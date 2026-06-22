---Dictate into a terminal buffer (e.g. the Claude Code window).
---
---whisper.nvim inserts transcribed text with `nvim_buf_set_text`, which fails on
---terminal buffers (not 'modifiable', and buffer edits never reach the running
---program). This records with ffmpeg, transcribes with whisper-cli, and sends the
---result to the terminal's job channel via `chansend` so it lands at the prompt.
---@class utils.whisper_term
local M = {}

---@type { job: integer?, wav: string?, chan: integer? }
local state = { job = nil, wav = nil, chan = nil }

-- A single Snacks notification that morphs through recording → transcribing →
-- result, so there's only ever one indicator on screen.
local IND = "whisper_term"

---@param msg string
---@param level? "info"|"warn"|"error"
---@param sticky? boolean stays until replaced; otherwise auto-dismisses
local function indicator(msg, level, sticky)
  local opts = { id = IND, title = "Whisper" }
  if sticky then
    opts.timeout = false
  end
  pcall(Snacks.notifier.notify, msg, level or "info", opts)
end

---Read paths/options from the loaded whisper.nvim config so they stay in one place.
local function cfg()
  local ok, w = pcall(require, "whisper_nvim")
  return (ok and w.config) or {}
end

---avfoundation input spec, mirroring whisper.nvim's macOS driver (":<device>").
local function audio_input()
  local dev = cfg().audio_device
  if not dev or dev == "" then
    dev = "default"
  end
  return ":" .. dev
end

local function transcribe(wav)
  local c = cfg()
  local out_base = wav:gsub("%.wav$", "")
  vim.fn.jobstart({
    c.whisper_path,
    "-m",
    c.model_path,
    "-f",
    wav,
    "--output-txt",
    "--output-file",
    out_base,
    "-l",
    c.language or "en",
  }, {
    on_exit = function(_, code)
      if code ~= 0 then
        pcall(vim.fn.delete, wav)
        indicator("whisper-cli failed (exit " .. code .. ")", "error")
        return
      end
      local txt = out_base .. ".txt"
      local lines = vim.fn.filereadable(txt) == 1 and vim.fn.readfile(txt) or {}
      local text = vim.trim((table.concat(lines, " "):gsub("%s+", " ")))
      pcall(vim.fn.delete, wav)
      pcall(vim.fn.delete, txt)

      if text == "" then
        indicator("No speech detected", "warn")
        return
      end
      if state.chan and vim.fn.chansend(state.chan, text) == 0 then
        indicator("Terminal channel closed", "warn")
        return
      end
      local preview = #text > 60 and (text:sub(1, 60) .. "…") or text
      indicator("✓ " .. preview, "info")
    end,
  })
end

function M.start()
  if state.job then
    return
  end
  local chan = vim.b.terminal_job_id
  if not chan then
    indicator("Not a terminal buffer", "warn")
    return
  end
  state.chan = chan
  state.wav = vim.fn.tempname() .. ".wav"

  state.job = vim.fn.jobstart({
    "ffmpeg",
    "-y",
    "-f",
    "avfoundation",
    "-i",
    audio_input(),
    "-ar",
    "16000",
    "-ac",
    "1",
    "-c:a",
    "pcm_s16le",
    state.wav,
  }, {
    on_exit = function()
      local wav = state.wav
      state.job, state.wav = nil, nil
      if wav then
        transcribe(wav)
      end
    end,
  })

  if state.job <= 0 then
    indicator("Failed to start ffmpeg recording", "error")
    state.job, state.wav, state.chan = nil, nil, nil
    return
  end
  indicator("🎙  Recording…  <C-s> to stop", "info", true)
end

function M.stop()
  if not state.job then
    return
  end
  indicator("󰔉  Transcribing…", "info", true)
  -- 'q' on ffmpeg's stdin makes it stop and finalize the WAV header cleanly.
  vim.fn.chansend(state.job, "q")
end

function M.toggle()
  if state.job then
    M.stop()
  else
    M.start()
  end
end

return M

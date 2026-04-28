vim.cmd('command! Wipe %bd|e#"')

vim.api.nvim_create_user_command("TscQuickfix", function()
  local cmd =
    [[sh -c 'yarn tsc --noEmit --pretty false 2>&1 | grep -E "^[^:]+\\(.*\\): error" | sed -E "s/^([^()]+)\\(([0-9]+),([0-9]+)\\): error [^:]+: (.*)$/\\1:\\2:\\3: \\4/"']]
  local output = vim.fn.systemlist(cmd)

  local qf = {}
  for _, line in ipairs(output) do
    local filename, lnum, col, text = string.match(line, "^([^:]+):(%d+):(%d+):%s(.+)$")
    if filename and lnum and col and text then
      table.insert(qf, {
        filename = filename,
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = text:sub(1, 200), -- Trim if needed
      })
    end
  end

  vim.fn.setqflist(qf, "r")
  -- -- Get the quickfix list
  local qflist = vim.fn.getqflist()

  -- Check if the list is empty
  if #qflist == 0 then
    -- If empty, show "No errors found" notification
    NeoUtils.notification.info("No errors found", {
      title = "TSC Quickfix",
    })
  else
    -- If not empty, show error count notification and open the quickfix window
    NeoUtils.notification.warn(#qflist .. " errors found", {
      title = "TSC Quickfix",
    })
    vim.cmd("copen")
  end
end, {})

vim.api.nvim_create_user_command("LintQuickfix", function()
  local output = vim.fn.systemlist("yarn lint:ts 2>&1")

  local qf = {}
  local current_file = nil

  for _, line in ipairs(output) do
    -- Check if this is a file path line (doesn't start with whitespace)
    if not line:match("^%s") and line:match("^/") then
      current_file = line
    elseif current_file then
      -- Parse error/warning lines: "  78:14  error  message  rule-name"
      local lnum, col, severity, text = line:match("^%s+(%d+):(%d+)%s+(%w+)%s+(.+)$")
      if lnum and col and severity == "error" and text then
        -- Extract just the message without the rule name at the end
        local message = text:match("^(.-)%s+[%w-]+/[%w-]+$") or text:match("^(.-)%s+[%w-]+$") or text
        table.insert(qf, {
          filename = current_file,
          lnum = tonumber(lnum),
          col = tonumber(col),
          text = message:sub(1, 200),
        })
      end
    end
  end

  vim.fn.setqflist(qf, "r")
  local qflist = vim.fn.getqflist()

  if #qflist == 0 then
    NeoUtils.notification.info("No errors found", {
      title = "Lint Quickfix",
    })
  else
    NeoUtils.notification.warn(#qflist .. " errors found", {
      title = "Lint Quickfix",
    })
    vim.cmd("copen")
  end
end, {})

local runners = {
  python = function(filepath)
    return { "python3", filepath }
  end,
}

vim.api.nvim_create_user_command("RunBuffer", function(opts)
  local ft = vim.bo.filetype
  local runner = runners[ft]

  if not runner then
    NeoUtils.notification.warn("No runner configured for filetype: " .. ft, { title = "RunBuffer" })
    return
  end

  local lines
  local label
  if opts.range > 0 then
    lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
    label = "selection"
  else
    lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    label = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
    if label == "" then
      label = "[unnamed]"
    end
  end

  local tmpfile = vim.fn.tempname() .. "." .. ft
  vim.fn.writefile(lines, tmpfile)

  local inner = table.concat(vim.tbl_map(vim.fn.shellescape, runner(tmpfile)), " ")
  local cmd = { "bash", "-c", inner .. "; echo; echo '─── Press any key to close ───'; read -rsn1" }
  Snacks.terminal.open(cmd, {
    win = {
      position = "float",
      border = "rounded",
      title = " Run: " .. label .. " ",
      title_pos = "center",
    },
  })
end, { desc = "Run current buffer or selection in a floating terminal", range = true })

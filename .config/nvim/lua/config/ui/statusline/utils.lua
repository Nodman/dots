-- ============================================================================
-- STATUSLINE UTILITIES
-- ============================================================================
-- Helper functions for building and formatting the statusline.
-- ============================================================================

local M = {}

local ftMap = require("config.ui.statusline.well-known-file-types")

---@alias ModeAttributes { name: string, highlight: string }

---@type table<string, ModeAttributes>
M.modesMap = {
  ["n"] = { name = "nrm", highlight = "ModeBlockNormal" },
  ["i"] = { name = "ins", highlight = "ModeBlockInsert" },
  ["R"] = { name = "rpl", highlight = "ModeBlockReplace" },
  ["v"] = { name = "vis", highlight = "ModeBlockVisual" },
  ["V"] = { name = "vln", highlight = "ModeBlockVisualLine" },
  [" "] = { name = "vbl", highlight = "ModeBlockVisualBlock" },
  ["c"] = { name = "com", highlight = "ModeBlockCommand" },
  ["t"] = { name = "ter", highlight = "ModeBlockTerminal" },
}

M.statusLineRest = table.concat({
  "%=",
  "%#GeneralBlock#",
  "%p%% ",
  "%l:%c ",
})

--- @param ft string
--- @return string
function M.getFt(ft)
  if ft == "" then
    return "-"
  end

  return ftMap[ft] or ft
end

--- @return ModeAttributes
function M.getModeAttributes()
  local mode = vim.api.nvim_get_mode().mode
  local attributes = M.modesMap[mode]

  if not attributes then
    -- More robust fallback
    local fallback_hl = M.modesMap["n"] and M.modesMap["n"].highlight or "ModeBlockNormal" -- Default highlight if 'n' isn't in map
    attributes = { name = mode, highlight = fallback_hl }
  end

  return attributes
end

--- Trims a file path from the beginning to fit within available width
--- @param filepath string The file path to trim
--- @param max_width number Maximum width available for the file path
--- @return string Trimmed file path with ellipsis if necessary
function M.trimFilePath(filepath, max_width)
  -- Handle empty or very short paths
  if filepath == "" then
    return ""
  end

  local filepath_width = vim.fn.strwidth(filepath)

  -- If path fits, return as-is
  if filepath_width <= max_width then
    return filepath
  end

  -- Need to trim from the beginning
  local ellipsis = "..."
  local ellipsis_width = vim.fn.strwidth(ellipsis)

  -- If max_width is too small to show anything meaningful
  if max_width <= ellipsis_width then
    return ellipsis
  end

  -- Calculate how much space we have for the actual path after ellipsis
  local available_width = max_width - ellipsis_width

  -- Find the right substring from the end
  -- We'll iterate character by character from the end to ensure accuracy with multibyte chars
  local result = ""
  local current_width = 0

  -- Work backwards through the string
  for i = #filepath, 1, -1 do
    local char = filepath:sub(i, i)
    local char_width = vim.fn.strwidth(char)

    if current_width + char_width <= available_width then
      result = char .. result
      current_width = current_width + char_width
    else
      break
    end
  end

  return ellipsis .. result
end

--- Calculates the available width for the file path in the statusline
--- @param mode_name string The mode name (e.g., "nrm", "ins")
--- @param filetype_display string The filetype display string
--- @return number Available width for file path
function M.calculateAvailableWidth(mode_name, filetype_display)
  local win_width = vim.fn.winwidth(0)

  -- Calculate fixed element widths
  -- Format: " {mode} " + " " + "{filepath}" + " " + "{modified}" + " " + "%=" + "{percentage} {line:col} " + " {filetype} "
  local mode_width = vim.fn.strwidth(mode_name) + 2 -- mode + spaces around it
  local modified_width = 4 -- " [+] " worst case (modified flag with spaces)
  local position_width = 12 -- "100% 9999:999 " typical worst case
  local filetype_width = vim.fn.strwidth(filetype_display) + 2 -- filetype + spaces
  local separators_width = 4 -- Extra spaces and separators

  local fixed_width = mode_width + modified_width + position_width + filetype_width + separators_width

  -- Reserve some margin for safety
  local margin = 2
  local available = win_width - fixed_width - margin

  -- Ensure we have at least minimal space
  return math.max(available, 20)
end

--- Builds the statusline string from components
---@param mode_highlight string
---@param mode_name string
---@param trimmed_filepath string
---@param filetype_display string
---@return string
function M.build_statusline(mode_highlight, mode_name, trimmed_filepath, filetype_display)
  return string.format(
    "%s %s %s %s %s %s %s %s %s %s ",
    "%#" .. mode_highlight .. "#",
    mode_name,
    "%#FileBlock#",
    trimmed_filepath,
    "%#GeneralBlock#",
    "%{get(b:,'gitsigns_status','')}",
    "%m",
    M.statusLineRest,
    "%#FtBlock#",
    filetype_display
  )
end

return M

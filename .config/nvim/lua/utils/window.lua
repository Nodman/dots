local cmd = vim.cmd
local api = vim.api

---@class utils.window
---@field isRelative fun(windowId: number): boolean Check if a window is relative (float/popup)
---@field checkIs fun(optName: string, optValue: any, windowId?: number): boolean Check a buffer-local option value for a window
---@field checkIsOctoWindow fun(windowId: number): boolean Check if window is an octo window
---@field wrapWindow fun(id: number) Set options for a "wrapped" (minimized) window
---@field unwrapWindow fun(id: number) Set options for an "unwrapped" (maximized) window
---@field equalizeWindows fun() Equalize window sizes and apply default view options
local M = {}

--- Check if a window is relative (float/popup)
---@param windowId number Window ID
---@return boolean
function M.isRelative(windowId)
  -- Check if 'relative' config field is non-empty
  return api.nvim_win_get_config(windowId).relative ~= ""
end

--- Check a buffer-local option value for a window (current or specified).
---@param optName string Option name (e.g., 'filetype', 'buftype')
---@param optValue any Expected value
---@param windowId? number Window ID (defaults to current window)
---@return boolean
function M.checkIs(optName, optValue, windowId)
  local win_id_to_check = windowId or api.nvim_get_current_win()
  local bufferId = api.nvim_win_get_buf(win_id_to_check)
  if bufferId == 0 then
    return false
  end -- No buffer in window

  local actualValue = api.nvim_get_option_value(optName, { buf = bufferId })
  return actualValue == optValue
end

--- Check if window is an octo window
---@param windowId number Window ID
---@return boolean
function M.checkIsOctoWindow(windowId)
  local bufferId = api.nvim_win_get_buf(windowId)
  if bufferId == 0 then
    return false
  end
  local filePath = api.nvim_buf_get_name(bufferId)

  -- Check buffer name prefix OR filetype
  return (filePath and filePath:find("^octo://") == 1) or M.checkIs("filetype", "octo_panel", windowId)
end

--- Set options for a "wrapped" (minimized) window
---@param id number Window ID
---@return nil
function M.wrapWindow(id)
  api.nvim_set_option_value("wrap", false, { win = id })

  -- Don't change number settings for grug-far or terminal buffers
  if M.checkIs("filetype", "grug-far", id) or M.checkIs("buftype", "terminal", id) then
    return
  end

  api.nvim_set_option_value("number", true, { win = id })
  api.nvim_set_option_value("relativenumber", false, { win = id })
end

--- Set options for an "unwrapped" (maximized) window
---@param id number Window ID
---@return nil
function M.unwrapWindow(id)
  api.nvim_set_option_value("wrap", true, { win = id })

  -- Don't change number settings for grug-far, codecompanion, or terminal buffers
  if M.checkIs("filetype", "grug-far", id) or M.checkIs("filetype", "codecompanion") or M.checkIs("buftype", "terminal", id) then
    return
  end

  api.nvim_set_option_value("number", true, { win = id })
  api.nvim_set_option_value("relativenumber", true, { win = id })
end

--- Equalize window sizes and apply default view options to non-relative, non-neo-tree windows
---@return nil
function M.equalizeWindows()
  -- Use vim.cmd for the convenient <C-w>= command
  cmd("wincmd =") -- More direct equivalent

  local windowsIds = api.nvim_list_wins()

  for _, id in ipairs(windowsIds) do
    -- Apply settings only to windows that are NOT relative AND NOT neo-tree
    if not M.isRelative(id) and not M.checkIs("filetype", "neo-tree", id) then
      -- Apply the "wrapped" state settings
      M.wrapWindow(id)
    end
  end
end

return M

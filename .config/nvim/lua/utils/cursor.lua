local api = vim.api
local opt = vim.opt
local cmd = vim.cmd

---@class utils.cursor
local M = {}

---@type string Store the original guicursor setting
M.guicursor = vim.o.guicursor

--- Hides the visual cursor block by changing guicursor and blending.
---@return nil
function M.hideCursor()
  cmd('hi Cursor blend=100')
  cmd('set guicursor=' .. M.guicursor .. ',a:Cursor/lCursor')
end

--- Restores the visual cursor block and original guicursor setting.
---@return nil
function M.restoreCursor()
  cmd('hi Cursor blend=0')
  cmd('set guicursor=' .. M.guicursor)
end

return M

---https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/util/init.lua

---@class utils.common
local M = {}

---@generic T
---@param list T[]
---@return T[]
function M.dedup(list)
  local ret = {}
  local seen = {}
  for _, v in ipairs(list) do
    if not seen[v] then
      table.insert(ret, v)
      seen[v] = true
    end
  end
  return ret
end

---@class AutocmdArgs
---@field event string|string[] The event(s) to trigger the autocommand
---@field pattern string|string[] The pattern(s) to match
---@field callback function The callback function to execute
---@field desc? string Optional description for the autocommand

---@class AugroupArgs
---@field name string The name of the augroup
---@field autocmds AutocmdArgs[] Array of autocommand configurations

---@param args AugroupArgs
---@return integer The created augroup ID
function M.createAugroup(args)
  local group = vim.api.nvim_create_augroup(args.name, { clear = true })

  for _, autocmd in ipairs(args.autocmds) do
    vim.api.nvim_create_autocmd(autocmd.event, {
      group = group,
      pattern = autocmd.pattern,
      callback = autocmd.callback,
      desc = autocmd.desc, -- Optional description for the autocommand
    })
  end

  return group
end

return M

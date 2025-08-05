---@meta

---@class VimGlobals
vim.g = {}

--- @class lspconfig

-- Type definitions

-- Define the shape of the global NeoUtils table
---@class NeoUtils
---@field layout utils.layout
---@field icons utils.icons
---@field notification utils.notification
---@field plugin utils.plugin
---@field window utils.window
---@field cursor utils.cursor
---@field common utils.common
---@field lsp utils.lsp
---@field root utils.root
---@field config utils.config
_G.NeoUtils = {}

---@class vim.api.create_autocmd.callback.args
---@field id number
---@field event string
---@field group number?
---@field match string
---@field buf number
---@field file string
---@field data any

---@class vim.api.keyset.create_autocmd.opts: vim.api.keyset.create_autocmd
---@field callback? fun(ev:vim.api.create_autocmd.callback.args):boolean?

--- @param event any (string|array) Event(s) that will trigger the handler
--- @param opts vim.api.keyset.create_autocmd.opts
--- @return integer
function vim.api.nvim_create_autocmd(event, opts) end

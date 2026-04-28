---@class LspConstants
local M = {}

-- Diagnostic configuration
-- Applied via vim.diagnostic.config()
---@type vim.diagnostic.Opts
M.diagnostics = {
  underline = true,
  update_in_insert = false,
  virtual_text = {
    spacing = 4,
    source = "if_many",
    prefix = "▪",
  },
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "▪",
      [vim.diagnostic.severity.WARN] = "▪",
      [vim.diagnostic.severity.HINT] = "▪",
      [vim.diagnostic.severity.INFO] = "▪",
    },
  },
}

-- Inlay hints configuration
M.inlay_hints = {
  enabled = false,
  exclude = { "vue" }, -- filetypes to exclude from inlay hints
}

-- Code lens configuration
M.codelens = {
  enabled = true,
}

-- Global LSP capabilities
M.capabilities = {
  workspace = {
    fileOperations = {
      didRename = true,
      willRename = true,
    },
  },
}

-- LSP symbol kind filter configuration
-- Used in LSP symbol pickers to filter by symbol kind
---@type table<string, string[]|boolean>?
M.kind_filter = {
  default = {
    "Class",
    "Constructor",
    "Enum",
    "Field",
    "Function",
    "Interface",
    "Method",
    "Module",
    "Namespace",
    "Package",
    "Property",
    "Struct",
    "Trait",
  },
  markdown = false,
  help = false,
  lua = {
    "Class",
    "Constructor",
    "Enum",
    "Field",
    "Function",
    "Interface",
    "Method",
    "Module",
    "Namespace",
    -- "Package", -- remove package since luals uses it for control flow structures
    "Property",
    "Struct",
    "Trait",
  },
}

-- Server-specific configurations (optional overrides)
-- These configs are applied AFTER loading lsp/*.lua files, allowing for overrides
-- Only include servers here if you need to override settings from lsp/ files
-- or if the server doesn't have a dedicated lsp/*.lua file
M.server_configs = {
  -- Example override (commented out - lsp/*.lua files contain full configs):
  -- lua_ls = {
  --   settings = {
  --     Lua = {
  --       workspace = { checkThirdParty = false },
  --     },
  --   },
  -- },
}

return M

---@class LspNativeConfig
local M = {}

-- List of LSP servers to enable
-- These will be activated via vim.lsp.enable()
M.servers = {
  "lua_ls",
  "vtsls",
  "eslint",
  "sourcekit",
}

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
-- Enabled via NeoUtils.lsp.on_supports_method("textDocument/inlayHint", ...)
M.inlay_hints = {
  enabled = true,
  exclude = { "vue" }, -- filetypes to exclude from inlay hints
}

-- Code lens configuration
-- Enabled via NeoUtils.lsp.on_supports_method("textDocument/codeLens", ...)
M.codelens = {
  enabled = true,
}

-- Global LSP capabilities
-- Merged with Blink.cmp capabilities and set via vim.lsp.config('*', { capabilities })
M.capabilities = {
  workspace = {
    fileOperations = {
      didRename = true,
      willRename = true,
    },
  },
}

-- Server-specific configurations
-- Applied via vim.lsp.config(server_name, { settings, root_dir, capabilities, etc. })
M.server_configs = {
  lua_ls = {
    settings = {
      Lua = {
        workspace = {
          checkThirdParty = false,
        },
        codeLens = {
          enable = true,
        },
        completion = {
          callSnippet = "Replace",
        },
        doc = {
          privateName = { "^_" },
        },
      },
    },
  },

  vtsls = {
    settings = {
      experimental = {
        completion = {
          enableServerSideFuzzyMatch = true,
        },
      },
    },
  },

  eslint = {
    settings = {
      -- helps eslint find the eslintrc when it's placed in a subfolder instead of the cwd root
      workingDirectories = { mode = "auto" },
      format = true,
    },
  },

  sourcekit = {
    root_dir = function(filename)
      local util = require("lspconfig.util")
      return util.root_pattern("buildServer.json")(filename)
        or util.root_pattern("*.xcodeproj", "*.xcworkspace")(filename)
        or vim.fs.dirname(vim.fs.find(".git", { path = filename, upward = true })[1])
        or util.root_pattern("Package.swift")(filename)
    end,
    capabilities = {
      workspace = {
        didChangeWatchedFiles = {
          dynamicRegistration = true,
        },
      },
    },
  },
}

---Setup native LSP configuration
---This is the main entry point called from the plugin spec
function M.setup()
  -- 1. Initialize NeoUtils.lsp - sets up dynamic capability handling
  NeoUtils.lsp.setup()

  -- 2. Configure diagnostic display
  vim.diagnostic.config(vim.deepcopy(M.diagnostics))

  -- 3. Define diagnostic signs
  -- These are used in the sign column for diagnostic indicators
  if type(M.diagnostics.signs) ~= "boolean" then
    for severity, icon in pairs(M.diagnostics.signs.text) do
      local name = vim.diagnostic.severity[severity]:lower():gsub("^%l", string.upper)
      name = "DiagnosticSign" .. name
      vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
    end
  end

  -- 4. Build global capabilities by merging Blink.cmp capabilities
  local has_blink, blink = pcall(require, "blink.cmp")
  local capabilities = vim.tbl_deep_extend(
    "force",
    {},
    vim.lsp.protocol.make_client_capabilities(),
    has_blink and blink.get_lsp_capabilities() or {},
    M.capabilities or {}
  )

  -- 5. Set global LSP config with merged capabilities
  -- This applies to all servers via the '*' pattern
  vim.lsp.config("*", {
    capabilities = capabilities,
  })

  -- 6. Configure server-specific settings
  -- Each server gets its own configuration via vim.lsp.config(server_name, opts)
  for server_name, config in pairs(M.server_configs) do
    local server_config = vim.deepcopy(config)

    -- Merge server-specific capabilities with global capabilities
    if server_config.capabilities then
      server_config.capabilities = vim.tbl_deep_extend("force", vim.deepcopy(capabilities), server_config.capabilities)
    end

    vim.lsp.config(server_name, server_config)
  end

  -- 7. Setup LspAttach for keymaps
  -- This runs whenever an LSP client attaches to a buffer
  NeoUtils.lsp.on_attach(function(client, buffer)
    require("plugins.neovim.lsp-native.keymaps").on_attach(client, buffer)
  end)

  -- 8. Setup dynamic capability handling for keymaps
  -- This handles when LSP servers dynamically register new capabilities
  NeoUtils.lsp.on_dynamic_capability(require("plugins.neovim.lsp-native.keymaps").on_attach)

  -- 9. Enable inlay hints when server supports them
  if M.inlay_hints.enabled then
    NeoUtils.lsp.on_supports_method("textDocument/inlayHint", function(client, buffer)
      if
        vim.api.nvim_buf_is_valid(buffer)
        and vim.bo[buffer].buftype == ""
        and not vim.tbl_contains(M.inlay_hints.exclude, vim.bo[buffer].filetype)
      then
        vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
      end
    end)
  end

  -- 10. Enable code lens when server supports them
  if M.codelens.enabled and vim.lsp.codelens then
    NeoUtils.lsp.on_supports_method("textDocument/codeLens", function(client, buffer)
      vim.lsp.codelens.refresh()
      vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
        buffer = buffer,
        callback = vim.lsp.codelens.refresh,
      })
    end)
  end

  -- 11. Create Snacks toggle for virtual text
  -- Allows toggling diagnostic virtual text on/off with <leader>tv
  Snacks.toggle({
    name = "LSP virtual text",
    get = function()
      return not not vim.diagnostic.config().virtual_text
    end,
    set = function()
      if not vim.diagnostic.config().virtual_text then
        vim.diagnostic.config({ virtual_text = M.diagnostics.virtual_text })
      else
        vim.diagnostic.config({
          virtual_text = false,
        })
      end
    end,
  }):map("<leader>tv")

  -- 12. Enable all LSP servers
  -- This is the native API replacement for lspconfig.setup()
  -- It automatically starts servers when opening matching filetypes
  vim.lsp.enable(M.servers)
end

return M

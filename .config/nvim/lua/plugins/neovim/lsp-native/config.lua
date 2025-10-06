---@class LspNativeConfig
local M = {}

-- Get list of installed LSP servers from Mason
---@return string[] List of LSP server names
function M.get_installed_servers()
  local has_mason, mason_registry = pcall(require, "mason-registry")

  local servers = {}
  local installed_packages = {}

  -- Mason package name → LSP server name mapping
  local package_to_server = {
    ["lua-language-server"] = "lua_ls",
    ["vtsls"] = "vtsls",
    ["eslint-lsp"] = "eslint",
    ["json-lsp"] = "jsonls",
    ["yaml-language-server"] = "yamlls",
    ["graphql-language-service-cli"] = "graphql",
    ["typescript-language-server"] = "ts_ls",
    ["pyright"] = "pyright",
    ["rust-analyzer"] = "rust_analyzer",
    ["gopls"] = "gopls",
    -- Add more mappings as needed
  }

  for _, package in ipairs(mason_registry.get_installed_packages()) do
    local package_name = package.name
    table.insert(installed_packages, package_name)
    local server_name = package_to_server[package_name]

    if server_name then
      table.insert(servers, server_name)
    end
  end

  -- Debug info
  -- NeoUtils.notification.info("Mason installed packages: " .. table.concat(installed_packages, ", "))
  -- NeoUtils.notification.info("Detected LSP servers: " .. table.concat(servers, ", "))

  return servers
end

-- List of LSP servers to enable (fallback if Mason is not available)
-- If Mason is installed, this list is auto-generated from installed packages
M.servers = {
  -- "lua_ls",
  -- "vtsls",
  -- "eslint",
  -- "sourcekit",
  -- "jsonls",
  -- "yamlls",
  -- "graphql",
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

  -- 6. Determine which servers to enable
  -- Try to get installed servers from Mason, fallback to M.servers
  local servers_to_enable = M.get_installed_servers()
  if #servers_to_enable == 0 then
    servers_to_enable = M.servers
  end

  -- 7. Load server configs with fallback to nvim-lspconfig reference
  -- Neovim automatically loads lsp/*.lua files, so we only need to handle fallback
  -- Priority: local lsp/ dir (auto-loaded by Neovim) → nvim-lspconfig/lsp/ (manual fallback) → M.server_configs
  local local_lsp_dir = vim.fn.stdpath("config") .. "/lsp"
  local lspconfig_lsp_dir = vim.fn.stdpath("config") .. "/pack/nvim/start/nvim-lspconfig/lsp"

  for _, server_name in ipairs(servers_to_enable) do
    local config_file = local_lsp_dir .. "/" .. server_name .. ".lua"
    local fallback_file = lspconfig_lsp_dir .. "/" .. server_name .. ".lua"

    -- Only load fallback if local config doesn't exist (Neovim loads local automatically)
    if vim.fn.filereadable(config_file) ~= 1 and vim.fn.filereadable(fallback_file) == 1 then
      local ok, server_config = pcall(dofile, fallback_file)
      if ok and server_config then
        -- Merge capabilities
        server_config.capabilities =
          vim.tbl_deep_extend("force", vim.deepcopy(capabilities), server_config.capabilities or {})
        vim.lsp.config(server_name, server_config)
      end
    end
  end

  -- 8. Apply configs from M.server_configs table (for manual overrides)
  -- Each server gets its own configuration via vim.lsp.config(server_name, opts)
  for server_name, config in pairs(M.server_configs) do
    local server_config = vim.deepcopy(config)

    -- Merge server-specific capabilities with global capabilities
    if server_config.capabilities then
      server_config.capabilities = vim.tbl_deep_extend("force", vim.deepcopy(capabilities), server_config.capabilities)
    end

    vim.lsp.config(server_name, server_config)
  end

  -- 9. Setup LspAttach for keymaps
  -- This runs whenever an LSP client attaches to a buffer
  NeoUtils.lsp.on_attach(function(client, buffer)
    require("plugins.neovim.lsp-native.keymaps").on_attach(client, buffer)
  end)

  -- 10. Setup dynamic capability handling for keymaps
  -- This handles when LSP servers dynamically register new capabilities
  NeoUtils.lsp.on_dynamic_capability(require("plugins.neovim.lsp-native.keymaps").on_attach)

  -- 11. Enable inlay hints when server supports them
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

  -- 12. Enable code lens when server supports them
  if M.codelens.enabled and vim.lsp.codelens then
    NeoUtils.lsp.on_supports_method("textDocument/codeLens", function(client, buffer)
      vim.lsp.codelens.refresh()
      vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
        buffer = buffer,
        callback = vim.lsp.codelens.refresh,
      })
    end)
  end

  -- 13. Create Snacks toggle for virtual text
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

  -- 14. Enable all LSP servers
  -- This is the native API replacement for lspconfig.setup()
  -- It automatically starts servers when opening matching filetypes
  vim.lsp.enable(servers_to_enable)
end

return M

---@class LspNativeConfig
local M = {}

local constants = require("plugins.lsp.lib.constants")
local mason = require("plugins.lsp.lib.mason")

-- Re-export constants for convenience
M.diagnostics = constants.diagnostics
M.inlay_hints = constants.inlay_hints
M.codelens = constants.codelens
M.capabilities = constants.capabilities
M.kind_filter = constants.kind_filter
M.server_configs = constants.server_configs

---Setup LSP log notifications to show errors and warnings
function M.setup_log_notifications()
  -- Store original log functions
  local original_error = vim.lsp.log.error
  local original_warn = vim.lsp.log.warn

  -- Keep track of recent messages to avoid spam (simple deduplication)
  local recent_messages = {}
  local function should_notify(msg, level)
    local key = level .. ":" .. msg
    local now = vim.loop.now()

    -- Check if we've shown this message in the last 5 seconds
    if recent_messages[key] and (now - recent_messages[key]) < 5000 then
      return false
    end

    recent_messages[key] = now
    return true
  end

  -- Wrap error function
  vim.lsp.log.error = function(...)
    -- Call original function to maintain normal logging
    original_error(...)

    -- Extract message from arguments
    local args = { ... }
    local msg = table.concat(vim.tbl_map(tostring, args), " ")

    -- Show notification if not a duplicate
    if should_notify(msg, "ERROR") then
      -- Try to extract server name from message
      local server_name = msg:match("graphql") and "GraphQL"
        or msg:match("lua_ls") and "Lua"
        or msg:match("typescript") and "TypeScript"
        or msg:match("eslint") and "ESLint"
        or "LSP"

      -- Clean up and truncate message
      local clean_msg = msg:gsub("^%[ERROR%]%[%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d%]", ""):gsub("^%s+", "")
      if #clean_msg > 500 then
        clean_msg = clean_msg:sub(1, 500) .. "\n\n... (truncated, check :LspLog for full message)"
      end

      vim.schedule(function()
        NeoUtils.notification.error(clean_msg, { title = server_name .. " Error" })
      end)
    end
  end

  -- Wrap warn function
  vim.lsp.log.warn = function(...)
    -- Call original function to maintain normal logging
    original_warn(...)

    -- Extract message from arguments
    local args = { ... }
    local msg = table.concat(vim.tbl_map(tostring, args), " ")

    -- Show notification if not a duplicate
    if should_notify(msg, "WARN") then
      -- Try to extract server name from message
      local server_name = msg:match("graphql") and "GraphQL"
        or msg:match("lua_ls") and "Lua"
        or msg:match("typescript") and "TypeScript"
        or msg:match("eslint") and "ESLint"
        or "LSP"

      -- Clean up and truncate message
      local clean_msg = msg:gsub("^%[WARN%]%[%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d%]", ""):gsub("^%s+", "")
      if #clean_msg > 500 then
        clean_msg = clean_msg:sub(1, 500) .. "\n\n... (truncated, check :LspLog for full message)"
      end

      vim.schedule(function()
        NeoUtils.notification.warn(clean_msg, { title = server_name .. " Warning" })
      end)
    end
  end
end

---Setup native LSP configuration
---This is the main entry point called from the plugin spec
function M.setup()
  -- 1. Initialize NeoUtils.lsp - sets up dynamic capability handling
  NeoUtils.lsp.setup()

  -- 2. Initialize Mason integration
  mason.setup()

  -- 3. Configure diagnostic display
  vim.diagnostic.config(vim.deepcopy(M.diagnostics))

  -- 4. Setup LSP log notifications
  M.setup_log_notifications()

  -- 5. Define diagnostic signs
  if type(M.diagnostics.signs) ~= "boolean" then
    for severity, icon in pairs(M.diagnostics.signs.text) do
      local name = vim.diagnostic.severity[severity]:lower():gsub("^%l", string.upper)
      name = "DiagnosticSign" .. name
      vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
    end
  end

  -- 6. Build global capabilities by merging Blink.cmp capabilities
  local has_blink, blink = pcall(require, "blink.cmp")
  local capabilities = vim.tbl_deep_extend(
    "force",
    {},
    vim.lsp.protocol.make_client_capabilities(),
    has_blink and blink.get_lsp_capabilities() or {},
    M.capabilities or {}
  )

  -- 7. Set global LSP config with merged capabilities
  vim.lsp.config("*", {
    capabilities = capabilities,
  })

  -- 8. Get installed servers from Mason
  local servers_to_enable = mason.get_installed_servers()

  -- 9. Load server configs with fallback to nvim-lspconfig reference
  -- Priority: local lsp/ dir (auto-loaded by Neovim) → nvim-lspconfig/lsp/ (manual fallback) → M.server_configs
  local local_lsp_dir = vim.fn.stdpath("config") .. "/lsp"
  local lspconfig_dir = vim.fn.stdpath("config") .. "/pack/nvim/start/nvim-lspconfig"
  local lspconfig_lsp_dir = lspconfig_dir .. "/lsp"

  -- lazy.nvim resets packpath, so pack/ dirs aren't auto-added to rtp.
  -- Add nvim-lspconfig to rtp so fallback configs can `require 'lspconfig.util'`.
  if vim.fn.isdirectory(lspconfig_dir) == 1 and not vim.o.runtimepath:find(lspconfig_dir, 1, true) then
    vim.opt.runtimepath:prepend(lspconfig_dir)
  end

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

  -- 10. Apply configs from M.server_configs table (for manual overrides)
  for server_name, config in pairs(M.server_configs) do
    local server_config = vim.deepcopy(config)

    -- Merge server-specific capabilities with global capabilities
    if server_config.capabilities then
      server_config.capabilities = vim.tbl_deep_extend("force", vim.deepcopy(capabilities), server_config.capabilities)
    end

    vim.lsp.config(server_name, server_config)
  end

  -- 11. Setup LspAttach for keymaps
  NeoUtils.lsp.on_attach(function(client, buffer)
    require("plugins.lsp.lib.keymaps").on_attach(client, buffer)
  end)

  -- 12. Setup dynamic capability handling for keymaps
  NeoUtils.lsp.on_dynamic_capability(require("plugins.lsp.lib.keymaps").on_attach)

  -- 13. Enable inlay hints when server supports them
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

  -- 14. Enable code lens when server supports them
  if M.codelens.enabled and vim.lsp.codelens then
    NeoUtils.lsp.on_supports_method("textDocument/codeLens", function(client, buffer)
      vim.lsp.codelens.refresh()
      vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
        buffer = buffer,
        callback = vim.lsp.codelens.refresh,
      })
    end)
  end

  -- 15. Create Snacks toggle for virtual text (deferred until Snacks is loaded)
  vim.schedule(function()
    local ok, snacks = pcall(require, "snacks")
    if ok and snacks.toggle then
      snacks.toggle({
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
    end
  end)

  -- 16. Enable all LSP servers
  vim.lsp.enable(servers_to_enable)
end

return M

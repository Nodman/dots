---@type LazySpec
return {
  -- Mason: LSP server, formatter, and linter installer
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    keys = {
      { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" },
    },
    opts = {
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    },
    ---@param opts MasonSettings
    config = function(_, opts)
      require("mason").setup(opts)

      -- Auto-install packages
      local ensure_installed = {
        "lua-language-server",
        "vtsls",
        "eslint-lsp",
        "json-lsp",
        "yaml-language-server",
        "graphql-language-service-cli",
        "stylua",
        "shfmt",
      }

      -- Install missing packages
      local registry = require("mason-registry")

      -- Ensure registry is updated before checking packages
      registry.refresh(function()
        for _, package_name in ipairs(ensure_installed) do
          local ok, package = pcall(registry.get_package, package_name)
          if ok then
            if not package:is_installed() then
              vim.notify("Installing " .. package_name, vim.log.levels.INFO)
              package:install()
            end
          else
            vim.notify(
              "Package not found in registry: " .. package_name,
              vim.log.levels.WARN
            )
          end
        end
      end)

      -- Trigger FileType event after successful package installation
      -- This allows LSP servers to attach to already-open buffers
      local mr = require("mason-registry")
      mr:on("package:install:success", function()
        vim.defer_fn(function()
          -- Trigger FileType event for all loaded buffers
          vim.cmd("doautocmd FileType")
        end, 100)
      end)
    end,
  },

  -- Native LSP Configuration
  {
    name = "native-lsp-config",
    dir = vim.fn.stdpath("config") .. "/lua/plugins/lsp",
    lazy = false,
    priority = 100,
    dependencies = {
      "williamboman/mason.nvim",
    },
    config = function()
      require("plugins.lsp.config").setup()
    end,
  },
}

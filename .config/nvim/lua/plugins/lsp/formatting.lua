local prettier_ft = {
  "css",
  "graphql",
  "handlebars",
  "html",
  "json",
  "jsonc",
  "less",
  "markdown",
  "markdown.mdx",
  "scss",
  "vue",
  "yaml",
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
}

local prettier_eslint_ft = {
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
}

return {
  {
    "stevearc/conform.nvim",
    dependencies = { "mason.nvim" },
    lazy = true,
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>bf",
        function()
          local bufnr = vim.api.nvim_get_current_buf()
          local conform_opts = { async = true, bufnr = bufnr, lsp_format = "fallback", timeout_ms = 2000 }
          local vtsls_client = vim.lsp.get_clients({ name = "vtsls", bufnr = bufnr })[1]
          local eslint_client = vim.lsp.get_clients({ name = "eslint", bufnr = bufnr })[1]

          if vtsls_client then
            local params = vim.lsp.util.make_range_params(0, vtsls_client.offset_encoding)
            params.context = { diagnostics = {}, only = { "source.fixAll.ts" }, triggerKind = 1 }
            local result = vtsls_client:request_sync("textDocument/codeAction", params, 5000, bufnr)
            if result and not result.err and result.result then
              for _, action in ipairs(result.result) do
                if action.edit then
                  vim.lsp.util.apply_workspace_edit(action.edit, vtsls_client.offset_encoding)
                end
                if action.command then
                  local cmd = type(action.command) == "string"
                    and { command = action.command }
                    or action.command
                  vtsls_client:request_sync("workspace/executeCommand", cmd, 2000, bufnr)
                end
              end
            end
          end

          if eslint_client then
            local request_result = eslint_client:request_sync("workspace/executeCommand", {
              command = "eslint.applyAllFixes",
              arguments = {
                {
                  uri = vim.uri_from_bufnr(bufnr),
                  version = vim.lsp.util.buf_versions[bufnr],
                },
              },
            }, nil, bufnr)

            if request_result and request_result.err then
              vim.notify(request_result.err.message, vim.log.levels.ERROR)
              return
            end
          end

          require("conform").format(conform_opts)
        end,
        mode = { "n", "v" },
        desc = "Format Injected Langs",
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        fish = { "fish_indent" },
        sh = { "shfmt" },
      },
      default_format_opts = {
        lsp_format = "fallback",
      },
    },
    config = function(_, opts)
      for _, ft in ipairs(prettier_ft) do
        opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
        table.insert(opts.formatters_by_ft[ft], "prettier")
      end

      -- for _, ft in ipairs(prettier_eslint_ft) do
      --   opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
      --   vim.list_extend(opts.formatters_by_ft[ft], { "prettier", "eslint_d" })
      -- end

      opts.formatters = opts.formatters or {}

      require("conform").setup(opts)
    end,
  },
}

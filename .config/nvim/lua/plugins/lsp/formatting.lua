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
            local request_result = vtsls_client:request_sync("workspace/executeCommand", {
              command = "source.fixAll.ts",
              arguments = { vim.api.nvim_buf_get_name(bufnr) },
            })

            if request_result and request_result.err then
              vim.notify(request_result.err.message, vim.log.levels.ERROR)
              return
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

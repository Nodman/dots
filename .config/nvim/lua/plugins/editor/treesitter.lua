return {
  {
    "nvim-treesitter/nvim-treesitter",
    version = false,
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile", "BufWritePre", "VeryLazy" },
    lazy = vim.fn.argc(-1) == 0,
    init = function(plugin)
      require("lazy.core.loader").add_to_rtp(plugin)
      -- query_predicates is now a plugin/ file, loaded via vim.cmd.runtime
      vim.cmd.runtime({ "plugin/query_predicates.lua", bang = true })
    end,
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "diff",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "printf",
        "python",
        "query",
        "regex",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
        "git_config",
        "gitcommit",
        "git_rebase",
        "gitignore",
        "gitattributes",
        "http",
        "graphql",
        "dockerfile",
        "ruby",
      },
    },
    config = function(_, opts)
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("nvim-treesitter", { clear = true }),
        callback = function(args)
          vim.bo[args.buf].indentexpr = 'v:lua.require"nvim-treesitter".indentexpr()'
        end,
      })
      if type(opts.ensure_installed) == "table" then
        require("nvim-treesitter").install(NeoUtils.common.dedup(opts.ensure_installed))
      end
    end,
  },

  {
    "mks-h/treesitter-autoinstall.nvim",
    event = "FileType",
    opts = {
      highlight = true,
    },
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = "VeryLazy",
    enabled = true,
    config = function()
      local move = require("nvim-treesitter-textobjects.move")

      local mappings = {
        goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer", ["]a"] = "@parameter.inner" },
        goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer", ["]A"] = "@parameter.inner" },
        goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer", ["[a"] = "@parameter.inner" },
        goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer", ["[A"] = "@parameter.inner" },
      }

      for dir, keys in pairs(mappings) do
        for key, query in pairs(keys) do
          vim.keymap.set({ "n", "x", "o" }, key, function()
            -- In diff mode, fall back to vim's native [c/]c/[C/]C for hunk navigation
            if vim.wo.diff and key:find("[%]%[][cC]") then
              vim.cmd("normal! " .. key)
            else
              move[dir](query)
            end
          end, { desc = dir:gsub("_", " ") .. " " .. query })
        end
      end
    end,
  },

  -- Automatically add closing tags for HTML and JSX
  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPost", "BufNewFile", "BufWritePre" },
    opts = {},
  },
}

return {
  "olimorris/codecompanion.nvim",
  opts = {
    extensions = {
      mcphub = {
        callback = "mcphub.extensions.codecompanion",
        opts = {
          show_result_in_chat = true, -- Show mcp tool results in chat
          make_vars = true, -- Convert resources to #variables
          make_slash_commands = true, -- Add prompts as /slash commands
        },
      },
    },
    display = {
      inline = {
        layout = "buffer", -- vertical|horizontal|buffer
      },
      -- diff = {
      --   provider = "mini_diff",
      -- },
    },
    adapters = {
      gemini_pro = function()
        return require("codecompanion.adapters").extend("gemini", {
          schema = {
            model = {
              default = "gemini-2.5-pro-preview-05-06",
            },
          },
        })
      end,
      gemini = function()
        return require("codecompanion.adapters").extend("gemini", {
          schema = {
            model = {
              default = "gemini-2.5-flash-preview-04-17",
            },
          },
        })
      end,
    },
    strategies = {
      chat = {
        adapter = "gemini",
        keymaps = {
          completion = {
            modes = {
              i = "<C-=>",
            },
            index = 1,
            callback = "keymaps.completion",
            description = "Completion Menu",
          },
        },
      },
      inline = {
        adapter = "gemini",
      },
      cmd = {
        adapter = "gemini",
      },
    },
  },
  -- lazy = true,
  -- cmd = { "CodeCompanionActions", "CodeCompanionChat", "CodeCompanionCmd", "CodeCompanion" },
  dependencies = {
    { "nvim-lua/plenary.nvim", branch = "master" },
    "nvim-treesitter/nvim-treesitter",
    "ravitemer/mcphub.nvim",
  },
  keys = {
    {
      "<leader>cc",
      "<cmd>CodeCompanionActions<cr>",
      mode = { "n", "v" },
      desc = "CodeCompanion Actions",
    },
    {
      "<LocalLeader>a",
      "<cmd>CodeCompanionChat Toggle<cr>",
      mode = { "n", "v" },
      desc = "Toggle Chat",
    },
    {
      "<LocalLeader>a",
      "<cmd>CodeCompanionChat Add<cr>",
      mode = { "v" },
      desc = "Add To Chat",
    },
  },
  config = function(_, opts)
    require("codecompanion").setup(opts)
  end,
}

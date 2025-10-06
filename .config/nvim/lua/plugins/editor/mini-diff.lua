return {
  "echasnovski/mini.diff",
  event = "VeryLazy",
  keys = {
    {
      "<leader>go",
      function()
        require("mini.diff").toggle_overlay(0)
      end,
      desc = "Toggle mini.diff overlay",
    },
  },
  opts = {
    mappings = {
      -- Apply hunks inside a visual/operator region
      apply = "<leader>Da",

      -- Reset hunks inside a visual/operator region
      reset = "<leader>Dr",

      -- Hunk range textobject to be used inside operator
      -- Works also in Visual mode if mapping differs from apply and reset
      textobject = "<leader>Do",

      -- Go to hunk range in corresponding direction
      goto_first = "<leader>D0",
      goto_prev = "<leader>D[",
      goto_next = "<leader>D]",
      goto_last = "<leader>D$",
    },
    view = {
      style = "sign",
      priority = 0,
      signs = {
        add = "",
        change = "",
        delete = "",
      },
    },
  },
}

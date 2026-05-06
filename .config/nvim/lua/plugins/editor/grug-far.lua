return {
  "MagicDuck/grug-far.nvim",
  keys = {
    {
      "<leader>sr",
      function()
        local grug = require("grug-far")
        local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
        grug.open({
          transient = true,
          prefills = {
            filesFilter = ext and ext ~= "" and "*." .. ext or nil,
          },
        })
      end,
      mode = { "n", "v" },
      desc = "Search and Replace",
    },
    {
      "<leader>sf",
      function()
        local grug = require("grug-far")
        local opts = { prefills = { paths = vim.fn.expand("%") } }
        local mode = vim.fn.mode()
        if mode == "v" or mode == "V" or mode == "\22" then
          grug.with_visual_selection(opts)
        else
          grug.open(opts)
        end
      end,
      mode = { "n", "v" },
      desc = "Search and Replace (current file)",
    },
  },
  config = function()
    require("grug-far").setup({})
    vim.keymap.set({ "n" }, "]m", function()
      local inst = require("grug-far").get_instance()
      if inst then
        inst:goto_next_match({ wrap = true })
        inst:open_location()
      end
    end, { desc = "grug-far: next match" })
  end,
}

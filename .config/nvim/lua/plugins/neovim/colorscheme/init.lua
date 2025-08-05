return {
  "gbprod/nord.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("nord").setup({})

    vim.cmd.colorscheme("nord")
    require("plugins.neovim.colorscheme.nord-highlights")
  end,
}

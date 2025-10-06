return {
  "f-person/auto-dark-mode.nvim",
  lazy = false,
  priority = 1000,
  dependencies = {
    {

      "gbprod/nord.nvim",
      config = function()
        require("nord").setup({})
      end,
    },
    {
      "catppuccin/nvim",
      name = "catppuccin",
      lazy = false,
    },
  },
  opts = {
    update_interval = 1000,
    set_dark_mode = function()
      -- vim.api.nvim_set_option_value("background", "dark", {})
      vim.opt.termguicolors = true
      vim.cmd.colorscheme("nord")
      require("plugins.neovim.colorscheme.nord-highlights")
    end,
    set_light_mode = function()
      -- vim.api.nvim_set_option_value("background", "light", {})
      vim.opt.termguicolors = true
      require("catppuccin").setup({
        transparent_background = true,
        float = {
          transparent = true, -- enable transparent floating windows
          solid = false, -- use solid styling for floating windows, see |winborder|
        },
      })
      vim.cmd.colorscheme("catppuccin-latte")
      require("plugins.neovim.colorscheme.catpuccin-highlights")
    end,
  },
}

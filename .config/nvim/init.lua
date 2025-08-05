--[[ -- key mappings
require("keymap")

-- nvim settings
require("settings")

-- via lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

vim.opt.rtp:prepend(lazypath)

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end

if not vim.g.vscode then
  -- statusline
  require("statusline")
  -- custom commands
  require("commands")
end

require("lazy").setup({
  {
    import = "plugins.neovim",
    cond = function()
      return not vim.g.vscode
    end,
  },
  { import = "plugins.always", cond = true },
  {
    import = "plugins.vscode",
    cond = function()
      return vim.g.vscode
    end,
  },
})

if not vim.g.vscode then
  require("autocmd")
end ]]

---------------
-- new config
---------------

-- Load utility functions into _G.NeoUtils
require("loaders.neo-utils").load()

require("lazy-config")

-- Load main configuration files based on environment (vscode/neovim)
require("loaders.config-loader").load("config")


-- require("config.neovim.options")
-- require("config.neovim.keymap")
-- require("config.neovim.ui.statusline")
-- require("config.neovim.ui.nord-highlights")
-- require("config.neovim.autocmd")

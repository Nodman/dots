vim.g.mapleader = " "
vim.g.maplocalleader = ","
vim.uv = vim.uv or vim.loop

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

require("lazy").setup({
  {
    import = "plugins.neovim",
    cond = function()
      return not vim.g.vscode
    end,
  },
  -- { import = "plugins.always", cond = true },
  {
    import = "plugins.vscode",
    cond = function()
      return vim.g.vscode
    end,
  },
})
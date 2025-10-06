return {
  'norcalli/nvim-colorizer.lua',
  ft = {
    'tmux',
    'xml',
    'lua',
    'css',
    'scss',
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
  },
  config = function()
    require('colorizer').setup({
      'tmux',
      'xml',
      'lua',
      'css',
      'scss',
      'javascript',
      'javascriptreact',
      'typescript',
      'typescriptreact',
    })
  end,
}

return {
  's1n7ax/nvim-window-picker',
  config = function()
    require('window-picker').setup({
      autoselect_one = true,
      include_current = false,
      selection_chars = 'HJKL1234567890',
      statusline_winbar_picker = {
        use_winbar = 'smart', -- "always" | "never" | "smart"
      },
      show_prompt = false,
      filter_rules = {
        -- filter using buffer options
        bo = {
          -- if the file type is one of following, the window will be ignored
          filetype = { 'neo-tree', 'neo-tree-popup', 'notify' },

          -- if the buffer type is one of following, the window will be ignored
          buftype = { 'terminal', 'quickfix' },
        },
      },
    })
  end,
}

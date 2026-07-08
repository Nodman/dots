return {
  'aserowy/tmux.nvim',
  config = function()
    return require('tmux').setup({
      copy_sync = {
        -- tmux.nvim defaults copy_sync.enable to true, which registers a
        -- VimEnter autocmd that syncs every tmux buffer into vim registers.
        -- Binary buffer content (a NUL byte) marshals to a Blob and blows up
        -- setreg with E976. We only want pane navigation, so disable it.
        enable = false,
      },
      navigation = {
        -- cycles to opposite pane while navigating into the border
        cycle_navigation = true,

        -- enables default keybindings (C-hjkl) for normal mode
        enable_default_keybindings = false,

        -- prevents unzoom tmux when navigating beyond vim border
        persist_zoom = false,
      },
    })
  end,
}

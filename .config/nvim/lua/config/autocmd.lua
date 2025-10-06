NeoUtils.common.createAugroup({
  name = "golden_ratio",
  autocmds = {
    {
      event = { "WinLeave", "WinEnter" },
      pattern = "*",
      callback = function()
        NeoUtils.layout.autoRefresh()
      end,
      desc = "Automatically maximize window on enter/leave",
    },
  },
})

NeoUtils.common.createAugroup({
  name = "macro_cmd",
  autocmds = {
    {
      event = "RecordingEnter",
      pattern = "*",
      callback = function()
        vim.cmd("set cmdheight=1")
      end,
      desc = "Set command height to 1 when recording",
    },
    {
      event = "RecordingLeave",
      pattern = "*",
      callback = function()
        vim.cmd("set cmdheight=0")
      end,
      desc = "Set command height to 0 after recording",
    },
  },
})

NeoUtils.common.createAugroup({
  name = "hybryd_lnr",
  autocmds = {
    {
      event = "WinEnter",
      pattern = "*.js,*.jsx,*.ts,*.tsx,*.json,*.md,*.lua",
      callback = function()
        vim.cmd("set relativenumber")
      end,
      desc = "Set relative number on enter for certain filetypes",
    },
    {
      event = "WinLeave",
      pattern = "*.js,*.jsx,*.ts,*.tsx,*.json,*.md,*.lua",
      callback = function()
        vim.cmd("set norelativenumber")
      end,
      desc = "Unset relative number on leave for certain filetypes",
    },
  },
})

NeoUtils.common.createAugroup({
  name = "podfile_ft",
  autocmds = {
    {
      event = { "BufNewFile", "BufRead" },
      pattern = "Podfile",
      callback = function()
        vim.cmd("set ft=ruby")
      end,
      desc = "Set filetype to ruby for Podfile",
    },
  },
})

NeoUtils.common.createAugroup({
  name = "cmd_restore_cursor",
  autocmds = {
    {
      event = "CmdlineEnter",
      pattern = ":",
      callback = function()
        NeoUtils.cursor.restoreCursor()
      end,
      desc = "Restore cursor position on command line enter",
    },
  },
})

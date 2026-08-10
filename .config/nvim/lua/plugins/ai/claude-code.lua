local toggle_key = "<C-\\>"

return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  config = true,
  keys = {
    { toggle_key, "<cmd>ClaudeCodeFocus<cr>", desc = "Claude Code", mode = { "n", "x", "t" } },
    { "<leader>a", nil, desc = "AI/Claude Code" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
    -- Diff management
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
  },
  cmd = {
    "ClaudeCode",
    "ClaudeCodeFocus",
    "ClaudeCodeSelectModel",
    "ClaudeCodeAdd",
    "ClaudeCodeSend",
    "ClaudeCodeTreeAdd",
    "ClaudeCodeStatus",
    "ClaudeCodeStart",
    "ClaudeCodeStop",
    "ClaudeCodeOpen",
    "ClaudeCodeClose",
    "ClaudeCodeDiffAccept",
    "ClaudeCodeDiffDeny",
    "ClaudeCodeCloseAllDiffs",
  },
  opts = {
    env = {
      COLORTERM = "truecolor",
    },
    focus_after_send = false,
    diff_opts = {
      auto_close_on_accept = true,
      open_in_new_tab = true,
      hide_terminal_in_new_tab = true,
    },
    -- pty-tmux-unwrap: claude sees $TMUX and wraps OSC 52 in tmux passthrough,
    -- which nvim's :terminal can't parse (leaks "52;c;<base64>" into the UI).
    -- The shim unwraps those sequences; nvim handles the raw OSC 52 natively.
    terminal_cmd = "~/.local/scripts/pty-tmux-unwrap ~/.local/bin/claude",
    terminal = {
      -- provider = "native",
      ---@module "snacks"
      ---@type snacks.win.Config|{}
      snacks_win_opts = {
        position = "float",
        width = 0.9,
        height = 0.9,
        keys = {
          claude_hide = {
            toggle_key,
            function(self)
              self:hide()
            end,
            mode = "t",
            desc = "Hide",
          },
          -- Drop into Normal mode in place so you can scroll / visually select /
          -- yank the terminal like any buffer. Press i/a to resume typing.
          term_normal = {
            "<C-y>",
            "<C-\\><C-n>",
            mode = "t",
            desc = "Normal mode (copy/scroll)",
          },
        },
      },
    },
  },
}

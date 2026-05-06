local toggle_key = "<C-\\>"

return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  config = true,
  keys = {
    { toggle_key, "<cmd>ClaudeCodeFocus<cr>", desc = "Claude Code", mode = { "n", "x" } },
    { "<leader>a", nil, desc = "AI/Claude Code" },
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
    { "<leader>ad", "<cmd>ClaudeCode --dangerously-skip-permissions<cr>", desc = "Toggle Claude (--dsp)" },
    { "<leader>aa", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
    -- Diff management
    { "<leader>da", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
    { "<leader>dr", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
  },
  opts = {
    env = {
      COLORTERM = "truecolor",
    },
    diff_opts = {
      auto_close_on_accept = true,
      vertical_split = true,
      open_in_current_tab = false,
      keep_terminal_focus = true, -- If true, moves focus back to terminal after diff opens
    },
    terminal_cmd = "~/.local/bin/claude", -- Point to local installation
    terminal = {
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
        },
      },
    },
  },
}

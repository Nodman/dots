return {
  "pittcat/claude-fzf.nvim",
  dependencies = {
    "ibhagwan/fzf-lua",
    "coder/claudecode.nvim",
  },
  opts = {
    auto_context = true,
    batch_size = 10,
  },
  cmd = {
    "ClaudeFzf",
    "ClaudeFzfFiles",
    "ClaudeFzfGrep",
    "ClaudeFzfBuffers",
    "ClaudeFzfGitFiles",
    "ClaudeFzfDirectory",
  },
  keys = {
    { "<leader>cf", "<cmd>ClaudeFzfFiles<cr>", desc = "Claude: Add files" },
    { "<leader>cg", "<cmd>ClaudeFzfGrep<cr>", desc = "Claude: Search and add" },
    { "<leader>cb", "<cmd>ClaudeFzfBuffers<cr>", desc = "Claude: Add buffers" },
    { "<leader>cgf", "<cmd>ClaudeFzfGitFiles<cr>", desc = "Claude: Add Git files" },
    { "<leader>cd", "<cmd>ClaudeFzfDirectory<cr>", desc = "Claude: Add directory files" },
  },
}

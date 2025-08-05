return {
  "mason-org/mason.nvim",
  opts = { ensure_installed = { "gitui" } },
  keys = {
    {
      "<leader>gU",
      function()
        Snacks.terminal({ "gitui" })
      end,
      desc = "GitUi (cwd)",
    },
    {
      "<leader>gu",
      function()
        Snacks.terminal({ "gitui" }, { cwd = NeoUtils.root.get() })
      end,
      desc = "GitUi (Root Dir)",
    },
  },
  init = function()
    -- delete lazygit keymap for file history
    vim.api.nvim_create_autocmd("User", {
      pattern = "LazyVimKeymaps",
      once = true,
      callback = function()
        pcall(vim.keymap.del, "n", "<leader>gf")
        pcall(vim.keymap.del, "n", "<leader>gl")
      end,
    })
  end,
}

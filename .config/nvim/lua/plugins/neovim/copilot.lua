return {
  'github/copilot.vim',
  config = function()
    vim.api.nvim_create_autocmd('ColorScheme', {
      pattern = 'nord',
      -- group = ...,
      callback = function()
        vim.api.nvim_set_hl(0, 'CopilotSuggestion', {
          fg = '#81A1C1',
          ctermfg = 8,
          -- force = true,
        })
      end,
    })
  end,
}

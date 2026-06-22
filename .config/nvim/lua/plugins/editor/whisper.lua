return {
  "jbuck95/whisper.nvim",
  main = "whisper_nvim",
  cmd = "Whisper",
  keys = {
    { "<leader>aw", nil, desc = "Whisper" },
    { "<leader>awr", "<cmd>Whisper rec<cr>", desc = "Toggle recording" },
    { "<leader>aws", "<cmd>Whisper stream<cr>", desc = "Stream" },
    { "<leader>awf", "<cmd>Whisper file<cr>", desc = "Transcribe file" },
    {
      "<C-s>",
      function()
        NeoUtils.whisper_term.toggle()
      end,
      mode = "t",
      desc = "Whisper: dictate into terminal",
    },
  },
  opts = {
    -- Built with Metal (Apple Silicon GPU) by default; see build steps in README.
    whisper_path = vim.fn.expand("~/repos/whisper.cpp/build/bin/whisper-cli"),
    model_path = vim.fn.expand("~/repos/whisper.cpp/models/ggml-large-v3-turbo.bin"),
    language = "en",
  },
}

return {
  "j-hui/fidget.nvim",
  opts = {},
  config = function(_, opts)
    local fidget = require("fidget")
    fidget.setup(opts)
  end,
}

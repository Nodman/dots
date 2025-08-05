local palette = require("catppuccin.palettes").get_palette("latte")

local set_hl = vim.api.nvim_set_hl

-- local palette = {
--   base = "#eff1f6",
--   blue = "#1e66f6",
--   crust = "#dce0e9",
--   flamingo = "#dd7879",
--   green = "#40a02c",
--   lavender = "#7287fe",
--   mantle = "#e6e9f0",
--   maroon = "#e64554",
--   mauve = "#8839f0",
--   overlay0 = "#9ca0b1",
--   overlay1 = "#8c8fa2",
--   overlay2 = "#7c7f94",
--   peach = "#fe640c",
--   pink = "#ea76cc",
--   red = "#d20f3a",
--   rosewater = "#dc8a79",
--   sapphire = "#209fb6",
--   sky = "#04a5e6",
--   subtext0 = "#6c6f86",
--   subtext1 = "#5c5f78",
--   surface0 = "#ccd0db",
--   surface1 = "#bcc0cd",
--   surface2 = "#acb0bf",
--   teal = "#17929a",
--   text = "#4c4f6a",
--   yellow = "#df8e1e"
-- }

-- ----------------
-- statusline
-- ----------------
set_hl(0, "statusline", { ctermbg = "NONE", bg = "NONE" })
set_hl(0, "statuslinenc", { ctermbg = "NONE", bg = "NONE" })
set_hl(0, "FileBlock", { ctermbg = "NONE", ctermfg = 60, fg = palette.subtext0, bg = "NONE" })
set_hl(0, "FtBlock", { ctermbg = "NONE", ctermfg = 222, fg = palette.subtext1, bg = palette.green })

set_hl(0, "GeneralBlock", { ctermbg = "NONE", ctermfg = 60, fg = palette.blue, bg = "NONE" })
set_hl(0, "ModeBlockNormal", { bg = palette.green, fg = palette.subtext1 })
set_hl(0, "ModeBlockInsert", { bg = palette.flamingo, fg = palette.subtext1 })
set_hl(0, "ModeBlockReplace", { bg = palette.peach, fg = palette.subtext1 })
set_hl(0, "ModeBlockVisual", { bg = palette.blue, fg = palette.subtext1 })
set_hl(0, "ModeBlockVisualLine", { bg = palette.blue, fg = palette.subtext1 })
set_hl(0, "ModeBlockVisualBlock", { bg = palette.blue, fg = palette.subtext1 })
set_hl(0, "ModeBlockCommand", { bg = palette.pink, fg = palette.subtext1 })
set_hl(0, "ModeBlockTerminal", { bg = palette.yellow, fg = palette.subtext1 })

-- ----------------
-- NeoTree
-- ----------------
set_hl(0, "NeoTreeTitleBar", { bg = palette.base, fg = palette.green })
set_hl(0, "NeoTreeFloatTitle", { bg = palette.green, fg = palette.base })
set_hl(0, "NeoTreeFloatBorder", { bg = palette.base, fg = palette.base })
-- set_hl(0, "NeoTreeNormal", { bg = palette.base, fg = palette.snow1 })
-- set_hl(0, "NeoTreeFloatNormal", { fg = palette.snow2, bg = palette.night1 })
set_hl(0, "NeoTreeCursorLine", { fg = "NONE", bg = palette.surface0 })
set_hl(0, "NeoTreeNormalNC", { bg = palette.base, fg = palette.text })
set_hl(0, "NeoTreeTabInactive", { bg = palette.base, fg = palette.subtext1 })
-- set_hl(0, "NeoTreePreview", { link = "NeoTreeNormal" })

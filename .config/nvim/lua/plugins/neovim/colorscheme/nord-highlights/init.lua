local palette = {
  -- custom colors
  night5 = "#616E88",
  night0 = "#292E39",
  --
  night4 = "#4C566A",
  night3 = "#434C5E",
  night2 = "#3B4252",
  night1 = "#2E3440",

  snow3 = "#ECEFF4",
  snow2 = "#E5E9F0",
  snow1 = "#D8DEE9",

  frost4 = "#8FBCBB",
  frost3 = "#88C0D0",
  frost2 = "#81A1C1",
  frost1 = "#5E81AC",

  red = "#BF616A",
  orange = "#D08770",
  yellow = "#EBCB8B",
  green = "#A3BE8C",
  pink = "#B48EAD",

  greenFade = "#2e403a",
  redFade = "#402e34",
  yellowFade = "#403a2e",
}

local set_hl = vim.api.nvim_set_hl

-- ----------------
-- diff
-- ----------------

set_hl(0, "@diff.plus", { bg = palette.greenFade, fg = "NONE" })
set_hl(0, "diffAdded", { bg = palette.greenFade, fg = "NONE" })
set_hl(0, "DiffAdd", { bg = palette.greenFade, fg = "NONE" })
set_hl(0, "@text.diff.add", { bg = palette.greenFade, fg = "NONE" })
set_hl(0, "MiniDiffOverAdd", { bg = palette.greenFade, fg = "NONE" })

set_hl(0, "@diff.minus", { bg = palette.redFade, fg = "NONE" })
set_hl(0, "diffRemoved", { bg = palette.redFade, fg = "NONE" })
set_hl(0, "DiffDelete", { bg = palette.redFade, fg = "NONE" })
set_hl(0, "@text.diff.delete", { bg = palette.redFade, fg = "NONE" })
set_hl(0, "MiniDiffOverDelete", { bg = palette.redFade, fg = "NONE" })

set_hl(0, "@diff.delta", { bg = palette.yellowFade, fg = "NONE" })
set_hl(0, "diffChanged", { bg = palette.yellowFade, fg = "NONE" })
set_hl(0, "DiffChange", { bg = palette.yellowFade, fg = "NONE" })
set_hl(0, "@text.diff.changed", { bg = palette.yellowFade, fg = "NONE" })
set_hl(0, "MiniDiffOverContext", { bg = palette.yellowFade, fg = "NONE" })

set_hl(0, "MiniDiffOverChange", { bg = palette.yellowFade, fg = "NONE", underdashed = true })

set_hl(0, "SignColumn", { bg = "NONE" })
set_hl(0, "FloatBorder", { bg = palette.night0, fg = palette.night0 })
set_hl(0, "FloatTitle", { bg = palette.green, fg = palette.night0 })
set_hl(0, "NormalFloat", { bg = palette.night0, fg = palette.snow2 })

-- ----------------
-- NeoTree
-- ----------------
set_hl(0, "NeoTreeTitleBar", { bg = palette.night0, fg = palette.green })
set_hl(0, "NeoTreeFloatTitle", { bg = palette.green, fg = palette.night0 })
set_hl(0, "NeoTreeFloatBorder", { bg = palette.night0, fg = palette.night0 })
set_hl(0, "NeoTreeNormal", { bg = palette.night0, fg = palette.snow1 })
set_hl(0, "NeoTreeFloatNormal", { fg = palette.snow2, bg = palette.night1 })
set_hl(0, "NeoTreeNormalNC", { bg = palette.night0, fg = palette.snow1 })
set_hl(0, "NeoTreeTabInactive", { bg = palette.night0, fg = palette.night2 })
set_hl(0, "NeoTreeDirectoryIcon", { bg = "NONE", fg = palette.frost2 })
set_hl(0, "NeoTreeDirectoryName", { bg = "NONE", fg = palette.snow1, bold = true })
set_hl(0, "NeoTreePreview", { link = "NeoTreeNormal" })

-- ----------------
-- Telescope
-- ----------------
-- set_hl(0, "TelescopeNormal", { bg = palette.night0 })
-- set_hl(0, "TelescopeBorder", { bg = palette.night0, fg = palette.night0 })
-- set_hl(0, "TelescopePreviewBorder", { bg = palette.night0, fg = palette.night0 })
-- set_hl(0, "TelescopeResultsBorder", { bg = palette.night0, fg = palette.night0 })
-- set_hl(0, "TelescopeSelection", { bg = palette.night2 })
--
-- set_hl(0, "TelescopePromptNormal", { bg = palette.night0, fg = palette.snow1 })
-- set_hl(0, "TelescopePromptBorder", { bg = palette.night0, fg = palette.night0 })
-- set_hl(0, "TelescopePromptPrefix", { bg = "NONE", fg = palette.pink })
-- set_hl(0, "TelescopePromptTitle", { bg = palette.pink, fg = palette.night1 })
-- set_hl(0, "TelescopePreviewTitle", { bg = palette.green, fg = palette.night1 })

-- ----------------
-- Git Sgns
-- ----------------
set_hl(0, "GitSignsStagedAdd", { fg = palette.green, bg = "NONE" })
set_hl(0, "GitSignsStagedAddLn", { fg = palette.green, bg = "NONE" })
set_hl(0, "GitSignsStagedAddNr", { fg = palette.green, bg = "NONE" })
--
-- set_hl(0, "SnacksPickerBorder", { bg = palette.night2, fg = palette.night0 })
set_hl(0, "SnacksPickerBoxBorder", { bg = palette.night0, fg = palette.night0 })
set_hl(0, "SnacksPickerListBorder", { bg = palette.night0, fg = palette.night0 })
set_hl(0, "SnacksPickerInputBorder", { bg = palette.night0, fg = palette.night0 })
set_hl(0, "SnacksPickerPreviewBorder", { bg = palette.night0, fg = palette.night0 })

-- ----------------
-- Lsp
-- ----------------
set_hl(0, "LspFloatNormal", { fg = palette.snow2, bg = palette.night2 })
set_hl(0, "LspFloatBorder", { fg = palette.night2, bg = palette.night2 })

set_hl(0, "LspInlayHint", { fg = palette.night4, bg = "NONE" })

set_hl(0, "PmenuThumb", { bg = palette.night5 })

set_hl(0, "qfLineNr", { fg = palette.frost2 })

set_hl(0, "BlinkCmpDocBorder", { bg = palette.night0, fg = palette.night0 })

-- set_hl(0, "CmpItemAbbrDeprecated", { bg = "NONE", strikethrough = true, fg = palette.night5 })
-- -- blue
-- set_hl(0, "CmpItemAbbrMatch", { bg = "NONE", fg = palette.orange })
-- set_hl(0, "CmpItemAbbrMatchFuzzy", { link = "CmpItemAbbrMatch" })
-- -- light blue
-- set_hl(0, "CmpItemKindVariable", { bg = "NONE", fg = palette.frost2 })
-- set_hl(0, "CmpItemKindInterface", { link = "CmpItemKindVariable" })
-- set_hl(0, "CmpItemKindText", { link = "CmpItemKindVariable" })
-- -- pink
-- set_hl(0, "CmpItemKindFunction", { bg = "NONE", fg = palette.pink })
-- set_hl(0, "CmpItemKindMethod", { link = "CmpItemKindFunction" })
-- -- front
-- set_hl(0, "CmpItemKindKeyword", { bg = "NONE", fg = palette.snow1 })
-- set_hl(0, "CmpItemKindProperty", { link = "CmpItemKindKeyword" })
-- set_hl(0, "CmpItemKindUnit", { link = "CmpItemKindKeyword" })

-- ----------------
-- statusline
-- ----------------
set_hl(0, "statusline", { ctermbg = "NONE", bg = "NONE" })
set_hl(0, "statuslinenc", { ctermbg = "NONE", bg = "NONE" })
set_hl(0, "FileBlock", { ctermbg = "NONE", ctermfg = 60, fg = palette.night5, bg = "NONE" })
set_hl(0, "FtBlock", { ctermbg = "NONE", ctermfg = 222, fg = palette.night1, bg = palette.pink })

set_hl(0, "GeneralBlock", { ctermbg = "NONE", ctermfg = 60, fg = palette.pink, bg = "NONE" })
set_hl(0, "ModeBlockNormal", { bg = palette.frost4, fg = palette.night1 })
set_hl(0, "ModeBlockInsert", { bg = palette.pink, fg = palette.night1 })
set_hl(0, "ModeBlockReplace", { bg = palette.frost2, fg = palette.night1 })
set_hl(0, "ModeBlockVisual", { bg = palette.frost1, fg = palette.night1 })
set_hl(0, "ModeBlockVisualLine", { bg = palette.frost1, fg = palette.night1 })
set_hl(0, "ModeBlockVisualBlock", { bg = palette.frost1, fg = palette.night1 })
set_hl(0, "ModeBlockCommand", { bg = palette.orange, fg = palette.night1 })
set_hl(0, "ModeBlockTerminal", { bg = palette.yellow, fg = palette.night1 })

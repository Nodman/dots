local ftMap = require('config.neovim.ui.statusline.well-known-file-types')


---@alias ModeAttributes { name: string, highlight: string }

---@type table<string, ModeAttributes>
local modesMap = {
  ['n'] = { name = 'nrm', highlight = 'ModeBlockNormal' },
  ['i'] = { name = 'ins', highlight = 'ModeBlockInsert' },
  ['R'] = { name = 'rpl', highlight = 'ModeBlockReplace' },
  ['v'] = { name = 'vis', highlight = 'ModeBlockVisual' },
  ['V'] = { name = 'vln', highlight = 'ModeBlockVisualLine' },
  [' '] = { name = 'vbl', highlight = 'ModeBlockVisualBlock' },
  ['c'] = { name = 'com', highlight = 'ModeBlockCommand' },
  ['t'] = { name = 'ter', highlight = 'ModeBlockTerminal' },
}

local statusLineRest = table.concat({
  '%=',
  '%#GeneralBlock#',
  '%p%% ',
  '%l:%c ',
})

--- @param ft string
--- @return string
local function getFt(ft)
  if ft == '' then
    return '-'
  end

  return ftMap[ft] or ft
end

--- @return ModeAttributes
local function getModeAttributes()
  local mode = vim.api.nvim_get_mode().mode
  local attributes = modesMap[mode]

  if not attributes then
    -- More robust fallback
    local fallback_hl = modesMap['n'] and modesMap['n'].highlight or 'ModeBlockNormal' -- Default highlight if 'n' isn't in map
    attributes = { name = mode, highlight = fallback_hl }
  end

  return attributes
end

--- @return string
function ActiveStatusLine()
  local modeAttributes = getModeAttributes()

  return string.format(
    '%s %s %s %s %s %s %s %s %s ',
    '%#' .. modeAttributes.highlight .. '#',
    modeAttributes.name,
    '%#FileBlock#',
    vim.fn.expand('%:.'),
    '%#GeneralBlock#',
    '%m',
    statusLineRest,
    '%#FtBlock#',
    getFt(vim.bo.ft)
  )
end

vim.o.showmode = false
vim.o.laststatus = 3
vim.o.statusline = '%!v:lua.ActiveStatusLine()'

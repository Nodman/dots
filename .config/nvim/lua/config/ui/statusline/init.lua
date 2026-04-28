-- ============================================================================
-- STATUSLINE MAIN MODULE
-- ============================================================================
-- Custom statusline implementation with caching for performance.
-- Architecture:
-- - cache.lua: Caching system for expensive computations
-- - utils.lua: Helper functions for statusline components
-- - well-known-file-types.lua: Filetype display mappings
-- ============================================================================

local cache = require("config.ui.statusline.cache")
local utils = require("config.ui.statusline.utils")

-- ============================================================================
-- MAIN STATUSLINE FUNCTION (with caching)
-- ============================================================================

--- @return string
function ActiveStatusLine()
  -- Get current context
  local modeAttributes = utils.getModeAttributes()
  local win_width = vim.fn.winwidth(0)
  local filepath = vim.fn.expand("%:.")
  local filetype = vim.bo.ft
  local filetype_display = utils.getFt(filetype)
  local modified = vim.bo.modified

  -- Check cache validity
  local cached = cache.get_cache()
  if cached and cache.is_cache_valid(cached, win_width, filepath, filetype, modeAttributes.name, modified) then
    -- Cache hit: reconstruct statusline with current mode highlight
    -- (mode highlight can change more frequently than the filepath computation)
    return utils.build_statusline(
      modeAttributes.highlight,
      modeAttributes.name,
      cached.trimmed_filepath,
      filetype_display
    )
  end

  -- Cache miss: compute trimmed filepath
  local available_width = utils.calculateAvailableWidth(modeAttributes.name, filetype_display)
  local trimmed_filepath = utils.trimFilePath(filepath, available_width)

  -- Build the final statusline
  local result =
    utils.build_statusline(modeAttributes.highlight, modeAttributes.name, trimmed_filepath, filetype_display)

  -- Update cache
  cache.set_cache({
    win_width = win_width,
    filepath = filepath,
    filetype = filetype,
    mode_name = modeAttributes.name,
    modified = modified,
    trimmed_filepath = trimmed_filepath,
    result = result,
  })

  return result
end

-- ============================================================================
-- STATUSLINE SETUP
-- ============================================================================

-- Initialize cache invalidation autocommands
cache.setup()

-- Configure statusline display
vim.o.showmode = false
vim.o.laststatus = 3
vim.o.statusline = "%!v:lua.ActiveStatusLine()"

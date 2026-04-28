-- ============================================================================
-- STATUSLINE CACHING SYSTEM
-- ============================================================================
-- The statusline is rendered on every cursor movement, which is wasteful since
-- most components (filepath, window width, filetype) don't change frequently.
--
-- Cache Strategy:
-- - Store computed statusline components in buffer-local variables
-- - Cache key includes: window width, filepath, filetype, mode name
-- - Invalidate cache on: BufEnter, WinResized, VimResized, BufFilePost, BufWritePost
-- - This reduces expensive operations (trimFilePath, calculateAvailableWidth) to
--   only run when inputs actually change
-- ============================================================================

local M = {}

---@class StatuslineCache
---@field win_width number Window width when cache was computed
---@field filepath string File path when cache was computed
---@field filetype string Filetype when cache was computed
---@field mode_name string Mode name when cache was computed
---@field modified boolean Modified flag when cache was computed
---@field trimmed_filepath string The computed trimmed filepath
---@field result string The final formatted statusline string

--- Gets the cache for the current buffer
---@return StatuslineCache?
function M.get_cache()
  return vim.b.statusline_cache
end

--- Sets the cache for the current buffer
---@param cache StatuslineCache
function M.set_cache(cache)
  vim.b.statusline_cache = cache
end

--- Clears the cache for the current buffer
function M.clear_cache()
  vim.b.statusline_cache = nil
end

--- Checks if the cache is valid for current context
---@param cache StatuslineCache
---@param win_width number
---@param filepath string
---@param filetype string
---@param mode_name string
---@param modified boolean
---@return boolean
function M.is_cache_valid(cache, win_width, filepath, filetype, mode_name, modified)
  return cache.win_width == win_width
    and cache.filepath == filepath
    and cache.filetype == filetype
    and cache.mode_name == mode_name
    and cache.modified == modified
end

--- Sets up autocommands for cache invalidation
function M.setup()
  local group = vim.api.nvim_create_augroup("StatuslineCache", { clear = true })

  -- Invalidate cache when buffer, window, or file changes
  vim.api.nvim_create_autocmd({ "BufEnter", "BufFilePost", "BufWritePost" }, {
    group = group,
    callback = M.clear_cache,
    desc = "Clear statusline cache on buffer changes",
  })

  -- Invalidate cache when window is resized
  vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
    group = group,
    callback = function()
      -- Clear cache for all buffers since window width affects all statuslines
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_call(buf, M.clear_cache)
        end
      end
    end,
    desc = "Clear statusline cache on window resize",
  })
end

return M

---@diagnostic disable-next-line: undefined-field
local api = vim.api

---@class utils.layout
---@field refresh fun(size?: number)
---@field autoRefresh fun()
---@field toggleAutoRefresh fun()
---@field disableAutoRefresh boolean | nil
local M = {}

M.config = {
  minWidth = 15, -- Minimum width for non-focused windows
  autoRefreshExclusions = {
    filetype = { "toggleterm", "neo-tree" },
    buftype = { "quickfix" },
  },
  -- Functions to calculate width for specific filetypes
  -- They receive totalWidth, minWidth, windowId, and isCurrentWindow
  ---@type table<string, fun(totalWidth: number, minWidth: number, windowId: number, isCurrentWindow: boolean): number | nil>
  specialWidths = {
    tsplayground = function(totalWidth, _minWidth, _windowId, _isCurrentWindow)
      return math.floor(totalWidth / 2)
    end,
    snacks_terminal = function(totalWidth, _minWidth, windowId, _isCurrentWindow)
      return math.floor(totalWidth / 3)
    end,
  },
} -- Configuration table for module M

--- Refreshes window layout based on configuration.
---@param size? number Minimum width for non-focused windows (default: M.config.minWidth).
---@return nil
function M.refresh(size)
  local currentWindowId = api.nvim_get_current_win()
  local allWindowIds = api.nvim_list_wins()

  -- nothing to resize if < 2 windows or current is a float/popup
  if #allWindowIds < 2 or NeoUtils.window.isRelative(currentWindowId) then
    return
  end

  local minWidth = size or M.config.minWidth
  local totalWidth = 0
  local currentRow = vim.api.nvim_win_get_position(currentWindowId)[1]
  ---@type number[]
  local currentRowWindowIds = {}

  -- Calculate total width and gather windows in the current row
  for _, id in ipairs(allWindowIds) do
    if not NeoUtils.window.isRelative(id) then
      local winPos = api.nvim_win_get_position(id)
      if winPos[1] == currentRow then
        local windowWidth = api.nvim_win_get_width(id)
        totalWidth = totalWidth + windowWidth
        table.insert(currentRowWindowIds, id)
      end
    end
  end

  local windowsInRow = #currentRowWindowIds

  -- nothing to resize if < 2 windows in the current row
  if windowsInRow < 2 then
    return
  end

  -- Check if all windows in the row are diff windows
  local allDiffWindows = true
  for _, id in ipairs(currentRowWindowIds) do
    if not vim.wo[id].diff then
      allDiffWindows = false
      break
    end
  end

  if allDiffWindows then
    -- Equalize widths for diff windows
    local equalWidth = math.floor(totalWidth / windowsInRow)
    for _, id in ipairs(currentRowWindowIds) do
      api.nvim_win_set_width(id, equalWidth)
    end
    return
  end

  -- Check if current window has special width - if so, don't resize anything
  local currentFiletype = ""
  local success, result = pcall(function()
    if api.nvim_win_is_valid(currentWindowId) then
      local bufId = api.nvim_win_get_buf(currentWindowId)
      if api.nvim_buf_is_valid(bufId) and api.nvim_buf_is_loaded(bufId) then
        return vim.bo[bufId].filetype
      end
    end
    return nil
  end)

  if success and result then
    currentFiletype = result
  end

  local currentHasSpecialWidth = M.config.specialWidths[currentFiletype] ~= nil

  if currentHasSpecialWidth then
    -- Current window has special width, don't resize any windows
    return
  end

  -- Calculate widths based on configuration
  local targetWidths = {}
  local remainingWidth = totalWidth
  local defaultWindowsCount = 0
  local currentWindowIsDefault = false

  for _, id in ipairs(currentRowWindowIds) do
    local filetype = "" -- Default to empty string if filetype cannot be determined
    local success, result = pcall(function()
      -- Check if window and buffer are valid before accessing buffer options
      if api.nvim_win_is_valid(id) then
        local bufId = api.nvim_win_get_buf(id)
        if api.nvim_buf_is_valid(bufId) and api.nvim_buf_is_loaded(bufId) then
          return vim.bo[bufId].filetype
        end
      end
      return nil -- Indicate failure or invalid state
    end)

    if success and result then
      filetype = result -- Assign the retrieved filetype
    end
    -- else: filetype remains "", pcall failed or window/buffer invalid

    local isCurrent = (id == currentWindowId)
    local specialWidthFn = M.config.specialWidths[filetype]
    local targetWidth = nil

    if specialWidthFn then
      targetWidth = specialWidthFn(totalWidth, minWidth, id, isCurrent)
    end

    if targetWidth then
      targetWidth = math.max(targetWidth, minWidth) -- Ensure special width is at least minWidth
      targetWidths[id] = targetWidth
      remainingWidth = remainingWidth - targetWidth
    else
      defaultWindowsCount = defaultWindowsCount + 1
      if isCurrent then
        currentWindowIsDefault = true
      else
        -- Tentatively assign minWidth to other default windows
        remainingWidth = remainingWidth - minWidth
      end
    end
  end

  -- Calculate width for the current window if it wasn't handled specially
  local maximizedWidth = minWidth
  if currentWindowIsDefault then
    -- Width for the current window is the remaining width, but not less than minWidth
    -- Subtract minWidth for other non-current default windows
    maximizedWidth = remainingWidth -- Already accounted for minWidth for non-current defaults
    maximizedWidth = math.max(maximizedWidth, minWidth) -- Ensure at least minWidth
    targetWidths[currentWindowId] = maximizedWidth
    -- else: The current window got a special width, already handled.
  end

  -- Apply calculated widths, but only if the resulting current window width is sensible
  if not currentWindowIsDefault or (currentWindowIsDefault and maximizedWidth >= minWidth) then
    for _, id in ipairs(currentRowWindowIds) do
      local isCurrent = (id == currentWindowId)
      local widthToSet = targetWidths[id]

      if not widthToSet then
        -- This must be a non-current, non-special window
        widthToSet = minWidth
        NeoUtils.window.wrapWindow(id)
        api.nvim_win_set_width(id, widthToSet)
      elseif isCurrent then
        NeoUtils.window.unwrapWindow(0) -- Unwrap the current window
        api.nvim_win_set_width(id, widthToSet)
      else
        -- Special width window, or current window handled above
        -- Decide if wrap/unwrap is needed based on comparison to minWidth?
        -- For simplicity, let's assume special widths don't need wrapping/unwrapping
        -- unless they *are* the current window (handled above).
        -- If it's *not* the current window but has a special width, don't wrap/unwrap yet.
        api.nvim_win_set_width(id, widthToSet)
      end
    end
    -- else: calculated maximized width wasn't sensible, don't resize.
  end
end

local function shouldAutoRefresh()
  if M.disableAutoRefresh then
    return false
  end

  -- Use configurations from M.config
  for type, exclusions in pairs(M.config.autoRefreshExclusions) do
    for _, exclusion in ipairs(exclusions) do
      if NeoUtils.window.checkIs(type, exclusion) then
        return false
      end
    end
  end
  return true
end

--- Automatically refreshes layout, respecting exclusion rules.
---@return nil
function M.autoRefresh()
  if not shouldAutoRefresh() then
    return
  end
  M.refresh()
end

--- Toggles the auto-refresh behavior.
---@return nil
function M.toggleAutoRefresh()
  -- Equalize windows when disabling auto refresh
  if not M.disableAutoRefresh then
    NeoUtils.window.equalizeWindows()
  end

  M.disableAutoRefresh = not M.disableAutoRefresh
end

return M

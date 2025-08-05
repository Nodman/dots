---@class utils.notification
local M = {}

local function process_message(msg)
  if type(msg) == 'table' then
    return table.concat(msg, " ")
  end
  return msg -- Assume string if not table
end

---@param msg string | table
---@param opts snacks.notifier.Notif.opts
M.error = function(msg, opts)
  local processed_msg = process_message(msg)
  Snacks.notifier.notify(processed_msg, "error", opts)
end

---@param msg string | table
---@param opts snacks.notifier.Notif.opts
M.warn = function(msg, opts)
  local processed_msg = process_message(msg)
  Snacks.notifier.notify(processed_msg, "warn", opts)
end

---@param msg string | table
---@param opts snacks.notifier.Notif.opts
M.info = function(msg, opts)
  local processed_msg = process_message(msg)
  Snacks.notifier.notify(processed_msg, "info", opts)
end

---@param msg string | table
---@param opts snacks.notifier.Notif.opts
M.debug = function(msg, opts)
  local processed_msg = process_message(msg)
  Snacks.notifier.notify(processed_msg, "debug", opts)
end

---@param msg table
---@param opts snacks.notifier.Notif.opts
M.inspect = function(msg, opts)
  Snacks.notifier.notify(vim.inspect(msg), "info", opts)
end

return M

vim.cmd('command! Wipe %bd|e#"')

vim.api.nvim_create_user_command("TscQuickfix", function()
  local cmd =
    [[sh -c 'yarn tsc --noEmit --pretty false 2>&1 | grep -E "^[^:]+\\(.*\\): error" | sed -E "s/^([^()]+)\\(([0-9]+),([0-9]+)\\): error [^:]+: (.*)$/\\1:\\2:\\3: \\4/"']]
  local output = vim.fn.systemlist(cmd)

  local qf = {}
  for _, line in ipairs(output) do
    local filename, lnum, col, text = string.match(line, "^([^:]+):(%d+):(%d+):%s(.+)$")
    if filename and lnum and col and text then
      table.insert(qf, {
        filename = filename,
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = text:sub(1, 200), -- Trim if needed
      })
    end
  end

  vim.fn.setqflist(qf, "r")
  -- -- Get the quickfix list
  local qflist = vim.fn.getqflist()

  -- Check if the list is empty
  if #qflist == 0 then
    -- If empty, show "No errors found" notification
    NeoUtils.notification.info("No errors found", {
      title = "TSC Quickfix",
    })
  else
    -- If not empty, show error count notification and open the quickfix window
    NeoUtils.notification.warn(#qflist .. " errors found", {
      title = "TSC Quickfix",
    })
    vim.cmd("copen")
  end
end, {})

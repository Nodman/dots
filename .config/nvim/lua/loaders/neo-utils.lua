local M = {}

function M.load()
  -- Assign utils functions to global var
  _G.NeoUtils = {}

  local utils_path_pattern = vim.fn.stdpath('config') .. '/lua/utils/*.lua'
  local utils_files = vim.fn.glob(utils_path_pattern, true, true) -- Use vim.fn.glob for simpler path list

  for _, filepath in ipairs(utils_files) do
    local module_basename = vim.fn.fnamemodify(filepath, ':t')
    local module_stem = string.gsub(module_basename, '%.lua$', '')
    local module_name = 'utils.' .. module_stem

    -- Safely require the module
    local ok, module_content = pcall(require, module_name)

    if ok then
      -- Assign the entire exported content under the module stem name
      _G.NeoUtils[module_stem] = module_content
      -- Optional: Check if it was actually a table, though assigning nil/other types is fine
      -- if type(module_content) ~= 'table' then
      --  print(string.format("Warning: Utility module '%s' did not return a table.", module_name))
      -- end
    else
      -- Print error if require failed
      print(string.format("Error loading utility module '%s': %s", module_name, tostring(module_content)))
    end
  end
end

return M

local M = {}

local path_sep = package.config:sub(1, 1) -- Get OS path separator ('/' or '\\')

-- Helper to convert a full filesystem path back to a Lua module path
local function to_module_path(filepath, lua_base_path)
  -- Ensure consistent separators for string manipulation
  filepath = string.gsub(filepath, "\\", "/")
  lua_base_path = string.gsub(lua_base_path, "\\", "/")

  -- Ensure lua_base_path ends with a separator for clean removal
  if not lua_base_path:match("/$") then
    lua_base_path = lua_base_path .. "/"
  end

  local relative_path = filepath:gsub(lua_base_path, "", 1) -- Remove lua base path prefix
  local stem = relative_path:gsub("%.lua$", "") -- Remove .lua suffix
  local module_name = stem:gsub("/", ".") -- Replace path sep with dot
  return module_name
end

-- Recursive helper function
-- parent_loaded_init: boolean indicating if the parent directory was loaded via its init.lua
local function load_recursive(current_fs_path, lua_base_path, parent_loaded_init)
  local dir_iter = vim.fs.dir(current_fs_path)
  if not dir_iter then
    -- Silently ignore if directory doesn't exist or can't be read
    -- print(string.format("Config Loader: Could not open directory '%s' for recursive load", current_fs_path))
    return
  end

  for name, type in dir_iter do
    local item_fs_path = current_fs_path .. path_sep .. name
    local module_to_load = nil

    if type == "file" and name:match("%.lua$") and name ~= "init.lua" then
      -- Only load sibling files if parent dir's init.lua was NOT loaded
      if not parent_loaded_init then
        module_to_load = to_module_path(item_fs_path, lua_base_path)
      end
    elseif type == "directory" then
      local init_path = item_fs_path .. path_sep .. "init.lua"
      local stat = vim.uv.fs_stat(init_path)
      local has_init = (stat and stat.type == "file")

      if has_init then
         -- Load the directory module itself if it has init.lua
         module_to_load = to_module_path(item_fs_path, lua_base_path)
      end
       -- Always recurse into subdirectories
       -- Pass 'has_init' as the parent_loaded_init flag for the next level
      load_recursive(item_fs_path, lua_base_path, has_init)
    end

    -- Load the determined module if any (either a sibling .lua or a dir with init.lua)
    if module_to_load then
      -- print(string.format("Config Loader: Requiring module '%s'", module_to_load))
      local ok, require_err = pcall(require, module_to_load)
      if not ok then
        print(string.format("Config Loader: Error loading module '%s': %s", module_to_load, tostring(require_err)))
      end
    end
  end
end

-- Main entry point: Loads Lua files based on environment
function M.load(base_module_name)
  local target_subdir = vim.g.vscode and "vscode" or "neovim"
  local target_module_path = base_module_name .. "." .. target_subdir

  local config_base_path = vim.fn.stdpath("config")
  local lua_base_path = config_base_path .. path_sep .. "lua" .. path_sep
  local target_fs_path = lua_base_path .. string.gsub(target_module_path, "%.", path_sep)

  -- print(string.format("Config Loader: Starting load from '%s'", target_fs_path))
  -- Start recursion; parent_loaded_init is false for the top level
  load_recursive(target_fs_path, lua_base_path, false)
end

return M

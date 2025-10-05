-- Pull in WezTerm API
local wezterm = require("wezterm")

-- Utility functions
local window_background_opacity = 0.9
local function toggle_window_background_opacity(window)
  local overrides = window:get_config_overrides() or {}
  if not overrides.window_background_opacity then
    overrides.window_background_opacity = 1.0
  else
    overrides.window_background_opacity = nil
  end
  window:set_config_overrides(overrides)
end

wezterm.on("toggle-window-background-opacity", toggle_window_background_opacity)

local function toggle_ligatures(window)
  local overrides = window:get_config_overrides() or {}
  if not overrides.harfbuzz_features then
    overrides.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
  else
    overrides.harfbuzz_features = nil
  end
  window:set_config_overrides(overrides)
end
wezterm.on("toggle-ligatures", toggle_ligatures)

-- Returns color scheme dependant on operating system theme setting (dark/light)
local function color_scheme_for_appearance(appearance)
  if appearance:find("Dark") then
    return "nord"
  else
    return "Catppuccin Latte"
  end
end

wezterm.on("open-uri", function(window, pane, uri)
  -- Check if the URI starts with "term://"
  local start, match_end = uri:find("term://")
  if start == 1 then
    -- Extract the path or command from the URI
    -- Example: assuming term://c:/Users/User/docs/file.txt
    -- You would parse this to get C:/Users/User/docs/file.txt
    -- For demonstration, let's just open a specific path
    -- In a real scenario, you would parse 'uri' to extract relevant information.
    local path_to_open = uri:sub(match_end + 1)

    window:perform_action(
      wezterm.action.SpawnCommandInNewPane({
        cmd = { "your_editor_command", path_to_open }, -- Replace with your desired command
        args = {},
        cwd = nil, -- Optional: set a current working directory
      }),
      pane -- Attaching to the existing pane
    )

    -- Prevent the default action (opening in a browser)
    return false
  end

  -- If the URI is not 'term://', allow default behavior (open in browser)
  -- Do nothing here, and the function will implicitly return nil (or you can return nil explicitly)
end)

-- Initialize actual config
local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- Start tmux when opening WezTerm
config.default_prog = { "/bin/zsh", "-l", "-c", "--", "tmux new -As base" }

-- Skip closing confirmation when tmux is running
config.skip_close_confirmation_for_processes_named = { "tmux" }

-- Appearance
config.font_size = 14.0
config.color_scheme = color_scheme_for_appearance(wezterm.gui.get_appearance())
config.window_background_opacity = window_background_opacity
config.macos_window_background_blur = 10
config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = true
config.native_macos_fullscreen_mode = false
config.use_fancy_tab_bar = false
config.harfbuzz_features = { "calt = 0", "clig = 0", "liga = 0" }

-- Keybindings
config.keys = {
  -- Default QuickSelect keybind (CTRL-SHIFT-Space) gets captured by something
  -- else on my system
  {
    key = "A",
    mods = "CTRL|SHIFT",
    action = wezterm.action.QuickSelect,
  },
  {
    key = "O",
    mods = "CTRL|SHIFT",
    action = wezterm.action.EmitEvent("toggle-window-background-opacity"),
  },
  {
    key = "E",
    mods = "CTRL|SHIFT",
    action = wezterm.action.EmitEvent("toggle-ligatures"),
  },
  -- Quickly open config file with common macOS keybind
  {
    key = ",",
    mods = "SUPER",
    action = wezterm.action.SpawnCommandInNewWindow({
      cwd = os.getenv("WEZTERM_CONFIG_DIR"),
      args = { os.getenv("SHELL"), "-c", "$VISUAL $WEZTERM_CONFIG_FILE" },
    }),
  },
  -- Quickly open config file with alternative keybind
  {
    key = "<",
    mods = "CTRL|SHIFT",
    action = wezterm.action.SpawnCommandInNewWindow({
      cwd = os.getenv("WEZTERM_CONFIG_DIR"),
      args = { os.getenv("SHELL"), "-c", "$VISUAL $WEZTERM_CONFIG_FILE" },
    }),
  },
  -- Spawn Window without tmux
  {
    key = ">",
    mods = "CTRL|SHIFT",
    action = wezterm.action.SpawnCommandInNewWindow({
      args = { os.getenv("SHELL"), "-l", "-c", "zsh" },
    }),
  },
}

-- Return config to WezTerm
return config

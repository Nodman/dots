# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Formatting
- **Format Lua files**: `stylua .` - Formats all Lua files according to stylua.toml configuration (2-space indentation, 120 column width, auto-prefer double quotes)

### Package Management
- **Install Node dependencies**: `pnpm install` - Installs mcp-hub and other Node.js dependencies
- **Update lazy.nvim plugins**: Open Neovim and run `:Lazy sync` - Updates all plugins and generates lazy-lock.json

### LSP Management
- **Install LSP servers**: Open Neovim and run `:Mason` - Manages LSP servers, formatters, and linters
- **Check LSP status**: Open a file and use `<leader>cl` - Shows LSP configuration and active servers

## Architecture

### Bootstrap Flow
1. **init.lua** - Entry point that loads NeoUtils global utilities and lazy-config
2. **loaders/neo-utils.lua** - Loads all utility modules from `lua/utils/` into `_G.NeoUtils` namespace
3. **loaders/config-loader.lua** - Recursively loads configuration from `lua/config/` with init.lua precedence logic:
   - If a directory has init.lua, load it and skip sibling files
   - Otherwise, load all sibling .lua files in the directory
4. **lua/config/** - Core Neovim configuration (options, keymaps, commands, autocmds)

### Plugin System (lazy.nvim)
Plugins are organized by category in `lua/plugins/`:
- **ai/** - AI integrations (Copilot, Claude Code)
- **completion/** - Completion engine (blink.cmp)
- **editor/** - Editor enhancements (treesitter, surround, mini.diff, mini.pairs, grug-far, rest)
- **git/** - Git integrations (gitsigns, gitui)
- **lsp/** - Native LSP configuration (see LSP Architecture below)
- **system/** - System integrations (tmux, persistence, window-picker, mcp-hub, neoconf, lazy-dev)
- **ui/** - UI components (snacks.nvim, neo-tree, colorschemes, colorizer, render-markdown, which-key)

Each plugin file returns a LazySpec table. Plugins with complex configuration may have subdirectories (e.g., `ui/neo-tree/`, `lsp/lib/`).

### LSP Architecture (Native Neovim LSP)
The configuration uses **Neovim's native LSP system** (vim.lsp.config/enable) instead of nvim-lspconfig plugin:

**Entry point**: `lua/plugins/lsp/init.lua`
- Returns lazy.nvim spec for Mason and native-lsp-config plugin

**Core configuration**: `lua/plugins/lsp/lib/config.lua`
1. Initializes NeoUtils.lsp for dynamic capability handling
2. Initializes Mason integration (auto-install servers)
3. Configures diagnostics display
4. Merges capabilities from blink.cmp into global LSP config
5. Loads server configurations in order of precedence:
   - **lsp/*.lua** (project-specific configs, auto-loaded by Neovim)
   - **pack/nvim/start/nvim-lspconfig/lsp/*.lua** (fallback reference configs)
   - **M.server_configs** (manual overrides in constants.lua)
6. Registers keymaps on LspAttach and dynamic capability events
7. Enables inlay hints and codelens for supporting servers
8. Enables LSP servers via vim.lsp.enable()

**Server configurations**: `lsp/*.lua`
- Custom per-server configurations (lua_ls, vtsls, eslint, graphql, sourcekit)
- Return standard vim.lsp.ClientConfig tables
- Loaded automatically by Neovim on LSP start

**Helper modules**:
- **lib/constants.lua** - Diagnostic signs, inlay hints, codelens, capabilities, kind filters, server overrides
- **lib/mason.lua** - Mason integration for server installation
- **lib/keymaps.lua** - LSP keymaps with capability checks (uses Snacks.picker for definitions/references)

### Global Utilities (NeoUtils)
Utility modules in `lua/utils/` are automatically loaded into `_G.NeoUtils`:
- **NeoUtils.common** - Common helper functions
- **NeoUtils.icons** - Icon definitions
- **NeoUtils.layout** - Layout utilities
- **NeoUtils.lsp** - LSP helper functions:
  - `on_attach(fn, name?)` - Register LSP attach callback
  - `on_dynamic_capability(fn)` - Handle dynamic capability registration
  - `on_supports_method(method, fn)` - Run callback when method is supported
  - `action[action_name]()` - Execute code actions by kind (e.g., NeoUtils.lsp.action.source)
- **NeoUtils.notification** - Notification utilities (via Snacks)
- **NeoUtils.plugin** - Plugin management utilities
- **NeoUtils.root** - Project root detection
- **NeoUtils.window** - Window management utilities

### UI System (Snacks.nvim)
The config heavily relies on `folke/snacks.nvim` for UI components:
- **Picker** (lua/plugins/ui/snacks.lua) - Fuzzy finder for files, grep, LSP, git, etc.
  - Custom action `toggle_cwd` - Toggles between project root and cwd (<a-c>)
  - Custom action `claude_send` - Sends selected files to Claude Code (<leader>as)
- **Notifications** - Notification system
- **Input/Notifier** - Input prompts and notifications
- **Terminal** - Terminal integration
- **Toggle** - Toggle utilities for settings
- **Words** - Word highlight and navigation
- **Scroll** - Smooth scrolling

### Statusline (Custom Implementation)
Custom statusline in `lua/config/ui/statusline/`:
- **well-known-file-types.lua** - File type definitions for icons/labels
- Uses NeoUtils for rendering

## Key Patterns

### Plugin Configuration Pattern
```lua
return {
  "author/plugin-name",
  event = "VeryLazy", -- or lazy = false for immediate load
  opts = { ... }, -- options table passed to setup()
  config = function(_, opts)
    require("plugin-name").setup(opts)
  end,
}
```

### LSP Server Configuration Pattern
Create `lsp/{server_name}.lua`:
```lua
return {
  cmd = { "server-command" },
  filetypes = { "filetype" },
  root_markers = { ".git" },
  settings = {
    -- server-specific settings
  },
}
```

### Utility Module Pattern
Create `lua/utils/{module_name}.lua`:
```lua
local M = {}
-- functions here
return M
```
Available globally as `NeoUtils.{module_name}` after init.

### Custom Loader Pattern
The config-loader skips loading sibling files when a directory has init.lua. This prevents double-loading and allows directory-based organization with explicit exports.

## Important Notes

- **No nvim-lspconfig dependency**: The config uses Neovim's native LSP system (vim.lsp.config/enable). nvim-lspconfig is only referenced in pack/ for fallback server configs.
- **Mason auto-install**: Servers in `lua/plugins/lsp/init.lua` ensure_installed list are automatically installed on startup.
- **Blink.cmp integration**: Completion capabilities are merged from blink.cmp into LSP config.
- **Dynamic capabilities**: The config handles dynamic LSP capability registration (e.g., server enables formatting mid-session).
- **Snacks-first UI**: Most pickers, notifications, and UI elements use Snacks.nvim instead of telescope/notify/other plugins.

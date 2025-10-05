# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal Neovim configuration repository built with Lua, designed to work in both Neovim and VSCode environments. The configuration uses lazy.nvim as the plugin manager and implements a sophisticated dual-environment loading system.

## Architecture

### Dual Environment System

The configuration dynamically loads different modules based on whether it's running in VSCode (`vim.g.vscode`) or native Neovim:

- **VSCode mode**: Loads plugins/config from `lua/plugins/vscode/` and `lua/config/vscode/`
- **Neovim mode**: Loads plugins/config from `lua/plugins/neovim/` and `lua/config/neovim/`

This is controlled by:
1. `lua/lazy-config/init.lua` - Lazy.nvim setup with conditional plugin imports
2. `lua/loaders/config-loader.lua` - Recursive config file loader based on environment

### Config Loading System

The `config-loader.lua` implements a recursive loading strategy:
- Automatically loads all `.lua` files in the target environment directory
- If a directory has an `init.lua`, loads that instead of sibling files
- Always recurses into subdirectories
- Silently handles missing directories

### Global Utilities (_G.NeoUtils)

All utility functions are automatically loaded into `_G.NeoUtils` by `lua/loaders/neo-utils.lua`:
- Scans `lua/utils/*.lua` and assigns each module to `_G.NeoUtils[module_name]`
- Available utilities: `layout`, `icons`, `notification`, `plugin`, `window`, `cursor`, `common`, `lsp`, `root`, `config`
- Type definitions in `lua/types.lua` provide IntelliSense for NeoUtils

Access utilities anywhere as: `NeoUtils.lsp.on_attach()`, `NeoUtils.root()`, etc.

### Plugin Organization

Plugins are organized by environment:
- `lua/plugins/neovim/` - Neovim-only plugins (LSP, treesitter, UI, etc.)
  - May contain subdirectories with `init.lua` for complex plugin configurations
  - Plugin files that have been disabled are moved to `lua/plugins/innactive/`
- `lua/plugins/vscode/` - VSCode-specific plugins (minimal set)

### Key Configuration Files

- `init.lua` - Entry point: loads NeoUtils, lazy-config, and config-loader
- `lua/config/neovim/keymap.lua` - All keybindings (space = leader, comma = localleader)
- `lua/config/neovim/options.lua` - Vim options
- `lua/config/neovim/autocmd.lua` - Autocommands
- `lua/plugins/neovim/lsp/init.lua` - LSP configuration with Mason integration
- `lua/plugins/neovim/formatting.lua` - Conform.nvim formatter setup

### LSP Setup

LSP uses a centralized configuration approach:
1. `NeoUtils.lsp.setup()` - Initializes LSP handlers and dynamic capability support
2. `NeoUtils.lsp.on_attach()` - Registers keymaps and LSP features per buffer
3. Server configs in `opts.servers` table with auto-install via Mason
4. Inlay hints and codelens auto-enabled when server supports them

### Key Conventions

1. **Leader keys**: `<Space>` (leader), `,` (localleader)
2. **Keymap prefixes**:
   - `<leader>f` - File/finder operations (Snacks.picker)
   - `<leader>b` - Buffer operations
   - `<leader>w` - Window operations
   - `<leader>g` - Git operations
   - `<leader>s` - Search operations
   - `<leader>a` - AI/Claude Code operations
   - `<leader>d` - Diff operations
   - `<leader>t` - Toggle operations
3. **TMUX integration**: `<C-w>hjkl` navigate between Neovim and TMUX panes
4. **Plugin specs**: Return table from plugin files, lazy.nvim auto-loads them

## Common Operations

### Testing Configuration Changes

```bash
# Reload current Lua file
:luafile %

# Or use keymap
<leader>feR
```

### Accessing Config Files

```bash
# Open init.lua
<leader>fed

# Find config files with picker
<leader>fc
```

### LSP Operations

Mason manages LSP servers, formatters, and linters:
```bash
# Open Mason UI
:Mason

# LSP commands in code:
gd          # Go to definition (via Snacks.picker)
gr          # References (via Snacks.picker)
<leader>ss  # Document symbols
<leader>bf  # Format buffer
```

### Plugin Management

```bash
# Lazy plugin manager UI
:Lazy

# Update plugins
:Lazy update

# Check plugin status
:Lazy check
```

### Formatting

Uses `conform.nvim` with per-filetype formatters:
- Lua: stylua
- Shell: shfmt
- JavaScript/TypeScript: prettier + eslint_d
- Other web formats: prettier

Format with `<leader>bf` or automatically via LSP fallback.

### Git Integration

- GitUI for terminal git interface (via `gitui.lua` plugin)
- Git operations via Snacks.picker (`<leader>g*` keymaps)
- Inline diff viewing with mini-diff

### Claude Code Integration

Configured in `lua/plugins/neovim/claude-code/init.lua`:
- Toggle: `<C-\>` or `<leader>ac`
- Focus: `<leader>aa`
- Add buffer: `<leader>ab`
- Diff accept/deny: `<leader>da` / `<leader>dr`
- Terminal runs from `~/.claude/local/claude`

## Technical Details

### Custom LSP Utilities (`utils/lsp.lua`)

- `on_attach()` - Register callbacks when LSP attaches
- `on_supports_method()` - Run callbacks when LSP supports specific capabilities
- `on_dynamic_capability()` - Handle dynamic LSP capability registration
- `get_clients()` - Get LSP clients with filtering

### Root Directory Detection (`utils/root.lua`)

The config includes sophisticated project root detection for LSP and file operations.

### Type Safety

The codebase uses EmmyLua annotations (`---@class`, `---@type`, `---@param`) for type checking with lua_ls LSP.

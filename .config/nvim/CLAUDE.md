# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal Neovim configuration repository built with Lua. The configuration uses lazy.nvim as the plugin manager and implements a modular loading system.

## Architecture

### Config Loading System

The `config-loader.lua` implements a recursive loading strategy:
- Automatically loads all `.lua` files from `lua/config/neovim/` directory
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

Plugins are organized in `lua/plugins/neovim/`:
- Main plugin specifications (LSP, treesitter, UI, etc.)
- May contain subdirectories with `init.lua` for complex plugin configurations
- Plugin files that have been disabled are moved to `lua/plugins/innactive/`

### Key Configuration Files

- `init.lua` - Entry point: loads NeoUtils, lazy-config, and config-loader
- `lua/config/neovim/keymap.lua` - All keybindings (space = leader, comma = localleader)
- `lua/config/neovim/options.lua` - Vim options
- `lua/config/neovim/autocmd.lua` - Autocommands
- `lua/plugins/neovim/lsp-native/` - Native LSP configuration using Neovim 0.11+ APIs
  - `init.lua` - Mason plugin spec with auto-install
  - `config.lua` - Main LSP setup (diagnostics, capabilities, server configs)
  - `keymaps.lua` - LSP keymaps with Snacks picker integration
- `lua/plugins/neovim/formatting.lua` - Conform.nvim formatter setup

### LSP Setup (Native Neovim 0.11+)

LSP uses native Neovim 0.11+ APIs without nvim-lspconfig plugin:
1. `vim.lsp.config()` - Configures LSP servers (global `*` and per-server)
2. `vim.lsp.enable()` - Activates servers by name (auto-starts on matching filetypes)
3. `NeoUtils.lsp.setup()` - Initializes dynamic capability handling
4. `NeoUtils.lsp.on_attach()` - Registers keymaps when LSP attaches to buffers
5. **Mason integration** - Installs servers to `~/.local/share/nvim/mason/bin/`, native LSP calls them directly (no mason-lspconfig bridge needed)
6. **Server configs** - Defined in `M.server_configs` table in `config.lua` (lua_ls, vtsls, eslint, sourcekit)
7. **Capabilities** - Merged from `vim.lsp.protocol.make_client_capabilities()` + Blink.cmp + custom file operation support
8. **Keymaps** - Snacks pickers for gd/gr/symbols, standard vim.lsp.buf for other operations
9. Inlay hints and codelens auto-enabled when server supports them

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

Mason manages LSP servers, formatters, and linters. Native Neovim LSP APIs handle server lifecycle:
```bash
# Open Mason UI
:Mason

# Check LSP status
:LspInfo

# LSP commands in code:
gd             # Go to definition (via Snacks.picker)
gr             # References (via Snacks.picker)
<leader>ss     # Document symbols (via Snacks.picker)
<leader>sS     # Workspace symbols (via Snacks.picker)
gI             # Go to implementation
gy             # Go to type definition
K              # Hover documentation
<F2>           # Rename symbol
<leader>ca     # Code action
<leader>bf     # Format buffer
<leader>tv     # Toggle virtual text diagnostics
gh             # Show diagnostic float
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

### Adding New LSP Servers

To add a new LSP server:
1. Add server name to `M.servers` array in `lua/plugins/neovim/lsp-native/config.lua`
2. Add server-specific config to `M.server_configs` table (optional, for custom settings/root_dir)
3. Add Mason package name to `ensure_installed` in `lua/plugins/neovim/lsp-native/init.lua`
4. Reference `pack/nvim/start/nvim-lspconfig/lua/lspconfig/configs/` for server configuration examples

Example minimal server addition:
```lua
-- In config.lua
M.servers = { "lua_ls", "vtsls", "eslint", "sourcekit", "pyright" }

-- Optional server-specific config
M.server_configs.pyright = {
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "basic",
      },
    },
  },
}
```

### Custom LSP Utilities (`utils/lsp.lua`)

Native-compatible utilities for LSP management:
- `setup()` - Initializes dynamic capability handling (wraps `client/registerCapability` handler)
- `on_attach()` - Register callbacks when LSP attaches to buffers (LspAttach autocmd)
- `on_supports_method()` - Run callbacks when LSP supports specific capabilities (LspSupportsMethod event)
- `on_dynamic_capability()` - Handle dynamic LSP capability registration (LspDynamicCapability event)
- `get_clients()` - Get LSP clients with filtering (wraps `vim.lsp.get_clients()`)
- `action` - Metatable for quick code actions (e.g., `NeoUtils.lsp.action.source()`)

### Root Directory Detection (`utils/root.lua`)

The config includes sophisticated project root detection for LSP and file operations.

### Type Safety

The codebase uses EmmyLua annotations (`---@class`, `---@type`, `---@param`) for type checking with lua_ls LSP.

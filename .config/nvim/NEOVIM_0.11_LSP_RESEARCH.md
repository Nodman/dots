# Neovim 0.11 Native LSP API Research Report

**Generated:** 2025-10-08
**Purpose:** Document Neovim 0.11's native LSP capabilities to identify redundant custom utilities

---

## Executive Summary

Neovim 0.11 introduced major LSP API changes that significantly reduce the need for custom wrapper utilities and external plugins like nvim-lspconfig. The new `vim.lsp.config()` and `vim.lsp.enable()` APIs provide a native, plugin-free way to configure LSP servers. Additionally, Neovim now includes built-in handlers for dynamic capabilities, multiple client support, and advanced LSP features like folding, semantic tokens, and completion.

**Key Finding:** Most custom LSP utilities in `/Users/spooner/dots/.config/nvim/lua/utils/lsp.lua` remain valuable because Neovim does NOT provide native equivalents for:
- Dynamic capability tracking (`on_supports_method`)
- Custom `LspDynamicCapability` event emission
- Code action helpers (`M.action` metatable)

---

## What's New in Neovim 0.11 LSP

### 1. Core Configuration API

#### `vim.lsp.config(name, config)`
Defines default LSP server configurations. Configurations can be specified programmatically or via `lsp/<name>.lua` files.

**Function Signature:**
```lua
vim.lsp.config(name: string, cfg: vim.lsp.ClientConfig)
```

**Configuration Structure:**
```lua
vim.lsp.config('lua_ls', {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json', '.luarc.jsonc', '.git' },
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      workspace = { checkThirdParty = false }
    }
  }
})
```

**Configuration Merging Priority:**
1. Global `'*'` configuration
2. Configuration from `lsp/<name>.lua` files
3. Programmatically defined configurations via `vim.lsp.config()`

**Wildcard Configuration:**
```lua
vim.lsp.config('*', {
  capabilities = require('blink.cmp').get_lsp_capabilities()
})
```

#### `vim.lsp.enable(name | names)`
Auto-starts LSP servers when buffers are opened based on configured filetypes and root_markers.

**Function Signature:**
```lua
vim.lsp.enable(name: string | string[], enable?: boolean)
```

**Example:**
```lua
vim.lsp.enable({ 'lua_ls', 'ts_ls', 'pyright' })
```

**How it works:**
- Monitors buffer events (BufEnter, etc.)
- Matches buffer filetype against server's `filetypes` list
- Searches for `root_markers` to determine workspace root
- Starts server automatically if conditions are met

---

### 2. Client Management

#### `vim.lsp.get_clients(filter)`
Retrieves active LSP clients with powerful filtering capabilities.

**Function Signature:**
```lua
vim.lsp.get_clients(filter?: {
  id?: number,
  bufnr?: number,
  name?: string,
  method?: string
}): vim.lsp.Client[]
```

**Filter Parameters:**
- `id` - Filter by specific client ID
- `bufnr` - Filter by buffer number
- `name` - Filter by server name
- `method` - Filter by LSP method/capability support

**Examples:**
```lua
-- Get all clients for current buffer
local clients = vim.lsp.get_clients({ bufnr = 0 })

-- Get clients that support a specific method
local formatters = vim.lsp.get_clients({
  bufnr = 0,
  method = 'textDocument/formatting'
})

-- Get specific client by name
local lua_ls = vim.lsp.get_clients({ name = 'lua_ls' })[1]
```

**Deprecation Note:** `vim.lsp.get_active_clients()` is deprecated in favor of `vim.lsp.get_clients()`.

#### `vim.lsp.get_client_by_id(id)`
Retrieves a specific client by ID.

**Function Signature:**
```lua
vim.lsp.get_client_by_id(id: number): vim.lsp.Client?
```

---

### 3. LSP Client Object

#### Client Properties
```lua
client.id                    -- number: Unique client ID
client.name                  -- string: Server name
client.attached_buffers      -- table<number, true>: Map of attached buffer numbers
client.workspace_folders     -- { uri: string, name: string }[]
client.server_capabilities   -- table: Static capabilities from server initialization
client.dynamic_capabilities  -- table: Capabilities registered dynamically at runtime
client.config                -- vim.lsp.ClientConfig: Client configuration
```

#### Client Methods
All client methods can now be called as methods (Neovim 0.11+):

```lua
-- Old style (still works)
if client.supports_method('textDocument/formatting') then
  -- ...
end

-- New style (preferred)
if client:supports_method('textDocument/formatting') then
  -- ...
end
```

**Key Methods:**
- `client:supports_method(method, opts?)` - Check if client supports a method
- `client:request(method, params, handler, bufnr)` - Send LSP request
- `client:notify(method, params)` - Send LSP notification
- `client:request_sync(method, params, timeout_ms, bufnr)` - Synchronous request
- `client:is_stopped()` - Check if client is stopped
- `client:stop(force?)` - Stop the client

---

### 4. Dynamic Capability Support

Neovim 0.11 has **built-in support for dynamic capability registration** (`client/registerCapability`), but does **NOT** emit user-facing events automatically.

**How Neovim Handles Dynamic Capabilities:**
1. Server sends `client/registerCapability` request
2. Neovim's built-in handler updates `client.dynamic_capabilities`
3. `client.supports_method()` checks both static and dynamic capabilities
4. **NO automatic event is emitted** for user autocmds

**Critical Issue:**
The `LspAttach` event fires before dynamic capabilities are registered, meaning `client.supports_method()` may return `false` for capabilities that will be registered moments later.

**Current Solution (Custom):**
The existing `/Users/spooner/dots/.config/nvim/lua/utils/lsp.lua` implements a wrapper around the `client/registerCapability` handler to emit a custom `User LspDynamicCapability` event. This is **NOT redundant** - Neovim does not provide this.

---

### 5. LSP Events (Autocmds)

#### LspAttach
Triggered when an LSP client attaches to a buffer.

**Event Data:**
```lua
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local bufnr = args.buf
    local client_id = args.data.client_id
    local client = vim.lsp.get_client_by_id(client_id)
  end
})
```

#### LspDetach
Triggered when an LSP client detaches from a buffer.

**Event Data:**
```lua
vim.api.nvim_create_autocmd('LspDetach', {
  callback = function(args)
    local bufnr = args.buf
    local client_id = args.data.client_id
  end
})
```

#### LspRequest (New in 0.11)
Triggered for each LSP request status change (`pending`, `complete`, `cancel`).

**Event Data:**
```lua
vim.api.nvim_create_autocmd('LspRequest', {
  callback = function(args)
    local bufnr = args.buf
    local client_id = args.data.client_id
    local request_id = args.data.request_id
    local request = args.data.request

    if request.type == 'pending' then
      -- Request sent to server
    elseif request.type == 'complete' then
      -- Response received from server
    elseif request.type == 'cancel' then
      -- Request was cancelled
    end
  end
})
```

**Use Cases:**
- Track LSP performance (measure request duration)
- Show loading indicators during long requests
- Debug LSP communication issues

#### LspNotify (New in 0.11)
Triggered for LSP notifications sent to the server.

**Event Data:**
```lua
vim.api.nvim_create_autocmd('LspNotify', {
  callback = function(args)
    if args.data.method == 'textDocument/didOpen' then
      -- Auto-fold imports when opening a file
      vim.lsp.foldclose('imports', vim.fn.bufwinid(args.buf))
    end
  end
})
```

---

### 6. Code Actions

#### `vim.lsp.buf.code_action(options)`
Executes code actions with improved filtering and multi-client support.

**Breaking Change in 0.11:**
- Now shows client name when multiple clients provide actions
- Resolves `command` property during `codeAction/resolve` request
- No longer triggers global handlers from `vim.lsp.handlers`

**Function Signature:**
```lua
vim.lsp.buf.code_action({
  context?: {
    only?: string[],        -- Filter by code action kind
    diagnostics?: table[]   -- Associated diagnostics
  },
  filter?: function,         -- Custom filter function
  apply?: boolean,           -- Apply first action without prompting
  range?: {                  -- Range for code action (auto-detected in visual mode)
    start: { line, character },
    end: { line, character }
  }
})
```

**Examples:**
```lua
-- Show all code actions
vim.lsp.buf.code_action()

-- Organize imports (apply immediately)
vim.lsp.buf.code_action({
  context = { only = { 'source.organizeImports' } },
  apply = true
})

-- Source actions only
vim.lsp.buf.code_action({
  context = { only = { 'source' } }
})

-- Quickfix actions only
vim.lsp.buf.code_action({
  context = { only = { 'quickfix' } }
})

-- Refactor actions only
vim.lsp.buf.code_action({
  context = { only = { 'refactor' } }
})
```

**Common Code Action Kinds:**
- `source` - Source-level actions (organize imports, fix all)
- `source.organizeImports` - Organize imports
- `source.fixAll` - Fix all auto-fixable issues
- `quickfix` - Quick fixes for diagnostics
- `refactor` - Refactoring actions
- `refactor.extract` - Extract to function/variable/constant
- `refactor.inline` - Inline variable/function
- `refactor.rewrite` - Rewrite expressions

**Deprecation Note:** `vim.lsp.buf.range_code_action()` is deprecated - use `vim.lsp.buf.code_action()` with the `range` parameter.

---

### 7. Formatting

#### `vim.lsp.buf.format(options)`
Formats a buffer using LSP servers.

**Function Signature:**
```lua
vim.lsp.buf.format({
  async?: boolean,           -- Asynchronous formatting (default: false)
  timeout_ms?: number,       -- Timeout for synchronous formatting (default: 1000)
  filter?: function,         -- Filter which clients to use
  id?: number,               -- Specific client ID to use
  name?: string,             -- Specific client name to use
  bufnr?: number,            -- Buffer to format (default: current)
  range?: {                  -- Format specific range
    start: { line, character },
    end: { line, character }
  }
})
```

**Examples:**
```lua
-- Synchronous format on save
vim.api.nvim_create_autocmd('BufWritePre', {
  callback = function()
    vim.lsp.buf.format({ async = false, timeout_ms = 3000 })
  end
})

-- Format with specific server
vim.lsp.buf.format({ name = 'null-ls' })

-- Format only with servers supporting range formatting
vim.lsp.buf.format({
  filter = function(client)
    return client.supports_method('textDocument/rangeFormatting')
  end
})
```

**Deprecation Note:**
- `vim.lsp.buf.formatting()` is deprecated
- `vim.lsp.buf.formatting_sync()` is deprecated
- Use `vim.lsp.buf.format({ async = true/false })`

---

### 8. Built-in Completion

#### `vim.lsp.completion.enable()`
Enables built-in LSP completion (new in 0.11).

**Function Signature:**
```lua
vim.lsp.completion.enable(
  enable: boolean,
  client_id: number,
  bufnr: number,
  opts?: {
    autotrigger?: boolean,  -- Auto-trigger completion
    convert?: function      -- Transform CompletionItem
  }
)
```

**Features:**
- Built-in snippet expansion
- Command execution on completion
- Additional text edits (auto-imports)
- Trigger characters from server

**Example:**
```lua
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    vim.lsp.completion.enable(true, args.data.client_id, args.buf, {
      autotrigger = true
    })
  end
})
```

**Recommended Settings:**
```lua
vim.opt.completeopt = { 'menuone', 'noselect', 'popup' }
```

**Note:** Most users prefer dedicated completion engines like `blink.cmp` or `nvim-cmp` for better UX.

---

### 9. Inlay Hints

#### `vim.lsp.inlay_hint.enable()`
Enables/disables inlay hints for a buffer or globally.

**Function Signature:**
```lua
vim.lsp.inlay_hint.enable(
  enable: boolean,
  opts?: { bufnr?: number }
)
```

**Examples:**
```lua
-- Enable for current buffer
vim.lsp.inlay_hint.enable(true)

-- Enable for specific buffer
vim.lsp.inlay_hint.enable(true, { bufnr = 5 })

-- Disable globally
vim.lsp.inlay_hint.enable(false)
```

#### `vim.lsp.inlay_hint.is_enabled()`
Checks if inlay hints are enabled.

**Function Signature:**
```lua
vim.lsp.inlay_hint.is_enabled(opts?: { bufnr?: number }): boolean
```

**Example:**
```lua
if vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }) then
  print('Inlay hints enabled')
end
```

#### `vim.lsp.inlay_hint.get()`
Retrieves inlay hints for a buffer.

**Function Signature:**
```lua
vim.lsp.inlay_hint.get(opts?: { bufnr?: number }): table[]
```

---

### 10. Code Lens

#### `vim.lsp.codelens.refresh()`
Refreshes code lenses for a buffer.

**Function Signature:**
```lua
vim.lsp.codelens.refresh(opts?: { bufnr?: number })
```

**Example:**
```lua
-- Refresh code lenses on text change
vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'InsertLeave' }, {
  callback = function()
    vim.lsp.codelens.refresh()
  end
})
```

#### `vim.lsp.codelens.run()`
Executes a code lens action.

**Function Signature:**
```lua
vim.lsp.codelens.run()
```

---

### 11. Semantic Tokens

Neovim automatically enables semantic token highlighting when servers support it.

**Disabling Semantic Tokens:**
```lua
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client then
      client.server_capabilities.semanticTokensProvider = nil
    end
  end
})
```

**Inspecting Semantic Highlights:**
```vim
:Inspect
```

**API Changes in 0.11:**
- `vim.lsp.semantic_tokens.start()` renamed to `vim.lsp.semantic_tokens.enable()`
- `vim.lsp.semantic_tokens.stop()` removed

---

### 12. LSP Folding

#### `vim.lsp.foldexpr()`
Provides LSP-based code folding via the `textDocument/foldingRange` method.

**Setup:**
```lua
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.lsp.foldexpr()'
```

#### `vim.lsp.foldtext()`
Provides fold text from server's `collapsedText` (falls back to first line).

**Setup:**
```lua
vim.opt.foldtext = 'v:lua.vim.lsp.foldtext()'
```

---

### 13. Tag Navigation

#### `vim.lsp.tagfunc()`
Integrates LSP with Vim's tag navigation (CTRL-], CTRL-W ], etc.).

**Default Behavior:**
- `'tagfunc'` is automatically set to `vim.lsp.tagfunc()` on LspAttach
- Normal mode commands use `textDocument/definition`
- Tag commands like `:tjump` use `workspace/symbol`
- Falls back to built-in tags if LSP fails

---

### 14. Format Expression

#### `vim.lsp.formatexpr()`
Integrates LSP formatting with Vim's `gq` operator.

**Default Behavior:**
- `'formatexpr'` is automatically set to `vim.lsp.formatexpr()` on LspAttach
- Enables `gq` to format lines/ranges using LSP

---

### 15. Diagnostics

Diagnostics are configured globally via `vim.diagnostic.config()`.

**Configuration Options:**
```lua
vim.diagnostic.config({
  underline = true,
  update_in_insert = false,
  virtual_text = {
    spacing = 4,
    source = 'if_many',
    prefix = '●',
  },
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = ' ',
      [vim.diagnostic.severity.WARN] = ' ',
      [vim.diagnostic.severity.INFO] = ' ',
      [vim.diagnostic.severity.HINT] = ' ',
    }
  },
  float = {
    border = 'rounded',
    source = 'always',
    header = '',
    prefix = '',
  }
})
```

**Built-in Functions:**
- `vim.diagnostic.get(bufnr?, opts?)` - Get diagnostics
- `vim.diagnostic.count(bufnr?, opts?)` - Count diagnostics by severity
- `vim.diagnostic.is_enabled(bufnr?)` - Check if diagnostics enabled
- `vim.diagnostic.enable(enable, opts?)` - Enable/disable diagnostics
- `vim.diagnostic.reset(namespace?, bufnr?)` - Clear diagnostics
- `vim.diagnostic.open_float(opts?)` - Show diagnostic float
- `vim.diagnostic.setloclist(opts?)` - Populate location list
- `vim.diagnostic.setqflist(opts?)` - Populate quickfix list

---

### 16. Default LSP Keymaps (Neovim 0.11)

Neovim 0.11 includes default LSP keymaps:

| Keymap   | Action                        | LSP Method                          |
|----------|-------------------------------|-------------------------------------|
| `grn`    | Rename                        | `textDocument/rename`               |
| `grr`    | References                    | `textDocument/references`           |
| `gri`    | Implementation                | `textDocument/implementation`       |
| `gO`     | Document symbols              | `textDocument/documentSymbol`       |
| `gra`    | Code actions                  | `textDocument/codeAction`           |
| `CTRL-S` | Signature help (insert mode)  | `textDocument/signatureHelp`        |
| `[d`     | Previous diagnostic           | -                                   |
| `]d`     | Next diagnostic               | -                                   |

**Note:** These can be disabled if you prefer custom keymaps.

---

### 17. Handler Breaking Changes

**Global Handlers No Longer Triggered (Breaking Change):**

In Neovim 0.10 and earlier, you could override global handlers:
```lua
-- OLD (Neovim 0.10) - No longer works in 0.11
vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
  vim.lsp.handlers.hover,
  { border = 'rounded' }
)
```

**Why it changed:**
To properly support multiple LSP clients per buffer, Neovim now directly invokes handlers rather than going through the global handlers table.

**New Approach:**
Use the global `vim.o.winborder` option or override functions directly:
```lua
-- Set default border for all floating windows
vim.o.winborder = 'rounded'

-- Or wrap the function
local orig_hover = vim.lsp.buf.hover
vim.lsp.buf.hover = function()
  orig_hover({ border = 'rounded' })
end
```

**Deprecated Handlers:**
- `vim.lsp.handlers.signature_help()` - No longer used
- Global handler overrides via `vim.lsp.handlers[method]` - No longer respected

---

## Analysis: Custom LSP Utilities

### Current Implementation Review

The current `/Users/spooner/dots/.config/nvim/lua/utils/lsp.lua` provides:

1. **`M.get_clients(opts)`** - Extended filter with custom `filter` function
2. **`M.on_attach(on_attach, name?)`** - LspAttach wrapper with name filtering
3. **`M.on_dynamic_capability(fn)`** - Custom event for dynamic capability registration
4. **`M.on_supports_method(method, fn)`** - Callback when method is supported
5. **`M.action` metatable** - Shorthand for code actions by kind
6. **`M.setup()`** - Registers custom handlers and events

---

### Utility Analysis

#### 1. `M.get_clients(opts)` - **PARTIALLY REDUNDANT**

**Current Implementation:**
```lua
function M.get_clients(opts)
  local ret = vim.lsp.get_clients(opts)
  return opts and opts.filter and vim.tbl_filter(opts.filter, ret) or ret
end
```

**Native Equivalent:**
Neovim's `vim.lsp.get_clients()` supports `id`, `bufnr`, `name`, and `method` filters natively. However, it does **NOT** support custom filter functions.

**Verdict:**
- Basic filtering: **REDUNDANT** (use `vim.lsp.get_clients()` directly)
- Custom filter function: **USEFUL** (keep for advanced filtering)

**Recommendation:** Keep for the custom `filter` function support, but most use cases can use native API.

---

#### 2. `M.on_attach(on_attach, name?)` - **CONVENIENT WRAPPER**

**Current Implementation:**
```lua
function M.on_attach(on_attach, name)
  return vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local buffer = args.buf
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and (not name or client.name == name) then
        return on_attach(client, buffer)
      end
    end,
  })
end
```

**Native Equivalent:**
```lua
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client then
      on_attach(client, args.buf)
    end
  end
})
```

**Verdict:** **CONVENIENT** - Simplifies common pattern, adds name filtering.

**Recommendation:** Keep for ergonomics, but could be inlined if minimalism is preferred.

---

#### 3. `M.on_dynamic_capability(fn)` - **NOT REDUNDANT** ⭐

**Current Implementation:**
Wraps the `client/registerCapability` handler to emit a custom `User LspDynamicCapability` event.

**Native Equivalent:**
**NONE** - Neovim does not emit any user-facing event when capabilities are dynamically registered.

**Verdict:** **ESSENTIAL** - This is a custom solution to a real problem that Neovim does not address natively.

**Recommendation:** **KEEP** - This is valuable functionality that should not be removed.

---

#### 4. `M.on_supports_method(method, fn)` - **NOT REDUNDANT** ⭐

**Current Implementation:**
Tracks which clients support which methods across buffers and emits a custom `User LspSupportsMethod` event.

**Native Equivalent:**
**NONE** - While `client.supports_method()` exists, there's no event-based mechanism to run callbacks when a method becomes available (including after dynamic registration).

**Verdict:** **ESSENTIAL** - Solves the dynamic capability timing problem elegantly.

**Recommendation:** **KEEP** - This is a sophisticated solution that handles edge cases (dynamic capabilities, multiple buffers).

---

#### 5. `M.action` metatable - **CONVENIENT SHORTHAND** ⭐

**Current Implementation:**
```lua
M.action = setmetatable({}, {
  __index = function(_, action)
    return function()
      vim.lsp.buf.code_action({
        apply = true,
        context = {
          only = { action },
          diagnostics = {},
        },
      })
    end
  end,
})
```

**Usage:**
```lua
NeoUtils.lsp.action.source.organizeImports()  -- Organize imports
NeoUtils.lsp.action.quickfix()                -- Apply quickfix
NeoUtils.lsp.action.refactor.extract()        -- Extract function
```

**Native Equivalent:**
```lua
vim.lsp.buf.code_action({
  apply = true,
  context = { only = { 'source.organizeImports' } }
})
```

**Verdict:** **HIGHLY CONVENIENT** - Provides excellent ergonomics for common operations.

**Recommendation:** **KEEP** - This is idiomatic Lua and provides significant value.

---

#### 6. `M.setup()` - **ESSENTIAL COORDINATOR**

**Current Implementation:**
- Wraps `client/registerCapability` handler
- Registers `M._check_methods` on LspAttach and dynamic capability
- Coordinates the entire dynamic capability system

**Native Equivalent:**
**NONE** - This is the orchestration layer for custom functionality.

**Verdict:** **ESSENTIAL** - Required for the custom event system to work.

**Recommendation:** **KEEP**

---

## Recommendations

### Keep These Custom Utilities

1. **`M.on_dynamic_capability(fn)`** - Neovim has no equivalent
2. **`M.on_supports_method(method, fn)`** - Solves dynamic capability timing issues
3. **`M.action` metatable** - Excellent ergonomics for code actions
4. **`M.setup()`** - Required coordinator for custom events

### Optional to Keep

1. **`M.on_attach(on_attach, name?)`** - Convenient wrapper, but not essential
2. **`M.get_clients(opts)`** - Only needed if using custom filter functions

### Can Remove/Simplify

- None. All utilities provide value.

---

## Migration Considerations

### What nvim-lspconfig Still Provides

Even with Neovim 0.11's native APIs, **nvim-lspconfig remains useful for**:
1. **Server configurations** in `lsp/<server>.lua` files (cmd, filetypes, settings)
2. **Reference configurations** for 100+ language servers
3. **Community-maintained** server-specific knowledge

**What's deprecated:**
- The `require('lspconfig').server.setup()` API
- The `lspconfig` Lua module (framework)

**What's NOT deprecated:**
- The `lsp/<server>.lua` configuration files
- The plugin as a reference for server configurations

### Current Config Assessment

The current `/Users/spooner/dots/.config/nvim/lua/plugins/lsp/lib/config.lua`:

1. ✅ Uses `vim.lsp.config()` and `vim.lsp.enable()` (native API)
2. ✅ Loads configs from local `lsp/` directory (Neovim auto-loads these)
3. ✅ Falls back to nvim-lspconfig reference configs (good practice)
4. ✅ Uses custom utilities appropriately (`on_attach`, `on_supports_method`)
5. ✅ Handles dynamic capabilities for keymaps and features

**Verdict:** Your current configuration is **already aligned with Neovim 0.11 best practices**.

---

## Code Examples

### Example 1: Enable LSP Server Without Any Plugin

```lua
-- ~/.config/nvim/lsp/lua_ls.lua
return {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json', '.git' },
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
      workspace = {
        library = vim.api.nvim_get_runtime_file('', true),
        checkThirdParty = false,
      },
    },
  },
}
```

```lua
-- ~/.config/nvim/init.lua
vim.lsp.enable('lua_ls')
```

### Example 2: Global Configuration with Capabilities

```lua
-- Merge capabilities from completion plugin
local capabilities = vim.tbl_deep_extend(
  'force',
  vim.lsp.protocol.make_client_capabilities(),
  require('blink.cmp').get_lsp_capabilities()
)

-- Apply to all servers
vim.lsp.config('*', {
  capabilities = capabilities
})
```

### Example 3: Setup Keymaps on LspAttach

```lua
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local bufnr = args.buf

    -- Only set keymaps if client supports method
    if client:supports_method('textDocument/definition') then
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = bufnr })
    end

    if client:supports_method('textDocument/formatting') then
      vim.keymap.set('n', '<leader>cf', vim.lsp.buf.format, { buffer = bufnr })
    end
  end
})
```

### Example 4: Handle Dynamic Capabilities (Custom Solution)

```lua
-- Wrap the native handler to emit custom events
local register_capability = vim.lsp.handlers['client/registerCapability']
vim.lsp.handlers['client/registerCapability'] = function(err, res, ctx)
  local ret = register_capability(err, res, ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)

  if client then
    for buffer in pairs(client.attached_buffers) do
      -- Emit custom event
      vim.api.nvim_exec_autocmds('User', {
        pattern = 'LspDynamicCapability',
        data = { client_id = client.id, buffer = buffer }
      })
    end
  end

  return ret
end

-- Listen for dynamic capability registration
vim.api.nvim_create_autocmd('User', {
  pattern = 'LspDynamicCapability',
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local buffer = args.data.buffer

    -- Re-check capabilities and update keymaps
    if client:supports_method('textDocument/formatting') then
      vim.keymap.set('n', '<leader>cf', vim.lsp.buf.format, { buffer = buffer })
    end
  end
})
```

### Example 5: Code Actions by Kind

```lua
-- Using native API (verbose)
vim.keymap.set('n', '<leader>co', function()
  vim.lsp.buf.code_action({
    apply = true,
    context = { only = { 'source.organizeImports' } }
  })
end)

-- Using custom utility (ergonomic)
vim.keymap.set('n', '<leader>co', NeoUtils.lsp.action['source.organizeImports'])
```

### Example 6: Enable Inlay Hints When Supported

```lua
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    if client:supports_method('textDocument/inlayHint') then
      vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
    end
  end
})
```

### Example 7: Track LSP Request Performance

```lua
vim.api.nvim_create_autocmd('LspRequest', {
  callback = function(args)
    local request = args.data.request

    if request.type == 'pending' then
      request.start_time = vim.loop.hrtime()
    elseif request.type == 'complete' then
      local duration = (vim.loop.hrtime() - request.start_time) / 1e6
      print(string.format('%s took %.2fms', request.method, duration))
    end
  end
})
```

---

## Conclusion

Neovim 0.11 has dramatically improved the native LSP experience, making it possible to configure LSP servers without external plugins. However, several aspects still require custom utilities:

1. **Dynamic capability events** - Not provided by Neovim
2. **Method support callbacks** - No native event system
3. **Ergonomic code action API** - Native API is verbose

**Your current LSP utilities are NOT redundant** and should be kept. They solve real problems that Neovim 0.11 does not address natively. The configuration is modern, well-architected, and takes full advantage of the new native APIs while filling in the gaps with custom utilities.

---

## Further Reading

- **Official Documentation:** `:help lsp` in Neovim 0.11
- **Release Notes:** `:help news-0.11`
- **LSP Quickstart:** `:help lsp-quickstart`
- **API Reference:** https://neovim.io/doc/user/lsp.html
- **Greg Anders' Blog:** https://gpanders.com/blog/whats-new-in-neovim-0-11/
- **LSP Configuration Guide:** https://goral.net.pl/post/lsp-configuration-in-neovim-011/

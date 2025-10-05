# Native LSP Migration Guide - Complete & Concise

**Goal:** Migrate to native Neovim 0.11+ LSP while keeping Mason for server management and all current features.

**What Changes:** Remove nvim-lspconfig and mason-lspconfig plugins, use native `vim.lsp.config()` and `vim.lsp.enable()`

**What Stays:** Mason for installation, all keymaps, Snacks pickers, Blink.cmp, inlay hints, code lens, diagnostics, icons

**Time:** ~2 hours

---

## Quick Overview

### Current Setup → Native Setup

```
OLD: nvim-lspconfig → mason-lspconfig → Mason → servers
NEW: lsp/*.lua configs → vim.lsp.enable() → Mason → servers
```

**Plugins to Remove:**
- ❌ `neovim/nvim-lspconfig`
- ❌ `mason-org/mason-lspconfig.nvim`

**Plugins to Keep:**
- ✅ `williamboman/mason.nvim` (still manages installation)
- ✅ All other plugins (Snacks, Blink.cmp, etc.)

---

## Mason + Native LSP Integration

### How It Works

1. **Mason installs** servers to `~/.local/share/nvim/mason/bin/`
2. **Mason adds** this directory to Neovim's PATH
3. **Native LSP** calls server commands directly (they're in PATH)
4. **No bridge needed** - servers "just work"

### Server Name Mapping

Mason package names → LSP server names:

```lua
-- Mason installs:          Native LSP uses:
lua-language-server    →    lua_ls
typescript-language-server → vtsls (or ts_ls)
vscode-langservers-extracted → eslint
sourcekit-lsp          →    sourcekit
rust-analyzer          →    rust_analyzer
pyright                →    pyright
```

Full list: https://mason-registry.dev/registry/list

---

## File Structure (After Migration)

```
~/.config/nvim/
├── lsp/                          # NEW: Native server configs
│   ├── lua_ls.lua
│   ├── vtsls.lua
│   ├── eslint.lua
│   └── sourcekit.lua
├── lua/
│   ├── plugins/
│   │   └── neovim/
│   │       ├── lsp-native/       # NEW: Native LSP plugin
│   │       │   ├── init.lua      # Mason + setup
│   │       │   ├── config.lua    # Main LSP config
│   │       │   └── keymaps.lua   # LSP keymaps
│   │       └── lsp/              # OLD: Move to innactive/
│   └── utils/
│       └── lsp.lua               # UPDATED: Remove lspconfig functions
└── init.lua
```

---

## Migration Steps - TODO List

### Phase 1: Setup (15 min)

- [ ] **1.1 Backup:** `git commit -am "Backup before native LSP migration"`
- [ ] **1.2 Create directories:** `mkdir -p lsp lua/plugins/neovim/lsp-native`
- [ ] **1.3 Get lspconfig reference (optional):**
  ```bash
  # Option A: Official location (for Neovim packages)
  git clone https://github.com/neovim/nvim-lspconfig ~/.config/nvim/pack/nvim/start/nvim-lspconfig

  # Option B: Separate reference (recommended)
  mkdir -p ~/dev/references
  git clone https://github.com/neovim/nvim-lspconfig ~/dev/references/nvim-lspconfig
  ```

### Phase 2: Create Server Configs (20 min)

- [ ] **2.1 Create `lsp/lua_ls.lua`:**
  ```lua
  return {
    cmd = { 'lua-language-server' },
    filetypes = { 'lua' },
    root_markers = { '.luarc.json', '.luarc.jsonc', '.git' },
    single_file_support = true,
    settings = {
      Lua = {
        workspace = { checkThirdParty = false },
        codeLens = { enable = true },
        completion = { callSnippet = "Replace" },
        doc = { privateName = { "^_" } },
        hint = {
          enable = true,
          setType = false,
          paramType = true,
          paramName = "Disable",
          semicolon = "Disable",
          arrayIndex = "Disable",
        },
      },
    },
  }
  ```

- [ ] **2.2 Create `lsp/vtsls.lua`:**
  ```lua
  return {
    cmd = { 'vtsls', '--stdio' },
    filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'vue' },
    root_markers = { 'package.json', 'tsconfig.json', 'jsconfig.json', '.git' },
    single_file_support = true,
    settings = {
      experimental = {
        completion = { enableServerSideFuzzyMatch = true }
      }
    },
  }
  ```

- [ ] **2.3 Create `lsp/eslint.lua`:**
  ```lua
  return {
    cmd = { 'vscode-eslint-language-server', '--stdio' },
    filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'vue' },
    root_markers = { '.eslintrc', '.eslintrc.js', '.eslintrc.json', 'eslint.config.js', 'package.json', '.git' },
    settings = {
      workingDirectory = { mode = "auto" },
      format = true,
    },
  }
  ```

- [ ] **2.4 Create `lsp/sourcekit.lua`:**
  ```lua
  return {
    cmd = { 'sourcekit-lsp' },
    filetypes = { 'swift', 'objective-c', 'objective-cpp' },
    root_markers = { 'buildServer.json', { '*.xcodeproj', '*.xcworkspace' }, 'Package.swift', '.git' },
    capabilities = {
      workspace = {
        didChangeWatchedFiles = { dynamicRegistration = true }
      }
    },
  }
  ```

### Phase 3: Update Utils (10 min)

- [ ] **3.1 Update `lua/utils/lsp.lua`:**

  **Delete these functions (lines 121-188):**
  - `M.get_config()`
  - `M.get_raw_config()`
  - `M.is_enabled()`
  - `M.disable()`
  - `M.execute()` (if unused)

  **Simplify `M.get_clients()` (lines 7-22):**
  ```lua
  ---@param opts? lsp.Client.filter
  function M.get_clients(opts)
    local ret = vim.lsp.get_clients(opts)
    return opts and opts.filter and vim.tbl_filter(opts.filter, ret) or ret
  end
  ```

### Phase 4: Create Native LSP Plugin (30 min)

- [ ] **4.1 Create `lua/plugins/neovim/lsp-native/init.lua`:**
  ```lua
  return {
    -- Mason for server installation
    {
      "williamboman/mason.nvim",
      cmd = "Mason",
      keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
      build = ":MasonUpdate",
      opts = {
        ensure_installed = {
          -- LSP servers
          "lua-language-server",
          "vtsls",
          "eslint-lsp",
          "sourcekit-lsp",
          -- Formatters
          "stylua",
          "shfmt",
        },
      },
      config = function(_, opts)
        require("mason").setup()
        local mr = require("mason-registry")

        -- Trigger FileType event after install
        mr:on("package:install:success", function()
          vim.defer_fn(function()
            require("lazy.core.handler.event").trigger({
              event = "FileType",
              buf = vim.api.nvim_get_current_buf(),
            })
          end, 100)
        end)

        -- Auto-install packages
        mr.refresh(function()
          for _, tool in ipairs(opts.ensure_installed) do
            local p = mr.get_package(tool)
            if not p:is_installed() then
              p:install()
            end
          end
        end)
      end,
    },

    -- Load native LSP config
    {
      name = "native-lsp-config",
      dir = vim.fn.stdpath("config"),
      lazy = false,
      priority = 100,
      config = function()
        require("plugins.neovim.lsp-native.config").setup()
      end,
    },
  }
  ```

- [ ] **4.2 Create `lua/plugins/neovim/lsp-native/config.lua`:**
  ```lua
  local M = {}

  M.servers = {
    'lua_ls',
    'vtsls',
    'eslint',
    'sourcekit',
  }

  M.diagnostics = {
    underline = true,
    update_in_insert = false,
    virtual_text = { spacing = 4, source = "if_many", prefix = "▪" },
    severity_sort = true,
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = "▪",
        [vim.diagnostic.severity.WARN] = "▪",
        [vim.diagnostic.severity.HINT] = "▪",
        [vim.diagnostic.severity.INFO] = "▪",
      },
    },
  }

  M.inlay_hints = {
    enabled = true,
    exclude = { "vue" },
  }

  M.codelens = {
    enabled = true,
  }

  M.capabilities = {
    workspace = {
      fileOperations = {
        didRename = true,
        willRename = true,
      },
    },
  }

  function M.setup()
    -- Initialize NeoUtils.lsp utilities
    NeoUtils.lsp.setup()

    -- Configure diagnostics
    vim.diagnostic.config(M.diagnostics)

    -- Set diagnostic signs
    for severity, icon in pairs(M.diagnostics.signs.text) do
      local name = vim.diagnostic.severity[severity]:lower():gsub("^%l", string.upper)
      name = "DiagnosticSign" .. name
      vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
    end

    -- Setup global LSP configuration
    local has_blink, blink = pcall(require, "blink.cmp")
    local capabilities = vim.tbl_deep_extend(
      "force",
      {},
      vim.lsp.protocol.make_client_capabilities(),
      has_blink and blink.get_lsp_capabilities() or {},
      M.capabilities or {}
    )

    -- Configure all servers with global settings
    vim.lsp.config('*', {
      capabilities = capabilities,
    })

    -- Setup LspAttach for keymaps
    NeoUtils.lsp.on_attach(function(client, buffer)
      require("plugins.neovim.lsp-native.keymaps").on_attach(client, buffer)
    end)

    NeoUtils.lsp.on_dynamic_capability(
      require("plugins.neovim.lsp-native.keymaps").on_attach
    )

    -- Enable inlay hints
    if M.inlay_hints.enabled then
      NeoUtils.lsp.on_supports_method("textDocument/inlayHint", function(client, buffer)
        if vim.api.nvim_buf_is_valid(buffer)
          and vim.bo[buffer].buftype == ""
          and not vim.tbl_contains(M.inlay_hints.exclude, vim.bo[buffer].filetype)
        then
          vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
        end
      end)
    end

    -- Enable code lens
    if M.codelens.enabled then
      NeoUtils.lsp.on_supports_method("textDocument/codeLens", function(client, buffer)
        vim.lsp.codelens.refresh()
        vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
          buffer = buffer,
          callback = vim.lsp.codelens.refresh,
        })
      end)
    end

    -- Setup toggle for virtual text
    Snacks.toggle({
      name = "LSP virtual text",
      get = function()
        return not not vim.diagnostic.config().virtual_text
      end,
      set = function()
        if not vim.diagnostic.config().virtual_text then
          vim.diagnostic.config({ virtual_text = M.diagnostics.virtual_text })
        else
          vim.diagnostic.config({ virtual_text = false })
        end
      end,
    }):map("<leader>tv")

    -- Enable all configured servers
    vim.lsp.enable(M.servers)
  end

  return M
  ```

- [ ] **4.3 Create `lua/plugins/neovim/lsp-native/keymaps.lua`:**

  Copy from `lua/plugins/neovim/lsp/keymaps.lua` - **NO CHANGES NEEDED**, just copy:
  ```bash
  cp lua/plugins/neovim/lsp/keymaps.lua lua/plugins/neovim/lsp-native/keymaps.lua
  ```

### Phase 5: Testing (20 min)

- [ ] **5.1 Update lazy-config:**

  Edit `lua/lazy-config/init.lua`:
  ```lua
  -- OLD:
  { import = "plugins.neovim.lsp" },

  -- NEW:
  { import = "plugins.neovim.lsp-native" },
  ```

- [ ] **5.2 Remove Snacks LSP config:**

  Edit `lua/plugins/neovim/snacks/init.lua`, delete lines 345-359:
  ```lua
  -- DELETE THIS:
  {
    "neovim/nvim-lspconfig",
    opts = function()
      -- ... (whole block)
    end,
  },
  ```

- [ ] **5.3 Restart Neovim:**
  ```bash
  nvim
  :messages  # Check for errors
  :LspInfo   # Should show servers
  :Mason     # Verify servers installed
  ```

- [ ] **5.4 Test each server:**
  - [ ] lua_ls: Open `.lua` file, test `K` hover, `gd` definition
  - [ ] vtsls: Open `.ts` file, test completion, inlay hints
  - [ ] eslint: Open `.js` file, test diagnostics, code actions
  - [ ] sourcekit: Open `.swift` file (if available)

- [ ] **5.5 Test features:**
  - [ ] All keymaps (`gd`, `gr`, `gI`, `gy`, `K`, `<leader>ca`, etc.)
  - [ ] Diagnostics with icons
  - [ ] Inlay hints
  - [ ] Code lens
  - [ ] Blink.cmp completion
  - [ ] Snacks pickers (definition, references, symbols)
  - [ ] `<leader>tv` toggle virtual text

- [ ] **5.6 Health check:**
  ```vim
  :checkhealth vim.lsp
  ```

### Phase 6: Cleanup (10 min)

- [ ] **6.1 Move old config:**
  ```bash
  mv lua/plugins/neovim/lsp lua/plugins/innactive/lsp
  ```

- [ ] **6.2 Clean plugins:**
  ```vim
  :Lazy clean
  ```
  Confirm removal of:
  - `neovim/nvim-lspconfig`
  - `mason-lspconfig.nvim`

- [ ] **6.3 Update CLAUDE.md:**
  ```markdown
  ### LSP Setup

  Native Neovim 0.11+ LSP:
  - Server configs: `lsp/*.lua`
  - Mason manages installation
  - Native APIs: `vim.lsp.config()`, `vim.lsp.enable()`
  - Config: `lua/plugins/neovim/lsp-native/`
  ```

- [ ] **6.4 Final test:**
  Code for 30+ minutes in real projects to verify stability

---

## What You Keep (Zero Loss of Features)

### ✅ All Features Preserved

| Feature | Implementation | Status |
|---------|---------------|--------|
| **LSP keymaps** | Same keymaps, native APIs | ✅ Works |
| **Snacks pickers** | LSP navigation via Snacks | ✅ Works |
| **Blink.cmp** | Completion + code actions | ✅ Works |
| **Inlay hints** | `vim.lsp.inlay_hint.enable()` | ✅ Works |
| **Code lens** | `vim.lsp.codelens.*` | ✅ Works |
| **Diagnostics** | `vim.diagnostic.config()` | ✅ Works |
| **Icons** | NeoUtils.icons integration | ✅ Works |
| **Mason** | Server installation | ✅ Works |
| **Dynamic capabilities** | NeoUtils.lsp utilities | ✅ Works |
| **Custom keymaps** | Conditional on capabilities | ✅ Works |

### 🎯 What Changes

- Plugin framework: nvim-lspconfig → native APIs
- Server configs: Table in plugin → `lsp/*.lua` files
- Setup call: `require('lspconfig').server.setup{}` → `vim.lsp.enable()`
- Dependencies: 2 fewer plugins

---

## Rollback (If Needed)

```bash
# Quick rollback
cd ~/.config/nvim

# 1. Revert import
# In lua/lazy-config/init.lua: change back to { import = "plugins.neovim.lsp" }

# 2. Restore old config
mv lua/plugins/innactive/lsp lua/plugins/neovim/lsp

# 3. Restart Neovim
```

---

## Adding New Servers (After Migration)

1. **Install via Mason:**
   ```vim
   :Mason
   # Search and install server
   ```

2. **Create config file:**
   ```bash
   nvim lsp/rust_analyzer.lua
   ```
   ```lua
   return {
     cmd = { 'rust-analyzer' },
     filetypes = { 'rust' },
     root_markers = { 'Cargo.toml', '.git' },
   }
   ```

3. **Add to server list:**
   Edit `lua/plugins/neovim/lsp-native/config.lua`:
   ```lua
   M.servers = {
     'lua_ls',
     'vtsls',
     'eslint',
     'sourcekit',
     'rust_analyzer',  -- ADD HERE
   }
   ```

4. **Restart or reload:**
   ```vim
   :Lazy reload native-lsp-config
   ```

---

## Reference: lspconfig Configs

**If you need server configs from lspconfig:**

1. **Browse reference:**
   ```bash
   # If you cloned to official location:
   ls ~/.config/nvim/pack/nvim/start/nvim-lspconfig/lua/lspconfig/server_configurations/

   # If you cloned to separate reference:
   ls ~/dev/references/nvim-lspconfig/lua/lspconfig/server_configurations/
   ```

2. **View config:**
   ```bash
   cat path/to/lspconfig/lua/lspconfig/server_configurations/gopls.lua
   ```

3. **Convert to native:**
   - Extract `cmd`, `filetypes`
   - Convert `root_dir` function → `root_markers` array
   - Copy `settings`, `capabilities`, `init_options`
   - Flatten (remove `default_config` wrapper)

---

## Troubleshooting

### Server not starting
```vim
:LspInfo                          " Check if attached
:lua vim.print(vim.lsp.get_clients())  " List active clients
:messages                         " Check for errors
```

### Server binary not found
```bash
# Check if installed
:Mason

# Verify in PATH
:lua vim.print(vim.fn.exepath('lua-language-server'))

# Manual PATH check
echo $PATH | grep mason
```

### Wrong server config
```vim
:lua vim.print(vim.lsp.config['lua_ls'])  " View merged config
```

### Keymaps not working
```vim
:verbose map gd           " Check keymap source
:lua vim.print(NeoUtils.lsp.get_clients({ bufnr = 0 }))  " Check client attached
```

---

## Key Benefits

✅ **Simpler:** 2 fewer plugins, less abstraction
✅ **Native:** Use built-in Neovim APIs
✅ **Modular:** File-based configs, easy to manage
✅ **Future-proof:** Official Neovim direction
✅ **Same features:** Zero functionality loss
✅ **Mason kept:** Still manages installation

---

## Time Estimate

- Setup: 15 min
- Server configs: 20 min
- Utils update: 10 min
- Plugin creation: 30 min
- Testing: 20 min
- Cleanup: 10 min

**Total: ~2 hours**

---

## Success Checklist

After migration, verify:

- [ ] All servers start (`:LspInfo`)
- [ ] No errors (`:messages`, `:checkhealth vim.lsp`)
- [ ] All keymaps work
- [ ] Diagnostics display correctly
- [ ] Inlay hints show
- [ ] Code lens works
- [ ] Completion works (Blink.cmp)
- [ ] Snacks pickers work
- [ ] Can code normally for 30+ minutes
- [ ] Plugins removed (`:Lazy`)

**You're done!** 🎉

---

## Resources

- **Neovim LSP docs:** `:help lsp`, `:help vim.lsp.config`
- **Mason registry:** https://mason-registry.dev/registry/list
- **Neovim 0.11 news:** https://neovim.io/doc/user/news-0.11.html
- **This config:** All code provided above, ready to use

---

*Migration guide v1.0 - Comprehensive but concise edition*

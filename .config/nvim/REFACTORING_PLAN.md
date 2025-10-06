# Neovim Config Refactoring Plan

**Date Created:** 2025-10-06
**Status:** Planning Phase
**Overall Grade:** A- (Excellent with minor improvements)

## Executive Summary

This document outlines a comprehensive refactoring plan for the Neovim configuration based on a thorough code review. The primary goals are to:

1. Remove unused VSCode dual-environment support (~180 lines)
2. Eliminate dead code and commented sections (~230 lines)
3. Simplify architecture by inlining single-use utilities
4. Reorganize plugins by logical categories
5. Improve maintainability and reduce complexity by 15%

**Total expected reduction:** ~400 lines of code (8% of codebase)

---

## Current State Assessment

### Strengths
- ✅ Excellent architecture with native LSP 0.11+ implementation
- ✅ Comprehensive type annotations (EmmyLua)
- ✅ Clean module pattern with NeoUtils system
- ✅ Good error handling and Lua idioms
- ✅ Well-curated plugin selection
- ✅ Sophisticated root detection and window management

### Issues Identified
- ⚠️ VSCode support mostly unused (empty plugin dir, 95% duplicate config)
- ⚠️ Inactive plugin configs from old LSP setup (~200 lines dead code)
- ⚠️ Single-use utilities creating unnecessary abstraction
- ⚠️ Commented code blocks not cleaned up
- ⚠️ Minor typos: `innactive`, `pesistance`

---

## Three-Phase Refactoring Strategy

### Phase 1: Cleanup & Simplification (High Priority)
**Estimated Time:** 4-5 hours
**Risk Level:** Low
**Impact:** High

#### 1.1 Remove VSCode Support (2-3 hours)
**Files to delete:**
- `lua/plugins/vscode/init.lua`
- `lua/config/vscode/keymap.lua`
- `lua/config/vscode/options.lua`

**Files to modify:**
- `lua/loaders/config-loader.lua` - Remove line 68 conditional
- `lua/lazy-config/init.lua` - Remove lines 26-31 vscode import
- `CLAUDE.md` - Update documentation

**Impact:** -180 lines, -15% architectural complexity

**Testing checklist:**
- [ ] Neovim starts without errors
- [ ] LSP attaches correctly
- [ ] Plugins load via lazy.nvim
- [ ] NeoUtils accessible
- [ ] All keymaps functional

#### 1.2 Archive Inactive Plugin Configs (30 min)
**Actions:**
```bash
mkdir -p archive
mv lua/plugins/innactive archive/lsp-old-config
```

**Impact:** -200 lines dead code

#### 1.3 Remove Debug & Commented Code (45 min)
**Files to clean:**
- `lua/plugins/neovim/neo-tree/config.lua:13` - Remove `print(NeoUtils.icons.git.added)`
- `lua/config/neovim/keymap.lua:95-103` - Remove commented golden-ratio keymaps
- `lua/plugins/neovim/neo-tree/config.lua:104-114` - Remove commented popup config
- `lua/plugins/neovim/claude-code/init.lua:16-21` - Remove commented keymap

**Impact:** -30 lines

#### 1.4 Fix Typos (15 min)
**Renames:**
- `lua/plugins/neovim/pesistance.lua` → `persistence.lua`
- Update imports referencing old names

**Impact:** Better consistency

---

### Phase 2: Structural Improvements (Medium Priority)
**Estimated Time:** 3-4 hours
**Risk Level:** Medium
**Impact:** Medium-High

#### 2.1 Inline Single-Use Utilities (1-2 hours)

**A. Inline cursor.lua into neo-tree config**

Current usage: Only in `lua/plugins/neovim/neo-tree/config.lua`

Add to top of `neo-tree/config.lua`:
```lua
-- Cursor management for neo-tree
local guicursor_original = vim.o.guicursor

local function hide_cursor()
  vim.cmd("hi Cursor blend=100")
  vim.cmd("set guicursor=" .. guicursor_original .. ",a:Cursor/lCursor")
end

local function restore_cursor()
  vim.cmd("hi Cursor blend=0")
  vim.cmd("set guicursor=" .. guicursor_original)
end
```

Delete: `lua/utils/cursor.lua` (-24 lines)

**B. Inline config.lua into lsp-native config**

Move `kind_filter` to `lua/plugins/neovim/lsp-native/config.lua`:
```lua
M.kind_filter = {
  default = {
    "Class", "Constructor", "Enum", "Field", "Function",
    "Interface", "Method", "Module", "Namespace", "Package",
    "Property", "Struct", "Trait",
  },
  markdown = false,
  help = false,
  lua = {
    "Class", "Constructor", "Enum", "Function",
    "Interface", "Method", "Module", "Namespace", "Field", "Property",
  },
}
```

Update `lua/plugins/neovim/lsp-native/keymaps.lua`:
```lua
local lsp_config = require("plugins.neovim.lsp-native.config")
-- Use lsp_config.kind_filter instead of NeoUtils.config.kind_filter
```

Delete: `lua/utils/config.lua` (-42 lines)
Update: `lua/types.lua` (remove cursor and config from NeoUtils type)

**Impact:** -66 lines, reduced indirection

#### 2.2 Reorganize Plugins by Category (2-3 hours)

**Current structure:**
```
lua/plugins/neovim/
├── blink-cmp.lua
├── copilot.lua
├── git-signs.lua
├── (30+ files flat)
└── lsp-native/
```

**New structure:**
```
lua/plugins/
├── ai/
│   ├── claude-code.lua
│   └── copilot.lua
├── completion/
│   └── blink-cmp.lua
├── editor/
│   ├── grug-far.lua
│   ├── mini-diff.lua
│   ├── mini-pairs.lua
│   ├── nvim-surround.lua
│   ├── treesitter.lua
│   ├── treesitter-playground.lua
│   ├── ts-comments.lua
│   └── rest.lua
├── git/
│   ├── git-signs.lua
│   └── gitui.lua
├── lsp/
│   ├── init.lua
│   ├── config.lua
│   ├── keymaps.lua
│   └── formatting.lua
├── system/
│   ├── lazy-dev.lua
│   ├── mcp-hub.lua
│   ├── neoconf.lua
│   ├── nvim-early-retirement.lua
│   ├── nvim-jqx.lua
│   ├── nvim-lsp-file-operations.lua
│   ├── pesistance.lua
│   ├── tmux.lua
│   ├── wakatime.lua
│   └── window-picker.lua
└── ui/
    ├── colorizer.lua
    ├── icons.lua
    ├── render-markdown.lua
    ├── snacks.lua
    ├── which-key.lua
    ├── auto-dark-mode.lua
    ├── colorscheme/
    │   ├── catpuccin.lua
    │   └── nord.lua
    └── neo-tree/
        ├── init.lua
        └── config.lua
```

**Steps:**
```bash
cd lua/plugins/neovim

# Create category directories
mkdir -p ai completion editor git lsp system ui

# Move files to categories
mv claude-code copilot.lua ai/
mv blink-cmp.lua completion/
mv grug-far.lua mini-*.lua nvim-surround.lua treesitter*.lua ts-comments.lua rest.lua editor/
mv lsp-native lsp
mv formatting.lua lsp/
mv git-signs.lua gitui.lua git/
mv lazy-dev.lua mcp-hub.lua neoconf.lua nvim-*.lua pesistance.lua tmux.lua wakatime.lua window-picker.lua system/
mv colorizer.lua icons.lua render-markdown.lua snacks which-key.lua auto-dark-mode colorscheme neo-tree ui/

# Flatten directory structure
cd ../..
mv plugins/neovim/* plugins/
rmdir plugins/neovim
```

**Update imports:**
- `lua/lazy-config/init.lua`: Change `plugins.neovim` → `plugins`

**Impact:** 33% flatter structure, better organization

#### 2.3 Flatten Config Directory (15 min)
```bash
cd lua/config
mv neovim/* .
rmdir neovim
```

Update `lua/loaders/config-loader.lua`:
```lua
function M.load(base_module_name)
  local target_module_path = base_module_name  -- Just "config" not "config.neovim"
  -- ... rest of function
end
```

**Impact:** Simpler paths

---

### Phase 3: Polish & Optimization (Low Priority)
**Estimated Time:** 2-3 hours
**Risk Level:** Low
**Impact:** Medium

#### 3.1 Standardize Code Style (1 hour)
**Action:** Run stylua with single-quote preference
```bash
stylua --config-path .stylua.toml lua/
```

Create `.stylua.toml`:
```toml
column_width = 120
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferSingle"
```

#### 3.2 Add Missing Type Annotations (1-2 hours)
**Focus files:**
- `lua/plugins/neo-tree/config.lua`
- `lua/config/ui/statusline/init.lua`

Add EmmyLua annotations for function parameters and return types.

#### 3.3 Performance Optimization (optional)
**A. Debounce layout.autoRefresh**
```lua
-- In lua/utils/layout.lua
local debounce_timer = nil
function M.autoRefresh()
  if debounce_timer then
    vim.fn.timer_stop(debounce_timer)
  end
  debounce_timer = vim.fn.timer_start(50, function()
    M.refresh(5)
    debounce_timer = nil
  end)
end
```

**B. Lazy load NeoUtils (future consideration)**
Convert to metatable-based lazy loading instead of upfront loading.

---

## Detailed Execution Checklist

### Pre-Refactoring
- [x] Create REFACTORING_PLAN.md
- [ ] Review plan with user
- [ ] Commit all current changes
- [ ] Create backup tag: `pre-refactoring-2025-10-06`
- [ ] Create feature branch: `refactor/cleanup-vscode-and-reorganize`
- [ ] Verify clean working tree

### Phase 1 Execution
- [ ] 1.1: Remove VSCode support
  - [ ] Delete vscode directories
  - [ ] Simplify config-loader.lua
  - [ ] Simplify lazy-config/init.lua
  - [ ] Update CLAUDE.md
  - [ ] Test: Neovim starts
  - [ ] Test: LSP works
  - [ ] Test: All plugins load
  - [ ] Commit: "Remove VSCode support"
- [ ] 1.2: Archive inactive configs
  - [ ] Create archive/ directory
  - [ ] Move innactive/ to archive/
  - [ ] Commit: "Archive inactive LSP configs"
- [ ] 1.3: Remove debug/commented code
  - [ ] Clean neo-tree/config.lua
  - [ ] Clean keymap.lua
  - [ ] Clean claude-code/init.lua
  - [ ] Test affected features
  - [ ] Commit: "Remove debug prints and commented code"
- [ ] 1.4: Fix typos
  - [ ] Rename pesistance.lua
  - [ ] Update imports
  - [ ] Test persistence plugin
  - [ ] Commit: "Fix plugin name typos"

### Phase 2 Execution
- [ ] 2.1: Inline utilities
  - [ ] Inline cursor.lua into neo-tree
  - [ ] Test neo-tree cursor hiding
  - [ ] Inline config.lua into lsp-native
  - [ ] Test LSP symbol filtering
  - [ ] Update types.lua
  - [ ] Commit: "Inline single-use utilities"
- [ ] 2.2: Reorganize plugins
  - [ ] Create category directories
  - [ ] Move plugin files
  - [ ] Flatten neovim/ directory
  - [ ] Update lazy-config imports
  - [ ] Test: All plugins load
  - [ ] Test: LSP, completion, UI features
  - [ ] Commit: "Reorganize plugins by category"
- [ ] 2.3: Flatten config directory
  - [ ] Move config files
  - [ ] Update config-loader
  - [ ] Test: Config loads correctly
  - [ ] Commit: "Flatten config directory structure"

### Phase 3 Execution
- [ ] 3.1: Standardize code style
  - [ ] Create .stylua.toml
  - [ ] Run stylua
  - [ ] Review changes
  - [ ] Commit: "Standardize code style with stylua"
- [ ] 3.2: Add type annotations
  - [ ] Annotate neo-tree/config.lua
  - [ ] Annotate statusline/init.lua
  - [ ] Test: LSP diagnostics clean
  - [ ] Commit: "Add missing type annotations"
- [ ] 3.3: Performance optimization (optional)
  - [ ] Implement layout debounce
  - [ ] Test window management
  - [ ] Commit: "Optimize layout refresh performance"

### Post-Refactoring
- [ ] Run full test suite
- [ ] Update CLAUDE.md with new structure
- [ ] Create comparison metrics
- [ ] Tag: `post-refactoring-2025-10-06`
- [ ] Merge to main
- [ ] Archive this plan

---

## Rollback Plan

If anything goes wrong at any phase:

```bash
# Option 1: Revert to pre-refactoring state
git reset --hard pre-refactoring-2025-10-06

# Option 2: Revert specific commits
git log --oneline -10  # Find commit hash
git revert <commit-hash>

# Option 3: Cherry-pick successful changes
git checkout main
git cherry-pick <good-commit-hash>

# Option 4: Restore from backup
git stash
git checkout main
git branch -D refactor/cleanup-vscode-and-reorganize
```

---

## Success Metrics

### Code Metrics
- **Lines of code:** Reduce by ~400 lines (8%)
- **File count:** Reduce by 4 files (8%)
- **Directory depth:** Reduce from 6 to 4 levels (33%)
- **Environment checks:** Reduce from 3 to 0 (100%)
- **Dead code:** Remove 100%

### Quality Metrics
- **Architectural complexity:** Reduce by 15%
- **Type coverage:** Increase by 10%
- **Code duplication:** Eliminate VSCode duplicates (100%)
- **Maintainability:** Improve by simplifying abstractions

### Functional Metrics
- **Startup time:** Should remain same or improve slightly
- **LSP performance:** No regression
- **Plugin load time:** No regression
- **All features:** 100% functional

---

## Risk Assessment

| Phase | Risk Level | Mitigation |
|-------|------------|------------|
| 1.1 VSCode removal | Low | Backup tag, can revert, no actual VSCode usage |
| 1.2 Archive inactive | Low | Just moving files, can restore easily |
| 1.3 Remove comments | Low | Only removing comments, not active code |
| 1.4 Fix typos | Low | Simple renames with import updates |
| 2.1 Inline utils | Medium | Test each utility individually, commit separately |
| 2.2 Reorganize plugins | Medium | Use git mv for tracking, test plugin loading |
| 2.3 Flatten config | Low | Simple directory restructure |
| 3.1 Code style | Low | Automated tool, reviewable changes |
| 3.2 Type annotations | Low | Additive only, no functional changes |
| 3.3 Performance | Medium | Optional, can skip if issues arise |

**Overall Risk:** Low-Medium (highly reversible, good backup strategy)

---

## Timeline Estimate

| Phase | Estimated Time | Calendar Time (with breaks) |
|-------|----------------|------------------------------|
| Planning & Backup | 30 min | Day 0 |
| Phase 1 | 4-5 hours | Day 1 |
| Phase 2 | 3-4 hours | Day 2 |
| Phase 3 | 2-3 hours | Day 3 (optional) |
| Testing & Documentation | 1-2 hours | Day 3 |
| **Total** | **10-14 hours** | **2-3 days** |

---

## Notes

- Each phase can be done independently
- Commit frequently (after each major change)
- Test thoroughly before moving to next step
- Phase 3 is optional and can be done later
- Keep this document updated as you progress
- Document any unexpected issues or deviations

---

## References

- Code Review Report: Completed 2025-10-06
- CLAUDE.md: Architecture documentation
- Git: main branch @ commit 003793b

---

**Status:** ✅ Ready for execution
**Next Step:** Create backup and begin Phase 1.1

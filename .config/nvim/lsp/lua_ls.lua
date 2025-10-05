---@brief
---
--- Native Neovim 0.11+ LSP configuration for lua_ls (Lua Language Server)
---
--- https://github.com/luals/lua-language-server
---
--- This configuration uses native LSP APIs without nvim-lspconfig.
--- The lua-language-server binary is installed via Mason and available in $PATH.
---
--- Features:
--- - Neovim runtime awareness with automatic detection via on_init
--- - Code lens support for run/test actions
--- - Inlay hints for type information
--- - Enhanced completion with snippet support
--- - Private name documentation filtering
--- - Third-party library checking disabled by default
---
--- See lua-language-server's documentation for settings:
--- https://luals.github.io/wiki/settings/

---@type vim.lsp.Config
return {
  -- Command to start the language server
  cmd = { 'lua-language-server' },

  -- Filetypes this server handles
  filetypes = { 'lua' },

  -- Project root detection markers
  -- LSP will look for these files/directories to determine project root
  root_markers = {
    '.luarc.json',
    '.luarc.jsonc',
    '.luacheckrc',
    '.stylua.toml',
    'stylua.toml',
    'selene.toml',
    'selene.yml',
    '.git',
  },

  -- Support single file mode when no root is found
  single_file_support = true,

  -- Initialization hook to configure Neovim-specific settings
  -- This automatically configures lua_ls for Neovim development when:
  -- 1. Working in a Neovim config directory, OR
  -- 2. No .luarc.json/.luarc.jsonc exists in the project
  on_init = function(client)
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      -- Skip auto-config if .luarc.json/jsonc exists (project has its own config)
      if
        path ~= vim.fn.stdpath('config')
        and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
      then
        return
      end
    end

    -- Configure for Neovim development
    client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
      runtime = {
        -- Tell the language server which version of Lua you're using
        -- (LuaJIT in the case of Neovim)
        version = 'LuaJIT',
        -- Tell the language server how to find Lua modules
        -- Same way as Neovim (see :h lua-module-load)
        path = {
          'lua/?.lua',
          'lua/?/init.lua',
        },
      },
      -- Make the server aware of Neovim runtime files
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
          -- Add additional library paths as needed:
          -- '${3rd}/luv/library',
          -- '${3rd}/busted/library',
        },
        -- Note: Using vim.api.nvim_get_runtime_file('', true) is much slower
        -- and can cause performance issues when working on your own config.
        -- See https://github.com/neovim/nvim-lspconfig/issues/3189
      },
    })
  end,

  -- LSP server settings
  settings = {
    Lua = {
      -- Workspace settings
      workspace = {
        -- Disable third-party library prompts (e.g., "Do you need to configure busted?")
        checkThirdParty = false,
      },

      -- Code lens settings
      -- Enables run/test actions above functions/test cases
      codeLens = {
        enable = true,
      },

      -- Completion settings
      completion = {
        -- Replace mode for call snippets
        -- Options: "Disable" | "Both" | "Replace"
        -- "Replace" replaces the function name when accepting completion
        callSnippet = 'Replace',
      },

      -- Documentation settings
      doc = {
        -- Define what constitutes a private name
        -- Functions/variables matching these patterns won't show in completion
        privateName = { '^_' },
      },

      -- Inlay hints settings
      -- Shows type information inline in the editor
      hint = {
        enable = true,
        -- Don't show type hints for variables with explicit types
        setType = false,
        -- Show parameter type hints
        paramType = true,
        -- Don't show parameter names
        paramName = 'Disable',
        -- Don't show semicolon hints
        semicolon = 'Disable',
        -- Don't show array index hints
        arrayIndex = 'Disable',
      },
    },
  },
}

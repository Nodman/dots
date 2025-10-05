---@brief
---
--- Native Neovim 0.11+ LSP configuration for vtsls (TypeScript/JavaScript Language Server)
---
--- https://github.com/yioneko/vtsls
---
--- `vtsls` can be installed with npm:
--- ```sh
--- npm install -g @vtsls/language-server
--- ```
---
--- To configure a TypeScript project, add a
--- [`tsconfig.json`](https://www.typescriptlang.org/docs/handbook/tsconfig-json.html)
--- or [`jsconfig.json`](https://code.visualstudio.com/docs/languages/jsconfig) to
--- the root of your project.
---
--- Features:
--- - Server-side fuzzy matching for better completions
--- - Comprehensive inlay hints for TypeScript and JavaScript
--- - Monorepo support by default
--- - Vue.js support (see below)
---
--- ### Vue support
---
--- Since v3.0.0, the Vue language server requires `vtsls` to support TypeScript.
---
--- ```lua
--- -- If you are using mason.nvim, you can get the ts_plugin_path like this
--- -- For Mason v1:
--- -- local mason_registry = require('mason-registry')
--- -- local vue_language_server_path = mason_registry.get_package('vue-language-server'):get_install_path() .. '/node_modules/@vue/language-server'
--- -- For Mason v2:
--- -- local vue_language_server_path = vim.fn.expand '$MASON/packages' .. '/vue-language-server' .. '/node_modules/@vue/language-server'
--- -- or even:
--- -- local vue_language_server_path = vim.fn.stdpath('data') .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"
--- local vue_language_server_path = '/path/to/@vue/language-server'
--- local vue_plugin = {
---   name = '@vue/typescript-plugin',
---   location = vue_language_server_path,
---   languages = { 'vue' },
---   configNamespace = 'typescript',
--- }
--- vim.lsp.config('vtsls', {
---   settings = {
---     vtsls = {
---       tsserver = {
---         globalPlugins = {
---           vue_plugin,
---         },
---       },
---     },
---   },
---   filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
--- })
--- ```
---
--- - `location` MUST be defined. If the plugin is installed in `node_modules`, `location` can have any value.
--- - `languages` must include vue even if it is listed in filetypes.
--- - `filetypes` is extended here to include Vue SFC.
---
--- You must make sure the Vue language server is setup. For example,
---
--- ```lua
--- vim.lsp.enable('vue_ls')
--- ```
---
--- See `vue_ls` section and https://github.com/vuejs/language-tools/wiki/Neovim for more information.
---
--- ### Monorepo support
---
--- `vtsls` supports monorepos by default. It will automatically find the `tsconfig.json` or `jsconfig.json`
--- corresponding to the package you are working on. This works without the need of spawning multiple instances
--- of `vtsls`, saving memory.
---
--- It is recommended to use the same version of TypeScript in all packages, and therefore have it available
--- in your workspace root. The location of the TypeScript binary will be determined automatically, but only once.

---@type vim.lsp.Config
return {
  -- Command to start the language server
  cmd = { 'vtsls', '--stdio' },

  -- Initialization options sent when starting the server
  init_options = {
    hostInfo = 'neovim',
  },

  -- Filetypes this server handles
  filetypes = {
    'javascript',
    'javascriptreact',
    'javascript.jsx',
    'typescript',
    'typescriptreact',
    'typescript.tsx',
    'vue',
  },

  -- Project root detection markers
  -- The LSP looks for these files/directories to determine the project root
  -- For monorepos, vtsls will automatically handle multiple packages
  root_markers = {
    'package.json',
    'tsconfig.json',
    'jsconfig.json',
    '.git',
  },

  -- Support single file mode when no root is found
  single_file_support = true,

  -- LSP server settings
  settings = {
    -- Experimental features
    experimental = {
      completion = {
        -- Enable server-side fuzzy matching for better completion results
        enableServerSideFuzzyMatch = true,
      },
    },

    -- TypeScript-specific settings
    typescript = {
      -- Inlay hints configuration for TypeScript
      inlayHints = {
        -- Parameter hints
        parameterNames = {
          -- Show parameter names for all literals except function calls
          -- Options: "none" | "literals" | "all"
          enabled = 'literals',
          -- Suppress hints when parameter name matches the argument name
          suppressWhenArgumentMatchesName = true,
        },

        -- Parameter type hints
        parameterTypes = {
          -- Show type hints for function parameters
          enabled = true,
        },

        -- Variable type hints
        variableTypes = {
          -- Show type hints for variables without explicit types
          enabled = true,
          -- Suppress hints when type matches the variable name
          suppressWhenTypeMatchesName = true,
        },

        -- Property declaration type hints
        propertyDeclarationTypes = {
          -- Show type hints for properties without explicit types
          enabled = true,
        },

        -- Function return type hints
        functionLikeReturnTypes = {
          -- Show return type hints for functions without explicit return types
          enabled = true,
        },

        -- Enum member value hints
        enumMemberValues = {
          -- Show enum member values
          enabled = true,
        },
      },

      -- TypeScript-specific preferences
      preferences = {
        -- Prefer 'import type' for type-only imports
        preferTypeOnlyAutoImports = true,
      },

      -- Suggest configuration
      suggest = {
        -- Enable auto-imports in completions
        autoImports = true,
      },
    },

    -- JavaScript-specific settings (mirrors TypeScript for consistency)
    javascript = {
      -- Inlay hints configuration for JavaScript
      inlayHints = {
        -- Parameter hints
        parameterNames = {
          enabled = 'literals',
          suppressWhenArgumentMatchesName = true,
        },

        -- Parameter type hints
        parameterTypes = {
          enabled = true,
        },

        -- Variable type hints
        variableTypes = {
          enabled = true,
          suppressWhenTypeMatchesName = true,
        },

        -- Property declaration type hints
        propertyDeclarationTypes = {
          enabled = true,
        },

        -- Function return type hints
        functionLikeReturnTypes = {
          enabled = true,
        },

        -- Enum member value hints
        enumMemberValues = {
          enabled = true,
        },
      },

      -- Suggest configuration
      suggest = {
        -- Enable auto-imports in completions
        autoImports = true,
      },
    },
  },
}

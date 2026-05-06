--- @brief
---
--- Native Neovim 0.11+ LSP configuration for ESLint Language Server
---
--- https://github.com/hrsh7th/vscode-langservers-extracted
---
--- `vscode-eslint-language-server` is a linting engine for JavaScript / TypeScript.
--- It can be installed via `npm`:
---
--- ```sh
--- npm i -g vscode-langservers-extracted
--- ```
---
--- ### Auto-fix on save
---
--- The default `on_attach` config provides the `LspEslintFixAll` command that can be used
--- to format a document on save:
---
--- ```lua
--- local base_on_attach = vim.lsp.config.eslint.on_attach
--- vim.lsp.config("eslint", {
---   on_attach = function(client, bufnr)
---     if base_on_attach then
---       base_on_attach(client, bufnr)
---     end
---
---     vim.api.nvim_create_autocmd("BufWritePre", {
---       buffer = bufnr,
---       command = "LspEslintFixAll",
---     })
---   end,
--- })
--- ```
---
--- ### Monorepo support
---
--- `vscode-eslint-language-server` supports monorepos by default. It will automatically
--- find the config file corresponding to the package you are working on. You can use
--- different configs in different packages.
---
--- This works without the need of spawning multiple instances of `vscode-eslint-language-server`.
--- You can use a different version of ESLint in each package, but it is recommended to use
--- the same version of ESLint in all packages. The location of the ESLint binary will be
--- determined automatically.
---
--- /!\ When using flat config files, you need to use them across all your packages in your
--- monorepo, as it's a global setting for the server.
---
--- ### Configuration
---
--- See [vscode-eslint](https://github.com/microsoft/vscode-eslint/blob/55871979d7af184bf09af491b6ea35ebd56822cf/server/src/eslintServer.ts#L216-L229)
--- for comprehensive configuration options.
---
--- Messages handled in this config:
--- - `eslint/openDoc` - Opens ESLint documentation URLs
--- - `eslint/confirmESLintExecution` - Auto-approves ESLint execution
--- - `eslint/probeFailed` - Notifies when ESLint probe fails
--- - `eslint/noLibrary` - Notifies when ESLint library is not found
---
--- Additional messages you can handle: `eslint/noConfig`
---
--- @type vim.lsp.Config
return {
  -- Command to start the ESLint language server
  cmd = { 'vscode-eslint-language-server', '--stdio' },

  -- Supported filetypes for ESLint linting
  filetypes = {
    'javascript',
    'javascriptreact',
    'javascript.jsx',
    'typescript',
    'typescriptreact',
    'typescript.tsx',
    'vue',
    'svelte',
    'astro',
    'htmlangular',
  },

  -- Root directory markers for ESLint projects
  -- Priority order: package manager lock files > eslint configs > package.json > .git
  root_markers = {
    -- Package manager lock files (highest priority for monorepo support)
    'package-lock.json',
    'yarn.lock',
    'pnpm-lock.yaml',
    'bun.lockb',
    'bun.lock',
    -- ESLint configuration files
    '.eslintrc',
    '.eslintrc.js',
    '.eslintrc.cjs',
    '.eslintrc.yaml',
    '.eslintrc.yml',
    '.eslintrc.json',
    'eslint.config.js',
    'eslint.config.mjs',
    'eslint.config.cjs',
    'eslint.config.ts',
    'eslint.config.mts',
    'eslint.config.cts',
    -- Fallback markers
    'package.json',
    '.git',
  },

  -- Require a workspace folder to be detected
  workspace_required = true,

  -- Attach callback to create the LspEslintFixAll command per buffer
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, 'LspEslintFixAll', function()
      client:request_sync('workspace/executeCommand', {
        command = 'eslint.applyAllFixes',
        arguments = {
          {
            uri = vim.uri_from_bufnr(bufnr),
            version = vim.lsp.util.buf_versions[bufnr],
          },
        },
      }, nil, bufnr)
    end, {
      desc = 'ESLint: Fix all auto-fixable problems',
    })
  end,

  -- ESLint language server settings
  -- See: https://github.com/Microsoft/vscode-eslint#settings-options
  settings = {
    -- Validation mode: 'on' | 'off' | 'probe'
    validate = 'on',

    -- Package manager to use: nil (auto-detect) | 'npm' | 'yarn' | 'pnpm'
    packageManager = nil,

    -- Use ESLint class instead of CLIEngine
    useESLintClass = false,

    -- Experimental features
    experimental = {
      -- Enable flat config support (auto-detected via before_init)
      useFlatConfig = false,
    },

    -- Code action on save settings
    codeActionOnSave = {
      enable = false,
      mode = 'all', -- 'all' | 'problems'
    },

    -- Enable/disable ESLint as a formatter
    format = true,

    -- Only report errors (suppress warnings)
    quiet = false,

    -- How to handle ignored files: 'off' | 'warn'
    onIgnoredFiles = 'off',

    -- Custom rule severity overrides
    rulesCustomizations = {},

    -- When to run ESLint: 'onSave' | 'onType'
    run = 'onType',

    -- Problem display settings
    problems = {
      shortenToSingleLine = false,
    },

    -- Node modules resolution path (relative to workspace folder)
    nodePath = '',

    -- Code action settings
    codeAction = {
      -- Disable rule comment settings
      disableRuleComment = {
        enable = true,
        location = 'separateLine', -- 'separateLine' | 'sameLine'
      },
      -- Show documentation for ESLint rules
      showDocumentation = {
        enable = true,
      },
    },
  },

  -- Before initialization callback to configure workspace and detect flat config
  before_init = function(_, config)
    -- The "workspaceFolder" is a VSCode concept. It limits how far the
    -- server will traverse the file system when locating the ESLint config
    -- file (e.g., .eslintrc).
    local root_dir = config.root_dir

    if not root_dir then
      return
    end

    -- Set workspace folder configuration
    config.settings = config.settings or {}
    config.settings.workspaceFolder = {
      uri = root_dir,
      name = vim.fn.fnamemodify(root_dir, ':t'),
    }

    -- Pin working directory to the project root so relative paths in .eslintrc.js
    -- (e.g. rulesdir plugin's ".eslint/custom-rules") resolve correctly regardless
    -- of which file is open.
    config.settings.workingDirectory = {
      directory = root_dir,
    }

    -- Auto-detect flat config files
    -- Flat config files contain 'config' in the file name
    local flat_config_patterns = {
      'eslint.config.js',
      'eslint.config.mjs',
      'eslint.config.cjs',
      'eslint.config.ts',
      'eslint.config.mts',
      'eslint.config.cts',
    }

    for _, pattern in ipairs(flat_config_patterns) do
      local found_files = vim.fn.globpath(root_dir, pattern, true, true)

      -- Filter out files inside node_modules
      local filtered_files = {}
      for _, file in ipairs(found_files) do
        if not file:match('[/\\]node_modules[/\\]') then
          table.insert(filtered_files, file)
        end
      end

      if #filtered_files > 0 then
        config.settings.experimental = config.settings.experimental or {}
        config.settings.experimental.useFlatConfig = true
        break
      end
    end

    -- Support Yarn 2+ (PnP) projects
    local pnp_cjs = root_dir .. '/.pnp.cjs'
    local pnp_js = root_dir .. '/.pnp.js'
    if vim.uv.fs_stat(pnp_cjs) or vim.uv.fs_stat(pnp_js) then
      local cmd = config.cmd
      config.cmd = vim.list_extend({ 'yarn', 'exec' }, cmd)
    end
  end,

  -- Custom message handlers for ESLint-specific requests
  handlers = {
    -- Handle documentation requests
    ['eslint/openDoc'] = function(_, result)
      if result then
        vim.ui.open(result.url)
      end
      return {}
    end,

    -- Auto-approve ESLint execution requests
    ['eslint/confirmESLintExecution'] = function(_, result)
      if not result then
        return
      end
      return 4 -- approved
    end,

    -- Handle probe failures
    ['eslint/probeFailed'] = function()
      vim.notify('[eslint] ESLint probe failed.', vim.log.levels.WARN)
      return {}
    end,

    -- Handle missing ESLint library
    ['eslint/noLibrary'] = function()
      vim.notify('[eslint] Unable to find ESLint library.', vim.log.levels.WARN)
      return {}
    end,
  },
}

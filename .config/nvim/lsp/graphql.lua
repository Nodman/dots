---@brief
---
--- Native Neovim 0.11+ LSP configuration for graphql (GraphQL Language Server)
---
--- https://github.com/graphql/graphiql/tree/main/packages/graphql-language-service-cli
---
--- This configuration uses native LSP APIs without nvim-lspconfig.
--- The graphql-lsp binary is installed via Mason.
---
--- Features:
--- - GraphQL query/mutation/subscription validation
--- - Schema-aware autocompletion
--- - Go to definition for types and fields
--- - Hover documentation for schema elements
--- - Support for inline GraphQL in TypeScript/JavaScript React files
---
--- Requirements:
--- 1. The 'graphql' package must be installed in your project
--- 2. A GraphQL config file must exist in your project root
---
--- Installation:
--- npm install -g graphql-language-service-cli
---
--- GraphQL Config:
--- Create one of these files in your project root:
--- - .graphqlrc
--- - .graphqlrc.json
--- - .graphqlrc.js
--- - graphql.config.js
--- - graphql.config.json
---
--- Example .graphqlrc.json:
--- {
---   "schema": "schema.graphql",
---   "documents": "src/**/*.{graphql,js,ts,jsx,tsx}"
--- }
---
--- See GraphQL Config documentation:
--- https://the-guild.dev/graphql/config/docs

---@type vim.lsp.Config
return {
  -- Command to start the language server
  -- -m stream: Use streaming mode for better performance
  cmd = { 'graphql-lsp', 'server', '-m', 'stream' },

  -- Filetypes this server handles
  -- Includes .graphql files and inline GraphQL in React files
  filetypes = {
    'graphql',         -- .graphql files
    'typescript',
    'typescriptreact', -- .tsx files (for inline gql`` tags)
    'javascriptreact', -- .jsx files (for inline gql`` tags)
  },

  -- Project root detection markers
  -- GraphQL LSP requires a GraphQL config file to function properly
  -- These files define the schema location and document patterns
  root_markers = {
    '.graphqlrc.*',         -- YAML format config
    '.graphqlrc.json',    -- JSON format config
    '.graphqlrc.js',      -- JavaScript format config
    'graphql.config.js',  -- Alternative JS format
    'graphql.config.json', -- Alternative JSON format
  },

  -- Do not enable single file support
  -- GraphQL LSP requires a config file and project context to work properly
  -- single_file_support = false (default when not specified)
}

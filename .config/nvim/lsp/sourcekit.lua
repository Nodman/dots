---@brief
---
--- Native Neovim 0.11+ LSP configuration for sourcekit-lsp (Swift Language Server)
---
--- https://github.com/swiftlang/sourcekit-lsp
---
--- This configuration uses native LSP APIs without nvim-lspconfig.
--- The sourcekit-lsp binary is typically installed as part of the Swift toolchain.
---
--- Features:
--- - Language server for Swift and Objective-C/C++
--- - Custom root directory detection with priority order
--- - Dynamic file watching support for workspace changes
--- - Proper language ID mapping for Objective-C variants
---
--- Root Directory Detection Priority:
--- 1. buildServer.json (Build Server Protocol configuration)
--- 2. *.xcodeproj or *.xcworkspace (Xcode projects)
--- 3. .git directory (Git repository root)
--- 4. Package.swift (Swift Package Manager)
---
--- See sourcekit-lsp documentation:
--- https://github.com/swiftlang/sourcekit-lsp/tree/main/Documentation

---@type vim.lsp.Config
return {
  -- Command to start the language server
  cmd = { 'sourcekit-lsp' },

  -- Filetypes this server handles
  filetypes = { 'swift', 'objective-c', 'objective-cpp' },

  -- Custom root directory detection with priority order
  -- This function implements a specific priority for Swift/Xcode projects:
  -- 1. buildServer.json - Build Server Protocol config (highest priority)
  -- 2. *.xcodeproj, *.xcworkspace - Xcode project files
  -- 3. .git - Git repository root
  -- 4. Package.swift - Swift Package Manager (lowest priority)
  --
  -- The priority order is important because modularized apps may contain
  -- multiple Package.swift files, so we want to prefer more specific markers.
  root_dir = function(bufnr, on_dir)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    local path = vim.fs.dirname(filename)

    -- Helper function to find files/directories matching patterns upward from path
    local function find_root(patterns)
      for _, pattern in ipairs(patterns) do
        local matches = vim.fs.find(pattern, {
          path = path,
          upward = true,
          type = pattern:match('%*') and 'file' or nil, -- glob patterns are files
        })
        if #matches > 0 then
          return vim.fs.dirname(matches[1])
        end
      end
      return nil
    end

    -- Priority 1: buildServer.json (Build Server Protocol)
    local root = find_root({ 'buildServer.json' })

    -- Priority 2: Xcode project files
    if not root then
      root = find_root({ '*.xcodeproj', '*.xcworkspace' })
    end

    -- Priority 3: Git repository
    if not root then
      local git = vim.fs.find('.git', { path = path, upward = true })
      if #git > 0 then
        root = vim.fs.dirname(git[1])
      end
    end

    -- Priority 4: Swift Package Manager (lowest priority due to modularized apps)
    if not root then
      root = find_root({ 'Package.swift' })
    end

    -- Return the found root directory
    on_dir(root)
  end,

  -- Map Neovim filetypes to LSP language IDs
  -- sourcekit-lsp expects specific language IDs for Objective-C variants
  get_language_id = function(_, ftype)
    local filetype_map = {
      ['objective-c'] = 'objective-c',
      ['objective-cpp'] = 'objective-cpp',
    }
    return filetype_map[ftype] or ftype
  end,

  -- LSP capabilities
  -- Enable dynamic file watching for workspace changes
  capabilities = {
    workspace = {
      -- Allow the server to dynamically register file watchers
      -- This is important for Swift projects where file changes
      -- can affect the build configuration
      didChangeWatchedFiles = {
        dynamicRegistration = true,
      },
    },
    textDocument = {
      -- Enhanced diagnostic support
      diagnostic = {
        dynamicRegistration = true,
        relatedDocumentSupport = true,
      },
    },
  },
}

-- Load utility functions into _G.NeoUtils
require("loaders.neo-utils").load()

require("lazy-config")

-- Load main configuration files based on environment (vscode/neovim)
require("loaders.config-loader").load("config")

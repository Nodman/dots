---@class LspMason
local M = {}

local cached_map = nil

-- Get mapping between Mason packages and LSP server names
-- Uses Mason's package specs to dynamically build the mapping
function M.get_mason_map()
  if cached_map then
    return cached_map
  end

  local has_mason_registry, registry = pcall(require, "mason-registry")
  if not has_mason_registry then
    return { package_to_lspconfig = {}, lspconfig_to_package = {} }
  end

  ---@type table<string, string>
  local package_to_lspconfig = {}

  for _, pkg in ipairs(registry.get_installed_packages()) do
    local pkg_name = pkg.name
    local pkg_spec = pkg.spec

    -- Check if package provides an LSP server via neovim.lspconfig field
    local lspconfig = vim.tbl_get(pkg_spec, "neovim", "lspconfig")
    if lspconfig then
      package_to_lspconfig[pkg_name] = lspconfig
    end
  end

  -- Invert the mapping to get lspconfig -> package
  local lspconfig_to_package = {}
  for pkg, lsp in pairs(package_to_lspconfig) do
    lspconfig_to_package[lsp] = pkg
  end

  cached_map = {
    package_to_lspconfig = package_to_lspconfig,
    lspconfig_to_package = lspconfig_to_package,
  }

  return cached_map
end

-- Clear cache when Mason registry updates
local function setup_cache_invalidation()
  local has_mason_registry, registry = pcall(require, "mason-registry")
  if has_mason_registry then
    registry:on("package:install:success", function()
      cached_map = nil
    end)
    registry:on("package:uninstall:success", function()
      cached_map = nil
    end)
  end
end

-- Get list of installed LSP server names
---@return string[] List of LSP server names
function M.get_installed_servers()
  local map = M.get_mason_map()
  local servers = {}

  for _, server_name in pairs(map.package_to_lspconfig) do
    table.insert(servers, server_name)
  end

  return servers
end

-- Initialize Mason integration
function M.setup()
  setup_cache_invalidation()
end

return M

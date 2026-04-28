local M = {}

---@type nil | LazyKeysSpec[]
M._keys = nil

---@return LazyKeysSpec[]
function M.get()
  if M._keys then
    return M._keys
  end
  -- Get lsp_config for kind_filter
  local lsp_config = require("plugins.lsp.lib.config")
    -- stylua: ignore
    M._keys =  {
      {"<F2>", vim.lsp.buf.rename, desc = 'Rename', has = 'rename'},
      {"gh", vim.diagnostic.open_float, desc = 'Hover'},
      { "<leader>cl", function() Snacks.picker.lsp_config() end, desc = "Lsp Info" },
      { "<leader>cls", M.show_lsp_server_info, desc = "LSP Server Info" },
      { "<leader>cll", M.open_lsp_log, desc = "Open LSP Log" },
      { "gd", function() Snacks.picker.lsp_definitions() end, desc = "Goto Definition", has = "definition" },
      { "gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
      { "<leader>ss", function() Snacks.picker.lsp_symbols({ filter = lsp_config.kind_filter}) end, desc = "LSP Symbols", has = "documentSymbol" },
      { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols({ filter = lsp_config.kind_filter }) end, desc = "LSP Workspace Symbols", has = "workspaceSymbol" },
      { "gI", vim.lsp.buf.implementation, desc = "Goto Implementation" },
      { "gy", vim.lsp.buf.type_definition, desc = "Goto T[y]pe Definition" },
      { "gD", vim.lsp.buf.declaration, desc = "Goto Declaration" },
      { "K", function() return vim.lsp.buf.hover() end, desc = "Hover" },
      { "gK", function() return vim.lsp.buf.signature_help() end, desc = "Signature Help", has = "signatureHelp" },
      { "<a-k>", function() return vim.lsp.buf.signature_help() end, mode = "i", desc = "Signature Help", has = "signatureHelp" },
      { "<leader>ca", vim.lsp.buf.code_action, desc = "Code Action", mode = { "n", "v" }, has = "codeAction" },
      { "<leader>cA", NeoUtils.lsp.action.source, desc = "Source Action", has = "codeAction" },
      { "<leader>cL", vim.lsp.codelens.run, desc = "Run Codelens", mode = { "n", "v" }, has = "codeLens" },
      { "<leader>cC", vim.lsp.codelens.refresh, desc = "Refresh & Display Codelens", mode = { "n" }, has = "codeLens" },
      { "<leader>cr", function() Snacks.rename.rename_file() end, desc = "Rename File", mode ={"n"}, has = { "workspace/didRenameFiles", "workspace/willRenameFiles" } },
      { "]]", function() Snacks.words.jump(vim.v.count1) end, has = "documentHighlight",
        desc = "Next Reference", cond = function() return Snacks.words.is_enabled() end },
      { "[[", function() Snacks.words.jump(-vim.v.count1) end, has = "documentHighlight",
        desc = "Prev Reference", cond = function() return Snacks.words.is_enabled() end },
      { "<a-n>", function() Snacks.words.jump(vim.v.count1, true) end, has = "documentHighlight",
        desc = "Next Reference", cond = function() return Snacks.words.is_enabled() end },
      { "<a-p>", function() Snacks.words.jump(-vim.v.count1, true) end, has = "documentHighlight",
        desc = "Prev Reference", cond = function() return Snacks.words.is_enabled() end },
    }

  return M._keys
end

---@param buffer number
---@param method string|string[]
---@return boolean
function M.has(buffer, method)
  if type(method) == "table" then
    for _, m in ipairs(method) do
      if M.has(buffer, m) then
        return true
      end
    end
    return false
  end
  method = method:find("/") and method or "textDocument/" .. method
  local clients = NeoUtils.lsp.get_clients({ bufnr = buffer })
  for _, client in ipairs(clients) do
    if client.supports_method(method) then
      return true
    end
  end
  return false
end

---@param buffer number
---@return LazyKeys[]
function M.resolve(buffer)
  local Keys = require("lazy.core.handler.keys")
  if not Keys.resolve then
    return {}
  end
  local spec = vim.tbl_extend("force", {}, M.get())
  return Keys.resolve(spec)
end

---@param _ vim.lsp.Client
---@param buffer number
function M.on_attach(_, buffer)
  local Keys = require("lazy.core.handler.keys")
  local keymaps = M.resolve(buffer)

  for _, keys in pairs(keymaps) do
    local has = not keys.has or M.has(buffer, keys.has)
    local cond = not (keys.cond == false or ((type(keys.cond) == "function") and not keys.cond()))

    if has and cond then
      local opts = Keys.opts(keys)
      ---@diagnostic disable-next-line: inject-field
      opts.cond = nil
      ---@diagnostic disable-next-line: inject-field
      opts.has = nil
      ---@diagnostic disable-next-line: inject-field
      opts.silent = opts.silent ~= false
      ---@diagnostic disable-next-line: inject-field
      opts.buffer = buffer
      ---@diagnostic disable-next-line: param-type-mismatch
      vim.keymap.set(keys.mode or "n", keys.lhs, keys.rhs, opts)
    end
  end
end

---Opens a picker to select an LSP client and displays detailed server information
function M.show_lsp_server_info()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = NeoUtils.lsp.get_clients({ bufnr = bufnr })

  if #clients == 0 then
    NeoUtils.notification.warn("No LSP clients attached to current buffer")
    return
  end

  -- If only one client, show info directly
  if #clients == 1 then
    M._display_server_info(clients[1])
    return
  end

  -- Build select items
  local items = {}
  for _, client in ipairs(clients) do
    local root_dir = client.root_dir or client.config.root_dir or "N/A"
    table.insert(items, string.format("%s (ID: %d) - %s", client.name, client.id, vim.fn.fnamemodify(root_dir, ":~")))
  end

  -- Use vim.ui.select to choose a client
  vim.ui.select(items, {
    prompt = "Select LSP Server:",
    format_item = function(item)
      return item
    end,
  }, function(choice, idx)
    if choice and idx then
      M._display_server_info(clients[idx])
    end
  end)
end

---Display detailed information about an LSP client in a scratch buffer
---@param client vim.lsp.Client
function M._display_server_info(client)
  -- Create a new scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "lsp-info"

  -- Gather server information
  local lines = {}
  local function add_section(title)
    if #lines > 0 then
      table.insert(lines, "")
    end
    table.insert(lines, string.rep("=", 80))
    table.insert(lines, title)
    table.insert(lines, string.rep("=", 80))
  end

  local function add_line(text)
    table.insert(lines, text or "")
  end

  local function add_kv(key, value)
    if value == nil then
      value = "N/A"
    elseif type(value) == "table" then
      value = vim.inspect(value)
    else
      value = tostring(value)
    end
    add_line(string.format("  %s: %s", key, value))
  end

  -- Server Info Section
  add_section("LSP Server Information")
  add_kv("Name", client.name)
  add_kv("ID", client.id)
  add_kv("Root Directory", client.root_dir or client.config.root_dir)
  add_kv("Command", table.concat(client.config.cmd or {}, " "))

  -- Filetypes Section
  if client.config.filetypes then
    add_line("")
    add_line("Filetypes:")
    for _, ft in ipairs(client.config.filetypes) do
      add_line("  - " .. ft)
    end
  end

  -- Attached Buffers Section
  local attached_buffers = {}
  for buf_id in pairs(client.attached_buffers) do
    if vim.api.nvim_buf_is_valid(buf_id) then
      local buf_name = vim.api.nvim_buf_get_name(buf_id)
      buf_name = buf_name ~= "" and vim.fn.fnamemodify(buf_name, ":~:.") or "[No Name]"
      table.insert(attached_buffers, string.format("%d: %s", buf_id, buf_name))
    end
  end
  if #attached_buffers > 0 then
    add_line("")
    add_line("Attached Buffers:")
    for _, buf_info in ipairs(attached_buffers) do
      add_line("  - " .. buf_info)
    end
  end

  -- Capabilities Section
  add_section("Server Capabilities")
  if client.server_capabilities then
    local caps = client.server_capabilities

    -- Document-level capabilities
    add_line("Document:")
    add_kv("  Hover", caps.hoverProvider)
    add_kv("  Completion", caps.completionProvider ~= nil)
    add_kv("  Signature Help", caps.signatureHelpProvider ~= nil)
    add_kv("  Definition", caps.definitionProvider)
    add_kv("  Type Definition", caps.typeDefinitionProvider)
    add_kv("  Implementation", caps.implementationProvider)
    add_kv("  References", caps.referencesProvider)
    add_kv("  Document Highlight", caps.documentHighlightProvider)
    add_kv("  Document Symbol", caps.documentSymbolProvider)
    add_kv("  Formatting", caps.documentFormattingProvider)
    add_kv("  Range Formatting", caps.documentRangeFormattingProvider)
    add_kv("  Code Action", caps.codeActionProvider ~= nil)
    add_kv("  Code Lens", caps.codeLensProvider ~= nil)
    add_kv("  Inlay Hint", caps.inlayHintProvider ~= nil)
    add_kv("  Folding", caps.foldingRangeProvider)
    add_kv("  Selection Range", caps.selectionRangeProvider)
    add_kv("  Rename", caps.renameProvider ~= nil)
    add_kv("  Semantic Tokens", caps.semanticTokensProvider ~= nil)

    -- Workspace-level capabilities
    add_line("")
    add_line("Workspace:")
    add_kv("  Workspace Symbol", caps.workspaceSymbolProvider)
    add_kv("  Execute Command", caps.executeCommandProvider ~= nil)
    if caps.workspace then
      add_kv("  File Operations", caps.workspace.fileOperations ~= nil)
      add_kv("  Workspace Folders", caps.workspace.workspaceFolders ~= nil)
    end
  else
    add_line("  No capability information available")
  end

  -- Settings Section (if available)
  if client.config.settings then
    add_section("Server Settings")
    add_line(vim.inspect(client.config.settings))
  end

  -- Handlers Section
  if client.config.handlers then
    add_section("Custom Handlers")
    for method, _ in pairs(client.config.handlers) do
      add_line("  - " .. method)
    end
  end

  -- Log Section
  add_section("Log Information")
  local log_path = vim.lsp.get_log_path()
  add_kv("Log Path", log_path)
  add_kv("Log Level", vim.lsp.log.get_level())
  add_line("")
  add_line("Press 'L' to open the LSP log file")
  add_line("Press 'q' to close this window")

  -- Set buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  -- Open in a split
  vim.cmd("split")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  -- Set buffer name
  vim.api.nvim_buf_set_name(buf, string.format("[LSP Info: %s]", client.name))

  -- Set up keymaps for the info buffer
  local function buf_keymap(key, fn, desc)
    vim.keymap.set("n", key, fn, { buffer = buf, silent = true, noremap = true, desc = desc })
  end

  buf_keymap("q", function()
    vim.api.nvim_win_close(win, true)
  end, "Close window")

  buf_keymap("L", function()
    M.open_lsp_log()
  end, "Open LSP log")

  -- Set up syntax highlighting
  vim.api.nvim_buf_call(buf, function()
    vim.cmd([[
      syntax match LspInfoHeader "^=.*="
      syntax match LspInfoKey "^\s*\w\+:"
      syntax match LspInfoBullet "^\s*-"
      syntax match LspInfoTrue "\<true\>"
      syntax match LspInfoFalse "\<false\|N/A\>"
      syntax match LspInfoNumber "\<\d\+\>"

      highlight default link LspInfoHeader Title
      highlight default link LspInfoKey Label
      highlight default link LspInfoBullet Special
      highlight default link LspInfoTrue String
      highlight default link LspInfoFalse Comment
      highlight default link LspInfoNumber Number
    ]])
  end)
end

---Opens the LSP log file in a new buffer
function M.open_lsp_log()
  local log_path = vim.lsp.get_log_path()

  -- Check if log file exists
  if vim.fn.filereadable(log_path) == 0 then
    NeoUtils.notification.warn("LSP log file does not exist: " .. log_path)
    return
  end

  -- Open log in a new split
  vim.cmd("split " .. vim.fn.fnameescape(log_path))

  -- Set up buffer options
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].bufhidden = "wipe"

  -- Jump to end of file to see latest logs
  vim.cmd("normal! G")

  -- Set up auto-reload on file change
  vim.api.nvim_create_autocmd({ "FileChangedShellPost" }, {
    buffer = buf,
    callback = function()
      vim.cmd("checktime")
      -- Jump to end after reload
      vim.cmd("normal! G")
    end,
  })

  NeoUtils.notification.info("LSP log opened. Press 'q' to close.")
end

return M

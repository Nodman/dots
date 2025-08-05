local map = vim.keymap.set

local vscode = require("vscode")

-- enter command line faster
map("n", ";", ":")


map("n", "<Leader>bf", function()
  vscode.call("editor.action.formatDocument")
end)
map("n", "<Leader>a", function()
  vscode.call("editor.action.quickFix")
end)
map("n", "gr", function()
  vscode.call("editor.action.goToReferences")
end)
map("n", "go", function()
  vscode.call("editor.action.goToTypeDefinition")
end)
map("n", "gi", function()
  vscode.call("editor.action.goToImplementation")
end)
map("n", "gd", function()
  vscode.call("editor.action.goToDeclaration")
end)
map("n", "<Leader>fb", function()
  vscode.call("workbench.action.showAllEditors")
end)
map("n", "<Leader>ff", function()
  vscode.call("workbench.action.quickOpen")
end)

-- faster init.lua access
map("", "<leader>fed", "<CMD>e $MYVIMRC<CR>")

-- reload lua file
map("", "<leader>feR", "<CMD>luafile %<CR>")

-- print file info
map("n", "<Leader>if", '<CMD>echo printf("[%.2f KB] %s", wordcount().bytes / 1000.0, expand(@%))<CR>')

-- search selection in buffer
map("v", "//", 'y/\\V<C-r>=escape(@","/")<CR><CR>')
-- clear search highlight
map("n", "<Leader>sc", "<CMD>nohl<CR>")

map("n", "<C-w>h", function()
  vscode.call("workbench.action.navigateLeft")
end)
map("n", "<C-w>l", function()
  vscode.call("workbench.action.navigateRight")
end)
map("n", "<C-w>j", function()
  vscode.call("workbench.action.navigateDown")
end)
map("n", "<C-w>k", function()
  vscode.call("workbench.action.navigateUp")
end)

-- close window
map("n", "<Leader>wd", "<CMD>wd<CR>")
map("n", "<Leader>bd", "<CMD>bn|:bd#<CR>")
-- wipe buffer
map("n", "<Leader>bw", "<CMD>bw<CR>")
map("n", "<Leader>bW", "<CMD>Wipe<CR>")
-- create new buffer
map("n", "<Leader>ba", "<CMD>badd<space>")
-- next buffer
map("n", "<Leader>bn", "<CMD>bn<CR>")
-- previous buffer
map("n", "<Leader>bp", "<CMD>bp<CR>")
-- next tab
map("n", "<Leader>tn", "<CMD>tabnext<CR>")
-- previous tab
map("n", "<Leader>tp", "<CMD>tabprevious<CR>")

-- duplicate line
map("n", "<Leader>ld", "yyp")

-- keep selection while indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

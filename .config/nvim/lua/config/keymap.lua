local map = vim.keymap.set

-- set leader key
map("n", "<Space>", "<Nop>", { silent = true })
map("n", "<Esc><Esc>", "<Nop>", { silent = true })
map("i", "<C-Space>", "<Nop>", { silent = true })
map("i", "<C-Space>", "<Nop>", { silent = true })
map("n", "<C-Space>", "<Nop>", { silent = true })

-- enter command line faster
map("n", ";", ":")

-- don't invoke autocompletion menu due to accidental keystrokes
map("i", "<C-p>", "<Nop>")
-- use tab instead
map("i", "<TAB>", "<C-n>")

-- move in insert mode
map("i", "<C-h>", "<Left>")
map("i", "<C-l>", "<Right>")
map("i", "<C-j>", "<Down>")
map("i", "<C-k>", "<Up>")

-- move in command mode
map("c", "<C-h>", "<Left>")
map("c", "<C-l>", "<Right>")
map("c", "<C-k>", "<Up>")
map("c", "<C-j>", "<Down>")

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

local function get_target_window_buftype(direction)
  local winnr = vim.fn.winnr()
  local target_winnr

  if direction == "h" then
    target_winnr = vim.fn.winnr("h")
  elseif direction == "l" then
    target_winnr = vim.fn.winnr("l")
  elseif direction == "j" then
    target_winnr = vim.fn.winnr("j")
  elseif direction == "k" then
    target_winnr = vim.fn.winnr("k")
  end

  if target_winnr == winnr then
    return nil -- no target window in that direction
  end

  local target_bufnr = vim.fn.winbufnr(target_winnr)
  return vim.fn.getbufvar(target_bufnr, "&buftype")
end

map("n", "<C-w>h", function()
  local target_buftype = get_target_window_buftype("h")
  if target_buftype ~= "terminal" then
    require("tmux").move_left()
  end
end)
map("n", "<C-w>l", function()
  local target_buftype = get_target_window_buftype("l")
  if target_buftype ~= "terminal" then
    require("tmux").move_right()
  end
end)
map("n", "<C-w>j", function()
  local target_buftype = get_target_window_buftype("j")
  if target_buftype ~= "terminal" then
    require("tmux").move_bottom()
  end
end)
map("n", "<C-w>k", function()
  local target_buftype = get_target_window_buftype("k")
  if target_buftype ~= "terminal" then
    require("tmux").move_top()
  end
end)
map("n", "<Leader>ws", "<CMD>split<CR>", { desc = "Window: Split horizontal" })
map("n", "<Leader>wv", "<CMD>vsplit<CR>", { desc = "Window: Split vertical" })

-- close window
map("n", "<Leader>wd", "<CMD>wd<CR>")
-- resize vertically
map("n", "<Leader>H", "<CMD>vertical resize +5<CR>")
-- resize vertically
map("n", "<Leader>L", "<CMD>vertical resize -5<CR>")
-- switch windows by number
map("n", "<Leader>1", "<CMD>1wincmd w<CR>")
map("n", "<Leader>2", "<CMD>2wincmd w<CR>")
map("n", "<Leader>3", "<CMD>3wincmd w<CR>")
map("n", "<Leader>4", "<CMD>4wincmd w<CR>")

-- track the last focused "normal editable" window (skip terminals, trees, pickers, floats)
local last_editable_win = nil

local function is_editable_win(win)
  if not vim.api.nvim_win_is_valid(win) then
    return false
  end
  -- ignore floating windows
  if vim.api.nvim_win_get_config(win).relative ~= "" then
    return false
  end
  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].buftype ~= "" then
    return false -- terminal, nofile, prompt, quickfix, help, etc.
  end
  if not vim.bo[buf].modifiable then
    return false
  end
  return true
end

vim.api.nvim_create_autocmd("WinLeave", {
  group = vim.api.nvim_create_augroup("track_editable_win", { clear = true }),
  callback = function()
    local win = vim.api.nvim_get_current_win()
    if is_editable_win(win) then
      last_editable_win = win
    end
  end,
})

-- focus last editable window
map("n", "<Leader>0", function()
  local cur = vim.api.nvim_get_current_win()
  if last_editable_win and last_editable_win ~= cur and is_editable_win(last_editable_win) then
    vim.api.nvim_set_current_win(last_editable_win)
    return
  end
  -- fallback: pick any other editable window
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if win ~= cur and is_editable_win(win) then
      vim.api.nvim_set_current_win(win)
      return
    end
  end
end, { desc = "Window: Focus last editable" })

-- scroll through command mode with C-j and C-k
map("c", "<C-j>", "<C-n>")
map("c", "<C-k>", "<C-p>")

-- exit buffer
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
-- copy to system clipboard
map("v", "<Leader>sy", '"+y')
-- paste from system clipboard
map("n", "<Leader>sp", '"+p')
map("n", "<Leader>sP", '"+P')

-- keep selection while indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

--exit terminal mode
map("t", "<C-n>", "<C-\\><C-n><C-w>h")

-- alot of accidental presses
map("n", "<S-q>", "<nop>")

-- Setup inlay hints toggle when Snacks is available
if vim.lsp.inlay_hint then
  vim.schedule(function()
    if Snacks and Snacks.toggle and Snacks.toggle.inlay_hints then
      Snacks.toggle.inlay_hints():map("<leader>th")
    end
  end)
end

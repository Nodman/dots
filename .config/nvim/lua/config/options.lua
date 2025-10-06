local indent = 2

local opt = vim.opt

vim.g.netrw_fastbrowse = 0
vim.g.lazydev_enabled = true

vim.api.nvim_create_autocmd('User', {
  pattern = 'PrStatusUpdate',
  callback = function()
    vim.api.nvim_command('redrawstatus!')
  end,
})

-- don't wrap cuz animation
opt.wrap = false

-- hide cmd
opt.cmdheight = 0

-- backups
opt.backup = true
opt.backupdir = vim.fn.stdpath('state') .. '/backup'
-- fold by indent
-- opt("o", "foldmethod", "indent")
-- highlight line with cursor
opt.updatetime = 100
-- highlight line with cursor
opt.cursorline = true
-- size of indent
opt.shiftwidth = indent
-- number of spaces tabs counts for
opt.tabstop = indent
-- insert spaces when TAB is pressed.
opt.expandtab = true
-- enable sign column
opt.signcolumn = 'yes:1'
-- set number column width
opt.numberwidth = 1
-- hybrid line numbers
opt.relativenumber = true
opt.number = true
-- allow backspace over everything in insert mode
opt.backspace = 'indent,eol,start'
-- round indents
opt.shiftround = true
-- ignore case
opt.ignorecase = true
-- don't ignore case with capitals
opt.smartcase = true
-- support true colours
opt.termguicolors = true
-- command line completion
opt.wildmenu = true
-- allow to search in sub directories
opt.path = opt.path + '**'
-- don't give ins-completion-menu messages
opt.shortmess = opt.shortmess + 'c'
-- timeout length
opt.timeoutlen = 1000 -- Default is 1000
opt.ttimeoutlen = 100
-- use 'magic' patterns (extended regular expressions)
opt.magic = true
-- show matching brackets
opt.showmatch = true
-- enable list chars
opt.list = true
-- opt.listchars = 'tab:› ,trail:·,nbsp:~,extends:»,precedes:«' -- Added extends/precedes
-- split rules
opt.splitbelow = true
opt.splitright = true

-- Save localoptions to session file
opt.sessionoptions = opt.sessionoptions + 'localoptions'
--
opt.wildignore = opt.wildignore + '*/node_modules/*,*/tmp/*,*.so,*.swp,*.zip,*.pyc,*.db,*.sqlite,package-lock.json'
--
opt.spell = false
opt.spellfile = vim.fn.stdpath('config') .. '/spell/en.utf-8.add'
-- python version (Note: 'pyx' is deprecated, use vim.g.python3_host_prog)
-- opt.pyx = 3 -- Commented out, use vim.g if needed
--
opt.secure = true

-- remove ~ at the end of the buffer
opt.fillchars = opt.fillchars + 'eob: '

opt.showmode = false

opt.laststatus = 3

opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }

local opt = vim.opt
local g = vim.g

-- General settings
g.loaded_netrw = 1
g.loaded_netrwPlugin = 1
opt.clipboard = "unnamedplus"

-- Interface options
opt.termguicolors = true
opt.number = true
opt.relativenumber = true
opt.fillchars = "eob: "
opt.cursorline = true
opt.signcolumn = "yes"
opt.scrolloff = 8
opt.winborder = "single"
opt.wrap = true
opt.linebreak = true
opt.breakindent = true
opt.colorcolumn = "80"

-- Indentation settings
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true

-- Window & Display
-- opt.cmdheight      = 0
opt.splitright = true
opt.splitbelow = true

-- File handling
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.updatetime = 250
opt.timeoutlen = 300

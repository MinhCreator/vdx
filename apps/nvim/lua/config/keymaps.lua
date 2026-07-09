-- Custom mapping function
local function map(mode, lhs, rhs, opts)
	local options = { noremap = true, silent = true }
	if opts then
		if type(opts) == "string" then
			opts = { desc = opts }
		end
		options = vim.tbl_extend("force", options, opts)
	end
	vim.keymap.set(mode, lhs, rhs, options)
end

-- Remaping leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- General keymaps
map("i", "jk", "<ESC>", "Exit form insert mode")
map("i", "kj", "<ESC>", "Exit from insert mode")
map("v", "jk", "<ESC>", "Exit from visaul mode")
map("v", "kj", "<ESC>", "Exit from visual mode")

map("n", "<C-h>", "<C-w>h", "Window left")
map("n", "<C-j>", "<C-w>j", "Window down")
map("n", "<C-k>", "<C-w>k", "Window up")
map("n", "<C-l>", "<C-w>l", "Window right")
map("n", "<C-q>", ":close<CR>", "Close window")

map("n", "<leader>sv", ":vsplit<CR>", "Vertical split")
map("n", "<leader>sh", ":split<CR>", "Horizontal split")

map("n", "<leader>w", ":w<CR>", "Save buffer")
map("n", "<leader>wq", ":wqa<CR>", "Save all end exit")
map("n", "<leader>qq", ":qa!<CR>", "Exit without saving")

map({ "n", "v" }, "<leader>d", '"_d', "Remove line")
map({ "n", "v" }, "<leader>y", "yy", "Yank line")

map("v", "<", "<gv", "Decrease indentation")
map("v", ">", ">gv", "Increase indentation")
map("v", "J", ":m '>+1<CR>gv=gv", "Move selection down")
map("v", "K", ":m '<-2<CR>gv=gv", "Move selection up")

map("i", "---", "—", "Insert em-dash")

-- Plugin: Conform
map("n", "<leader>fmt", function()
	require("conform").format({
		lsp_fallback = true,
		async = false,
		timeout_ms = 500,
	})
end, "Format buffer")

-- Plugin: Flash
map({ "n", "x", "o" }, "s", function()
	require("flash").jump()
end, "Flash jump")
map({ "n", "x", "o" }, "S", function()
	require("flash").treesitter()
end, "Flash treesitter")

-- Plugin: Telescope
map("n", "<leader>ff", ":Telescope find_files<CR>", "Find file")
map("n", "<leader>fg", ":Telescope live_grep<CR>", "Find text")
map("n", "<leader>fb", ":Telescope buffers<CR>", "Find buffer")
map("n", "<leader>fh", ":Telescope help_tags<CR>", "Neovim documentation")
map("n", "<leader>fw", ":Telescope grep_string<CR>", "Find word")
map("n", "<leader>fo", ":Telescope oldfiles<CR>", "Recent files")
map("n", "<leader>fk", ":Telescope keymaps<CR>", "Keymaps")

-- Plugin: Bufferline
map("n", "<S-h>", ":BufferLineCyclePrev<CR>", "Previous buffer")
map("n", "<S-l>", ":BufferLineCycleNext<CR>", "Next buffer")
map("n", "<S-x>", ":Bdelete<CR>", "Close current buffer")
map("n", "<S-p>", ":BufferLineTogglePin<CR>", "Pin buffer")
map("n", "<A-h>", ":BufferLineMovePrev<CR>", "Move buffer left")
map("n", "<A-l>", ":BufferLineMoveNext<CR>", "Move buffer right")

-- Plugin: Neo-tree
map("n", "<leader>e", ":Neotree toggle<CR>", "Toggle neo-tree")

-- Plugin: Auto-session
map("n", "<leader>Q", function()
	local auto_session = require("auto-session")
	auto_session.DeleteSession()
	vim.cmd("qa!")
end, "Close and delete session")

-- Plugin: REnder Markdown
map("n", "<leader>mp", ":RenderMarkdown toggle<CR>", "Toggle Markdown Preview")

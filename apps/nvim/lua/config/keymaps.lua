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

-- Leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

---------- General ----------
map("i", "jk", "<ESC>", "Exit from insert mode")
map("i", "kj", "<ESC>", "Exit from insert mode")
map("v", "jk", "<ESC>", "Exit from visual mode")
map("v", "kj", "<ESC>", "Exit from visual mode")

map("n", "<leader>w", ":w<CR>", "Save buffer")
map("n", "<leader>wq", ":wqa<CR>", "Save all and exit")
map("n", "<leader>qq", ":qa!<CR>", "Exit without saving")

map({ "n", "v" }, "<leader>d", '"_d', "Delete to black hole")
map({ "n", "v" }, "<leader>y", "yy", "Yank line")

---------- Windows ----------
map("n", "<C-h>", "<C-w>h", "Window left")
map("n", "<C-j>", "<C-w>j", "Window down")
map("n", "<C-k>", "<C-w>k", "Window up")
map("n", "<C-l>", "<C-w>l", "Window right")
map("n", "<C-q>", ":close<CR>", "Close window")

map("n", "<leader>sv", ":vsplit<CR>", "Vertical split")
map("n", "<leader>sh", ":split<CR>", "Horizontal split")

---------- Buffers ----------
map("n", "<S-h>", ":BufferLineCyclePrev<CR>", "Previous buffer")
map("n", "<S-l>", ":BufferLineCycleNext<CR>", "Next buffer")
map("n", "<S-x>", function()
	local buf = vim.fn.bufnr()
	if vim.fn.buflisted(vim.fn.bufnr("#")) == 1 then
		vim.cmd("buffer #")
	else
		vim.cmd("bprevious")
	end
	vim.cmd("bdelete! " .. buf)
end, "Close buffer")
map("n", "<S-p>", ":BufferLineTogglePin<CR>", "Pin buffer")
map("n", "<A-h>", ":BufferLineMovePrev<CR>", "Move buffer left")
map("n", "<A-l>", ":BufferLineMoveNext<CR>", "Move buffer right")

---------- Editing ----------
map("v", "<", "<gv", "Indent left")
map("v", ">", ">gv", "Indent right")
map("v", "J", ":m '>+1<CR>gv=gv", "Move selection down")
map("v", "K", ":m '<-2<CR>gv=gv", "Move selection up")
map("i", "---", "—", "Insert em-dash")

---------- Search (Telescope) ----------
map("n", "<leader>ff", ":Telescope find_files<CR>", "Find file")
map("n", "<leader>fg", ":Telescope live_grep<CR>", "Find text")
map("n", "<leader>fb", ":Telescope buffers<CR>", "Find buffer")
map("n", "<leader>fh", ":Telescope help_tags<CR>", "Help tags")
map("n", "<leader>fw", ":Telescope grep_string<CR>", "Find word")
map("n", "<leader>fo", ":Telescope oldfiles<CR>", "Recent files")
map("n", "<leader>fk", ":Telescope keymaps<CR>", "Keymaps")

---------- Diagnostics ----------
map("n", "<leader>fmt", function()
	require("conform").format({
		lsp_fallback = true,
		async = false,
		timeout_ms = 500,
	})
end, "Format buffer")

---------- Plugins ----------
map({ "n", "x", "o" }, "s", function()
	require("flash").jump()
end, "Flash jump")
map({ "n", "x", "o" }, "S", function()
	require("flash").treesitter()
end, "Flash treesitter")

map("n", "<leader>e", ":Neotree toggle<CR>", "Toggle neo-tree")
map("n", "<leader>mp", ":RenderMarkdown toggle<CR>", "Toggle Markdown Preview")

map("n", "<leader>Q", function()
	local auto_session = require("auto-session")
	auto_session.DeleteSession()
	vim.cmd("qa!")
end, "Delete session and quit")

---------- LSP ----------
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local bufnr = args.buf

		map("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "LSP hover" })
		map("i", "<C-k>", vim.lsp.buf.signature_help, { buffer = bufnr, desc = "LSP signature help" })
		map("n", "gd", vim.lsp.buf.definition, { buffer = bufnr, desc = "Go to definition" })
		map("n", "gr", vim.lsp.buf.references, { buffer = bufnr, desc = "Find references" })
		map("n", "<leader>rn", vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename symbol" })
		map("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr, desc = "Code action" })
	end,
})

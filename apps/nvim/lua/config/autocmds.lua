-- Opening neo-tree when opening a directory
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		local stats = vim.uv.fs_stat(vim.fn.argv(0) or "")
		if vim.fn.argc() == 0 or (stats and stats.type == "directory") then
			vim.cmd("Neotree show")
		end
	end,
})

-- Display errors on hover
vim.api.nvim_create_autocmd("CursorHold", {
	buffer = vim.api.nvim_get_current_buf(),
	callback = function()
		local options = {
			focusable = false,
			close_events = { "CursorMoved", "CursorMovedI", "BufLeave" },
			border = "single",
			source = "always",
			prefix = " ",
			scope = "cursor",
		}
		vim.diagnostic.open_float(nil, options)
	end,
})

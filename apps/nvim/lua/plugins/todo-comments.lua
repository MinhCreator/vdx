return {
	"folke/todo-comments.nvim",
	event = { "BufReadPost", "BufNewFile" },
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		require("todo-comments").setup({
			signs = false,
			highlight = {
				keyword = "fg",
				after = "",
			},
		})

		vim.keymap.set("n", "<leader>ft", function()
			require("telescope.builtin").todo_comments()
		end, { desc = "Find TODOs" })
	end,
}

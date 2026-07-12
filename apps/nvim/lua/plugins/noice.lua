return {
	"folke/noice.nvim",
	event = "VeryLazy",
	dependencies = {
		"MunifTanjim/nui.nvim",
	},
	config = function()
		require("noice").setup({
			presets = {
				bottom_search = true,
				command_palette = true,
				long_message_to_split = true,
				lsp_doc_border = true,
			},
			notify = {
				view = "mini",
			},
			views = {
				mini = {
					border = { style = "single" },
					timeout = 3000, -- сколько уведомление висит на экране, мс
				},
				cmdline_popup = {
					border = { style = "single" },
				},
				popupmenu = {
					border = { style = "single" },
				},
			},
			routes = {
				{
					filter = {
						event = "notify",
						find = "No information available",
					},
					opts = { skip = true },
				},
			},
		})
	end,
}

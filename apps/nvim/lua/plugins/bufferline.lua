return {
	"akinsho/bufferline.nvim",
	version = "*",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	lazy = false,
	config = function()
		require("bufferline").setup({
			options = {
				mode = "buffers",
				show_buffer_icons = true,
				show_buffer_close_icons = false,
				show_close_icon = false,
				indicator = { style = "icon", icon = "" },
				separator_style = { "|", "|" },
				offsets = {
					{
						filetype = "neo-tree",
						text = "File explorer",
						text_align = "left",
						separator = true,
					},
				},
			},
			highlights = {
				-- Inactive elements:
				background = { bg = "#282828" },
				buffer_visible = { bg = "#282828" },
				separator = { bg = "#282828" },
				separator_visible = { bg = "#282828" },
				indicator_visible = { bg = "#282828" },
				modified = { bg = "#282828" },
				-- Active elements:
				buffer_selected = { bg = "#45403d" },
				separator_selected = { bg = "#45403d" },
				indicator_selected = { bg = "#45403d" },
				modified_selected = { bg = "#45403d" },
			},
		})
	end,
}

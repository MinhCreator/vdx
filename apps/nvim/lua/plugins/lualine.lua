return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("lualine").setup({
			options = {
				globalstatus = true,
				theme = "gruvbox-material",
				component_separators = "",
				section_separators = { "", "" },
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = {
					{ "filename", path = 1 },
				},
				lualine_c = {
					{ "branch", "diff", "diagnostic" },
				},
				lualine_x = {},
				lualine_y = { "filetype" },
				lualine_z = { "location" },
			},
		})
	end,
}

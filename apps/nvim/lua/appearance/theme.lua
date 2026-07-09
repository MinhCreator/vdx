return {
	"sainnhe/gruvbox-material",
	priority = 1000,
	config = function()
		-- Colors configuration
		vim.g.gruvbox_material_better_perfomance = 1
		vim.g.gruvbox_material_background = "medium"
		vim.g.gruvbox_material_foreground = "material"
		vim.g.gruvbox_material_transparent_background = 1
		-- Font configuration
		vim.g.gruvbox_material_enable_bold = 1
		vim.g.gruvbox_material_enable_italic = 1
		vim.cmd.colorscheme("gruvbox-material")
	end
}

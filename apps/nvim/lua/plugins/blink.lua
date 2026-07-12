return {
	"saghen/blink.cmp",
	version = "*",
	dependencies = {
		"rafamadriz/friendly-snippets",
	},
	config = function()
		require("blink.cmp").setup({
			appearance = {
				use_nvim_cmp_as_default = true,
				nerd_font_variant = "mono",
			},
			completion = {
				list = {
					selection = {
						preselect = false,
						auto_insert = true,
					},
				},
				menu = {
					border = "single",
					winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,BlinkCmpMenuSelection:BlinkCmpMenuSelection",
					draw = {
						columns = {
							{ "label", "label_description", gap = 1 },
							{ "kind_icon", "kind" },
						},
					},
				},
				documentation = {
					window = {
						border = "single",
						winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
					},
				},
			},
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			keymap = {
				preset = "none",
				["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
				["<C-e>"] = { "hide" },
				["<CR>"] = { "accept", "fallback" },
				["<Tab>"] = { "select_next", "fallback" },
				["<S-Tab>"] = { "select_prev", "fallback" },
				["<C-b>"] = { "scroll_documentation_up", "fallback" },
				["<C-f>"] = { "scroll_documentation_down", "fallback" },
			},
		})
	end,
}

return {
	"rmagatti/auto-session",
	lazy = false,
	config = function()
		require("auto-session").setup({
			log_level = "error",
			auto_restore_enabled = true,
			auto_session_suppress_dirs = { "/", "~", "/Downloads" },
			auto_session_enable_last_session = false,
			pre_save_cmds = { "Neotree close" },
			session_lens = {
				load_on_setup = true,
				theme_conf = {
					border = true,
				},
				previewer = false,
			},
		})
	end,
}

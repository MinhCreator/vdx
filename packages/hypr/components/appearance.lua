-- https://wiki.hypr.land/Configuring/Basics/Variables/
-- https://wiki.hypr.land/Configuring/Layouts/Master-Layout/

local colors = require("components.colors")

hl.config({
	general = {
		layout = "master",
		gaps_in = 10,
		gaps_out = 20,
		-- 1px frames like the bar's popups: light on the focused window, quiet on the rest
		border_size = 1,
		col = {
			active_border = colors.foreground2,
			inactive_border = colors.background3,
		},
	},

	master = {
		new_status = "slave",
		mfact = 0.5,
	},

	decoration = {
		rounding = 0,
		active_opacity = 1.0,
		inactive_opacity = 1.0,
		fullscreen_opacity = 1.0,

		blur = {
			enabled = false,
		},

		shadow = {
			enabled = true,
			range = 20,
			render_power = 8,
			-- 0xAARRGGBB format (not rgba() string): rgba(00000066) -> 0x66000000
			color = 0x66000000,
			color_inactive = 0x22000000,
		},
	},
})

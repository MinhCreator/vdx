-- Hyprland — input devices
-- https://wiki.hypr.land/Configuring/Basics/Variables/#input

hl.config({
	input = {
		kb_layout = "us,ru",
		kb_options = "grp:caps_toggle",
		follow_mouse = 1,
		repeat_rate = 50,
		repeat_delay = 300,
		touchpad = {
			natural_scroll = true,
			tap_to_click = true,
			disable_while_typing = true,
		},
	},
})

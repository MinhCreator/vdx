-- Hyprland — input devices
-- https://wiki.hypr.land/Configuring/Basics/Variables/#input

hl.config({
	input = {
		kb_layout = "us",
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

-- this machine's layouts (and how to switch them): machine/input.lua, from .machine.toml
require("components.machine").load("input")

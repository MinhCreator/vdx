-- Hyprland — appearance: gaps, borders, decoration
-- https://wiki.hypr.land/Configuring/Basics/Variables/
-- https://wiki.hypr.land/Configuring/Layouts/Master-Layout/

local colors = require("components.colors")

hl.config({
	general = {
		layout = "master",
		gaps_in = 10,
		gaps_out = 20,
		-- 2px frames like the bar's popups: light on the focused window, quiet on the rest
		border_size = 2,
		col = {
			active_border = colors.frame_active,
			inactive_border = colors.background3,
		},
	},

	-- until the shell sets its wallpaper: the theme's background1 (the shell's own colour),
	-- not Hyprland's mascot pictures and logo
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
		background_color = colors.background1,
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
			render_power = 4,
			-- 0xAARRGGBB format (not rgba() string): rgba(00000066) -> 0x66000000
			color = 0x66000000,
			color_inactive = 0x22000000,
		},
	},
})

-- Shell Manager › Appearance › Corners: window rounding (CornersService.qml
-- writes it and also applies it live)
local okc, corners = pcall(dofile, os.getenv("HOME") .. "/.local/state/dotfiles/corners.lua")
if okc and type(corners) == "table" and corners.rounding then
	hl.config({ decoration = { rounding = corners.rounding } })
end

-- Shell Manager › Appearance › Style › Accent › Window border: the focused
-- frame's colour (AccentService.qml writes it and applies it live)
local oka, accent = pcall(dofile, os.getenv("HOME") .. "/.local/state/dotfiles/accent.lua")
if oka and type(accent) == "table" and accent.border then
	hl.config({ general = { col = { active_border = accent.border } } })
end

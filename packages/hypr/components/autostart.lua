-- Hyprland — autostart
-- hyprland.start fires once at startup, not on config reload.
-- https://wiki.hypr.land/Configuring/Basics/Autostart/

hl.on("hyprland.start", function()
	-- the bar fills it with the theme's (or the user's) solid colour
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("qs -c taskbar")
	hl.exec_cmd("mako")
	-- the cursor picked in the Shell Manager, at its size
	hl.exec_cmd("python3 ~/.config/quickshell/taskbar/scripts/cursors.py restore")
end)

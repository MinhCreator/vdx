-- Hyprland — autostart
-- hyprland.start fires once at startup, not on config reload.
-- https://wiki.hypr.land/Configuring/Basics/Autostart/

hl.on("hyprland.start", function()
	-- the bar fills it with the theme's (or the user's) solid colour
	hl.exec_cmd("awww-daemon")
	-- the shell's window rules, written once on a fresh install
	hl.exec_cmd("python3 ~/.config/quickshell/shell/scripts/shellapps.py ensure")
	hl.exec_cmd("qs -c shell")
	hl.exec_cmd("mako")
	-- the cursor picked in the Shell Manager, at its size
	hl.exec_cmd("python3 ~/.config/quickshell/shell/scripts/cursors.py restore")
end)

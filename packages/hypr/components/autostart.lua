-- Hyprland — autostart
-- hyprland.start fires once at startup, not on config reload.
-- https://wiki.hypr.land/Configuring/Basics/Autostart/

-- this machine's start-up parts (the mic level), if the profile asks for them
require("components.machine").load("autostart")

hl.on("hyprland.start", function()
	-- the bar fills it with the theme's (or the user's) solid colour
	-- no cache: the daemon would show the last picture it cached, not the chosen one
	hl.exec_cmd("awww-daemon --no-cache")
	-- the shell's window rules, written once on a fresh install
	hl.exec_cmd("python3 ~/.config/quickshell/shell/scripts/shellapps.py ensure")
	-- the shell, started again if it crashes (not when it is killed or restarted)
	hl.exec_cmd("~/.config/quickshell/shell/scripts/supervise.sh")
	hl.exec_cmd("mako")
	-- the cursor picked in the Shell Manager, at its size
	hl.exec_cmd("python3 ~/.config/quickshell/shell/scripts/cursors.py restore")
	-- the monitor scales and positions picked in the Display window, over the machine profile
	hl.exec_cmd("python3 ~/.config/quickshell/shell/scripts/display.py restore")
end)

-- hyprland.start fires once at startup, not on config reload.
-- https://wiki.hypr.land/Configuring/Basics/Autostart/

hl.on("hyprland.start", function()
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("awww img /home/diominvd/Pictures/Wallpapers/solid.jpeg")
	hl.exec_cmd("waybar")
	hl.exec_cmd("mako")
end)

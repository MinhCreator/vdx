-- https://wiki.hypr.land/Configuring/Basics/Monitors/
-- https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

hl.monitor({
	output = "eDP-1",
	mode = "1920x1080@144.00",
	position = "0x0",
	scale = 1.2,
})

hl.monitor({
	output = "HDMI-A-2",
	mode = "1920x1080@144.00",
	position = "1600x0",
	scale = 1,
})

hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-2", default = true })
for i = 2, 8 do
	hl.workspace_rule({ workspace = tostring(i), monitor = "HDMI-A-2" })
end

hl.workspace_rule({ workspace = "9", monitor = "eDP-1", default = true })
hl.workspace_rule({ workspace = "10", monitor = "eDP-1" })

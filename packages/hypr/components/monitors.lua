-- Hyprland — monitors and workspaces
-- https://wiki.hypr.land/Configuring/Basics/Monitors/
-- https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- this machine's outputs and workspace rules: machine/monitors.lua, from
-- .machine.toml; without it every output takes its preferred mode
if not require("components.machine").load("monitors") then
	hl.monitor({
		output = "",
		mode = "preferred",
		position = "auto",
		scale = "auto",
	})
end

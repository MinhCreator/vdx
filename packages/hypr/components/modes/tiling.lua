-- Hyprland — binds of the tiling mode (windowmode.lua loads the mode's file)
-- Super + H / J / K / L move the focus, the wheel (or Super +
-- arrows, Shell Manager › Windows) goes through workspaces.

local function bind(group, keys, action, what)
	hl.bind(keys, action, { description = group .. " · " .. what })
end

bind("Focus", "SUPER + H", hl.dsp.focus({ direction = "left" }), "Left")
bind("Focus", "SUPER + L", hl.dsp.focus({ direction = "right" }), "Right")
bind("Focus", "SUPER + K", hl.dsp.focus({ direction = "up" }), "Up")
bind("Focus", "SUPER + J", hl.dsp.focus({ direction = "down" }), "Down")

WheelBind("Workspaces", "SUPER", "mouse_down", "down", hl.dsp.focus({ workspace = "e+1" }), "Next workspace")
WheelBind("Workspaces", "SUPER", "mouse_up", "up", hl.dsp.focus({ workspace = "e-1" }), "Previous workspace")

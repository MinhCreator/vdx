-- Hyprland — binds of the scrolling mode, like Niri (windowmode.lua loads
-- the mode's file): Super + H / J / K / L move the focus; the row of columns
-- slides with Super + wheel (or Super + left / right) or a three-finger
-- swipe sideways; workspaces
-- stack up and down (Super + Shift + wheel, a three-finger swipe up / down).

local function bind(group, keys, action, what)
	hl.bind(keys, action, { description = group .. " · " .. what })
end

bind("Focus", "SUPER + H", hl.dsp.focus({ direction = "left" }), "Left")
bind("Focus", "SUPER + L", hl.dsp.focus({ direction = "right" }), "Right")
bind("Focus", "SUPER + K", hl.dsp.focus({ direction = "up" }), "Up")
bind("Focus", "SUPER + J", hl.dsp.focus({ direction = "down" }), "Down")

-- a lone window keeps its column width (half the screen) instead of
-- filling it, so a second one opens beside it, as in Niri
hl.config({ scrolling = { fullscreen_on_one_column = false } })
-- every wheel step is the bind's: with a delay, steps inside it would
-- reach the app under the pointer and scroll it too
hl.config({ binds = { scroll_event_delay = 0 } })

-- the layout's own move: the row slides, the pointer stays where it is
-- (a focus move would warp it to the newly focused window)
WheelBind("Scrolling", "SUPER", "mouse_down", "right", function() ScrollColumns(1) end, "Next column")
WheelBind("Scrolling", "SUPER", "mouse_up", "left", function() ScrollColumns(-1) end, "Previous column")
hl.gesture({ fingers = 3, direction = "left", action = function() ScrollColumns(1) end })
hl.gesture({ fingers = 3, direction = "right", action = function() ScrollColumns(-1) end })

-- the active column: half the screen <-> the whole of it, then into view
bind("Scrolling", "SUPER + W", function()
	local w = hl.get_active_window()
	if not w then return end
	local m = w.monitor or hl.get_active_monitor()
	local width = type(w.size) == "table" and (w.size.x or w.size[1]) or 0
	local wide = width > (m.width / (m.scale or 1)) * 0.75
	hl.dispatch(hl.dsp.layout(wide and "colresize 0.5" or "colresize 1.0"))
	hl.dispatch(hl.dsp.layout("fit active"))
end, "Wide / half column")

WheelBind("Scrolling", "SUPER + SHIFT", "mouse_down", "down", hl.dsp.focus({ workspace = "e+1" }), "Workspace below")
WheelBind("Scrolling", "SUPER + SHIFT", "mouse_up", "up", hl.dsp.focus({ workspace = "e-1" }), "Workspace above")
hl.gesture({ fingers = 3, direction = "vertical", action = "workspace" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1, bezier = "smoothOut", style = "slidevert" })

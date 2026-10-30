-- Hyprland — binds of the floating mode (windowmode.lua loads the mode's file)
-- Like Windows' Super + arrows, on Super + H / J / K / L: the active window
-- to the left / right half, maximized and back, minimized (to the taskbar);
-- Alt + Tab switches windows.
-- The wheel (or Super + up / down) goes through workspaces.

local function bind(group, keys, action, what)
	hl.bind(keys, action, { description = group .. " · " .. what })
end

bind("Floating", "SUPER + H", function() SnapWindow("left") end, "Left half")
bind("Floating", "SUPER + L", function() SnapWindow("right") end, "Right half")
bind("Floating", "SUPER + K", function() MaximizeWindow() end, "Maximize / back")
bind("Floating", "SUPER + J", function() MinimizeWindow() end, "Minimize")

-- the window switcher (apps/switcher/Switcher.qml); other modes don't bind Alt + Tab
bind("Shell", "ALT + TAB", hl.dsp.exec_cmd("qs -c shell ipc call switcher next"), "Window switcher")
bind("Shell", "ALT + SHIFT + TAB", hl.dsp.exec_cmd("qs -c shell ipc call switcher back"), "Window switcher back")

WheelBind("Workspaces", "SUPER", "mouse_down", "down", function() StepWorkspace(1) end, "Next workspace")
WheelBind("Workspaces", "SUPER", "mouse_up", "up", function() StepWorkspace(-1) end, "Previous workspace")

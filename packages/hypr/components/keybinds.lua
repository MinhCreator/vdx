-- Hyprland — keybinds
-- https://wiki.hypr.land/Configuring/Basics/Binds/
-- https://wiki.hypr.land/Configuring/Basics/Dispatchers/
--
-- Every bind carries a description "Group · What it does": hyprctl binds
-- shows it, and the Shell Manager (Super+S › Binds) lists binds by group.

local mainMod = "SUPER"

local function bind(group, keys, action, what, opts)
	opts = opts or {}
	opts.description = group .. " · " .. what
	hl.bind(keys, action, opts)
end

-- apps
bind("Apps", mainMod .. " + Q", hl.dsp.exec_cmd("kitty"), "Terminal")
bind("Apps", mainMod .. " + E", hl.dsp.exec_cmd("kitty -e elio"), "File manager")
bind("Apps", mainMod .. " + M", hl.dsp.exec_cmd("kitty -e ncmpcpp"), "Music player")
bind("Apps", mainMod .. " + R", hl.dsp.exec_cmd("~/.config/rofi/dmenu.sh"), "App launcher")
bind("Apps", mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("~/.config/rofi/scripts.sh"), "Scripts menu")
bind("Apps", mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("~/.config/rofi/boot.sh"), "Boot menu")
bind("Apps", mainMod .. " + Z", hl.dsp.exec_cmd("swaylock"), "Lock the screen")

-- shell
bind("Shell", mainMod .. " + S", hl.dsp.exec_cmd("qs -c taskbar ipc call shell toggle"), "Shell Manager")
bind("Shell", mainMod .. " + B", hl.dsp.exec_cmd("qs -c taskbar ipc call clipboard toggle"), "Clipboard history")
bind("Shell", mainMod .. " + D", hl.dsp.exec_cmd("qs -c taskbar ipc call taskmanager toggle"), "Task manager")
bind("Shell", mainMod .. " + X", hl.dsp.exec_cmd("qs -c taskbar ipc call cleaner toggle"), "Cleaner")

-- screenshots (both copy to the clipboard)
-- capture tool: region / window / screen, shot or recording (again: stop recording)
bind("Capture", mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("qs -c taskbar ipc call capture open"), "Capture tool")
bind("Capture", mainMod .. " + P", hl.dsp.exec_cmd("grim - | wl-copy"), "Screenshot to the clipboard")

-- windows
bind("Windows", mainMod .. " + C", hl.dsp.window.close(), "Close")
bind("Windows", mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }), "Float / tile")
bind("Windows", mainMod .. " + F", hl.dsp.window.fullscreen(), "Fullscreen")

-- mouse
bind("Windows", mainMod .. " + mouse:272", hl.dsp.window.drag(), "Drag", { mouse = true })
bind("Windows", mainMod .. " + mouse:273", hl.dsp.window.resize(), "Resize", { mouse = true })

-- focus
bind("Focus", mainMod .. " + H", hl.dsp.focus({ direction = "left" }), "Left")
bind("Focus", mainMod .. " + L", hl.dsp.focus({ direction = "right" }), "Right")
bind("Focus", mainMod .. " + K", hl.dsp.focus({ direction = "up" }), "Up")
bind("Focus", mainMod .. " + J", hl.dsp.focus({ direction = "down" }), "Down")

-- move window
bind("Move", mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }), "Left")
bind("Move", mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }), "Right")
bind("Move", mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }), "Up")
bind("Move", mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }), "Down")

-- resize (repeating while held)
bind("Resize", mainMod .. " + comma", hl.dsp.window.resize({ x = -40, y = 0 }), "Narrower", { repeating = true })
bind("Resize", mainMod .. " + period", hl.dsp.window.resize({ x = 40, y = 0 }), "Wider", { repeating = true })
bind("Resize", mainMod .. " + SHIFT + comma", hl.dsp.window.resize({ x = 0, y = -40 }), "Shorter", { repeating = true })
bind("Resize", mainMod .. " + SHIFT + period", hl.dsp.window.resize({ x = 0, y = 40 }), "Taller", { repeating = true })

-- music / volume
bind("Media", mainMod .. " + ALT + P", hl.dsp.exec_cmd("mpc toggle"), "Play / pause")
bind("Media", mainMod .. " + ALT + left", hl.dsp.exec_cmd("mpc prev"), "Previous track")
bind("Media", mainMod .. " + ALT + right", hl.dsp.exec_cmd("mpc next"), "Next track")
bind("Media", mainMod .. " + ALT + up", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), "Volume up")
bind("Media", mainMod .. " + ALT + down", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), "Volume down")

-- workspaces 1-10 (SUPER+0 = workspace 10)
for i = 1, 10 do
	local key = (i == 10) and "0" or tostring(i)
	bind("Workspaces", mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }), "Go to " .. i)
	bind("Workspaces", mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), "Send window to " .. i)
end

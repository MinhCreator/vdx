-- https://wiki.hypr.land/Configuring/Basics/Binds/
-- https://wiki.hypr.land/Configuring/Basics/Dispatchers/

local mainMod = "SUPER"

-- apps
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("swaylock"))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("kitty -e elio"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("kitty -e ncmpcpp"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("~/.config/rofi/dmenu.sh"))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("~/.config/rofi/scripts.sh"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("~/.config/rofi/boot.sh"))

-- screenshots (both copy to the clipboard)
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("grim - | wl-copy"))

-- music / volume
hl.bind(mainMod .. " + ALT + P", hl.dsp.exec_cmd("mpc toggle"))
hl.bind(mainMod .. " + ALT + left", hl.dsp.exec_cmd("mpc prev"))
hl.bind(mainMod .. " + ALT + right", hl.dsp.exec_cmd("mpc next"))
hl.bind(mainMod .. " + ALT + up", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind(mainMod .. " + ALT + down", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))

-- mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- focus
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- move window
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))

-- resize (repeating while held)
hl.bind(mainMod .. " + comma", hl.dsp.window.resize({ x = -40, y = 0 }), { repeating = true })
hl.bind(mainMod .. " + period", hl.dsp.window.resize({ x = 40, y = 0 }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + comma", hl.dsp.window.resize({ x = 0, y = -40 }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + period", hl.dsp.window.resize({ x = 0, y = 40 }), { repeating = true })

-- workspaces 1-10 (SUPER+0 = workspace 10)
for i = 1, 10 do
	local key = (i == 10) and "0" or tostring(i)
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

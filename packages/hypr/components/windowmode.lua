-- Hyprland — window mode and snapping
-- Three ways windows behave, picked in the Shell Manager or the bar's windows
-- plugin (scripts/windowmode.sh writes the choice to
-- ~/.local/state/dotfiles/window-mode and calls WindowMode here):
--   tiling    — the master layout (appearance.lua);
--   floating  — like Windows: every window floats, dragged and resized with
--               the mouse; windows the mode floated carry the tag
--               "modefloat" and go back to the layout when it ends;
--   scrolling — like Niri: the built-in scrolling layout.
-- SnapWindow(spot) puts the active window on a part of its monitor.

local stateFile = os.getenv("HOME") .. "/.local/state/dotfiles/window-mode"

-- floating: new windows float, tagged as the mode's
local floatAll = hl.window_rule({
	name = "mode-float-all",
	match = { class = ".*" },
	float = true,
	tag = "+modefloat",
	enabled = false,
})

local function tagged(w)
	local tags = type(w.tags) == "table" and w.tags or { w.tags }
	for _, t in ipairs(tags) do
		if t == "modefloat" or t == "modefloat*" then return true end
	end
	return false
end

function WindowMode(mode)
	hl.config({ general = { layout = mode == "scrolling" and "scrolling" or "master" } })
	floatAll:set_enabled(mode == "floating")
	for _, w in ipairs(hl.get_windows()) do
		local target = "address:" .. w.address
		if mode == "floating" and not w.floating then
			hl.dispatch(hl.dsp.window.tag({ tag = "+modefloat", window = target }))
			hl.dispatch(hl.dsp.window.float({ action = "enable", window = target }))
		elseif mode ~= "floating" and w.floating and tagged(w) then
			hl.dispatch(hl.dsp.window.float({ action = "disable", window = target }))
			hl.dispatch(hl.dsp.window.tag({ tag = "-modefloat", window = target }))
		end
	end
end

-- the active window on a part of its monitor (logical pixels, under the bar)
local GAP = 8
local SPOTS = {
	-- spot = { x, y, width, height } as shares of the work area
	left = { 0, 0, 0.5, 1 }, right = { 0.5, 0, 0.5, 1 },
	top = { 0, 0, 1, 0.5 }, bottom = { 0, 0.5, 1, 0.5 },
	["top-left"] = { 0, 0, 0.5, 0.5 }, ["top-right"] = { 0.5, 0, 0.5, 0.5 },
	["bottom-left"] = { 0, 0.5, 0.5, 0.5 }, ["bottom-right"] = { 0.5, 0.5, 0.5, 0.5 },
	["left-third"] = { 0, 0, 1 / 3, 1 }, ["middle-third"] = { 1 / 3, 0, 1 / 3, 1 }, ["right-third"] = { 2 / 3, 0, 1 / 3, 1 },
	["left-two-thirds"] = { 0, 0, 2 / 3, 1 }, ["right-two-thirds"] = { 1 / 3, 0, 2 / 3, 1 },
	center = { 0.15, 0.1, 0.7, 0.8 }, maximize = { 0, 0, 1, 1 },
}

function SnapWindow(spot)
	local w = hl.get_active_window()
	local s = SPOTS[spot]
	if not w or not s then return end
	local m = w.monitor or hl.get_active_monitor()
	local scale = m.scale or 1
	local r = type(m.reserved) == "table" and m.reserved or {}
	local left, top, right, bottom = r[1] or r.left or 0, r[2] or r.top or 0, r[3] or r.right or 0, r[4] or r.bottom or 0
	local ax, ay = m.x + left + GAP, m.y + top + GAP
	local aw = m.width / scale - left - right - 2 * GAP
	local ah = m.height / scale - top - bottom - 2 * GAP
	-- neighbours keep a gap between them
	local x = ax + s[1] * aw + (s[1] > 0 and GAP / 2 or 0)
	local y = ay + s[2] * ah + (s[2] > 0 and GAP / 2 or 0)
	local width = s[3] * aw - ((s[1] > 0 and GAP / 2 or 0) + (s[1] + s[3] < 0.999 and GAP / 2 or 0))
	local height = s[4] * ah - ((s[2] > 0 and GAP / 2 or 0) + (s[2] + s[4] < 0.999 and GAP / 2 or 0))
	local target = "address:" .. w.address
	if not w.floating then hl.dispatch(hl.dsp.window.float({ action = "enable", window = target })) end
	hl.dispatch(hl.dsp.window.resize({ x = math.floor(width), y = math.floor(height), window = target }))
	hl.dispatch(hl.dsp.window.move({ x = math.floor(x), y = math.floor(y), window = target }))
end

-- the row of columns one step sideways (scrolling): not past the last
-- column — when the outermost one on that side is already on screen, no move
function ScrollColumns(dir)
	local m = hl.get_active_monitor()
	local ws = m and m.active_workspace
	if not ws then return end
	local scale = m.scale or 1
	local left, right = m.x, m.x + m.width / scale
	local minX, maxX = nil, nil
	for _, w in ipairs(hl.get_workspace_windows(ws.id)) do
		if w.mapped and not w.floating and not w.hidden then
			local x = type(w.at) == "table" and (w.at.x or w.at[1]) or 0
			local width = type(w.size) == "table" and (w.size.x or w.size[1]) or 0
			minX = minX and math.min(minX, x) or x
			maxX = maxX and math.max(maxX, x + width) or x + width
		end
	end
	if not minX then return end
	if dir > 0 and maxX <= right + 1 then return end
	if dir < 0 and minX >= left - 1 then return end
	hl.dispatch(hl.dsp.layout(dir > 0 and "move +col" or "move -col"))
end

-- the mode chosen last, at every start and reload (a switch reloads the
-- config, so the mode's binds and gestures below are set from scratch)
local f = io.open(stateFile, "r")
local saved = f and f:read("*l") or "tiling"
if f then f:close() end
WindowMode(saved)

-- wheel and touchpad, the mode's way
local function bind(keys, action, what)
	hl.bind(keys, action, { description = (saved == "scrolling" and "Scrolling" or "Workspaces") .. " · " .. what })
end

if saved == "scrolling" then
	-- a lone window keeps its column width (half the screen) instead of
	-- filling it, so a second one opens beside it, as in Niri
	hl.config({ scrolling = { fullscreen_on_one_column = false } })
	-- every wheel step is the bind's: with a delay, steps inside it would
	-- reach the app under the pointer and scroll it too
	hl.config({ binds = { scroll_event_delay = 0 } })
	-- the row of columns: Super + wheel, or a three-finger swipe sideways
	-- the layout's own move: the row slides, the pointer stays where it is
	-- (a focus move would warp it to the newly focused window)
	bind("SUPER + mouse_down", function() ScrollColumns(1) end, "Next column")
	bind("SUPER + mouse_up", function() ScrollColumns(-1) end, "Previous column")
	hl.gesture({ fingers = 3, direction = "left", action = function() ScrollColumns(1) end })
	hl.gesture({ fingers = 3, direction = "right", action = function() ScrollColumns(-1) end })
	-- the active column: half the screen <-> the whole of it, then into view
	bind("SUPER + W", function()
		local w = hl.get_active_window()
		if not w then return end
		local m = w.monitor or hl.get_active_monitor()
		local width = type(w.size) == "table" and (w.size.x or w.size[1]) or 0
		local wide = width > (m.width / (m.scale or 1)) * 0.75
		hl.dispatch(hl.dsp.layout(wide and "colresize 0.5" or "colresize 1.0"))
		hl.dispatch(hl.dsp.layout("fit active"))
	end, "Wide / half column")
	-- workspaces stack up and down: Super + Shift + wheel, a three-finger swipe up / down
	bind("SUPER + SHIFT + mouse_down", hl.dsp.focus({ workspace = "e+1" }), "Workspace below")
	bind("SUPER + SHIFT + mouse_up", hl.dsp.focus({ workspace = "e-1" }), "Workspace above")
	hl.gesture({ fingers = 3, direction = "vertical", action = "workspace" })
	hl.animation({ leaf = "workspaces", enabled = true, speed = 1, bezier = "smoothOut", style = "slidevert" })
else
	bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }), "Next workspace")
	bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }), "Previous workspace")
end

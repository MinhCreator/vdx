-- Hyprland — window mode and snapping
-- Three ways windows behave, picked in the Shell Manager or the bar's windows
-- plugin (scripts/windowmode.sh writes the choice to
-- ~/.local/state/dotfiles/window-mode and calls WindowMode here):
--   tiling    — the master layout (appearance.lua);
--   floating  — like Windows: every window floats, dragged and resized with
--               the mouse; windows the mode floated carry the tag
--               "modefloat" and go back to the layout when it ends;
--   scrolling — like Niri: the built-in scrolling layout.
-- SnapWindow(spot) puts the active window on a part of its monitor;
-- MinimizeWindow / RestoreWindow / MaximizeWindow — the bottom dock's buttons.
-- The options (gaps, master, column width, floating arrangement) come from
-- ~/.local/state/dotfiles/windows.lua, written by the Shell Manager › Windows.

local stateDir = os.getenv("HOME") .. "/.local/state/dotfiles/"
local stateFile = stateDir .. "window-mode"

local ok, opts = pcall(dofile, stateDir .. "windows.lua")
if not ok or type(opts) ~= "table" then opts = {} end
hl.config({
	general = { gaps_in = opts.gapsIn or 10, gaps_out = opts.gapsOut or 20 },
	master = { mfact = opts.mfact or 0.5, new_status = opts.newStatus or "slave" },
	scrolling = { column_width = opts.columnWidth or 0.5 },
})

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
	local floated = {}
	for _, w in ipairs(hl.get_windows()) do
		local target = "address:" .. w.address
		if mode == "floating" and not w.floating then
			hl.dispatch(hl.dsp.window.tag({ tag = "+modefloat", window = target }))
			hl.dispatch(hl.dsp.window.float({ action = "enable", window = target }))
			table.insert(floated, w)
		elseif mode ~= "floating" and w.floating and tagged(w) then
			hl.dispatch(hl.dsp.window.float({ action = "disable", window = target }))
			hl.dispatch(hl.dsp.window.tag({ tag = "-modefloat", window = target }))
		end
	end
	ArrangeFloating(floated)
	-- minimizing is the floating mode's (its dock): leaving it, they come back
	if mode ~= "floating" then
		for _, w in ipairs(hl.get_windows()) do
			if w.workspace and w.workspace.name == "special:minimized" then RestoreWindow(w.address) end
		end
	end
end

-- the active window on a part of its monitor (logical pixels, under the bar)
local GAP = 8

-- a monitor's work area: x, y, width, height (logical, inside the gaps)
local function workArea(m)
	local scale = m.scale or 1
	local r = type(m.reserved) == "table" and m.reserved or {}
	local left, top, right, bottom = r[1] or r.left or 0, r[2] or r.top or 0, r[3] or r.right or 0, r[4] or r.bottom or 0
	return m.x + left + GAP, m.y + top + GAP,
		m.width / scale - left - right - 2 * GAP, m.height / scale - top - bottom - 2 * GAP
end

local function place(w, x, y, width, height)
	local target = "address:" .. w.address
	hl.dispatch(hl.dsp.window.resize({ x = math.floor(width), y = math.floor(height), window = target }))
	hl.dispatch(hl.dsp.window.move({ x = math.floor(x), y = math.floor(y), window = target }))
end

-- windows the floating mode just floated, laid out per workspace the way
-- opts.arrange says: cascade (a staircase from the top-left), grid (side by
-- side, no overlap) or center (each in the middle, the same size)
function ArrangeFloating(list)
	local byWs = {}
	for _, w in ipairs(list) do
		local ws = w.workspace and w.workspace.id or 0
		if ws > 0 then
			byWs[ws] = byWs[ws] or {}
			table.insert(byWs[ws], w)
		end
	end
	local arrange = opts.arrange or "cascade"
	for _, wins in pairs(byWs) do
		local ax, ay, aw, ah = workArea(wins[1].monitor or hl.get_active_monitor())
		local n = #wins
		if arrange == "grid" then
			local cols = math.ceil(math.sqrt(n))
			local rows = math.ceil(n / cols)
			local cw, ch = (aw - (cols - 1) * GAP) / cols, (ah - (rows - 1) * GAP) / rows
			for i, w in ipairs(wins) do
				local c, r = (i - 1) % cols, math.floor((i - 1) / cols)
				place(w, ax + c * (cw + GAP), ay + r * (ch + GAP), cw, ch)
			end
		elseif arrange == "center" then
			for _, w in ipairs(wins) do place(w, ax + aw * 0.15, ay + ah * 0.1, aw * 0.7, ah * 0.8) end
		else
			local step = 40
			local width, height = aw * 0.6, ah * 0.7
			for i, w in ipairs(wins) do
				local k = (i - 1) % math.max(1, math.floor(math.min(aw - width, ah - height) / step) + 1)
				place(w, ax + k * step, ay + k * step, width, height)
			end
		end
	end
end
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
	local ax, ay, aw, ah = workArea(w.monitor or hl.get_active_monitor())
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

-- the dock's buttons: a minimized window waits on the special workspace
-- "minimized" (not shown); restored, it comes to the active workspace
function MinimizeWindow(address)
	if not floatAll:is_enabled() then return end
	local w = address and { address = address } or hl.get_active_window()
	if not w then return end
	hl.dispatch(hl.dsp.window.move({ workspace = "special:minimized", window = "address:" .. w.address, follow = false }))
end

function RestoreWindow(address)
	local target = "address:" .. address
	hl.dispatch(hl.dsp.window.move({ workspace = hl.get_active_workspace().id, window = target }))
	hl.dispatch(hl.dsp.focus({ window = target }))
end

-- floating: the whole work area and back to the middle; otherwise fullscreen
-- that keeps the bar (maximized)
function MaximizeWindow()
	local w = hl.get_active_window()
	if not w then return end
	if not w.floating then
		hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized" }))
		return
	end
	local _, _, aw = workArea(w.monitor or hl.get_active_monitor())
	local width = type(w.size) == "table" and (w.size.x or w.size[1]) or 0
	SnapWindow(width >= aw - 2 and "center" or "maximize")
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

-- title bars (hyprbars, AUR hyprland-plugin-hyprbars) — the floating mode's:
-- the title and close / maximize / minimize, a double click maximizes
local barsLib = "/usr/lib/libhyprbars.so"
local barsLoaded = false
for _, p in ipairs(hl.get_loaded_plugins() or {}) do
	if p.name == "hyprbars" then barsLoaded = true end
end
if not barsLoaded and io.open(barsLib, "r") then
	hl.plugin.load(barsLib)
	barsLoaded = true
end
if barsLoaded and hl.plugin.hyprbars then
	local colors = require("components.colors")
	hl.config({ plugin = { hyprbars = {
		enabled = saved == "floating",
		bar_height = 28,
		bar_color = colors.background0,
		["col.text"] = colors.foreground0,
		bar_text_font = "monospace",
		bar_text_size = 11,
		bar_text_align = "left",
		bar_padding = 12,
		bar_button_padding = 8,
		bar_precedence_over_border = true,
		bar_part_of_window = true,
		on_double_click = "hyprctl eval 'MaximizeWindow()'",
	} } })
	-- right to left: the first one stands at the edge
	local function button(icon, fg, action)
		hl.plugin.hyprbars.add_button({ bg_color = colors.background0, fg_color = fg, size = 16, icon = icon, action = action })
	end
	button("✕", colors.red, "hyprctl eval 'hl.dispatch(hl.dsp.window.close())'")
	button("□", colors.foreground0, "hyprctl eval 'MaximizeWindow()'")
	button("–", colors.foreground0, "hyprctl eval 'MinimizeWindow()'")
end

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

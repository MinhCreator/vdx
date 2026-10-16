-- Hyprland — window rules
-- windowrule: hl.window_rule({name=, match=, ...})
-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/

hl.window_rule({
	name = "portal-filechooser",
	match = { class = "^(xdg-desktop-portal-gtk)$" },
	float = true,
	center = true,
	size = "900 600",
})

-- the shell's own windows: how each opens is set in the Shell Manager › Shell
-- apps; scripts/shellapps.py writes the rules (at the first start too)
local ok, shellRules = pcall(dofile, os.getenv("HOME") .. "/.local/state/dotfiles/shell-apps.lua")
for _, rule in ipairs(ok and type(shellRules) == "table" and shellRules or {}) do
	hl.window_rule(rule)
end

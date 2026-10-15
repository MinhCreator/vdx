-- Hyprland — window rules
-- windowrule: hl.window_rule({name=, match=, ...})
-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/

hl.window_rule({
  name  = "portal-filechooser",
  match = { class = "^(xdg-desktop-portal-gtk)$" },
  float  = true,
  center = true,
  size   = "900 600",
})

-- Quickshell's own windows (shell/apps): how each one opens is set in the
-- Shell Manager › Shell apps (scripts/shellapps.py writes the rules to
-- ~/.local/state/dotfiles/shell-apps.lua and reloads). Without that file:
-- floating, centred, at the app's own size (the same values as shellapps.py).
local shellApps = {
  { name = "shell-manager", title = "Shell Manager", size = "820 600" },
  { name = "task-manager",  title = "Task Manager",  size = "780 600" },
  { name = "cleaner",       title = "Cleaner",       size = "760 620" },
}
local ok, chosen = pcall(dofile, os.getenv("HOME") .. "/.local/state/dotfiles/shell-apps.lua")
if not ok or type(chosen) ~= "table" then chosen = {} end

for _, app in ipairs(shellApps) do
  local rule = chosen[app.name] or { float = true, size = app.size, center = true }
  rule.name = app.name
  rule.match = { title = "^(" .. app.title .. ")$" }
  hl.window_rule(rule)
end

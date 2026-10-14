-- windowrule: hl.window_rule({name=, match=, ...})
-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/

hl.window_rule({
  name  = "portal-filechooser",
  match = { class = "^(xdg-desktop-portal-gtk)$" },
  float  = true,
  center = true,
  size   = "900 600",
})

-- Quickshell's Shell Manager window (taskbar/apps/shellmanager)
hl.window_rule({
  name  = "shell-manager",
  match = { title = "^(Shell Manager)$" },
  float  = true,
  center = true,
  size   = "820 600",
})

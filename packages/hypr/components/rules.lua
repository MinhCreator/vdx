-- windowrule: hl.window_rule({name=, match=, ...})
-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/

hl.window_rule({
  name  = "portal-filechooser",
  match = { class = "^(xdg-desktop-portal-gtk)$" },
  float  = true,
  center = true,
  size   = "900 600",
})

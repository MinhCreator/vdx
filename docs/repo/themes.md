# Themes

- One theme for the whole desktop; colours by role
  ([themes/gruvbox/README.md](../../themes/gruvbox/README.md)). A hex outside a theme
  is a bug (imported themes of btop may keep their own shades).
- A package holds the config; a theme only what depends on its colours. The
  colour files themselves (hypr `colors.lua`, kitty `colors.conf`, …) live in
  the themes alone, so a theme is always active. Two exceptions are gruvbox's
  own: `packages/tmux/colors.conf` and `packages/btop/themes/current.theme`
  are its colours and the source the other themes are recoloured from
  (`FROM_PACKAGES` in `themes/mktheme.py`).
- Switch: `./install.py theme set <name>` or the Shell Manager.

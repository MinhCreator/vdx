# gruvbox-material — one theme for the whole desktop

Source of truth: `quickshell/taskbar/config/Colors.qml`. Every program below
uses these values and roles; a new config takes its colours from here.

| Role | Hex | Used for |
|---|---|---|
| background0 | `#202020` | base surface: bar, popups, terminal, rofi, mako, lock screen, editor |
| background1 | `#32302f` | raised: hover, fields, active tab |
| background2 | `#3c3836` | tmux status cells |
| background3 | `#45403d` | selection fill, quiet frames, hairlines |
| foreground0 | `#d4be98` | text, block cursor |
| foreground1 | `#ddc7a1` | emphasised text |
| foreground2 | `#bdae93` | secondary text, active frames (focused window) |
| gray | `#7c6f64` | frames at rest (popups, notifications, rofi) |
| muted | `#928374` | hints, inactive labels |
| dim | `#665c54` | disabled |
| red | `#ea6962` | errors, critical, clipping |
| orange | `#e78a4e` | special mode (night light), pending action |
| yellow | `#d8a657` | accent: focus, prompt; warnings |
| green | `#a9b665` | ok, connected, on |
| aqua | `#89b482` | |
| blue | `#7daea3` | |
| purple | `#d3869b` | |

Rules (the bar's style):
- surfaces step up in tone (`background0 → 1 → 3`), no shadows-as-colour;
- frames: 1px inside the bar (`Theme.frameWidth`), 2px for windows, notifications and rofi; `gray` at rest, `foreground2` when active / focused;
- selection is a `background3` fill with bold text, not a colour;
- colour carries meaning only: green ok, yellow / orange attention, red error.

Where each program keeps it: hypr `components/colors.lua`, kitty `colors.conf`,
rofi `colors.rasi`, mako `config`, swaylock `config`, gtk `gtk.css`, elio
`theme.toml`, zed `themes/gruvbox-material.json`, tmux `tmux.conf` (package),
btop `gruvbox_material_dark` (package), nvim — gruvbox-material, transparent
over the terminal.

# Machine profile

`./install.py machine detect` reads `/sys` and `/proc` (GPUs, battery,
backlight, codecs, outputs, DMI) into `[hardware]` of `.machine.toml`.
Wrong values are fixed in `[override]`, which detect keeps. Code:
`installer/detect.py` (readers take a fake root for tests).

`[hypr]` holds this machine's Hyprland settings; `link` writes them to
`~/.config/hypr/machine/{gpu,input,monitors}.lua` (real files, marked as
generated — edit the profile, never them):

```toml
[hypr]
gpu_env = "none"                    # nvidia | none; default nvidia only without an iGPU
layouts = "us,ru"
layout_options = "grp:caps_toggle"
monitors = [{ output = "eDP-1", mode = "1920x1080@144.00", position = "0x0", scale = 1.2 }]
workspaces = { eDP-1 = "1-10" }     # the first of each range is the output's default
```

The repo's hypr config loads them through `components/machine.lua` and has a
default for each (every output at its preferred mode, `us`, no GPU env).
`hl.env` applies when Hyprland starts: a `gpu_env` change needs a new login
(`link` says so, `doctor` checks the running session).

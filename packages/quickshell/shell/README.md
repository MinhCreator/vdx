# shell

Quickshell config (`qs -c shell`): the bar, the shell's apps and the Shell
Manager. Code rules: [CLAUDE.md](CLAUDE.md).

## Overview

![The shell in 55 seconds](../../../docs/shell/shell-demo.webp)

Full quality: [shell-demo.mp4](../../../docs/shell/shell-demo.mp4).

![The bar](../../../docs/shell/bar.png)

<table>
  <tr>
    <td colspan="2"><img src="../../../docs/shell/sm-appearance.png" alt="Shell Manager, Appearance"><br><sub>Shell Manager › Appearance: theme, icons, wallpaper, font</sub></td>
  </tr>
  <tr>
    <td colspan="2"><img src="../../../docs/shell/sm-bar.png" alt="Shell Manager, Bar"><br><sub>Shell Manager › Bar: modules dragged between zones and the Folder</sub></td>
  </tr>
  <tr>
    <td><img src="../../../docs/shell/launcher.png" alt="Launcher"><br><sub>System menu (Super+R)</sub></td>
    <td><img src="../../../docs/shell/keybinds.png" alt="Keybinds"><br><sub>Keybinds (Super+B)</sub></td>
  </tr>
  <tr>
    <td><img src="../../../docs/shell/taskmanager.png" alt="Task manager"><br><sub>Task Manager (Super+D)</sub></td>
    <td><img src="../../../docs/shell/cleaner.png" alt="Cleaner"><br><sub>Cleaner (Super+X)</sub></td>
  </tr>
  <tr>
    <td><img src="../../../docs/shell/packages.png" alt="Packages"><br><sub>Packages</sub></td>
    <td><img src="../../../docs/shell/ai.png" alt="AI"><br><sub>AI: Claude Code limits, Ollama</sub></td>
  </tr>
  <tr>
    <td><img src="../../../docs/shell/audio.png" alt="Audio"><br><sub>Audio</sub></td>
    <td><img src="../../../docs/shell/battery.png" alt="Battery"><br><sub>Battery</sub></td>
  </tr>
  <tr>
    <td><img src="../../../docs/shell/brightness.png" alt="Brightness"><br><sub>Brightness</sub></td>
    <td><img src="../../../docs/shell/windows.png" alt="Windows"><br><sub>Window mode</sub></td>
  </tr>
  <tr>
    <td><img src="../../../docs/shell/music.png" alt="Music"><br><sub>Music</sub></td>
    <td><img src="../../../docs/shell/radio.png" alt="Radio"><br><sub>Radio</sub></td>
  </tr>
</table>

Media: `docs/shell/` in the repo root.

## Apps

Registry: `apps/apps.json` (the Shell Manager, the system menu,
`scripts/shellapps.py` and the window rules read it).

| App | Key | IPC |
|---|---|---|
| Shell Manager | Super+S | `shell toggle`, `shell open <page>[:<group or app>]` |
| Task Manager | Super+D | `taskmanager toggle` |
| Cleaner | Super+X | `cleaner toggle` |
| Capture | Super+Shift+S | `capture open\|stop\|close` |
| System menu | Super+R | `launcher toggle` |
| Packages | — | `packages toggle` |
| Display | — | `display toggle` |
| VirusTotal | — | `virustotal toggle` |
| Clipboard | — | `clipboard toggle` |
| Backups | — | `backup toggle\|open\|close` (bar module `backup`: last backup, Back up, the restore guide); the terminal: `backup status\|run\|snapshots\|restore\|guide …` (`scripts/backup.py`, restic) |
| Files | Super+E | `files toggle\|open\|close`, `files go\|reveal\|inspect\|select\|duplicates <path>`, `files choose <json>` (the portal's picker); F1 lists the keys; Ctrl+G list, grid, columns; Ctrl+T terminal here; F2 on several files renames them by a pattern |
| Keybinds | Super+B | `keybinds toggle\|open\|close` |
| Window switcher | Super+Tab (floating mode) | `switcher toggle\|open\|close` |
| Overview | — | `overview toggle` |
| Lock screen | Super+Z | `lock lock` (options: Shell Manager › Apps › Lock screen) |
| Taskbar | — | floating mode only |
| Root prompt | — | polkit agent; asks before every root action |

IPC: `qs -c shell ipc call <target> <function>`. Window mode:
`windowmode set tiling|floating|scrolling`.

## Modules

Bar modules live in `modules/<id>/`; each popup opens with
`qs -c shell ipc call <id> toggle` (except clipboard `clip`, taskmanager
`tasks`, cleaner `clean`, virustotal `scan`, packages `updates`). Order, zones and visibility: Shell Manager
› Bar. Options: Shell Manager › Modules (an app's module: a link to › Apps).

Workspaces, Music, Radio, Equalizer, Clock, Themes, Wallpapers, Brightness, Audio, Wi-Fi, Mihomo, Battery,
Language, AI, Shell, Notifications, Capture, Clipboard, System, Task Manager,
Cleaner, VirusTotal, Packages, Display, Windows, Chat, Folder.

## Controls

Shell Manager › Appearance › Controls: Outlined (framed controls, the
terminal look) or Material (filled controls, no frames or prompt arrows,
a quiet hairline round popups). The island keeps its frame either way.
## Accent

Shell Manager › Appearance › Accent: a switch (Off: monochrome). On: Fill (Solid or Gradient),
then the colours in one row: a colour field per stop (Gradient: From and To, with a swap between
them). A field takes a hex typed in (applied as you go; left invalid, it goes back to the last
valid colour), and its chip or chevron opens the picker under the row (palette dots, then Hue,
Saturation and Brightness sliders), for that stop only. Applies to: Switches, Sliders, Choices,
Workspaces, Dropdowns, Window border, all off until switched on. A gradient runs across fills
(switch, slider, window border); text and outlines take the first colour. Window border is
Hyprland's focused frame: `hypr/components/appearance.lua` reads
`~/.local/state/dotfiles/accent.lua`, written by `AccentService.qml`. The equalizer follows the
accent with its own switch (Modules › Equalizer › Follow accent). Wallpaper and cursor colours use
the same field and picker.

## Corners

Shell Manager › Appearance › Shape › Corners: Sharp, or Round with one radius on a
ticked slider. Everything follows — popups, controls, rows, the island,
Hyprland's windows, mako — and the icons switch to Material Symbols Rounded.

## Island

Solid and island keep their own icon size, gap, separators and hub opening (`ShellSettings.looks`).
Shell Manager › Bar › Look › Shape › Island: no strip — one pill at the top centre is
the whole bar (`bar/island/`). At rest: LEFT · clock · RIGHT (by default the
workspaces and the equalizer). The clock opens the hub on a hover or a click (Bar › Behaviour › Open the hub):
the date, the track and the HUB modules as chips; a chip opens its module's
popup inside the island, with a bubble beside it to the hub (the mouse's
back button too; Escape when it came from the hub). Shell Manager › Bar › Layout arranges LEFT, RIGHT, HUB
and HIDDEN; Bar › Monitor › Island clock, per monitor: off with nothing beside it, the
island hides there until it has something to show. Volume / brightness changes pass over it as a flash, but not
when made from the island itself (its chips, the open volume popup) or while the pointer rests on it; new
notifications pass over it too (mako only keeps them: its `island` mode). The track in the hub is the player (Bar › Behaviour › Show the player: off leaves the chips);
the equalizer has no clicks (its colour, Follow accent and Show when paused: Modules › Equalizer; a gradient runs left to right).
Right click on a chip: its options (the hub closes). Middle click: play / pause. The wheel belongs to the modules.

IPC: `qs -c shell ipc call island hub|media|power|collapse`.

## Child bars

Shell Manager › Bar › Layout: the empty framed bar on the preview (right of
the centre) adds a child bar — a small bar of the monitor's main bar, in its
row; one empty child bar at a time. Drag it on the preview to one of four
spots (either edge, either side of the centre); its corner cross (or a drop
off the preview) removes it. Its band under the preview takes modules like
the others. A module is in one bar only. In the island style each is
an island of its own: its modules' popups open inside it as in the island
(`bar/island/IslandChild.qml`); with no centre showing they meet in the
middle. Bar › Look › Module gap and Separators: the room between modules and
the "|" in it, in every bar. Bar › Layout › ADD › Separator: a custom "|",
dragged into a band (a click puts it at the end of RIGHT); its chip's cross removes it. Modules › Notifications › Unseen dot: the dot shows
while the notifications centre is tucked away — on the Folder in the strip, on
the island's resting pill when the centre is in the hub, never beside the bell
in the bar. Moving the centre sets the switch; the switch overrides until the next move. Modules › Notifications › Bell badge: the bell's own dot or count, off by default.

## Requirements

| What | Needs |
|---|---|
| Battery limit | `system/etc/tmpfiles.d/quickshell-power.conf` |
| Power profile | `system/etc/udev/rules.d/90-quickshell-power.rules` |
| Headset mic | `system/etc/tmpfiles.d/headset-mic.conf` |
| Root actions without a password for 5 min | `system/etc/polkit-1/rules.d/50-pkexec-keep.rules` |
| Ollama service switch | `system/etc/polkit-1/rules.d/50-ollama.rules` |
| AI limits | Claude Code login (`~/.claude/.credentials.json`) |
| File scans | `VIRUSTOTAL_API_KEY` (env or `~/.config/secrets/env`) |
| Music likes | Yandex Music token (`~/.config/scripts/yandex-music/token`) |
| Island wave | `cava` (without it the wave is made up) |
| Files: devices | `udisks2` (`udisksctl`), removable drives show in the sidebar |
| Files: file chooser and links | `python-gobject`, `xdg-desktop-portal` (portal backend: `scripts/files_portal.py`, config `packages/xdg-portal/`) |

System files: `./install.py system install`.

## Files you edit

| File | What |
|---|---|
| `modules/brightness/night_light.json` | night light presets and schedule |
| `modules/wifi/dns_providers.json` | DNS providers: `{label, servers}` |
| `~/.config/scripts/radio/stations.json` | radio stations: `"key": {name, url}` |

State: `~/.local/state/quickshell/by-shell/<id>/` (`settings.json`,
`modules.json`, `layout.json`, …) and `~/.local/state/dotfiles/`
(`window-mode`, `windows.json`, `shell-apps.json`).

# shell

Quickshell config (`qs -c shell`): the bar, the shell's apps and the Shell
Manager. Code rules: [CLAUDE.md](CLAUDE.md).

## Apps

Registry: `apps/apps.json` (the Shell Manager, the system menu,
`scripts/shellapps.py` and the window rules read it).

| App | Key | IPC |
|---|---|---|
| Shell Manager | Super+S | `shell toggle`, `shell open <page>[:<group or app>]`, `shell search <words>` (the sidebar's search) |
| Task Manager | Ctrl+Shift+Esc | `taskmanager toggle` |
| Cleaner | Super+X | `cleaner toggle` |
| Capture | Super+Shift+S · Super+P | `capture open\|stop\|close\|library\|shot <region\|window\|screen>`: the screens freeze as they are (popups, the island), a toolbar at the bottom picks what (R W S: region, window or popup, screen), as (Tab: shot, recording), the sound, the pointer (C), a Delay (Settings › Apps › Capture); again: cancel, or stop the recording. Super+P (`shot screen`): the focused screen at once. The bar module is a button for the same and shows a recording; `library` toggles the window of saved captures |
| System menu | Alt+Space | `launcher toggle` |
| Packages | — | `packages toggle` |
| Display | — | `display toggle` |
| VirusTotal | — | `virustotal toggle` |
| Clipboard | — | `clipboard toggle` |
| Music | — | `music toggle\|open\|close`, `music go <yandex\|files\|radio>` (the old likes, search, playlist open the Yandex tab; playing keeps the tab): the window is tabbed by source: Yandex Music (LIKES: Likes, Search; PLAYLISTS with New playlist), Files (the folders of `music.folders`: enter a folder, Up, a track plays the folder from it; ⋮ Play, Play next, Add to queue) and Radio (the stations); each tab only while its component is installed. The list is a table in a raised box, the player at the foot of every tab. Bar module `music`: the track that plays (any source), its popup has a switch (the music service on or off), Now playing (a select of the players when several run), Queue (MPD's) and Library (tiles: the likes, the folders, the favourite stations). Radio: a star marks a favourite station. Options: Shell Manager › Music (one page: Shows, Max length, Time left, Players shown, Opens on, Close when a track plays, the folders) |
| Backups | — | `backup toggle\|open\|close` (bar module `backup`: last backup, Back up, the restore guide); the terminal: `backup status\|run\|snapshots\|restore\|guide …` (`scripts/backup.py`, restic) |
| Files | Super+E | `files toggle\|open\|close`, `files go\|reveal\|inspect\|duplicates <path>`, `files choose <json>` (the portal's picker; a setting's Choose… opens the same picker); F1 lists the keys; Ctrl+G list, grid, columns; Ctrl+T terminal here; F2 on several files renames them by a pattern; the sidebar's "This computer" shows the storage (used / free, unmounted drives mount on a click); the sidebar is in sections: PLACES (drag to reorder within it; right click to hide, Settings › SIDEBAR), PINNED (your folders; drag to reorder; right click › Unpin; a folder's right click › Pin to sidebar), USB (plugged-in removable drives, mounted or not, with a mount / eject button at the row's end), DEVICES (other drives mounted for you); Recent (recently-used.xbel) and Starred (Ctrl+S) in the sidebar; the list shows folders as tiles above a table of files (checkboxes, ⋮ menu, Type / Size / Modified columns), the path as crumbs (Ctrl+L types one); typing a letter jumps to a name; the look and columns in Settings › Apps › Files |
| Keybinds | Super+B | `keybinds toggle\|open\|close` |
| Window switcher | Super+Tab (floating mode) | `switcher toggle\|open\|close` |
| Overview | — | `overview toggle` |
| Lock screen | Super+Z | `lock lock` (options: Shell Manager › Lock screen) |
| Taskbar | — | floating mode only |
| Root prompt | — | polkit agent; asks before every root action |

IPC: `qs -c shell ipc call <target> <function>`. Window mode:
`windowmode set tiling|floating|scrolling`.

After a crash Quickshell itself usually starts the shell again in the same
process and opens its crash report window. When the process ends instead
(killed by the OOM killer, a crash right after start), `scripts/supervise.sh`,
which Hyprland starts the shell through, starts it again in a second (five
in a minute: it stops with a toast); a kill or Restart (About, the system
menu) is not a crash. Locked when it crashed, the new one locks again. No bar and no way to a terminal: switch to
a tty (Ctrl+Alt+F2), log in, then
`HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/$UID/hypr | tail -1) hyprctl eval 'hl.exec_cmd("~/.config/quickshell/shell/scripts/supervise.sh")'`.

## Modules

Bar modules live in `modules/<id>/`; each popup opens with
`qs -c shell ipc call <id> toggle` (except clipboard `clip`, taskmanager
`tasks`, cleaner `clean`, virustotal `scan`, packages `updates`). Order, zones and visibility: Shell Manager
› Bar. Options: Shell Manager › Bar modules (an app's module too; Notifications: its own page).
Every page has Reset in its header; About › Settings exports every option to one file, imports it
(the shell restarts) and resets everything (the old set kept as `settings-before-reset.json`).
A new layout (and Bar › Layout › Reset) shows workspaces, the clock, audio, Wi-Fi,
Bluetooth, battery, notifications, Shell and the Folder; the rest start in the Folder
(`BarLayout.defaultBar`), one drag from the bar. In the strip, modules of LEFT / RIGHT
that don't fit beside the centre fold into the Folder, nearest the centre first, and
come back when there is room (not saved; no Folder on the bar, no folding).

Workspaces, Music, Equalizer, Clock, Themes, Wallpapers, Brightness, Audio, Wi-Fi, Bluetooth, Mihomo, Battery,
Language, AI, Shell, Notifications, Capture, Clipboard, System, Task Manager,
Cleaner, Backups, VirusTotal, Packages, Display, Windows, Chat, Folder.

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
`~/.local/state/dotfiles/accent.lua`, written by `AccentService.qml`. APPLIES TO › Bar modules
paints the active state of every bar module with the accent (off: each module's own colour, and
its colour options show a note instead). The wallpaper's custom colour is the same field and picker, with the
same palette dots (Appearance › Wallpaper › Colour); the cursor's is a plain colour row.

## Corners

Shell Manager › Appearance › Shape › Corners: Sharp, or Round with one radius on a
ticked slider. Everything follows — popups, controls, rows, the island,
Hyprland's windows, mako — and the icons switch to Material Symbols Rounded.

## Island

Solid and island keep their own icon size, gap, separators and hub opening (`ShellSettings.looks`).
Shell Manager › Bar › Look › Shape › Island: no strip — one pill at the top centre is
the whole bar (`bar/island/`). At rest: LEFT · clock · RIGHT (by default the
workspaces and the equalizer). The clock opens the hub on a hover or a click (Bar › Behaviour › Open the hub):
the date, the track, the Launcher and Keys chips (they open the launcher and the keybinds inside the island: a Launcher / Keys view, Escape goes back to the hub when it came from there, a click outside closes) and the HUB modules as chips; a chip opens its module's
popup inside the island, with a bubble beside it to the hub (the mouse's
back button too; Escape when it came from the hub). Shell Manager › Bar › Layout arranges LEFT, RIGHT, HUB
and HIDDEN; Bar › Monitor › Island clock, per monitor: off with nothing beside it, the
island hides there until it has something to show. Volume / brightness changes pass over it as a flash, but not
when made from the island itself (its chips, the open volume popup) or while the pointer rests on it; new
notifications pass over it too (mako only keeps them: its `island` mode); a click on one focuses its app's window, else opens the centre. A new OSD or the end of the flash clears them from the island (the centre keeps them). Modules › Notifications › Toasts › Toast duration sets how long (Until dismissed: critical always stays so); the centre opening closes them. The track in the hub is the player (Bar › Behaviour › Show the player: off leaves the chips);
the equalizer has no clicks (its colour and Show when paused: Bar modules › Equalizer;
a gradient runs left to right).
Right click on a chip: its options (the hub closes). Middle click: play / pause. The wheel belongs to the modules.

IPC: `qs -c shell ipc call island hub|media|power|launcher|keybinds|collapse`.

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
the "|" in it, in every bar. The Folder is never off the bar: a saved
"folder" in HIDDEN is ignored. Bar › Layout › ADD › Separator: a custom "|",
dragged into a band (a click puts it at the end of RIGHT); its chip's cross removes it.
Notifications › BELL › Bell badge: the bell's own dot or count, off by default.
Notifications › UNSEEN DOT › Show the dot: the dot shows while the notifications
centre is tucked away — on the Folder in the strip, on the island's resting pill
when the centre is in the hub, never beside the bell. Moving the centre sets the
switch; the switch overrides until the next move. Dot colour shows with it.

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
| Files: devices | `udisks2` (`udisksctl`): the sidebar's USB and DEVICES sections (`files.py devices`, `removable` tells them apart); `findmnt` for "This computer" |
| Music | MPRIS players (Spotify, a browser, mpv: each needs its MPRIS support, e.g. `mpv-mpris` for mpv); Yandex Music, the local folders (`~/Music`, Shell Manager › Music) and the radio come through MPD (components `yandex-music`, `mpd`, `radio`) |
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

# Shell architecture

How the shell is built and where its responsibilities end. Code rules:
[packages/quickshell/shell/CLAUDE.md](../packages/quickshell/shell/CLAUDE.md);
repo and installer: [CONVENTIONS.md](../CONVENTIONS.md); what exists for a
user: [shell/README.md](../packages/quickshell/shell/README.md). Decisions:
[decisions/](decisions/README.md). Paths below are under
`packages/quickshell/shell/` unless they start with the repo root.

Status: written from the audit of 2026-10-19
([00_REPOSITORY_AUDIT.md](implementation-plans/00_REPOSITORY_AUDIT.md)).
Parts marked *not inspected* are names and roles only.

## Runtime

```
Hyprland ── autostart.lua (hyprland.start)
   ├─ awww-daemon            wallpaper surface (`--no-cache`: starts empty; the shell sets the picture)
   ├─ shellapps.py ensure    window rules for the shell's apps (repo hypr config)
   ├─ supervise.sh           runs settings_migrate.py, then qs; starts it again when it ends by a crash (not a kill);
   │                         most crashes Quickshell restarts in place itself (crash report window)
   │   └─ qs -c shell        ONE process: bars, island, popups, apps, lock, polkit agent
   ├─ mako                   the notification server (toasts in Solid style, history)
   ├─ cursors.py restore
   └─ display.py restore     monitor scales/positions saved by the Display app
```

Everything in the shell is one Quickshell process: a QML error in a shared
file can drop the whole bar; a crash also takes the lock screen
(`WlSessionLock`; Hyprland keeps the session locked, `allow_session_lock_restore`)
until the supervisor's new `qs` locks again (marker in
`$XDG_RUNTIME_DIR/shell-lock/locked`, this session's signature).

## Layers inside the shell

| Layer | Where | Owns | Must not |
|---|---|---|---|
| Backend scripts | `scripts/*.sh\|py` (`backend.py`) | every system call; one JSON object per command | hold UI state |
| Services | `modules/<id>/<Name>Service.qml`, `apps/<id>/<Name>Service.qml` (singletons) | state, `Process` / `Timer`, actions | draw |
| Faces & popups | `modules/<id>/<Name>.qml`, `<Name>Popup.qml` | look; call service functions | talk to the system |
| Apps | `apps/<id>/`, registry `apps/apps.json` | own windows or overlays, IPC targets | — |
| Bar | `bar/` (`Bar`, `BarLayout`, `BarPopup`, `ModuleFaces`), `bar/island/` | zones, child bars, island views, popup hosting | module logic |
| Kit | `kit/` (`Kit*.qml`, icons, `reply.js`, `markup.js`) | shared controls and parsing | feature logic |
| Config | `config/` (`Theme`, `Colors`, `Motion`, `Format`, `Paths`, `ShellSettings`, `ModuleSettings`) | tokens and settings stores | — |
| Components | `components/` (`Hypr`, `PopupManager`, `PopupCatcher`, `ScrimWindow`, …) | Hyprland helpers, popup arbitration | — |

## Themes

`themes/gruvbox/` is the source; `themes/mktheme.py <name>` generates every
other theme (never edited by hand). A theme holds the colour files of each
package (`hypr` colours, `kitty`, `mako/config`, `quickshell` colours …),
linked over the package files by `./install.py link`; `.theme` names the
active one. The shell reads colours through `config/Colors.qml` → `Theme`.
Runtime-written theme-ish state goes to `~/.local/state/dotfiles/`
(`accent.lua`, read by `hypr/components/appearance.lua`). mako modes
(`island`, `round`) are switched by the shell with `makoctl mode`.

## Install flow

`./install.py setup`: preflight → plan → steps (packages, AUR, submodules,
links, secrets, `/etc`, units, services). `link` also writes
`~/.local/state/dotfiles/components.json` (modules not installed) and
`hypr/machine/*.lua`. `doctor` checks the machine. Details: CONVENTIONS.md.

*Not inspected (lifecycle):* restart behaviour of every `Process` beyond
`NotificationsService.monitorProc` (restarts after 2 s) and the wallpaper wait loop (25 × 0.4 s).

## Settings and state

| Store | File (`~/.local/state/quickshell/by-shell/<id>/`) | API | Notes |
|---|---|---|---|
| Shell options | `settings.json` | `ShellSettings` property + `set()` | 36 keys; `version` (schema, below) |
| Module / app options | `modules.json` › `values.<id>` | `ModuleSettings.get(id, key, default)` / `set` | default lives in the module; written on each change, external edits reloaded |
| Bar layout | `layout.json` | `BarLayout` | renames via `BarLayout.renamed` (live fallback); not watched |
| Notifications history | `notifications.json` (statePath) | `NotificationsService` | — |
| Schema | `version` in the three files above | `scripts/settings_migrate.py` (`VERSION`, `MIGRATIONS`), run by `supervise.sh` before qs | a file is written only when changed, old one as `.bak`; `tests/test_settings_migrate.py` |
| Dotfiles state | `~/.local/state/dotfiles/` | installer + shell | `components.json` (modules not installed), `accent.lua`, `window-mode`, `shell-apps.json` |

Settings UI = **Shell Manager** (`apps/shellmanager/`, Super+S). Pages:
Appearance, Animations · Bar, Bar modules, Windows, Lock screen, Notifications · Network, Bluetooth · Apps, About (decision 0002).
An app's or module's options are its `<Name>Settings.qml`, shown under Apps
or Bar modules (Lock screen, Notifications: own pages). Applied at once (pickers with preview: Apply; fields: Enter).

## Feature map

| Feature | Code | Depends on | Notes |
|---|---|---|---|
| Notifications | `modules/notifications/`, `scripts/notifications.sh`, `bar/island/IslandNotice.qml`, `IslandService` › notice | mako (server), `dbus-monitor`, `makoctl` | Solid: mako toasts; Island: island toasts, mako `island` mode invisible |
| Wallpaper | `apps/shellmanager/Wallpaper.qml` (in `shell.qml`), `WallpaperService.qml` | `awww`, `wallpapers/` in the repo | modes theme / custom / image (`ShellSettings.wallpaperMode`) |
| Displays | `apps/display/`, `scripts/display.py` | `hyprctl` | restore at login |
| Audio | `modules/audio/`, `scripts/audio.sh` | Quickshell Pipewire, `pactl` (ports) | one list entry per port |
| Bluetooth | `modules/bluetooth/`, `apps/shellmanager/BluetoothPage.qml`, `scripts/bluetooth.sh` | BlueZ | — |
| Files + picker | `apps/files/`, `scripts/files.py`, `scripts/files_portal.py`, `packages/xdg-portal/` | `xdg-desktop-portal`, `python-gobject`, `udisks2` | the shell's FileChooser portal and `FileManager1` |
| Lock | `apps/lock/` | Quickshell `WlSessionLock`, PAM | options in `modules.json` › `lock` |
| Island / hub | `bar/island/` | `ShellSettings.barStyle` | hub = island view from the clock; media merges MPD + MPRIS |
| Music (Yandex) | `modules/music/`, `modules/mpd/`, `scripts/music.sh`, `scripts/yandex_likes.py` | component `yandex-music` (+ `mpd`, submodule) | `MusicService` is imported by the island and `AudioPause` |
| Radio | `modules/radio/` | component `radio` (+ `mpd`) | shares `MpdService` |
| Capture | `apps/capture/`, `modules/capture/` | `grim`, `gpu-screen-recorder`, `wl-copy`, `notify-send` | the only "camera" in the repo: screen capture |
| Launcher, Keybinds | `apps/launcher/`, `apps/keybinds/` | Hyprland binds | no island entry |

*Not inspected:* Task Manager, Cleaner, Packages, Backups, VirusTotal,
Clipboard, Windows, Sysmon, Wi-Fi, Mihomo, AI, Chat, Overview, Switcher, Taskbar.

## Optional parts

`components.toml` decides what is installed; a bar module whose components
are all off is "not installed" (hidden from bars, greyed in Shell Manager,
`installer/shell.py` → `components.json`). QML files of every module are
linked with `quickshell` regardless — a service of an absent integration
still loads, so it must tolerate missing binaries.

## Boundaries (current rules)

- Only scripts touch the system; services never shell out with untrusted text.
- Colours only through `Theme.*`; tokens per `docs/SHELL_DESIGN_SYSTEM.md`.
- Repo-linked files (theme configs) are never written at runtime; runtime state
  goes to the state dirs.
- `/etc` only via `system/` and `./install.py system install`.

## Update rule

A phase that changes a flow or a boundary above updates this file in the same
commit; a new boundary or store gets a decision record first.

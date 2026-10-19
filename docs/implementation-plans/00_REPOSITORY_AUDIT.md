# 00 — Repository audit (2026-10-19)

Status: **done** (planning pass, no code changed). Snapshot of `main` at
`d855ef6`; the living map is [SHELL_ARCHITECTURE.md](../SHELL_ARCHITECTURE.md).
Source of requirements: `CLAUDE_SHELL_PROJECT_MASTER_INSTRUCTIONS.md` (repo
root, untracked; "the spec" below, sections as §N).

## What was inspected

Read in full or in the relevant part:

- `CLAUDE.md`, `CONVENTIONS.md`, `packages/quickshell/shell/{CLAUDE,README}.md`,
  `components.toml` (all entries), `installer/check.py` (groups, syntax tools),
  `packages/hypr/components/autostart.lua`, `themes/gruvbox/mako/config`.
- Notifications: `modules/notifications/NotificationsService.qml`,
  `scripts/notifications.sh`, `bar/island/IslandNotice.qml`,
  `bar/island/IslandService.qml` (notice + media parts), `bar/island/Island.qml` (flash timers).
- Files: `apps/files/FilesService.qml` (show, listing, run, poll, picker entry).
- Audio: `modules/audio/AudioService.qml` (device lists), `scripts/audio.sh`,
  `system/etc/tmpfiles.d/headset-mic.conf`; live `pactl list sources`.
- Wallpaper: `apps/shellmanager/{Wallpaper,WallpaperService}.qml`,
  `config/ShellSettings.qml` (wallpaper keys); live `~/.cache/awww/0.12.1/`.
- Bluetooth: grep of `Scan` in `modules/bluetooth/`, `apps/shellmanager/BluetoothPage.qml`.
- Lock: option keys in `apps/lock/*.qml`, lock mechanism (WlSessionLock + PAM).
- Music: `modules/music/MusicService.qml` header, `scripts/music.sh` header,
  MPRIS / MPD users (grep).
- Capture: grep of camera/v4l in the whole repo; `apps/capture/CaptureService.qml` notify calls.
- Shell Manager: page list in `apps/shellmanager/ShellManager.qml`; file sizes.
- Apps registry `apps/apps.json`; file listing of every shell directory.
- Memory notes of earlier sessions (outside the repo) for context only; facts were re-checked in code.

Not inspected (unknown until the phase that needs it): the bodies of most
popups and Shell Manager pages, `BarLayout.qml` beyond renames, `Bar.qml`,
`BarPopup.qml`, `PopupManager.qml`, `DisplayService.qml` / `display.py`
internals, `CaptureService` recording flow, `LockScreen.qml` layout code,
the submodules (`packages/scripts/yandex-music`, `radio`, `vpn`, `packages/nvim`),
`private/`.

## Tooling (verified 2026-10-19 on this machine)

| Command | Result |
|---|---|
| `./install.py check` | all 8 groups ✓ (links, syntax, themes, components, tests, hypr, shell, repo) |
| `ruff check` | All checks passed |
| `shellcheck -S warning` on tracked `*.sh` (no nvim) | exit 0 |
| `qmllint` | at `/usr/lib/qt6/bin/qmllint` (not on PATH; `check syntax` finds it) — syntax errors only |

Versions: Quickshell 0.3.2, Hyprland 0.56.2, awww 0.12.1. Present: `qs`, `jq`,
`makoctl`, `awww`, `grim`, `podman` (for `tests/fresh-machine.sh`, not run in this pass).

There are **no QML behaviour tests**. Automated coverage is: Python backends
(`tests/test_files.py`, `test_display.py`, `test_backup.py`), the installer,
`check shell` (icons, module registration, rounded twins), qmllint syntax,
`check hypr` (`Hyprland --verify-config`). Shell behaviour is verified by hand:
`qs log -c shell`, IPC calls, `grim` screenshots.

## Findings per spec item

Evidence level: **confirmed** (code + live state agree), **from code** (read,
not reproduced), **hypothesis** (needs reproduction).

### §5.1 Notifications — two toast surfaces, no own server

- mako is the notification server. In bar style **Solid**, mako draws toasts
  (`default-timeout=5000`, `ignore-timeout=1`, theme file
  `themes/<t>/mako/config`, generated from gruvbox by `themes/mktheme.py`).
  In style **Island**, mako mode `island` sets `invisible=1` and the island
  draws toasts (`IslandService.notices`, `noticeMs: 5000`).
- `NotificationsService` builds the shell's history by watching `Notify` on
  D-Bus (`dbus-monitor`), then 300 ms later reading `makoctl list` + `history`.
  History items have no mako actions; `focusApp(item)` matches a Hyprland
  window by a normalised class.
- **A (reappearing) — from code, strong:** `Island.qml` `flashTimer` ends the
  flash (`flash = ""`) but never clears `IslandService.notices`; only
  `dismissNotice` removes rows. The next notification does
  `notices = fresh.concat(root.notices)`, so ignored ones show again.
  Island style only; mako toasts in Solid were not examined for this.
- **B (wrong target) — from code:** `IslandNotice.qml` click =
  `dismissed(); IslandService.openNotifications()` — every click opens the centre.
  The popup already has `focusApp`; mako's default action (`makoctl invoke`) is unused.
- **D:** two durations exist (mako config, `noticeMs`), neither is a setting.
  The mako file is theme-generated and linked from the repo: the shell must not
  rewrite it at runtime.
- **E:** `CaptureService.qml` calls `notify-send -a Capture` (lines ~195, 210,
  258, 331): screenshot copied/saved, errors, recording saved.

### §5.2 Filepicker stale files — hypothesis

The picker is the Files window (`files choose` from `scripts/files_portal.py`,
`FilesService.pick`). `show()` displays the cached `listing[path]` and calls
`refresh()`; a 1 s poll runs while `active` (window visible) and not searching.
The last change to `FilesService.qml` is 2026-10-18 (`d14e745` "the folder
reloads itself"); the bug may predate it. Candidates to check: reopen at the
same path (`open()` does nothing when `path !== ""`), `run()` queueing
(`proc.next` keeps one pending request), the poll paused by `searching`, and
the GTK/portal path vs the shell's own `Choose…`. First step: reproduce on
current `main`.

### §5.3 Duplicate microphone — hypothesis, mechanism from code

Live: one source `alsa_input.pci-0000_00_1f.3.analog-stereo` with ports
`analog-input-internal-mic` and `analog-input-mic` (both "availability
unknown"; the second is the quirk-made jack mic, `headset-mic.conf`, no
presence detect). `AudioService.entriesOf` lists a port when it is the
**active** one, or internal, or available-and-not-an-unknown-mic. So the jack
mic is listed exactly while it is the active port; choosing Internal makes it
inactive and it vanishes — matches the report. Open: who selects
`analog-input-mic` (WirePlumber restore at login, port priority, a headset
plug). The list model mixes "ports of a card" with "devices".

### §5.4 / §5.5 Wallpaper — confirmed root cause

`Wallpaper.qml` sets the background with `awww img` or `awww clear <hex>`.
`~/.cache/awww/0.12.1/<output>` holds the **last image** only
(`…/wallpapers/gruvbox/stripes.jpg` for all three outputs); `clear` does not
update it. Two paths bring that image back:

- `scripts/display.py:133-134` runs `awww restore` after every monitor apply
  ("draws the picture at the new scale") — every Display change, and
  `display.py restore` at login (`autostart.lua`). This is the §5.4 cause.
- `awww-daemon` (started first in `autostart.lua`, no `--no-cache`) looks up
  the cache when it starts (§5.5), before the shell applies its colour
  (`apply()` waits for `awww query`).

One cause (a cache that only knows images, restored outside the shell's
source of truth); one task (03). Found by the independent review; first
draft blamed only the daemon.

### §5.6 Bluetooth label

`"Scan"` is a button in `modules/bluetooth/BluetoothOverview.qml:188` and
`apps/shellmanager/BluetoothPage.qml:194`; hint texts mention "Scan" at
`BluetoothOverview.qml:59`, `BluetoothPage.qml:204`. No localisation layer exists.

### §6 Settings = Shell Manager

`apps/shellmanager/` (42 files, ~5.9k lines). Pages: Appearance, Animations ·
Bar, Windows · Network, Bluetooth · Apps, Modules · About. Storage:
`ShellSettings` (`settings.json`, ~75 properties), `ModuleSettings`
(`modules.json`, under `values`), `BarLayout` (`layout.json`). Per-app/module
`<Name>Settings.qml` pages. No search. Migration exists only as
`BarLayout.renamed`; there is no settings schema version. The shell writes
`modules.json` on exit (external edits while it runs are lost).

### §7 Lock screen

`apps/lock/` — `WlSessionLock` + `PamContext` inside the shell process. Options
(`modules.json` › `lock`): `background` (solid | wallpaper | blur), `blur`,
`screen`, `clock`, `date`, `user`, `power`, `layout`, `hideCursor`,
`cursorDelay`. Settings live under Shell Manager › Apps › Lock screen.
Hyprland has `misc.allow_session_lock_restore = true`.

### §8 File manager

`apps/files/` (12 files). Has sidebar with places, bookmarks, udisks2 devices,
device free space in properties, optional section frames (`frames` setting).
No home/storage page.

### §9 Bar / Island

Bar styles Solid and Island (`ShellSettings.barStyle`, `bar/island/`). The
"hub" is a view of the island opened from the clock; module popups open inside
the island; child bars exist. Launcher (`launcher toggle`) and Keybinds
(`keybinds toggle`) are separate apps with Hyprland binds; no island entry.

### §10 Music

- Yandex Music is already a component: `yandex-music` (default off, requires
  `mpd`, submodule `packages/scripts/yandex-music`, module `music`, secret).
  A module whose components are off is hidden ("not installed").
- Coupling left: `bar/island/IslandService.qml` and `modules/audio/AudioPause.qml`
  import `MusicService` / `MpdService` unconditionally; island media prefers MPD,
  falls back to MPRIS (`Quickshell.Services.Mpris`). `scripts/yandex_likes.py`
  ships with the quickshell component. `mpd.conf` music dir is `~/Music/yandex`.
- The bar module id `music` is Yandex-specific; Radio is separate on the same MPD.

### §11 "Camera" = Capture

No webcam / V4L code anywhere in the repo. The "camera" app/module is
**Capture**: app `apps/capture/` (overlay, recording, library window, IPC
`capture` and `captures`), bar module `modules/capture/` (camera icon). The
spec's camera phase is read as the Capture architecture; owner to confirm (D-11).

### §12 Torrent client

Nothing exists. No engine dependency in `components.toml`.

### §13–14 Docs and process

Existing authoritative docs: `CONVENTIONS.md` (repo, commits, installer),
`packages/quickshell/shell/CLAUDE.md` (shell code + UI rules — the de facto
guidelines and design system), `shell/README.md` (what exists),
`themes/gruvbox/README.md` (colour roles), `docs/POWER_MANAGEMENT.md`.
No roadmap, ADRs or task files in the repo before this pass. Rules there
are imperative but not marked MUST/SHOULD/MAY.

## Debt seen in passing (not in the spec, not scheduled)

Fixed delays the spec's §2.2 warns about: `NotificationsService.refreshDelay`
300 ms, `Wallpaper.qml` 25 × 0.4 s wait loop and `addedTimer` 500 ms.
`ThemesPopup` / `WallpapersPopup` share ~250 lines (known, left on purpose).
Listed for task 12 (UX audit) to rank, not to fix ad hoc.

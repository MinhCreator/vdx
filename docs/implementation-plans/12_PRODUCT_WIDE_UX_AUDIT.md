# 12 — Product-wide UX and customisation audit

Status: findings approved ("go to code", 2026-10-19); slice 1 implemented and verified · Category: C (findings only; fixes are new tasks) ·
Depends on: 00; best after 01–04 (so known bugs are not re-reported) ·
Gate: the ranked findings are approved before any of them is implemented. Spec: §13, §4.2–4.3.

Runs **before** 05 (its findings feed the Settings redesign), although the
spec lists it later in §13 — see the roadmap's order note.

## Objective

A candid, ranked list of what makes the shell hard for someone who is not its
author, with evidence, and proposed fixes for approval.

## Scope

In: install and first run (`./install.py install`, wizard), Shell Manager
discoverability, customisation breadth and conflicts, screen sizes / scaling /
multi-monitor, missing hardware and services, keyboard navigation and
accessibility, performance (idle CPU / memory of `qs`), error recovery,
settings reset and migration, optional integrations (Yandex Music, VPN, AI,
VirusTotal off), docs and extension points.
Out: implementing fixes; visual redesign proposals beyond a sentence each (05/08 own those).

## Read first

`docs/SHELL_ARCHITECTURE.md`, `00_REPOSITORY_AUDIT.md`, `shell/README.md`,
`shell/CLAUDE.md` › UI and Settings, `CONVENTIONS.md` › wizard/setup,
`installer/wizard.py`, Shell Manager pages list (`apps/shellmanager/ShellManager.qml`).

## Method

1. Inventory first-run path: `tests/fresh-machine.sh defaults` result + wizard screens (read code; run if the owner agrees — ~840 MB download).
2. Combination matrix (at least): bar style × monitors (1, 2, different scales);
   theme colour vs custom vs image wallpaper × multi-monitor; accent on/off × corners;
   island with open module + notification + OSD; audio with no device / BT only;
   each optional component off; runtime change of each Shell Manager page's options; reset to defaults (does a reset exist?).
3. Keyboard: can every app/popup be used without a mouse (Tab, Esc, Enter)? Focus visible?
4. Performance: `ps -o rss,pcpu -C qs` idle and with popups; polling timers inventory (`grep -rn 'interval:'`).
5. External references only where a finding needs one (GNOME HIG, KDE HIG,
   Apple HIG, Material, Fluent, WCAG 2.2 for contrast/focus; Noctalia Shell for Linux-shell parity). Record each source used.

## Output

`docs/implementation-plans/12_PRODUCT_WIDE_UX_AUDIT.md` › Findings (this
file): a table — id, finding, evidence (path / steps / screenshot by owner),
user impact, severity (S1 blocker … S4 polish), effort (S/M/L), risk,
dependencies, recommendation, proposed task (existing plan or new).

## Acceptance

Every area in Scope has at least a checked line (finding or "no issue, how
checked"); every finding has evidence; nothing marked good without a check; sources listed.

## Agents

May use one read-only review agent for a second opinion on the ranking, only if the owner asks.

## Forbidden

Code changes; editing other plans except to link a finding.

## Report

Research format (README). Top 10 findings in the chat; the full table here.

## Findings

Run 2026-10-19 on `implementation` at `3ab192b`. Machine: one monitor, eDP-1
1920×1080 @ 1.2 (1600 px logical), bar style Island, round corners, Material,
all components on (`components.json` › `off` empty). Paths under
`packages/quickshell/shell/` unless they start at the repo root.

Evidence level: **live** (measured or seen on this machine), **code** (read,
not reproduced), **hypothesis** (needs a check). Severity S1 blocker … S4
polish; effort S/M/L. No code was changed.

### Ranked findings

| ID | Finding | Evidence | User impact | Sev | Effort | Risk | Depends on | Recommendation | Task |
|---|---|---|---|---|---|---|---|---|---|
| U-01 | A fresh bar shows **every** installed module: ~20 in RIGHT on a default install; the real bar has no overflow | code: `bar/BarLayout.qml:293-305` `normalize` puts every known module in its zone, `state.hidden` starts `[]`; `bar/Bar.qml:199-218` three unconstrained `Row`s, centre `anchors.centerIn` — nothing clips or folds. `components.toml` › `quickshell` brings 23 modules. Only the Shell Manager preview has `+N` (`BarPage.qml` comment ~312). Not seen: the owner's layout is customised and in Island style | the first thing a new user sees: a crowded strip whose RIGHT zone likely runs over the clock and LEFT on ≤ 1600 px | S1 | M | low (defaults only; saved layouts untouched) | — | a short default set (workspaces · clock · audio, wifi, bluetooth, battery, notifications, shell, folder; the rest in the Folder); a real-bar overflow into the Folder or `+N`. Owner screenshot of a fresh state first | new 12-A (B) |
| U-02 | *(Half wrong — Quickshell restarts most crashes in place itself; see 12-B result.)* No supervisor for `qs`: a crash or a QML error in a shared file leaves no bar and a dead lock screen; the only "Restart shell" lives inside `qs` | code: `packages/hypr/components/autostart.lua:14` `exec_cmd("qs -c shell")` once; `apps/launcher/LauncherService.qml:101`; `docs/SHELL_ARCHITECTURE.md:26-28`. No recovery note in README / CONVENTIONS / shell README (grep `crash\|recover\|lockdead`) | a stranger without a bar has no visible way back short of a terminal they may not have bound; locked → tty + `hyprctl` | S2 | S | medium: exactly one instance is a rule (`shell/CLAUDE.md` › Work) | — | a restart loop or a systemd user unit (`Restart=on-failure`, no restart on clean exit) + a recovery paragraph in the shell README | new 12-B (B, owner approval: process model) |
| U-03 | Regression of task 03: `Wallpaper.qml` uses `DisplayService` without `import qs.apps.display` — the re-apply after a Display change never runs | live: `qs log -c shell` → `Wallpaper.qml[37]: ReferenceError: DisplayService is not defined` and `Detected function "onApplied" … no signal`; code: imports at `apps/shellmanager/Wallpaper.qml:1-5`, signal at `apps/display/DisplayService.qml:26` | the 03 fix rests on `--no-cache` + no `awww restore` alone; the hook it adds is dead and a WARN is in every log (03 acceptance: no new WARN) | S2 | S | low | 03 | add the import; re-check 03's Display acceptance | 03 follow-up (A) |
| U-04 | Island toasts are lost: a **critical** one is wiped by any OSD (volume / brightness key); a toast that comes while a module popup or the power view is open never shows | code: `bar/island/Island.qml:34-35` (`shown` keeps `module` / `power` over a flash), `:357-361` (timer end clears notices), `:377` (an OSD calls `clearNotices`), `IslandService.qml:121-123,129-132` (critical = no timer, but `clearNotices` drops all). README line 127 says critical "always stays" | a low-battery or auth warning disappears on a volume press; notices while a popup is open are only in the centre | S2 | S | low | 01 C/D | keep critical rows through an OSD; queue the flash until the open view closes (or show the unseen dot) | 01 follow-up (A) |
| U-05 | Keyboard and assistive tech: settings and popups are mouse-only | code: whole shell — `activeFocusOnTab` 1, `KeyNavigation` 0, `Accessible.*` 0; focus visuals only in `kit/KitInput.qml`, `kit/KitColourField.qml`; `KitSwitch`/`KitButton` are bare `MouseArea`s. Escape is handled widely (BarPopup, windows, island). Hypothesis: a popup opened by a key gets the keyboard only after a click (`bar/Bar.qml:102` `OnDemand`) | no Tab / Enter / Space anywhere in Shell Manager or popups; no screen reader names (WCAG 2.2 SC 2.1.1, 2.4.7, 4.1.2) | S2 | L | medium: every Kit control; focus ring is a visual change | 05 p1 (design tokens for focus) | focus + keys in the Kit controls (Space toggles, arrows in Choices, Enter activates), one visible focus token, `Accessible.name/role`; prototype on the Wi-Fi popup | new 12-C (B/C) |
| U-06 | Memory: `qs` holds 834 MB RSS idle; every app window and all nine Shell Manager pages are built at start | live: `ps -o rss -C qs` 834 448 kB at 16:57 and 834 260 kB at 21:58 uptime (stable, not a leak); 327 MB shared. code: `shell.qml:35-55` instantiates 10 windows + overlays; no `LazyLoader`/`Loader` in any `apps/*/*Window.qml`; `ShellManager.qml:377-386` makes every page. Share of each part: hypothesis | heavy on 8 GB machines; slow start | S3 | M | medium: window state kept across opens may reset | — | measure with windows stubbed, then `LazyLoader` for windows and pages that are closed (Quickshell `LazyLoader`) | new 12-D (B) |
| U-07 | Idle polling spawns ~1.5 bash processes a second for ever | live: 10 s sample of `ps --ppid <qs>`: `mihomo.sh --status` ×5, `wifi.sh --status` ×3, `battery.sh --status` ×3, `audio.sh` ×1, `bluetooth.sh --devices` ×1; `qs` 0–5 % CPU. code: `running: true` timers — `MihomoService.qml:115` (2 s), `BatteryService.qml:125` (3 s, also with no battery: face hidden, service on), `BrightnessService.qml:114` (2 s), `AudioService.qml:146` (2 s, `pactl`), `WifiService.qml:279` (5 s) | battery wake-ups on laptops; noise in `top` | S3 | M | low | — | event sources first (UPower D-Bus, `pactl subscribe`, udev backlight, the existing `--listen`s); poll only while a popup is open; a no-battery machine stops polling | new 12-D (with U-06) |
| U-08 | No reset or export of the shell's own options; resets that exist are instant and partial | code: `config/ShellSettings.qml` (35 keys: appearance, animations, bar look) has no reset; `ModuleSettings.reset(id)` per module, `BarLayout.reset(screen)` per monitor (`bar/BarLayout.qml:200` keeps child bars and the island layout); Reset buttons call at once, no confirm / undo (`ModulesPage.qml:109-115`, `ShellAppsPage.qml:152-154`, `BarPage.qml:302-306`); no schema version (D-09) | a user who broke the look has no way back but deleting `settings.json` by hand | S3 | M | low | D-09, 05 p1 | per-page "Reset" + "Reset everything" with a confirm; export / import of the state dir | 05 (input) |
| U-09 | Missing hardware has no state: modules show values that mean "nothing there" | code: battery and brightness are `quickshell` core modules (`components.toml`), not `laptop`; no backlight → `brightnessctl` prints nothing, face shows `0`, wheel does nothing (`BrightnessService.qml:24`); no sink → audio shows `0`, not `--` (`AudioService.qml:25-26`, rule `shell/CLAUDE.md` › Bar); charge limit row always shown (`BatteryPopup.qml` ~98) even without `charge_control_end_threshold`; 15 of 35 services have no `error`/`status` (`Audio`, `Brightness`, `Wifi`, `Sysmon`, `Capture`, …) | on a desktop: a dead brightness number; with broken audio: "0" reads as muted | S3 | M | low | — | hardware-gated modules (`auto` terms or a detected-backlight trait), an "unavailable" face (`--`) and an empty-state line in each popup | new 12-E (B) |
| U-10 | Optional parts stop at modules: apps are never gated, and `quickshell` is one big component | code: no `installed()` in `ShellAppsPage.qml`, `ShellAppsService.qml`, `LauncherService.qml` — VirusTotal (component `virustotal`, default off) still lists in Apps and the launcher; `components.toml` › `quickshell` pulls `restic`, `gpu-screen-recorder`, `cava`, `dnsmasq`, `iw`, `pacman-contrib` for Backups, Capture, the wave, the hotspot, Packages | a user who did not pick VirusTotal sees a broken app; nobody can install the bar without Backups / Cleaner / Packages | S3 | M | medium: file moves between components | 09-A (same pattern) | gate apps by their module's components; split `quickshell` into core + `shell-backups`, `shell-capture`, … (suggested, on by default) | new 12-F (B) |
| U-11 | Contrast and text size: hint and caption greys fail WCAG AA in every theme; the shell's text size is fixed | live (computed from each theme's `Colors.qml`): `gray` on `background0` 2.32 (onedark) – 3.79 (graphite), 57 uses (sidebar captions, `Esc close`, footers, often at `fontSize - 2` = 11 px); `muted` (every `KitRow` hint, `KitLabel`) 3.50 (nord) – 5.59, under 4.5 in gruvbox 4.44, catppuccin 4.44, tokyonight 4.10, dracula 3.98, everforest 3.84, onedark 3.73, nord 3.50. `Theme.fontSize: 13` (`config/Theme.qml:78`), no option; only monitor scale | low-vision users can't read hints; WCAG 2.2 SC 1.4.3 (4.5:1 for text) | S3 | S–M | medium: a look change (owner approval, refactors keep visuals) | — | raise `muted` to ≥ 4.5 in `mktheme.py`, keep `gray` for non-text; a text-size option (Theme scales from it) | new 12-G (B) |
| U-12 | Settings are wide and unsearchable; where an option lives is not predictable | code: 39 options pages, ~257 rows (163 in `*Settings.qml`, 94 in Shell Manager pages); no search (00); an app's module options under Apps, others under Modules (`shell/CLAUDE.md` › An app); Lock under Apps; toast duration under Modules › Notifications, bar style under Bar | "where is X" needs the author's map | S3 | L | — | 05 p1 | search over every row's label + hint; IA in 05 | 05 (input) |
| U-13 | Multi-monitor: two layout roles only, one wallpaper for all outputs | code: `BarLayout.qml:61-75` roles main / extra, main = first non-internal in `Quickshell.screens` order (two externals: order may swap on replug — hypothesis); a third monitor shares "extra"; `Wallpaper.qml:24` one `awww img` / `clear` with no `--outputs`. Not tested: one monitor here | per-monitor wallpapers (spec §13 example) impossible; desks with 2 externals may see bars swap | S3 | M | low | — | per-output wallpaper (`awww img -o`), main = an explicit pick in Bar › Monitor | new 12-H (B) |
| U-14 | First run ends with no next step; the wizard drops picks on Esc | code: `installer/setup.py:137-145` ends with verify, "Left to do by hand", the log — no "log in on a tty and run `start-hyprland`" (README only); no display manager; no first-session hint in the shell (Super+S, Super+B); `installer/wizard.py:164` maps Esc to quit at once (all picks lost, no confirm); theme picked blind by cycling 13 names (`:296-297`) | a new user after a long install does not know how to get into the desktop or what keys exist | S3 | S | low | — | a closing "Next" block in `setup`; a one-time hint toast in the shell; Esc = back, q asks | new 12-I (B) |
| U-15 | Pictures a user adds are copied into the repo | code: `apps/shellmanager/WallpaperService.qml:9-12` "copied into the active theme's folder, so it lives in the repo" | personal images become untracked files in `~/.dotfiles` (one `git add -A` from being published) | S3 | S–M | low | — | user pictures in `~/.local/share/dotfiles/wallpapers/` (or `~/Pictures`), listed beside the repo's | new 12-H (with U-13) |
| U-16 | Extension points are repo edits: a module or app needs changes to shared registry files | code: `shell/CLAUDE.md` › A module 5–6 (`BarLayout.modules`, `bar/ModuleFaces.qml`, `components.toml`); no user drop-in dir; docs for it are agent rules; `update` is fast-forward only (`CONVENTIONS.md` › Living with it) | anyone extending it forks and then conflicts with `update` | S4 | L | high (a plugin boundary) | 05, 13 | decision record later; not now | — (deferred) |
| U-17 | Docs state a wrong fact: `modules.json` "written on exit, external edits lost" | code: `config/ModuleSettings.qml:35-41` `watchChanges`, `onFileChanged: reload()`, `onAdapterUpdated: writeAdapter()`; text in `docs/SHELL_ARCHITECTURE.md` › Settings and `00_REPOSITORY_AUDIT.md` › §6. `layout.json` is the one not watched (`BarLayout.qml:319-323`) | misleads the 05 design (migration, external edits) | S4 | S | — | — | fix the two docs | 13 / next docs pass |

### Checked, no issue (how)

- Reduced motion: Animations has all-off and per part (`ShellSettings` `motion*`, `config/Motion.qml`) — read.
- Escape: every window and bar popup closes on it (`BarPopup.qml:115`, `*Window.qml` `StandardKey.Cancel`, island `Keys.onEscapePressed`) — grep.
- Not-installed modules: hidden from bars, greyed in Modules with `components add …` (`ModulesPage.qml:48,123-125`) — read; Yandex Music coupling is 09-A, not re-reported.
- Live apply: `settings.json` and `modules.json` are watched and reloaded; options apply without restart (`ShellSettings.qml:80-90`) — read.
- Theme change: `.theme` watched, recolours live (`shell.qml:87-98`) — read.
- Window sizes: largest default 1040×640 (Files) fits 1366×768 at scale 1 — `*Window.qml` sizes; at 1.25 (614 px logical height) Files and Backups are taller than the screen less the bar (hypothesis, not tried).
- Wizard: refuses a terminal under 72×20, checks run before any write, summary before setup (`installer/wizard.py:342-359`) — read.
- Wi-Fi / Bluetooth without their tools: the scripts answer `{"ok":false,"error":"<bin> is required"}` (`scripts/wifi.sh:27-28`, `bluetooth.sh:25`) — read. NetworkManager and BlueZ are hard deps of `quickshell`; rival services are listed "by hand" (CONVENTIONS › Setup) — accepted, not a finding.

### Not checked, and why

- `tests/fresh-machine.sh defaults`: ~840 MB download, needs the owner's yes. U-01 and U-14 rest on code until then.
- The combination matrix live (bar style × monitors, wallpaper modes × monitors, accent × corners, island + open module + notice + OSD, each Shell Manager page's options changed at runtime): it changes the owner's live session; one monitor only. U-04 is from code.
- Audio with no device / BT only: no way to remove the card here.
- Solid-bar overflow (U-01): the owner's layout is customised; needs a screenshot of a fresh state dir.

### Sources

- WCAG 2.2 (W3C Recommendation), https://www.w3.org/TR/WCAG22/ — SC 1.4.3 Contrast (Minimum): 4.5:1 for text (U-11); SC 2.1.1 Keyboard, SC 2.4.7 Focus Visible, SC 4.1.2 Name, Role, Value (U-05). Applies to the shell's own surfaces; limits: written for web content, used here as the common bar.
- Quickshell `LazyLoader` (Quickshell docs, type `Quickshell.LazyLoader`) — the mechanism for U-06; to be confirmed against Quickshell 0.3.2 in that task.
- No other HIG cited: no finding needed one; Noctalia parity not compared (no source checked in this pass).

### Phase 2 — slice 1: U-03, U-04, U-17 (owner: "go to code", 2026-10-19)

Category A each. Scope: the import (U-03); island toasts kept (U-04); the two
doc lines (U-17). Out: every other finding (own tasks, 12-A first).

Files edited: `apps/shellmanager/Wallpaper.qml`, `bar/island/Island.qml`,
`bar/island/IslandService.qml`, `docs/SHELL_ARCHITECTURE.md`,
`docs/implementation-plans/00_REPOSITORY_AUDIT.md`, this file, the roadmap.

U-04, found while planning: a plain notice after a critical one starts the
timer, whose end clears the critical too (`IslandService.qml:122` looks at
`fresh` only).

Steps:
1. `Wallpaper.qml`: `import qs.apps.display`.
2. `IslandService`: the flash is untimed while any shown notice is critical;
   `clearNotices(keepCritical)`.
3. `Island.qml`: an OSD drops only plain notices; its end brings the critical
   ones back; the notice timer waits while the flash is not shown (a module
   popup, the power view) and starts again once it is.

Acceptance:
- `qs log -c shell` after a restart: no `DisplayService` ReferenceError.
- Island, `notify-send -u critical a b`, then a volume key: after the OSD the
  critical toast is back; dismissing it ends the flash.
- Critical, then `notify-send c d`: after 5 s the critical is still there (the
  stack is untimed while a critical is in it).
- A module popup open, `notify-send e f`: nothing over the popup; on close the
  toast shows for the full duration.
- `./install.py check` green.

Result (2026-10-19): **Implemented and verified.** After a restart the log
has no `DisplayService` error and no new WARN (only Qt's textinput noise).
Island, screenshots by `grim`: critical toast → volume OSD → the critical
toast back after it; a plain notice stacked on it, both still there after
6.5 s; audio popup open + `notify-send`: nothing over the popup for 6.5 s, the
toast on close, gone 6 s later (unseen dot on the bell). `./install.py check`
all ✓, `ruff` clean. Not tested: Solid style (mako draws, untouched); two
screens (each island runs the same logic on the shared list).

### Phase 2 — 12-A: default bar and overflow (U-01; owner approved the set, 2026-10-19)

Category B. Scope: a fresh layout (and Reset) puts on the strip only
workspaces · clock · audio, wifi, bluetooth, battery, notifications, shell,
folder; every other module starts in the Folder (still movable to any zone
or HIDDEN on Bar › Layout). Solid style: modules of LEFT / RIGHT that don't
fit fold into the Folder at run time, not saved; they come back when there is
room. Out: the island (it has its own layout), the Shell Manager preview (its
`+N` is about the preview's room), the centre zone (never folds).

Files edited: `bar/BarLayout.qml`, `bar/Bar.qml`, `modules/folder/Folder.qml`,
`packages/quickshell/shell/README.md` (Child bars / Folder text), this file,
the roadmap.

Design:
- `BarLayout.defaultBar` (ids); a role's `folder` that is `null` (fresh, or
  after Reset) reads as every other module. A saved entry keeps its array; an
  entry from before the Folder (`folder` absent) stays `[]`; a shared layout
  saved before per-monitor ones (`state.zones` set) keeps no default folder.
  Existing layouts don't change.
- `BarLayout.overflow` (screen → ids, runtime) and `folderShown(screen)` =
  saved folder + folded ones; `update()` keeps writing `inFolder` only.
- `Bar.qml`: each zone slot's width is cached while it is loaded; a folded
  slot is hidden and its Loader empty (one face per module: the Folder makes
  the folded one, its popup and IPC); the fold is worked out from the cached
  widths, the side's room (centre, child bars, edge margin, a 24 px gap) and
  goes from the centre outwards (RIGHT from its start, LEFT from its end).
  The Folder itself never folds; no Folder on that bar → no fold.

Acceptance:
- A fresh state dir: the strip shows the set; Folder lists the rest; dragging
  one from FOLDER to RIGHT puts it on the bar. (Checked on a copy of the state
  dir, then the owner's own state put back.)
- Reset on Bar › Layout brings the set back; the owner's saved layout is
  unchanged by the update (diff of `layout.json` before / after).
- Solid style with a crowded RIGHT: no overlap with the clock; the folded
  modules in the Folder (count, tiles, their popups open); widening the room
  (a module moved to HIDDEN) brings them back. No duplicate-IPC warning.
- `qs log -c shell` no new WARN; `./install.py check` green.

Result (2026-10-19): **Implemented, partially verified.** On this machine
(one 1600 px logical screen), state dir backed up and put back (`diff` of
`layout.json` / `settings.json`: identical):
- the owner's layout after the update: `layout.json` unchanged, island as before;
- no `layout.json`, Solid: the strip is the set, the Folder `20` with the rest
  (screenshot); `folder: null` in an entry (Reset's write): the same;
- `folder: []` (every module on the strip): RIGHT folds from Task Manager
  onwards, nothing reaches the clock, Folder `16`; a folded module's popup
  (`sysmon toggle`) opens from the Folder; separators narrowed live (bar gap
  0) → one comes back (`15`); no duplicate-IPC warning;
- `./install.py check` all ✓; log clean after the owner's state came back.
Not tested: the drag from FOLDER to a zone (code path `BarLayout.move`
unchanged); child bars beside a crowded side; two monitors.

Seen while testing, not caused by 12-A (both show with the old code paths):
`Workspaces.qml:32` `Qt.callLater(() => started = true)` writes to a gone
item when the zone's Repeater remakes it while `layout.json` loads (WARN
"Invalid write to global property"); a centre zone with a hidden face before
the clock (equalizer while paused) draws a leading `|`. Small A fixes, not
done here.

### Phase 2 — 12-B: the shell starts again after a crash (U-02; owner: "continue", 2026-10-19)

Category B. Found while planning: `apps/lock/Lock.qml:11-13` says a shell
started again locks anew, but nothing does it — `sessionLock.locked` starts
false, so a crash while locked leaves Hyprland's dead-lock screen even after
a restart.

Scope: a supervisor script; every start / restart path goes through it; the
lock comes back after a crash while locked; the docs. Out: a QML error that
leaves `qs` running without a bar (Quickshell reloads on the next edit; not a
crash); a systemd unit (it would need the session's environment imported and
fights the kill-and-start restarts).

Files edited: `scripts/supervise.sh` (new), `packages/hypr/components/autostart.lua`,
`apps/shellmanager/AboutPage.qml`, `apps/shellmanager/FontService.qml`,
`apps/lock/Lock.qml`, `installer/maintain.py` (doctor's hint), `shell/CLAUDE.md`
(Work › Restart, Layout), `shell/README.md`, `docs/SHELL_ARCHITECTURE.md`, this file, the roadmap.

Design:
- `supervise.sh` runs `qs -n -c shell` in the foreground. Exit 0 (also a
  duplicate: `-n` exits 0) or a kill by HUP / INT / TERM (Restart, `qs kill`,
  logout): done. Anything else (SEGV, ABRT, KILL from the OOM killer, an error
  code): mako's `island` mode off (nothing else would draw a toast), then
  start again after 1 s; the 5th crash within 60 s stops it with a critical
  notification.
- Restart paths keep "kill, wait, start", the start being the supervisor.
- Lock: on lock, `$XDG_RUNTIME_DIR/shell-lock/locked` holds the Hyprland
  instance signature (the dir is removed on unlock, as now); at start, a
  marker of this session locks at once (plain colour, no snapshot). A stale
  marker from another session is ignored.

Acceptance:
- `kill -SEGV <qs>`: a new `qs` within ~2 s, one instance, bar back.
- Restart from About and `kill <qs>`+start: one instance, the supervisor of
  the old one gone (`pgrep -af supervise`).
- Five SEGVs in a row: stops, critical toast visible (mako mode reset).
- Lock after a crash: not run by the agent (it needs the owner's password at
  the screen); steps written for the owner.
- `shellcheck`, `ruff`, `./install.py check` green; log clean.

Result (2026-10-19): **Implemented, partially verified.**
- U-02 was half wrong: Quickshell 0.3.2 has its own crash handler. On SEGV it
  re-execs the config in the same process (same pid, new launch time in
  `qs list`) and opens a crash report window (`org.quickshell`); when the
  crash comes right after start, the process exits (139) instead. The
  supervisor covers the exits and KILL; the relock covers both.
- `kill -SEGV`: first run — process ended, the supervisor started a new one;
  second — Quickshell restarted in place. One instance each time.
- The restart command (`FontService.restartShell`'s, run by hand): old qs and
  its supervisor gone, one new supervisor + qs.
- Five `kill -KILL` in a row: four restarts, then stop; the critical toast
  "The shell keeps crashing" drawn by mako (island mode taken off; screenshot).
  The shell started again by hand; mako back to `island` by the shell.
- `shellcheck -S warning`, `ruff`, `./install.py check` all ✓; log clean.
- Not run: the lock after a crash (needs the owner's password at the screen).
  Owner's check: Super+Z, then from a tty or ssh `kill -KILL $(pgrep -x qs)`;
  within ~2 s the lock screen is back and the password unlocks.
- About › Restart and the launcher's Restart shell clicked: not done (no
  pointer automation); they call the command tested above.

Found while testing (new finding, not fixed here):

| ID | Finding | Evidence | User impact | Sev | Effort | Risk | Depends on | Recommendation | Task |
|---|---|---|---|---|---|---|---|---|---|
| U-18 | Every shell restart leaks its listener scripts | live: after a day of restarts, 39 `music.sh` / `bluetooth.sh` / `wifi.sh --listen` with ppid 1 plus 61 of their subshells (killed by hand: only those outside the live `qs` tree); an in-place crash restart also keeps the old set as children (10 under one `qs`). `wifi.sh:431` / `bluetooth.sh:179` pipe `nmcli monitor` / `gdbus monitor` into a read loop, `music.sh:61-67` loops on `mpc idle` (else `sleep 2`); none is killed with its parent, and a closed stdout only ends one at its next write | processes and memory grow with each restart; old listeners keep polling | S3 | S | low | — | listeners exit when stdout closes or their parent goes (`trap` + check `$PPID`, or `exec` the monitor command so the kill reaches it) | new 12-J (A) |

### Phase 2 — 12-J: listeners end with the shell (U-18; "continue", 2026-10-19)

Category A. Files: `scripts/listen.sh` (new, sourced), `scripts/wifi.sh`,
`scripts/bluetooth.sh`, `scripts/music.sh`, this file, the roadmap.

Steps: `listen.sh` › `listen_to <cmd…>` runs the monitor in a process
substitution (its pid known), reads it with a 2 s timeout, writes `ok` per
event, and ends — killing the monitor — when its parent (`qs`) is gone, the
monitor ends, or a write fails (SIGPIPE ignored, so a closed stdout is an
error, not a silent death). `music.sh` `cmd_listen`: the same parent check,
`mpc idle` under `timeout 30` so a gone parent is seen within 30 s.

Acceptance: kill `qs` (TERM and KILL): within ~2 s (music ≤ 30 s) no
`--listen` with ppid 1; a Wi-Fi / Bluetooth event still reaches the shell
(toggle Bluetooth power: the popup follows); `shellcheck` clean.

Result (2026-10-19): **Implemented and verified.** A fake parent that dies
after 3 s: Wi-Fi and Bluetooth listeners and their monitors gone within 2 s,
the music one within 30 s; a 2 s BlueZ scan under it gave 4 `ok` lines
(events still pass; instead of toggling power, which would drop the owner's
devices). The real shell killed by TERM and by KILL (the supervisor's
restart): no listener of the new code left with ppid 1 (the ones left
dated from before the change). Old leftovers of the whole day removed by
hand: ~100 processes (`--listen` shells, `nmcli` / `gdbus monitor`,
`mpc idle`). `shellcheck -S warning -x` clean. An in-place crash restart
keeps the old set until its next write (stdout closed → the write fails →
it ends): not waited for.

Correction (same day, found in 12-D): the TERM case above was misread. On
its way out Quickshell sends its processes TERM; bash died by the signal and
its EXIT trap never ran, so `nmcli monitor` / `gdbus monitor` were left (the
fake parent sent no signal, so it did not show). `listen.sh` now turns TERM /
INT / HUP into `exit`. Re-checked: shell TERM → after 3 s only `music.sh`
(its `timeout 30 mpc idle`, by design ≤ 30 s); shell KILL → none after 34 s.

### Phase 2 — 12-D part 1: idle polling (U-07; "continue", 2026-10-19)

Category B (a bar value updates less often while its popup is closed).
Measured cost of one run (`time bash <script>`): `mihomo.sh --status` 0.098 s
CPU, `wifi.sh --status` 0.164 s, `battery.sh --status` 0.050 s, `audio.sh`
0.019 s, `brightness.sh --get` 0.010 s — at their intervals ≈ 11 % of one
core, all the time.

Changes (popup open → as now; closed → slower or by event):
- Mihomo status: 2 s open, 15 s closed (`idlePollMs`).
- Wi-Fi status: 5 s open, 20 s closed; NM changes already come by `--listen`.
- Battery: 3 s open, 30 s closed, and at once on a UPower change of the
  display device (plugged / unplugged, percentage) — `Quickshell.Services.UPower`.
- Audio ports: `audio.sh --listen` (`pactl subscribe`, card and server events
  only, through `listen_to` with a line filter) replaces the 2 s poll; a 30 s
  poll stays as a fallback. Brightness (0.5 %) left.

Files: `MihomoService.qml`, `Mihomo.qml` (none: hooks exist), `WifiService.qml`,
`BatteryService.qml`, `Battery.qml` (onHidden), `AudioService.qml`,
`scripts/audio.sh`, `scripts/listen.sh`, this file, the roadmap.

Acceptance: 60 s idle sample of `ps --ppid <qs>`: mihomo ≤ 5 runs, wifi ≤ 4,
battery ≤ 3 (+ UPower), audio.sh ≤ 3; a headphone plug or a default-sink
change still updates the audio popup at once (a sink switch by `pactl`); the
battery face follows unplug within ~1 s (owner: unplug); `shellcheck`, log clean.

Result (2026-10-19): **Implemented, partially verified.** 60 s sample of the
shell's children every 0.2 s, popups closed: `mihomo.sh --status` 2,
`wifi.sh --status` 2, `bluetooth.sh --devices` 3, `audio.sh` only its
`--listen` (the sample misses runs shorter than 0.2 s, e.g. battery's 50 ms;
before: ~90 runs a minute). Estimated idle cost ≈ 2 % of a core, from ≈ 11 %.
`audio.sh --listen` under a fake parent: a null sink loaded and unloaded → 5
lines; six volume steps → 1 line (a card change; the 300 ms refresh folds it).
`shellcheck -S warning -x`, `./install.py check` ✓, log clean. Not checked:
the battery face on unplug (UPower path; owner: pull the charger), a headphone
plug (owner).

### 12-D part 2: memory — measured, not changed (owner: "don't go deep into optimisation", 2026-10-19)

Fresh `qs` 30 s after start: RSS 577 MB, of it ~317 MB file-backed (Qt
libraries, fonts, icons: shared, reclaimable) and 260 MB anonymous. With the
ten app windows taken out of `shell.qml` (a temporary edit, put back, `git
diff` empty): RSS 492 MB, anonymous 182 MB. The windows cost ~78 MB of the
shell's own memory (~30 %). The 834 MB of U-06 was growth over a session
with popups and windows opened, not the price at start.

Left as an option, not done: `LazyLoader` for the ten windows (about −80 MB;
risk: a window's state — the Files listing, the Shell Manager page — starts
over each opening). U-06 stays S3; the growth over a long session is not
looked into.

### Phase 2 — 12-E: missing hardware shows as missing (U-09; owner: "go", 2026-10-19)

Category A/B, kept small (owner: no deep work). Out: an error state for all
15 services; component gating of battery / brightness.

- Brightness: `brightness.sh` asks for the `backlight` class only (no
  backlight: `brightnessctl` would take an LED) and answers
  `{"ok":false,"error":"no backlight"}`; `BrightnessService.available`. Face
  `--`, wheel off; popup: subtitle `NO BACKLIGHT`, the BRIGHTNESS slider gone.
  The face is not hidden: dimming and the night light (hyprsunset) work
  without a backlight.
- Audio: no default sink → face `--`; popup subtitle `NO OUTPUT`; a device
  row with nothing to list says `None found`.
- Battery: `battery.sh --status` adds `limit` (the threshold file exists);
  the Charge limit row shows only then.

Files: `scripts/brightness.sh`, `modules/brightness/{BrightnessService,Brightness,BrightnessPopup}.qml`,
`modules/audio/{Audio,AudioPopup}.qml`, `scripts/battery.sh`,
`modules/battery/{BatteryService,BatteryPopup}.qml`, this file, the roadmap.

Acceptance: `brightness.sh --get` with a fake `brightnessctl` that finds
nothing → the error JSON; on this laptop the same values as before; the
popups look unchanged here (screenshots); `shellcheck`, log clean. The
no-hardware faces themselves: not reproducible here (said so).

Result (2026-10-19): **Implemented, partially verified.** `brightness.sh
--get` here `{"brightness":100}`, `--step -5 / +5` 95 / 100; with a fake
`brightnessctl` that finds nothing `{"ok":false,"error":"no backlight"}`.
`battery.sh --status` here `limit: true`. After a restart the Brightness and
Battery popups look as before (screenshots: slider, `CHARGING · … TO 100%`,
Charge limit row); log clean; `shellcheck`, `check shell syntax` ✓. Not
seen: the `--` faces, `NO BACKLIGHT`, `NO OUTPUT`, `None found` and the
hidden limit row (no machine without a backlight, a sink or the threshold
file here).

### Phase 2 — 12-F: optional apps gated, `quickshell` split (U-10; owner: "everything by the plan", 2026-10-19)

Category B (installer + wizard). Two parts.

1. Apps: an app whose bar module is not installed (`apps.json` › `module` in
   `BarLayout.notInstalled`) leaves Shell Manager › Apps (shown greyed with the
   `components add` hint, as Modules does) and the launcher.
2. Split: new components, `requires = ["quickshell"]`, default on, group
   desktop, no `links` (every QML file stays linked with `quickshell`, or
   `shell.qml`'s imports break): `shell-backups` (module `backup`, `restic`),
   `shell-cleaner` (module `cleaner`), `shell-packages` (module `packages`,
   `pacman-contrib`). Capture, the hotspot (`dnsmasq`, `iw`) and the wave
   (`cava`) stay in `quickshell` (core features / degrade without).

Migration (found while planning): a saved selection lists what is on, so a
component newer than it would be off — the owner and every set-up machine
would lose Backups / Cleaner / Packages. New catalog field `split_from`: such
a component is on wherever its parent is, unless `[components] off` names it;
saving (wizard, `components add|remove|set`) writes `off` for a split
component left out while its parent is on. A fresh machine is unchanged
(default on). Tests in `tests/test_components.py` (and the wizard's save).

Files: `components.toml`, `installer/components.py`, `installer/choose.py`,
`installer/wizard.py`, `tests/test_components.py`, `tests/test_wizard.py`,
`CONVENTIONS.md` (components fields), `apps/shellmanager/ShellAppsPage.qml`,
`apps/launcher/LauncherService.qml`, this file, the roadmap.

Acceptance: tests green; `./install.py components` on this machine lists the
three on (owner's saved list has none of them); `components remove
shell-cleaner` then `add` round-trips through `off` (on a copy of the
profile); `check components` green; with `shell-cleaner` off the Cleaner
module and app leave the bar, Apps and the launcher (`components.json`),
then back. `tests/fresh-machine.sh` not run (owner).

Result (2026-10-19): **Implemented, partially verified.**
- Tests: 4 new (split follows parent, `off` keeps it off, `record`, catalog
  check; the wizard writes `off`); all 141 installer tests pass;
  `check components tests` ✓.
- The real catalog, a selection saved before the split → all three on; with
  `off = ["shell-cleaner"]` → that one off.
- This machine: `components remove shell-cleaner` → `off = ["shell-cleaner"]`,
  `components.json` › `cleaner`, Shell Manager › Apps › Cleaner shows "Not
  installed · components add shell-cleaner" (screenshot); `add` → back.
  Correction to the plan's acceptance: the owner's profile has no
  `[components]` at all ("nothing chosen": everything is on), so the
  migration was not what kept the three on here; the round trip wrote a
  saved list, so the profile was put back from its backup (`diff` empty).
- Not checked: the launcher without the app (code: `shellApps` filtered by
  the same `installed()`); the wizard's screens drawn. Hyprland binds of an
  app that is off (Super+X for Cleaner) still open its window: left as is.

### Phase 2 — 12-I: first run (U-14; owner: "everything by the plan", 2026-10-19)

Category B, small. Out: a theme preview in the wizard.

1. `setup` ends, outside a Hyprland session (the first install, from a tty),
   with a "Next" block: log in on a tty and run `start-hyprland`; Super + S
   the Shell Manager, Super + B every keybind, Alt + Space the launcher
   (corrected: the plan said "the system menu"), Super + Q a terminal.
   Inside a session (an `update`) nothing new is printed. `setup.next_steps`.
2. The shell's very first start (no `settings.json` yet) shows one toast with
   the same keys. `ShellSettings.firstRun` (not saved).
3. Wizard: Esc is back (was: quit at once, every pick lost); q asks once more
   ("q again to quit: nothing is written").

Files: `installer/setup.py`, `installer/wizard.py`, `tests/test_steps.py`,
`tests/test_wizard.py`, `config/ShellSettings.qml`, `shell.qml`, `README.md`
(the wizard's keys), this file, the roadmap.

Acceptance: tests for `next_steps` and the wizard keys; the toast on a fresh
state dir (a copy, then the owner's put back); `./install.py check` green.

Result (2026-10-19): **Implemented and verified.**
- `setup.next_steps(env)`; tests: a run with no `HYPRLAND_INSTANCE_SIGNATURE`
  logs `start-hyprland` and `Super + S`, one inside a session nothing.
- Wizard: `key_name` (Esc → back) and `Quit` (q asks, a second q in a row
  quits, any other key starts over); 3 tests. All installer tests pass.
- The toast: `ShellSettings.firstRun` is set only when `settings.json` is
  missing (`FileViewError.FileNotFound`, not a broken file). The state dir
  backed up, `settings.json` removed, shell restarted: mako lists "Welcome"
  from `Shell`; the owner's state put back (`diff -r` same), restarted: no
  toast, log clean. `./install.py check` all ✓, `ruff` clean.
- Not seen: the "Next" block on a real tty install (`fresh-machine.sh` not
  run: owner); the wizard's screens drawn (keys tested without curses).
- Seen, not caused by 12-I: on a fresh state dir Quickshell logs one WARN
  `fileview: got operation finished from dropped operation` (the defaults
  written while the watch reloads). `$XDG_RUNTIME_DIR/shell-lock/locked` of
  this session was present while the screen was not locked, and a live
  reload logged "Session lock object was destroyed without unlocking": the
  relock marker of 12-B may be left behind after an unlock. Not looked into.

### Phase 2 — 12-G: hint contrast and a text size (U-11; owner: "12-G, 12-H by the plan", 2026-10-19)

Category B (a look change, approved as U-11's recommendation). Found while
planning: `muted` is kitty's `color8` (and tmux's, nvim's) — raising it in
`mktheme.py` would recolour the terminal too. So the shell lifts it for
itself: theme files unchanged.

Scope:
1. `Theme.muted` = the theme's `muted` mixed toward `foreground0` in 2 %
   steps until it reaches 4.5:1 on `background0` (`Theme.legible`); a theme
   already there keeps its colour (graphite, ember, khaki, rosé pine,
   kanagawa). Below now: gruvbox 4.44, catppuccin 4.44, mono 4.36,
   tokyonight 4.10, dracula 3.98, everforest 3.84, onedark 3.73, nord 3.50.
2. Text drawn in `gray` takes `muted`: the clock face, the music queue's
   numbers, the island's OSD value, notice body, artist and times, the hub's
   artist, a field's placeholder, Shell Manager's sidebar captions and
   `Esc close`. `gray` stays for frames, ticks, icons, the `|` separator, the
   `❯` prompt and inactive text (the speed test before a result, a dimmed
   slider's value — WCAG exempts inactive parts).
3. Appearance › FONT › Text size: `12 px · 13 px · 14 px · 15 px` (chips),
   default 13; `Theme.fontSize` reads it (`ShellSettings.textSize`), every
   `fontSize ± n` follows. The bar's and the island's heights stay; the lock
   clock and the overview's numbers keep their own sizes.
Out: `gray` on frames and icons (WCAG 1.4.11, 3:1 — a separate look
question); a text size above 15 (fixed bar and row heights).

Files edited: `config/Theme.qml`, `config/ShellSettings.qml`,
`apps/shellmanager/FontSection.qml`, `modules/clock/Clock.qml`,
`modules/music/MusicQueue.qml`, `bar/island/{IslandOsd,IslandNotice,IslandMedia,IslandHub}.qml`,
`kit/KitInput.qml`, `apps/shellmanager/ShellManager.qml`, `shell/CLAUDE.md`
(UI › colour of hints, the text size), this file, the roadmap.

Acceptance:
- `Theme.muted` on `background0` ≥ 4.5 in every theme (computed for each
  theme's colours by the same formula, in Python); unchanged where it was.
- Screenshots (gruvbox): a popup, Shell Manager's sidebar, the island's
  media before / after — hints a step lighter, nothing else moved.
- Text size 15: the Wi-Fi popup and Shell Manager › Appearance with no text
  cut or overlapping (screenshots); back to 13: as before.
- `./install.py check` green; log no new WARN.

Result (2026-10-19): **Implemented, partially verified.**
- Contrast, same formula in Python over all 13 themes' colours: lowest now
  4.51 (gruvbox 4.44 → 4.51, catppuccin → 4.54, mono → 4.60, tokyonight →
  4.57, dracula → 4.60, everforest → 4.55, onedark → 4.52, nord → 4.55);
  graphite, ember, khaki, rosé pine, kanagawa unchanged.
- Screenshots (gruvbox, island): the Wi-Fi popup at 13 px as before (gruvbox
  moves 2 %: not visible); at 15 px the Wi-Fi popup and Shell Manager ›
  Appearance with nothing overlapping (the popup's `This PC` address elides
  beside a long ping line). Back to 13: the owner's `settings.json` put back
  (`diff` same).
- `./install.py check` all ✓; log no new WARN.
- Not seen: the Text size row itself (below the fold; no scroll by IPC), the
  other 12 themes drawn, every app window at 15 px.

### Phase 2 — 12-H: monitors and wallpapers (U-13, U-15; owner: "12-G, 12-H by the plan", 2026-10-19)

Category B. Three parts; with one monitor nothing new shows in the UI.

1. U-15 — pictures a user adds live outside the repo:
   `~/.local/share/dotfiles/wallpapers/` (`WallpaperService.userDir`). Add
   copies there; its pictures are listed for every theme between the
   theme's own and `common/`, kept as `user/<file>`;
   `WallpaperService.pathOf(rel)` turns a kept name into a path (Wallpaper,
   the lock screen, the theme preview). Pictures already in the repo stay
   where they are. The Appearance grid lists `WallpaperService.pictures`
   (one list, the same order as before plus the user's).
2. U-13 — a picture per monitor (image mode, more than one monitor):
   Appearance › Wallpaper › Monitor (`Every monitor` + each name, a
   `KitSelect`); a pick for one monitor goes to
   `ShellSettings.wallpaperOutputs` (theme → output → picture), a pick for
   every monitor clears that theme's. Wallpaper: `awww img` for all, then
   `awww img -o <output>` for each override; a colour mode stays one colour.
3. U-13 — the main monitor is a pick: Bar › Monitor › Main monitor
   (`Automatic` + each name; more than one monitor, bars not shared);
   `BarLayout` `state.main`, used while that monitor is connected, else the
   automatic rule (the first external one).
Out: a third role for a third monitor; per-monitor colour wallpapers.

Files edited: `apps/shellmanager/{WallpaperService,Wallpaper,WallpaperSection,ThemePreview,BarPage}.qml`,
`apps/lock/LockScreen.qml`, `config/ShellSettings.qml`, `bar/BarLayout.qml`,
`shell/README.md` (if it names the wallpaper folders), this file, the roadmap.

Acceptance:
- Add a picture: it lands in `~/.local/share/dotfiles/wallpapers/`, is
  picked and drawn (`awww query`); `git status` of the repo unchanged.
- An override for `eDP-1` in `settings.json`: `awww query` shows it on
  eDP-1; cleared: the theme's picture back.
- A headless second output (`hyprctl output create headless`, removed
  after): the Monitor rows show; a per-monitor picture on each; Main
  monitor set to it moves the main bar (screenshots), Automatic moves it
  back.
- The owner's `settings.json` / `layout.json` put back; `check` green; log
  without new WARN.

Result (2026-10-19): **Implemented, partially verified.**
- A picture in `~/.local/share/dotfiles/wallpapers/` kept as `user/…`:
  `awww query` shows it from there; an `eDP-1` override in `settings.json`
  → `awww query` shows the override; cleared → the theme's picture back.
  The repo's `git status` unchanged. Owner's `settings.json` put back
  (`diff` same), test picture removed.
- `check shell syntax` ✓; log no new WARN.
- Not done (owner: keep token use down; it would change the live session):
  the headless second output — the Monitor select, Main monitor and a bar
  moving between monitors are unseen; the Add button end to end (the copy
  target changed only).

### Proposed tasks (for approval)

Order by value / risk: 03 follow-up (U-03) and 01 follow-up (U-04) — category A, small; 12-A default bar + overflow (U-01); 12-B supervisor (U-02); 12-D memory and polling (U-06, U-07); 12-E hardware states (U-09); 12-F gating apps + component split (U-10, with 09-A); 12-I first run (U-14); 12-G contrast + text size (U-11); 12-H monitors + wallpapers (U-13, U-15); 12-C keyboard (U-05, after 05 p1). Into 05 phase 1 as inputs: U-08, U-12 (and U-05's focus token). U-16 deferred; U-17 a docs fix.

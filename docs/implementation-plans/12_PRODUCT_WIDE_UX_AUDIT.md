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

### Proposed tasks (for approval)

Order by value / risk: 03 follow-up (U-03) and 01 follow-up (U-04) — category A, small; 12-A default bar + overflow (U-01); 12-B supervisor (U-02); 12-D memory and polling (U-06, U-07); 12-E hardware states (U-09); 12-F gating apps + component split (U-10, with 09-A); 12-I first run (U-14); 12-G contrast + text size (U-11); 12-H monitors + wallpapers (U-13, U-15); 12-C keyboard (U-05, after 05 p1). Into 05 phase 1 as inputs: U-08, U-12 (and U-05's focus token). U-16 deferred; U-17 a docs fix.

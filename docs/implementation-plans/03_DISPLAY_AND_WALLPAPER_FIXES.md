# 03 — Wallpaper overwritten by Displays and at session start

Status: Implemented, partially verified (login and live Display check open) · Category: A · Depends on: nothing · Gate: none for
`--no-cache`-style fixes; owner approval if Hyprland's own background or
startup order changes visibly (D-04). Spec: §5.4, §5.5 (one root cause).
Shell paths are under `packages/quickshell/shell/`.

## Objective

The background the user chose (theme colour, custom colour, image) is the
only one ever shown: at login, after a Display change, after a monitor is plugged.

## Scope

In: `scripts/display.py` (its `awww restore`), `apps/shellmanager/Wallpaper.qml`,
`packages/hypr/components/autostart.lua`, `apps/display/DisplayService.qml`.
Out: wallpaper picker UI, theme files, Display features.

Files edited (expected): `scripts/display.py`, `Wallpaper.qml`, `autostart.lua`, maybe `DisplayService.qml`, `tests/test_display.py`.

## Read first

`Wallpaper.qml`, `WallpaperService.qml`, `config/ShellSettings.qml` (wallpaper
keys), `autostart.lua`, `scripts/display.py` (restore, apply), `awww-daemon --help`,
`awww --help`, audit §5.4/5.5.

## Findings so far (confirmed 2026-10-19)

- `awww clear <hex>` does not touch `~/.cache/awww/0.12.1/<output>`; that file
  holds the last image (`stripes.jpg`).
- `scripts/display.py:133-134` calls `awww restore` after every monitor apply
  (to redraw at the new scale) → the cached image replaces the colour (§5.4).
  `display.py restore` at login does the same.
- `awww-daemon` looks up the cache when it starts (`--no-cache` turns that
  off; it does not affect the client's `awww restore`) (§5.5).
- The shell applies the colour after `awww query` succeeds, seconds later at login.
- Source of truth for the background: `ShellSettings.wallpaperMode` /
  `wallpaperColor` / `wallpaperImages` — the daemon cache must not compete with it.

## Requirements

- One source of truth (ShellSettings); awww's cache never shows a stale choice.
- Login: no intermediate image; at worst the plain Hyprland background until
  the shell applies (D-04: make that colour the theme's `background1`, e.g.
  `misc.background_color` + `disable_hyprland_logo` via the theme's hypr colours — verify keys for 0.56).
- Display change / monitor added: the chosen background stays (re-apply if the daemon resets a surface).
- No new fixed sleeps as the primary fix (the existing wait loop may stay or be replaced by an event).

## Steps

1. Reproduce both with mode = theme colour: change a scale in Display; re-login (owner).
2. Main fix: `display.py` stops calling `awww restore`; the redraw at the new
   scale follows ShellSettings — e.g. the shell re-runs `Wallpaper.apply()`
   after a Display apply (DisplayService reply) and on Hyprland monitor events
   (`addedTimer` exists). Check that `awww img` at the new scale is sharp.
3. Login: `awww-daemon --no-cache` in `autostart.lua` if the cached image
   still flashes after step 2 (the login `display.py restore` no longer restores it).
4. D-04 for the pre-shell colour if the default Hyprland background is visible.
5. Update `tests/test_display.py` if it asserts the `awww restore` call.

## Acceptance

- Mode colour: Display scale/position/rate change → colour stays (each monitor).
- Mode image: same → the chosen image stays.
- Re-login (owner): no theme image flash in any mode.
- Plugging a monitor → it gets the chosen background.

## Validation

`./install.py check` (incl. `hypr`); `awww query`; `ls ~/.cache/awww/*/`;
`qs log -c shell`; the owner's re-login.

## Regressions

Theme switch (colour + image per theme); Shell Manager wallpaper picker; lock
screen background (`LockScreen.qml` reads the same settings); capture overlay stills.

## Forbidden

Changing wallpaper modes or the picker; arbitrary sleeps; editing generated theme files by hand.

## Report

Per README › Report format.

**Root cause (evidence):** `~/.cache/awww/0.12.1/<output>` holds
`…/wallpapers/gruvbox/stripes.jpg` on all three outputs, while the chosen
background was a colour (`awww query`: `currently displaying: color: 32302F`).
`display.py` `apply()` ran `awww restore` after each monitor change, which drew
the cached picture; the daemon also starts from that cache.

**Changes:**
- `scripts/display.py`: `apply()` no longer calls `awww restore`.
- `apps/display/DisplayService.qml`: new `applied()` signal, emitted when a change succeeds.
- `apps/shellmanager/Wallpaper.qml`: `Connections` on `DisplayService.applied` → `apply()`.
- `packages/hypr/components/autostart.lua`: `awww-daemon --no-cache` (step 3, applied up front: the cache is always stale for this shell).
- `tests/test_display.py`: `test_apply_never_restores_awww_cache`.

**Validation run:** `python3 -m unittest tests/test_display.py` (13 OK);
`./install.py check tests hypr` ✓; `./install.py check shell syntax` ✓; `ruff check` on the two Python files ✓;
`qs log -c shell`: only Qt text-input WARN lines, no new ERROR.

**Not verified:** a Display scale/position change with the owner watching the
wallpaper; a re-login (the `--no-cache` line takes effect only on a new session);
a plugged monitor; sharpness of `awww img` at the new scale. The live display was not changed.

**D-04 (step 4), done after the owner reported Hyprland's stock wallpaper at login:**
`packages/hypr/components/appearance.lua` sets `misc.force_default_wallpaper = 0`,
`disable_hyprland_logo = true`, `background_color = colors.background1` (the theme's
role, the colour the shell sets). `./install.py check hypr` and `Hyprland --verify-config` ok.
Not seen on screen yet: the live socket was stale in the check, so the value is not read back;
confirm at the next login.

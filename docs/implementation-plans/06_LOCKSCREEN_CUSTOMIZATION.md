# 06 — Lock screen: own settings section and customisation

Status: Not started · Category: B (move) / C (grid layout) ·
Depends on: 05 phase 1 approved (it fixes where Lock lives); 03 (wallpaper source of truth) ·
Gate: customisation proposal approved before implementation. Spec: §7.
Shell paths are under `packages/quickshell/shell/`.

## Objective

Lock screen options live in their own Shell Manager section; the user can
place, show/hide and colour the lock's elements, set blur and wallpaper, and
reset to defaults — without ever being unable to unlock.

## Scope

In: `apps/lock/{Lock,LockScreen,LockSettings}.qml`, its entry in
`apps/apps.json`, the Shell Manager navigation (as decided in 05).
Out: PAM / authentication changes, idle-lock policy, a second lock implementation.

## Read first

`apps/lock/*.qml` in full; `apps/apps.json` (lock); `apps/shellmanager/ShellManager.qml`
(page moves: `pageFor`, renamed pages); `apps/shellmanager/{WallpaperService,Wallpaper}.qml`;
`kit/` controls; `shell/CLAUDE.md` › UI; 03's outcome.

## Findings so far

`WlSessionLock` + `PamContext` in the shell. Options in `modules.json` › `lock`:
`background` (solid | wallpaper | blur), `blur`, `screen`, `clock`, `date`,
`user`, `power`, `layout`, `hideCursor`, `cursorDelay`. Settings now under Apps › Lock screen.

## Phase 1 — proposal

- Elements and which can move (clock, date, user, password field, power row, layout indicator…); the password field MAY move but MUST NOT be hidden.
- Grid: e.g. 3 × 3 anchors (corners, edges, centre) scaled by the output, or a finer grid — collisions (one element per cell or stacking rule), restore defaults, per-monitor or global.
- Colours: per element or per role; "Follow theme" switch shared by the colour rows (explicit inheritance: theme role vs user hex).
- Blur and wallpaper: own choice vs "same as desktop" (reads ShellSettings per 03).
- Preview in Shell Manager (static mock using the same QML), presets (optional, proposal), apply behaviour.
- Constraints: scaling / aspect ratios / portrait monitors; lock must render if a setting is invalid (fallback to defaults).
- References (record): Noctalia Shell lock screen, Windows lock screen, macOS lock screen, iOS lock screen customisation, Android lock screen; Linux `ext-session-lock` constraints.

## Phase 2 — implementation (after approval)

1. Move to the dedicated section (keep `shell open lock` working).
2. Show/hide + colours + follow theme.
3. Grid placement + reset.
4. Preview.

## Acceptance

- `shell open lock` opens the new section; old links work.
- Every element toggle and position observed on lock (owner) on every monitor; invalid saved layout → defaults, unlock works.
- Follow theme on → theme switch recolours; off → user colour kept.
- Reset restores defaults.

## Validation

`./install.py check`; `qs log -c shell`; `qs -c shell ipc call lock lock` (owner
present; wrong then right password); two monitors; round/sharp corners.

## Regressions

Blur snapshot; wallpaper mode image/colour; power actions on lock; keyboard
layout switch on lock; cursor hiding; session restore after a shell restart.

## Agents

None by default.

## Forbidden

PAM changes; hiding the password field; additions beyond the spec without a proposal.

## Report

Research format (phase 1), implementation format (phase 2).

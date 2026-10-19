# 01 — Notification system

Status: Not started · Category: A (parts A, B, E) / B (parts C, D) ·
Depends on: nothing · Gate: before part C+D implementation (lifecycle spec + D-01 approved).
Spec: §5.1 A–E.

## Objective

Toasts appear once per event, a click does what the user expects, the centre
keeps history without re-showing it, the toast duration is a setting, and
Capture's own notifications can be switched off.

## Scope

In: island toasts (`IslandService` › notice, `Island.qml`, `IslandNotice.qml`),
mako toasts in Solid style (config, click), `NotificationsService`,
`NotificationsPopup`, `NotificationsSettings`, Capture's `notify-send` calls,
the mako theme config (through gruvbox + `themes/mktheme.py`).
Out: replacing mako with an own server (only as decision D-01), the unseen dot
logic beyond what part C needs, notification styling, other apps' senders.

## Read first

- `modules/notifications/{NotificationsService,NotificationsPopup,NotificationsSettings,Notifications}.qml`
- `scripts/notifications.sh`
- `bar/island/{IslandService,Island,IslandNotice}.qml` (notice parts, `flashTimer`, `onNoticesChanged`)
- `apps/capture/{CaptureService,CaptureSettings}.qml`
- `themes/gruvbox/mako/config`, `themes/mktheme.py` (how mako config is generated), `themes/gruvbox/README.md`
- `docs/implementation-plans/00_REPOSITORY_AUDIT.md` › §5.1

(Shell paths are under `packages/quickshell/shell/`.)

## Findings so far (2026-10-19, from code, not reproduced)

- Two toast surfaces: Solid → mako; Island → the island (`mako mode island` = `invisible=1`).
- A: `flashTimer` ends the flash but leaves `IslandService.notices`; the next
  notification prepends to the old list → old rows reappear.
- B: `IslandNotice` click → `IslandService.openNotifications()` always.
  `NotificationsService.focusApp(item)` exists (window by class). mako's
  default action (`makoctl invoke -n <id>`) is not used; `notifications.sh`
  does not read actions.
- D: durations: mako `default-timeout=5000` + `ignore-timeout=1`; island `noticeMs: 5000` (critical ×2).
- E: `notify-send -a Capture` in `CaptureService.qml` (~195 copy, ~210 save, ~258 error, ~331 recording saved).
- One `Island` per bar (`bar/Bar.qml:232`) → one `flashTimer` per screen, all
  sharing the singleton `IslandService.notices`; an OSD flash can replace the
  notice flash (`Island.qml` `onFlashed`), so a timer in `Island.qml` is the wrong place to expire toasts.
- Replace: `NotificationsService.ingest` keeps only `n.id > state.lastId`
  (~line 76); mako keeps the id on a `replaces_id` update → updates are dropped today.
- In Island style mako still expires its (invisible) notification after
  `default-timeout`; after that `makoctl invoke` has no target.

Files edited (expected): `bar/island/{IslandService,Island,IslandNotice}.qml`,
`modules/notifications/{NotificationsService,NotificationsSettings}.qml`,
`scripts/notifications.sh`, `apps/capture/{CaptureService,CaptureSettings}.qml`,
`themes/gruvbox/mako/config` + regenerated themes. Shares `IslandService.qml` with 08-A and 09-A.

## Requirements

Lifecycle (part C) — one table in the report, then implemented:

| Event | Toast | Centre entry |
|---|---|---|
| arrival | shown once (one instance per notification id) | added once |
| timeout | gone; never re-shown | stays |
| manual dismiss (×) | gone | stays |
| click | default action of the source if it has one; else focus its window; else open the centre (D-02) | marked seen |
| open the centre | toasts close | all seen |
| delete one / clear all | — | removed |
| repeat from one source | each new id is new; a replaced id (`replaces_id`) updates, not duplicates | one row per id |

- Toast state is separate from centre entries (island: its own list keyed by id; centre: `NotificationsService.items`).
- D: setting **Toast duration** (`ModuleSettings` "notifications", key e.g. `toastSeconds`): chips `3 s · 5 s · 10 s · Until dismissed` (wording per `shell/CLAUDE.md`). Applies to new toasts without restart, in both styles. Critical keeps its own rule (proposed: until dismissed). Manual dismiss always works; expiry never deletes the centre entry; no timer per toast left running after it closes.
- E: Capture settings: `Notify after a screenshot`, `Notify after a recording` (two `KitToggleRow`s, default on). Off skips only those `notify-send` calls; capture, copy and save still happen; errors ("Could not save") still notify (proposed, D-03).

## Constraints

- No runtime writes to repo-linked files (`themes/*/mako/config`). Generated themes are changed only via gruvbox + `mktheme.py`.
- No fixed delays added; the existing 300 ms `refreshDelay` stays unless part C replaces it with a cleaner signal (state why).
- No fragile matching beyond the existing `focusApp` key; no hard-coded app names.
- Settings via `ModuleSettings`; controls per `shell/CLAUDE.md` › UI.

## Decisions for this task (roadmap D-01…D-03)

- **D-01** How the mako toast duration follows the setting. Options:
  (a) mako modes per duration in the theme config (`[mode=toast-10]
  default-timeout=10000`), the shell switches with `makoctl mode -a/-r`;
  (b) a runtime include file in the state dir, if the installed mako supports
  `include=` (verify `man 5 mako`), then `makoctl reload`; (c) the shell
  becomes the notification server (Quickshell `NotificationServer`) and mako
  is dropped — Category C, its own decision record. Recommended: (a), no new
  files, works with theme switching; verify modes combine with `island`/`round`.
  In Island style mako's timeout MUST follow the setting too (or be longer
  than the island's), so a click can still `invoke`; otherwise record the limit.
- **D-02** Click with no action and no window: open the centre (current), or do nothing. Recommended: open the centre.
- **D-03** Capture errors ignore the new toggles. Recommended: yes.

## Approval gate

Parts A, B, E: no gate (Category A) — but B's mako-side behaviour is
reported before changing the mako config. Parts C, D: submit the lifecycle
table and D-01 choice; wait for approval.

## Agents

Nothing delegated.

## Steps

1. Reproduce A and B in Island style (`notify-send -a Test one`, wait > 5 s,
   `notify-send -a Test two`); check Solid style for the same symptoms with mako.
2. A: expiry lives in `IslandService` (the singleton): each toast keyed by
   id with its own deadline, dropped when it passes; `Island.qml` only
   renders the list. Not a per-screen timer in `Island.qml`.
3. B: island click → `makoctl invoke -n <id>` when the notification has a
   default action (needs `actions` in `notifications.sh --list`), else
   `focusApp`, else the centre. Check mako's own click binding in Solid
   (`on-button-left`, default `invoke-default-action`).
4. Report lifecycle table + D-01..D-03 → gate.
5. D: setting + mako side (per D-01) + island `noticeMs` from the setting.
6. C: whatever of the table is not met after 2, 3, 5.
7. E: two toggles in `CaptureSettings.qml`, guards in `CaptureService.qml`.
8. Docs: `shell/README.md` (Notifications / Capture options), architecture row.

## Acceptance

- A: ignored toast + new notification → only the new toast shows (both styles).
- A: one `notify-send` → one toast, one centre row.
- A: a volume OSD during a toast, then a new notification → no old toast returns.
- A: two monitors → the same toasts on each island, expiring together.
- C: `notify-send -r <id>` updates the toast and the centre row, no duplicate (needs `ingest` change).
- B: a notification from an app with a window (e.g. Telegram) focuses it; one
  with a default action runs it; one with neither opens the centre (or per D-02).
- C: every row of the lifecycle table observed.
- D: each duration observed in both styles; change applies to the next toast
  without restart; "Until dismissed" stays until ×; expiry leaves the centre row.
- E: toggles off → screenshot / recording produce no notification, files and
  clipboard still right, other apps' notifications unchanged; errors still notify (D-03).

## Validation

`./install.py check`; `qs log -c shell | grep -E 'ERROR|WARN'`; `makoctl list -j`,
`makoctl history -j`, `makoctl mode`; `notify-send -a Test -A default=Open t b`
(an action); `notify-send -u critical`; `notify-send -r <id>` (replace).

## Regressions

Unseen dot (Folder / island / bell badge); notification centre popup open/clear;
island osd flashes (volume, brightness); island hub and media views while a
toast shows; mako `round` mode with corners; theme switch (mako config of
another theme); mako restart (`state.lastId` logic).

## Forbidden

Replacing mako, restyling toasts or the centre, editing generated themes by
hand, changing Capture's capture/record flow, touching unrelated island views.

## Report

Per README › Report format; include the lifecycle table as implemented and
the D-01..D-03 outcomes.

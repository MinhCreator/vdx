# 08 — Island: Launcher and Keybinds entry; notch bar style

Spec: §9. Shell paths are under `packages/quickshell/shell/`.
Two parts; A is smaller and goes first; B is Category C.

## Read first (both)

`bar/island/*.qml` (all 11), `bar/Bar.qml`, `bar/BarPopup.qml`,
`bar/BarLayout.qml`, `components/PopupManager.qml`, `components/PopupCatcher.qml`,
`apps/launcher/Launcher.qml`, `apps/keybinds/Keybinds.qml`,
`config/ShellSettings.qml` (`barStyle`, `looks`, `clockOpens`, `hubPlayer`),
`apps/shellmanager/BarPage.qml`, `shell/README.md` › Island / Child bars,
`docs/shell/design.md`. Owner's taste notes for the bar: islands rejected as the default look, wanted only as an option.

---

## Part A — Open Launcher and Keybinds from the island

Status: Not started · Category: B · Depends on: 01-A (island toast fix, same file `IslandService.qml`) ·
Gate: interaction concept approved.

Concept to submit (no code):

- Entry points: candidates — hub chips (like module chips), the power view,
  a long-press / right click on the clock, or bar-layout items (`launcher`,
  `keybinds` pseudo-modules placeable in LEFT/RIGHT/HUB). Recommend one, with reasons.
- Does the launcher open **inside** the island (like module popups) or as its
  own surface? Both apps today are separate overlays; inside means reparenting like `BarPopup`.
- Behaviour: repeat click toggles; switching from a module closes it; Esc;
  outside click; keyboard focus (launcher takes it, island returns it);
  conflicts with an open popup / notification flash / OSD; multi-monitor (which island).
- Affected files and any change to Hyprland binds (none expected).

Acceptance (after approval): open, close, switch, Esc, outside click, focus
return, two monitors, Solid style unaffected.

## Part B — Notch bar style

Status: Not started · Category: C · Depends on: A done, 05 phase 1 (where its settings live), 12 ·
Gate: research + UX concept + architecture + migration approved; decision record.

Research and proposal:

- What "notch" adds over Island: e.g. flush with the top edge (no gap, ears /
  inverted corners into the edge), collapsed size, expansion direction, idle content.
  Must not be only a shape change (spec §9.2).
- Audit: bar architecture and styles (`barStyle`, `looks` per style), hub and
  module integration, expansion/collapse states, layer-shell positioning and
  exclusive zone (does the notch reserve space? windows under it?),
  animations (`Motion.island`), input masks and interactive regions,
  focus / outside click, resolutions / scaling / multi-monitor, Hyprland gaps and rounding interplay.
- Reuse vs new: which `bar/island/` pieces are reusable; what needs architecture work.
- Own settings (separate from Island per `ShellSettings.looks`), state
  transitions, size/placement, switching back to Solid/Island without losing layouts.
- Migration: none expected (new style value); verify `layout.json` per style.
- References (record): Apple Dynamic Island (HIG "Live Activities"), Noctalia
  Shell and other Quickshell / AGS configs with a notch, GNOME top bar; layer-shell protocol docs.

Acceptance (after approval): defined in the approved proposal; at least —
switch Solid ↔ Island ↔ Notch at runtime without restart or layout loss;
module popups, hub, OSD, notices work; 1 and 2 monitors, scales 1.0 / 1.2 / 2.0.

---

## Validation

`./install.py check`; `qs log -c shell`; `qs -c shell ipc call island hub|media|power|collapse`;
screenshots by the owner of each state.

## Regressions

Solid style untouched; child islands (`IslandChild.qml`); popups inside island;
Folder module; right click → options; equalizer; media view; unseen dot.

## Agents

None by default.

## Forbidden

Changing the Solid style; changing default bar style; arbitrary control placement (spec §9.1).

## Report

Research format for gates; implementation format after.

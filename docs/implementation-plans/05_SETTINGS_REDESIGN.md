# 05 — Settings (Shell Manager) redesign

Status: Not started · Category: C · Depends on: 12 (findings), 01-D (the
notification settings exist), decision 0001 ·
Gate: **proposal approved before any implementation**; then each slice is reviewed. Spec: §6.
Shell paths are under `packages/quickshell/shell/`.

## Objective

A user finds any setting without knowing the shell's internals; controls and
layout are one system; changing, resetting and migrating settings is predictable.

## Scope

In: every page and section of the Shell Manager (`apps/shellmanager/`), every
`<Name>Settings.qml` it hosts (apps and modules), `ShellSettings`,
`ModuleSettings`, `BarLayout` persistence as far as settings touch it.
Out: features behind the settings (only their options), the bar look, lock-screen
customisation (06 — but 05 decides where Lock lives).

## Read first

`apps/shellmanager/ShellManager.qml` and every `*Page.qml` / `*Section.qml`;
`config/ShellSettings.qml`, `config/ModuleSettings.qml`; all `*Settings.qml`
(`find . -name '*Settings.qml'`); `kit/Kit{Row,ToggleRow,OptionRow,Choices,Select,SliderRow,Input,Label,Header}.qml`;
`shell/CLAUDE.md` › UI + Settings; 12's findings.

## Phase 1 — audit and proposal (no code)

Deliver in `docs/implementation-plans/05_SETTINGS_REDESIGN.md` › Proposal (or a linked file `05_settings_inventory.md` if long):

1. Inventory: every page / group / row / nested option — key, store
   (`settings.json` / `modules.json` id.key / `layout.json`), default, control,
   affected feature, dependencies (shown-only-with), applied-when.
2. Problems: duplicates, contradictions, unclear labels, dead or redundant options, inconsistent controls, hidden dependencies.
3. Per setting: keep / move / merge / split / rename / replace control / remove — each removal and breaking change justified.
4. New information architecture (pages, groups), and the old → new location map.
5. Control and pattern spec (buttons, switches, tabs, sliders, selects, fields,
   descriptions, groups, dialogs, secondary/advanced options, disabled, error,
   defaults) — as a delta to `shell/CLAUDE.md` › UI, not a parallel document (decision 0001).
6. Journeys: at least 10 named common tasks ("change wallpaper", "toast duration",
   "hide a bar module", "lock screen clock", "keyboard layout"…), each with the
   click count before and after; plus a findability check without prior knowledge
   (a labels-only tree test of the new IA: for each task, the path a newcomer picks first).
7. Search: is it justified by the count (≈ 75 shell keys + per-module pages)? If yes, the model (index of labels + hints + page anchors).
8. Apply / save / reset / migrate / validate rules: reset per group and per page?
   Schema version for `settings.json` / `modules.json`; migration of moved keys (like `BarLayout.renamed`).
9. Interactions: settings affecting one feature from two places (e.g. module colours vs Accent › Bar modules; bar look per style `ShellSettings.looks`).
10. Visual clutter: redundant cards, borders, containers per page, and what replaces them (spacing, `KitLine`).
11. Affected files, risks, slices, acceptance per slice.

External references (record each): GNOME Settings / HIG, KDE System Settings
/ HIG, Windows 11 Settings / Fluent, macOS System Settings / Apple HIG,
Android Settings / Material, Noctalia Shell settings. Principles, not copies.

Then: a decision record (`docs/decisions/NNNN-settings-ia.md`), an independent
review if the owner asks for agents, owner approval.

## Phase 2 — implementation (after approval)

Small slices, each one commit, each with its acceptance: e.g. (1) schema
version + migration helper with tests where it is backend logic; (2) new
navigation shell with old pages mapped; (3) page by page moves; (4) control
replacements; (5) search if approved. A prototype page is shown to the owner
before rolling a new look across pages (`shell/CLAUDE.md`: new look is
prototyped on one popup first).

## Requirements (both phases)

- No setting lost: every existing key reachable or migrated, or removed with an approved reason.
- Old state files load (migration tested with a copy of the owner's `by-shell/<id>/` files).
- Applied at once except the documented exceptions.
- `shell open <page>[:<group or app>]` links keep working or are migrated (they are used by right-click "open options").

## Acceptance

Phase 1: items 1–11 present; every row of the inventory has a recommendation;
each named journey has before/after counts and none gets longer without a
stated reason; the tree test result recorded; owner approval recorded.
Phase 2: per slice; the full inventory re-walked at the end.

## Validation

`./install.py check`; `qs log -c shell`; `qs -c shell ipc call shell open <page>`
for every page; right-click options on every bar module; restart persistence.

## Regressions

All pages; `ShellManagerSettings` (start page); bar right-click → options;
app ↔ module links (Apps › Bar module tab); "not installed" greyed modules.

## Agents

Phase 1: none (or one read-only reviewer if the owner asks). Phase 2: only if
the owner asks; one agent per page, files disjoint, primary reviews diffs.

## Forbidden

Phase 1: any code. Phase 2: changes outside the approved slice; feature changes.

## Report

Research format for phase 1; implementation format per slice.

## Proposal

*(empty until phase 1 runs)*

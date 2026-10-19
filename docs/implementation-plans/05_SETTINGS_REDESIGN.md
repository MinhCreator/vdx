# 05 — Settings (Shell Manager) redesign

Status: Phase 1 approved 2026-10-20; phase 2 in progress · Category: C · Depends on: 12 (findings), 01-D (the
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

### Approval (2026-10-20, owner, chat)

Q1–Q5 approved; Q6 (tree test by a newcomer) declined; Q7 changed: the UI rules
move to their own file now (`docs/SHELL_DESIGN_SYSTEM.md`, 0001 option 3), linked
from `CLAUDE.md`. ADR 0002 accepted. Owner: "do everything" — all slices run in one go;
the prototype rule is met by showing the Notifications page with the S4 report.

### Scope (phase 2)

In: slices S0–S7 below, as in Proposal › 11. Out: the tree test; P-17 (keyboard
layouts); 12-C keys and focus (only the token is specified); feature changes.

### Steps

- **S0 docs split.** Move `shell/CLAUDE.md` › UI into `docs/SHELL_DESIGN_SYSTEM.md`
  (verbatim, then the Proposal › 5 delta marked MUST/SHOULD); `shell/CLAUDE.md`
  and root `CLAUDE.md` link it; 0001 Consequences updated; roadmap docs-split row done.
- **S1 schema + migrations.** `scripts/settings_migrate.py <state dir>`: reads
  `settings.json`, `modules.json`, `layout.json`, applies `n → n+1` steps up to
  `VERSION`, writes back atomically only when changed, keeps `<file>.bak`; a file
  that is not JSON is left alone. Migrations: 1 = stamp `version` (+ music / radio
  `titleLength 0` → `show icon`, `titleLength 60`); 2 = `BarLayout.renamed`
  ids in zones / hidden / folder / bars. `supervise.sh` runs it before `qs`. QML
  adapters get `property int version`; the inline Music / Radio fix goes;
  `BarLayout.renamed` stays as the live-reload fallback. Test `tests/test_settings_migrate.py`
  incl. a copy of the owner's state.
- **S2 navigation.** Sidebar per Proposal › 4; pages `lockscreen` (`LockScreenPage.qml`
  hosting `apps/lock/LockSettings.qml`) and `notifications` (`NotificationsPage.qml`
  hosting `modules/notifications/NotificationsSettings.qml`); `resolve` aliases
  (`lock`, `launcher`…, `media`, `apps:lock`, `modules:notifications`); Lock removed from
  Apps (`apps.json` keeps the entry for the launcher / keybind, flagged out of Apps);
  `ShellManagerWindow` comment.
- **S3 bar modules.** Modules page lists every module; an app's module loads its
  `moduleSettings`; Notifications in the list is a link to its page; Apps' Bar module
  tab → a link row; `Bar.qml` `openSettings` → `modules:<id>` (notifications →
  `notifications`); `shell/CLAUDE.md` › An app.
- **S4 rows.** Inventory Rec R / C / regroups; `KitLinkRow` (new kit control);
  link and overridden rows of Proposal › 9; dot colour → `KitSwatches`; System's
  Show rows only with Content.
- **S5 resets.** `KitResetButton` (two-step); page reset for Appearance, Animations,
  Bar (look + behaviour) through `ShellSettings.reset(keys)`; About › Settings: Export,
  Import, Reset everything (`scripts/settings_io.py`, tested).
- **S6 search.** `scripts/settings_index.py` → `config/settings-index.json`;
  `installer/check.py` fails on a stale index; sidebar field and results; test.
- **S7 docs.** README, architecture, testing, roadmap, this file's report; full inventory re-walk.

### Acceptance (phase 2)

Per slice in Proposal › 11; plus: every `shell open` value of the old map opens its
place; right click on every module opens its options; `./install.py check` green;
`qs log -c shell` without new ERROR / WARN; the owner's state loads with every value kept.

### Files edited (expected)

S0: `docs/SHELL_DESIGN_SYSTEM.md` (new), `packages/quickshell/shell/CLAUDE.md`, `CLAUDE.md`,
`docs/decisions/0001-documentation-system.md`, `docs/SHELL_ROADMAP.md`. S1–S6: Proposal › 11
(with `LockScreenPage.qml`, `NotificationsPage.qml`, `kit/KitLinkRow.qml`,
`kit/KitResetButton.qml`, `scripts/settings_io.py` added). S7: `docs/*`, shell README.

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

Phase 1 ran 2026-10-20 (commit `c8c7c90`; no code changed). Approved the same
day (Phase 2 › Approval). Decision record: [0002](../decisions/0002-settings-ia.md) (Accepted).

### 1. Inventory

[05_settings_inventory.md](05_settings_inventory.md): 150 rows (a row there is a
row or a block of like rows), each with key, store, default, control,
shown-only-with, applied-when and a recommendation (item 3 is its Rec column).

### 2. Problems

| # | Problem | Evidence | Fix (item) |
|---|---|---|---|
| P-01 | Where an option lives depends on internals: an app's module is set under Apps › Bar module tab, the others under Modules; Modules lists the app ones as links | `shell/CLAUDE.md` › An app; `ModulesPage.qml:51`; `bar/Bar.qml:30` `openSettings` | one Bar modules page for every module (4) |
| P-02 | Lock screen is an "app" under Apps; nothing on the sidebar says Lock | `apps.json` `lock`; spec §7 | own page (4) |
| P-03 | Notification options are a bar module's page; toast duration is not a bar option | `NotificationsSettings.qml` (Toasts) | own page (4) |
| P-04 | Hidden dependency: the Folder's unseen dot is set on Notifications, the Folder's page shows Bar text only | S `barFolderDot`; `FolderSettings.qml` | Notifications › Bar + a link row on Folder (4, 5) |
| P-05 | Store ≠ page: the audio's auto-pause is in `settings.json` but shown on a module page | `AudioSettings.qml` | kept, findable by search (7); revisit in 09-B |
| P-06 | Two text sizes in two places: the shell's (Appearance › Font) and GTK apps' (Display window) | `FontSection.qml`, `apps/display/Display.qml:84` | cross-links (9) |
| P-07 | Settings that override each other without saying where: Accent › Bar modules disables Equalizer colours; Accent › Window border vs Windows › Frames; Corners also round windows and toasts | `EqualizerSettings.qml`, `CornersService.qml:23-24` | override hint naming the place (5, 9) |
| P-08 | Bar look (icon size, gap, separators) is kept per shape; switching Solid ↔ Island changes them back without a word | `ShellSettings.looks`, `setLook` | hint "Kept for each shape" (9) |
| P-09 | Resets are instant, partial and missing for the shell's own options | U-08; `ModulesPage.qml:108`, `ShellAppsPage.qml` Reset, `BarPage.qml:316` | two-step resets, page reset, Reset everything + export (8) |
| P-10 | System › Show CPU load … rows stay while Bar text is Name or Icon, where they do nothing | `SysmonSettings.qml` (no `visible`) | show only with Content (Rec 135) |
| P-11 | Inconsistent controls: Notifications' dot colour is hand-made dots; Equalizer uses `KitSwatches` | `NotificationsSettings.qml` Repeater of Rectangles | `KitSwatches` (5) |
| P-12 | Wording against the rules: "Date", "User" (not `Show …`), "Rows before scrolling" (not `<Things> shown`), BEHAVIOUR (not OPENING), two rows "Shape", "Controls" row in group CONTROLS | inventory Rec R | renames (3) |
| P-13 | Groups mixing jobs: Packages › Opening holds background checks; Lock › Look holds Monitors; Windows › Arrange in the mode group, not FLOATING | `PackagesSettings.qml`, `LockSettings.qml`, `WindowsPage.qml:110` | regroup (3) |
| P-14 | No search over ~260 rows on 39 option pages | U-12 | search (7) |
| P-15 | No schema version; migrations are ad hoc in pages | D-09; `MusicSettings.qml`, `RadioSettings.qml` `Component.onCompleted`; `BarLayout.renamed` | version + migration step (8) |
| P-16 | Keyboard: no Tab / Space / Enter in Settings | U-05 | focus token in the control spec (5); keys in 12-C |
| P-17 | Gap: no keyboard layout option (layouts, switch key) anywhere in the shell; the Language module shows the layout only | `LanguageSettings.qml`; layouts in Hyprland's input config | out of scope (a feature); named for the roadmap |
| P-18 | Repeated per-surface toggles: "English layout on open" ×4 (Launcher, Keybinds, Themes, Wallpapers), "Close when its window opens" ×5 | inventory 78, 80, 121, 123, 143–147 | K: each surface differs; search finds them all (7). Not merged: a global switch would remove choices |

No duplicate key (one key, two rows) and no dead option was found: every key in the
inventory is read by code. Rows with an empty hint (Module gap, Shadows, Width,
Position) follow the rule "a hint adds something or is left out".

### 3. Per setting

The inventory's Rec column. Summary: no option removed, no key renamed (every move is
a UI move: the stores stay), 23 rows moved, 9 renamed, 4 control replacements,
2 optional merges, 2 removals (the Apps › Bar module tab; the Music / Radio
inline migration once slice 1 has migrations).

### 4. Information architecture

Sidebar, new (★ new page, ✎ changed):

```
LOOK      Appearance      Theme · Accent · Wallpaper · Text ✎ · Cursor · Shape · Controls
          Animations      General · Parts
DESKTOP   Bar             Look · Behaviour · Monitor · Layout
          Bar modules ✎   every bar module (app modules too), one list
          Windows         Mode · <mode> (incl. Floating) · Decoration
          Lock screen ★   Look · Where · On screen · Try it      (06 extends it)
          Notifications ★ Toasts · History · Bar
SYSTEM    Network         Wi-Fi | Hotspot | Ethernet
          Bluetooth       Bluetooth · Connected · Paired · Nearby
SHELL     Apps ✎          an app's own options and window; a link row to its bar module
          About ✎         … · Settings (Export, Import, Reset everything)
```

A search field sits at the top of the sidebar (7). 9 → 11 entries: with the
field, ~510 px of rows and captions against ~460 px of list in the default
600 px window, so the list scrolls (it is a Flickable already) unless the window
grows to ~650 px or captions tighten — decided on the S2 prototype.

Old → new:

| Old | New | `shell open` |
|---|---|---|
| Apps › Lock screen | Lock screen | `lock`, `apps:lock` → `lockscreen` (old names kept by `resolve`) |
| Modules › Notifications (toasts, popup, bell, dot) | Notifications | `modules:notifications` → `notifications` |
| Modules › <module> | Bar modules › <module> | `modules:<id>` kept (page id `modules` stays; only its label changes) |
| Apps › <app> › Bar module tab | Bar modules › <app's module> | `apps:<id>:bar` → `modules:<module>`; `Bar.qml` `openSettings` opens `modules:<id>` for every module |
| Apps › <app> › App tab | Apps › <app> | unchanged |
| Windows › <mode> › Arrange | Windows › Floating › Arrange | — |
| Appearance › Font | Appearance › Text | `appearance:font` kept as an alias |

Rejected: the Bar page with a Modules tab (one more click on every module journey);
module options inside each app's page (P-01 stays); a separate Sound page for two rows.

### 5. Control and pattern spec (delta to `shell/CLAUDE.md` › UI)

Added to `shell/CLAUDE.md` › UI and › Settings in phase 2 (one authority, decision 0001), MUST unless marked:

- **Link row.** A setting kept on another page shows a row there: label = the setting, hint
  `In <Page> › <Group>`, `KitButton { text: "Open"; icon: "arrow-right" }` → `navigate`.
  Used for P-04, P-06, P-07, Wi-Fi / Bluetooth module → their pages, app ↔ its module.
- **Overridden.** A row another setting overrides stays visible, `disabled`, hint
  `Set by <Page> › <Row>` (≤ 29 chars where wide) — today's "Follows the accent colour".
  A row meaningless without its parent hides (the existing rule).
- **Reset.** A reset is two-step: `Reset` → `Sure?` (3 s, then back), as the SAFETY
  toggles' "Sure?". Placed right of the page / item header. Disabled when nothing differs.
- **Colour choice.** Named colours → `KitSwatches`; a free colour → `KitColourField` + picker.
- **Error.** A failed apply shows red `KitText` under the group that failed, wrapped,
  `fontSize - 1` (today's ThemeService / FontService / Wallpaper pattern); it clears on the next success.
- **Pending.** A row whose apply runs (install, Hyprland reload) shows `busy` on its button or a `KitSpinner`; the rest of the page stays usable.
- **Focus (for 12-C).** One token `Theme.focusRing`: a 2 px `foreground2` outline at
  `radiusControl`, shown on keyboard focus only. Space toggles a switch, arrows move
  Choices, Enter activates. SHOULD: `Accessible.name` = the row's label.
- **Advanced.** No "Advanced" fold (groups are short); rarely used groups go last on the page (Files: Terminal, Picker, Actions).
- **Header subtitle** SHOULD hold at most three parts; the group labels already carry their values.

### 6. Journeys

Clicks from an open Shell Manager on its first page (Appearance); a drag counts 1;
scrolling is not counted. Before = today, after = the IA above.

| # | Task | Before | After | Note |
|---|---|---|---|---|
| J1 | Change the wallpaper picture | 2 | 2 | Source Image, a thumb |
| J2 | Toast duration | 3 | 2 | Notifications, a chip |
| J3 | Hide a bar module | 2 | 2 | Bar, drag to HIDDEN |
| J4 | Lock screen clock 12h | 3 | 2 | Lock screen, a chip |
| J5 | Keyboard layout | — | — | no such option (P-17) |
| J6 | Animations off | 2 | 2 | |
| J7 | Clock shows seconds | 3 | 3 | right click on the clock: 2 both |
| J8 | Change theme | 2 | 2 | a theme, Apply |
| J9 | Shell text size | 1 | 1 | |
| J10 | Accent on, a colour | 3 | 3 | |
| J11 | Window gaps | 2 | 2 | |
| J12 | Clipboard popup without search field | 4 | 3 | Bar modules, Clipboard, switch |
| J13 | Pause music when a video plays | 3 | 3 | search: type + Enter + switch |
| J14 | Unseen dot colour | 3 | 2 | |
| J15 | Launcher width | 3 | 3 | |
| J16 | Undo every look change | — (delete `settings.json` by hand) | 3 | About, Reset everything, Sure? |

None gets longer.

**Tree test (labels only, heuristic).** For each task, the first sidebar entry a newcomer
picks reading the new labels only. Done by the author of the proposal, so a bias toward
its own labels: a real test needs someone who has not seen the shell (open, 6).

| Task | First pick | Right? | Before: first pick → right? |
|---|---|---|---|
| J1 wallpaper | Appearance | yes | Appearance yes |
| J2 toast duration | Notifications | yes | Modules? Apps? — no |
| J3 hide a module | Bar | yes | Bar yes |
| J4 lock clock | Lock screen | yes | Appearance or Apps — no |
| J5 keyboard layout | Bar modules (Language) | no option | same |
| J7 clock seconds | Bar | no → Bar modules next | Bar → no |
| J12 clipboard search field | Apps (Clipboard) | no → link row to Bar modules | Apps yes |
| J13 pause music | search | yes with search | Modules › Audio — guess |
| J14 dot colour | Notifications | yes | Folder? — no |
| J11 gaps | Windows | yes | Windows yes |

Result: 7 of 10 first picks right (before 4 of 10); J12 loses its direct hit and is
covered by the link row; J7 and J13 need the link or search.

### 7. Search

Justified: 11 pages, ~260 rows, 39 option pages; GNOME, KDE, Windows 11, macOS and
Android Settings all put search at the top of navigation.
Model: an index of rows (label, hint, group, page, jump target, module / app id)
built from the QML by `scripts/settings_index.py` into `config/settings-index.json`
(literal `label:` / `hint:` / `KitLabel` texts; dynamic labels such as an SSID left
out); `./install.py check` fails on a stale index. The field at the top of the sidebar
matches label + hint + group, words in any order; results replace the section list
(`label · Page › Group`), arrows + Enter or a click → `navigate(page, target)`, the
row flashes once (`Motion.controls`). Esc clears. No new dependency.

### 8. Apply / save / reset / migrate / validate

- Apply: at once, as now; exceptions unchanged (pickers with a preview → Apply; fields → Enter).
- Reset per item (module, app, a monitor's layout: exists, becomes two-step), per page for
  the S-backed pages (Appearance, Animations, Bar look + behaviour), and Reset everything
  (About › Settings: S + M + L, not W / system state; Theme, font, cursor keep theirs and the page says so).
- Export / Import: About › Settings writes or reads one JSON with `settings`, `modules`,
  `layout` (picker via `FilesService.pick`); Import validates the version and unknown keys are dropped.
- Schema version (D-09): `version: 1` in `settings.json`, `modules.json`, `layout.json`.
  Migrations are a list `n → n+1` in `scripts/settings_migrate.py`, run by
  `scripts/supervise.sh` before `qs` starts, on copies, written back only on success
  (the old file kept as `.bak`); tested in `tests/` with a copy of the owner's
  `by-shell/<id>/` files. QML keeps reading old keys as a fallback for one release
  (a live reload after `update` runs without the supervisor). The Music / Radio
  `titleLength 0` fix and `BarLayout.renamed` become migrations 1 and 2.
- Validate: a value outside a control's model falls back to the default (today's
  `ModuleSettings.get` fallback; S values get the same check in the migration step).

### 9. Interactions

| Two places | Rule |
|---|---|
| Accent › Bar modules ↔ Equalizer colour (and every module's active colour) | Equalizer row disabled, hint `Set by Accent › Bar modules` + link |
| Accent › Window border ↔ Windows › Frames | each shows a link row to the other |
| Appearance › Corners ↔ windows and toasts | hint "Also windows and toasts" |
| Bar look ↔ Bar › Shape | hint "Kept for each shape" on icon size and gap |
| Appearance › Text size ↔ Display › GTK apps | link rows both ways |
| Folder ↔ Notifications › Unseen dot | link row on Folder |
| Appearance › Theme / Wallpaper ↔ Themes / Wallpapers modules (popups) | different jobs (setting vs quick switch); module pages get a link row to Appearance |
| Lock › Background Wallpaper ↔ Appearance › Wallpaper | hint "As Appearance › Wallpaper" |
| Bar › Main monitor ↔ the theme preview and Apps' place | one source (`BarLayout.mainScreen()`), no change |
| Capture › Notifications ↔ Notifications page | link rows (the toggles stay with Capture) |

### 10. Visual clutter

Measured, not redesigned: Appearance has 7 groups and 6 `KitLine`s (rule-conform);
framed boxes are only pickers with a preview (theme, font, cursor) and the bar preview —
kept. Found: the Appearance header subtitle repeats three group values (≤ 3 parts, 5);
Network › Connection shows 6 one-fact rows (optional: one two-column facts block,
`KitText` pairs, no frame); Apps and Modules each draw a framed list beside a scrolling
pane — after the merge one of the two such pages goes. Any look change is prototyped
on one page (Notifications, the new one) before rollout.

### 11. Affected files, risks, slices

Slices, one commit each, in order:

| Slice | What | Files | Acceptance |
|---|---|---|---|
| S1 | Schema version + migrations (D-09) | `scripts/settings_migrate.py` (new), `scripts/supervise.sh`, `config/ShellSettings.qml`, `config/ModuleSettings.qml`, `bar/BarLayout.qml`, `tests/test_settings_migrate.py` (new), `components.toml` if a link is added | owner's state copied → migrated → shell starts, every value kept; tests green; a bad file is left untouched |
| S2 | Navigation: new sidebar, page ids, `resolve` aliases; Lock screen + Notifications pages (rows moved as they are) | `apps/shellmanager/ShellManager.qml`, `ShellManagerWindow.qml`, new `LockPage.qml` / `NotificationsPage.qml` (hosting the existing `LockSettings.qml` / `NotificationsSettings.qml`), `ShellAppsPage.qml`, `apps/apps.json` (lock), `bar/Bar.qml` | every old `shell open` value opens the right place; right click on every module |
| S3 | Bar modules: app modules' options moved; Apps link rows | `ModulesPage.qml`, `ShellAppsPage.qml`, `bar/Bar.qml`, `shell/CLAUDE.md` › An app | inventory rows 143–148 reachable from Bar modules and by right click |
| S4 | Renames, regroups, control fixes, link / overridden rows (prototype first: Notifications page) | the `*Settings.qml` with Rec R/C/M-group, `kit/` (link row) | owner approves the prototype; rows per inventory |
| S5 | Resets two-step, page reset, About › Settings (export / import / reset everything) | `ModulesPage.qml`, `ShellAppsPage.qml`, `BarPage.qml`, `AboutPage.qml`, `config/*Settings.qml` | reset → defaults; export → import round trip equal |
| S6 | Search | `scripts/settings_index.py` (new), `config/settings-index.json` (new), `installer/check.py`, `ShellManager.qml`, test | every task of 6 found by a word of its label |
| S7 | Docs: `shell/CLAUDE.md` UI + Settings delta (5), README, architecture | docs | 0001 split question answered |

Risks: S2/S3 change `shell open` targets used by right click (aliases kept, tested per
module); S1 touches the files every start reads (copies + `.bak`, tests on the owner's
files); search index drift (check fails); a convention change in `shell/CLAUDE.md` ›
An app (owner approval, Q1). 06 may start after S2 (its page exists).

### References

From prior knowledge of the published guidelines; not re-fetched in this session.
Principles taken, nothing copied.

- GNOME HIG (Preferences) and GNOME Settings — apply at once, no Apply button; search
  above the sidebar; few options, grouped. Used: 7, 8.
- KDE HIG and System Settings — sidebar of categories with search; per page
  Defaults / Reset; "highlight changed settings". Used: 8 (page reset), 7.
- Windows 11 Settings (Fluent) — search at the top of navigation; "Related settings"
  links on a page. Used: 5 (link row), 7.
- macOS System Settings (Apple HIG) — sidebar with search that highlights the match;
  a pane per area (Lock Screen and Notifications are their own panes). Used: 4, 7.
- Android Settings (Material) — preference groups with summaries; dependent preferences
  disabled with a reason; search across all settings. Used: 5 (overridden), 7.
- Noctalia Shell settings — a Quickshell desktop shell with one settings window, a tab
  per area incl. Lock screen and Notifications next to Bar. Used: 4.

### Open questions for the owner

- Q1. Every bar module's options in Bar modules, an app's included (changes the
  `shell/CLAUDE.md` › An app convention). Recommended: yes.
- Q2. Lock screen and Notifications as their own DESKTOP pages. Recommended: yes.
- Q3. Search (S6) in this redesign. Recommended: yes, last slice.
- Q4. Migrations in Python run by `supervise.sh` (tested in `tests/`) rather than in QML. Recommended: yes.
- Q5. Reset everything + export / import in About › Settings. Recommended: yes.
- Q6. A real tree test by someone new to the shell before S2. Recommended: optional.
- Q7. 0001 split (UI rules into `docs/SHELL_DESIGN_SYSTEM.md`): not yet — the delta of 5
  adds ~15 lines to `shell/CLAUDE.md`. Recommended: revisit after S7.

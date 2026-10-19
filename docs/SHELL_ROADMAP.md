# Shell roadmap

All shell project work: phases, status, order, dependencies, approvals.
Requirements: `CLAUDE_SHELL_PROJECT_MASTER_INSTRUCTIONS.md` (repo root; §
numbers below). Process and how to run a task:
[implementation-plans/README.md](implementation-plans/README.md).
Architecture: [SHELL_ARCHITECTURE.md](SHELL_ARCHITECTURE.md). Testing:
[SHELL_TESTING.md](SHELL_TESTING.md). Decisions: [decisions/](decisions/README.md).

Updated: 2026-10-19 (planning pass; task 12 findings; no code changed).

## Phases

Cat = category (A local fix · B medium · C redesign / new app). Gate = what
must be approved before implementation.

| # | Task | Cat | Depends on | Gate | Status |
|---|---|---|---|---|---|
| [00](implementation-plans/00_REPOSITORY_AUDIT.md) | Repository audit | — | — | — | Done (planning), partial coverage — see its "Not inspected" |
| [01](implementation-plans/01_NOTIFICATION_SYSTEM.md) | Notifications: A reappear, B click, E capture toggles | A | — | — | Implemented, partially verified (B: no default action in island style) |
| [01](implementation-plans/01_NOTIFICATION_SYSTEM.md) | Notifications: C lifecycle, D toast duration | B | 01 A/B | lifecycle table + D-01..03 | Implemented, partially verified (visual check open) |
| [02-A](implementation-plans/02_FILEPICKER_AND_AUDIO_FIXES.md) | Filepicker stale listing | A | — | — | Implemented, partially verified (not reproduced; `open()` refresh added) |
| [02-B](implementation-plans/02_FILEPICKER_AND_AUDIO_FIXES.md) | Duplicate microphone | A/B | — | device model (D-05) | Implemented, partially verified (model A; headset switch not tested live) |
| [03](implementation-plans/03_DISPLAY_AND_WALLPAPER_FIXES.md) | Wallpaper after Display change and at login | A | — | D-04 if Hyprland bg changes | Implemented, partially verified (re-login and Display check open; D-04 open) |
| [04](implementation-plans/04_BLUETOOTH_LABEL_FIX.md) | Bluetooth "Rescan" | A | — | — | Implemented, partially verified |
| [12](implementation-plans/12_PRODUCT_WIDE_UX_AUDIT.md) | Product-wide UX audit (findings) | C | 00 (best after 01–04) | findings approved | Findings done (17); slice 1 (U-03, U-04, U-17) implemented and verified; 12-A (default bar, overflow) and 12-B (supervisor, relock) implemented, partially verified; 12-J (U-18 leaked listeners) implemented and verified; 12-D part 1 (idle polling) implemented, partially verified; 12-D part 2 (memory) measured only (windows ~78 MB; lazy loading left as an option); 12-E (missing hardware) implemented, partially verified; next 12-F |
| [05](implementation-plans/05_SETTINGS_REDESIGN.md) | Settings redesign — phase 1 proposal | C | 12, 0001 | proposal | Not started |
| [05](implementation-plans/05_SETTINGS_REDESIGN.md) | Settings redesign — phase 2 slices | C | 05 p1 approved, 01-D | per slice | Not started |
| [06](implementation-plans/06_LOCKSCREEN_CUSTOMIZATION.md) | Lock screen section + customisation | B/C | 05 p1, 03 | proposal | Not started |
| [07-A](implementation-plans/07_FILE_MANAGER_IMPROVEMENTS.md) | Files: storage home page | B | 02-A | proposal | Not started |
| [07-B](implementation-plans/07_FILE_MANAGER_IMPROVEMENTS.md) | Files: custom sidebar | B | 02-A, 07-A | proposal | Not started |
| [07-C](implementation-plans/07_FILE_MANAGER_IMPROVEMENTS.md) | Files: fewer frames | A | 02-A | prototype screen | Not started |
| [08-A](implementation-plans/08_BAR_ISLAND_AND_NOTCH_MODE.md) | Island: Launcher + Keybinds entry | B | 01-A | interaction concept | Not started |
| [08-B](implementation-plans/08_BAR_ISLAND_AND_NOTCH_MODE.md) | Notch bar style | C | 08-A, 05 p1, 12 | research + concept + ADR | Not started |
| [09-A](implementation-plans/09_MUSIC_SUBSYSTEM.md) | Yandex Music fully optional | A/B | — | file moves between components | Not started |
| [09-B](implementation-plans/09_MUSIC_SUBSYSTEM.md) | Generic MPRIS player module (+ rename) | B/C | 09-A | naming + UX + model | Not started |
| [09-C](implementation-plans/09_MUSIC_SUBSYSTEM.md) | Yandex Music app | C | 09-B | full proposal + ADR | Not started |
| [11](implementation-plans/11_CAMERA_ARCHITECTURE.md) | Capture ("camera") architecture proposal | C | D-11 (a restructure after it: 01-E) | proposal | Not started |
| [10](implementation-plans/10_TORRENT_CLIENT.md) | Torrent client | C | 05 p1, 01; 07-A optional | design + engine ADR | Not started |
| [13](implementation-plans/13_FINAL_INTEGRATION_AND_REVIEW.md) | Integration, regressions, docs | B | each milestone | — | Not started |
| D1 | Docs: mark `shell/CLAUDE.md` UI/Settings rules MUST/SHOULD/MAY; add UI-state rules (§3.3 item 5, §14.2, §16) | B | 0001 accepted | owner reviews the diff | Not started |
| — | Docs: guidelines/design system split (0001 option 3) | — | 05 p1 approved | 0001 | Researched/proposed; awaiting approval |

## Dependency map

```
00 ─┬─ 01 A/B/E ──┬── 01 C/D ───────────────┐
    │             ├── 08-A ── 08-B ◄────────┤
    │                                       │
    ├─ 02-A ── 07-A ── 07-B ; 02-A ── 07-C  │
    ├─ 02-B                                 │
    ├─ 03 ─────────────── 06 ◄──────────────┤
    ├─ 04                                   │
    ├─ D-11 ── 11 (restructure after 01-E)  │
    ├─ 09-A ── 09-B ── 09-C                 │
    └─ 12 ── 05 p1 ─┬─ 05 p2 ◄── 01-D       │
                    ├─ 06, 08-B, 10 ◄───────┘ (10 also needs 01)
                    └─ 0001 split
13 after each milestone
```

## Recommended order and milestones

**M1 — stability (Category A, parallel-safe):** 04 → 01 A/B/E → 03 → 02-A → 02-B.
04, 03, 02-A, 02-B touch disjoint files: any order, or two in one session.
01, 08-A and 09-A all touch `bar/island/IslandService.qml`: one at a time.
Each plan lists "Files edited (expected)"; check it before running two at once.

**M2 — audit and settings design:** 12 → 01 C/D → D1 (rule marking) → 05 phase 1 (+ approval) → 0001 split decision.
05 phase 1 MAY approve an early "Lock section" slice so 06 can start before the rest of 05.

**M3 — features on approved patterns:** 05 phase 2 slices → 06 → 07-A/B/C → 08-A → 09-A/B.

**M4 — Category C new things:** 08-B, 09-C, 11, 10 (each starts with its own research gate).

13 after M1, M2, M3, M4.

Order changes against spec §3.3, with reasons:

- 12 (UX audit) runs before 05 and is findings-only (spec §3.3 puts it third — kept;
  §13 reads later — the audit's findings are an input of 05).
- 01 is split: C/D need a decision (D-01) and settings patterns; A/B/E don't.
- 09-A moved into M1-parallel: it is installer/gating work, independent of design.
- 11 needs 01-E first (Capture notifications) and the D-11 answer.
- 06 after 05 phase 1: the spec's "move Lock out of Shell Apps" is an IA decision of 05.

## Decisions awaiting the owner

| ID | Question | Recommendation | Task |
|---|---|---|---|
| D-01 | How mako's toast duration follows the setting (mako modes / runtime include / own notification server) | mako modes in the theme config | 01 |
| D-02 | Click on a notification with no action and no window | open the centre | 01 |
| D-03 | Capture error notifications ignore the new toggles | yes | 01 |
| D-04 | Hyprland's own background = theme colour, to cover the moment before the shell | yes, if visible after the cache fix | 03 |
| D-05 | Input list model for jack ports with unknown presence | list only when plausible; active-but-unplugged shown with a hint | 02-B |
| D-06 | Agents: spec §12.2/§15 wants Haiku implementers and an Opus reviewer; owner rule is no agents unless asked per task | ask per task; default none | all |
| D-07 | Accept decision 0001 (docs system; no separate guidelines/design-system files yet) | accept | docs |
| D-08 | The "Rescan" label also before any scan ran | keep as asked | 04 |
| D-09 | Settings schema version + migrations (none today) | add in 05 phase 2 first slice | 05 |
| D-10 | Rename module `music` (Yandex) and give the generic player the name | `yandex` + `player` (or `music`) | 09-B |
| D-11 | "Camera" in the spec = Capture (screen capture)? A webcam app is not in the repo | confirm Capture | 11 |
| D-12 | Torrent engine | after 10 phase 1 research | 10 |
| D-13 | Notch: a third `barStyle` or a variant of Island | after 08-B research | 08-B |
| D-14 | The spec file is untracked at the repo root; plans cite it by § | commit it as `docs/SHELL_SPEC.md` (and fix the references) | docs |

## Spec conflicts and doubtful points

| Spec | Issue | Resolution |
|---|---|---|
| §5.1 D "setting through the existing settings architecture" | Two toast surfaces; mako's config is a repo-linked, theme-generated file | D-01; never write the linked file at runtime |
| §5.1 C vs A/D | Lifecycle overlaps both | one lifecycle table in 01 after A/B, implemented with D |
| §5.1 B "activate the app" | History items have no actions; mako may have dropped the notification | `makoctl invoke` while alive, else window focus, else D-02 |
| §5.2 | Bug may be fixed by `d14e745` (2026-10-18) | reproduce first; close as "not reproduced" with evidence if so |
| §5.4/§5.5 | Two bugs, one cause (awww cache) | one task 03 |
| §5.6 | "Rescan" before any scan | D-08 |
| §7 vs §6 | Moving Lock is part of the Settings IA | 06 after 05 phase 1 |
| §10.1 | Already a component (default off) | 09-A covers the remaining coupling |
| §11 "camera" | No webcam in the repo | D-11 |
| §12.2, §15 | Agents vs the owner's standing rule | D-06 |
| §3.1 / §14.1 file set | Duplicates `shell/CLAUDE.md` / `CONVENTIONS.md` | decision 0001 |
| §2.2 "no arbitrary delays" | Existing delays (300 ms refresh, wallpaper wait loop) | ranked by 12, not fixed ad hoc (12: not ranked as findings — no user-visible effect found; U-07 covers the polls) |

## Spec coverage

| Spec | Requirement | Task |
|---|---|---|
| §4.1 | Inventory and map | 00, SHELL_ARCHITECTURE |
| §4.2 | External research with sources | 05, 06, 07, 08-B, 09-B/C, 10, 11, 12 (each "References") |
| §5.1 A–E | Notifications | 01 |
| §5.2 | Filepicker | 02-A |
| §5.3 | Microphones | 02-B |
| §5.4, §5.5 | Wallpaper | 03 |
| §5.6 | Rescan | 04 |
| §6 (12 audit items + 8 deliverables) | Settings | 05 |
| §7 | Lock section, grid, show/hide, blur, wallpaper, colours, follow theme | 06 |
| §8.1–8.3 | Files home, sidebar, frames | 07 A–C |
| §9.1, §9.2 | Island entries, notch | 08 A–B |
| §10.1–10.3 | Music | 09 A–C |
| §11 | Capture/camera | 11 |
| §12.1–12.2 | Torrent | 10 |
| §13 | UX audit | 12 |
| §14 | Docs system | 0001, this file, README of plans |
| §15 | Agents and review | plans README › Agents, D-06 |
| §16 | Testing and regressions | SHELL_TESTING, each plan |
| §17 | Reporting and statuses | plans README |
| §19 | Definition of success | 13 |

## Updating this file

Update order and rules: [decision 0001](decisions/0001-documentation-system.md) › Update order (the one authority).

## Independent review (2026-10-19)

One read-only agent (type Plan, model Opus, asked for by the owner's task),
given the spec, all plan files, the rules files and criteria (completeness,
dependencies, assumptions, boundaries, docs, risks). Not an owner approval.

| # | Finding | Outcome |
|---|---|---|
| 1 | §5.4 cause is `display.py:134` `awww restore`, not only the daemon; `--no-cache` alone would not fix it | accepted, verified in code; 00 and 03 fixed |
| 2 | 09-A and 01 both edit `IslandService.qml` | accepted; M1 note, "Files edited" lines |
| 3 | 01-A expiry per screen in `Island.qml` is racy (one Island per bar, OSD replaces flash) | accepted; expiry in `IslandService`, new acceptance cases |
| 4 | `replaces_id` updates dropped by `ingest` (`id > lastId`) | accepted; 01 findings + acceptance |
| 5 | Island style: mako expires invisibly, `invoke` loses its target | accepted; D-01 note |
| 6 | No early MUST/SHOULD/MAY pass (§3.3 item 5, §14.2) | accepted; task D1 |
| 7 | Architecture lacks theme pipeline and install flow | accepted; sections added |
| 8 | Spec file untracked | accepted as D-14 (owner decides) |
| 9 | `IslandService` does not use `MusicService` | **rejected**: it does, `IslandService.qml:52` (`MusicService.cover`), `:59` (`MusicService.setActive`) |
| 10 | Plans after a gate lack phase-2 steps | accepted; README rule |
| 11 | 05 acceptance not observable; §6 clutter item; §10.2 reuse visuals | accepted; 05 and 09 updated |
| 12 | 11 needs nothing from 01-E; 06 waits on all of 05 p1; 10's 07-A | accepted; rows changed |
| 13 | Update discipline in three places; UI states missing in testing; row 00 overclaims | accepted; one authority (0001), testing rows, status changed |

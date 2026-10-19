# 0002 — Settings information architecture

Status: Accepted (2026-10-20, owner, chat; Q6 declined, Q7 changed)
Phase: [05_SETTINGS_REDESIGN.md](../implementation-plans/05_SETTINGS_REDESIGN.md) › Proposal

## Context

The Shell Manager (`packages/quickshell/shell/apps/shellmanager/`) has 9 pages
and ~260 option rows on 39 pages ([inventory](../implementation-plans/05_settings_inventory.md)).
Where an option lives follows the code's split, not the user's task: an app's bar
module is set under Apps, other modules under Modules; Lock screen is an app;
toast duration is a bar module's option (12: U-12). Resets are instant and
partial, the shell's own options have none, and there is no schema version (U-08, D-09).

## Options

1. Keep the pages; add search only. Cheap; the "where" problem stays for browsing.
2. Bar page with a Modules tab; Apps keeps app modules. One click more on every
   module journey; P-01 stays.
3. Pages by the user's area: Bar modules holds every module (apps' too); Lock
   screen and Notifications become pages; Apps holds apps' own options; search,
   two-step resets, export / import, a schema version with migrations.

## Decision: option 3

As in 05 › Proposal › 4, 5, 7, 8. No key is renamed and no option removed: every
move is in the UI; stores stay. Old `shell open` names keep working through
`ShellManager.resolve`.

## Consequences

- `shell/CLAUDE.md` › An app changes: an app's module is set in Bar modules.
- `shell/CLAUDE.md` › UI / Settings gain the control delta (05 › Proposal › 5).
- New: `scripts/settings_migrate.py` (run by `supervise.sh`), `scripts/settings_index.py`
  + `config/settings-index.json` (checked by `./install.py check`), tests.
- 06 builds on the Lock screen page; 08-B and 10 add rows to the pages of option 3.
- Revisit 0001's split after 05 S7.

## Sources

Repository (paths in the inventory); GNOME HIG, KDE HIG, Windows 11 Settings,
macOS System Settings, Android Settings, Noctalia Shell — principles, from prior
knowledge, listed in 05 › References.

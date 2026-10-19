# 10 — Torrent client

Status: Not started · Category: C · Depends on: 05 phase 1 (settings
patterns), 01 (notification lifecycle), 07-A (storage/destination patterns, optional) ·
Gate: full design approved before code; decision record for the engine. Spec: §12.
Shell paths are under `packages/quickshell/shell/`.

## Objective

A torrent app that looks and behaves like the shell's other apps, with the
download engine outside the UI.

## Scope

In: research, design, then (after approval) an app `apps/torrent/`, a backend
script, an optional bar module, a component in `components.toml` (default off).
Out: implementing BitTorrent; search/indexer sites; RSS (unless approved later).

## Read first

`shell/CLAUDE.md` (A module / An app / UI / Settings), `apps/apps.json`,
an app with a backend and a window as the pattern: `apps/backup/` +
`scripts/backup.py` + `tests/test_backup.py` (progress lines, one reply);
`apps/packages/` (long jobs); `modules/notifications/` (after 01);
`docs/repo/recipes.md` › Add a component, Add a program a config uses.

## Phase 1 — research and design (no code)

- Engine candidates (evaluate, don't presume): transmission-daemon (RPC),
  qBittorrent-nox (Web API), aria2 (JSON-RPC), libtorrent-rasterbar Python
  bindings driven by an own script. For each: Arch package availability
  (`pacman -Si`), maintenance, licence, security (RPC auth, bind to
  localhost / unix socket), resource use, feature coverage, failure modes
  (daemon down, port blocked, disk full), how the shell talks to it (script ↔ engine).
- Feature set v1 from the spec's candidates: add magnet / `.torrent` (also as
  the `x-scheme-handler/magnet` and `application/x-bittorrent` handler — a
  `.desktop` file), queue + status, progress and rates, pause/resume/remove
  (with/without data), seeding controls (ratio/time), file selection,
  destination (`FilesService.pickFolder`), speed/connection limits, errors and retry, notifications on completion.
- Deliver: UX flows, screens and states (empty, adding, downloading,
  seeding, paused, error, engine missing), component reuse plan (kit),
  data/state model, the engine interface (script commands, JSON shapes),
  settings (`ModuleSettings` keys), dependency evaluation, test strategy
  (`tests/test_torrent.py` against a fake RPC), phased plan.
- References (record): the chosen engine's official docs; BEP 9 (magnet),
  BEP 3; existing clients' UX (Transmission GTK, qBittorrent, Fragments) for patterns only.

## Phase 2 — implementation (after approval)

Phased per the approved plan; first slice = backend script + tests, then the
window, then the bar module, then notifications and handlers.

## Agents

The spec (§12.2) asks for Haiku-level implementation agents after approval.
The owner's standing rule is no agents unless asked per task (README › Agents).
If the owner asks: bounded slices with disjoint files (e.g. agent 1 =
`scripts/torrent.py` + `tests/test_torrent.py` to the approved interface;
agent 2 = one view QML against a fixed service API); the primary agent owns
the service, integration, review, checks and acceptance.

## Acceptance

Phase 1: every deliverable above, engine decision record, owner approval.
Phase 2: per the approved plan; at least add → download → pause → resume →
complete → seed → remove on a legal test torrent (e.g. an Arch ISO magnet),
engine-down state, restart persistence.

## Validation

`./install.py check`; `python -m unittest tests.test_torrent`; `qs log -c shell`;
`./install.py components add torrent` / `remove`.

## Regressions

Component gating ("not installed"); notification centre; Files picker; mime handlers of other apps.

## Forbidden

Writing a protocol implementation; exposing the engine RPC beyond localhost; code before approval.

## Report

Research format (phase 1); implementation format per slice.

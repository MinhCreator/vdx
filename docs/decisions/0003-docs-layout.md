# 0003 — Docs layout: an index and one topic per file

Status: Accepted (2026-10-20, owner). Supersedes 0001's file layout.

## Context

After the audit, the Settings redesign and the UX audit the docs were a pile:
`CONVENTIONS.md` (356 lines, read whole before any change), plans of 200–700
lines kept after they were done, the spec untracked at the repo root. The
owner got lost in them; agents loaded far more than a change needs.

## Decision

- `docs/README.md` is the index: one line per topic → its file.
- One short topic per file: `docs/repo/*` (was `CONVENTIONS.md`),
  `docs/shell/{architecture,design,testing}.md`, `docs/power.md`.
- `docs/roadmap.md` holds only what is open: tasks, owner checks, questions.
- `docs/tasks/` holds open task plans only; a finished plan is deleted, its
  results go into the topic files, its leftovers into the roadmap.
- The spec is `docs/spec.md` (was untracked; old D-14).
- Kept from 0001: one authority per rule; MUST / SHOULD / MAY; English, terse.
  The update order is in `docs/tasks/README.md`.

## Consequences

Old paths (`CONVENTIONS.md`, `docs/SHELL_*.md`, `docs/implementation-plans/`)
live in git history only; decision records keep them as written.

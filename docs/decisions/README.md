# Decisions

One file per significant architecture or design decision:
`NNNN-short-name.md`, numbered in order, never renumbered.

| # | Decision | Status |
|---|---|---|
| [0001](0001-documentation-system.md) | Documentation system for the shell project | Superseded by 0003 |
| [0002](0002-settings-ia.md) | Settings information architecture | Accepted |
| [0003](0003-docs-layout.md) | Docs layout: index + one topic per file | Accepted |
| [0004](0004-yandex-music-app.md) | Yandex Music app: scope, playback and backend | Accepted |
| [0005](0005-capture-freeze-first.md) | Capture: freeze first, a toolbar on the overlay | Accepted |
| [0006](0006-music-app.md) | Music app: one player, Yandex Music and radio as sections | Proposed |

Open questions that will become records are listed in the roadmap
([roadmap.md › Open questions](../roadmap.md#open-questions)).

## Statuses

- **Proposed** — written, not approved by the owner. Code does not depend on it.
- **Accepted** — the owner approved it (date, and where: chat or commit).
- **Superseded by NNNN** — kept for history; the header links the new one.
- **Rejected** — kept with the reason.

An independent review (agent or human) is recorded in the file but is not an approval.

## Template

```markdown
# NNNN — Title

Status: Proposed | Accepted (YYYY-MM-DD) | Superseded by NNNN | Rejected
Phase: <tasks/NN_….md>

## Context
The problem and the facts from the repository (paths).

## Options
1. … — pros, cons.
2. …

## Decision
What was chosen and why.

## Consequences
What changes, migrations, what becomes harder, follow-ups.

## Sources
Documents consulted (official / opinion), what each was used for.
```

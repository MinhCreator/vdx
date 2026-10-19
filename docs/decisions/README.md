# Decisions

One file per significant architecture or design decision:
`NNNN-short-name.md`, numbered in order, never renumbered.

| # | Decision | Status |
|---|---|---|
| [0001](0001-documentation-system.md) | Documentation system for the shell project | Proposed |

Open questions that will become records are listed in the roadmap
([SHELL_ROADMAP.md › Decisions awaiting the owner](../SHELL_ROADMAP.md#decisions-awaiting-the-owner)).

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
Phase: <implementation-plans/NN_….md>

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

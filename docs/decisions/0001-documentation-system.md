# 0001 — Documentation system for the shell project

Status: Accepted (2026-10-20, owner; D-07)
Phase: [00_REPOSITORY_AUDIT.md](../implementation-plans/00_REPOSITORY_AUDIT.md)

## Context

The spec (`CLAUDE_SHELL_PROJECT_MASTER_INSTRUCTIONS.md` §3.1, §14) proposes
`docs/SHELL_{PROJECT_ROADMAP,ARCHITECTURE,DEVELOPMENT_GUIDELINES,DESIGN_SYSTEM,TESTING_AND_RELEASE}.md`.
The repo already has binding rules: `CONVENTIONS.md` (repo, installer,
commits) and `packages/quickshell/shell/CLAUDE.md` (shell code, UI tokens,
controls, wording, motion — a design system in all but name). The owner
wants terse English docs and no duplicates (one shell README; "no new docs
unless asked").

## Options

1. Create all five spec files; move rules out of `shell/CLAUDE.md`.
   Clear names; but a big move of binding rules, and agents read
   `shell/CLAUDE.md` by default (root `CLAUDE.md` points to it).
2. Keep the existing rule files as the authority; add only what is missing
   (roadmap, architecture, testing, decisions, task files, process).
3. Option 2 now; split `shell/CLAUDE.md` › UI into `docs/SHELL_DESIGN_SYSTEM.md`
   only when task 05 adds the Settings control specification and the file
   gets too long to read every session.

## Decision: option 3

| Spec document | In this repo | Role |
|---|---|---|
| SHELL_PROJECT_ROADMAP | `docs/SHELL_ROADMAP.md` (new) | phases, status, dependencies, approvals |
| SHELL_ARCHITECTURE | `docs/SHELL_ARCHITECTURE.md` (new) | runtime, layers, stores, feature map, boundaries |
| SHELL_DEVELOPMENT_GUIDELINES | `CONVENTIONS.md` + `packages/quickshell/shell/CLAUDE.md` (existing) | binding rules |
| SHELL_DESIGN_SYSTEM | `docs/SHELL_DESIGN_SYSTEM.md` (split out of `shell/CLAUDE.md` › UI on 2026-10-20, task 05) | tokens, controls, wording, Settings pages |
| SHELL_TESTING_AND_RELEASE | `docs/SHELL_TESTING.md` (new) + CONVENTIONS › Before a commit / push | verified commands, manual scenarios |
| decisions/README | `docs/decisions/` (new) | one record per decision |
| implementation-plans/* | `docs/implementation-plans/` (new) + its README (process, checklists, agents) | one executable task per file |
| — | `packages/quickshell/shell/README.md` (existing) | what exists, for users |

Rules:

- **One authority per rule.** Others link to it. Code rules: `shell/CLAUDE.md`; UI rules: `docs/SHELL_DESIGN_SYSTEM.md`;
  repo / installer / commits: `CONVENTIONS.md`; process: `implementation-plans/README.md`.
- **MUST / SHOULD / MAY.** New rules are written with these words; existing
  imperative rules in `shell/CLAUDE.md` count as MUST until a task marks them
  (no mass rewrite now).
- **Status words** in the roadmap: the four of the spec §17.
- **Update order** at the end of a phase: its plan file (status, report) →
  roadmap row → architecture / `shell/CLAUDE.md` / README if the change made
  them wrong → a decision record if a choice was made → `SHELL_TESTING.md` if
  validation changed. Same commit as the code.
- English, terse, facts only; proposals say "proposed".

## Consequences

- Agents keep reading `shell/CLAUDE.md` first; root `CLAUDE.md` gets one line
  pointing to the roadmap.
- `CONVENTIONS.md` "No new docs unless asked" stays; these docs exist because
  the owner asked (2026-10-19).
- Revisit when task 05 is approved (split of the UI section). Done 2026-10-20:
  the owner asked for the split with 05's approval; `docs/SHELL_DESIGN_SYSTEM.md`
  is the one authority for UI rules, `shell/CLAUDE.md` › UI links it.

## Sources

Repository only; no external sources.

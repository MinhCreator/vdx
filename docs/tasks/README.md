# Tasks

One file per open task; a finished one is deleted (README › Rules for these
docs). Order, status and approvals: [roadmap.md](../roadmap.md). Requirements:
[spec.md](../spec.md) (§ numbers refer to it). This file is the authority for
the process; code and repo rules: [docs/README.md](../README.md).

## Running a task in a new Claude Code session

Paste, with the file name:

```
Run docs/tasks/NN_NAME.md (part X if it has parts).
Read it, docs/tasks/README.md and the files it lists under
"Read first". Follow its approval gate: stop and report at the gate.
```

The agent then:

1. Reads the plan, this file, `CLAUDE.md`, `packages/quickshell/shell/CLAUDE.md`,
   the topic files the plan needs (`docs/README.md`), and its "Read first".
2. Checks the roadmap: dependencies done, gate approved where required.
   Not met → reports and stops.
3. Re-checks the plan's facts in code (files move; the plan is a snapshot).
   A wrong fact is fixed in the plan file, not silently worked around.
4. Works in the plan's order; stops at the gate with a report.
5. Ends with the report (below) and the docs updated in this order, same
   commit as the code: the plan (status, report) → the roadmap row → topic
   files the change made wrong (architecture, design, README, `shell/CLAUDE.md`)
   → a decision record if a choice was made → `shell/testing.md` if validation
   changed. When the task is done: what is left goes to the roadmap, the plan
   file is deleted.

After a gate is approved, the plan file gets its phase-2 Scope, Steps,
Acceptance and "Files edited" written in **before** any code (spec §3.1).

One task per session is the norm (context cost). Two tasks share a session
only when the roadmap marks them parallel-safe and they touch no common file.

## Task categories (§2.5)

| | What | Before implementation |
|---|---|---|
| **A** local fix | a bug with a bounded root cause | inspect, short plan in the report; go |
| **B** medium change | new setting, changed behaviour | audit + UX/affected files; owner approval when user behaviour or a convention changes |
| **C** redesign / new app | Settings, notch, music, torrent, camera, UX audit | research, proposal, decision record, independent review, owner approval |

The plan file says its category. A task never takes an approval-dependent
decision silently: it writes the question in the report.

## Checklist — before changing code (MUST)

- [ ] Relevant files read in full where they are edited; callers found (`grep`).
- [ ] Current vs intended behaviour written down; root cause has evidence.
- [ ] Related settings, stores, events, components named.
- [ ] Existing tests and checks for the area known (`docs/shell/testing.md`).
- [ ] Regressions listed (the plan's checklist + the shared scenarios).
- [ ] No new dependency, public interface change or settings migration without a line of reason in the plan or a decision record.

## Checklist — new feature (MUST, plus the code rules)

- [ ] Script → service → face/popup split (`shell/CLAUDE.md` › A module / An app).
- [ ] Registered: `BarLayout.modules` + `ModuleFaces`, or `apps/apps.json`; component in `components.toml`.
- [ ] Settings through `ShellSettings` or `ModuleSettings`, default in the module, applied without restart.
- [ ] Controls, wording, tokens per `docs/shell/design.md`; one prototype screen approved before rollout (visual work).
- [ ] Missing binary / service / hardware handled: a state in the UI, no log errors.
- [ ] Component off → "not installed", nothing breaks.
- [ ] Docs made wrong by the change fixed (README, CLAUDE.md, architecture).

## Checklist — acceptance (MUST)

- [ ] Every acceptance criterion of the plan checked, with evidence (command output, log, screenshot by the owner).
- [ ] Full diff reviewed; only intended files changed.
- [ ] `./install.py check` green; `ruff check`, shellcheck clean.
- [ ] `qs log -c shell` without new ERROR / WARN.
- [ ] Regression checklist walked; what was not tested is written down with why.
- [ ] `docs/repo/commits.md` › Before a commit: security / tests / docs answered to the owner.

## Agents (§12.2, §15)

Owner's standing rule: **no subagents unless the owner asks for them in that
task** (stated 2026-10-16; an explicit ask in one task does not carry over).
When asked:

- Available in this environment (2026-10-19): the Agent tool with
  `opus` / `sonnet` / `haiku` model options and read-only types (`Explore`,
  `Plan`). Check again before relying on it.
- Review agent: read-only type, gets the spec section, the plan, the audit
  evidence and explicit criteria; its findings are answered in the plan
  (accepted / rejected with reason). A review is not an owner approval.
- Implementation agent: only after the plan's gate is approved; given exact
  files it may edit, the interfaces, rules files and acceptance tests; no two
  agents on one file. The primary agent reviews every diff, runs the checks,
  and owns the result. "It builds" is not acceptance.
- A plan's "Agents" section says what may be delegated; default is nothing.

## Report format (§17)

Implementation:

1. Problem and root cause (evidence).
2. Changes (files, summary).
3. Why this approach (alternatives).
4. Validation actually run, with results.
5. Regressions checked.
6. Open issues, not tested, blocked.

Research / proposal: sources and why; repository findings; method and
criteria; alternatives; recommendation; risks, dependencies, gate; the next
task to run.

## Status words (§17)

Implemented and verified · Implemented, partially verified ·
Researched/proposed; awaiting approval · Blocked, deferred, or not implemented
— plus *Not started* and *In progress* for the roadmap.

## Plan file shape

Header (status, category, depends on, gate) · Objective · Scope (in / out) · Files edited (expected) ·
Read first · Findings so far · Requirements · Constraints · Approval gate ·
Agents · Steps · Acceptance · Validation · Regressions · Forbidden · Report.

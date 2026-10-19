# 13 — Integration, regression review, docs reconciliation

Status: Not started · Category: B · Depends on: every phase that was
implemented (runs at the end, and MAY run after each milestone M1–M4 of the roadmap) ·
Gate: none to run; findings that need fixes become tasks. Spec: §3.3 item 13, §14.3, §16, §19.

## Objective

The shell as a whole still works, the docs tell the truth, and every roadmap
item has an honest status.

## Steps

1. `git log` since the last review: list every phase commit; map to roadmap rows.
2. Automated: `./install.py check`, `ruff check`, shellcheck (see `shell/testing.md`),
   `tests/fresh-machine.sh defaults` and with the music/torrent components (owner agrees: slow).
3. Manual: the shared regression scenarios (`shell/testing.md`) + each phase's regression list.
4. Docs: every statement in `shell/architecture.md`, `shell/README.md`,
   `shell/CLAUDE.md`, roadmap and decision records matches the code (grep
   names); proposals still marked proposed; superseded decisions marked.
5. Spec coverage: walk the spec §5–§14 and tick each requirement against a
   roadmap row with evidence; anything missing → a new row.
6. Statuses: set each row to one of the four §17 states with a reason for blocked/deferred.

## Acceptance

All checks green or failures recorded; every spec requirement mapped; docs
diff reviewed; final report delivered.

## Agents

An independent read-only reviewer (spec §15) if the owner asks: it gets the
spec, the roadmap, the diff since the last review and these criteria.

## Forbidden

New features; refactors; rewriting docs wholesale (only the smallest authoritative fix).

## Report

What improved for users and why (evidence only); per-row status table; open risks; next steps.

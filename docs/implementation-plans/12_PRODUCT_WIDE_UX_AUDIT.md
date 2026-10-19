# 12 — Product-wide UX and customisation audit

Status: Not started · Category: C (findings only; fixes are new tasks) ·
Depends on: 00; best after 01–04 (so known bugs are not re-reported) ·
Gate: the ranked findings are approved before any of them is implemented. Spec: §13, §4.2–4.3.

Runs **before** 05 (its findings feed the Settings redesign), although the
spec lists it later in §13 — see the roadmap's order note.

## Objective

A candid, ranked list of what makes the shell hard for someone who is not its
author, with evidence, and proposed fixes for approval.

## Scope

In: install and first run (`./install.py install`, wizard), Shell Manager
discoverability, customisation breadth and conflicts, screen sizes / scaling /
multi-monitor, missing hardware and services, keyboard navigation and
accessibility, performance (idle CPU / memory of `qs`), error recovery,
settings reset and migration, optional integrations (Yandex Music, VPN, AI,
VirusTotal off), docs and extension points.
Out: implementing fixes; visual redesign proposals beyond a sentence each (05/08 own those).

## Read first

`docs/SHELL_ARCHITECTURE.md`, `00_REPOSITORY_AUDIT.md`, `shell/README.md`,
`shell/CLAUDE.md` › UI and Settings, `CONVENTIONS.md` › wizard/setup,
`installer/wizard.py`, Shell Manager pages list (`apps/shellmanager/ShellManager.qml`).

## Method

1. Inventory first-run path: `tests/fresh-machine.sh defaults` result + wizard screens (read code; run if the owner agrees — ~840 MB download).
2. Combination matrix (at least): bar style × monitors (1, 2, different scales);
   theme colour vs custom vs image wallpaper × multi-monitor; accent on/off × corners;
   island with open module + notification + OSD; audio with no device / BT only;
   each optional component off; runtime change of each Shell Manager page's options; reset to defaults (does a reset exist?).
3. Keyboard: can every app/popup be used without a mouse (Tab, Esc, Enter)? Focus visible?
4. Performance: `ps -o rss,pcpu -C qs` idle and with popups; polling timers inventory (`grep -rn 'interval:'`).
5. External references only where a finding needs one (GNOME HIG, KDE HIG,
   Apple HIG, Material, Fluent, WCAG 2.2 for contrast/focus; Noctalia Shell for Linux-shell parity). Record each source used.

## Output

`docs/implementation-plans/12_PRODUCT_WIDE_UX_AUDIT.md` › Findings (this
file): a table — id, finding, evidence (path / steps / screenshot by owner),
user impact, severity (S1 blocker … S4 polish), effort (S/M/L), risk,
dependencies, recommendation, proposed task (existing plan or new).

## Acceptance

Every area in Scope has at least a checked line (finding or "no issue, how
checked"); every finding has evidence; nothing marked good without a check; sources listed.

## Agents

May use one read-only review agent for a second opinion on the ranking, only if the owner asks.

## Forbidden

Code changes; editing other plans except to link a finding.

## Report

Research format (README). Top 10 findings in the chat; the full table here.

## Findings

*(empty until the task runs)*

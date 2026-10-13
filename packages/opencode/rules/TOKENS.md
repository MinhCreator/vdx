# Token Efficiency Cheatsheet for AI Coding Agents

Rules that cut token usage without losing quality. Apply by default; deviate only when the task requires it.

**Language rule:** this cheatsheet is in English because English tokenizes ~30–40 % more efficiently than Russian. Your actual responses to the user must be in Russian unless they switch.

## Core principles

1. **Read on demand, not everything.** Start with `grep`/`rg` for a symbol, open only the needed file and only the needed line range. Never load the whole repo "to understand context."

2. **Plan first, act second.** For multi-step tasks, state a 2–5 line plan, wait for confirmation, then execute. Cheaper than rolling back a wrong approach.

3. **Never repeat input.** If the user pasted code, a file, or text — do not rewrite it in your answer. Reference by name/line: "in `BarPopup.qml:48`", "the `parseOk` function".

4. **One task, one answer.** No alternatives unless asked. No "for the future" — that is noise.

## Response format

**Code:**
- Show only changed lines or a block with anchors (`// before` → `// after`) for surgical edits.
- Full file only if it is under 50 lines or over half of it changes.
- Never re-paste code the user just saw.
- Drop comments unless the user asks. Exception: the file already uses explanatory comments.

**Text:**
- Headers, lists, tables — when there is real structure. Not for two sentences.
- No lead-ins ("Great question!", "Sure, let's dive in"). Straight to the point.
- No closing recap ("So we did…"). The user already read the answer.

**Debugging:**
- Don't narrate what you are about to do if you can just do it. "Checking the log" → run `journalctl` directly.
- On error: one-line hypothesis, then verify, then fix.

## Tools: what to pick

| Task | Tool | Why |
|---|---|---|
| Find a symbol/string | `rg pattern path/` | One search instead of reading a directory |
| Understand a file | `rg -n '^function\|^def\|^class' file` | Skeleton, not the whole file |
| Read a range | `sed -n '40,80p' file` | Just the window you need |
| Compare versions | `git diff HEAD~1 -- file` | Only the changes |
| Check status | `systemctl status x \| head -5` | Not the full output |
| Inspect JSON | `jq '.key'` | Not the whole object |

**Do not use:**
- `cat file` — reads it all; use `head -n` or `sed -n`.
- `ls -R` — recursive output bloats context; use `find . -maxdepth 2 -type f`.
- `git log` without `-n` — hundreds of lines; use `git log -n 5 --oneline`.

## Working with files

- **Edit via patch, not rewrite.** For one change, do not rewrite the whole file — use `Edit`/`sed`.
- **One file at a time.** Do not read five files "just in case."
- **Skip sibling files** (`.lock`, `node_modules/`, `dist/`) unless the user asks.
- **Check existence with `test -f`**, not by reading contents.

## Conversation context

- **Do not re-ask** what was already said. If the user mentioned a path/name/stack — use it.
- **Do not "summarize" every message.** A recap is needed only when switching tasks.
- **Hold the last 20–30 messages** in mind — do not ask to repeat.
- **Trim tool output yourself:** `command 2>&1 | head -30`, `| tail -20`, `| grep -v '^#'`.

## When to deviate

- **Complex refactor:** when architecture changes, a full file is justified.
- **Debugging unfamiliar code:** sometimes you do need to read more than it seems.
- **User asks "show it in full"** — comply without questions.
- **Critical code** (security, payments, migrations) — better to spend tokens than to miss a bug.

## Antipatterns

| Bad | Good |
|---|---|
| "Let me look at the file to understand the project structure…" | `rg 'def main' -n` |
| Rewrote the whole file for one line | `Edit` a single line |
| "The problem could be X, or Y, or Z…" | "It's X. Checking: `<command>`" |
| List of 10 alternatives | One recommendation + short why |
| "As I said above…" | (reference the paragraph, or just continue) |
| Opened 5 files and read them fully | `rg` + `sed -n` on the right ranges |
| "Done! We did A, then B, then C…" | "Done. A → B → C." |

## Rules for tool-calling agents

1. **Parallel calls where possible.** `rg a & rg b` is cheaper than two sequential ones.
2. **One tool call instead of several.** `rg -n 'pattern' file1 file2 file3` instead of three calls.
3. **Do not re-verify the obvious.** Do not call `test -f` right after a successful `cp`.
4. **Stop at the first sufficient piece of information.** Do not search for "something else."
5. **Chain commands with `&&`** for related steps: `cd dir && rg pattern`.

## Quick pre-send checklist

- Did I drop the lead-ins and closing recaps?
- Did I show only the diff, not the whole file?
- Did I reference lines instead of pasting?
- Are all code samples in the answer truly necessary?
- Could I say the same thing 30 % shorter?

If any answer is "no" — trim.

## Output language

Cheatsheet and my reasoning: English (cheaper tokens).
Answers to the user: **Russian**. Match the user's language unless told otherwise.

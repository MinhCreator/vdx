# Docs

One topic per file. Read the line you need, open only that file. For people
and agents. A rule that is in the way is changed in its file.

## Repo and installer

| Need | File |
|---|---|
| Where things live, what the installer does with each | [repo/layout.md](repo/layout.md) |
| `./install.py` commands | [repo/commands.md](repo/commands.md) |
| Components (`components.toml`), who owns a file | [repo/components.md](repo/components.md) |
| Machine profile, per-machine Hyprland settings | [repo/machine.md](repo/machine.md) |
| Wizard, setup, update, doctor, uninstall; changing the installer | [repo/installer.md](repo/installer.md) |
| How to: change a config, add a file / program / component / `/etc` file / secret / theme / bar module | [repo/recipes.md](repo/recipes.md) |
| Themes and colours | [repo/themes.md](repo/themes.md) |
| File headers, comments, submodules | [repo/style.md](repo/style.md) |
| Commits, checks before a commit / push, branches | [repo/commits.md](repo/commits.md) |
| Laptop power (TLP, GPU) | [power.md](power.md) |

## Shell (Quickshell)

| Need | File |
|---|---|
| Code rules: modules, apps, settings, restart, QML pitfalls | [packages/quickshell/shell/CLAUDE.md](../packages/quickshell/shell/CLAUDE.md) |
| How it is built: process, layers, stores, feature map | [shell/architecture.md](shell/architecture.md) |
| UI rules: tokens, controls, wording, Settings pages | [shell/design.md](shell/design.md) |
| Checks, manual scenarios, regressions | [shell/testing.md](shell/testing.md) |
| What exists, for users | [packages/quickshell/shell/README.md](../packages/quickshell/shell/README.md) |

## Project work

| Need | File |
|---|---|
| What is open, in what order; owner checks; open questions | [roadmap.md](roadmap.md) |
| How to run a task; checklists; report format | [tasks/README.md](tasks/README.md) |
| One open task | `tasks/NN_*.md` |
| Why something is the way it is | [decisions/](decisions/README.md) |
| The original requirements (cited as §) | [spec.md](spec.md) |

## Asking an agent

Rules load by themselves (`CLAUDE.md` → this index), so a request says only
what to do, where, and when to stop. Templates (any language):

A task that has a plan:

```
Run docs/tasks/NN_NAME.md (part X).
```

A bug or a small change without a plan:

```
<what is wrong, or what I want; where I saw it>.
Find the topic files for this area in docs/README.md and read them, then the code.
Tell me the cause and the plan in a few lines before changing anything.
```

Something big or new:

```
I want <X>. Write a plan in docs/tasks/ (shape: docs/tasks/README.md),
add it to the roadmap and stop for my approval. No code yet.
```

Useful endings: "commit when done" · "don't commit" · "stop after the
research" · "show me one screen first".

## Rules for these docs

- English, terse, facts only; proposals say "proposed".
- One authority per rule; other files link to it, never copy.
- A file stays one topic and short; a long one is split, with a line here.
- A finished task's plan is deleted (git keeps it): what it built goes into
  the topic files, what is left goes into the roadmap.
- New rules use MUST / SHOULD / MAY; plain imperative rules count as MUST.
- A change that makes a doc wrong fixes it in the same commit.
- No new file without a line in this index.

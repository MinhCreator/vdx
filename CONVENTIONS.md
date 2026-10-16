# Conventions

Rules for people and agents. If a rule is in the way, change it here.

## Where things go

| What | Where | How it gets installed |
|---|---|---|
| A program's config | `packages/<pkg>/` | linked into `~/.config/<pkg>/` |
| A file in `~` | `home/` | linked into `~/` |
| Anything theme-dependent | `themes/<theme>/<pkg>/` | shadows the package file |
| Wallpapers | `wallpapers/<theme>/`, `wallpapers/common/` | read by the Shell Manager |
| A file in `/etc` | `system/<path>` | copied by `./install.py system install` |
| A required program | `deps/pacman.txt`, `deps/aur.txt` | `./install.py deps` |
| A secret's template | `templates/secrets/*.example` | `./install.py bootstrap` |
| Notes | `docs/` | — |

- One package per program. A non-default install path goes in
  `packages/<pkg>/package.toml` (`dir`, `skip`, `[files]`).
- A package holds the config; a theme holds only what depends on its colours.
  The colour files themselves (hypr `colors.lua`, kitty `colors.conf`, …) live
  in the themes alone, so a theme is always active: `.theme`, else gruvbox.
- Real package names in `deps/` (`mihomo-bin`, not `mihomo`);
  check with `./install.py deps --check`.

## Themes

- One theme for the whole desktop; colours by role
  ([themes/gruvbox/README.md](themes/gruvbox/README.md)). A hex outside a theme
  is a bug (imported themes of btop may keep their own shades).
- A new theme: its colours in `themes/mktheme.py`, then
  `python3 themes/mktheme.py <name>`. Generated themes are not edited by hand.
- Switch: `./install.py theme set <name>` or the Shell Manager.

## File style

- First line: `<program> — <what this file is>` as a comment, then a link to the
  docs if there is one; scripts put it after the shebang. QML: a comment right
  before the root object. Python: the module docstring.
- Section markers: `# Section` in configs, `// ---- name ----` in QML,
  `-- ---- name ----` in Lua.
- Comments explain why or what is not obvious; everything in English.
- Files a program rewrites itself (`btop.conf`, `gh/config.yml`) keep its format.

## Links

- Files are linked one by one: a new file is invisible until `./install.py link`.
- After any structural change `./install.py verify` must report `all … ok`.
- `.theme` is local state, not in git (gruvbox when absent).

## Secrets

- Never committed: tokens, keys, passwords, `hosts.yml`, the rendered
  `mihomo/config.yaml`, `providers/`, personal data.
- All real secret files are in the private repo `private/` (gitignored here),
  which `private/secrets.py` copies to their places: `status`, `restore`,
  `collect`. The file list is `private/manifest.json`.
- Keys live in `~/.config/secrets/env` (from `templates/secrets/env.example`).
- A new secret: a `*.example` template, a `.gitignore` line, a row in the
  README's Secrets table, and an entry in `private/manifest.json`.

## Submodules

`packages/nvim`, `packages/scripts/yandex-music`, `packages/scripts/radio`,
`packages/scripts/vpn` change in their own repositories; here only
`git submodule update --remote <path>` and a `<scope>: bump submodule` commit.

## Commits

`scope: what changed` — English, lowercase, imperative, no full stop, ≤ ~72
characters; a body says why. Scopes: a package name (`hypr`, `quickshell`, …),
`themes`, `scripts`, `system`, `installer`, `docs`, `repo`.

- One commit is one whole change: a feature, a fix, a refactor, a cleanup. Not
  a single line or a small tweak split off from the change it belongs to.
- No WIP, fixup, "misc" or "tidy" subjects. A half-done change waits until it
  is finished.
- The body says why in a few short lines when the subject does not.
- Co-authors: one `Co-Authored-By:` trailer per model that helped write the
  change, for example `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
  Agents add their own model's trailer.
- Nothing broken: `./install.py check` (links, syntax of every file, themes,
  deps, the shell's registry and icons); `qs log -c shell` without errors for
  the shell.

```
scope: what changed

Why, in a few short lines when the subject does not say it.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
```

## Branches

`main` is the default. Published history is not rewritten except by the
owner's decision, with a backup (`git bundle create … --all`) first. No hooks:
commands that check out old commits run with `git -c core.hooksPath=/dev/null`
and end with `./install.py link`.

## Before a push

```
./install.py check
./install.py system status
git status
git log --oneline -5
```

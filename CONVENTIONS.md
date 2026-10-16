# Conventions

How this repo works and how to change it. For people and agents: read it
before changing anything; if a rule is in the way, change it here.

## How it works

Arch Linux + Hyprland. `install.py` (Python stdlib, code in `installer/`)
puts the repo on a machine:

| Piece | Where | What happens to it |
|---|---|---|
| Config of a program | `packages/<pkg>/` | each file symlinked into `~/.config/<pkg>/` |
| A file in `~` | `home/` | symlinked into `~/` |
| Theme-dependent file | `themes/<theme>/<pkg>/` | shadows the package file of the same path |
| File in `/etc` | `system/<path>` | copied (never linked) by `system install`, sudo |
| What can be installed | `components.toml` | one entry = one checkbox: packages, links, `/etc` files, bar modules |
| This machine | `.machine.toml` (local) | detected hardware, `[override]`, selected components |
| Active theme | `.theme` (local) | gruvbox when absent |
| Secrets | `private/` (private repo, gitignored) | copied to `$HOME` by `private/secrets.py` |
| Secret templates | `templates/secrets/*.example` | `./install.py bootstrap` |
| Wallpapers | `wallpapers/<theme>/`, `wallpapers/common/` | read by the Shell Manager |
| Installer tests | `tests/` | `./install.py check tests`; run before every install |
| Notes | `docs/` | — |

### Components

`components.toml` lists everything that can go on a machine: dotfiles
packages (`kitty`, `quickshell`), features (`vpn`, `yandex-music`) and
hardware (`gpu-nvidia`, `laptop`). Its header documents every field.

- `link`, `deps`, `system`, `setup` act only on the **selected** components.
  The selection is `[components] selected` in `.machine.toml`
  (`./install.py components add|remove <name>`). A machine that never chose
  has everything on, except hardware that wasn't detected.
- A file belongs to the component whose `links` path matches it longest:
  `zsh` owns `zsh/`, `vpn` owns `zsh/functions/vpn`. Theme overlays follow
  their package. A file nobody owns is linked everywhere and fails `check`.
- `requires` can't be switched off; `suggests` is ticked along, can be
  unticked; `default = false` keeps personal things off for a new machine;
  hardware has `auto` terms (`gpu:nvidia`, `laptop`, `hybrid`, `asus`,
  `quirk:<name>`) from `./install.py machine`.

### The machine profile

`./install.py machine detect` reads `/sys` and `/proc` (GPUs, battery,
backlight, codecs, outputs, DMI) into `[hardware]` of `.machine.toml`.
Wrong values are fixed in `[override]`, which detect keeps. Code:
`installer/detect.py` (readers take a fake root for tests).

`[hypr]` holds this machine's Hyprland settings; `link` writes them to
`~/.config/hypr/machine/{gpu,input,monitors}.lua` (real files, marked as
generated — never edit them, edit the profile):

```toml
[hypr]
gpu_env = "nvidia"                  # nvidia | none; default nvidia only without an iGPU
layouts = "us,ru"
layout_options = "grp:caps_toggle"
monitors = [{ output = "eDP-1", mode = "1920x1080@144.00", position = "0x0", scale = 1.2 }]
workspaces = { eDP-1 = "1-10" }     # first of each range is the output's default
```

The repo's hypr config loads them through `components/machine.lua` and has a
default for each (preferred mode on every output, `us`, no GPU env).

### Preflight

`setup` and `deps` first run the environment check (Arch, not root, tools),
`check components`, `check hypr` and the tests; one problem stops them before sudo.

## Recipes

Every recipe ends with `./install.py check` all green.

### Change a config

Edit the file in `packages/<pkg>/` (it is what `~/.config` points to).
Colours never go there: see Themes.

### Add a config file

1. Put it in `packages/<pkg>/…` (or `home/` for `~`).
2. `./install.py link` — a new file is invisible until linked.
3. If the package is new, add a component (below) or a path to an existing
   component's `links`; `check components` names any file nobody owns.
4. A non-default target: `packages/<pkg>/package.toml` —
   `dir = "~/.config"`, `skip = ["notes.txt"]`, `[files] "a.toml" = "~/x.toml"`.

### Add a program a config uses

Its real package name (`mihomo-bin`, not `mihomo`) goes in `pacman` or `aur`
of the component that needs it; shared names may repeat across components.
`check components` asks pacman whether it exists and is in the right list.

### Add a component

```toml
[name]
group = "apps"                 # core desktop terminal editor apps music network ai personal hardware
about = "One line for the wizard"
default = false                # personal / heavy things are off for a new machine
requires = ["quickshell"]
pacman = ["pkg"]
aur = ["pkg-bin"]
links = ["pkg"]                # paths under packages/, or "home/<file>"
submodules = ["packages/scripts/x"]
modules = ["x"]                # bar modules it brings
system = ["etc/…"]             # files under system/
services = ["x.service"]       # system units; user_services for --user
secrets = ["x/token"]          # keys of private/manifest.json
hint = "a manual step, printed, never done"
```

Unknown fields, missing paths, loops in `requires` and modules that no
component brings all fail `check components`.

### Add a file in /etc

1. `system/etc/…` mirrors `/`; list it in a component's `system`.
2. `@KEY@` is replaced by a text value of the machine profile
   (`@BATTERY@` → `BAT0`); `check` rejects unknown keys. Write placeholders
   only where the value goes — a comment would get it substituted too.
3. Hardware-specific registers (codec pins, …) are a quirk: an entry in
   `QUIRKS` of `installer/detect.py` with every condition (board, codec at
   its address), a hardware component with `auto = ["quirk:<name>"]`.
4. Agents don't run sudo: give the owner `./install.py system install`.
   It shows a diff of each changed file and asks first.
5. What runs after a copy: `SYSTEM_APPLY` (tmpfiles, tlp) and pacman hooks
   in `installer/system.py`; modprobe applies after a reboot.
6. Boot changes (kernel cmdline, mkinitcpio) are never automated: a `hint`.

### A setting that differs per machine

Hardware-bound values (GPU env, outputs, layouts) never go in the repo's
config. Hyprland: a key in `[hypr]` rendered by `installer/hypr.py` into
`machine/<name>.lua`, loaded with `require("components.machine").load("<name>")`
after the repo's default; a test in `tests/test_hypr.py`. `check hypr` runs
`Hyprland --verify-config` on copies of the config with and without
`machine/`, so both a configured and a new machine must parse.

### Add a bar module or a shell app

Follow `packages/quickshell/shell/CLAUDE.md`, then put the module id in
`modules` of the component it depends on (`quickshell` for core ones).
`link` writes `~/.local/state/dotfiles/components.json` (`installer/shell.py`):
modules whose components are all off. `BarLayout` keeps them off every bar
(their saved place stays) and the Shell Manager lists them as not installed.

### Add a secret

1. A template `templates/secrets/<name>.example` when someone else can fill it.
2. A `.gitignore` line for its path in the repo, if it lives there.
3. The file in `private/` and an entry in `private/manifest.json`
   (`"dir/file": "~/target"`); `private/secrets.py collect` copies it in.
4. Its key in `secrets` of the component using it.
5. A row in the README's Secrets table.

Keys live in `~/.config/secrets/env` (from `templates/secrets/env.example`).
Never committed: tokens, keys, passwords, `hosts.yml`, the rendered
`mihomo/config.yaml`, `providers/`, personal data.

### Add a theme

Its colours in `themes/mktheme.py`, then `python3 themes/mktheme.py <name>`.
Generated themes are never edited by hand; `check themes` finds stale ones.

### Change the installer

Code in `installer/` (one module per concern: `paths`, `ui`, `model`, `links`,
`theme`, `system`, `deps`, `setup`, `check`, `menu`, `cli`, `detect`,
`machine`, `components`, `choose`, `preflight`, `hypr`, `shell`). Stdlib only, Python ≥ 3.11.
A behaviour change comes with a test in `tests/` (fake `/sys` trees in
`tests/fakesys.py`; nothing touches the real machine). Compare the output of
`status`, `verify`, `system status`, `deps --check` before and after a
refactor.

## Themes

- One theme for the whole desktop; colours by role
  ([themes/gruvbox/README.md](themes/gruvbox/README.md)). A hex outside a theme
  is a bug (imported themes of btop may keep their own shades).
- A package holds the config; a theme only what depends on its colours. The
  colour files themselves (hypr `colors.lua`, kitty `colors.conf`, …) live in
  the themes alone, so a theme is always active.
- Switch: `./install.py theme set <name>` or the Shell Manager.

## File style

- First line: `<program> — <what this file is>` as a comment, then a link to the
  docs if there is one; scripts put it after the shebang. QML: a comment right
  before the root object. Python: the module docstring.
- Section markers: `# Section` in configs, `// ---- name ----` in QML,
  `-- ---- name ----` in Lua.
- Comments explain why or what is not obvious; everything in English.
- Files a program rewrites itself (`btop.conf`, `gh/config.yml`) keep its format.

## Submodules

`packages/nvim`, `packages/scripts/yandex-music`, `packages/scripts/radio`,
`packages/scripts/vpn` change in their own repositories; here only
`git submodule update --remote <path>` and a `<scope>: bump submodule` commit.
Each is listed in `submodules` of its component and cloned only with it.

## Commands

| Command | |
|---|---|
| `./install.py` | menu with a status overview |
| `setup [-y]` | preflight, packages, submodules, links, secrets, plugins, `/etc` |
| `components [list\|add\|remove <name>…]` | what is on this machine |
| `machine [show\|detect]` | the hardware profile |
| `link` · `verify` · `status` | links: create · check · per package |
| `deps [--check]` | missing packages of the selected components |
| `system status\|install` | `/etc` files of the selected components |
| `check [group…]` | links, syntax, themes, components, tests, hypr, shell, repo |
| `theme list\|current\|set <name>` | themes |
| `secrets [status\|restore]` | `private/` |

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
- Nothing broken: `./install.py check`; `qs log -c shell` without errors for
  the shell. Check `git diff --cached` for secrets.

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

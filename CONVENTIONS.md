# Conventions

How this repo works and how to change it. For people and agents: read it
before changing anything; if a rule is in the way, change it here.

## How it works

Arch Linux + Hyprland. `install.py` (Python ≥ 3.11, stdlib only, code in
`installer/`) puts the repo on a machine:

| Piece | Where | What happens to it |
|---|---|---|
| Config of a program | `packages/<pkg>/` | each file symlinked into `~/.config/<pkg>/` |
| A file in `~` | `home/` | symlinked into `~/` |
| Theme-dependent file | `themes/<theme>/<pkg>/` | shadows the package file of the same path |
| File in `/etc` | `system/<path>` | copied (never linked) with sudo, after a diff |
| What can be installed | `components.toml` | one entry, one checkbox: packages, links, `/etc` files, units, bar modules |
| This machine | `.machine.toml` (local) | detected hardware, `[override]`, `[hypr]`, the chosen components |
| Active theme | `.theme` (local) | gruvbox when absent |
| Secrets | `private/` (private repo, gitignored) | copied to `$HOME` by `private/secrets.py` |
| Secret templates | `templates/secrets/*.example` | seeded by `setup` (`bootstrap`) |
| Wallpapers | `wallpapers/<theme>/`, `wallpapers/common/` | read by the Shell Manager |
| Installer state | `~/.local/state/dotfiles/` | logs, the setup journal, backups, what the shell reads |
| Installer tests | `tests/` | `./install.py check tests`; run before every install |
| Notes | `docs/` | — |

### Components

`components.toml` lists everything that can go on a machine: dotfiles
packages (`kitty`, `quickshell`), features (`vpn`, `yandex-music`) and
hardware (`gpu-nvidia`, `laptop`). Its header documents every field.

- `link`, `deps`, `system` and `setup` act on the **selected** components:
  `[components] selected` in `.machine.toml`, set by the wizard or
  `./install.py components add|remove|set <name>…`.
- With nothing chosen: a machine already set up keeps everything (but
  hardware that wasn't detected); a fresh one gets the catalog's defaults,
  which `setup` saves.
- A file belongs to the component whose `links` path matches it longest:
  `zsh` owns `zsh/`, `vpn` owns `zsh/functions/vpn`. Theme overlays follow
  their package. A file nobody owns is linked everywhere and fails `check`.
- `requires` can't be switched off; `suggests` is ticked along, can be
  unticked; `default = false` keeps personal things off for a new machine;
  hardware turns on by `auto` terms (`gpu:nvidia`, `hybrid`, `laptop`,
  `asus`, `quirk:<name>`; `!term` negates).
- Packages count as installed when anything provides them (`pacman -T`:
  `yay-bin` is `yay`).

### The machine profile

`./install.py machine detect` reads `/sys` and `/proc` (GPUs, battery,
backlight, codecs, outputs, DMI) into `[hardware]` of `.machine.toml`.
Wrong values are fixed in `[override]`, which detect keeps. Code:
`installer/detect.py` (readers take a fake root for tests).

`[hypr]` holds this machine's Hyprland settings; `link` writes them to
`~/.config/hypr/machine/{gpu,input,monitors}.lua` (real files, marked as
generated — edit the profile, never them):

```toml
[hypr]
gpu_env = "none"                    # nvidia | none; default nvidia only without an iGPU
layouts = "us,ru"
layout_options = "grp:caps_toggle"
monitors = [{ output = "eDP-1", mode = "1920x1080@144.00", position = "0x0", scale = 1.2 }]
workspaces = { eDP-1 = "1-10" }     # the first of each range is the output's default
```

The repo's hypr config loads them through `components/machine.lua` and has a
default for each (every output at its preferred mode, `us`, no GPU env).
`hl.env` applies when Hyprland starts: a `gpu_env` change needs a new login
(`link` says so, `doctor` checks the running session).

### The wizard

`./install.py install` (`installer/wizard.py`, curses): welcome with the
checks → hardware → one screen per component group → settings (theme,
layouts, the switch key) → summary. Only the confirmed summary writes
`.machine.toml` and `.theme`; then `setup` runs. It opens on the saved
choice; on a machine set up before choices were saved, on what is on now;
only a fresh machine starts from the defaults.

### Setup

`./install.py setup` = preflight, the plan, then each step with work
(`installer/steps.py`): packages, the AUR helper (yay-bin, built when none
is there), AUR packages, submodules, links, the secrets template, `private/`,
Oh My Zsh and plugins, `/etc`, user units, services and masks, the login
shell, Neovim's plugins. `--dry-run` stops at the plan; `--noconfirm` goes
to pacman, yay and makepkg. Each step is asked again right before it runs
(earlier steps make work for later ones); a failed step stops the run and
the next run skips what is done. Never done, only listed "by hand": group
membership, rival services, boot settings (`hint`), units without a running
systemd (a container, a chroot).

Preflight, before anything with sudo, for `setup` and `deps`: the
environment (Arch, not root, pacman / git / sudo), `check components`,
`check hypr` and the tests. One problem stops the install.

### Living with it

`installer/maintain.py`:

- `update` pulls (fast-forward only) and runs `setup` in a new process, so
  the pulled installer is the one that runs.
- `doctor` is `check` for the machine: the plan's pending work plus what it
  can't see — services enabled but not running, mihomo's capabilities,
  Hyprland's config errors, `machine/` out of step, a session on another
  GPU environment, changed hardware — each with its fix.
- `uninstall [--system]` removes links, generated files (they carry
  `hypr.MARK`) and, with `--system`, our `/etc` files nobody changed;
  `rollback` puts backed-up files back. Packages, services and anything
  that isn't ours stay; a file in the way of a restore stays in its backup.
- A link that replaces a real file moves it to
  `~/.local/state/dotfiles/backup/<time>/`, by its path from `~`.

## Recipes

Every recipe ends with `./install.py check` all green.

### Change a config

Edit the file in `packages/<pkg>/` (it is what `~/.config` points to).
Colours never go there: see Themes. Hardware-bound values never go there:
see "A setting that differs per machine".

### Add a config file

1. Put it in `packages/<pkg>/…` (or `home/` for `~`).
2. `./install.py link` — a new file is invisible until linked.
3. A new package needs a component (below), or its path in an existing
   component's `links`; `check components` names any file nobody owns.
4. A non-default target: `packages/<pkg>/package.toml` —
   `dir = "~/.config"`, `skip = ["notes.txt"]`, `[files] "a.toml" = "~/x.toml"`.

### Add a program a config uses

Its real package name (`mihomo-bin`, not `mihomo`) goes in `pacman` or `aur`
of the component that needs it; a name may repeat across components.
`check components` asks pacman whether it exists and is in the right list.

### Add a component

```toml
[name]
group = "apps"                 # core desktop terminal editor apps music network ai personal hardware
about = "One line for the wizard"
default = false                # personal or heavy things stay off for a new machine
requires = ["quickshell"]      # on with it, can't be switched off
suggests = ["mako"]            # ticked along, can be unticked
pacman = ["pkg"]
aur = ["pkg-bin"]
links = ["pkg"]                # paths under packages/, or "home/<file>"
submodules = ["packages/scripts/x"]
modules = ["x"]                # bar modules it brings
system = ["etc/…"]             # files under system/
services = ["x.service"]       # system units to enable; user_services for --user
user_units = ["packages/…/x.service"]   # unit files copied into ~/.config/systemd/user
masks = ["rival.service"]      # system units that fight this one
secrets = ["x/token"]          # keys of private/manifest.json
hint = "a manual step, printed, never done"
```

Hardware is `group = "hardware"` with `auto = [...]` instead of `default`.
Unknown fields, missing paths, loops in `requires` and bar modules that no
component brings all fail `check components`.

### Add a file in /etc

1. `system/etc/…` mirrors `/`; list it in a component's `system`.
2. `@KEY@` is a text value of the machine profile (`@BATTERY@` → `BAT0`);
   `check` rejects unknown keys. A placeholder is replaced everywhere in the
   file, comments included.
3. Hardware registers (codec pins, …) are a quirk: an entry in `QUIRKS` of
   `installer/detect.py` with every condition (board, codec at its address)
   and a hardware component with `auto = ["quirk:<name>"]`.
4. Agents don't run sudo: give the owner `./install.py system install`.
5. What runs after a copy: `SYSTEM_APPLY` (tmpfiles, tlp) and pacman hooks
   in `installer/system.py`; modprobe applies after a reboot.
6. Boot changes (kernel cmdline, mkinitcpio) are never automated: a `hint`.

### A setting that differs per machine

Never in the repo's config. Hyprland: a key in `[hypr]`, rendered by
`installer/hypr.py` into `machine/<name>.lua` and loaded with
`require("components.machine").load("<name>")` after the repo's default; a
test in `tests/test_hypr.py`. `check hypr` runs `Hyprland --verify-config`
on copies of the config with and without `machine/`: a configured and a new
machine must both parse.

### Add a bar module or a shell app

Follow `packages/quickshell/shell/CLAUDE.md`, then put the module id in
`modules` of the component it depends on (`quickshell` for core ones).
`link` writes `~/.local/state/dotfiles/components.json` (`installer/shell.py`):
the modules whose components are all off. `BarLayout` keeps them off every
bar (their saved place stays); the Shell Manager lists them as not installed.

### Add a secret

1. A template `templates/secrets/<name>.example` when someone else can fill it.
2. A `.gitignore` line for its path, if it lives in the repo.
3. The file in `private/` and an entry in `private/manifest.json`
   (`"dir/file": "~/target"`); `private/secrets.py collect` copies it in.
4. Its key in `secrets` of the component using it.
5. A row in the README's Secrets table.

Keys live in `~/.config/secrets/env` (from `templates/secrets/env.example`).
Never committed: tokens, keys, passwords, `hosts.yml`, the rendered
`mihomo/config.yaml`, `providers/`, personal data. `setup` clones `private/`
over SSH or `gh` and restores only files that are missing (a restore
overwrites, and a local edit not yet collected would be lost).

### Add a theme

Its colours in `themes/mktheme.py`, then `python3 themes/mktheme.py <name>`.
Generated themes are never edited by hand; `check themes` finds stale ones.

### Change the installer

One module per concern in `installer/`: `paths`, `ui`, `model` (links,
system files), `links`, `theme`, `system`, `deps`, `components`, `choose`
(the `components` command), `detect`, `machine`, `hypr`, `shell`, `steps`,
`setup`, `preflight`, `wizard`, `maintain`, `check`, `menu`, `cli`.

- A behaviour change comes with a test in `tests/` (fake `/sys` trees in
  `tests/fakesys.py`; nothing touches the real machine).
- A new kind of setup work: a `Step` in `STEPS` whose `pending()` only looks
  and `run()` is idempotent; a test in `tests/test_steps.py`.
- A change to what setup does also runs on a clean Arch:
  `tests/fresh-machine.sh [defaults | component…]` (podman; clones the
  committed repo as a new user, runs setup unattended, then doctor, verify,
  a second setup with nothing to do, uninstall).
- A refactor keeps the output of `status`, `verify`, `system status` and
  `deps --check`: compare before and after.

## Themes

- One theme for the whole desktop; colours by role
  ([themes/gruvbox/README.md](themes/gruvbox/README.md)). A hex outside a theme
  is a bug (imported themes of btop may keep their own shades).
- A package holds the config; a theme only what depends on its colours. The
  colour files themselves (hypr `colors.lua`, kitty `colors.conf`, …) live in
  the themes alone, so a theme is always active. Two exceptions are gruvbox's
  own: `packages/tmux/colors.conf` and `packages/btop/themes/current.theme`
  are its colours and the source the other themes are recoloured from
  (`FROM_PACKAGES` in `themes/mktheme.py`).
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
| `install` | the wizard, then `setup` |
| `setup [--dry-run] [--noconfirm] [-y]` | preflight, the plan, each step with work |
| `update [--dry-run] [--noconfirm] [-y]` | `git pull --ff-only`, then `setup` with the new code |
| `doctor` | this machine's health, each problem with its fix |
| `components [list \| add \| remove \| set <name>…]` | what is on this machine |
| `machine [show \| detect]` | the hardware profile |
| `link` · `verify` · `status` | links: create · check · per package |
| `deps [--check]` | missing packages of the selected components |
| `system status \| install` | `/etc` files of the selected components |
| `check [group…]` | the repo: links, syntax, themes, components, tests, hypr, shell, repo |
| `theme list \| current \| set <name>` | themes |
| `secrets [status \| restore]` | `private/` |
| `uninstall [--system]` · `rollback [stamp]` | links and generated files off · backed-up files back |
| `force` · `unlink` · `cleanup` · `bootstrap [-f]` | re-link all · remove all links · only stale ones · the secrets template |

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
- Someone else's uncommitted changes are not committed or reverted without
  asking; commit your own hunks only.

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
./install.py doctor
./install.py system status
git status
git log --oneline -5
```

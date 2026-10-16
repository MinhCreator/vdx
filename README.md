# dotfiles

Arch Linux + Hyprland, one theme across the desktop, deployed by `install.py`
(Python stdlib, per-file symlinks): a wizard picks what goes on the machine,
the hardware is detected, nothing personal is installed unless asked for.

![The Quickshell shell](docs/shell/shell-demo.webp)

The shell up close: [packages/quickshell/shell](packages/quickshell/shell/README.md#overview)
· [video](docs/shell/shell-demo.mp4).

| | |
|---|---|
| Desktop | Hyprland (Lua config), Quickshell shell, mako |
| Shell | zsh, Oh My Zsh, Starship |
| Editor | Neovim |
| Terminal | kitty, tmux |
| Music | MPD, ncmpcpp, Yandex Music and radio CLIs (optional) |
| VPN | Mihomo + `vpn` (optional) |

## Install

Arch Linux, a user with sudo, `git` and `python` ≥ 3.11:

```bash
sudo pacman -S --needed git python
git clone https://github.com/diominvd/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.py install
```

The wizard shows the machine and the checks, the detected hardware, every
component by group (desktop, terminal, editor, apps, music, network, AI),
the theme and keyboard, then a summary; nothing is written before it. Then
`setup` runs: preflight, the plan, packages (yay is built when missing),
submodules, links, plugins, `/etc` files (a diff first), services, the
login shell. Each step skips what is in place; boot settings (the NVIDIA
driver, mkinitcpio) are only listed for you.

Without the wizard: `./install.py components set <name>…`, then
`./install.py setup` (`--dry-run` shows the plan). Hyprland needs the Lua
config layer (0.55+); log in from a tty and run `start-hyprland`.

## Commands

`./install.py` alone opens a menu.

| Command | |
|---|---|
| `install` | the wizard, then `setup` |
| `setup [--dry-run]` | install / bring up to date what is chosen |
| `update` | `git pull`, then `setup` |
| `doctor` | this machine's health, each problem with its fix |
| `components [list\|add\|remove\|set]` | what is on this machine |
| `machine [show\|detect]` | the detected hardware (`.machine.toml`) |
| `theme list\|current\|set <name>` | themes; `set` re-links and reloads |
| `link` · `verify` · `status` | links: create · check · per package |
| `check [group…]` | the repo itself: links, syntax, themes, components, tests, hypr, shell |
| `uninstall [--system]` · `rollback` | take it off · put replaced files back |

Destructive commands ask first; `-y` answers yes. All of them:
[CONVENTIONS.md](CONVENTIONS.md#commands).

## Layout

```
install.py        the installer (code in installer/, tests in tests/)
components.toml   what can be installed: one entry per checkbox
.machine.toml     this machine: hardware, overrides, the choice (local)
home/             -> ~/
packages/         -> ~/.config/<pkg>/   (package.toml overrides the target)
themes/<t>/       overlay of packages/, the active theme wins per file
system/           copied into / with sudo
templates/        secrets/env.example
wallpapers/       per theme + common/
docs/             notes
```

Themes: catppuccin, dracula, ember, everforest, graphite, gruvbox (the
source), kanagawa, khaki, mono, nord, onedark, rosepine, tokyonight. Colour
roles: [themes/gruvbox/README.md](themes/gruvbox/README.md).

The shell (bar, apps, Shell Manager on Super+S):
[packages/quickshell/shell](packages/quickshell/shell/README.md).

Submodules (cloned with their component): `packages/nvim`,
`packages/scripts/{yandex-music,radio,vpn}`.

## Secrets

| Secret | Where | In git |
|---|---|---|
| All of the below, one place | `private/` (private repo, `private/secrets.py restore`) | no |
| API keys | `~/.config/secrets/env` | no |
| GitHub token | `~/.config/gh/hosts.yml` | no |
| Mihomo subscriptions | `packages/mihomo/subscriptions.json` (template: `.example`) | no |
| Mihomo config, providers | `packages/mihomo/config.yaml`, `providers/` | no |
| Yandex Music token | `~/.config/scripts/yandex-music/token` | no |
| opencode password | `~/.config/opencode/service.json` | no |

## Troubleshooting

- Something off: `./install.py doctor` names it and the command that fixes it.
- A real file was in the way of a link: it is in
  `~/.local/state/dotfiles/backup/<time>/`; `./install.py rollback` puts it back.
- A new file isn't picked up: `./install.py link`.
- Video in the browser shows nothing after a GPU change: log out of Hyprland
  and back in (its environment is set at start).
- Logs of each setup: `~/.local/state/dotfiles/setup-<time>.log`.

Rules for changing anything: [CONVENTIONS.md](CONVENTIONS.md). License: MIT.

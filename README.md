# dotfiles

Arch Linux + Hyprland, one theme across the desktop, deployed by `install.py`
(Python stdlib, per-file symlinks).

| | |
|---|---|
| Desktop | Hyprland (Lua config), Quickshell shell, mako |
| Shell | zsh, Oh My Zsh, Starship |
| Editor | Neovim |
| Terminal | kitty, tmux |
| Music | MPD, ncmpcpp, Yandex Music and radio CLIs |
| VPN | Mihomo + `vpn` |

## Install

Fresh Arch with `git` and `python` ≥ 3.11:

```bash
git clone --recursive git@github.com:diominvd/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.py setup
```

`setup` installs `deps/`, submodules, links, the secrets template, zsh / tmux
plugins and `system/`, then verifies. Each step skips what is in place.
Hyprland needs the Lua config layer (0.55+).

## Commands

`./install.py` alone opens a menu.

| Command | |
|---|---|
| `setup` | everything above |
| `deps [--check]` | install missing packages |
| `link` | create / refresh links, drop stale ones |
| `force` | unlink + link |
| `unlink` · `cleanup` | remove all links · only stale ones |
| `status` · `verify` | per-package status · broken, missing, stale links |
| `bootstrap [-f]` | seed secrets from templates |
| `system status\|install` | compare / install `system/` into `/etc` |
| `theme list\|current\|set <name>` | themes; `set` re-links and reloads |

Destructive commands ask first; `-y` answers yes.

## Layout

```
install.py     the manager
deps/          pacman.txt, aur.txt
home/          -> ~/
packages/      -> ~/.config/<pkg>/   (package.toml overrides the target)
themes/<t>/    overlay of packages/, the active theme wins per file
system/        copied into /etc with sudo
secrets/       env.example
wallpapers/    per theme + common/
docs/          notes
```

Themes: catppuccin, dracula, ember, everforest, graphite, gruvbox (the
source), kanagawa, khaki, mono, nord, onedark, rosepine, tokyonight. Colour
roles: [themes/gruvbox/README.md](themes/gruvbox/README.md).

The shell (bar, apps, Shell Manager on Super+S):
[packages/quickshell/shell](packages/quickshell/shell/README.md).

Submodules: `packages/nvim`, `packages/scripts/{yandex-music,radio,vpn}`.

## Secrets

| Secret | Where | In git |
|---|---|---|
| API keys | `~/.config/secrets/env` | no |
| GitHub token | `~/.config/gh/hosts.yml` | no |
| Mihomo config, providers | `packages/mihomo/config.yaml`, `providers/` | no |
| Mihomo subscriptions | `packages/mihomo/subscriptions.json` | yes (private repo) |
| Yandex Music token | `~/.config/scripts/yandex-music/token` | no |

## Troubleshooting

- Conflicts: `./install.py force` (real files are kept as `.bak`).
- A new file isn't picked up: `./install.py link`.
- Empty submodules: `git submodule update --init --recursive`.

Rules: [CONVENTIONS.md](CONVENTIONS.md). License: MIT.

> **[Русская версия](README_RU.md)**

# dotfiles

Gruvbox-themed dotfiles for Arch Linux / Hyprland / Zsh / Neovim. Python-based symlink manager with TUI — no stow required.

| Component | Software |
|-----------|----------|
| Window Manager | Hyprland + Waybar + Mako + Rofi + Swaylock |
| Shell | Zsh + Oh My Zsh + Starship |
| Editor | Neovim (lazy.nvim, LSP, Treesitter, Telescope) |
| Terminal | Kitty + tmux |
| Music | MPD + ncmpcpp + Yandex Music |
| VPN | Mihomo (Clash Meta) + Krusofiya |
| Other | btop, fastfetch, elio, opencode |

---

## Requirements

- **OS:** Arch Linux (or derivative)
- **Python:** 3.11+
- **Git:** for cloning and submodules
- **uv** (recommended): used by the `radio`, `vpn` and `yandex-music` scripts

No other dependencies — the installer is pure Python stdlib.

---

## Installation

### Fresh system

```bash
# 1. Prerequisites
sudo pacman -S --needed git python uv

# 2. Oh My Zsh + Starship (needed by the zsh config)
ZSH="$HOME/.local/share/oh-my-zsh" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
curl -sS https://starship.rs/install.sh | sh

# 3. Clone and deploy
git clone git@github.com:diominvd/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.py link                          # deploy all symlinks
git submodule update --init --recursive    # fetch nvim, tpm, radio, vpn, yandex-music
git config core.hooksPath hooks            # enable auto-relink hooks
```

### Existing system

If git is already installed:

```bash
./install.py link
```

### Makefile (legacy)

The repo also ships a `Makefile` that uses GNU Stow (`make setup`, `make install`, `make link`, ...). It is kept for compatibility only — new installs should use `./install.py`.

---

## Usage

### CLI

| Command | Description |
|---------|-------------|
| `./install.py link` | Create all symlinks (auto-resolves conflicts) |
| `./install.py update` | Add only new files, skip existing/conflicting |
| `./install.py force` | Unlink + relink everything |
| `./install.py cleanup` | Remove stale and broken symlinks |
| `./install.py unlink` | Remove all managed symlinks |
| `./install.py status` | Show package status (linked/missing/problem) |
| `./install.py verify` | Check for broken and stale symlinks |
| `./install.py tui` | Interactive TUI menu |

The same CLI is available as `python -m installer` or `uv run install.py` (works via the inline PEP 723 metadata).

### TUI

```bash
./install.py tui
```

Navigate with arrow keys or j/k, Enter to select, q to quit.

### Common workflows

```bash
# Added new config files to apps/nvim/
./install.py update

# Pulled changes from GitHub (hooks auto-run link)
git pull

# Conflicts with existing files in ~/.config/
./install.py force

# Diagnose problems
./install.py status
./install.py verify
```

---

## How It Works

### install.py

`install.py` is a pure Python symlink manager with no external dependencies (no stow). It provides both CLI and TUI interfaces for managing dotfile symlinks.

### Symlink Manager

The manager scans three source directories and creates symlinks preserving the package structure:

| Source | Target | Example |
|--------|--------|---------|
| `home/` | `~/` | `home/.zshenv` → `~/.zshenv` |
| `apps/` | `~/.config/` | `apps/nvim/init.lua` → `~/.config/nvim/init.lua` |
| `system/` | `~/.config/` | `system/mpd/mpd.conf` → `~/.config/mpd/mpd.conf` |

Each package gets its own subdirectory in `~/.config/`, avoiding name collisions between packages (e.g. `mako/config` vs `ncmpcpp/config`). Root-level files such as `apps/starship.toml` are linked directly.

**Skip rules:** hidden files are skipped unless in the allow-list (`.zshrc`, `.zshenv`, `.luarc.json`, `.gitignore`); `.git`, `README.md`, `README`, `assets` and `node_modules` are never linked.

**Conflict resolution:**
- Existing symlinks pointing to the correct source are kept
- Wrong symlinks are replaced
- Real files/directories are backed up with `.bak` extension
- Empty directories are removed

**Stale links:** symlinks pointing into the repo that are no longer managed are detected and removed by `link`, `update`, `cleanup` and `verify`.

### Git Hooks

Enable hooks once with `git config core.hooksPath hooks`, then they stay in sync:

- **post-checkout** — runs `./install.py link` after `git checkout` or `git switch`
- **post-merge** — runs `./install.py link` after `git pull`
- **post-rebase** — runs `./install.py link` after `git rebase`

This means symlinks are always in sync with the repo after any branch operation.

### Submodules

External tools are pulled as git submodules:

| Submodule | Path | Source |
|-----------|------|--------|
| Neovim config | `apps/nvim` | github.com/diominvd/neovim |
| tmux TPM | `apps/tmux/plugins/tpm` | github.com/tmux-plugins/tpm |
| Radio CLI | `system/scripts/radio` | github.com/diominvd/radio-cli |
| VPN manager | `system/scripts/vpn` | github.com/diominvd/vpn-manager-cli |
| Yandex Music | `system/scripts/yandex-music` | github.com/diominvd/yandex-music-cli |

Initialized manually with `git submodule update --init --recursive` (or by the legacy `make install`).

---

## Repository Structure

```
.dotfiles/
├── apps/              → ~/.config/
│   ├── btop/                      system monitor
│   ├── elio/                      file manager
│   ├── fastfetch/                 system info
│   ├── gtk-3.0/                   GTK theme
│   ├── hypr/                      Hyprland WM (Lua config)
│   │   ├── hyprland.lua           main config
│   │   └── components/            modular configs
│   ├── kitty/                     terminal
│   ├── mako/                      notifications
│   ├── mihomo-tui/                VPN TUI client
│   ├── ncmpcpp/                   MPD client
│   ├── nvim/                      Neovim (submodule)
│   ├── opencode/                  AI assistant
│   │   ├── opencode.jsonc         main config
│   │   ├── tui.json               TUI settings
│   │   └── command/               custom commands (snapshot, restore)
│   ├── rofi/                      launcher
│   │   ├── apps.sh, scripts.sh, boot.sh   launcher modes
│   │   ├── dmenu.sh               custom menu script
│   │   ├── menu.json, scripts.json        menu entries
│   │   └── config.rasi, colors.rasi       theme
│   ├── starship.toml              prompt
│   ├── swaylock/                  screen lock
│   ├── telegram/                  Telegram theme
│   ├── tmux/                      terminal multiplexer
│   │   ├── tmux.conf
│   │   └── plugins/tpm/           TPM plugin manager (submodule)
│   ├── waybar/                    status bar
│   │   ├── config.jsonc           → include modules/*.jsonc
│   │   ├── modules/               modular configs
│   │   ├── style.css              → @import styles/*.css + colors.css
│   │   ├── styles/                modular styles
│   │   ├── colors.css             shared color variables
│   │   └── scripts/               custom scripts
│   └── zsh/                       shell
│       ├── .zshrc                 main config
│       ├── aliases                aliases
│       ├── exports                environment variables
│       ├── functions/             autoloaded functions (battery, disk, memory, music, radio, volume, vpn)
│       ├── keys                   secrets placeholder
│       └── keys.example           template for keys
│
├── home/              → ~/
│   └── .zshenv                     ZDOTDIR, paths
│
├── system/            → ~/.config/
│   ├── gh/                         GitHub CLI
│   ├── mihomo/                     VPN proxy
│   │   ├── config.example.yaml     template
│   │   ├── config.yaml             subscription (tracked)
│   │   └── providers/              providers (git-ignored)
│   ├── mpd/                        Music Player Daemon
│   └── scripts/                    helper scripts
│       ├── battery.sh
│       ├── disk.sh
│       ├── memory.sh
│       ├── colorpaper/             image recolor tool
│       ├── radio/                  (submodule)
│       ├── vpn/                    (submodule)
│       └── yandex-music/           (submodule)
│
├── hooks/                         git hooks
│   ├── post-checkout              relink after checkout
│   ├── post-merge                 relink after pull
│   └── post-rebase                relink after rebase
│
├── installer/                     Python package (stdlib only)
│   ├── cli.py                     argument parsing
│   ├── commands.py                command implementations
│   ├── links.py                   symlink logic
│   ├── tui.py                     TUI menu
│   ├── config.py                  paths & skip rules
│   └── ansi.py                    terminal colors
│
├── install.py                     entry point
├── Makefile                       legacy stow-based alternative
├── docs/
│   ├── POWER_MANAGEMENT.md        ASUS TUF power optimization
│   └── POWER_MANAGEMENT_RU.md
└── .gitignore
```

---

## Secrets

API keys and tokens are **not** stored in the repository.

| Secret | Location | In git? |
|--------|----------|---------|
| GEMINI_API_KEY, etc. | `~/.config/secrets/env` | No (sourced by zsh) |
| GitHub OAuth token | `~/.config/gh/hosts.yml` | No (created by `gh auth login`) |
| GitHub CLI config | `system/gh/config.yml` | Yes (no secrets) |
| Mihomo subscription | `system/mihomo/config.yaml` | Yes — contains subscription token + HWID |
| VPN providers | `system/mihomo/providers/` | No (git-ignored) |

> **Note:** `system/mihomo/config.yaml` currently **is** tracked in git and contains a subscription token and HWID. If this repository is public, un-track it (`git rm --cached system/mihomo/config.yaml`) and rotate the credentials.

### Setting up secrets

1. Create the secrets file:
   ```bash
   mkdir -p ~/.config/secrets
   cp ~/.config/zsh/keys.example ~/.config/secrets/env
   ```

2. Edit `~/.config/secrets/env` and add your API keys:
   ```bash
   export GEMINI_API_KEY="your-key-here"
   export GOOGLE_GENERATIVE_AI_API_KEY="your-key-here"
   export ANTHROPIC_API_KEY="your-key-here"
   export OPENAI_API_KEY="your-key-here"
   ```

3. Set up Mihomo VPN:
   ```bash
   cp system/mihomo/config.example.yaml system/mihomo/config.yaml
   # Edit config.yaml with your subscription URL and HWID
   ```

**Backup:** Encrypted backup at `~/secrets.tar.gz.enc` (AES-256-CBC), password in `~/secrets.passphrase`.

---

## Included Apps

| App | Config path | Description |
|-----|-------------|-------------|
| [btop](https://github.com/aristocratos/btop) | `apps/btop/` | System monitor |
| [elio](https://github.com/elio-fm/elio) | `apps/elio/` | File manager |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | `apps/fastfetch/` | System info display |
| [Hyprland](https://hyprland.org/) | `apps/hypr/` | Wayland compositor |
| [Kitty](https://sw.kovidgoyal.net/kitty/) | `apps/kitty/` | Terminal emulator |
| [Mako](https://github.com/emersion/mako) | `apps/mako/` | Notification daemon |
| [mihomo-tui](https://github.com/MetaCubeX/mihomo-tui) | `apps/mihomo-tui/` | VPN TUI client |
| [ncmpcpp](https://github.com/ncmpcpp/ncmpcpp) | `apps/ncmpcpp/` | MPD music client |
| [Neovim](https://neovim.io/) | `apps/nvim/` | Text editor |
| [opencode](https://github.com/opencode-ai/opencode) | `apps/opencode/` | AI coding assistant |
| [Rofi](https://github.com/DaveDavenport/rofi) | `apps/rofi/` | Application launcher |
| [Starship](https://starship.rs/) | `apps/starship.toml` | Shell prompt |
| [Swaylock](https://github.com/swaywm/swaylock) | `apps/swaylock/` | Screen locker |
| [Telegram](https://desktop.telegram.org/) | `apps/telegram/` | Telegram theme |
| [tmux](https://github.com/tmux/tmux) | `apps/tmux/` | Terminal multiplexer |
| [Waybar](https://github.com/Alexays/Waybar) | `apps/waybar/` | Status bar |
| [Zsh](https://www.zsh.org/) | `apps/zsh/` | Shell |

Color scheme: **Gruvbox Material Dark** across all configs.

---

## Troubleshooting

### Conflicts with existing files

The manager backs up conflicting files with `.bak` extension. To force recreate everything:

```bash
./install.py force
```

### Submodules are empty

After cloning, submodules need initialization:

```bash
git submodule update --init --recursive
```

### Git hooks not running

```bash
git config core.hooksPath hooks
```

### Broken symlinks found

```bash
./install.py verify
# Then redeploy:
./install.py link
```

### "permission denied: ./install.py"

```bash
chmod +x install.py
```

---

## License

[MIT](https://opensource.org/licenses/MIT)

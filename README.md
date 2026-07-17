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
- **Python:** 3.10+
- **Git:** for cloning and submodules

Everything else is installed by `./install.py setup`.

---

## Installation

### Fresh system (recommended)

```bash
git clone git@github.com:diominvd/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
chmod +x install.py
./install.py setup
```

This will:
1. Install system packages (`git`) via pacman
2. Install Oh My Zsh (if not present)
3. Install Starship prompt (if not present)
4. Deploy all symlinks
5. Initialize git submodules (nvim, radio, vpn)
6. Configure git hooks (auto-relink on pull/checkout/rebase)

### Existing system

If git is already installed:

```bash
./install.py link
```

---

## Usage

### CLI

| Command | Description |
|---------|-------------|
| `./install.py link` | Create all symlinks (auto-resolves conflicts) |
| `./install.py update` | Add only new files, skip existing |
| `./install.py force` | Remove all symlinks and recreate |
| `./install.py unlink` | Remove all managed symlinks |
| `./install.py status` | Show package status (linked/missing/conflict) |
| `./install.py verify` | Check for broken symlinks |
| `./install.py tui` | Interactive TUI menu |

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

# Fresh reinstall on a new machine
./install.py setup
```

---

## How It Works

### install.py

The `install.py` script is a pure Python symlink manager with no external dependencies (no stow). It provides both CLI and TUI interfaces for managing dotfile symlinks.

### Symlink Manager

The manager scans three source directories and creates symlinks preserving the package structure:

| Source | Target | Example |
|--------|--------|---------|
| `home/` | `~/` | `home/.zshenv` → `~/.zshenv` |
| `apps/` | `~/.config/` | `apps/nvim/init.lua` → `~/.config/nvim/init.lua` |
| `system/` | `~/.config/` | `system/mpd/mpd.conf` → `~/.config/mpd/mpd.conf` |

Each package gets its own subdirectory in `~/.config/`, avoiding name collisions between packages (e.g. `mako/config` vs `ncmpcpp/config`).

**Conflict resolution:**
- Existing symlinks pointing to the correct source are kept
- Wrong symlinks are replaced
- Real files/directories are backed up with `.bak` extension
- Empty directories are removed

### Git Hooks

After `install`, git hooks are configured in `hooks/`:

- **post-checkout** — runs `./install.py link` after `git checkout` or `git switch`
- **post-merge** — runs `./install.py link` after `git pull`
- **post-rebase** — runs `./install.py link` after `git rebase`

This means symlinks are always in sync with the repo after any branch operation.

### Submodules

External tools are pulled as git submodules:

| Submodule | Path | Source |
|-----------|------|--------|
| Neovim config | `apps/nvim` | github.com/diominvd/neovim |
| Radio CLI | `system/scripts/radio` | github.com/diominvd/radio-cli |
| VPN manager | `system/scripts/vpn` | github.com/diominvd/vpn-manager-cli |
| Yandex Music | `system/scripts/yandex-music` | github.com/diominvd/yandex-music-cli |

Initialized automatically by `./install.py link` or manually with `git submodule update --init --recursive`.

---

## Repository Structure

```
.dotfiles/
├── apps/              → ~/.config/
│   ├── btop/                      system monitor
│   ├── elio/                      file manager
│   ├── fastfetch/                 system info
│   ├── gtk-3.0/                   GTK theme
│   ├── hypr/                      Hyprland WM
│   │   ├── hyprland.conf
│   │   └── components/
│   ├── kitty/                     terminal
│   ├── mako/                      notifications
│   ├── mihomo-tui/                VPN TUI client
│   ├── ncmpcpp/                   MPD client
│   ├── nvim/                      Neovim (submodule)
│   ├── opencode/                  AI assistant
│   ├── rofi/                      launcher
│   │   ├── dmenu.sh              custom menu script
│   │   └── menu.json             menu entries
│   ├── starship.toml              prompt
│   ├── swaylock/                  screen lock
│   ├── telegram/                  Telegram theme
│   ├── tmux/                      terminal multiplexer
│   ├── waybar/                    status bar
│   │   ├── config.jsonc           → include modules/*.jsonc
│   │   ├── modules/               modular configs
│   │   ├── style.css              → @import styles/*.css
│   │   ├── styles/                modular styles
│   │   └── scripts/               custom scripts
│   └── zsh/                       shell
│       ├── .zshrc                 main config
│       ├── aliases                aliases
│       ├── exports                environment variables
│       ├── functions/             autoloaded functions
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
│   │   └── providers/              providers (git-ignored)
│   ├── mpd/                        Music Player Daemon
│   └── scripts/                    helper scripts
│       ├── battery.sh
│       ├── disk.sh
│       ├── memory.sh
│       ├── radio/                  (submodule)
│       ├── vpn/                    (submodule)
│       └── yandex-music/           (submodule)
│
├── hooks/                         git hooks
│   ├── post-checkout              relink after checkout
│   ├── post-merge                 relink after pull
│   └── post-rebase                relink after rebase
│
├── install.py                     symlink manager
├── docs/
│   └── POWER_MANAGEMENT.md        ASUS TUF power optimization
└── .gitignore
```

---

## Secrets

API keys and tokens are **not** stored in the repository.

| Secret | Location | In git? |
|--------|----------|---------|
| GEMINI_API_KEY, etc. | `~/.config/secrets/env` | No |
| GitHub OAuth token | `~/.config/gh/hosts.yml` | No (git-ignored) |
| Mihomo subscription | `system/mihomo/config.yaml` | No (git-ignored) |
| VPN providers | `system/mihomo/providers/` | No (git-ignored) |

### Setting up secrets

1. Create the secrets file:
   ```bash
   mkdir -p ~/.config/secrets
   cp ~/.config/zsh/keys.example ~/.config/secrets/env
   ```

2. Edit `~/.config/secrets/env` and add your API keys:
   ```bash
   export GEMINI_API_KEY="your-key-here"
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
| [elio](https://github.com/nicokosi/elio) | `apps/elio/` | File manager |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | `apps/fastfetch/` | System info display |
| [Hyprland](https://hyprland.org/) | `apps/hypr/` | Wayland compositor |
| [Kitty](https://sw.kovidgoyal.net/kitty/) | `apps/kitty/` | Terminal emulator |
| [Mako](https://github.com/emersion/mako) | `apps/mako/` | Notification daemon |
| [mihomo-tui](https://github.com/nicokosi/mihomo-tui) | `apps/mihomo-tui/` | VPN TUI client |
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
./install.py hooks
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

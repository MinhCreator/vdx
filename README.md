> **[Русская версия](README_RU.md)**

# dotfiles

Gruvbox-themed dotfiles for Arch Linux / Hyprland / Zsh / Neovim. Uses [GNU Stow](https://www.gnu.org/software/stow/) for symlink management and a Python installer for easy deployment.

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
1. Install system packages (`stow`, `git`) via pacman
2. Install Oh My Zsh (if not present)
3. Install Starship prompt (if not present)
4. Deploy all symlinks
5. Initialize git submodules (nvim, radio, vpn, yandex-music)
6. Configure git hooks (auto-relink on pull/checkout/rebase)

### Existing system

If you already have stow and git installed:

```bash
./install.py install
```

### Single package

```bash
./install.py link-pkg nvim
./install.py link-pkg hypr
./install.py link-pkg kitty
```

---

## Usage

| Command | Description |
|---------|-------------|
| `./install.py setup` | Install system dependencies + full install |
| `./install.py install` | Full install (check deps + link + submodules + hooks) |
| `./install.py link` | Deploy or update all symlinks |
| `./install.py link-pkg <name>` | Deploy a single package |
| `./install.py force` | Remove existing links and redeploy everything |
| `./install.py clean` | Remove all symlinks created by this tool |
| `./install.py verify` | Check for broken symlinks |
| `./install.py check-deps` | Verify stow and git are installed |
| `./install.py submodules` | Initialize git submodules |
| `./install.py hooks` | Configure git hooks |

### Common workflows

```bash
# Added a new config file to apps/nvim/
./install.py link

# Pulled changes from GitHub (hooks auto-run make link)
git pull

# Switched branch (hooks auto-run make link)
git checkout other-branch

# Files already exist in ~/.config/ and stow refuses to link
./install.py force

# Fresh reinstall on a new machine
./install.py setup
```

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
├── install.py                     installer script
├── docs/
│   └── POWER_MANAGEMENT.md        ASUS TUF power optimization
└── .gitignore
```

---

## How It Works

### Stow

The installer uses `stow --no-folding` to create symlinks from three source directories:

| Source | Target | Contents |
|--------|--------|----------|
| `home/` | `~/` | Files that live in $HOME (.zshenv) |
| `apps/` | `~/.config/` | Application configs |
| `system/` | `~/.config/` | System services and scripts |

Each subdirectory or file in the source becomes a symlink. For example:
- `apps/nvim/` → `~/.config/nvim/`
- `apps/starship.toml` → `~/.config/starship.toml`
- `home/.zshenv` → `~/.zshenv`

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
| Yandex Music | `system/scripts/yandex-music` | (personal) |

Initialized automatically by `./install.py install` or `./install.py submodules`.

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

### "stow: existing target is not the same as" / "not empty"

Files already exist in `~/.config/` conflicting with stow. Use force mode:

```bash
./install.py force
```

### Submodules are empty

After cloning, submodules need initialization:

```bash
./install.py submodules
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

### "command not found: stow"

```bash
./install.py setup
# or manually:
sudo pacman -S stow
```

### "permission denied: ./install.py"

```bash
chmod +x install.py
```

---

## License

[MIT](https://opensource.org/licenses/MIT)

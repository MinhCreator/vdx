# dotfiles

Gruvbox-themed dotfiles for Arch Linux / Hyprland / Zsh / Neovim.
Manifest-based symlink manager, pure Python stdlib — no stow required.

| Component | Software |
|-----------|----------|
| Window Manager | Hyprland + Waybar + Mako + Rofi + Swaylock |
| Shell | Zsh + Oh My Zsh + Starship |
| Editor | Neovim (lazy.nvim, LSP, Treesitter, Telescope) |
| Terminal | Kitty + tmux (TPM) |
| Music | MPD + ncmpcpp + Yandex Music |
| VPN | Mihomo (Clash Meta) + `vpn` manager |
| Other | btop, fastfetch, elio, opencode |

---

## Requirements

- **OS:** Arch Linux (or derivative)
- **Python:** 3.11+ (stdlib only, via `tomllib`)
- **Git:** for cloning and submodules
- **uv:** used by the `radio`, `vpn` and `yandex-music` scripts
- **Hyprland with Lua config support:** the window-manager config is written
  as `hyprland.lua` (the `hl.*` API), so a Hyprland build with the Lua
  configuration layer is required (0.55+ or current git —
  https://hypr.land/news/26_lua/)

---

## Installation

```bash
# Core packages (Arch official repos)
sudo pacman -S --needed git python uv zsh eza starship tmux kitty jq \
  brightnessctl wl-clipboard grim slurp swaylock mako waybar \
  mpd mpc ncmpcpp btop fastfetch github-cli

# From AUR (or git builds; see Requirements for the Hyprland version):
#   hyprland (Lua-capable build), rofi-wayland, awww (wallpaper daemon),
#   hyprsunset (night light), wifitui, elio, zed, mihomo, mihomo-tui,
#   opencode, telegram-desktop
# Optional: zoxide (enables `z` directory jumps in the zsh config)

# Oh My Zsh (required by zsh config) + custom plugins used by .zshrc
ZSH="$HOME/.local/share/oh-my-zsh" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH/custom/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH/custom/plugins/zsh-syntax-highlighting"

# Starship prompt
curl -sS https://starship.rs/install.sh | sh

# Clone and deploy
git clone git@github.com:diominvd/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
git submodule update --init --recursive     # fetch nvim config
./install.py link                           # deploy all symlinks
./install.py bootstrap                      # copy seed templates for secrets
git config core.hooksPath hooks             # auto-relink on checkout/pull/rebase
```

tmux: reinstall TPM at runtime (removed from the repo as a submodule):

```bash
rm -rf ~/.config/tmux/plugins/tpm
git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
```

---

## Usage

| Command | Description |
|---------|-------------|
| `./install.py link` | Create/refresh all symlinks (removes stale, resolves conflicts) |
| `./install.py update` | Alias of `link` |
| `./install.py force` | Unlink + relink everything |
| `./install.py unlink` | Remove all managed symlinks |
| `./install.py cleanup` | Remove stale symlinks only |
| `./install.py status` | Per-package link status |
| `./install.py verify` | Check for broken/missing/stale links |
| `./install.py theme list` | Available themes |
| `./install.py theme current` | Active theme |
| `./install.py theme set <name>` | Switch theme and re-link |
| `./install.py bootstrap` | Copy seeded templates (secrets/mihomo/vpn) |

Works everywhere via inline PEP 723 metadata: `uv run install.py link`.

---

## How It Works

### Layout

| Source | Target | Example |
|--------|--------|---------|
| `home/` | `~/` | `home/.zshenv` → `~/.zshenv` |
| `packages/<pkg>/` | `~/.config/<pkg>/` | `packages/nvim/init.lua` → `~/.config/nvim/init.lua` |
| `themes/<name>/` | overlay on `~/.config/` | `themes/gruvbox/waybar/colors.css` → `~/.config/waybar/colors.css` |

Each package maps to its own directory in `~/.config/` (avoids `mako/config` vs
`ncmpcpp/config` collisions). Exceptions are declared in an optional
`packages/<pkg>/package.toml`:

```toml
dir = "~/.config"              # install dir override (default ~/.config/<pkg>)

[files]                        # per-file target overrides
"starship.toml" = "~/.config/starship.toml"
```

Theme overlay: `themes/<active>/<pkg>/<rel>` shadows `packages/<pkg>/<rel>`
when present. `.theme` holds the active theme name.

**Skip rules:** `.git`, `.gitignore`, `package.toml`, `node_modules`, `README`,
`README.md` are never linked.

**Conflict resolution:** correct symlinks are kept; wrong ones replaced; real
files/directories get backed up as `.bak`.

### Git Hooks

Enable once — then symlinks stay in sync after every branch operation:

- `post-checkout` / `post-merge` / `post-rebase` → `./install.py link`

```bash
git config core.hooksPath hooks
```

### Submodules

Only Neovim remains a submodule:

| Submodule | Path |
|-----------|------|
| Neovim config | `packages/nvim` → github.com/diominvd/neovim |

`radio`, `vpn` and `yandex-music` are vendored as plain files under
`packages/scripts/` (they deploy as configs; their CLI repos remain the upstream
source). TPM is installed at runtime (see above).

---

## Repository Structure

```
.dotfiles/
├── install.py                     manifest-based manager (stdlib only)
├── .theme                         active theme (gruvbox | dune)
├── home/                          → ~/
│   └── .zshenv
├── packages/                      → ~/.config/<pkg>/
│   ├── btop/ elio/ fastfetch/ gh/ gtk-3.0/
│   ├── hypr/                      Hyprland (Lua, modular components)
│   ├── kitty/ mihomo/ mihomo-tui/ mpd/ ncmpcpp/
│   ├── nvim/                      submodule
│   ├── opencode/ rofi/ scripts/ starship/ telegram/ tmux/ waybar/ zsh/
│   ├── starship/starship.toml     ~/.config/starship.toml (package.toml override)
│   └── scripts/                   vendor: battery, disk, memory, colorpaper,
│                                  radio/, vpn/, yandex-music/
├── themes/
│   ├── gruvbox/                   active theme overlay (11 files)
│   └── dune/                      alternative theme overlay
├── secrets/
│   └── env.example                template for ~/.config/secrets/env
├── hooks/                         post-checkout / post-merge / post-rebase
├── docs/                          POWER_MANAGEMENT notes
└── .gitignore
```

---

## Secrets

API keys, tokens and subscriptions are **not** committed.

| Secret | Location | In git? |
|--------|----------|---------|
| API keys (GEMINI, ANTHROPIC, OPENAI...) | `~/.config/secrets/env`, sourced by zsh | No |
| GitHub OAuth token | `~/.config/gh/hosts.yml` | No (git-ignored) |
| GitHub CLI config | `packages/gh/config.yml` | Yes (no secrets) |
| Mihomo subscription | `packages/mihomo/config.yaml` (+ `packages/mihomo/providers/`) | No (git-ignored) |
| VPN subscriptions | `packages/scripts/vpn/subscriptions.json` | No (git-ignored) |
| Yandex Music token | `~/.config/scripts/yandex-music/token` | No (local file) |

Bootstrap seeds from templates:

```bash
./install.py bootstrap        # ~/.config/secrets/env, mihomo/config.yaml,
                              # scripts/vpn/subscriptions.json (from *.example)
```

Local runtime files may live inside the repo tree (`packages/mihomo/config.yaml`,
`providers/`) — they are git-ignored and re-linked by the manager.

---

## Troubleshooting

- **Conflicts** → `./install.py force` (backs up real files as `.bak`).
- **Submodules empty** → `git submodule update --init`.
- **Hooks not running** → `git config core.hooksPath hooks`.
- **Broken links** → `./install.py verify` then `./install.py link`.
- **Permission denied** → `chmod +x install.py`.

---

## License

MIT
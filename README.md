# dotfiles

Gruvbox-themed dotfiles for Arch Linux / Hyprland / Zsh / Neovim, deployed by a
manifest-based symlink manager in pure Python stdlib — no stow.

| Component | Software |
|-----------|----------|
| Desktop | Hyprland (Lua config) + Quickshell bar + Mako + Rofi + Swaylock |
| Shell | Zsh + Oh My Zsh + Starship |
| Editor | Neovim (lazy.nvim, LSP, Treesitter, Telescope), Zed |
| Terminal | Kitty + tmux (TPM) |
| Music | MPD + ncmpcpp + Yandex Music CLI + radio CLI |
| VPN | Mihomo (Clash Meta) + `vpn` manager |
| Other | btop, fastfetch, elio, opencode |

---

## Install

On a fresh Arch install (with `git` and `python` ≥ 3.11):

```bash
git clone --recursive git@github.com:diominvd/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.py setup
```

`setup` is idempotent — each step skips what is already in place:

1. **packages** — missing ones from `deps/pacman.txt` (`pacman --needed`) and
   `deps/aur.txt` (`paru` or `yay`);
2. **submodules** — nvim and the script CLIs;
3. **links** — `~/` and `~/.config` symlinks for the active theme;
4. **secrets** — seeds `~/.config/secrets/env` from `secrets/env.example`;
5. **shell plugins** — Oh My Zsh, zsh-autosuggestions, zsh-syntax-highlighting,
   TPM (cloned when missing);
6. **system files** — `system/` into `/etc` with sudo;
7. **verify** — reports broken, missing or stale links.

Hyprland must be a build with the Lua config layer (0.55+ or git): the config
is `hyprland.lua` (`hl.*` API) — https://hypr.land/news/26_lua/

---

## Commands

| Command | What it does |
|---------|--------------|
| `./install.py setup` | Fresh machine: everything above |
| `./install.py deps [--check]` | Install missing packages (`--check`: only list them) |
| `./install.py link` | Create/refresh symlinks, drop stale ones (`update` is an alias) |
| `./install.py force` | Unlink + link everything |
| `./install.py unlink` | Remove all managed symlinks |
| `./install.py cleanup` | Remove stale symlinks only |
| `./install.py status` | Per-package link status |
| `./install.py verify` | Broken / missing / stale links (non-zero exit on problems) |
| `./install.py bootstrap [-f]` | Seed secrets from templates |
| `./install.py system status\|install` | Compare / install `system/` files into `/etc` |
| `./install.py theme list\|current\|set <name>` | Themes; `set` re-links |

After adding a file to a package, run `./install.py link` — files are linked
one by one, so a new one is not visible until then.

---

## Layout

```
.dotfiles/
├── install.py         manager (stdlib only, PEP 723: `uv run install.py`)
├── deps/              pacman.txt, aur.txt — package lists for `deps` / `setup`
├── home/              -> ~/                 (.zshenv)
├── packages/<pkg>/    -> ~/.config/<pkg>/   (one package per program)
├── themes/<name>/     overlay mirroring packages/ (active theme wins per file)
├── system/            -> /                  (copied with sudo, never linked)
├── secrets/           env.example — template for ~/.config/secrets/env
└── docs/              power management notes
```

| Source | Target | Example |
|--------|--------|---------|
| `home/<file>` | `~/<file>` | `home/.zshenv` → `~/.zshenv` |
| `packages/<pkg>/<rel>` | `~/.config/<pkg>/<rel>` | `packages/kitty/kitty.conf` |
| `themes/<t>/<pkg>/<rel>` | same target, shadows the package file | `themes/gruvbox/kitty/colors.conf` |
| `system/<path>` | `/<path>` | `system/etc/tlp.d/99-dotfiles.conf` |

- **package.toml** (optional, per package) overrides the install dir or single
  targets:

  ```toml
  dir = "~/.config"                         # default ~/.config/<pkg>

  [files]
  "starship.toml" = "~/.config/starship.toml"
  ```

- **Themes.** `themes/gruvbox` is the only theme; the active one is in `.theme`
  (local, git-ignored — gruvbox when absent). Mako and Swaylock exist only as
  theme files. The Quickshell bar reloads itself when the theme changes.
- **Never linked:** `.git`, `.gitignore`, `package.toml`, `node_modules`,
  `README`, `README.md`.
- **Conflicts:** correct links are kept, wrong ones replaced, real files and
  directories moved to `.bak`.
- **System files** are copied, not linked (`/etc` must not point into `$HOME`).
  `system status` shows drift; `system install` copies and applies
  (`systemd-tmpfiles --create`, `tlp start`). Keep `/etc/tlp.conf` at the
  package defaults so the `/etc/tlp.d` drop-in applies.

### Quickshell bar

`packages/quickshell/taskbar/` — plugins for Wi-Fi, Mihomo, audio, display,
battery, music and radio. Architecture, UI rules and how to add a plugin:
[`taskbar/CLAUDE.md`](packages/quickshell/taskbar/CLAUDE.md); each plugin has its
own `README.md`.

### Submodules

| Submodule | Path |
|-----------|------|
| Neovim config | `packages/nvim` → github.com/diominvd/neovim |
| Yandex Music CLI | `packages/scripts/yandex-music` → github.com/diominvd/yandex-music-cli |
| Radio CLI | `packages/scripts/radio` → github.com/diominvd/radio-cli |
| VPN manager CLI | `packages/scripts/vpn` → github.com/diominvd/vpn-manager-cli |

Change them in their own repos, then bump the pointer here:
`git submodule update --remote <path>` and commit.

---

## Secrets

| Secret | Location | In git? |
|--------|----------|---------|
| API keys (GEMINI, ANTHROPIC, OPENAI…) | `~/.config/secrets/env`, sourced by zsh | No |
| GitHub OAuth token | `~/.config/gh/hosts.yml` | No (ignored) |
| Mihomo rendered config + providers | `packages/mihomo/config.yaml`, `providers/` | No (ignored) |
| Mihomo subscriptions | `packages/mihomo/subscriptions.json` | **Yes** (private repo) |
| Yandex Music token | `~/.config/scripts/yandex-music/token` | No (local file) |

---

## Troubleshooting

- **Conflicts** → `./install.py force` (real files are kept as `.bak`).
- **New file not picked up** → `./install.py link`.
- **Empty submodules** → `git submodule update --init --recursive`.
- **Broken links** → `./install.py verify`, then `./install.py link`.
- **Missing programs** → `./install.py deps --check`.

---

## License

MIT

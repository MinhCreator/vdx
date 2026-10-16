"""dotfiles installer — repository layout: where things are and where they go."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HOME = Path.home()
TGT = HOME / ".config"
PKG = ROOT / "packages"
THEME = ROOT / "themes"
SEED = ROOT / "templates" / "secrets"
SYSTEM = ROOT / "system"

THEME_FILE = ROOT / ".theme"          # local, git-ignored; DEFAULT_THEME when absent
DEFAULT_THEME = "gruvbox"

# names that are never treated as config files
SKIP = {".git", ".gitignore", ".DS_Store", "node_modules", "package.toml", "README", "README.md"}

# directories never worth scanning for managed symlinks (~/.cache, ~/.local,
# git/npm/rust trees, ...) — keeps `link`/`status`/`verify` fast on big homes
PRUNE = {
    ".cache", ".local", ".git", "node_modules", ".npm", ".cargo", ".rustup",
    ".nvm", ".pyenv", ".conda", "target", ".var", ".mozilla",
}

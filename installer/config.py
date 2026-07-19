from pathlib import Path

DOTFILES = Path(__file__).resolve().parent.parent
HOME = Path.home()
TARGET = HOME / ".config"
DIRS = ["home", "apps", "system"]
SKIP = {".git", ".gitignore", "README.md", "README", "assets", "node_modules"}
ALLOWED_DOTS = {".zshrc", ".zshenv", ".luarc.json", ".gitignore"}

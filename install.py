#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""dotfiles — the installer (stdlib only); the code is in installer/.

Run without arguments for a menu with a status overview, `install` for the
wizard, or a command (`./install.py --help`). How the repo is laid out and
how to change it: CONVENTIONS.md.

  components.toml   what can be installed: one entry per checkbox
  .machine.toml     this machine: detected hardware, overrides, the choice (local)
  packages/<pkg>/   -> ~/.config/<pkg>/ (package.toml: dir, skip, [files])
  home/             -> ~/
  themes/<name>/    overrides of packages/, the active theme's win (.theme, local)
  system/           -> / , copied with sudo (@KEY@: a machine value)
  installer/        the code; tests/ its tests
"""

import sys
from pathlib import Path

if sys.version_info < (3, 11):  # noqa: UP036 — the point: an older python gets a message, not a traceback
    sys.exit(f"install.py needs Python 3.11 or newer (this is {sys.version.split()[0]})")

# installer/ sits next to this file; `python3 -I install.py` would not see it
sys.path.insert(0, str(Path(__file__).resolve().parent))

from installer.cli import main  # noqa: E402

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""dotfiles — manifest-based symlink manager (stdlib only); the code is in installer/.

Run without arguments for an interactive menu with a status overview, or pass
a command (`./install.py --help`).

Layout:
  home/            -> ~/                 (files linked into the home dir)
  packages/<pkg>/  -> ~/.config/<pkg>/   (one package per directory)
  themes/<name>/   -> theme overrides, mirrors the packages/ tree
  system/          -> /                  (root-owned files, copied with sudo)
  deps/            -> pacman.txt / aur.txt package lists for `deps` and `setup`
  templates/secrets/env.example -> bootstrap template for ~/.config/secrets/env
  .theme           -> active theme name (local; DEFAULT_THEME when absent or gone)

`./install.py check` checks the repo itself: links, syntax, themes, packages,
the shell's registry and icons (`check --help`).

A package may ship an optional `package.toml`:

  dir  = "~/.config"                  # install dir (default ~/.config/<pkg>)
  skip = ["notes.txt"]                # extra relative paths to skip

  [files]                             # per-file target overrides
  "theme.toml" = "~/.config/custom.toml"
"""

import sys
from pathlib import Path

# installer/ sits next to this file; `python3 -I install.py` would not see it
sys.path.insert(0, str(Path(__file__).resolve().parent))

from installer.cli import main  # noqa: E402

if __name__ == "__main__":
    main()

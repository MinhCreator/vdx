"""dotfiles installer — packages from deps/: pacman and the AUR."""

from __future__ import annotations

import shutil
import subprocess

from .model import missing_packages
from .ui import confirm, heading, ok, warn


def cmd_deps(args) -> int:
    heading("Packages")
    repo, aur = missing_packages()
    if not repo and not aur:
        ok("all packages installed")
        return 0
    if repo:
        warn(f"missing (pacman): {' '.join(repo)}")
    if aur:
        warn(f"missing (aur): {' '.join(aur)}")
    if getattr(args, "check", False):
        return 1
    if not confirm("Install them?", args):
        return 1
    if repo:
        subprocess.run(["sudo", "pacman", "-S", "--needed", *repo], check=True)
    if aur:
        helper = shutil.which("paru") or shutil.which("yay")
        if helper:
            subprocess.run([helper, "-S", "--needed", *aur], check=True)
        else:
            warn(f"no AUR helper (paru / yay): install manually: {' '.join(aur)}")
    return 0

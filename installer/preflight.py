"""dotfiles installer — checks run before anything is installed; one problem stops the install.

Nothing here changes the machine. A failed check means the repo or the system
is not in a state the installer was written for, so it stops before sudo.
"""

from __future__ import annotations

import shutil

from . import detect
from .check import components_problems, hypr_problems, test_problems
from .ui import err, heading, ok


def environment_problems() -> list[str]:
    env = detect.environment()
    out = []
    if env["root"]:
        out.append("running as root: run as your user, sudo is asked for when needed")
    if not env["arch"]:
        out.append(f"distro {env['distro']!r}: only Arch Linux and its derivatives are supported")
    out += [f"{tool}: not found" for tool in ("pacman", "git", "sudo") if not shutil.which(tool)]
    return out


def preflight() -> bool:
    """Run every check; print the problems; True when the install may go on."""
    heading("Preflight")
    failed = False
    for name, run in (("environment", environment_problems), ("components", components_problems),
                      ("hypr", hypr_problems),
                      ("tests", test_problems)):
        problems = run()
        if not problems:
            ok(name)
            continue
        failed = True
        err(f"{name}: {len(problems)} problem(s)")
        for line in problems:
            print(f"      {line}")
    if failed:
        err("stopped before changing anything")
    return not failed

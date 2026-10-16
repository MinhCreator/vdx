"""dotfiles installer — command-line entry point."""

from __future__ import annotations

import argparse
import subprocess
import sys

from .check import CHECKS, cmd_check
from .choose import cmd_components
from .deps import cmd_deps
from .links import cmd_cleanup, cmd_force, cmd_link, cmd_status, cmd_unlink, cmd_verify
from .machine import cmd_machine
from .menu import menu
from .setup import cmd_bootstrap, cmd_secrets, cmd_setup
from .system import cmd_system
from .theme import cmd_theme
from .ui import err


def main() -> None:
    if len(sys.argv) == 1 and sys.stdin.isatty():
        sys.exit(menu())

    yes = argparse.ArgumentParser(add_help=False)
    yes.add_argument("-y", "--yes", action="store_true", help="don't ask for confirmation")

    p = argparse.ArgumentParser(description="dotfiles manager — run without arguments for a menu")
    sub = p.add_subparsers(dest="cmd")
    sub.add_parser("link", help="create/refresh all symlinks")
    sub.add_parser("update", help="alias of link")
    sub.add_parser("force", help="unlink + link", parents=[yes])
    sub.add_parser("unlink", help="remove all managed symlinks", parents=[yes])
    sub.add_parser("cleanup", help="remove stale symlinks only")
    sub.add_parser("status", help="per-package link status")
    sub.add_parser("verify", help="check for broken/missing/stale links")
    sub.add_parser("check", help="check the repo: links, syntax, themes, components, tests, shell, repo").add_argument(
        "groups", nargs="*", metavar="group", help=", ".join(CHECKS) + " (default: all)")
    sub.add_parser("bootstrap", help="copy seed templates to ~/.config").add_argument(
        "-f", "--force", action="store_true", help="overwrite existing files")
    sub.add_parser("deps", help="install missing packages of the selected components", parents=[yes]).add_argument(
        "--check", action="store_true", help="only list what is missing")
    sub.add_parser("setup", help="fresh machine: preflight, packages, submodules, links, secrets, plugins, system",
                   parents=[yes])
    sy = sub.add_parser("system", help="root-owned files under system/ (copied with sudo)", parents=[yes])
    sy.add_argument("s_action", choices=["status", "install"])
    se = sub.add_parser("secrets", help="secret files from private/: status or restore")
    se.add_argument("s_action", choices=["status", "restore"], nargs="?", default="status")
    te = sub.add_parser("theme", help="theme management")
    tsub = te.add_subparsers(dest="t_action", required=True)
    tsub.add_parser("list", help="list available themes")
    tsub.add_parser("current", help="show active theme")
    tsub.add_parser("set", help="switch theme").add_argument("t_name")
    ma = sub.add_parser("machine", help="this machine's profile: show or detect (.machine.toml)", parents=[yes])
    ma.add_argument("m_action", choices=["show", "detect"], nargs="?", default="show")
    co = sub.add_parser("components", help="what is installed: list, add or remove components", parents=[yes])
    co.add_argument("c_action", choices=["list", "add", "remove"], nargs="?", default="list")
    co.add_argument("names", nargs="*", metavar="component")

    args = p.parse_args()
    commands = {
        "link": cmd_link, "update": cmd_link, "force": cmd_force, "unlink": cmd_unlink,
        "cleanup": cmd_cleanup, "status": cmd_status, "verify": cmd_verify, "check": cmd_check,
        "bootstrap": cmd_bootstrap, "deps": cmd_deps, "setup": cmd_setup,
        "system": cmd_system, "theme": cmd_theme, "secrets": cmd_secrets,
        "machine": cmd_machine, "components": cmd_components,
    }
    if args.cmd not in commands:
        p.print_help()
        return
    try:
        sys.exit(commands[args.cmd](args) or 0)
    except subprocess.CalledProcessError as e:
        err(f"command failed: {' '.join(map(str, e.cmd))}")
        sys.exit(e.returncode or 1)
    except KeyboardInterrupt:
        print()
        sys.exit(130)

import argparse

from installer.commands import (
    cmd_link,
    cmd_update,
    cmd_force,
    cmd_cleanup,
    cmd_unlink,
    cmd_status,
    cmd_verify,
)
from installer.tui import tui_main

COMMANDS = {
    "link": cmd_link,
    "update": cmd_update,
    "force": cmd_force,
    "cleanup": cmd_cleanup,
    "unlink": cmd_unlink,
    "status": cmd_status,
    "verify": cmd_verify,
}


def main():
    p = argparse.ArgumentParser(description="Dotfiles manager")
    sub = p.add_subparsers(dest="cmd")
    sub.add_parser("link", help="Create all symlinks")
    sub.add_parser("update", help="Add only new files")
    sub.add_parser("force", help="Recreate all symlinks")
    sub.add_parser("cleanup", help="Remove stale & broken symlinks")
    sub.add_parser("unlink", help="Remove all symlinks")
    sub.add_parser("status", help="Show package status")
    sub.add_parser("verify", help="Check for broken symlinks")
    sub.add_parser("tui", help="Interactive TUI mode")

    args = p.parse_args()

    if args.cmd is None or args.cmd == "tui":
        tui_main()
    elif args.cmd in COMMANDS:
        COMMANDS[args.cmd](args)

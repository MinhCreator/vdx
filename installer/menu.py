"""dotfiles installer — the interactive menu: a status overview and the commands."""

from __future__ import annotations

import argparse
import subprocess

from . import components
from .check import cmd_check
from .deps import cmd_deps
from .links import cmd_force, cmd_link, cmd_status, cmd_unlink, cmd_verify
from .machine import describe, hardware, load
from .model import (
    active_theme,
    build_entries,
    link_counts,
    missing_packages,
    stale_links,
    system_state,
    themes,
)
from .paths import ROOT
from .setup import cmd_setup
from .system import cmd_system_install
from .theme import cmd_theme
from .ui import bold, clear, cyan, dim, err, green, heading, short, warn, yellow
from .wizard import cmd_install


def overview() -> None:
    entries = build_entries()
    good, bad = link_counts(entries)
    stale = len(stale_links(entries))
    sys_state = system_state()
    drift = sum(1 for *_, s in sys_state if s in ("differs", "missing"))
    unknown = sum(1 for *_, s in sys_state if s == "unreadable")
    repo, aur = missing_packages()
    branch = subprocess.run(["git", "-C", str(ROOT), "branch", "--show-current"],
                            capture_output=True, text=True).stdout.strip()

    def row(label: str, value: str, healthy: bool) -> None:
        print(f"  {(green('●') if healthy else yellow('●'))} {label:10s} {value}")

    print(f"\n  {bold('dotfiles')}  {dim(short(ROOT))}  {dim(branch)}\n")
    profile = load()
    row("machine", describe(hardware(profile)) + ("" if profile else " · not saved"), profile is not None)
    cat = components.load()
    on = components.selected(profile, cat)
    total = [n for n, c in cat.items() if c["group"] != "core"]
    row("components", f"{len([n for n in total if n in on])} of {len(total)} on"
        + ("" if components.saved(profile) is not None else " · nothing chosen yet"), True)
    row("theme", active_theme() or "none", active_theme() is not None)
    row("links", f"{good} ok" + (f" · {bad} problem(s)" if bad else "") + (f" · {stale} stale" if stale else ""),
        not bad and not stale)
    row("system", f"{len(sys_state) - drift - unknown}/{len(sys_state)} in sync"
        + (f" · {unknown} root-only" if unknown else ""), drift == 0)
    missing = repo + aur
    row("packages", "all installed" if not missing else f"{len(missing)} missing ({' '.join(missing)})",
        not missing)


MENU = [
    ("install", "Install", "the wizard: pick components and settings, then set up", cmd_install),
    ("link", "Link", "create / refresh symlinks", cmd_link),
    ("status", "Status", "per-package link status", cmd_status),
    ("verify", "Verify", "broken / missing / stale links", cmd_verify),
    ("check", "Check", "the repo: links, syntax, themes, packages, shell", cmd_check),
    ("deps", "Packages", "install missing packages", cmd_deps),
    ("system", "System", "copy system/ files into /etc", cmd_system_install),
    ("theme", "Theme", "switch the active theme", None),
    ("setup", "Setup", "full setup for a fresh machine", cmd_setup),
    ("force", "Re-link", "remove and recreate every symlink", cmd_force),
    ("unlink", "Unlink", "remove every managed symlink", cmd_unlink),
]


def pick_theme(args) -> int:
    names = themes()
    heading("Themes")
    for i, name in enumerate(names, 1):
        print(f"  {cyan(str(i))}  {name}{dim(' (active)') if name == active_theme() else ''}")
    choice = input(f"\n  {yellow('?')} Theme number {dim('(Enter: cancel)')} ").strip()
    if not choice.isdigit() or not 1 <= int(choice) <= len(names):
        return 0
    args.t_action, args.t_name = "set", names[int(choice) - 1]
    return cmd_theme(args)


def menu() -> int:
    args = argparse.Namespace(yes=False, check=False, force=False, groups=[])
    problem = ""                      # shown under the menu after a redraw
    while True:
        clear()
        overview()
        print()
        for i, (_, label, desc, _) in enumerate(MENU, 1):
            print(f"  {cyan(str(i))}  {label:9s} {dim(desc)}")
        print(f"  {cyan('q')}  {'Quit':9s}")
        if problem:
            print()
            warn(problem)
            problem = ""
        try:
            choice = input(f"\n  {yellow('?')} Choose ").strip().lower()
        except (EOFError, KeyboardInterrupt):
            print()
            return 0
        if choice in ("q", "quit", "exit", ""):
            return 0
        if not choice.isdigit() or not 1 <= int(choice) <= len(MENU):
            problem = f"no such item: {choice}"
            continue
        name, *_, action = MENU[int(choice) - 1]
        clear()
        try:
            (pick_theme if name == "theme" else action)(args)
            input(f"\n  {dim('Enter — back to the menu')} ")
        except subprocess.CalledProcessError as e:
            err(f"command failed: {' '.join(map(str, e.cmd))}")
            input(f"\n  {dim('Enter — back to the menu')} ")
        except (EOFError, KeyboardInterrupt):
            print()

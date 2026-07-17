#!/usr/bin/env python3
"""Dotfiles manager — smart symlinks without stow."""
import os
import shutil
import subprocess
import sys
import termios
from pathlib import Path

DOTFILES = Path(__file__).resolve().parent
HOME = Path.home()
TARGET = HOME / ".config"
DIRS = ["home", "apps", "system"]
SKIP = {".git", ".gitignore", "README.md", "README", "assets", "node_modules"}


# ─── ANSI ──────────────────────────────────────────────────────────────────────

class C:
    B  = "\033[1m"
    D  = "\033[2m"
    G  = "\033[32m"
    Y  = "\033[33m"
    R  = "\033[31m"
    CN = "\033[36m"
    M  = "\033[35m"
    BL = "\033[34m"
    X  = "\033[0m"
    CLR = "\033[2J\033[H"
    HID = "\033[?25l"
    SHW = "\033[?25h"


def ok(m):    print(f"  {C.G}✓{C.X} {m}")
def warn(m):  print(f"  {C.Y}!{C.X} {m}")
def fail(m):  print(f"  {C.R}✗{C.X} {m}")
def info(m):  print(f"  {C.CN}→{C.X} {m}")
def skip(m):  print(f"  {C.D}– {C.X} {m}")
def fix(m):   print(f"  {C.M}⚡{C.X} {m}")


def header(m):
    print(f"\n  {C.B}{C.CN}{'─' * 50}{C.X}")
    print(f"  {C.B}{m}{C.X}")
    print(f"  {C.B}{C.CN}{'─' * 50}{C.X}\n")


def divider():
    print(f"  {C.D}{'─' * 50}{C.X}")


def pause():
    print()
    input(f"  {C.D}Press Enter...{C.X}")


# ─── Link Map ─────────────────────────────────────────────────────────────────

def should_skip(p: Path) -> bool:
    return p.name in SKIP or (p.name.startswith(".") and p.name not in (
        ".zshrc", ".zshenv", ".luarc.json", ".gitignore"
    ))


def build_link_map() -> list[tuple[Path, Path]]:
    """Scan dirs and build (source, target) pairs."""
    links = []

    for d in DIRS:
        src = DOTFILES / d
        if not src.is_dir():
            continue

        if d == "home":
            # home/.zshenv → ~/.zshenv
            for entry in src.iterdir():
                if entry.is_file() and not should_skip(entry):
                    links.append((entry, HOME / entry.name))
        else:
            # apps/<pkg>/<file> → ~/.config/<pkg>/<file>
            # system/<pkg>/<file> → ~/.config/<pkg>/<file>
            for entry in src.iterdir():
                if entry.is_dir():
                    pkg_dir = entry
                    for f in pkg_dir.rglob("*"):
                        if f.is_file() and not should_skip(f) and not should_skip(f.parent):
                            rel = f.relative_to(src)
                            links.append((f, TARGET / rel))
                elif entry.is_file() and not should_skip(entry):
                    # Standalone file: apps/starship.toml → ~/.config/starship.toml
                    links.append((entry, TARGET / entry.name))

    return links


def is_managed(link: Path) -> bool:
    """Check if a symlink was created by us."""
    if not link.is_symlink():
        return False
    try:
        return str(link.resolve()).startswith(str(DOTFILES))
    except (OSError, ValueError):
        return False


# ─── Commands ──────────────────────────────────────────────────────────────────

def cmd_link(args):
    header("Linking dotfiles")
    links = build_link_map()
    created = 0
    skipped = 0
    errors = 0

    for src, tgt in links:
        if tgt.exists() or tgt.is_symlink():
            if is_managed(tgt):
                try:
                    if tgt.resolve() == src.resolve():
                        skipped += 1
                        continue
                except (OSError, ValueError):
                    pass
            # Conflict: real file/dir or wrong symlink
            if tgt.is_dir() and not tgt.is_symlink():
                has_real = any(c.is_file() and not c.is_symlink() for c in tgt.rglob("*"))
                if has_real:
                    backup = tgt.with_suffix(".bak")
                    if backup.exists():
                        shutil.rmtree(backup)
                    shutil.move(str(tgt), str(backup))
                    fix(f"{tgt.name} → {backup.name}")
                else:
                    shutil.rmtree(tgt)
                    fix(f"removed empty dir: {tgt.name}")
            elif tgt.is_symlink():
                tgt.unlink()
                fix(f"removed wrong symlink: {tgt.name}")
            elif tgt.is_file():
                backup = tgt.with_suffix(".bak")
                if backup.exists():
                    backup.unlink()
                shutil.move(str(tgt), str(backup))
                fix(f"{tgt.name} → {backup.name}")

        # Create parent dirs
        tgt.parent.mkdir(parents=True, exist_ok=True)

        # Create symlink
        rel = os.path.relpath(src, tgt.parent)
        tgt.symlink_to(rel)
        created += 1
        ok(f"{tgt.relative_to(HOME)}")

    divider()
    info(f"Created: {created} | Up to date: {skipped}")
    ok("Done")


def cmd_unlink(args):
    header("Removing managed symlinks")
    links = build_link_map()
    removed = 0

    for _, tgt in links:
        if tgt.is_symlink() and is_managed(tgt):
            tgt.unlink()
            removed += 1
            ok(f"removed: {tgt.relative_to(HOME)}")

    # Clean empty dirs
    for p in sorted(TARGET.glob("*")):
        if p.is_dir() and not any(p.iterdir()):
            p.rmdir()
            ok(f"removed empty dir: {p.name}")

    divider()
    info(f"Removed: {removed}")
    ok("Done")


def cmd_update(args):
    header("Updating — adding new files only")
    links = build_link_map()
    added = 0
    skipped = 0

    for src, tgt in links:
        if tgt.is_symlink() and is_managed(tgt):
            try:
                if tgt.resolve() == src.resolve():
                    skipped += 1
                    continue
            except (OSError, ValueError):
                pass

        # New or wrong — link it
        if tgt.exists() or tgt.is_symlink():
            if tgt.is_dir() and not tgt.is_symlink():
                if not any(c.is_file() and not c.is_symlink() for c in tgt.rglob("*")):
                    shutil.rmtree(tgt)
                    fix(f"removed empty dir: {tgt.name}")
                else:
                    warn(f"skipped (real dir): {tgt.relative_to(HOME)}")
                    continue
            elif tgt.is_symlink():
                tgt.unlink()
            elif tgt.is_file():
                backup = tgt.with_suffix(".bak")
                if backup.exists():
                    backup.unlink()
                shutil.move(str(tgt), str(backup))
                fix(f"{tgt.name} → {backup.name}")

        tgt.parent.mkdir(parents=True, exist_ok=True)
        rel = os.path.relpath(src, tgt.parent)
        tgt.symlink_to(rel)
        added += 1
        ok(f"+ {tgt.relative_to(HOME)}")

    divider()
    info(f"Added: {added} | Up to date: {skipped}")
    ok("Done")


def cmd_status(args):
    header("Package status")
    raw_links = build_link_map()

    # Classify each link
    links = []
    for src, tgt in raw_links:
        try:
            rel = tgt.relative_to(TARGET)
            pkg = rel.parts[0] if len(rel.parts) > 1 else "(root)"
        except ValueError:
            pkg = "(home)"

        if tgt.is_symlink() and is_managed(tgt):
            try:
                status = "linked" if tgt.resolve() == src.resolve() else "wrong"
            except (OSError, ValueError):
                status = "broken"
        elif tgt.exists():
            status = "conflict"
        else:
            status = "missing"

        links.append((pkg, src, tgt, status))

    # Group by package
    pkgs: dict[str, list] = {}
    for pkg, src, tgt, status in links:
        pkgs.setdefault(pkg, []).append((src, tgt, status))

    for pkg in sorted(pkgs):
        items = pkgs[pkg]
        n_linked = sum(1 for _, _, s in items if s == "linked")
        n_missing = sum(1 for _, _, s in items if s == "missing")
        n_conflict = sum(1 for _, _, s in items if s in ("conflict", "wrong", "broken"))

        parts = []
        if n_linked: parts.append(f"{C.G}{n_linked} linked{C.X}")
        if n_missing: parts.append(f"{C.Y}{n_missing} missing{C.X}")
        if n_conflict: parts.append(f"{C.R}{n_conflict} problem{C.X}")
        status_str = " | ".join(parts) if parts else f"{C.D}no files{C.X}"

        print(f"    {pkg:20s} {status_str}")

    # Show problem details
    problems = [(pkg, src, tgt, s) for pkg, src, tgt, s in links if s in ("conflict", "wrong", "broken")]
    if problems:
        print()
        info("Problems:")
        for pkg, src, tgt, s in problems:
            if s == "conflict":
                print(f"    {C.R}✗{C.X} {tgt.relative_to(HOME)} (real file/dir)")
            elif s == "wrong":
                print(f"    {C.R}✗{C.X} {tgt.relative_to(HOME)} (points elsewhere)")
            elif s == "broken":
                print(f"    {C.R}✗{C.X} {tgt.relative_to(HOME)} (broken)")
    print()


def cmd_verify(args):
    header("Checking symlinks")
    links = build_link_map()
    broken = 0

    for src, tgt in links:
        if tgt.is_symlink() and not tgt.exists():
            fail(f"BROKEN: {tgt.relative_to(HOME)}")
            broken += 1

    if broken == 0:
        ok("All symlinks OK")
    else:
        fail(f"{broken} broken symlink(s)")
        sys.exit(1)


def cmd_force(args):
    header("Force relinking")
    cmd_unlink(args)
    cmd_link(args)


# ─── TUI ───────────────────────────────────────────────────────────────────────

def tui_menu(items, title="Dotfiles Manager"):
    idx = 0
    print(C.HID, end="")
    try:
        while True:
            print(C.CLR, end="")
            print()
            print(f"  {C.B}{C.CN}{title}{C.X}")
            print(f"  {C.D}{'═' * 60}{C.X}")
            print()
            for i, item in enumerate(items):
                label = item["label"]
                desc = item.get("desc", "")
                if i == idx:
                    line = f"  {C.B}{C.G}▸{C.X} {C.B}{label}{C.X}"
                    if desc:
                        line += f"  {C.D}— {desc}{C.X}"
                    print(line)
                else:
                    print(f"    {C.D}{label}{C.X}")
            print()
            print(f"  {C.D}↑/↓/j/k — navigate  Enter — select  q/Esc — quit{C.X}")

            try:
                import tty
                fd = sys.stdin.fileno()
                old = termios.tcgetattr(fd)
                try:
                    tty.setraw(fd)
                    ch = sys.stdin.read(1)
                    # Handle escape sequences (arrow keys)
                    if ch == "\x1b":
                        seq = sys.stdin.read(2)
                        if seq == "[A":
                            ch = "k"
                        elif seq == "[B":
                            ch = "j"
                        else:
                            ch = "\x1b"
                finally:
                    termios.tcsetattr(fd, termios.TCSADRAIN, old)
            except (ImportError, OSError):
                ch = input()

            if ch in ("\x1b", "q", "Q"):
                return -1
            if ch in ("\r", "\n"):
                return idx
            if ch in ("j", "J"):
                idx = (idx + 1) % len(items)
            if ch in ("k", "K"):
                idx = (idx - 1) % len(items)
    finally:
        print(C.SHW, end="")


def tui_main():
    items = [
        {"label": "Link all",      "desc": "Create all symlinks", "cmd": cmd_link},
        {"label": "Update",        "desc": "Add only new files", "cmd": cmd_update},
        {"label": "Force relink",  "desc": "Recreate all symlinks", "cmd": cmd_force},
        {"label": "Unlink",        "desc": "Remove all symlinks", "cmd": cmd_unlink},
        {"label": "Status",        "desc": "Show package status", "cmd": cmd_status},
        {"label": "Verify",        "desc": "Check for broken symlinks", "cmd": cmd_verify},
    ]

    while True:
        choice = tui_menu(items)
        if choice == -1:
            print(C.CLR, end="")
            print(f"\n  {C.D}Bye!{C.X}\n")
            break
        try:
            items[choice]["cmd"](None)
        except SystemExit:
            pass
        pause()


# ─── CLI ───────────────────────────────────────────────────────────────────────

def main():
    import argparse
    p = argparse.ArgumentParser(description="Dotfiles manager")
    sub = p.add_subparsers(dest="cmd")
    sub.add_parser("link", help="Create all symlinks")
    sub.add_parser("update", help="Add only new files")
    sub.add_parser("force", help="Recreate all symlinks")
    sub.add_parser("unlink", help="Remove all symlinks")
    sub.add_parser("status", help="Show package status")
    sub.add_parser("verify", help="Check for broken symlinks")
    sub.add_parser("tui", help="Interactive TUI mode")

    args = p.parse_args()

    commands = {
        "link": cmd_link, "update": cmd_update, "force": cmd_force,
        "unlink": cmd_unlink, "status": cmd_status, "verify": cmd_verify,
    }

    if args.cmd is None or args.cmd == "tui":
        tui_main()
    elif args.cmd in commands:
        commands[args.cmd](args)


if __name__ == "__main__":
    main()

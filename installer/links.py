"""dotfiles installer — link commands: link, unlink, force, cleanup, status, verify."""

from __future__ import annotations

from pathlib import Path

from . import hypr, shell
from .model import (
    active_theme,
    build_entries,
    cleanup_stale,
    create_symlink,
    is_managed,
    is_same,
    link_counts,
    resolve_conflict,
    stale_links,
)
from .ui import added, confirm, dim, err, heading, ok, red, short


def cmd_link(args) -> int:
    heading(f"Linking dotfiles {dim('(theme: ' + (active_theme() or 'none') + ')')}")
    entries = build_entries()
    stale = cleanup_stale(entries)
    created = 0
    for src, tgt, _ in entries:
        if is_same(tgt, src):
            continue
        resolve_conflict(tgt)
        create_symlink(src, tgt)
        added(short(tgt))
        created += 1
    ok(f"{created} created · {len(entries) - created} up to date · {stale} stale removed")
    if hypr.wanted():
        hypr.apply()
    shell.apply()
    return 0


def cmd_unlink(args) -> int:
    heading("Removing managed symlinks")
    if not confirm("Remove every symlink this repo created?", args):
        return 1
    entries = build_entries()
    n = 0
    for _, tgt, _ in entries:
        if is_managed(tgt):
            tgt.unlink(missing_ok=True)
            n += 1
    ok(f"{n} removed · {cleanup_stale(entries)} stale")
    return 0


def cmd_force(args) -> int:
    heading("Re-linking everything")
    if not confirm("Remove and recreate every symlink (real files go to .bak)?", args):
        return 1
    args.yes = True
    cmd_unlink(args)
    return cmd_link(args)


def cmd_cleanup(args) -> int:
    heading("Removing stale symlinks")
    ok(f"{cleanup_stale()} removed")
    return 0


def cmd_status(args) -> int:
    heading("Link status")
    entries = build_entries()
    by_pkg: dict[str, list[tuple[Path, Path, str]]] = {}
    for e in entries:
        by_pkg.setdefault(e[2], []).append(e)
    for pkg in sorted(by_pkg):
        good, bad = link_counts(by_pkg[pkg])
        line = f"{pkg:14s} {good} linked"
        (err if bad else ok)(line + (red(f" · {bad} problem(s)") if bad else ""))
    stale = stale_links(entries)
    for p in stale:
        err(f"{short(p)} {dim('(stale)')}")
    return 0


def link_problems(entries: list[tuple[Path, Path, str]]) -> list[str]:
    """Broken, missing and stale links, one line each."""
    out = []
    for src, tgt, _ in entries:
        issue = ("source missing" if not src.exists()
                 else "broken" if tgt.is_symlink() and not tgt.exists()
                 else "missing" if not tgt.exists() and not tgt.is_symlink()
                 else None)
        if issue:
            out.append(f"{short(tgt)} ({issue})")
    return out + [f"{short(p)} (stale)" for p in stale_links(entries)]


def cmd_verify(args) -> int:
    heading("Verifying links")
    entries = build_entries()
    problems = link_problems(entries)
    for line in problems:
        err(line)
    if problems:
        err(f"{len(problems)} problem(s) — run `./install.py link`")
        return 1
    ok(f"all {len(entries)} links ok")
    return 0

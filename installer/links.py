from __future__ import annotations

import os
import shutil
from dataclasses import dataclass
from pathlib import Path
from enum import Enum

from installer.config import DOTFILES, HOME, TARGET, DIRS, SKIP, ALLOWED_DOTS
from installer.ansi import ok, fix


class Status(Enum):
    LINKED = "linked"
    WRONG = "wrong"
    BROKEN = "broken"
    CONFLICT = "conflict"
    MISSING = "missing"
    SOURCE_MISSING = "source_missing"


@dataclass
class Link:
    src: Path
    tgt: Path
    pkg: str = ""
    status: Status = Status.MISSING


def should_skip(p: Path) -> bool:
    return p.name in SKIP or (p.name.startswith(".") and p.name not in ALLOWED_DOTS)


def build_link_map() -> list[Link]:
    links = []

    for d in DIRS:
        src = DOTFILES / d
        if not src.is_dir():
            continue

        if d == "home":
            for entry in src.iterdir():
                if entry.is_file() and not should_skip(entry):
                    links.append(Link(src=entry, tgt=HOME / entry.name, pkg="(home)"))
        else:
            for entry in src.iterdir():
                if entry.is_dir():
                    for f in entry.rglob("*"):
                        if (
                            f.is_file()
                            and not should_skip(f)
                            and not should_skip(f.parent)
                        ):
                            rel = f.relative_to(src)
                            links.append(Link(src=f, tgt=TARGET / rel, pkg=entry.name))
                elif entry.is_file() and not should_skip(entry):
                    links.append(Link(src=entry, tgt=TARGET / entry.name, pkg="(root)"))

    return links


def classify(link: Link) -> Status:
    src, tgt = link.src, link.tgt

    if not src.exists():
        return Status.SOURCE_MISSING

    if tgt.is_symlink() and is_managed(tgt):
        try:
            return Status.LINKED if tgt.resolve() == src.resolve() else Status.WRONG
        except (OSError, ValueError):
            return Status.BROKEN

    if tgt.exists():
        return Status.CONFLICT

    return Status.MISSING


def is_managed(link: Path) -> bool:
    if not link.is_symlink():
        return False
    try:
        return str(link.resolve()).startswith(str(DOTFILES))
    except (OSError, ValueError):
        return False


def find_managed_symlinks() -> list[Path]:
    found = []
    if TARGET.is_dir():
        for p in TARGET.rglob("*"):
            if p.is_symlink() and is_managed(p):
                found.append(p)
    home_dir = DOTFILES / "home"
    if home_dir.is_dir():
        for entry in home_dir.iterdir():
            if entry.is_file() and not should_skip(entry):
                tgt = HOME / entry.name
                if tgt.is_symlink() and is_managed(tgt):
                    found.append(tgt)
    return found


def stale_links() -> list[Path]:
    expected = {link.tgt for link in build_link_map()}
    return [p for p in find_managed_symlinks() if p not in expected]


def cleanup_stale() -> int:
    removed = 0
    for p in stale_links():
        p.unlink()
        fix(f"removed stale: {p.relative_to(HOME)}")
        removed += 1
    return removed


def is_same_link(tgt: Path, src: Path) -> bool:
    if not tgt.is_symlink() or not is_managed(tgt):
        return False
    try:
        return tgt.resolve() == src.resolve()
    except (OSError, ValueError):
        return False


def resolve_conflict(tgt: Path) -> bool:
    """Clear target path for a new symlink. Returns True if cleared, False to skip."""
    if not tgt.exists() and not tgt.is_symlink():
        return True

    if tgt.is_dir() and not tgt.is_symlink():
        has_real = any(c.is_file() and not c.is_symlink() for c in tgt.rglob("*"))
        if has_real:
            backup = tgt.with_suffix(".bak")
            if backup.exists():
                shutil.rmtree(backup)
            shutil.move(str(tgt), str(backup))
            fix(f"{tgt.name} \u2192 {backup.name}")
        else:
            shutil.rmtree(tgt)
            fix(f"removed empty dir: {tgt.name}")
        return True

    if tgt.is_symlink():
        tgt.unlink()
        return True

    if tgt.is_file():
        backup = tgt.with_suffix(".bak")
        if backup.exists():
            backup.unlink()
        shutil.move(str(tgt), str(backup))
        fix(f"{tgt.name} \u2192 {backup.name}")
        return True

    return True


def create_symlink(src: Path, tgt: Path):
    tgt.parent.mkdir(parents=True, exist_ok=True)
    rel = os.path.relpath(src, tgt.parent)
    tgt.symlink_to(rel)


def remove_empty_dirs():
    for p in sorted(TARGET.glob("*")):
        if p.is_dir() and not any(p.iterdir()):
            p.rmdir()
            ok(f"removed empty dir: {p.name}")

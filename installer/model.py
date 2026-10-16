"""dotfiles installer — the link model: packages, themes, managed symlinks, system files, package lists."""

from __future__ import annotations

import os
import shutil
import subprocess
import tomllib
from pathlib import Path

from .paths import (
    DEFAULT_THEME,
    DEPS,
    HOME,
    PKG,
    PRUNE,
    ROOT,
    SKIP,
    SYSTEM,
    TGT,
    THEME,
    THEME_FILE,
)
from .ui import dim, err, removed, short, warn


def expand(p: str) -> Path:
    return Path(os.path.expanduser(p))


def active_theme() -> str | None:
    """The theme in .theme; DEFAULT_THEME when unset or gone; None without either."""
    name = THEME_FILE.read_text().strip() if THEME_FILE.exists() else ""
    return next((n for n in (name, DEFAULT_THEME) if n and (THEME / n).is_dir()), None)


def themes() -> list[str]:
    if not THEME.is_dir():
        return []
    return sorted(d.name for d in THEME.iterdir() if d.is_dir() and not d.name.startswith("."))


def parse_pkg(pkg: str) -> dict:
    mf = PKG / pkg / "package.toml"
    if mf.is_file():
        try:
            return tomllib.loads(mf.read_text())
        except tomllib.TOMLDecodeError as e:
            err(f"{pkg}: bad package.toml: {e}")
    return {}


def install_dir(pkg: str, man: dict) -> Path:
    d = man.get("dir")
    return expand(d) if d else TGT / pkg


def pkg_names() -> list[str]:
    names = set()
    if PKG.is_dir():
        names |= {p.name for p in PKG.iterdir() if p.is_dir() and not p.name.startswith(".")}
    act = active_theme()
    if act:
        names |= {p.name for p in (THEME / act).iterdir() if p.is_dir()}
    return sorted(names)


def sources_for(pkg: str) -> list[tuple[str, Path]]:
    """Return (relpath, best source) for a package, merging base + active theme."""
    act = active_theme()
    base = PKG / pkg
    th = (THEME / act / pkg) if act else None

    rels: set[str] = set()
    if base.is_dir():
        rels |= {str(f.relative_to(base)) for f in base.rglob("*") if f.is_file()}
    if th and th.is_dir():
        rels |= {str(f.relative_to(th)) for f in th.rglob("*") if f.is_file()}

    # every rel is a file of the theme or of the base: the theme's wins
    return [(rel, th / rel if th and (th / rel).is_file() else base / rel) for rel in sorted(rels)]


def build_entries() -> list[tuple[Path, Path, str]]:
    entries: list[tuple[Path, Path, str]] = []

    if (ROOT / "home").is_dir():
        for f in sorted((ROOT / "home").iterdir()):
            if f.is_file() and f.name not in SKIP:
                entries.append((f, HOME / f.name, "(home)"))

    for pkg in pkg_names():
        man = parse_pkg(pkg)
        idir = install_dir(pkg, man)
        files_map = man.get("files") or {}
        pkg_skip = set(man.get("skip") or [])
        for rel, src in sources_for(pkg):
            if Path(rel).name in SKIP or rel in pkg_skip:
                continue
            tgt = expand(str(files_map[rel])) if rel in files_map else idir / rel
            entries.append((src, tgt, pkg))

    return entries


def is_managed(p: Path) -> bool:
    """A symlink into this repo (a sibling like ~/.dotfiles-old is not)."""
    if not p.is_symlink():
        return False
    try:
        return p.resolve().is_relative_to(ROOT)
    except (OSError, RuntimeError):
        return False


def _walk(base: Path):
    """Yield file paths under base, pruning heavy/uninteresting dirs."""
    for root, dirs, files in os.walk(base):
        dirs[:] = sorted(d for d in dirs if d not in PRUNE)
        for name in sorted(files):
            yield Path(root) / name


def find_managed() -> list[Path]:
    """Every symlink under ~ (~/.config included) that points into the repo."""
    return [p for p in _walk(HOME) if is_managed(p)]


def stale_links(entries: list[tuple[Path, Path, str]]) -> list[Path]:
    expected = {t for _, t, _ in entries}
    return [p for p in find_managed() if p not in expected]


def cleanup_stale(entries: list[tuple[Path, Path, str]] | None = None) -> int:
    entries = entries if entries is not None else build_entries()
    n = 0
    for p in stale_links(entries):
        p.unlink(missing_ok=True)
        removed(f"{short(p)} {dim('(stale)')}")
        n += 1
    return n


def is_same(tgt: Path, src: Path) -> bool:
    if not tgt.is_symlink() or not is_managed(tgt):
        return False
    try:
        return tgt.resolve() == src.resolve()
    except (OSError, ValueError):
        return False


def resolve_conflict(tgt: Path) -> None:
    """Make room for a symlink. Backs up real files/dirs with .bak."""
    if not tgt.exists() and not tgt.is_symlink():
        return
    if tgt.is_symlink():
        tgt.unlink(missing_ok=True)
        return
    bak = tgt.with_name(tgt.name + ".bak")             # kitty.conf -> kitty.conf.bak
    if tgt.is_dir():
        if not any(c.is_file() and not c.is_symlink() for c in tgt.rglob("*")):
            shutil.rmtree(tgt)
            return
        if bak.exists():
            shutil.rmtree(bak)
    elif bak.exists():
        bak.unlink()
    shutil.move(str(tgt), str(bak))
    warn(f"backed up {short(tgt)} -> .bak")


def create_symlink(src: Path, tgt: Path) -> None:
    tgt.parent.mkdir(parents=True, exist_ok=True)
    tgt.symlink_to(os.path.relpath(src, tgt.parent))


def link_counts(entries: list[tuple[Path, Path, str]]) -> tuple[int, int]:
    """(linked, problems) over all entries."""
    good = sum(1 for src, tgt, _ in entries if src.exists() and is_same(tgt, src))
    return good, len(entries) - good


def system_state() -> list[tuple[Path, Path, str]]:
    """(src, dst, state) for every file under system/; state is ok, differs,
    missing or unreadable (a root-only folder, /etc/polkit-1/rules.d)."""
    out = []
    for src in sorted(SYSTEM.rglob("*")) if SYSTEM.is_dir() else []:
        if not src.is_file() or src.name in SKIP:
            continue
        dst = Path("/") / src.relative_to(SYSTEM)
        try:
            state = "ok" if dst.read_bytes() == src.read_bytes() else "differs"
        except FileNotFoundError:
            state = "missing"
        except OSError:
            state = "unreadable"
        out.append((src, dst, state))
    return out


def read_list(name: str) -> list[str]:
    f = DEPS / name
    if not f.is_file():
        return []
    return [w for w in (l.split("#", 1)[0].strip() for l in f.read_text().splitlines()) if w]


def missing_packages() -> tuple[list[str], list[str]]:
    if not shutil.which("pacman"):
        return [], []
    installed = set(subprocess.run(["pacman", "-Qq"], capture_output=True, text=True).stdout.split())
    return ([p for p in read_list("pacman.txt") if p not in installed],
            [p for p in read_list("aur.txt") if p not in installed])

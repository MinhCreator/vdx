#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""dotfiles — manifest-based symlink manager (stdlib only).

Layout:
  home/            -> ~/                 (files linked into the home dir)
  packages/<pkg>/  -> ~/.config/<pkg>/   (one package per directory)
  themes/<name>/   -> theme overrides, mirrors the packages/ tree
  system/          -> /                  (root-owned files, copied with sudo)
  secrets/env.example -> bootstrap template for ~/.config/secrets/env
  .theme           -> active theme name (local; DEFAULT_THEME when absent)

A package may ship an optional `package.toml`:

  [package]
  dir        = "~/.config"            # install dir (default ~/.config/<pkg>)
  skip       = ["*.log"]              # extra names to skip

  [files]    # per-file target overrides
  "theme.toml" = "~/.config/custom.toml"

Commands: link, update, force, unlink, cleanup, status, verify,
theme (list|set|current), bootstrap, system (status|install).
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parent
HOME = Path.home()
TGT = HOME / ".config"
PKG = ROOT / "packages"
THEME = ROOT / "themes"
SEED = ROOT / "secrets"
SYSTEM = ROOT / "system"

# after installing a system file under these dirs, run the command ({} = file)
SYSTEM_APPLY = {
    "/etc/tmpfiles.d": ["systemd-tmpfiles", "--create", "{}"],
    "/etc/tlp.d": ["tlp", "start"],
}
THEME_FILE = ROOT / ".theme"          # local, git-ignored; DEFAULT_THEME when absent
DEFAULT_THEME = "gruvbox"

# names that are never treated as config files
SKIP = {".git", ".gitignore", ".DS_Store", "node_modules", "package.toml", "README", "README.md"}

# directories never worth scanning for managed symlinks (~/.cache, ~/.local,
# git/npm/rust trees, ...) — keeps `link`/`status`/`verify` fast on big homes
PRUNE = {
    ".cache",
    ".local",
    ".git",
    "node_modules",
    ".npm",
    ".cargo",
    ".rustup",
    ".nvm",
    ".pyenv",
    ".conda",
    "target",
    ".var",
    ".mozilla",
}


# --------------------------------------------------------------------------- helpers

def expand(p: str) -> Path:
    return Path(os.path.expanduser(p))


def active_theme() -> str | None:
    name = THEME_FILE.read_text().strip() if THEME_FILE.exists() else DEFAULT_THEME
    return name if name and (THEME / name).is_dir() else None


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


# --------------------------------------------------------------------------- model

def pkg_names() -> list[str]:
    names = set()
    if PKG.is_dir():
        names |= {p.name for p in PKG.iterdir() if p.is_dir() and not p.name.startswith(".")}
    act = active_theme()
    if act and (THEME / act).is_dir():
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

    out: list[tuple[str, Path]] = []
    for rel in sorted(rels):
        src = None
        if th:
            cand = th / rel
            if cand.is_file():
                src = cand
        if src is None:
            cand = base / rel
            if cand.is_file():
                src = cand
        if src is not None:
            out.append((rel, src))
    return out


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
            if rel in files_map:
                tgt = expand(str(files_map[rel]))
            else:
                tgt = idir / rel
            entries.append((src, tgt, pkg))

    return entries


def is_managed(p: Path) -> bool:
    if not p.is_symlink():
        return False
    try:
        return str(p.resolve()).startswith(str(ROOT))
    except (OSError, ValueError):
        return False


def _walk(base: Path):
    """Yield file paths under base, pruning heavy/uninteresting dirs."""
    for root, dirs, files in os.walk(base):
        dirs[:] = sorted(d for d in dirs if d not in PRUNE)
        for name in sorted(files):
            yield Path(root) / name


def find_managed() -> list[Path]:
    # A dict is used purely for dedup: HOME already contains ~/.config.
    found: dict[Path, None] = {}
    for base in (HOME, TGT):
        if not base.is_dir():
            continue
        for p in _walk(base):
            if p.is_symlink() and is_managed(p):
                found[p] = None
    return list(found)


def expected_targets(entries: list[tuple[Path, Path, str]]) -> set[Path]:
    return {t for _, t, _ in entries}


def stale_links(entries: list[tuple[Path, Path, str]]) -> list[Path]:
    expected = expected_targets(entries)
    return [p for p in find_managed() if p not in expected]


def cleanup_stale(entries: list[tuple[Path, Path, str]] | None = None) -> int:
    entries = entries if entries is not None else build_entries()
    removed = 0
    for p in stale_links(entries):
        p.unlink(missing_ok=True)
        print(f"  ~ removed stale: {p.relative_to(HOME)}")
        removed += 1
    return removed


def is_same(tgt: Path, src: Path) -> bool:
    if not tgt.is_symlink() or not is_managed(tgt):
        return False
    try:
        return tgt.resolve() == src.resolve()
    except (OSError, ValueError):
        return False


def resolve_conflict(tgt: Path) -> bool:
    """Make room for a symlink. Backs up real files/dirs with .bak."""
    if not tgt.exists() and not tgt.is_symlink():
        return True
    if tgt.is_dir() and not tgt.is_symlink():
        has_real = any(c.is_file() and not c.is_symlink() for c in tgt.rglob("*"))
        if has_real:
            bak = tgt.with_suffix(".bak")
            if bak.exists():
                shutil.rmtree(bak)
            shutil.move(str(tgt), str(bak))
            print(f"  ! backed up dir: {tgt.relative_to(HOME)} -> .bak")
        else:
            shutil.rmtree(tgt)
        return True
    if tgt.is_symlink():
        tgt.unlink(missing_ok=True)
        return True
    if tgt.is_file():
        bak = tgt.with_suffix(".bak")
        if bak.exists():
            bak.unlink()
        shutil.move(str(tgt), str(bak))
        print(f"  ! backed up file: {tgt.relative_to(HOME)} -> .bak")
        return True
    return True


def create_symlink(src: Path, tgt: Path) -> None:
    tgt.parent.mkdir(parents=True, exist_ok=True)
    rel = os.path.relpath(src, tgt.parent)
    tgt.symlink_to(rel)


# --------------------------------------------------------------------------- commands

def cmd_link(args) -> None:
    print(f"\n  Linking dotfiles (theme: {active_theme() or 'default'})\n")
    removed = cleanup_stale()
    created = skipped = 0
    for src, tgt, pkg in build_entries():
        if is_same(tgt, src):
            skipped += 1
            continue
        resolve_conflict(tgt)
        create_symlink(src, tgt)
        created += 1
        print(f"  + {tgt.relative_to(HOME)}")
    if created or removed or skipped:
        print(f"\n  created: {created} | up-to-date: {skipped} | stale removed: {removed}")
    print("  done")


def cmd_unlink(args) -> None:
    entries = build_entries()
    removed = 0
    for src, tgt, pkg in entries:
        if tgt.is_symlink():
            tgt.unlink(missing_ok=True)
            removed += 1
            print(f"  - {tgt.relative_to(HOME)}")
    r2 = cleanup_stale(entries)
    print(f"\n  removed: {removed} | stale: {r2}")
    print("  done")


def cmd_force(args) -> None:
    cmd_unlink(args)
    cmd_link(args)


def cmd_cleanup(args) -> None:
    n = cleanup_stale()
    print(f"  removed stale: {n}")


def cmd_status(args) -> None:
    entries = build_entries()
    by_pkg: dict[str, list[tuple[Path, Path, str]]] = {}
    for e in entries:
        by_pkg.setdefault(e[2], []).append(e)

    for pkg in sorted(by_pkg):
        items = by_pkg[pkg]
        n_ok = 0
        n_prob = 0
        for src, tgt, _ in items:
            if src is None or not src.exists():
                n_prob += 1
            elif tgt.is_symlink() and is_same(tgt, src):
                n_ok += 1
            elif tgt.exists() and not tgt.is_symlink():
                n_prob += 1
            else:
                n_prob += 1
        print(f"  {pkg:20s} {n_ok} linked | {n_prob} problems")

    stale = stale_links(entries)
    if stale:
        print(f"\n  stale ({len(stale)}):")
        for p in stale:
            print(f"    x {p.relative_to(HOME)}")


def cmd_verify(args) -> None:
    entries = build_entries()
    broken = 0
    for src, tgt, pkg in entries:
        if not src.exists():
            print(f"  x SOURCE MISSING: {tgt.relative_to(HOME)}")
            broken += 1
        elif tgt.is_symlink() and not tgt.exists():
            print(f"  x BROKEN: {tgt.relative_to(HOME)}")
            broken += 1
        elif not tgt.exists() and not tgt.is_symlink():
            print(f"  x MISSING: {tgt.relative_to(HOME)}")
            broken += 1
    for p in stale_links(entries):
        print(f"  x STALE: {p.relative_to(HOME)}")
        broken += 1
    print(f"  {'all ok' if broken == 0 else f'{broken} problem(s)'}")
    return 1 if broken else 0


def cmd_theme(args) -> None:
    if args.t_action == "list":
        for d in sorted(THEME.iterdir()) if THEME.is_dir() else []:
            if d.is_dir() and not d.name.startswith("."):
                mark = " (active)" if d.name == active_theme() else ""
                print(f"  {d.name}{mark}")
    elif args.t_action == "current":
        print(active_theme() or "none")
    elif args.t_action == "set":
        name = args.t_name
        if not (THEME / name).is_dir():
            print(f"  x unknown theme: {name}")
            sys.exit(1)
        THEME_FILE.write_text(name + "\n")
        print(f"  switched to theme: {name}")
        cmd_link(args)


def cmd_bootstrap(args) -> None:
    jobs = [
        (SEED / "env.example", TGT / "secrets" / "env", 0o600, "secrets env"),
        (PKG / "scripts" / "vpn" / "subscriptions.json.example", TGT / "scripts" / "vpn" / "subscriptions.json", 0o644, "vpn subscriptions"),
    ]
    done = 0
    for src, tgt, mode, label in jobs:
        if not src.is_file():
            continue
        if tgt.exists() and not args.force:
            print(f"  - exists, skip: {label} ({tgt.relative_to(HOME)})")
            continue
        tgt.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, tgt)
        os.chmod(tgt, mode)
        print(f"  + {label} -> {tgt.relative_to(HOME)}")
        done += 1
    if done == 0:
        print("  nothing to bootstrap")


def system_files() -> list[tuple[Path, Path]]:
    if not SYSTEM.is_dir():
        return []
    return [(f, Path("/") / f.relative_to(SYSTEM))
            for f in sorted(SYSTEM.rglob("*")) if f.is_file() and f.name not in SKIP]


def cmd_system(args) -> None:
    """Root-owned files are copied, not linked: /etc must not point into $HOME."""
    changed = []
    for src, dst in system_files():
        state = "ok" if dst.is_file() and dst.read_bytes() == src.read_bytes() else \
                "differs" if dst.exists() else "missing"
        if state != "ok":
            changed.append((src, dst))
        if args.s_action == "status":
            print(f"  {'=' if state == 'ok' else 'x'} {dst}  ({state})")
    if args.s_action == "status":
        return
    if not changed:
        print("  system files are up to date")
        return
    for src, dst in changed:
        subprocess.run(["sudo", "install", "-Dm644", str(src), str(dst)], check=True)
        print(f"  + {dst}")
        for prefix, cmd in SYSTEM_APPLY.items():
            if str(dst).startswith(prefix + "/"):
                subprocess.run(["sudo", *(a.replace("{}", str(dst)) for a in cmd)], check=False)
    print("  done")


# --------------------------------------------------------------------------- cli

def main() -> None:
    p = argparse.ArgumentParser(description="dotfiles manager")
    sub = p.add_subparsers(dest="cmd")
    sub.add_parser("link", help="create/refresh all symlinks")
    sub.add_parser("update", help="alias of link")
    sub.add_parser("force", help="unlink + link")
    sub.add_parser("unlink", help="remove all managed symlinks")
    sub.add_parser("cleanup", help="remove stale symlinks only")
    sub.add_parser("status", help="per-package link status")
    sub.add_parser("verify", help="check for broken/missing/stale links")
    sub.add_parser("bootstrap", help="copy seed templates to ~/.config").add_argument(
        "-f", "--force", action="store_true"
    )
    sy = sub.add_parser("system", help="root-owned files under system/ (copied with sudo)")
    sy.add_argument("s_action", choices=["status", "install"])
    te = sub.add_parser("theme", help="theme management")
    tsub = te.add_subparsers(dest="t_action", required=True)
    tsub.add_parser("list", help="list available themes")
    tsub.add_parser("current", help="show active theme")
    tp = tsub.add_parser("set", help="switch theme")
    tp.add_argument("t_name")

    args = p.parse_args()

    if args.cmd in ("link", "update"):
        cmd_link(args)
    elif args.cmd == "force":
        cmd_force(args)
    elif args.cmd == "unlink":
        cmd_unlink(args)
    elif args.cmd == "cleanup":
        cmd_cleanup(args)
    elif args.cmd == "status":
        cmd_status(args)
    elif args.cmd == "verify":
        sys.exit(cmd_verify(args))
    elif args.cmd == "bootstrap":
        cmd_bootstrap(args)
    elif args.cmd == "theme":
        cmd_theme(args)
    elif args.cmd == "system":
        cmd_system(args)
    else:
        p.print_help()


if __name__ == "__main__":
    main()
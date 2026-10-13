#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""dotfiles — manifest-based symlink manager (stdlib only).

Run without arguments for an interactive menu with a status overview, or pass
a command (`./install.py --help`).

Layout:
  home/            -> ~/                 (files linked into the home dir)
  packages/<pkg>/  -> ~/.config/<pkg>/   (one package per directory)
  themes/<name>/   -> theme overrides, mirrors the packages/ tree
  system/          -> /                  (root-owned files, copied with sudo)
  deps/            -> pacman.txt / aur.txt package lists for `deps` and `setup`
  secrets/env.example -> bootstrap template for ~/.config/secrets/env
  .theme           -> active theme name (local; DEFAULT_THEME when absent)

A package may ship an optional `package.toml`:

  dir  = "~/.config"                  # install dir (default ~/.config/<pkg>)
  skip = ["notes.txt"]                # extra relative paths to skip

  [files]                             # per-file target overrides
  "theme.toml" = "~/.config/custom.toml"
"""

from __future__ import annotations

import argparse
import os
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
DEPS = ROOT / "deps"

THEME_FILE = ROOT / ".theme"          # local, git-ignored; DEFAULT_THEME when absent
DEFAULT_THEME = "gruvbox"

OMZ = HOME / ".local" / "share" / "oh-my-zsh"       # matches $ZSH in .zshrc
OMZ_INSTALL = "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
# repos cloned once when missing: (target, url)
CLONES = [
    (OMZ / "custom" / "plugins" / "zsh-autosuggestions", "https://github.com/zsh-users/zsh-autosuggestions"),
    (OMZ / "custom" / "plugins" / "zsh-syntax-highlighting", "https://github.com/zsh-users/zsh-syntax-highlighting"),
    (TGT / "tmux" / "plugins" / "tpm", "https://github.com/tmux-plugins/tpm"),
]

# after installing a system file under these dirs, run the command ({} = file)
SYSTEM_APPLY = {
    "/etc/tmpfiles.d": ["systemd-tmpfiles", "--create", "{}"],
    "/etc/tlp.d": ["tlp", "start"],
}

# names that are never treated as config files
SKIP = {".git", ".gitignore", ".DS_Store", "node_modules", "package.toml", "README", "README.md"}

# directories never worth scanning for managed symlinks (~/.cache, ~/.local,
# git/npm/rust trees, ...) — keeps `link`/`status`/`verify` fast on big homes
PRUNE = {
    ".cache", ".local", ".git", "node_modules", ".npm", ".cargo", ".rustup",
    ".nvm", ".pyenv", ".conda", "target", ".var", ".mozilla",
}


# --------------------------------------------------------------------------- output

COLOR = sys.stdout.isatty() and "NO_COLOR" not in os.environ


def paint(code: str, text: str) -> str:
    return f"\033[{code}m{text}\033[0m" if COLOR else text


def bold(t: str) -> str: return paint("1", t)
def dim(t: str) -> str: return paint("2", t)
def green(t: str) -> str: return paint("32", t)
def yellow(t: str) -> str: return paint("33", t)
def red(t: str) -> str: return paint("31", t)
def cyan(t: str) -> str: return paint("36", t)


def clear() -> None:
    """Wipe the terminal (menu screens only)."""
    if sys.stdout.isatty():
        print("\033[H\033[2J\033[3J", end="", flush=True)


def heading(text: str) -> None:
    print(f"\n{bold(cyan('::'))} {bold(text)}")


def mark(sym: str, color, text: str) -> None:
    print(f"  {color(sym)} {text}")


def ok(text: str) -> None: mark("✓", green, text)
def added(text: str) -> None: mark("+", green, text)
def removed(text: str) -> None: mark("-", yellow, text)
def warn(text: str) -> None: mark("!", yellow, text)
def err(text: str) -> None: mark("✗", red, text)
def note(text: str) -> None: print(f"  {dim(text)}")


def short(p: Path) -> str:
    """~/-relative path for display."""
    try:
        return "~/" + str(p.relative_to(HOME))
    except ValueError:
        return str(p)


def confirm(question: str, args) -> bool:
    """Ask before changing things; -y answers yes, no terminal answers no."""
    if getattr(args, "yes", False):
        return True
    if not sys.stdin.isatty():
        warn(f"{question} — skipped (no terminal; pass -y to confirm)")
        return False
    answer = input(f"  {yellow('?')} {question} {dim('[y/N]')} ").strip().lower()
    return answer in ("y", "yes", "д", "да")


# --------------------------------------------------------------------------- model

def expand(p: str) -> Path:
    return Path(os.path.expanduser(p))


def active_theme() -> str | None:
    name = THEME_FILE.read_text().strip() if THEME_FILE.exists() else DEFAULT_THEME
    return name if name and (THEME / name).is_dir() else None


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
            tgt = expand(str(files_map[rel])) if rel in files_map else idir / rel
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
    bak = tgt.with_suffix(".bak")
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
    """(src, dst, ok|differs|missing) for every file under system/."""
    out = []
    if SYSTEM.is_dir():
        for src in sorted(SYSTEM.rglob("*")):
            if not src.is_file() or src.name in SKIP:
                continue
            dst = Path("/") / src.relative_to(SYSTEM)
            state = "ok" if dst.is_file() and dst.read_bytes() == src.read_bytes() \
                else "differs" if dst.exists() else "missing"
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


# --------------------------------------------------------------------------- commands

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
    return 0


def cmd_unlink(args) -> int:
    heading("Removing managed symlinks")
    if not confirm("Remove every symlink this repo created?", args):
        return 1
    entries = build_entries()
    n = 0
    for _, tgt, _ in entries:
        if tgt.is_symlink():
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


def cmd_verify(args) -> int:
    heading("Verifying links")
    entries = build_entries()
    problems = 0
    for src, tgt, _ in entries:
        issue = ("source missing" if not src.exists()
                 else "broken" if tgt.is_symlink() and not tgt.exists()
                 else "missing" if not tgt.exists() and not tgt.is_symlink()
                 else None)
        if issue:
            err(f"{short(tgt)} {dim('(' + issue + ')')}")
            problems += 1
    for p in stale_links(entries):
        err(f"{short(p)} {dim('(stale)')}")
        problems += 1
    if problems:
        err(f"{problems} problem(s) — run `./install.py link`")
        return 1
    ok(f"all {len(entries)} links ok")
    return 0


def cmd_theme(args) -> int:
    if args.t_action == "list":
        heading("Themes")
        for name in themes():
            (ok if name == active_theme() else note)(name + (" (active)" if name == active_theme() else ""))
    elif args.t_action == "current":
        print(active_theme() or "none")
    elif args.t_action == "set":
        if args.t_name not in themes():
            err(f"unknown theme: {args.t_name} (have: {', '.join(themes())})")
            return 1
        THEME_FILE.write_text(args.t_name + "\n")
        ok(f"theme: {args.t_name}")
        return cmd_link(args)
    return 0


def cmd_bootstrap(args) -> int:
    heading("Seeding secrets")
    jobs = [
        (SEED / "env.example", TGT / "secrets" / "env", 0o600, "secrets env"),
    ]
    for src, tgt, mode, label in jobs:
        if not src.is_file():
            continue
        if tgt.exists() and not getattr(args, "force", False):
            note(f"{label}: {short(tgt)} exists, kept")
            continue
        tgt.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, tgt)
        os.chmod(tgt, mode)
        added(f"{label} -> {short(tgt)}")
    return 0


def cmd_system(args) -> int:
    """Root-owned files are copied, not linked: /etc must not point into $HOME."""
    state = system_state()
    if args.s_action == "status":
        heading("System files")
        for _, dst, s in state:
            (ok if s == "ok" else err)(f"{dst} {dim('(' + s + ')')}")
        return 0 if all(s == "ok" for *_, s in state) else 1
    heading("Installing system files")
    changed = [(src, dst) for src, dst, s in state if s != "ok"]
    if not changed:
        ok("system files are up to date")
        return 0
    for _, dst in changed:
        note(str(dst))
    if not confirm(f"Copy {len(changed)} file(s) into / with sudo?", args):
        return 1
    for src, dst in changed:
        subprocess.run(["sudo", "install", "-Dm644", str(src), str(dst)], check=True)
        added(str(dst))
        for prefix, cmd in SYSTEM_APPLY.items():
            if str(dst).startswith(prefix + "/"):
                subprocess.run(["sudo", *(a.replace("{}", str(dst)) for a in cmd)], check=False)
    return 0


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


def shell_extras(args=None) -> int:
    heading("Shell plugins")
    if not OMZ.is_dir():
        added("oh-my-zsh")
        script = subprocess.run(["curl", "-fsSL", OMZ_INSTALL], capture_output=True, text=True, check=True).stdout
        subprocess.run(["sh", "-c", script, "", "--unattended", "--keep-zshrc"],
                       env={**os.environ, "ZSH": str(OMZ), "RUNZSH": "no", "CHSH": "no"}, check=True)
    for target, url in CLONES:
        if not target.is_dir():
            added(short(target))
            subprocess.run(["git", "clone", "--depth", "1", "-q", url, str(target)], check=True)
    ok("oh-my-zsh, zsh plugins and TPM in place")
    return 0


def submodules(args=None) -> int:
    heading("Submodules")
    subprocess.run(["git", "-C", str(ROOT), "submodule", "update", "--init", "--recursive"], check=True)
    ok("submodules up to date")
    return 0


def cmd_setup(args) -> int:
    """Fresh machine, idempotent: every step skips what is already in place."""
    heading("Setup: packages, submodules, links, secrets, shell plugins, system files")
    if not confirm("Run the full setup (asks for sudo for packages and /etc)?", args):
        return 1
    args.yes = True
    for step in (cmd_deps, submodules, cmd_link, cmd_bootstrap, shell_extras, cmd_system_install):
        step(args)
    return cmd_verify(args)


def cmd_system_install(args) -> int:
    args.s_action = "install"
    return cmd_system(args)


# --------------------------------------------------------------------------- menu

def overview() -> None:
    entries = build_entries()
    good, bad = link_counts(entries)
    stale = len(stale_links(entries))
    sys_state = system_state()
    drift = sum(1 for *_, s in sys_state if s != "ok")
    repo, aur = missing_packages()
    branch = subprocess.run(["git", "-C", str(ROOT), "branch", "--show-current"],
                            capture_output=True, text=True).stdout.strip()

    def row(label: str, value: str, healthy: bool) -> None:
        print(f"  {(green('●') if healthy else yellow('●'))} {label:9s} {value}")

    print(f"\n  {bold('dotfiles')}  {dim(short(ROOT))}  {dim(branch)}\n")
    row("theme", active_theme() or "none", active_theme() is not None)
    row("links", f"{good} ok" + (f" · {bad} problem(s)" if bad else "") + (f" · {stale} stale" if stale else ""),
        not bad and not stale)
    row("system", f"{len(sys_state) - drift}/{len(sys_state)} in sync", drift == 0)
    missing = repo + aur
    row("packages", "all installed" if not missing else f"{len(missing)} missing ({' '.join(missing)})",
        not missing)


MENU = [
    ("link", "Link", "create / refresh symlinks", cmd_link),
    ("status", "Status", "per-package link status", cmd_status),
    ("verify", "Verify", "broken / missing / stale links", cmd_verify),
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
    args = argparse.Namespace(yes=False, check=False, force=False)
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
        except subprocess.CalledProcessError as e:
            err(f"command failed: {' '.join(map(str, e.cmd))}")
        except KeyboardInterrupt:
            print()
        input(f"\n  {dim('Enter — back to the menu')} ")


# --------------------------------------------------------------------------- cli

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
    sub.add_parser("bootstrap", help="copy seed templates to ~/.config").add_argument(
        "-f", "--force", action="store_true", help="overwrite existing files")
    sub.add_parser("deps", help="install missing packages from deps/", parents=[yes]).add_argument(
        "--check", action="store_true", help="only list what is missing")
    sub.add_parser("setup", help="fresh machine: deps, submodules, links, secrets, plugins, system",
                   parents=[yes])
    sy = sub.add_parser("system", help="root-owned files under system/ (copied with sudo)", parents=[yes])
    sy.add_argument("s_action", choices=["status", "install"])
    te = sub.add_parser("theme", help="theme management")
    tsub = te.add_subparsers(dest="t_action", required=True)
    tsub.add_parser("list", help="list available themes")
    tsub.add_parser("current", help="show active theme")
    tsub.add_parser("set", help="switch theme").add_argument("t_name")

    args = p.parse_args()
    commands = {
        "link": cmd_link, "update": cmd_link, "force": cmd_force, "unlink": cmd_unlink,
        "cleanup": cmd_cleanup, "status": cmd_status, "verify": cmd_verify,
        "bootstrap": cmd_bootstrap, "deps": cmd_deps, "setup": cmd_setup,
        "system": cmd_system, "theme": cmd_theme,
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


if __name__ == "__main__":
    main()

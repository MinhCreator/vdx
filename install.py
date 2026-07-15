#!/usr/bin/env python3
import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

DOTFILES = Path(__file__).resolve().parent
HOME = Path.home()
TARGET = HOME / ".config"

HOOKS = ["post-checkout", "post-merge", "post-rebase"]

APPS = {
    "btop": TARGET / "btop",
    "elio": TARGET / "elio",
    "fastfetch": TARGET / "fastfetch",
    "gtk-3.0": TARGET / "gtk-3.0",
    "hypr": TARGET / "hypr",
    "kitty": TARGET / "kitty",
    "mako": TARGET / "mako",
    "mihomo-tui": TARGET / "mihomo-tui",
    "ncmpcpp": TARGET / "ncmpcpp",
    "nvim": TARGET / "nvim",
    "opencode": TARGET / "opencode",
    "rofi": TARGET / "rofi",
    "starship.toml": TARGET / "starship.toml",
    "swaylock": TARGET / "swaylock",
    "telegram": TARGET / "telegram",
    "tmux": TARGET / "tmux",
    "waybar": TARGET / "waybar",
    "zsh": TARGET / "zsh",
}

SYSTEM = {
    "gh": TARGET / "gh",
    "mihomo": TARGET / "mihomo",
    "mpd": TARGET / "mpd",
    "scripts": TARGET / "scripts",
}

HOME_FILES = {
    ".zshenv": HOME / ".zshenv",
}

BOLD = "\033[1m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
CYAN = "\033[36m"
RESET = "\033[0m"


def ok(msg):
    print(f"{GREEN}✓{RESET} {msg}")


def warn(msg):
    print(f"{YELLOW}!{RESET} {msg}")


def fail(msg):
    print(f"{RED}✗{RESET} {msg}")


def info(msg):
    print(f"{CYAN}→{RESET} {msg}")


def header(msg):
    print(f"\n{BOLD}{msg}{RESET}")


def run(cmd, check=True, capture=False):
    result = subprocess.run(cmd, shell=isinstance(cmd, str), capture_output=capture, text=True)
    if check and result.returncode != 0:
        fail(f"Command failed: {cmd}")
        sys.exit(1)
    return result


def stow(source, target, pkg, delete=False):
    cmd = ["stow", "--no-folding", f"--dir={source}", f"--target={target}"]
    if delete:
        cmd.append("-D")
    cmd.append(pkg)
    return run(cmd, check=False)


def find_packages(dirpath):
    if not dirpath.is_dir():
        return []
    return [p.name for p in sorted(dirpath.iterdir()) if p.is_dir() or p.is_file()]


def resolve_target(pkg):
    if pkg in APPS:
        return TARGET
    if pkg in SYSTEM:
        return TARGET
    if pkg in HOME_FILES:
        return HOME
    return None


def cmd_link(args):
    header("Linking dotfiles")
    dirs = args.dirs or ["home", "apps", "system"]
    for d in dirs:
        src = DOTFILES / d
        if not src.is_dir():
            warn(f"Directory not found: {src}")
            continue
        if d == "home":
            tgt = HOME
        else:
            tgt = TARGET
        pkgs = find_packages(src)
        for pkg in pkgs:
            result = stow(src, tgt, pkg)
            if result.returncode == 0:
                ok(f"{pkg} → {tgt}")
            else:
                fail(f"{pkg} failed")
    header("Done")


def cmd_link_pkg(args):
    pkg = args.package
    header(f"Linking package: {pkg}")
    dirs = ["home", "apps", "system"]
    for d in dirs:
        src = DOTFILES / d
        if not src.is_dir():
            continue
        if pkg in find_packages(src):
            tgt = HOME if d == "home" else TARGET
            result = stow(src, tgt, pkg)
            if result.returncode == 0:
                ok(f"{pkg} → {tgt}")
            else:
                fail(f"{pkg} failed")
            return
    fail(f"Package '{pkg}' not found")
    sys.exit(1)


def cmd_force(args):
    header("Force relinking (removing old links first)")
    for d in ["home", "apps", "system"]:
        src = DOTFILES / d
        if not src.is_dir():
            continue
        tgt = HOME if d == "home" else TARGET
        for pkg in find_packages(src):
            stow(src, tgt, pkg, delete=True)
    ok("Old links removed, restowing...")
    args.dirs = None
    cmd_link(args)


def cmd_clean(args):
    header("Removing all symlinks")
    for d in ["home", "apps", "system"]:
        src = DOTFILES / d
        if not src.is_dir():
            continue
        tgt = HOME if d == "home" else TARGET
        for pkg in find_packages(src):
            stow(src, tgt, pkg, delete=True)
    for p in sorted(TARGET.glob("*")):
        if p.is_dir() and not any(p.iterdir()):
            p.rmdir()
            ok(f"Removed empty dir: {p}")
    header("Done")


def cmd_verify(args):
    header("Checking symlinks")
    broken = 0
    for search_dir in [HOME, TARGET]:
        for p in search_dir.rglob("*"):
            if p.is_symlink() and not p.exists():
                fail(f"BROKEN: {p}")
                broken += 1
    if broken == 0:
        ok("All symlinks OK")
    else:
        fail(f"{broken} broken symlink(s) found")
        sys.exit(1)


def cmd_check_deps(args):
    header("Checking dependencies")
    deps = {"stow": "sudo pacman -S stow", "git": "sudo pacman -S git"}
    missing = []
    for cmd, install in deps.items():
        if shutil.which(cmd):
            ok(f"{cmd} found")
        else:
            fail(f"{cmd} not found — {install}")
            missing.append(cmd)
    if missing:
        sys.exit(1)


def cmd_submodules(args):
    header("Initializing git submodules")
    run(["git", "submodule", "update", "--init", "--recursive"], check=False)
    ok("Submodules initialized")


def cmd_hooks(args):
    header("Setting up git hooks")
    hooks_dir = DOTFILES / "hooks"
    for hook in HOOKS:
        p = hooks_dir / hook
        p.chmod(p.stat().st_mode | 0o111)
        ok(f"chmod +x {hook}")
    run(["git", "config", "core.hooksPath", "hooks"], check=False)
    ok("core.hooksPath set to hooks/")


def cmd_install(args):
    cmd_check_deps(args)
    cmd_link(args)
    cmd_submodules(args)
    cmd_hooks(args)
    header("Install complete")


def cmd_setup(args):
    header("Setting up system")
    pkgs = ["stow", "git"]
    info(f"Installing packages: {', '.join(pkgs)}")
    run(["sudo", "pacman", "-S", "--needed"] + pkgs, check=False)

    if not (HOME / ".local/share/oh-my-zsh").is_dir():
        info("Installing oh-my-zsh...")
        run(
            'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended',
            check=False,
        )
    else:
        ok("oh-my-zsh already installed")

    if not shutil.which("starship"):
        info("Installing starship...")
        run("curl -sS https://starship.rs/install.sh | sh", check=False)
    else:
        ok("starship already installed")

    cmd_install(args)


def main():
    parser = argparse.ArgumentParser(
        description="Dotfiles installer for Arch Linux / Hyprland",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p_link = sub.add_parser("link", help="Deploy symlinks via stow")
    p_link.add_argument("dirs", nargs="*", help="Directories to link (default: home apps system)")

    p_pkg = sub.add_parser("link-pkg", help="Link a single package")
    p_pkg.add_argument("package", help="Package name (nvim, hypr, kitty, ...)")

    sub.add_parser("force", help="Remove old links and redeploy")
    sub.add_parser("clean", help="Remove all symlinks")
    sub.add_parser("verify", help="Check for broken symlinks")
    sub.add_parser("check-deps", help="Check required dependencies")
    sub.add_parser("submodules", help="Init git submodules")
    sub.add_parser("hooks", help="Set git hooks")
    sub.add_parser("install", help="Full install (deps + link + submodules + hooks)")
    sub.add_parser("setup", help="Install system deps + full install")

    args = parser.parse_args()

    commands = {
        "link": cmd_link,
        "link-pkg": cmd_link_pkg,
        "force": cmd_force,
        "clean": cmd_clean,
        "verify": cmd_verify,
        "check-deps": cmd_check_deps,
        "submodules": cmd_submodules,
        "hooks": cmd_hooks,
        "install": cmd_install,
        "setup": cmd_setup,
    }
    commands[args.command](args)


if __name__ == "__main__":
    main()

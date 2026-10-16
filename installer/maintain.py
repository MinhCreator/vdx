"""dotfiles installer — living with an installed machine: update, doctor, uninstall, rollback.

  update     git pull --ff-only, then setup with the new code (a fresh process)
  doctor     this machine's health: what setup would still do, plus what it
             can't see (services not running, capabilities, Hyprland's errors,
             generated files out of step, hardware changed) — each with a fix
  uninstall  links and generated files off (and our /etc files with --system);
             offers the backups back; packages, services and the repo stay
  rollback   the backed-up files back in place of the links
"""

from __future__ import annotations

import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

from . import detect, hypr, machine, shell, steps
from .model import find_managed, is_managed, render, system_files
from .paths import HOME, ROOT, STATE, SYSTEM
from .ui import confirm, dim, err, heading, note, ok, removed, short, warn

BACKUPS = STATE / "backup"
COPY = re.compile(r"\.~\d+$")          # a second copy of one path in one run's backup


def git(*cmd: str) -> subprocess.CompletedProcess:
    return subprocess.run(["git", "-C", str(ROOT), *cmd], capture_output=True, text=True)


# --------------------------------------------------------------------------- update

def cmd_update(args) -> int:
    heading("Updating the repo")
    upstream = git("rev-parse", "--abbrev-ref", "@{u}").stdout.strip()
    if not upstream:
        warn("no upstream branch: nothing to pull")
    else:
        old = git("rev-parse", "HEAD").stdout.strip()
        if getattr(args, "dry_run", False):
            git("fetch", "-q")
            incoming = git("log", "--oneline", f"HEAD..{upstream}").stdout.strip()
            (note if incoming else ok)(f"{upstream}: " + ("would pull:" if incoming else "up to date"))
            for line in incoming.splitlines():
                print(f"      {line}")
        else:
            r = git("pull", "--ff-only", "-q")
            if r.returncode:
                err("git pull --ff-only failed (local commits or changes in the way):")
                for line in (r.stderr or r.stdout).strip().splitlines()[:5]:
                    print(f"      {line}")
                return 1
            new = git("log", "--oneline", f"{old}..HEAD").stdout.strip()
            ok(f"{upstream}: " + (f"{len(new.splitlines())} new commit(s)" if new else "up to date"))
            for line in new.splitlines():
                print(f"      {line}")
    # the pull may have changed the installer itself: setup runs in a new process
    sys.stdout.flush()
    flags = [f for f, on in (("--dry-run", getattr(args, "dry_run", False)), ("-y", getattr(args, "yes", False))) if on]
    os.execv(sys.executable, [sys.executable, str(ROOT / "install.py"), "setup", *flags])


# --------------------------------------------------------------------------- doctor

def getcap(path: str) -> str:
    if not shutil.which("getcap") or not Path(path).exists():
        return ""
    return subprocess.run(["getcap", path], capture_output=True, text=True).stdout


def health(ctx: steps.Ctx) -> list[tuple[str, str, str]]:
    """(level, what, fix) for what setup's plan can't see; level is err or warn."""
    out = []
    profile = ctx.profile
    saved = profile.get("hardware")
    if saved is None:
        out.append(("warn", "no machine profile", "./install.py machine detect"))
    elif drift := machine.changes(saved, detect.hardware()):
        out.append(("warn", f"hardware changed since the profile: {', '.join(drift)}", "./install.py machine detect"))
    env = detect.environment()
    if env["hyprland"] and tuple(map(int, env["hyprland"].split("."))) < (0, 55):
        out.append(("err", f"Hyprland {env['hyprland']}: the Lua config needs 0.55+", "sudo pacman -Syu hyprland"))
    for unit in ctx.each("services"):
        if steps.enabled(unit) == "enabled" and not steps.active(unit):
            out.append(("err", f"{unit} is enabled but not running", f"systemctl status {unit}"))
    for unit in ctx.each("user_services"):
        if steps.enabled(unit, True) == "enabled" and \
                subprocess.run(["systemctl", "--user", "is-active", unit], capture_output=True, text=True).stdout.strip() != "active" \
:
            out.append(("err", f"{unit} (--user) is enabled but not running", f"systemctl --user status {unit}"))
    if ctx.has("vpn") and Path("/usr/bin/mihomo").exists() and "cap_net_admin" not in getcap("/usr/bin/mihomo"):
        out.append(("err", "mihomo lacks its capabilities (TUN, port 53)",
                    "sudo setcap cap_net_admin,cap_net_bind_service=ep /usr/bin/mihomo"))
    if ctx.has("hypr"):
        if stale := hypr.out_of_step(profile):
            out.append(("err", f"hypr machine/ out of step with the profile: {', '.join(stale)}", "./install.py link"))
        out += [("err", f".machine.toml {p}", "fix [hypr] in .machine.toml") for p in hypr.problems(profile)]
        if os.environ.get("HYPRLAND_INSTANCE_SIGNATURE") and shutil.which("hyprctl"):
            errors = subprocess.run(["hyprctl", "configerrors"], capture_output=True, text=True).stdout.strip()
            if errors and errors != "no errors":
                out.append(("err", f"Hyprland reports: {errors.splitlines()[0]}", "hyprctl configerrors"))
    if ctx.has("quickshell") and os.environ.get("WAYLAND_DISPLAY") and shutil.which("qs"):
        if "Process ID" not in subprocess.run(["qs", "list", "--all"], capture_output=True, text=True).stdout:
            out.append(("warn", "the shell is not running", "qs -c shell -d"))
    if (BACKUPS.is_dir() and any(BACKUPS.iterdir())):
        n = sum(1 for _ in BACKUPS.iterdir())
        out.append(("warn", f"{n} backup folder(s) of replaced files", f"look in {short(BACKUPS)}; ./install.py rollback puts them back"))
    return out


def cmd_doctor(args) -> int:
    heading("Doctor: this machine")
    ctx = steps.context(args)
    errors = 0
    for step, todo, manual in steps.plan(ctx):
        if isinstance(step, steps.Hints):
            continue
        for line in todo:
            err(f"{step.title}: {line} {dim('· ./install.py setup')}")
            errors += 1
        for line in manual:
            warn(f"{step.title}: {line}")
    for level, what, fix in health(ctx):
        (err if level == "err" else warn)(f"{what} {dim('· ' + fix)}")
        errors += level == "err"
    if not errors:
        ok("healthy")
    return 1 if errors else 0


# --------------------------------------------------------------------------- rollback

def stamps(root: Path = BACKUPS) -> list[Path]:
    """Backup folders, oldest first (their names are times)."""
    return sorted(p for p in root.iterdir() if p.is_dir()) if root.is_dir() else []


def restore(folder: Path, home: Path = HOME, replace_links: bool = True) -> tuple[list[Path], list[Path]]:
    """Move a backup folder's files back under home. A link of ours in the way
    goes (with replace_links); anything else in the way stays, and so does the
    backup copy. Returns (restored, kept in the backup)."""
    done, kept = [], []
    for f in sorted(p for p in folder.rglob("*") if p.is_file() or p.is_symlink()):
        if COPY.search(f.name):
            kept.append(f)
            continue
        target = home / f.relative_to(folder)
        if target.is_symlink() and replace_links and is_managed(target):
            target.unlink()
        if target.exists() or target.is_symlink():
            kept.append(f)
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(f), str(target))
        done.append(target)
    for d in sorted((p for p in folder.rglob("*") if p.is_dir()), key=lambda p: -len(p.parts)):
        if not any(d.iterdir()):
            d.rmdir()
    if folder.is_dir() and not any(folder.iterdir()):
        folder.rmdir()
    return done, kept


def cmd_rollback(args) -> int:
    heading("Rollback: backed-up files back in place")
    folders = stamps()
    wanted = getattr(args, "stamp", None)
    if wanted:
        folders = [f for f in folders if f.name == wanted]
    if not folders:
        ok("no backups" if not wanted else f"no backup {wanted} (have: {', '.join(p.name for p in stamps()) or 'none'})")
        return 0
    files = sum(1 for f in folders for p in f.rglob("*") if p.is_file())
    for f in folders:
        note(f"{f.name}: {sum(1 for p in f.rglob('*') if p.is_file())} file(s)")
    if not confirm(f"Put {files} file(s) back (our links in their place are removed)?", args):
        return 1
    for f in folders:                    # oldest first: the files from before the dotfiles win
        done, kept = restore(f)
        for p in done:
            removed(f"{short(p)} {dim('restored')}")
        for p in kept:
            note(f"kept in the backup: {short(p)}")
    note("`./install.py link` would replace them again (into a new backup)")
    return 0


# --------------------------------------------------------------------------- uninstall

def ours_in_etc() -> list[Path]:
    """/etc files that are exactly what we installed (anything changed there is not ours to remove)."""
    out = []
    for src in system_files(every=True):
        dst = Path("/") / src.relative_to(SYSTEM)
        try:
            if dst.read_bytes() == render(src):
                out.append(dst)
        except (OSError, ValueError):
            pass
    return out


def cmd_uninstall(args) -> int:
    heading("Uninstall")
    links = find_managed()
    generated = [f for f in sorted(hypr.DIR.glob("*.lua")) if hypr.MARK in f.read_text()] if hypr.DIR.is_dir() else []
    etc = ours_in_etc() if getattr(args, "system", False) else []
    note(f"{len(links)} link(s) into {short(ROOT)}")
    note(f"{len(generated)} generated Hyprland file(s), the shell's {short(shell.FILE)}")
    if etc:
        note(f"{len(etc)} file(s) in /etc, unchanged since installed (sudo)")
    if not getattr(args, "system", False):
        note(dim("/etc files stay (--system removes ours)"))
    warn("the running desktop loses its config: log out of Hyprland afterwards")
    note(dim("kept: packages, services, .machine.toml, .theme, the repo, private/"))
    if not confirm("Uninstall?", args):
        return 1
    for p in links:
        p.unlink(missing_ok=True)
    ok(f"{len(links)} link(s) removed")
    for p in hypr.remove_generated():
        removed(short(p))
    if shell.FILE.exists():
        shell.FILE.unlink()
        removed(short(shell.FILE))
    if etc:
        subprocess.run(["sudo", "rm", "-f", *map(str, etc)], check=True)
        for p in etc:
            removed(str(p))
    if stamps() and confirm("Put the files from before the dotfiles back (from the backups)?", args):
        args.stamp = None
        cmd_rollback(args)
    return 0


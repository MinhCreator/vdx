"""dotfiles installer — root-owned files under system/, copied into / with sudo.

Only the selected components' files; @KEY@ in a file is this machine's
hardware value (@BATTERY@ -> BAT0). A file that differs in / is shown as a
diff before it is replaced; files of components that are off are reported,
never removed.
"""

from __future__ import annotations

import difflib
import re
import shlex
import subprocess

from . import components
from .model import render, system_leftovers, system_state
from .ui import added, confirm, dim, err, heading, note, ok, warn

# after installing a system file under these dirs, run the command ({} = file)
SYSTEM_APPLY = {
    "/etc/tmpfiles.d": ["systemd-tmpfiles", "--create", "{}"],
    "/etc/tlp.d": ["tlp", "start"],
}
# what can't be applied at once
SYSTEM_LATER = {
    "/etc/modprobe.d": "applies when the module loads next: after a reboot",
}


def show_diff(src, dst) -> None:
    """The change a copy makes, as a unified diff (nothing when / is unreadable)."""
    try:
        old = dst.read_text().splitlines()
        new = render(src).decode().splitlines()
    except (OSError, UnicodeDecodeError, ValueError):
        return
    for line in difflib.unified_diff(old, new, str(dst), "dotfiles", lineterm="", n=1):
        print(f"      {dim(line) if line.startswith(('---', '+++', '@@')) else line}")


def run_hook(dst) -> None:
    """A pacman hook fires on its package's next upgrade; when the package is
    already installed, do its action now (mihomo's capabilities)."""
    text = dst.read_text() if dst.exists() else ""
    targets = re.findall(r"^\s*Target\s*=\s*(\S+)", text, re.M)
    action = re.search(r"^\s*Exec\s*=\s*(.+)$", text, re.M)
    if action and targets and subprocess.run(["pacman", "-Q", *targets], capture_output=True).returncode == 0:
        subprocess.run(["sudo", *shlex.split(action.group(1))], check=False)


def print_hints() -> None:
    cat = components.load()
    hints = [(n, cat[n]["hint"]) for n in cat if n in components.selected(cat=cat) and cat[n].get("hint")]
    if not hints:
        return
    heading("By hand")
    for name, hint in hints:
        warn(name)
        for line in hint.splitlines():
            note(line)


def cmd_system(args) -> int:
    """Root-owned files are copied, not linked: /etc must not point into $HOME."""
    state = system_state()
    leftovers = system_leftovers()
    if args.s_action == "status":
        heading("System files")
        for _, dst, s in state:
            mark = ok if s == "ok" else note if s == "unreadable" else err
            mark(f"{dst} {dim('(' + s + ')')}")
        for dst in leftovers:
            warn(f"{dst} {dim('(its component is off — remove: sudo rm ' + str(dst) + ')')}")
        return 0 if all(s in ("ok", "unreadable") for *_, s in state) else 1
    heading("Installing system files")
    for src, dst, s in state:
        if s == "unrenderable":
            try:
                render(src)
            except ValueError as e:
                err(f"{dst}: {e} — set it in [override] of .machine.toml")
    changed = [(src, dst, s) for src, dst, s in state if s in ("differs", "missing", "unreadable")]
    if not changed:
        ok("system files are up to date")
        print_hints()
        return 0
    for src, dst, s in changed:
        note(f"{dst} {dim('(' + s + ')')}")
        if s == "differs":
            show_diff(src, dst)
    if not confirm(f"Copy {len(changed)} file(s) into / with sudo?", args):
        return 1
    for src, dst, _ in changed:
        subprocess.run(["sudo", "install", "-Dm644", "/dev/stdin", str(dst)], input=render(src), check=True)
        added(str(dst))
        for prefix, cmd in SYSTEM_APPLY.items():
            if str(dst).startswith(prefix + "/"):
                subprocess.run(["sudo", *(a.replace("{}", str(dst)) for a in cmd)], check=False)
        if str(dst).startswith("/etc/pacman.d/hooks/"):
            run_hook(dst)
        for prefix, later in SYSTEM_LATER.items():
            if str(dst).startswith(prefix + "/"):
                note(later)
    print_hints()
    return 0


def cmd_system_install(args) -> int:
    args.s_action = "install"
    return cmd_system(args)

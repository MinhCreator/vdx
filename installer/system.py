"""dotfiles installer — root-owned files under system/, copied into / with sudo."""

from __future__ import annotations

import subprocess

from .model import system_state
from .ui import added, confirm, dim, err, heading, note, ok

# after installing a system file under these dirs, run the command ({} = file)
SYSTEM_APPLY = {
    "/etc/tmpfiles.d": ["systemd-tmpfiles", "--create", "{}"],
    "/etc/tlp.d": ["tlp", "start"],
}


def cmd_system(args) -> int:
    """Root-owned files are copied, not linked: /etc must not point into $HOME."""
    state = system_state()
    if args.s_action == "status":
        heading("System files")
        for _, dst, s in state:
            mark = ok if s == "ok" else note if s == "unreadable" else err
            mark(f"{dst} {dim('(' + s + ')')}")
        return 0 if all(s in ("ok", "unreadable") for *_, s in state) else 1
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


def cmd_system_install(args) -> int:
    args.s_action = "install"
    return cmd_system(args)

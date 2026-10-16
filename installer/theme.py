"""dotfiles installer — theme commands: list, current, set (re-links and reloads running programs)."""

from __future__ import annotations

import shutil
import subprocess

from .links import cmd_link
from .model import active_theme, themes
from .paths import TGT, THEME_FILE
from .ui import err, heading, note, ok

# Running programs that read their colours only at start; each command runs
# only when the program is there, failures are ignored (best effort).
THEME_RELOADS = [
    ("hyprctl", ["hyprctl", "reload"]),
    ("makoctl", ["makoctl", "reload"]),
    ("kitty", ["pkill", "-USR1", "-x", "kitty"]),
    ("tmux", ["tmux", "source-file", str(TGT / "tmux" / "tmux.conf")]),
]


def reload_running() -> None:
    for prog, command in THEME_RELOADS:
        if shutil.which(prog):
            subprocess.run(command, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


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
        code = cmd_link(args)
        reload_running()
        return code
    return 0

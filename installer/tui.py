import sys
import termios

from installer.ansi import C, pause
from installer.commands import (
    cmd_link,
    cmd_update,
    cmd_force,
    cmd_cleanup,
    cmd_unlink,
    cmd_status,
    cmd_verify,
)


ITEMS = [
    ("Link all", "Create all symlinks", cmd_link),
    ("Update", "Add only new files", cmd_update),
    ("Force relink", "Recreate all symlinks", cmd_force),
    ("Cleanup", "Remove stale & broken", cmd_cleanup),
    ("Unlink", "Remove all symlinks", cmd_unlink),
    ("Status", "Show package status", cmd_status),
    ("Verify", "Check for broken symlinks", cmd_verify),
]


def _read_key() -> str:
    try:
        import tty

        fd = sys.stdin.fileno()
        old = termios.tcgetattr(fd)
        try:
            tty.setraw(fd)
            ch = sys.stdin.read(1)
            if ch == "\x1b":
                seq = sys.stdin.read(2)
                if seq == "[A":
                    return "k"
                if seq == "[B":
                    return "j"
                return "\x1b"
            return ch
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old)
    except (ImportError, OSError):
        return input()


def tui_menu(items, title="Dotfiles Manager"):
    idx = 0
    print(C.HID, end="")
    try:
        while True:
            print(C.CLR, end="")
            print()
            print(f"  {C.B}{C.CN}{title}{C.X}")
            print(f"  {C.D}{'═' * 60}{C.X}")
            print()
            for i, (label, desc, _) in enumerate(items):
                if i == idx:
                    line = f"  {C.B}{C.G}\u25b8{C.X} {C.B}{label}{C.X}  {C.D}\u2014 {desc}{C.X}"
                else:
                    line = f"    {C.D}{label}{C.X}"
                print(line)
            print()
            print(
                f"  {C.D}\u2191/\u2193/j/k \u2014 navigate  Enter \u2014 select  q/Esc \u2014 quit{C.X}"
            )

            ch = _read_key()

            if ch in ("\x1b", "q", "Q"):
                return -1
            if ch in ("\r", "\n"):
                return idx
            if ch in ("j", "J"):
                idx = (idx + 1) % len(items)
            if ch in ("k", "K"):
                idx = (idx - 1) % len(items)
    finally:
        print(C.SHW, end="")


def tui_main():
    while True:
        choice = tui_menu(ITEMS)
        if choice == -1:
            print(C.CLR, end="")
            break
        try:
            ITEMS[choice][2](None)
        except SystemExit:
            pass
        pause()

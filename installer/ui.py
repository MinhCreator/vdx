"""dotfiles installer — terminal output and questions."""

from __future__ import annotations

import os
import sys
from pathlib import Path

from .paths import HOME

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

"""dotfiles installer — what the shell needs to know about the components.

`link` writes $XDG_STATE_HOME/dotfiles/components.json: the bar modules whose
components are off, each with the components that would bring it

  {"off": {"music": ["yandex-music"], "ai": ["ollama", "claude-code"]}}

The shell (bar/BarLayout.qml) keeps them off the bars and shows them as not
installed in the Shell Manager; a missing file means every module is there.
"""

from __future__ import annotations

import json
import os
from pathlib import Path

from . import components
from .paths import HOME

STATE = Path(os.environ.get("XDG_STATE_HOME") or HOME / ".local" / "state") / "dotfiles" / "components.json"


def render(on: set[str], cat: dict) -> str:
    bring: dict[str, list[str]] = {}
    for name, c in cat.items():
        for m in c["modules"]:
            bring.setdefault(m, []).append(name)
    off = {m: names for m, names in bring.items() if not any(n in on for n in names)}
    return json.dumps({"off": off}, indent=2, ensure_ascii=False) + "\n"


def apply(target: Path = STATE) -> bool:
    """Write the file when it changed; True then."""
    cat = components.load()
    text = render(components.selected(cat=cat), cat)
    if target.is_file() and target.read_text() == text:
        return False
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text)
    return True

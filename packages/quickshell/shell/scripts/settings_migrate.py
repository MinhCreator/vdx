#!/usr/bin/env python3
"""The shell's option files brought up to the current schema before it starts
(supervise.sh). One JSON object on stdout.

    settings_migrate.py [<state dir>]     {"ok", "changed": [file, ...]}

The state dir is Quickshell's for this shell (by-shell/<md5 of shell.qml's
path>) unless given. Each of settings.json, modules.json and layout.json
carries "version"; a file below VERSION goes through MIGRATIONS[n] for every
n from its version up, then gets the new version. A file is written only when
it changed: atomically, the old one kept as <file>.bak. A file that is missing,
not JSON or not an object is left alone (the shell writes its defaults).
QML keeps reading the old shapes too (a live reload runs without this)."""
import hashlib, json, os, sys
from pathlib import Path

VERSION = 1
FILES = ("settings.json", "modules.json", "layout.json")
RENAMED = {"claude": "ai", "plugins": "shell"}       # module ids that changed (BarLayout.renamed)


def state_dir() -> Path:
    config = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
    state = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state")
    shell = str(config / "quickshell/shell/shell.qml")
    return state / "quickshell/by-shell" / hashlib.md5(shell.encode()).hexdigest()


def _ids(ids):
    """A list of module ids with the renamed ones replaced, order kept, no repeats."""
    out = []
    for i in ids if isinstance(ids, list) else []:
        i = RENAMED.get(i, i)
        if i not in out:
            out.append(i)
    return out


def _layout_entry(e: dict) -> None:
    """One saved layout (the top level or a role): ids renamed everywhere."""
    if isinstance(e.get("zones"), dict):
        e["zones"] = {z: _ids(v) for z, v in e["zones"].items()}
    for key in ("hidden", "folder"):
        if isinstance(e.get(key), list):
            e[key] = _ids(e[key])
    if isinstance(e.get("island"), dict):
        e["island"] = {z: _ids(v) for z, v in e["island"].items()}
    if isinstance(e.get("bars"), list):
        for b in e["bars"]:
            if isinstance(b, dict) and isinstance(b.get("modules"), list):
                b["modules"] = _ids(b["modules"])


def to_1(name: str, data: dict) -> None:
    """Version 1: the fixes the pages and BarLayout did inline until now."""
    if name == "modules.json":
        values = data.get("values")
        if isinstance(values, dict):
            # a title length of 0 once meant "icon only" (MusicSettings / RadioSettings)
            for mod in ("music", "radio"):
                m = values.get(mod)
                if isinstance(m, dict) and m.get("titleLength") == 0:
                    m["show"], m["titleLength"] = "icon", 60
    elif name == "layout.json":
        _layout_entry(data)
        screens = data.get("screens")
        if isinstance(screens, dict):
            # per-monitor-name entries predate the main / extra roles
            data["screens"] = {r: screens[r] for r in ("main", "extra") if isinstance(screens.get(r), dict)}
            for e in data["screens"].values():
                _layout_entry(e)


MIGRATIONS = {0: to_1}          # n -> the step from version n to n + 1


def migrate(name: str, data: dict) -> dict:
    v = data.get("version", 0)
    if not isinstance(v, int) or v < 0:
        v = 0
    while v < VERSION:
        MIGRATIONS[v](name, data)
        v += 1
    data["version"] = v          # a newer file than this script keeps its own
    return data


def migrate_file(path: Path) -> bool:
    try:
        text = path.read_text()
        data = json.loads(text)
    except (OSError, ValueError):
        return False
    if not isinstance(data, dict):
        return False
    before = json.dumps(data, sort_keys=True)
    migrate(path.name, data)
    if json.dumps(data, sort_keys=True) == before:
        return False
    path.with_name(path.name + ".bak").write_text(text)
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(json.dumps(data, indent=4) + "\n")
    tmp.replace(path)
    return True


def main(argv: list[str]) -> int:
    folder = Path(argv[1]) if len(argv) > 1 else state_dir()
    changed = [n for n in FILES if migrate_file(folder / n)]
    print(json.dumps({"ok": True, "changed": changed}))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

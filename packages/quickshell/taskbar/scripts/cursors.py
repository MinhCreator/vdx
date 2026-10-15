#!/usr/bin/env python3
"""Cursor theme for the Shell Manager. One JSON object per command.

    cursors.py list                 {"ok", "current", "size", "cursors": [{id, name, installed}]}
    cursors.py install <id>         into ~/.local/share/icons              {"ok", "name"}
    cursors.py set <name> <size>    applies now and on the next login      {"ok"}
    cursors.py restore              re-applies the saved choice (Hyprland start)

The choice is the XDG default cursor (~/.local/share/icons/default/index.theme,
which GTK's `default` and Xcursor follow), Hyprland's `setcursor` and the
GNOME interface keys (GTK 4); the size is kept in
~/.local/state/dotfiles/cursor. Errors: {"ok": false, "error": "..."}."""
import json, shutil, subprocess, sys, tarfile, tempfile, urllib.request
from pathlib import Path

ICONS = Path.home() / ".local/share/icons"
STATE = Path.home() / ".local/state/dotfiles/cursor"
SEARCH = [ICONS, Path.home() / ".icons", Path("/usr/share/icons")]
BIBATA = "https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/{}.tar.xz"
PHINGER = "https://github.com/phisch/phinger-cursors/releases/latest/download/phinger-cursors-variants.tar.bz2"

# theme name -> where it comes from
CURATED = {
    "Bibata-Modern-Classic": BIBATA.format("Bibata-Modern-Classic"),
    "Bibata-Modern-Ice": BIBATA.format("Bibata-Modern-Ice"),
    "Bibata-Modern-Amber": BIBATA.format("Bibata-Modern-Amber"),
    "Bibata-Original-Classic": BIBATA.format("Bibata-Original-Classic"),
    "phinger-cursors-dark": PHINGER,
    "phinger-cursors-light": PHINGER,
}
DEFAULT = ("Adwaita", 24)


def out(obj):
    print(json.dumps(obj))
    sys.exit(0 if obj.get("ok") else 1)


def installed():
    """Themes with a cursors/ dir anywhere on the search path."""
    names = set()
    for base in SEARCH:
        if base.is_dir():
            names |= {d.name for d in base.iterdir() if (d / "cursors").is_dir() and d.name != "default"}
    return names


def saved():
    try:
        name, size = STATE.read_text().split()
        return name, int(size)
    except (OSError, ValueError):
        return DEFAULT


def cmd_list():
    have = installed()
    name, size = saved()
    cursors = [{"id": n, "name": n, "installed": n in have} for n in CURATED]
    cursors += [{"id": n, "name": n, "installed": True} for n in sorted(have - set(CURATED), key=str.lower)]
    out({"ok": True, "current": name, "size": size, "cursors": cursors})


def cmd_install(name):
    url = CURATED.get(name)
    if not url:
        out({"ok": False, "error": f"unknown cursor: {name}"})
    ICONS.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        archive = Path(tmp) / "cursor.tar"
        try:
            urllib.request.urlretrieve(url, archive)
            with tarfile.open(archive) as tar:
                tar.extractall(Path(tmp) / "x", filter="data")
        except Exception as e:
            out({"ok": False, "error": f"download failed: {e}"})
        # every listed theme in the archive (phinger ships dark and light at once)
        for index in (Path(tmp) / "x").rglob("index.theme"):
            theme = index.parent
            if theme.name in CURATED and (theme / "cursors").is_dir():
                dst = ICONS / theme.name
                if dst.exists():
                    shutil.rmtree(dst)
                shutil.move(str(theme), dst)
    if name not in installed():
        out({"ok": False, "error": f"{name} not found in the download"})
    out({"ok": True, "name": name})


def apply(name, size):
    subprocess.run(["hyprctl", "setcursor", name, str(size)], capture_output=True)
    for key, value in (("cursor-theme", name), ("cursor-size", str(size))):
        subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", key, value], capture_output=True)


def cmd_set(name, size):
    if name not in installed():
        out({"ok": False, "error": f"not installed: {name}"})
    if not size.isdigit() or not 12 <= int(size) <= 96:
        out({"ok": False, "error": f"bad size: {size}"})
    default = ICONS / "default"
    default.mkdir(parents=True, exist_ok=True)
    (default / "index.theme").write_text(f"[Icon Theme]\n# written by the Shell Manager (cursors.py set)\nInherits={name}\n")
    STATE.parent.mkdir(parents=True, exist_ok=True)
    STATE.write_text(f"{name} {size}\n")
    apply(name, int(size))
    out({"ok": True})


if __name__ == "__main__":
    args = sys.argv[1:]
    if args == ["list"]:
        cmd_list()
    elif args == ["restore"]:
        if STATE.exists():
            apply(*saved())
        out({"ok": True})
    elif len(args) == 2 and args[0] == "install":
        cmd_install(args[1])
    elif len(args) == 3 and args[0] == "set":
        cmd_set(args[1], args[2])
    out({"ok": False, "error": "usage: cursors.py list | install <name> | set <name> <size> | restore"})

#!/usr/bin/env python3
"""Display settings for the Shell Manager: monitor scale, position and the system
text size. One JSON object per command.

    display.py list                       {"ok", "monitors": [{name, model, width, height, refresh,
                                           x, y, scale, scales}], "text": factor, "textScales": [...]}
    display.py scale <output> <scale>     applies now (Hyprland; mode and position kept)   {"ok"}
    display.py position <output> <x> <y>  moves a monitor in logical pixels; refused when it
                                           would overlap another one                        {"ok"}
    display.py text <factor>              GTK's text-scaling-factor (gsettings), kept by dconf {"ok"}
    display.py restore                    re-applies the saved scales and positions (Hyprland start)

Scales and positions are kept in ~/.local/state/dotfiles/display.json. The boot
values of a monitor stay the ones in .machine.toml [hypr]; this overrides them.
Text size reaches GTK apps only (Qt and the shell keep theirs).
Errors: {"ok": false, "error": "..."}."""
import json, subprocess, sys
from pathlib import Path

STATE = Path.home() / ".local/state/dotfiles/display.json"
SCALES = [1.0, 1.25, 1.5, 1.75, 2.0]        # the choices offered; the current one is added
TEXT = [0.9, 1.0, 1.15, 1.3, 1.5]           # text-scaling-factor choices
SCHEMA = "org.gnome.desktop.interface"
KEY = "text-scaling-factor"


def out(obj):
    print(json.dumps(obj))
    sys.exit(0 if obj.get("ok") else 1)


def fail(msg):
    out({"ok": False, "error": msg})


def run(cmd):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=10)
    except (OSError, subprocess.TimeoutExpired) as e:
        fail(f"{cmd[0]}: {e}")


def monitors():
    r = run(["hyprctl", "monitors", "-j"])
    if r.returncode != 0:
        fail("hyprctl monitors failed")
    try:
        return [m for m in json.loads(r.stdout) if not m.get("disabled")]
    except json.JSONDecodeError:
        fail("bad reply from hyprctl")


def text_factor():
    r = run(["gsettings", "get", SCHEMA, KEY])
    try:
        return float(r.stdout.strip())
    except ValueError:
        return 1.0


def saved():
    try:
        s = json.loads(STATE.read_text())
    except (OSError, json.JSONDecodeError):
        s = {}
    return {"scales": s.get("scales", {}), "positions": s.get("positions", {})}


def save(state):
    STATE.parent.mkdir(parents=True, exist_ok=True)
    STATE.write_text(json.dumps(state, indent=2) + "\n")


def lua_num(x):
    return f"{x:g}" if float(x) != int(x) else f"{int(x)}.0"


def logical(m, x=None, y=None):
    """The rectangle a monitor takes in the layout: (x, y, w, h) in logical pixels."""
    w = round(m["width"] / m["scale"])
    h = round(m["height"] / m["scale"])
    return (m["x"] if x is None else x, m["y"] if y is None else y, w, h)


def apply(m, scale=None, pos=None):
    # hl.monitor takes the same keys as monitors.lua; the unchanged ones stay as they are
    scale = m["scale"] if scale is None else scale
    x, y = (m["x"], m["y"]) if pos is None else pos
    mode = f"{m['width']}x{m['height']}@{m['refreshRate']:.2f}"
    lua = (f'hl.monitor({{ output = "{m["name"]}", mode = "{mode}", '
           f'position = "{x}x{y}", scale = {lua_num(scale)} }})')
    r = run(["hyprctl", "eval", lua])
    if r.returncode != 0 or "error" in (r.stdout + r.stderr).lower():
        fail(f"hyprctl eval: {(r.stdout + r.stderr).strip() or 'failed'}")


def scale_choices(current):
    return sorted(set(SCALES) | {round(current, 2)})


def cmd_list():
    rows = [{"name": m["name"], "model": m.get("description", m["name"]), "width": m["width"],
             "height": m["height"], "refresh": round(m["refreshRate"], 2), "x": m["x"], "y": m["y"],
             "scale": m["scale"], "scales": scale_choices(m["scale"])} for m in monitors()]
    out({"ok": True, "monitors": rows, "text": text_factor(), "textScales": TEXT})


def find(name):
    found = [m for m in monitors() if m["name"] == name]
    if not found:
        fail(f"no monitor {name!r}")
    return found[0]


def cmd_scale(name, value):
    try:
        scale = float(value)
    except ValueError:
        fail(f"scale is a number: {value!r}")
    if not 0.5 <= scale <= 3:
        fail(f"scale out of range: {scale:g}")
    m = find(name)
    apply(m, scale=scale)
    state = saved()
    state["scales"][name] = scale
    save(state)
    out({"ok": True})


def cmd_position(name, sx, sy):
    try:
        x, y = int(sx), int(sy)
    except ValueError:
        fail(f"position is whole pixels: {sx!r} {sy!r}")
    m = find(name)
    ax, ay, aw, ah = logical(m, x, y)
    for o in monitors():
        if o["name"] == name:
            continue
        bx, by, bw, bh = logical(o)
        if ax < bx + bw and bx < ax + aw and ay < by + bh and by < ay + ah:
            fail(f"overlaps {o['name']}")
    apply(m, pos=(x, y))
    state = saved()
    state["positions"][name] = [x, y]
    save(state)
    out({"ok": True})


def cmd_text(value):
    try:
        factor = float(value)
    except ValueError:
        fail(f"text size is a number: {value!r}")
    if not 0.5 <= factor <= 3:
        fail(f"text size out of range: {factor:g}")
    r = run(["gsettings", "set", SCHEMA, KEY, lua_num(factor)])
    if r.returncode != 0:
        fail(r.stderr.strip() or "gsettings failed")
    out({"ok": True})


def cmd_restore():
    state = saved()
    current = {m["name"]: m for m in monitors()}
    for name in set(state["scales"]) | set(state["positions"]):
        if name not in current:
            continue
        m = current[name]
        scale = float(state["scales"][name]) if name in state["scales"] else None
        pos = tuple(state["positions"][name]) if name in state["positions"] else None
        apply(m, scale=scale, pos=pos)
    out({"ok": True})


if __name__ == "__main__":
    args = sys.argv[1:]
    if args == ["list"]:
        cmd_list()
    elif len(args) == 3 and args[0] == "scale":
        cmd_scale(args[1], args[2])
    elif len(args) == 4 and args[0] == "position":
        cmd_position(args[1], args[2], args[3])
    elif len(args) == 2 and args[0] == "text":
        cmd_text(args[1])
    elif args == ["restore"]:
        cmd_restore()
    else:
        fail("usage: display.py list | scale <output> <scale> | position <output> <x> <y> | text <factor> | restore")

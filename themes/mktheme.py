#!/usr/bin/env python3
"""Derive dotfiles themes from themes/gruvbox: every gruvbox colour is
replaced by the colour of the same role in the new palette.

    python3 themes/mktheme.py            # rebuild every theme in THEMES
    python3 themes/mktheme.py ember      # just one

A new theme: add its palette to THEMES (all roles + frame, frame_active) and
run it; the result lands in themes/<name> and shows up in the Shell Manager."""
import re, shutil, sys
from pathlib import Path

ROOT = Path.home() / ".dotfiles"
SRC = ROOT / "themes/gruvbox"

ROLES = ["background0", "background1", "background2", "background3", "foreground0", "foreground1",
         "foreground2", "gray", "muted", "dim", "red", "orange", "yellow", "green", "aqua", "blue",
         "purple", "bright"]
GRUVBOX = dict(background0="202020", background1="32302f", background2="3c3836", background3="45403d",
               foreground0="d4be98", foreground1="ddc7a1", foreground2="bdae93", gray="7c6f64",
               muted="928374", dim="665c54", red="ea6962", orange="e78a4e", yellow="d8a657",
               green="a9b665", aqua="89b482", blue="7daea3", purple="d3869b", bright="a89984")
EXTRA = {"282828": "background0", "ebdbb2": "foreground0", "ffffff": "foreground1"}

THEMES = {
    "graphite": dict(
        title="Graphite — near-black monochrome, light gray frames",
        background0="0e0e0e", background1="171717", background2="1f1f1f", background3="2c2c2c",
        foreground0="e4e4e4", foreground1="f2f2f2", foreground2="b8b8b8", gray="6e6e6e",
        muted="8a8a8a", dim="4f4f4f", red="f07178", orange="f4a261", yellow="e9d16c",
        green="7fd1a8", aqua="5fc4d4", blue="6aa7f0", purple="b39ddb", bright="a8a8a8",
        frame="a0a0a0", frame_active="d0d0d0"),
    "ember": dict(
        title="Ember — warm charcoal brown, coral frames and accents",
        background0="231b19", background1="2c2220", background2="352925", background3="42322c",
        foreground0="eadbd0", foreground1="f4e8de", foreground2="bfae9f", gray="6e5a51",
        muted="94827a", dim="574640", red="ff5c57", orange="ff8a5c", yellow="f9c56a",
        green="8fd45f", aqua="5fd3b8", blue="5ea8ff", purple="e48ad8", bright="b09e92",
        frame="e07a5f", frame_active="f07f5c"),
}

def recolor(text, pal):
    table = {GRUVBOX[r]: pal[r] for r in ROLES}
    table.update({k: pal[v] for k, v in EXTRA.items()})
    return re.sub(r"(?i)([0-9a-f]{6})", lambda m: table.get(m.group(1).lower(), m.group(1)), text)

def build(name, pal):
    dst = ROOT / "themes" / name
    if dst.exists(): shutil.rmtree(dst)
    files = [p for p in SRC.rglob("*") if p.is_file() and p.name != "README.md"]
    extra = {ROOT / "packages/tmux/colors.conf": dst / "tmux/colors.conf",
             ROOT / "packages/btop/themes/current.theme": dst / "btop/themes/current.theme"}
    for src in files: extra[src] = dst / src.relative_to(SRC)
    for src, out in extra.items():
        out.parent.mkdir(parents=True, exist_ok=True)
        text = src.read_text()
        out.write_text(recolor(text, pal))
    f = lambda rel: dst / rel
    # frames have their own colour per theme
    q = f("quickshell/taskbar/config/Colors.qml")
    q.write_text(re.sub(r'(readonly property color frame:\s*")#[0-9a-fA-F]{6}"', rf'\g<1>#{pal["frame"]}"', q.read_text())
                 .replace("gruvbox palette overlay", f"{name} palette overlay"))
    h = f("hypr/components/colors.lua")
    h.write_text(re.sub(r'frame_active = "rgb\([0-9a-fA-F]{6}\)"', f'frame_active = "rgb({pal["frame_active"]})"', h.read_text())
                 .replace("-- gruvbox-material,", f"-- {name},"))
    m = f("mako/config")
    m.write_text(re.sub(r"\[urgency=normal\]\nborder-color=#[0-9a-fA-F]{6}", f"[urgency=normal]\nborder-color=#{pal['frame']}",
                        re.sub(r"^border-color=#[0-9a-fA-F]{6}", f"border-color=#{pal['frame']}", m.read_text(), count=1, flags=re.M)))
    r = f("rofi/colors.rasi")
    r.write_text(re.sub(r"border:\s*#[0-9a-fA-F]{6};", f"border:   #{pal['frame']};", r.read_text()))
    rows = "\n".join(f"| {k} | `#{pal[k]}` |" for k in ROLES[:-1] + ["frame", "frame_active"])
    (dst / "README.md").write_text(f"# {pal['title']}\n\nGenerated from `themes/gruvbox` role by role "
        f"(same files, same roles — see `themes/gruvbox/README.md` for the rules).\n\n| Role | Hex |\n|---|---|\n{rows}\n")
    print(name, "->", len(extra), "files")

for n in (sys.argv[1:] or THEMES):
    build(n, THEMES[n])

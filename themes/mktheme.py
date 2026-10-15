#!/usr/bin/env python3
"""Derive dotfiles themes from themes/gruvbox: every gruvbox colour is
replaced by the colour of the same role in the new theme.

    python3 themes/mktheme.py            # rebuild every theme in THEMES
    python3 themes/mktheme.py ember      # just one

A new theme: add its colours to THEMES (all roles + frame, frame_active) and
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
    "khaki": dict(
        title="Khaki — near-black, warm cream text, sand frames",
        background0="141414", background1="1b1b1b", background2="232323", background3="322f26",
        foreground0="e5d7b2", foreground1="f0e4c4", foreground2="b8ac8e", gray="5a5a5a",
        muted="8a8270", dim="464239", red="d47766", orange="d9955b", yellow="dcc07a",
        green="a3b37a", aqua="8fb3a0", blue="7f9aa8", purple="b391a8", bright="a8a08a",
        frame="9a947a", frame_active="c8bb98"),
    "catppuccin": dict(
        title="Catppuccin Mocha — soft pastel on deep indigo",
        background0="1e1e2e", background1="2a2b3d", background2="313244", background3="45475a",
        foreground0="cdd6f4", foreground1="dfe5fb", foreground2="bac2de", gray="6c7086",
        muted="7f849c", dim="585b70", red="f38ba8", orange="fab387", yellow="f9e2af",
        green="a6e3a1", aqua="94e2d5", blue="89b4fa", purple="cba6f7", bright="a6adc8",
        frame="cba6f7", frame_active="b4befe"),
    "tokyonight": dict(
        title="Tokyo Night — city lights on navy",
        background0="1a1b26", background1="1f2335", background2="24283b", background3="2f344e",
        foreground0="c0caf5", foreground1="d5dcfa", foreground2="a9b1d6", gray="565f89",
        muted="737aa2", dim="3b4261", red="f7768e", orange="ff9e64", yellow="e0af68",
        green="9ece6a", aqua="73daca", blue="7aa2f7", purple="bb9af7", bright="9aa5ce",
        frame="7aa2f7", frame_active="7dcfff"),
    "nord": dict(
        title="Nord — arctic slate and frost blue",
        background0="2e3440", background1="3b4252", background2="434c5e", background3="4c566a",
        foreground0="d8dee9", foreground1="eceff4", foreground2="b9c0cd", gray="616e88",
        muted="7b88a1", dim="56607a", red="bf616a", orange="d08770", yellow="ebcb8b",
        green="a3be8c", aqua="8fbcbb", blue="81a1c1", purple="b48ead", bright="9aa3b5",
        frame="88c0d0", frame_active="8fbcbb"),
    "rosepine": dict(
        title="Rosé Pine — muted rose and iris on plum",
        background0="191724", background1="1f1d2e", background2="26233a", background3="403d52",
        foreground0="e0def4", foreground1="f0eefc", foreground2="c1bed9", gray="6e6a86",
        muted="908caa", dim="524f67", red="eb6f92", orange="ea9a97", yellow="f6c177",
        green="a3c9a0", aqua="9ccfd8", blue="7aa6c2", purple="c4a7e7", bright="a8a4c0",
        frame="c4a7e7", frame_active="ebbcba"),
    "everforest": dict(
        title="Everforest — warm forest greens",
        background0="2d353b", background1="343f44", background2="3d484d", background3="475258",
        foreground0="d3c6aa", foreground1="e2d7bc", foreground2="bdb59c", gray="7a8478",
        muted="859289", dim="56635f", red="e67e80", orange="e69875", yellow="dbbc7f",
        green="a7c080", aqua="83c092", blue="7fbbb3", purple="d699b6", bright="9da9a0",
        frame="a7c080", frame_active="dbbc7f"),
    "kanagawa": dict(
        title="Kanagawa — ink, old paper and wave blue",
        background0="1f1f28", background1="2a2a37", background2="363646", background3="54546d",
        foreground0="dcd7ba", foreground1="eae6cb", foreground2="c8c093", gray="727169",
        muted="938aa9", dim="4a4a5e", red="e46876", orange="ffa066", yellow="e6c384",
        green="98bb6c", aqua="7aa89f", blue="7e9cd8", purple="957fb8", bright="a6a69c",
        frame="7e9cd8", frame_active="e6c384"),
    "dracula": dict(
        title="Dracula — vivid neon on dusk purple-gray",
        background0="282a36", background1="2f3241", background2="383a4a", background3="44475a",
        foreground0="f8f8f2", foreground1="fafaf5", foreground2="c9c9c4", gray="6272a4",
        muted="7a86b0", dim="4d5168", red="ff5555", orange="ffb86c", yellow="f1fa8c",
        green="50fa7b", aqua="8be9fd", blue="8094ff", purple="bd93f9", bright="b0b6c9",
        frame="bd93f9", frame_active="ff79c6"),
    "onedark": dict(
        title="One Dark — Atom's calm blue-gray",
        background0="282c34", background1="2c313a", background2="353b45", background3="3e4451",
        foreground0="abb2bf", foreground1="c8ccd4", foreground2="9da5b4", gray="5c6370",
        muted="7f848e", dim="4b5263", red="e06c75", orange="d19a66", yellow="e5c07b",
        green="98c379", aqua="56b6c2", blue="61afef", purple="c678dd", bright="8b929e",
        frame="61afef", frame_active="c678dd"),
    "mono": dict(
        title="Mono — black and grays, accents barely tinted",
        background0="0a0a0a", background1="121212", background2="191919", background3="262626",
        foreground0="d6d6d6", foreground1="f2f2f2", foreground2="a3a3a3", gray="4d4d4d",
        muted="767676", dim="383838", red="c98b8b", orange="c9a78b", yellow="c9c18b",
        green="9bb59b", aqua="8bb3ae", blue="8ba3c4", purple="ab97c2", bright="8c8c8c",
        frame="8c8c8c", frame_active="d6d6d6"),
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
    q = f("quickshell/shell/config/Colors.qml")
    q.write_text(re.sub(r'(readonly property color frame:\s*")#[0-9a-fA-F]{6}"', rf'\g<1>#{pal["frame"]}"', q.read_text())
                 .replace("gruvbox theme overlay", f"{name} theme overlay"))
    h = f("hypr/components/colors.lua")
    h.write_text(re.sub(r'frame_active = "rgb\([0-9a-fA-F]{6}\)"', f'frame_active = "rgb({pal["frame_active"]})"', h.read_text())
                 .replace("-- gruvbox-material,", f"-- {name},"))
    m = f("mako/config")
    m.write_text(re.sub(r"\[urgency=normal\]\nborder-color=#[0-9a-fA-F]{6}", f"[urgency=normal]\nborder-color=#{pal['frame']}",
                        re.sub(r"^border-color=#[0-9a-fA-F]{6}", f"border-color=#{pal['frame']}", m.read_text(), count=1, flags=re.M)))
    # its wallpaper folder (wallpapers/<name>, kept outside the generated tree)
    wp = ROOT / "wallpapers" / name
    wp.mkdir(parents=True, exist_ok=True)
    (wp / ".gitkeep").touch()
    print(name, "->", len(extra), "files")

for n in (sys.argv[1:] or THEMES):
    build(n, THEMES[n])

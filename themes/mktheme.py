#!/usr/bin/env python3
"""Derive dotfiles themes from themes/gruvbox: every gruvbox colour is
replaced by the colour of the same role in the new theme.

    python3 themes/mktheme.py              # rebuild every theme in THEMES
    python3 themes/mktheme.py ember        # just one
    python3 themes/mktheme.py --check      # report generated files that are out of date

A new theme: add its colours to THEMES (all roles + frame, frame_active) and
run it; the result lands in themes/<name> and shows up in the Shell Manager."""
import re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "themes/gruvbox"
# package files that carry gruvbox's colours themselves: every other theme recolours them
FROM_PACKAGES = ["tmux/colors.conf", "btop/themes/current.theme"]

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


# light twins: "<theme>-light", switched to by Appearance › Mode (and the bar's
# Mode module). The roles keep their jobs: background0 the window, 1–3 a step
# deeper each, foreground0 the text; accents darkened to read on light.
def _l(title, bg, fg, gray, muted, dim, red, orange, yellow, green, aqua, blue, purple, bright, frame, frame_active):
    return dict(title=title, light=True,
                background0=bg[0], background1=bg[1], background2=bg[2], background3=bg[3],
                foreground0=fg[0], foreground1=fg[1], foreground2=fg[2], gray=gray, muted=muted, dim=dim,
                red=red, orange=orange, yellow=yellow, green=green, aqua=aqua, blue=blue, purple=purple,
                bright=bright, frame=frame, frame_active=frame_active)


LIGHT = {
    "gruvbox": _l("Gruvbox Light — warm paper, dark brown ink",
                  ["fbf1c7", "f2e5bc", "ebdbb2", "d5c4a1"], ["3c3836", "282828", "504945"], "a89984", "6f6259", "c9b99a",
                  "c14a4a", "c35e0a", "b47109", "6c782e", "4c7a5d", "45707a", "945e80", "7c6f64", "7c6f64", "45707a"),
    "graphite": _l("Graphite Light — paper white, near-black text",
                   ["f5f5f5", "ececec", "e2e2e2", "d4d4d4"], ["1c1c1c", "0a0a0a", "444444"], "9a9a9a", "5f5f5f", "bdbdbd",
                   "c4384a", "c2671c", "9a7b0f", "2f8a5a", "1f8a99", "2f6fc4", "7b5cc0", "7a7a7a", "5c5c5c", "2c2c2c"),
    "ember": _l("Ember Light — warm linen, coral frames",
                ["faf3ee", "f2e7df", "e9dcd2", "dccabd"], ["3a2a24", "2a1d18", "5c4a42"], "a8958a", "6e5a4f", "c8b6aa",
                "d23b33", "c95a28", "a8771c", "4f8a2e", "1f8f7a", "2f6fc4", "a8429c", "8a776c", "e07a5f", "c95a28"),
    "khaki": _l("Khaki Light — sand paper, dark olive ink",
                ["f6f1e4", "ede6d4", "e3dbc6", "d6cbb0"], ["3a3426", "26221a", "5a5240"], "a39a85", "6b6250", "c7bfa9",
                "a8473a", "a8612e", "8a7020", "5e7a3a", "4f7f6e", "4a6e85", "7f5a74", "8a8270", "9a947a", "6f6650"),
    "catppuccin": _l("Catppuccin Latte — pastel ink on cool white",
                     ["eff1f5", "e6e9ef", "dce0e8", "ccd0da"], ["4c4f69", "2b2d42", "5c5f77"], "9ca0b0", "5c5f77", "bcc0cc",
                     "d20f39", "fe640b", "df8e1d", "40a02b", "179299", "1e66f5", "8839ef", "7c7f93", "8839ef", "7287fd"),
    "tokyonight": _l("Tokyo Night Day — navy ink on morning grey",
                     ["e1e2e7", "d5d6db", "c4c8da", "b6bfe2"], ["3760bf", "2e3c64", "6172b0"], "8990b3", "4f5a8a", "a8aecb",
                     "f52a65", "b15c00", "8c6c3e", "587539", "118c74", "2e7de9", "9854f1", "848cb5", "2e7de9", "9854f1"),
    "nord": _l("Nord Light — snow storm, polar night ink",
               ["eceff4", "e5e9f0", "d8dee9", "c8d0de"], ["2e3440", "242933", "3b4252"], "9aa5b8", "4c566a", "b9c2d2",
               "bf616a", "c0673f", "a07a1e", "5f8a45", "4f8f98", "5e81ac", "9a6f96", "7b88a1", "5e81ac", "81a1c1"),
    "rosepine": _l("Rosé Pine Dawn — soft rose paper",
                   ["faf4ed", "f2e9e1", "dfdad9", "cecacd"], ["575279", "464261", "797593"], "9893a5", "68637f", "b4b0bd",
                   "b4637a", "d7827e", "ea9d34", "5f8a6b", "56949f", "286983", "907aa9", "6e6a86", "907aa9", "d7827e"),
    "everforest": _l("Everforest Light — forest green on parchment",
                     ["fdf6e3", "f4f0d9", "efebd4", "e6e2cc"], ["5c6a72", "4a555b", "708089"], "a6b0a0", "66756d", "c8c9b5",
                     "f85552", "f57d26", "c78f00", "7f9300", "35a77c", "3a94c5", "df69ba", "939f91", "8da101", "35a77c"),
    "kanagawa": _l("Kanagawa Lotus — ink on aged paper",
                   ["f2ecbc", "e5ddb0", "dcd5ac", "d5cea3"], ["545464", "43436c", "6a6a7a"], "a09c86", "6b685a", "c4bf9c",
                   "c84053", "cc6d00", "77713f", "6f894e", "597b75", "4d699b", "624c83", "8a8980", "624c83", "4d699b"),
    "dracula": _l("Alucard — Dracula's light side",
                  ["fffbeb", "f2eedc", "e6e2cf", "cfcfde"], ["1f1f1f", "141414", "4a4a4a"], "9e9aa8", "635d97", "c4c0d0",
                  "cb3a2a", "a34d14", "846e15", "14710a", "036a96", "3557b8", "644ac9", "6c6c80", "644ac9", "a3144d"),
    "onedark": _l("One Light — Atom's light syntax",
                  ["fafafa", "f0f0f1", "e5e5e6", "dbdbdc"], ["383a42", "202227", "4f525e"], "a0a1a7", "62656f", "c2c2c3",
                  "e45649", "986801", "c18401", "50a14f", "0184bc", "4078f2", "a626a4", "7f848e", "4078f2", "a626a4"),
    "mono": _l("Mono Light — white and greys, accents barely tinted",
               ["ffffff", "f3f3f3", "e8e8e8", "dadada"], ["111111", "000000", "3a3a3a"], "9e9e9e", "5f5f5f", "c4c4c4",
               "8f4f4f", "8f6a4f", "7d7440", "4f6e4f", "4a6e69", "4f6587", "6c5a85", "737373", "737373", "111111"),
}
THEMES.update({f"{name}-light": pal for name, pal in LIGHT.items()})


def render(name, pal):
    """The theme's files, {path under themes/<name>: text}: gruvbox's own files
    and FROM_PACKAGES recoloured role by role, then the frames' own colours."""
    sources = {ROOT / "packages" / rel: rel for rel in FROM_PACKAGES}
    sources.update({p: str(p.relative_to(SRC)) for p in sorted(SRC.rglob("*")) if p.is_file() and p.name != "README.md"})
    files = {rel: recolor(src.read_text(), pal) for src, rel in sources.items()}
    q = "quickshell/shell/config/Colors.qml"
    files[q] = (re.sub(r'(readonly property color frame:\s*")#[0-9a-fA-F]{6}"', rf'\g<1>#{pal["frame"]}"', files[q])
                .replace("gruvbox theme overlay", f"{name} theme overlay"))
    h = "hypr/components/colors.lua"
    files[h] = (re.sub(r'frame_active = "rgb\([0-9a-fA-F]{6}\)"', f'frame_active = "rgb({pal["frame_active"]})"', files[h])
                .replace("-- gruvbox-material,", f"-- {name},"))
    # a light theme: GTK apps take Adwaita's light variant
    if pal.get("light"):
        files["gtk-3.0/settings.ini"] = (ROOT / "packages/gtk-3.0/settings.ini").read_text().replace(
            "gtk-theme-name=Adwaita-dark", "gtk-theme-name=Adwaita")
    m = "mako/config"
    files[m] = re.sub(r"\[urgency=normal\]\nborder-color=#[0-9a-fA-F]{6}", f"[urgency=normal]\nborder-color=#{pal['frame']}",
                      re.sub(r"^border-color=#[0-9a-fA-F]{6}", f"border-color=#{pal['frame']}", files[m], count=1, flags=re.M))
    return files


def build(name, pal):
    dst = ROOT / "themes" / name
    files = render(name, pal)
    # rewritten in place, stale files removed after: the active theme's files
    # never vanish under a running Hyprland (its autoreload would fail)
    old = {p for p in dst.rglob("*") if p.is_file()} if dst.exists() else set()
    for rel, text in files.items():
        out = dst / rel
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(text)
    for p in old - {dst / rel for rel in files}:
        p.unlink()
    for p in sorted(dst.rglob("*"), reverse=True):
        if p.is_dir() and not any(p.iterdir()):
            p.rmdir()
    # its wallpaper folder (wallpapers/<name>, kept outside the generated tree)
    wp = ROOT / "wallpapers" / name
    wp.mkdir(parents=True, exist_ok=True)
    (wp / ".gitkeep").touch()
    print(name, "->", len(files), "files")


def stale(name, pal):
    """Paths under themes/<name> that differ from what render() would write."""
    dst = ROOT / "themes" / name
    files = render(name, pal)
    have = {str(p.relative_to(dst)) for p in dst.rglob("*") if p.is_file()} if dst.exists() else set()
    differ = [rel for rel, text in files.items() if not (dst / rel).is_file() or (dst / rel).read_text() != text]
    return sorted(differ + [rel + " (extra)" for rel in have - set(files)])


if __name__ == "__main__":
    args = sys.argv[1:]
    check = "--check" in args
    names = [a for a in args if a != "--check"] or list(THEMES)
    unknown = [n for n in names if n not in THEMES]
    if unknown:
        sys.exit(f"unknown theme: {', '.join(unknown)} (have: {', '.join(THEMES)})")
    if not check:
        for n in names:
            build(n, THEMES[n])
        sys.exit(0)
    problems = [f"themes/{n}/{rel}" for n in names for rel in stale(n, THEMES[n])]
    for p in problems:
        print(p)
    sys.exit(1 if problems else 0)

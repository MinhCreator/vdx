#!/usr/bin/env python3
"""Rounded copies of the icons: round/<name>.svg and round/solid/<name>.svg —
the same drawings with their corners rounded: rectangles get a radius,
polygons, polylines and straight-line paths an arc at every corner, lines
round caps and joins. Curves keep their shape. KitIcon picks them when
ShellSettings.roundIcons is on. Run again after adding or changing an icon:
    python3 kit/icons/mkround.py"""
import math, re
from pathlib import Path

HERE = Path(__file__).resolve().parent
R = 4.0                                   # the corner radius, in the 24-unit view (≈2.5px at bar size)


def fmt(v):
    return f"{v:.2f}".rstrip("0").rstrip(".")


def rounded(points, closed):
    """A path through `points` with each corner cut by a quadratic arc."""
    n = len(points)
    if n < 3:
        return "M" + " L".join(f"{fmt(x)} {fmt(y)}" for x, y in points) + ("Z" if closed else "")
    out = []
    corners = range(n) if closed else range(1, n - 1)
    pieces = {}
    for i in corners:
        (px, py), (x, y), (nx, ny) = points[i - 1], points[i], points[(i + 1) % n]
        a, b = math.hypot(x - px, y - py), math.hypot(nx - x, ny - y)
        r = min(R, a / 2, b / 2)
        if r <= 0.01:
            continue
        pieces[i] = ((x + (px - x) * r / a, y + (py - y) * r / a), (x + (nx - x) * r / b, y + (ny - y) * r / b))
    for i, (x, y) in enumerate(points):
        if i in pieces:
            (sx, sy), (ex, ey) = pieces[i]
            out.append(("M" if not out else "L") + f"{fmt(sx)} {fmt(sy)}")
            out.append(f"Q{fmt(x)} {fmt(y)} {fmt(ex)} {fmt(ey)}")
        else:
            out.append(("M" if not out else "L") + f"{fmt(x)} {fmt(y)}")
    return " ".join(out) + (" Z" if closed else "")


def straight_path(d):
    """Subpaths of a path made only of M / L / H / V / Z, as point lists; None
    when it has curves or arcs."""
    if re.search(r"[CcSsQqTtAa]", d):
        return None
    tokens = re.findall(r"[MmLlHhVvZz]|-?\d*\.?\d+(?:e-?\d+)?", d)
    subs, cur, x, y, cmd, start = [], None, 0.0, 0.0, None, (0.0, 0.0)
    i = 0
    while i < len(tokens):
        t = tokens[i]
        if re.match(r"[A-Za-z]", t):
            cmd = t
            i += 1
            if cmd in "Zz":
                if cur:
                    subs.append((cur, True))
                cur, (x, y) = None, start
            continue
        if cmd in "Mm":
            nx, ny = float(tokens[i]), float(tokens[i + 1])
            i += 2
            if cmd == "m":
                nx, ny = x + nx, y + ny
            if cur:
                subs.append((cur, False))
            x, y, start, cur = nx, ny, (nx, ny), [(nx, ny)]
            cmd = "L" if cmd == "M" else "l"
        elif cmd in "Ll":
            nx, ny = float(tokens[i]), float(tokens[i + 1])
            i += 2
            if cmd == "l":
                nx, ny = x + nx, y + ny
            x, y = nx, ny
            cur.append((x, y))
        elif cmd in "Hh":
            v = float(tokens[i]); i += 1
            x = x + v if cmd == "h" else v
            cur.append((x, y))
        elif cmd in "Vv":
            v = float(tokens[i]); i += 1
            y = y + v if cmd == "v" else v
            cur.append((x, y))
        else:
            return None
    if cur:
        subs.append((cur, False))
    # a closing point repeating the start is no corner of its own
    return [(pts[:-1] if closed and len(pts) > 1 and pts[0] == pts[-1] else pts, closed) for pts, closed in subs]


def soften(svg):
    svg = svg.replace('stroke-linecap="square"', 'stroke-linecap="round"')
    svg = svg.replace('stroke-linejoin="miter"', 'stroke-linejoin="round"')

    def rect(m):
        tag = m.group(0)
        if "rx=" in tag:
            return tag
        w = float(re.search(r'width="([\d.]+)"', tag).group(1))
        h = float(re.search(r'height="([\d.]+)"', tag).group(1))
        return tag.replace("<rect", f'<rect rx="{fmt(min(R, w / 3, h / 3))}"', 1)

    def poly(m):
        kind, attrs, pts = m.group(1), m.group(2) + m.group(4), m.group(3)
        nums = [float(v) for v in re.findall(r"-?\d*\.?\d+", pts)]
        points = list(zip(nums[0::2], nums[1::2]))
        closed = kind == "polygon"
        if closed and points and points[0] == points[-1]:
            points = points[:-1]
        return f'<path{attrs} d="{rounded(points, closed)}"/>'

    def path(m):
        before, d, after = m.group(1), m.group(2), m.group(3)
        subs = straight_path(d)
        if not subs:
            return m.group(0)
        return f'<path{before}d="{" ".join(rounded(p, c) for p, c in subs)}"{after}/>'

    svg = re.sub(r"<rect\b[^>]*>", rect, svg)
    svg = re.sub(r'<(polygon|polyline)\b([^>]*?)points="([^"]*)"([^>]*?)/>', poly, svg)
    svg = re.sub(r'<path\b([^>]*?)d="([^"]*)"([^>]*?)/>', path, svg)
    return svg


for sub in ("", "solid"):
    src, dst = HERE / sub, HERE / "round" / sub
    dst.mkdir(parents=True, exist_ok=True)
    for f in sorted(src.glob("*.svg")):
        (dst / f.name).write_text(soften(f.read_text()))
print("rounded:", len(list((HERE / "round").glob("*.svg"))), "+", len(list((HERE / "round/solid").glob("*.svg"))))

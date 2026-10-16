#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = [
#     "Pillow",
# ]
# ///
"""colorpaper — an image recoloured to the active theme's palette (a wallpaper
in the desktop's colours); every theme ships its own copy with its colours.

    uv run ~/.config/scripts/colorpaper/main.py <input> <output> [--no-dither]
    uv run ~/.config/scripts/colorpaper/main.py --info
"""

import argparse
import sys
from pathlib import Path

try:
    from PIL import Image, ImageEnhance
except ImportError:
    sys.exit(
        "Missing dependency Pillow. Run with 'uv run recolor_palette.py' or 'pip install Pillow'."
    )


# Unique palette colors (duplicates like foreground/color7 collapsed into one)
PALETTE_HEX = [
    "#1b1b1b",  # background
    "#e5d7b2",  # foreground / color7
    "#a8a08a",  # cursor / color15
    "#464239",  # color0
    "#8a8270",  # color8
    "#d47766",  # color1 / color9  (red)
    "#a3b37a",  # color2 / color10 (green)
    "#dcc07a",  # color3 / color11 (yellow)
    "#7f9aa8",  # color4 / color12 (blue)
    "#b391a8",  # color5 / color13 (magenta)
    "#8fb3a0",  # color6 / color14 (cyan)
]

INFO_TEXT = """\
recolor_palette.py — recolor any image to match a fixed color palette
(Gruvbox Material Dark, by default embedded in this script).

HOW IT WORKS
  The image is quantized down to the palette's colors using Pillow.
  Floyd-Steinberg dithering is applied by default, which preserves
  gradients and detail instead of producing flat color blobs.

RUNNING WITH uv (recommended, no manual install needed)
  uv run recolor_palette.py input.jpg output.png

RUNNING AS AN EXECUTABLE
  chmod +x recolor_palette.py
  ./recolor_palette.py input.jpg output.png

RUNNING WITH PLAIN PYTHON
  pip install Pillow
  python3 recolor_palette.py input.jpg output.png

EXAMPLES
  uv run recolor_palette.py photo.jpg out.png
  uv run recolor_palette.py photo.jpg out.png --no-dither
  uv run recolor_palette.py photo.jpg out.png --contrast 1.2 --brightness 1.1 --saturation 0.8

TIPS
  This palette is dark and muted, so boosting --contrast and slightly
  lowering --saturation before quantizing often gives better results,
  especially on bright/high-contrast photos.

CURRENT PALETTE ({count} colors)
{palette}
"""


def hex_to_rgb(h: str) -> tuple[int, int, int]:
    h = h.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def build_palette_image(colors_hex: list[str]) -> Image.Image:
    """Build a palette-mode ('P') Image from a list of hex colors,
    as required by Image.quantize(palette=...)."""
    rgb_colors = [hex_to_rgb(c) for c in colors_hex]

    pal_img = Image.new("P", (1, 1))
    # PIL palettes always hold 256 entries (768 bytes) — pad with the last color
    flat_palette = []
    for r, g, b in rgb_colors:
        flat_palette.extend([r, g, b])
    while len(flat_palette) < 256 * 3:
        flat_palette.extend(rgb_colors[-1])
    pal_img.putpalette(flat_palette[: 256 * 3])
    return pal_img


def recolor(
    input_path: Path,
    output_path: Path,
    dither: bool = True,
    contrast: float = 1.0,
    brightness: float = 1.0,
    saturation: float = 1.0,
) -> None:
    img = Image.open(input_path).convert("RGB")

    if brightness != 1.0:
        img = ImageEnhance.Brightness(img).enhance(brightness)
    if contrast != 1.0:
        img = ImageEnhance.Contrast(img).enhance(contrast)
    if saturation != 1.0:
        img = ImageEnhance.Color(img).enhance(saturation)

    pal_img = build_palette_image(PALETTE_HEX)

    dither_mode = Image.FLOYDSTEINBERG if dither else Image.NONE
    quantized = img.quantize(palette=pal_img, dither=dither_mode)

    result = quantized.convert("RGB")
    result.save(output_path)
    print(f"Done: {output_path}")


def print_info() -> None:
    palette_lines = "\n".join(f"  {c}" for c in PALETTE_HEX)
    print(INFO_TEXT.format(count=len(PALETTE_HEX), palette=palette_lines))


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Recolor an image to match a fixed color palette (Gruvbox Material Dark).",
        epilog="Run with --info for a detailed explanation, usage examples, and the full palette.",
    )
    parser.add_argument("input", type=Path, nargs="?", help="path to the source image")
    parser.add_argument("output", type=Path, nargs="?", help="path to save the result")
    parser.add_argument(
        "--no-dither",
        action="store_true",
        help="disable dithering (flatter, more posterized look)",
    )
    parser.add_argument(
        "--contrast", type=float, default=1.0, help="contrast multiplier (default: 1.0)"
    )
    parser.add_argument(
        "--brightness",
        type=float,
        default=1.0,
        help="brightness multiplier (default: 1.0)",
    )
    parser.add_argument(
        "--saturation",
        type=float,
        default=1.0,
        help="saturation multiplier (default: 1.0)",
    )
    parser.add_argument(
        "--info",
        action="store_true",
        help="show detailed help, examples, and the full palette, then exit",
    )
    args = parser.parse_args()

    if args.info:
        print_info()
        return

    if args.input is None or args.output is None:
        parser.error("input and output are required (or pass --info for details)")

    if not args.input.exists():
        sys.exit(f"File not found: {args.input}")

    recolor(
        args.input,
        args.output,
        dither=not args.no_dither,
        contrast=args.contrast,
        brightness=args.brightness,
        saturation=args.saturation,
    )


if __name__ == "__main__":
    main()

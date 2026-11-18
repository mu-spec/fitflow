#!/usr/bin/env python3
"""Render the launcher/splash visual check sheet.

Reads the assets that build_launcher_icons.py wrote and previews them the way a
launcher and the splash screen actually draw them:

  * adaptive icon (foreground + background) drawn at 108 dp and cropped to a
    72 dp window, under four mask shapes (circle, squircle, rounded square,
    superellipse), plus the 66 dp content keyline,
  * legacy icons at their real pixel size, or a whole-number zoom when they are
    too small to read at 1:1,
  * the round variant,
  * the splash plate on the pale brand background at phone size.

Output: docs/release/artwork/launcher-mask-check.png

Run:  python3 tools/media/make_mask_check.py
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
RES = ROOT / "android" / "app" / "src" / "main" / "res"
SPLASH = ROOT / "assets" / "images" / "branding" / "home_workout_icon.png"
OUT = ROOT / "docs" / "release" / "artwork" / "launcher-mask-check.png"

SPLASH_BG = (0xE3, 0xFB, 0xDD)
SPLASH_INK = (0x15, 0x25, 0x1A)
PAGE = (24, 26, 28)
LABEL = (232, 235, 229)

TILE = 208
GAP = 14
LABEL_H = 18


def mask(kind: str, size: int) -> Image.Image:
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    e = size - 1
    if kind == "circle":
        d.ellipse((0, 0, e, e), fill=255)
    elif kind == "squircle":
        d.rounded_rectangle((0, 0, e, e), radius=int(size * 0.30), fill=255)
    elif kind == "roundedsquare":
        d.rounded_rectangle((0, 0, e, e), radius=int(size * 0.16), fill=255)
    elif kind == "superellipse":
        # n = 4.5, the shape behind many OEM squircle masks.
        a = e / 2
        pts = []
        for i in range(360):
            t = math.radians(i)
            ct, st = math.cos(t), math.sin(t)
            pts.append((a + a * math.copysign(abs(ct) ** (2 / 4.5), ct),
                        a + a * math.copysign(abs(st) ** (2 / 4.5), st)))
        d.polygon(pts, fill=255)
    return m


def adaptive() -> Image.Image:
    fg = Image.open(RES / "mipmap-xxxhdpi" / "ic_launcher_foreground.png").convert("RGBA")
    bg = Image.open(RES / "mipmap-xxxhdpi" / "ic_launcher_background.png").convert("RGBA")
    layer = bg.copy()
    layer.alpha_composite(fg)
    return layer


def adaptive_tile(layer: Image.Image, kind: str, safe_ring: bool) -> Image.Image:
    """Draw the 108 dp layer the way launchers do: scaled to 72 dp, then masked."""
    scaled = layer.resize((int(TILE * 108 / 72),) * 2, Image.LANCZOS)
    wall = Image.new("RGB", (TILE, TILE), (245, 246, 243))
    inset = (scaled.width - TILE) // 2
    window = scaled.crop((inset, inset, inset + TILE, inset + TILE))
    window.putalpha(ImageChops.multiply(window.split()[3], mask(kind, TILE)))
    wall.paste(window, (0, 0), window)
    if safe_ring:
        d = ImageDraw.Draw(wall)
        r = TILE * (66 / 72) / 2
        c = TILE / 2
        d.ellipse((c - r, c - r, c + r, c + r), outline=(255, 0, 140), width=1)
    return wall


def splash_tile() -> Image.Image:
    plate = Image.open(SPLASH).convert("RGB")
    wall = Image.new("RGB", (TILE, TILE), SPLASH_BG)
    icon = plate.resize((int(TILE * 0.42), int(TILE * 0.42)), Image.LANCZOS)
    r = int(icon.width * 32 / 156)
    rounded = Image.new("L", icon.size, 0)
    ImageDraw.Draw(rounded).rounded_rectangle(
        (0, 0, icon.width - 1, icon.height - 1), radius=r, fill=255
    )
    x = (TILE - icon.width) // 2
    wall.paste(icon, (x, int(TILE * 0.20)), rounded)
    d = ImageDraw.Draw(wall)
    d.text((TILE // 2 - 30, int(TILE * 0.20) + icon.height + 10), "Home Workout",
           fill=SPLASH_INK)
    d.text((TILE // 2 - 32, int(TILE * 0.20) + icon.height + 26),
           "Workouts that adapt to you.", fill=(0x3F, 0x5B, 0x45))
    d.rectangle((TILE // 2 - 10, int(TILE * 0.20) + icon.height + 44,
                 TILE // 2 + 10, int(TILE * 0.20) + icon.height + 46),
                fill=(0x48, 0xE6, 0x1D))
    return wall


def legacy(density: str, round_variant: bool) -> Image.Image:
    """Real pixel size, or a small whole-number zoom so the tile stays legible."""
    name = "ic_launcher_round.png" if round_variant else "ic_launcher.png"
    src = Image.open(RES / f"mipmap-{density}" / name).convert("RGBA")
    zoom = max(1, TILE // (src.width * 2)) if src.width < TILE // 2 else 1
    shown = src.resize((src.width * zoom, src.height * zoom), Image.NEAREST)
    wall = Image.new("RGB", (TILE, TILE), (245, 246, 243))
    wall.paste(shown, ((TILE - shown.width) // 2, (TILE - shown.height) // 2), shown)
    return wall


def main() -> None:
    layer = adaptive()
    tiles: list[tuple[str, Image.Image]] = []

    for kind in ("circle", "squircle", "roundedsquare", "superellipse"):
        tiles.append((f"adaptive: {kind}", adaptive_tile(layer, kind, False)))
    tiles.append(("adaptive: circle + 66dp safe", adaptive_tile(layer, "circle", True)))

    for density, px in (("mdpi", 48), ("hdpi", 72), ("xhdpi", 96),
                        ("xxhdpi", 144), ("xxxhdpi", 192)):
        tiles.append((f"{density} legacy {px}px", legacy(density, False)))

    tiles.append(("round variant 192px", legacy("xxxhdpi", True)))
    tiles.append(("splash on #E3FBDD", splash_tile()))

    cols = 4
    rows = (len(tiles) + cols - 1) // cols
    width = cols * (TILE + GAP) + GAP
    height = rows * (TILE + GAP + LABEL_H) + GAP + 26
    sheet = Image.new("RGB", (width, height), PAGE)
    d = ImageDraw.Draw(sheet)
    d.text((GAP, 8), "Home Workout - approved artwork 512x512, launcher + splash", fill=LABEL)

    for i, (name, tile) in enumerate(tiles):
        r, c = divmod(i, cols)
        x = GAP + c * (TILE + GAP)
        y = 26 + GAP + r * (TILE + GAP + LABEL_H)
        sheet.paste(tile, (x, y))
        d.text((x, y + TILE + 3), name, fill=LABEL)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT, format="PNG", optimize=True)
    print(f"wrote {OUT.relative_to(ROOT)} ({sheet.width}x{sheet.height})")


if __name__ == "__main__":
    main()

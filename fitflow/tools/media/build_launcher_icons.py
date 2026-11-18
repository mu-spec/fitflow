#!/usr/bin/env python3
"""Build the Home Workout launcher and splash assets from the approved icon.

Source of truth (do not edit): docs/release/artwork/play_store_icon.png
The approved artwork is a rounded-square (squircle) composition exported on a
white canvas. Nothing inside the squircle is redrawn, recoloured or rescaled
out of proportion here. This script only:

  1. detects the white canvas outside the squircle and keys it out,
  2. composites the artwork over the icon's own dark green field so the
     legacy/round launcher icons have no white corners,
  3. fits the artwork inside the 72 dp adaptive-icon safe area for the
     foreground layer, leaving it transparent outside,
  4. paints a matching dark navy/green background layer,
  5. writes the Play listing icon copy and the Flutter splash artwork.

Run:  python3 tools/media/build_launcher_icons.py
"""

from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
APPROVED = ROOT / "docs" / "release" / "artwork" / "play_store_icon.png"
RES = ROOT / "android" / "app" / "src" / "main" / "res"
SPLASH_ASSET = ROOT / "assets" / "images" / "branding" / "home_workout_icon.png"

# Density buckets: legacy launcher px, adaptive layer px (108 dp canvas).
DENSITIES = {
    "mdpi": (48, 108),
    "hdpi": (72, 162),
    "xhdpi": (96, 216),
    "xxhdpi": (144, 324),
    "xxxhdpi": (192, 432),
}

# Colours sampled from the approved artwork's own dark field (see README notes
# in docs/release/artwork/icon-generation.md).
BG_CENTER = (14, 34, 29)   # #0E221D
BG_EDGE = (6, 18, 15)      # #06120F


def white_outside_mask(rgb: Image.Image) -> Image.Image:
    """Alpha mask (L) that is 0 on the white canvas outside the squircle."""
    a = np.asarray(rgb).astype(int)
    white = a.min(axis=2) > 235
    h, w = white.shape
    outside = np.zeros_like(white)
    queue: deque[tuple[int, int]] = deque()
    for x in range(w):
        for y in (0, h - 1):
            if white[y, x] and not outside[y, x]:
                outside[y, x] = True
                queue.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if white[y, x] and not outside[y, x]:
                outside[y, x] = True
                queue.append((y, x))
    while queue:
        y, x = queue.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and white[ny, nx] and not outside[ny, nx]:
                outside[ny, nx] = True
                queue.append((ny, nx))
    inner = np.where(outside, 0, 255).astype(np.uint8)
    mask = Image.fromarray(inner, mode="L")
    # 1 px feather so the squircle rim is not aliased against the new field.
    return mask.filter(ImageFilter.GaussianBlur(0.8))


def squircle_rgba(src: Image.Image) -> Image.Image:
    """Approved artwork with the white canvas replaced by transparency."""
    rgba = src.convert("RGBA")
    rgba.putalpha(white_outside_mask(src))
    return rgba


def gradient_canvas(size: int) -> Image.Image:
    """Dark navy/green radial background layer, sized size x size."""
    small = 64
    img = Image.new("RGB", (small, small), BG_EDGE)
    px = img.load()
    cx = cy = (small - 1) / 2
    max_d = (cx**2 + cy**2) ** 0.5
    for y in range(small):
        for x in range(small):
            d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5 / max_d
            t = min(1.0, d * 1.15)
            px[x, y] = tuple(
                round(BG_CENTER[i] + (BG_EDGE[i] - BG_CENTER[i]) * t) for i in range(3)
            )
    return img.resize((size, size), Image.LANCZOS).convert("RGBA")


def on_field(rgba: Image.Image, size: int) -> Image.Image:
    """Artwork flattened over the icon's own field at `size` x `size`."""
    plate = Image.new("RGBA", rgba.size, BG_EDGE + (255,))
    plate.alpha_composite(rgba)
    return plate.resize((size, size), Image.LANCZOS)


def round_icon(art: Image.Image, size: int, fill: float = 0.90) -> Image.Image:
    """Circular legacy icon: artwork inside a dark disc, nothing fringed."""
    disc = gradient_canvas(size)
    box = max(1, round(size * fill))
    inner = art.resize((box, box), Image.LANCZOS)
    offset = (size - box) // 2
    disc.alpha_composite(inner, (offset, offset))
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size - 1, size - 1), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(max(0.6, size * 0.006)))
    disc.putalpha(mask)
    return disc


def adaptive_foreground(rgba: Image.Image, canvas: int) -> Image.Image:
    """Artwork centred in the 72 dp safe area, with a soft edge to the field.

    Sized so that every key element - both heads, the house symbol and the
    dumbbell - stays inside the 72 dp safe circle (36 dp radius from the
    centre). Measured on the approved artwork, the outermost key element
    (the dumbbell's lower corners) sits at 49% of the artwork width from
    centre, so a 73/108 box is the largest scale that keeps the whole
    composition inside the safe area. The outer edge is feathered so the
    glow frame melts into the background layer instead of ending on a hard
    straight line.
    """
    box = round(canvas * 73 / 108)
    content = rgba.resize((box, box), Image.LANCZOS)
    feather = Image.new("L", (box, box), 0)
    ImageDraw.Draw(feather).rounded_rectangle(
        (0, 0, box - 1, box - 1), radius=round(box * 0.24), fill=255
    )
    feather = feather.filter(ImageFilter.GaussianBlur(canvas * 0.028))
    alpha = Image.composite(content.getchannel("A"), Image.new("L", (box, box), 0), feather)
    content.putalpha(alpha)
    layer = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    offset = (canvas - box) // 2
    layer.alpha_composite(content, (offset, offset))
    return layer


def write_png(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, format="PNG", optimize=True)


def main() -> None:
    src = Image.open(APPROVED).convert("RGB")
    if src.size != (512, 512):
        raise SystemExit(f"approved icon must be 512x512, got {src.size}")
    art = squircle_rgba(src)

    created: list[tuple[str, tuple[int, int], str]] = []

    for density, (legacy_px, layer_px) in DENSITIES.items():
        mip = RES / f"mipmap-{density}"

        # 1. Legacy launcher icon (full-bleed, no white corners).
        legacy = on_field(art, legacy_px)
        write_png(legacy, mip / "ic_launcher.png")
        created.append((f"mipmap-{density}/ic_launcher.png", legacy.size, "RGB opaque"))

        # 2. Round launcher icon (same artwork, circular crop).
        rnd = round_icon(art, legacy_px)
        write_png(rnd, mip / "ic_launcher_round.png")
        created.append((f"mipmap-{density}/ic_launcher_round.png", rnd.size, "RGBA circular"))

        # 3. Adaptive foreground: artwork inside the 72 dp safe area.
        fg = adaptive_foreground(art, layer_px)
        write_png(fg, mip / "ic_launcher_foreground.png")
        created.append(
            (f"mipmap-{density}/ic_launcher_foreground.png", fg.size, "RGBA transparent")
        )

        # 4. Adaptive background: matching dark navy/green field.
        bg = gradient_canvas(layer_px)
        write_png(bg, mip / "ic_launcher_background.png")
        created.append(
            (f"mipmap-{density}/ic_launcher_background.png", bg.size, "RGB opaque")
        )

    # 5. Flutter splash artwork: the same approved icon, squircle rim on a
    # transparent canvas, so it floats on the existing #202526 splash colour
    # exactly like the artwork it replaces (no colour patch at the corners).
    splash = art.resize((512, 512), Image.LANCZOS)
    write_png(splash, SPLASH_ASSET)
    created.append(("assets/images/branding/home_workout_icon.png", splash.size, "RGBA squircle"))

    for name, size, kind in created:
        print(f"{name:52s} {size[0]:>4d}x{size[1]:<4d} {kind}")


if __name__ == "__main__":
    main()

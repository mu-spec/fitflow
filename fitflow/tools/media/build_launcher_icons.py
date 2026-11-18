#!/usr/bin/env python3
"""Build the Home Workout launcher and splash assets from the approved icon.

Source of truth (do not edit): docs/release/artwork/play_store_icon.png
The approved artwork is a rounded-square (squircle) composition exported on a
white canvas: two fitness models in black and neon-green sportswear on a light
green field, no text, no house, no dumbbell.

Nothing is redrawn, recoloured or rescaled out of proportion here. The script
only

  1. detects the white canvas outside the squircle and keys it out,
  2. separates the two models from the artwork's own green field by
     flood-filling the green that touches the border, so the neon-green
     sportswear accents (enclosed by black fabric) survive intact,
  3. rebuilds the light green field: the artwork's own radial light is measured
     for the adaptive background layer, and for the opaque plates the field is
     extended outwards from the squircle edge so it never shows a seam,
  4. fits the models inside the adaptive-icon safe area for the foreground
     layer, transparent everywhere else,
  5. writes opaque full-bleed legacy icons, round icons and the splash plate.

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

# Model scale on the adaptive layer. Measured on the approved artwork: both
# heads reach 43% of the artwork width from the centre and the widest part of
# the crossed arms reaches 58%. 36 dp / 0.58 = 62 dp, so 62 dp is the largest
# scale that keeps every part of both models - heads, faces, torsos and crossed
# arms - inside the 72 dp safe circle under a circular mask.
ADAPTIVE_FILL = 62 / 108

# Splash plate: the artwork scaled around its models, which are cut off by the
# bottom edge of the source frame, so the plate is square and full-bleed.
SPLASH_PX = 512


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
    return Image.fromarray(np.where(outside, 0, 255).astype(np.uint8), mode="L")


def _flood(pred: np.ndarray, seeds: list[tuple[int, int]]) -> np.ndarray:
    h, w = pred.shape
    seen = np.zeros_like(pred)
    queue: deque[tuple[int, int]] = deque()
    for x, y in seeds:
        if 0 <= y < h and 0 <= x < w and pred[y, x] and not seen[y, x]:
            seen[y, x] = True
            queue.append((y, x))
    while queue:
        y, x = queue.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and pred[ny, nx] and not seen[ny, nx]:
                seen[ny, nx] = True
                queue.append((ny, nx))
    return seen


def models_rgba(src: Image.Image) -> Image.Image:
    """The two models only, transparent everywhere else."""
    a = np.asarray(src).astype(int)
    h, w, _ = a.shape
    r, g, b = a[:, :, 0], a[:, :, 1], a[:, :, 2]
    white = a.min(axis=2) > 235
    green = (g > 110) & (g > r + 30) & (g > b + 30)

    border = (
        [(x, 0) for x in range(w)]
        + [(x, h - 1) for x in range(w)]
        + [(0, y) for y in range(h)]
        + [(w - 1, y) for y in range(h)]
    )
    outside = _flood(white, border)
    # Green connected to the frame is the field; green enclosed by the black
    # sportswear is the neon accent and must stay.
    field = _flood(green & ~outside, [(255, 8), (8, 255), (255, 503), (503, 255),
                                      (150, 40), (360, 40)])
    models = (~outside) & (~field)

    # Drop the 5 px rim of antialiasing where the squircle met the white canvas.
    keep = np.asarray(
        Image.fromarray(((~outside) * 255).astype(np.uint8)).filter(ImageFilter.MinFilter(11))
    )
    models &= keep > 128

    alpha = Image.fromarray((models * 255).astype(np.uint8), mode="L")
    alpha = alpha.filter(ImageFilter.GaussianBlur(1.2))
    rgba = src.convert("RGBA")
    rgba.putalpha(alpha)
    return rgba


def radial_profile(src: Image.Image) -> list[tuple[float, tuple[int, int, int]]]:
    """Measure the artwork's own green as a function of radius.

    The field is not flat: it runs from a bright centre to a deeper rim. Fitting
    the real profile is what makes the rebuilt background and the full-bleed
    plate continue the artwork seamlessly instead of leaving a ring where the
    flat fill met the squircle.
    """
    a = np.asarray(src).astype(int)
    h, w, _ = a.shape
    r, g, b = a[:, :, 0], a[:, :, 1], a[:, :, 2]
    green = (g > 110) & (g > r + 30) & (g > b + 30)
    y, x = np.mgrid[0:h, 0:w]
    c = (h - 1) / 2
    d = np.sqrt((x - c) ** 2 + (y - c) ** 2) / (h * 0.7071)
    profile: list[tuple[float, tuple[int, int, int]]] = []
    step = 0.05
    t = 0.0
    last = (157, 251, 106)
    while t < 1.0:
        m = green & (d >= t) & (d < t + step)
        if m.sum() > 400:
            last = tuple(int(v) for v in np.median(a[m], axis=0))
        profile.append((round(t + step / 2, 3), last))
        t += step
    return profile


def _sample(profile: list[tuple[float, tuple[int, int, int]]], t: float) -> tuple[int, int, int]:
    """Linear lookup into the measured radial profile."""
    if t <= profile[0][0]:
        return profile[0][1]
    for (t0, c0), (t1, c1) in zip(profile, profile[1:]):
        if t <= t1:
            k = 0.0 if t1 == t0 else (t - t0) / (t1 - t0)
            return tuple(round(c0[i] + (c1[i] - c0[i]) * k) for i in range(3))
    # Beyond the measured range: extrapolate one more step with the same slope.
    (t0, c0), (t1, c1) = profile[-2], profile[-1]
    slope = [(c1[i] - c0[i]) / max(1e-6, t1 - t0) for i in range(3)]
    extra = t - t1
    return tuple(max(0, min(255, round(c1[i] + slope[i] * extra))) for i in range(3))


def gradient_field(size: int, profile: list[tuple[float, tuple[int, int, int]]]) -> Image.Image:
    """The artwork's own radial light, rebuilt at any size."""
    small = 96
    img = Image.new("RGB", (small, small))
    px = img.load()
    c = (small - 1) / 2
    max_d = (c**2 + c**2) ** 0.5
    for y in range(small):
        for x in range(small):
            t = ((x - c) ** 2 + (y - c) ** 2) ** 0.5 / max_d
            px[x, y] = _sample(profile, t)
    return img.resize((size, size), Image.LANCZOS).convert("RGBA")


def _fill_outside(rgb: np.ndarray, keep: np.ndarray, rounds: int = 96) -> np.ndarray:
    """Grow the kept pixels outwards so the frame is full-bleed.

    Each pass copies the colour of an already-filled neighbour into the next
    ring of empty pixels. Because the squircle is convex, this continues the
    artwork's own light outwards instead of stamping a second, slightly
    different green on top of it - which is what left a visible ring where a
    flat fill (or the measured gradient) met the squircle edge.
    """
    out = rgb.copy()
    filled = keep.copy()
    for _ in range(rounds):
        if filled.all():
            break
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            source = np.roll(out, (dy, dx), axis=(0, 1))
            ok = np.roll(filled, (dy, dx), axis=(0, 1))
            take = (~filled) & ok
            out[take] = source[take]
            filled |= take
    return out


def plate(src: Image.Image, size: int) -> Image.Image:
    """Opaque full-bleed artwork: white canvas keyed out, field extended.

    The antialiased rim where the squircle met the white canvas is discarded too,
    so nothing pale survives to become a halo at 48 px.
    """
    keep_mask = white_outside_mask(src)
    keep = np.asarray(keep_mask) > 128
    # The artwork carries a ~4 px darker shading band along the squircle edge.
    # Start the fill from inside that band so the extension continues it, rather
    # than sitting brighter than it and drawing a visible arc.
    keep = np.asarray(
        Image.fromarray((keep * 255).astype(np.uint8)).filter(ImageFilter.MinFilter(13))
    ) > 128

    rgb = np.asarray(src.convert("RGB"))
    filled = _fill_outside(rgb, keep)
    img = Image.fromarray(filled, mode="RGB")

    # Smooth only the synthesised border so the 1 px growth rings do not show.
    blurred = img.filter(ImageFilter.GaussianBlur(2.5))
    img = Image.composite(img, blurred, keep_mask.filter(ImageFilter.MaxFilter(9)))
    return img.convert("RGBA").resize((size, size), Image.LANCZOS)


def round_icon(src: Image.Image, size: int) -> Image.Image:
    """Circular legacy icon: the full-bleed plate, cropped to a disc."""
    disc = plate(src, size)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size - 1, size - 1), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(max(0.6, size * 0.006)))
    disc.putalpha(mask)
    return disc


def adaptive_foreground(models: Image.Image, canvas: int) -> Image.Image:
    """Models centred inside the 72 dp safe area, transparent elsewhere."""
    box = round(canvas * ADAPTIVE_FILL)
    content = models.resize((box, box), Image.LANCZOS)
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

    profile = radial_profile(src)
    centre, edge = profile[0][1], profile[-1][1]
    print(
        f"background field centre #{centre[0]:02X}{centre[1]:02X}{centre[2]:02X} -> "
        f"rim #{edge[0]:02X}{edge[1]:02X}{edge[2]:02X}"
    )
    models = models_rgba(src)

    created: list[tuple[str, tuple[int, int], str]] = []

    for density, (legacy_px, layer_px) in DENSITIES.items():
        mip = RES / f"mipmap-{density}"

        legacy = plate(src, legacy_px)
        write_png(legacy.convert("RGB"), mip / "ic_launcher.png")
        created.append((f"mipmap-{density}/ic_launcher.png", legacy.size, "RGB opaque"))

        rnd = round_icon(src, legacy_px)
        write_png(rnd, mip / "ic_launcher_round.png")
        created.append((f"mipmap-{density}/ic_launcher_round.png", rnd.size, "RGBA circular"))

        fg = adaptive_foreground(models, layer_px)
        write_png(fg, mip / "ic_launcher_foreground.png")
        created.append(
            (f"mipmap-{density}/ic_launcher_foreground.png", fg.size, "RGBA transparent")
        )

        bg = gradient_field(layer_px, profile)
        write_png(bg.convert("RGB"), mip / "ic_launcher_background.png")
        created.append(
            (f"mipmap-{density}/ic_launcher_background.png", bg.size, "RGB opaque")
        )

    # Flutter splash: the same approved artwork as an opaque plate whose border
    # is exactly the splash background colour, so it fills the screen with no
    # visible edge, no white corners and no second logo.
    splash = plate(src, SPLASH_PX).convert("RGB")
    write_png(splash, SPLASH_ASSET)

    corner = np.asarray(splash)[2, 2]
    print(
        f"plate edge #{corner[0]:02X}{corner[1]:02X}{corner[2]:02X}"
        "  <- splash background colour"
    )
    created.append(
        ("assets/images/branding/home_workout_icon.png", splash.size, "RGB opaque")
    )

    for name, size, kind in created:
        print(f"{name:52s} {size[0]:>4d}x{size[1]:<4d} {kind}")


if __name__ == "__main__":
    main()

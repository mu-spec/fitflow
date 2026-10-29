"""Slim the transparent, original 3/4-view squat artwork at authoring time.

The athlete's head and shoes keep their original scale and floor position. The
body between them is gently narrowed, with a smooth transition by image row.
This is a stylized derivative, not a source-artist-approved exercise guide.
"""
from __future__ import annotations

import numpy as np
from PIL import Image


def slim_squat_frame(image: Image.Image, *, width: float = .78) -> Image.Image:
    """Return an RGBA character frame; never warp the background or props."""
    if not .6 <= width <= 1.0:
        raise ValueError('width must be between .6 and 1')
    pixels = np.asarray(image.convert('RGBA'), dtype=np.float32)
    height, canvas_width, _ = pixels.shape
    alpha = pixels[:, :, 3]
    if alpha.min() == 255:
        raise ValueError('Use transparent athlete frames from extract_character.cjs')
    rows, columns = np.where(alpha > 32)
    if len(rows) == 0:
        raise ValueError('Empty athlete frame')
    top, bottom = int(rows.min()), int(rows.max())
    body_height = max(1, bottom - top)

    # An alpha-weighted centre follows the torso smoothly as the athlete
    # squats. Hands are not used as a global crop or a camera position.
    band = alpha[int(top + body_height*.19):int(top + body_height*.49), :]
    column_weight = band.sum(axis=0)
    if column_weight.sum() == 0:
        raise ValueError('No torso pixels in frame')
    center = float(np.dot(column_weight, np.arange(canvas_width)) / column_weight.sum())
    y = np.arange(height, dtype=np.float32)
    factors = np.interp((y-top)/body_height,
                        [0, .13, .23, .65, .81, .91, 1],
                        [1, 1, width, width, (width+1)/2, 1, 1]).astype(np.float32)
    x = np.arange(canvas_width, dtype=np.float32)
    source_x = (x[None, :] - center) / factors[:, None] + center
    left = np.floor(source_x).astype(np.int32)
    right = left + 1
    fraction = (source_x-left)[:, :, None]
    valid_left = (left >= 0) & (left < canvas_width)
    valid_right = (right >= 0) & (right < canvas_width)
    left = np.clip(left, 0, canvas_width-1)
    right = np.clip(right, 0, canvas_width-1)
    row_indices = np.arange(height)[:, None]

    # Interpolate premultiplied colors so transparent edges do not acquire a
    # dark outline. The alpha channel is restored before returning the image.
    pixels[:, :, :3] *= pixels[:, :, 3:4] / 255.0
    lhs = pixels[row_indices, left] * valid_left[:, :, None]
    rhs = pixels[row_indices, right] * valid_right[:, :, None]
    result = lhs*(1-fraction) + rhs*fraction
    a = result[:, :, 3:4]
    result[:, :, :3] = np.divide(result[:, :, :3] * 255.0, a,
                                  out=np.zeros_like(result[:, :, :3]), where=a > 0)
    return Image.fromarray(np.clip(np.rint(result), 0, 255).astype(np.uint8), 'RGBA')

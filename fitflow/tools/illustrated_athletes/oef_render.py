"""Render exercise figure files (figures/*.json) to looping animated WebP.

A figure file describes a mannequin in side or front view as a few key poses
plus the equipment it holds. Angles are absolute, in degrees, per segment:
0 points up, 90 points the way the figure faces, 180 points down, 270 back.

    python3 render.py figures/a.json figures/b.json   # into out/, plus out/sheet.png

build.py renders the whole exercise library.
"""

import json
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).parent
SIZE = 480
SCALE = 2  # supersampling for smooth edges
W = SIZE * SCALE
FPS = 15
FRAMES_PER_MOVE = 14
HOLD_FRAMES = 3

# Studio look: a soft-shaded grey mannequin on a light backdrop.
STYLE = dict(
    bg_top=(250, 250, 252), bg_bottom=(232, 234, 240), floor=(220, 223, 231),
    body=(150, 158, 176), body_far=(196, 201, 214), shadow_mul=0.5, spec=0.45,
    muscle=(255, 61, 87), muscle2=(214, 168, 180), outline=(90, 96, 112))

# Segment lengths in metres for a 1.75 m figure.
LEN = {"torso": 0.52, "neck": 0.10, "upperArm": 0.30, "forearm": 0.25, "hand": 0.09,
       "thigh": 0.44, "shin": 0.43, "foot": 0.17}
HEAD_R = 0.115
HIP_HALF = 0.09  # front view: half the distance between hip joints
SHOULDER_HALF = 0.17

# Muscles a figure can highlight (the exercise's target and secondary muscles).
MUSCLES = ("biceps", "triceps", "forearms", "delts", "pectorals", "serratus anterior", "abs", "lats",
           "upper back", "traps", "spine", "glutes", "quads", "hamstrings", "adductors", "abductors",
           "calves", "levator scapulae")

SIDES = ("near", "far")


def unit(angle):
    a = math.radians(angle)
    return math.sin(a), math.cos(a)


def side_pair(value):
    """`[a, b]` applies to both sides; `{"near": [...], "far": [...]}` splits them."""
    if isinstance(value, dict):
        return value["near"], value.get("far", value["near"])
    return value, value


def solve(pose, view):
    """Forward kinematics from the hip; returns joint positions."""
    torso = pose.get("torso", 0)
    head = pose.get("head", torso)
    neck = pose.get("neck", head)
    arms = side_pair(pose.get("arms", [180, 180]))
    legs = side_pair(pose.get("legs", [180, 180, 95]))
    short = pose.get("shorten", {})
    seg = {k: v * short.get(k, 1) for k, v in LEN.items()}
    j = {"hip": (0.0, 0.0)}
    dx, dy = unit(torso)
    j["shoulder"] = (dx * seg["torso"], dy * seg["torso"])
    nx, ny = unit(neck)
    j["neckTop"] = (j["shoulder"][0] + nx * seg["neck"], j["shoulder"][1] + ny * seg["neck"])
    hx, hy = unit(head)
    j["head"] = (j["neckTop"][0] + hx * HEAD_R * 0.8, j["neckTop"][1] + hy * HEAD_R * 0.8)
    # The face looks the way the head's "forward" points (side view only).
    fx, fy = unit(head + 90)
    j["face"] = (j["head"][0] + fx * HEAD_R * 0.95, j["head"][1] + fy * HEAD_R * 0.95)
    for side, arm, leg in zip(SIDES, arms, legs):
        if view == "front":
            # Near = the figure's left, drawn on the viewer's right.
            sign = 1 if side == "near" else -1
            px, py = dy * SHOULDER_HALF * sign, -dx * SHOULDER_HALF * sign
            hipx, hipy = dy * HIP_HALF * sign, -dx * HIP_HALF * sign
            mirror = (lambda a: a) if side == "near" else (lambda a: -a)
        else:
            px = py = hipx = hipy = 0.0
            mirror = lambda a: a
        s = (j["shoulder"][0] + px, j["shoulder"][1] + py)
        j[f"{side}Shoulder"] = s
        e = add(s, unit(mirror(arm[0])), seg["upperArm"])
        j[f"{side}Elbow"] = e
        w = add(e, unit(mirror(arm[1])), seg["forearm"])
        j[f"{side}Wrist"] = w
        hand = arm[2] if len(arm) > 2 else arm[1]
        j[f"{side}Hand"] = add(w, unit(mirror(hand)), seg["hand"])
        h = (hipx, hipy)
        j[f"{side}Hip"] = h
        k = add(h, unit(mirror(leg[0])), seg["thigh"])
        j[f"{side}Knee"] = k
        a = add(k, unit(mirror(leg[1])), seg["shin"])
        j[f"{side}Ankle"] = a
        foot = leg[2] if len(leg) > 2 else 95
        # Seen from the front a foot points at the viewer, so it looks short.
        foot_len = seg["foot"] * (0.45 if view == "front" else 1)
        j[f"{side}Toe"] = add(a, unit(mirror(foot)), foot_len)
    return j


def add(p, d, length):
    return p[0] + d[0] * length, p[1] + d[1] * length


def anchored(joints, anchor):
    """Translate so the anchor joint lands on its fixed world point."""
    name, at = anchor
    ax, ay = joints[name]
    return {k: (x - ax + at[0], y - ay + at[1]) for k, (x, y) in joints.items()}


def lerp_angle(a, b, t):
    d = (b - a + 180) % 360 - 180
    return a + d * t


def lerp_pose(p, q, t):
    out = {}
    for key in set(p) | set(q):
        a, b = p.get(key, q.get(key)), q.get(key, p.get(key))
        if key == "lift":
            out[key] = a + (b - a) * t
        elif key == "shorten":
            out[key] = lerp_linear(a, b, t, 1)
        elif key == "props":
            out[key] = [lerp_linear(x, y, t, None) for x, y in zip(a, b)]
        else:
            out[key] = lerp_value(a, b, t)
    return out


def lerp_linear(a, b, t, default):
    """Plain (not angular) blend of two {name: number or [numbers]} maps."""
    out = {}
    for k in set(a) | set(b):
        x, y = a.get(k, default), b.get(k, default)
        if x is None or y is None:
            out[k] = x if y is None else y
        elif isinstance(x, list):
            out[k] = [u + (v - u) * t for u, v in zip(x, y)]
        elif isinstance(x, (int, float)) and isinstance(y, (int, float)):
            out[k] = x + (y - x) * t
        else:
            out[k] = x if t < 0.5 else y
    return out


def lerp_value(a, b, t):
    if isinstance(a, (int, float)):
        return lerp_angle(a, b, t)
    if isinstance(a, dict) or isinstance(b, dict):
        an, af = side_pair(a)
        bn, bf = side_pair(b)
        return {"near": lerp_value(an, bn, t), "far": lerp_value(af, bf, t)}
    return [lerp_angle(x, y, t) for x, y in zip(a, b)]


def complete(pose, fig):
    """Spell out the defaults, so a pose that leaves a key out animates to the
    default (or the equipment's own value) instead of borrowing its neighbour's."""
    head = pose.get("head", pose.get("torso", 0))
    items = fig.get("equipment", [])
    moved = [set() for _ in items]
    for other in fig["poses"]:
        for keys, override in zip(moved, other.get("props", [])):
            keys.update(override)
    own = pose.get("props", [])
    props = [{**{k: item[k] for k in keys if k in item}, **(own[i] if i < len(own) else {})}
             for i, (item, keys) in enumerate(zip(items, moved))]
    return {"lift": 0, "shorten": {}, **pose, "head": head, "neck": pose.get("neck", head), "props": props}


def timeline(fig):
    """Pose for every frame: ease between keys, hold at each, loop back."""
    keys = [complete(pose, fig) for pose in fig["poses"]]
    frames = []
    loop = keys + [keys[0]] if len(keys) > 1 else keys
    for i in range(len(loop) - 1):
        frames += [keys[i]] * HOLD_FRAMES
        for f in range(FRAMES_PER_MOVE):
            t = (1 - math.cos(math.pi * (f + 1) / (FRAMES_PER_MOVE + 1))) / 2
            frames.append(lerp_pose(loop[i], loop[i + 1], t))
    return frames or keys




# Half-widths (front, back) along each segment, metres. t may run past 0..1.
PROFILE = {
    "torso": [(-0.14, 0.085, 0.10), (-0.02, 0.11, 0.13), (0.12, 0.105, 0.11), (0.3, 0.098, 0.088),
              (0.5, 0.108, 0.09), (0.72, 0.13, 0.1), (0.9, 0.115, 0.1), (1.02, 0.07, 0.085)],
    "neck": [(-0.1, 0.05, 0.05), (1.0, 0.045, 0.045)],
    "upperArm": [(-0.05, 0.062, 0.062), (0.15, 0.066, 0.063), (0.5, 0.056, 0.055), (0.85, 0.042, 0.044), (1.02, 0.039, 0.04)],
    "forearm": [(-0.02, 0.04, 0.04), (0.22, 0.05, 0.048), (0.6, 0.038, 0.037), (1.0, 0.028, 0.028)],
    "hand": [(-0.05, 0.028, 0.028), (0.4, 0.036, 0.03), (0.85, 0.028, 0.022), (1.0, 0.018, 0.016)],
    "thigh": [(-0.08, 0.09, 0.097), (0.25, 0.092, 0.08), (0.7, 0.074, 0.064), (1.0, 0.055, 0.056)],
    "shin": [(-0.02, 0.05, 0.056), (0.28, 0.05, 0.07), (0.62, 0.04, 0.048), (1.0, 0.032, 0.034)],
    "foot": [(-0.42, 0.03, 0.06), (-0.2, 0.045, 0.085), (0.15, 0.04, 0.078), (0.6, 0.03, 0.068), (1.05, 0.02, 0.058)],
}
FRONT_TORSO = [(-0.13, 0.12, 0.12), (-0.04, 0.155, 0.155), (0.08, 0.158, 0.158), (0.3, 0.135, 0.135), (0.55, 0.15, 0.15),
               (0.82, 0.19, 0.19), (0.97, 0.17, 0.17), (1.05, 0.08, 0.08)]

ALIAS = {"shoulders": "delts", "deltoids": "delts", "rear deltoids": "delts", "quadriceps": "quads",
         "chest": "pectorals", "upper chest": "pectorals", "core": "abs", "abdominals": "abs",
         "obliques": "abs", "lower back": "spine", "rhomboids": "upper back", "trapezius": "traps",
         "upper trapezius": "traps", "latissimus dorsi": "lats", "brachialis": "biceps",
         "soleus": "calves", "wrists": "forearms", "grip muscles": "forearms", "wrist flexors": "forearms",
         "wrist extensors": "forearms", "back": "upper back"}


def smooth(prof, n=28):
    """Resample a profile with smoothstep between keys."""
    out = []
    ts = [p[0] for p in prof]
    for i in range(n + 1):
        t = ts[0] + (ts[-1] - ts[0]) * i / n
        k = max(0, min(len(prof) - 2, next((j for j in range(len(prof) - 1) if prof[j + 1][0] >= t), len(prof) - 2)))
        a, b = prof[k], prof[k + 1]
        s = (t - a[0]) / (b[0] - a[0]) if b[0] != a[0] else 0
        s = s * s * (3 - 2 * s)
        out.append((t, a[1] + (b[1] - a[1]) * s, a[2] + (b[2] - a[2]) * s))
    return out


def axis(a, b, torso=False):
    vx, vy = b[0] - a[0], b[1] - a[1]
    L = math.hypot(vx, vy) or 1e-6
    ux, uy = vx / L, vy / L
    n = (uy, -ux) if torso else (-uy, ux)
    return ux, uy, L, n


def body_poly(a, b, prof, torso=False, sym=False):
    ux, uy, L, (nx, ny) = axis(a, b, torso)
    pts = smooth(prof)
    if sym:
        pts = [(t, (f + k) / 2, (f + k) / 2) for t, f, k in pts]
    front = [(a[0] + ux * L * t + nx * f, a[1] + uy * L * t + ny * f) for t, f, _ in pts]
    back = [(a[0] + ux * L * t - nx * k, a[1] + uy * L * t - ny * k) for t, _, k in pts]
    # Round caps.
    def cap(t, f, k, sgn):
        cx = a[0] + ux * L * t + nx * (f - k) / 2
        cy = a[1] + uy * L * t + ny * (f - k) / 2
        r = (f + k) / 2
        out = []
        for i in range(1, 8):
            th = math.pi * i / 8
            c, s = math.cos(th), math.sin(th)
            # From front (+n) round through +-u to back (-n).
            out.append((cx + nx * r * c + sgn * ux * r * s * 0.8, cy + ny * r * c + sgn * uy * r * s * 0.8))
        return out
    t1, f1, k1 = pts[-1]
    t0, f0, k0 = pts[0]
    return front + cap(t1, f1, k1, 1) + back[::-1] + cap(t0, f0, k0, -1)[::-1]


def ellipse_poly(c, rx, ry, angle, n=40):
    ca, sa = math.cos(math.radians(angle)), math.sin(math.radians(angle))
    out = []
    for i in range(n):
        th = 2 * math.pi * i / n
        x, y = rx * math.cos(th), ry * math.sin(th)
        out.append((c[0] + x * ca - y * sa, c[1] + x * sa + y * ca))
    return out


def lens(a, b, prof, t0, t1, face, depth=0.9, torso=False, offset=0.0, width=None, sym=False):
    """A muscle-shaped lens hugging one face of a segment (face 0 = centred)."""
    ux, uy, L, (nx, ny) = axis(a, b, torso)
    sm = smooth(prof, 60)
    def r_at(t, which):
        best = min(sm, key=lambda p: abs(p[0] - t))
        if sym:
            return (best[1] + best[2]) / 2
        return best[1] if which > 0 else best[2]
    outer, inner = [], []
    n = 18
    for i in range(n + 1):
        s = i / n
        t = t0 + (t1 - t0) * s
        bulge = math.sin(math.pi * s) ** 0.7
        px, py = a[0] + ux * L * t, a[1] + uy * L * t
        if face == 0:
            r = (width if width else r_at(t, 1) * 0.75) * bulge
            cx, cy = px + nx * offset, py + ny * offset
            outer.append((cx + nx * r, cy + ny * r))
            inner.append((cx - nx * r, cy - ny * r))
        else:
            r = r_at(t, face) * 0.96
            o = (px + nx * face * r, py + ny * face * r)
            ri = r * (1 - depth * bulge)
            outer.append(o)
            inner.append((px + nx * face * ri, py + ny * face * ri))
    return outer + inner[::-1]


_BG = {}


class Frame:
    """One supersampled frame; shapes are drawn in world metres (y up)."""

    def __init__(self, box):
        (x0, y0), (x1, y1) = box
        margin = 0.04
        span = max(x1 - x0, y1 - y0) * (1 + 2 * margin)
        self.k = W / span
        self.cx, self.cy = (x0 + x1) / 2, (y0 + y1) / 2
        key = box
        if key not in _BG:
            _BG.clear()
            _BG[key] = self.background()
        self.img = _BG[key].copy()
        self.body_alpha = np.zeros((W, W), np.float32)

    def pt(self, p):
        return ((p[0] - self.cx) * self.k + W / 2, W / 2 - (p[1] - self.cy) * self.k)

    def background(self):
        """Vertical gradient, a soft spotlight and the floor, cached per framing."""
        st = STYLE
        top, bot = np.array(st["bg_top"], np.float32), np.array(st["bg_bottom"], np.float32)
        ys = np.linspace(0, 1, W, dtype=np.float32)[:, None, None]
        img = top * (1 - ys) + bot * ys
        img = np.broadcast_to(img, (W, W, 3)).copy()
        yy, xx = np.mgrid[0:W, 0:W].astype(np.float32) / W
        d = np.sqrt((xx - 0.5) ** 2 + (yy - 0.42) ** 2 * 1.4)
        glow = np.clip(1 - d / 0.6, 0, 1) ** 2
        img += glow[..., None] * 14
        fy = self.pt((0, 0))[1]
        floor = np.array(st["floor"], np.float32)
        rows = np.arange(W, dtype=np.float32)[:, None]
        f = np.clip((rows - fy) / (0.012 * self.k) + 0.5, 0, 1)
        fade = np.clip(1 - (rows - fy) / (W * 0.35), 0.55, 1)
        img = img * (1 - f[..., None]) + (floor * fade[..., None] + img * (1 - fade[..., None])) * f[..., None]
        line = np.exp(-((rows - fy) / (0.006 * self.k)) ** 2)
        img -= line[..., None] * 14
        return np.clip(img, 0, 255).astype(np.float32)

    def region(self, polys, pad):
        xs = [self.pt(q)[0] for p in polys for q in p]
        ys = [self.pt(q)[1] for p in polys for q in p]
        x0, y0 = max(0, int(min(xs)) - pad), max(0, int(min(ys)) - pad)
        x1, y1 = min(W, int(max(xs)) + pad + 1), min(W, int(max(ys)) + pad + 1)
        if x1 <= x0 or y1 <= y0:
            return None
        return x0, y0, x1, y1

    def local(self, poly, x0, y0):
        return [(self.pt(q)[0] - x0, self.pt(q)[1] - y0) for q in poly]

    def flat(self, polys, rgb, alpha=1.0):
        reg = self.region(polys, 2)
        if not reg:
            return
        x0, y0, x1, y1 = reg
        m = Image.new("L", (x1 - x0, y1 - y0), 0)
        d = ImageDraw.Draw(m)
        for p in polys:
            d.polygon(self.local(p, x0, y0), fill=255)
        a = np.asarray(m, np.float32)[..., None] / 255 * alpha
        sub = self.img[y0:y1, x0:x1]
        sub *= 1 - a
        sub += np.array(rgb, np.float32) * a

    def blur(self, arr, r):
        return np.asarray(Image.fromarray(arr).filter(ImageFilter.GaussianBlur(r)), np.float32) / 255

    def shaded(self, parts, size_m=0.035):
        """Shade [(polygon, rgb)] as one rounded object lit from the top left.

        size_m is roughly the object's half-thickness in metres; it sets how far
        the shading reaches in from the edge.
        """
        st = STYLE
        polys = [p for p, _ in parts]
        pad = int(0.08 * self.k)
        reg = self.region(polys, pad)
        if not reg:
            return
        x0, y0, x1, y1 = reg
        size = (x1 - x0, y1 - y0)
        mc = Image.new("L", size, 0)
        col = Image.new("RGB", size, (0, 0, 0))
        dm, dc = ImageDraw.Draw(mc), ImageDraw.Draw(col)
        mm_img = Image.new("L", size, 0)
        dmm = ImageDraw.Draw(mm_img)
        for poly, rgb in parts:
            pp = self.local(poly, x0, y0)
            dm.polygon(pp, fill=255)
            dc.polygon(pp, fill=rgb)
            if rgb == st["muscle"]:
                dmm.polygon(pp, fill=255)
        mm = np.asarray(mm_img.filter(ImageFilter.GaussianBlur(0.004 * self.k)), np.float32) / 255
        r = size_m * self.k
        inner = np.asarray(mc.filter(ImageFilter.GaussianBlur(r)), np.float32) / 255
        lit_src = Image.new("L", size, 0)
        lit_src.paste(mc, (round(-0.63 * size_m * self.k), round(-0.86 * size_m * self.k)))
        lit = np.asarray(lit_src.filter(ImageFilter.GaussianBlur(r * 0.9)), np.float32) / 255
        m = np.asarray(mc, np.float32) / 255
        roundness = np.clip((inner - 0.35) / 0.55, 0, 1)
        diffuse = (1 - st["shadow_mul"]) + st["shadow_mul"] * (0.45 * roundness + 0.55 * lit)
        spec = np.clip((lit * roundness - 0.72) / 0.28, 0, 1) ** 2 * st["spec"]
        c = np.asarray(col.filter(ImageFilter.GaussianBlur(0.004 * self.k)), np.float32)
        # Muscles keep their colour: less shading, little shine.
        diffuse = diffuse * (1 - mm * 0.5) + (0.8 + 0.25 * diffuse) * mm * 0.5
        spec = spec * (1 - mm * 0.75)
        shaded = c * diffuse[..., None] + 255 * spec[..., None]
        # A darker rim keeps overlapping parts readable.
        edge = np.clip((0.5 - inner) / 0.5, 0, 1) * m
        edge = np.clip(edge * 1.6, 0, 1) ** 1.5
        shaded = shaded * (1 - edge[..., None] * 0.25) + np.array(st["outline"], np.float32) * edge[..., None] * 0.25
        sub = self.img[y0:y1, x0:x1]
        body = self.body_alpha[y0:y1, x0:x1]
        if body.any():  # cast a soft shadow on the body behind
            sh_src = Image.new("L", size, 0)
            sh_src.paste(mc, (round(0.025 * self.k), round(0.03 * self.k)))
            cast = self.blur(np.asarray(sh_src), 0.025 * self.k) * body
            sub *= 1 - cast[..., None] * 0.28
        a = m[..., None]
        sub *= 1 - a
        sub += np.clip(shaded, 0, 255) * a
        np.maximum(body, m, out=body)

    def composite(self, rgb, alpha):
        a = alpha[..., None]
        self.img *= 1 - a
        self.img += rgb * a

    def done(self):
        img = Image.fromarray(np.clip(self.img, 0, 255).astype(np.uint8))
        return img.resize((SIZE, SIZE), Image.LANCZOS)


# ---------------------------------------------------------------- muscles

def muscle_shapes(name, j, side, view):
    """World polygons for a muscle on one side."""
    P = PROFILE
    front = view == "front"
    s = lambda a, b: (j[side + a], j[side + b])  # noqa: E731
    out = []
    if name == "biceps":
        out.append(lens(*s("Shoulder", "Elbow"), P["upperArm"], 0.25, 0.92, 0 if front else 1, 0.8, width=0.036 if front else None))
    elif name == "triceps":
        out.append(lens(*s("Shoulder", "Elbow"), P["upperArm"], 0.15, 0.9, 0 if front else -1, 0.8, width=0.03 if front else None, offset=-0.02 if front else 0))
    elif name == "forearms":
        out.append(lens(*s("Elbow", "Wrist"), P["forearm"], 0.0, 0.75, 0, width=0.04))
    elif name == "delts":
        out.append(lens(*s("Shoulder", "Elbow"), P["upperArm"], -0.12, 0.42, 0, width=0.062))
    elif name == "quads":
        out.append(lens(*s("Hip", "Knee"), P["thigh"], 0.08, 0.95, 0 if front else 1, 0.85, width=0.07 if front else None))
    elif name == "hamstrings":
        out.append(lens(*s("Hip", "Knee"), P["thigh"], 0.1, 0.95, -1 if not front else 0, 0.8, width=0.05 if front else None))
    elif name == "adductors":
        out.append(lens(*s("Hip", "Knee"), P["thigh"], 0.0, 0.6, 0, width=0.045, offset=(-0.045 if front else 0)))
    elif name == "abductors":
        out.append(lens(*s("Hip", "Knee"), P["thigh"], -0.1, 0.45, 0, width=0.05, offset=(0.04 if front else 0)))
    elif name == "glutes" and not front:
        out.append(lens(*s("Hip", "Knee"), P["thigh"], -0.12, 0.3, -1, 0.85))
    elif name == "calves":
        out.append(lens(*s("Knee", "Ankle"), P["shin"], 0.05, 0.7, -1 if not front else 0, 0.8, width=0.045 if front else None))
    return out


def torso_muscles(name, j, view):
    hip, sh = j["hip"], j["shoulder"]
    P = PROFILE["torso"]
    if view == "front":
        F = FRONT_TORSO
        if name == "pectorals":
            return [lens(hip, sh, F, 0.66, 0.95, 0, torso=True, offset=o, width=0.07) for o in (-0.075, 0.075)]
        if name == "abs":
            ux, uy, L, (nx, ny) = axis(hip, sh, True)
            out = []
            for t in (0.2, 0.38, 0.56):
                for o in (-0.035, 0.035):
                    c = (hip[0] + ux * L * t + nx * o, hip[1] + uy * L * t + ny * o)
                    out.append(rrect(c, 0.085, 0.06, math.degrees(math.atan2(ux, uy)), 0.022))
            return out
        if name in ("lats", "serratus anterior"):
            a, b = (0.45, 0.88) if name == "lats" else (0.5, 0.72)
            return [lens(hip, sh, F, a, b, 0, torso=True, offset=o, width=0.035) for o in (-0.14, 0.14)]
        if name in ("traps", "levator scapulae"):
            return [lens(hip, sh, F, 0.9, 1.12, 0, torso=True, width=0.12)]
        if name == "glutes":
            return [lens(hip, sh, F, -0.12, 0.12, 0, torso=True, offset=o, width=0.04) for o in (-0.13, 0.13)]
        if name in ("upper back", "spine"):
            return [lens(hip, sh, F, 0.5, 0.92, 0, torso=True, offset=o, width=0.03) for o in (-0.15, 0.15)]
        return []
    table = {"pectorals": (0.6, 0.95, 1), "serratus anterior": (0.5, 0.72, 1), "abs": (0.05, 0.62, 1),
             "lats": (0.42, 0.9, -1), "upper back": (0.65, 1.0, -1), "traps": (0.85, 1.08, -1),
             "spine": (0.0, 0.5, -1), "glutes": (-0.16, 0.16, -1), "levator scapulae": (0.92, 1.1, -1)}
    if name not in table:
        return []
    a, b, face = table[name]
    return [lens(hip, sh, P, a, b, face, 0.75, torso=True)]


HELD_DEFAULT = {"barbell": ["nearHand"], "bar": ["nearHand"], "medicineBall": ["nearHand"],
                "plate": ["nearHand"], "trapBar": ["nearHand"], "keg": ["nearHand"],
                "sledgehammer": ["nearHand"]}
FIXED = ("bench", "box", "ball", "bosu", "roller", "pullupBar", "parallelBars", "rails", "pad", "wall", "sled",
         "tire")
CONNECTORS = ("cable", "band", "lever", "rope", "rings", "landmine")


def where(j, value):
    """A prop position is a world point [x, y] or a joint name it follows."""
    return j[value] if isinstance(value, str) else tuple(value)


def equipment(fig, pose):
    """The figure's equipment with this pose's `props` overrides applied (by index)."""
    items = [dict(item) for item in fig.get("equipment", [])]
    for item, override in zip(items, pose.get("props", [])):
        item.update(override or {})
    return items



# ---------------------------------------------------------------- equipment

IRON = (40, 43, 52)
STEEL = (170, 176, 190)
STEEL_DK = (110, 116, 130)
PAD = (58, 62, 76)
FRAME_C = (150, 156, 170)
BAND = (255, 138, 61)
WOOD = (196, 154, 112)
RUBBER = (46, 48, 56)


def draw_plate_face(fr, c, r):
    """A weight plate seen face on, with rim, ring and steel hub."""
    fr.shaded([(ellipse_poly(c, r, r, 0, 64), IRON)])
    fr.flat([ellipse_poly(c, r * 0.78, r * 0.78, 0, 64)], (52, 56, 68))
    fr.flat([ellipse_poly(c, r * 0.68, r * 0.68, 0, 64)], (44, 47, 57))
    fr.flat([ellipse_poly((c[0] - r * 0.02, c[1] + r * 0.02), r * 0.24, r * 0.24, 0)], STEEL)
    fr.flat([ellipse_poly(c, r * 0.12, r * 0.12, 0)], STEEL_DK)
    # Highlight arc.
    m = Image.new("L", (W, W), 0)
    d = ImageDraw.Draw(m)
    p0, p1 = fr.pt((c[0] - r * 0.92, c[1] + r * 0.92)), fr.pt((c[0] + r * 0.92, c[1] - r * 0.92))
    d.arc([p0, p1], 200, 280, fill=255, width=max(2, round(0.012 * fr.k)))
    a = np.asarray(m.filter(ImageFilter.GaussianBlur(0.004 * fr.k)), np.float32) / 255 * 0.5
    fr.composite(np.array((200, 206, 220), np.float32), a)


def rrect(c, w, h, angle, r=None, n=6):
    """Rounded rectangle polygon, long axis along `angle`."""
    dx, dy = unit(angle)
    nx, ny = dy, -dx
    r = min(r if r is not None else h * 0.3, w / 2, h / 2)
    pts = []
    for (sx, sy, a0) in ((1, 1, 0), (-1, 1, 90), (-1, -1, 180), (1, -1, 270)):
        ccx, ccy = sx * (w / 2 - r), sy * (h / 2 - r)
        for i in range(n + 1):
            th = math.radians(a0 + 90 * i / n)
            lx, ly = ccx + r * math.cos(th), ccy + r * math.sin(th)
            pts.append((c[0] + dx * lx + nx * ly, c[1] + dy * lx + ny * ly))
    return pts


def annulus(c, r, w, n=28):
    """A ring as short overlapping bars (polygons can't have holes)."""
    pts = [(c[0] + r * math.cos(2 * math.pi * i / n), c[1] + r * math.sin(2 * math.pi * i / n)) for i in range(n + 1)]
    return [bar_poly(pts[i], pts[i + 1], w) for i in range(n)] + [ellipse_poly(p, w / 2, w / 2, 0, 12) for p in pts[:-1]]


def bar_poly(a, b, w):
    ux, uy, L, (nx, ny) = axis(a, b)
    h = w / 2
    return [(a[0] + nx * h, a[1] + ny * h), (b[0] + nx * h, b[1] + ny * h),
            (b[0] - nx * h, b[1] - ny * h), (a[0] - nx * h, a[1] - ny * h)]


def draw_fixed(fr, j, item):
    kind = item["type"]
    at = where(j, item["at"]) if "at" in item else (0, 0)
    x, y = at
    if kind == "bench":
        length = item.get("length", 1.2)
        angle = item.get("angle", 90)
        dx, dy = unit(angle)
        legs = []
        for t in (-0.36, 0.36):
            px, py = x + dx * length * t, y + dy * length * t
            if py > 0.05:
                legs.append(bar_poly((px, py), (px, 0.02), 0.05))
                legs.append(rrect((px, 0.015), 0.22, 0.03, 90, 0.012))
        if legs:
            fr.shaded([(p, FRAME_C) for p in legs])
        fr.shaded([(rrect((x, y), length, 0.1, angle, 0.04), PAD)])
        # Frame rail under the pad.
        nx, ny = dy, -dx
        fr.flat([rrect((x + nx * 0.06, y + ny * 0.06), length * 0.85, 0.03, angle, 0.01)], STEEL_DK)
    elif kind == "pullupBar":
        fr.shaded([(bar_poly((x - 0.5, y), (x + 0.5, y), 0.045), STEEL)])
        fr.shaded([(bar_poly((px, y - 0.03), (px, y + 0.4), 0.06), FRAME_C) for px in (x - 0.5, x + 0.5)])
    elif kind == "parallelBars":
        fr.shaded([(bar_poly((px, y), (px, 0), 0.05), FRAME_C) for px in (x - 0.25, x + 0.25)])
        fr.shaded([(rrect((x, y), 0.65, 0.055, 90, 0.025), STEEL)])
    elif kind == "rails":
        fr.shaded([(bar_poly((x, 0), (x, item.get("h", 2.2)), 0.05), FRAME_C)])
    elif kind == "wall":
        h = item.get("h", 2.3)
        fr.flat([[(x - 0.04, 0), (x + 0.04, 0), (x + 0.04, h), (x - 0.04, h)]], (200, 204, 214))
    elif kind == "ball":
        r = item.get("r", 0.33)
        fr.shaded([(ellipse_poly(at, r, r, 0, 64), (96, 140, 220))], r * 0.45)
    elif kind == "bosu":
        r = item.get("r", 0.3)
        poly = [(x + r * math.cos(math.pi * i / 32), y + r * 0.85 * math.sin(math.pi * i / 32)) for i in range(33)]
        fr.shaded([(poly, (96, 140, 220))], r * 0.4)
        fr.flat([rrect((x, y + 0.01), 2 * r, 0.03, 90, 0.01)], IRON)
    elif kind == "roller":
        r = item.get("r", 0.08)
        fr.shaded([(ellipse_poly(at, r, r, 0), BAND)])
    elif kind in ("box", "sled"):
        w, h = item.get("w", 0.5), item.get("h", 0.45)
        color = (196, 154, 112) if kind == "box" else STEEL_DK
        fr.shaded([(rrect((x, y + h / 2), w, h, 90, 0.025), color)])
        if kind == "box":
            fr.flat([ellipse_poly((x, y + h * 0.6), w * 0.18, h * 0.08, 0)], (150, 112, 78))
    elif kind == "tire":
        # A truck tyre lying on its side, seen edge on: tread band and sidewall.
        w, h, angle = item.get("w", 1.25), item.get("h", 0.22), item.get("angle", 90)
        fr.shaded([(rrect(at, w, h, angle, h * 0.45), RUBBER)], h * 0.3)
        dx, dy = unit(angle)
        nx, ny = dy, -dx
        for t in range(-5, 6):
            c = (at[0] + dx * w * 0.08 * t, at[1] + dy * w * 0.08 * t)
            fr.flat([rrect((c[0] + nx * h * 0.38, c[1] + ny * h * 0.38), 0.025, h * 0.12, angle + 90, 0.01),
                     rrect((c[0] - nx * h * 0.38, c[1] - ny * h * 0.38), 0.025, h * 0.12, angle + 90, 0.01)], (26, 27, 32))
        fr.flat([rrect(at, w * 0.82, h * 0.1, angle, h * 0.05)], (70, 73, 84))
    elif kind == "pad":
        fr.shaded([(rrect(at, item.get("w", 0.35), item.get("h", 0.12), item.get("angle", 90)), PAD)])


def draw_connector(fr, j, item):
    kind = item["type"]
    start = where(j, item["from"])
    for name in item.get("on", ["nearHand"]):
        end = j[name]
        if kind == "lever":
            fr.shaded([(bar_poly(start, end, 0.06), STEEL_DK)])
            fr.shaded([(ellipse_poly(end, 0.05, 0.05, 0), IRON)])
        elif kind == "band":
            fr.flat([bar_poly(start, end, 0.025)], BAND)
        elif kind == "rings":
            # Strap down to a gymnastics ring held at the joint.
            top = (end[0], end[1] + 0.09)
            fr.flat([bar_poly(start, top, 0.022)], (52, 56, 68))
            fr.shaded([(p, WOOD) for p in annulus((end[0], end[1] + 0.02), 0.085, 0.022)], 0.012)
        elif kind == "landmine":
            # A barbell pivoting in a floor sleeve; the loaded end is just past the hands.
            ux, uy, length, _ = axis(start, end)
            tip = (end[0] + ux * 0.22, end[1] + uy * 0.22)
            fr.shaded([(rrect((start[0], 0.04), 0.2, 0.08, 90, 0.02), IRON)])
            fr.shaded([(bar_poly(start, tip, 0.032), STEEL)], 0.02)
            draw_plate_face(fr, (end[0] + ux * 0.14, end[1] + uy * 0.14), item.get("r", 0.16))
        else:
            fr.flat([bar_poly(start, end, 0.012)], (60, 64, 76))
            fr.shaded([(rrect(end, 0.11, 0.035, 90 + 0, 0.015), IRON)])
    if kind in ("cable", "rope"):
        fr.shaded([(ellipse_poly(start, 0.065, 0.065, 0), STEEL_DK)])
        fr.flat([ellipse_poly(start, 0.025, 0.025, 0)], IRON)
    if kind == "lever":
        fr.shaded([(ellipse_poly(start, 0.06, 0.06, 0), IRON)])


def draw_held(fr, j, item, kind, name, view):
    w = j[name]
    if kind in ("barbell", "bar") and view == "front":
        mid = ((j["nearHand"][0] + j["farHand"][0]) / 2, (j["nearHand"][1] + j["farHand"][1]) / 2)
        half = item.get("half", 0.75 if kind == "barbell" else 0.6)
        fr.shaded([(rrect(mid, 2 * half, 0.032, 90, 0.016), STEEL)])
        if kind == "barbell":
            parts = []
            for sx in (-1, 1):
                parts.append((rrect((mid[0] + sx * (half - 0.04), mid[1]), 0.12, 0.05, 90, 0.01), STEEL))
                for k, (off, h) in enumerate(((0.1, 0.44), (0.15, 0.36), (0.19, 0.26))):
                    parts.append((rrect((mid[0] + sx * (half - off), mid[1]), 0.045, h, 90, 0.015), IRON))
                parts.append((rrect((mid[0] + sx * (half - 0.225), mid[1]), 0.025, 0.08, 90, 0.008), STEEL_DK))
            for p in parts:
                fr.shaded([p])
    elif kind == "barbell":
        draw_plate_face(fr, w, item.get("r", 0.21))
    elif kind == "bar":
        fr.shaded([(ellipse_poly(w, 0.04, 0.04, 0), STEEL)])
    elif kind == "trapBar":
        if view == "front":
            mid = ((j["nearHand"][0] + j["farHand"][0]) / 2, (j["nearHand"][1] + j["farHand"][1]) / 2)
            fr.shaded([(rrect(mid, 1.3, 0.032, 90, 0.016), STEEL)])
            for sx in (-1, 1):
                fr.shaded([(rrect((mid[0] + sx * 0.33, mid[1] + 0.02), 0.06, 0.14, 90, 0.02), STEEL_DK)])
                fr.shaded([(rrect((mid[0] + sx * 0.52, mid[1]), 0.05, 0.4, 90, 0.015), IRON)])
        else:
            # The hexagonal frame runs front to back past the hands; plates end on.
            fr.shaded([(rrect((w[0], w[1] + 0.01), 0.62, 0.035, 90, 0.015), STEEL_DK)], 0.015)
            draw_plate_face(fr, w, item.get("r", 0.2))
    elif kind == "keg":
        c = (w[0], w[1] - 0.04)
        fr.shaded([(rrect(c, 0.4, 0.3, 0, 0.11), STEEL)], 0.07)
        for y in (0.12, -0.12):
            fr.flat([rrect((c[0], c[1] + y), 0.3, 0.025, 90, 0.01)], STEEL_DK)
    elif kind == "sledgehammer":
        # Handle along the hand, the head at its far end.
        wrist = j[name.replace("Hand", "Wrist")]
        ux, uy, _, _ = axis(wrist, w)
        length = item.get("length", 0.75)
        head = (w[0] + ux * length, w[1] + uy * length)
        fr.shaded([(bar_poly((w[0] - ux * 0.08, w[1] - uy * 0.08), head, 0.035), WOOD)], 0.015)
        fr.shaded([(rrect(head, 0.24, 0.1, math.degrees(math.atan2(-uy, ux)), 0.02), IRON)], 0.04)
    elif kind == "dumbbell":
        if view == "front" and "axis" in item:
            a = item["axis"]
            dx, dy = unit(a)
            fr.shaded([(rrect(w, 0.16, 0.035, a, 0.015), STEEL)])
            for s in (-1, 1):
                fr.shaded([(rrect((w[0] + dx * s * 0.1, w[1] + dy * s * 0.1), 0.07, 0.13, a, 0.02), IRON)])
        else:
            hexa = [(w[0] + 0.085 * math.cos(math.radians(30 + 60 * i)), w[1] + 0.085 * math.sin(math.radians(30 + 60 * i))) for i in range(6)]
            fr.shaded([(hexa, IRON)])
            fr.flat([ellipse_poly(w, 0.035, 0.035, 0)], STEEL)
    elif kind == "kettlebell":
        c = (w[0], w[1] - 0.15)
        fr.shaded([(bar_poly((w[0] - 0.05, w[1] - 0.06), (w[0] - 0.05, w[1] + 0.01), 0.03), IRON),
                   (bar_poly((w[0] + 0.05, w[1] - 0.06), (w[0] + 0.05, w[1] + 0.01), 0.03), IRON),
                   (rrect((w[0], w[1] + 0.01), 0.13, 0.03, 90, 0.014), IRON),
                   (ellipse_poly(c, 0.11, 0.105, 0, 48), IRON)])
    elif kind == "plate":
        draw_plate_face(fr, w, item.get("r", 0.16))
    elif kind == "medicineBall":
        fr.shaded([(ellipse_poly(w, 0.13, 0.13, 0, 48), (92, 80, 72))])
    elif kind == "handle":
        fr.shaded([(rrect(w, 0.11, 0.035, 90, 0.015), IRON)])
    elif kind == "hanging":
        low = (w[0], w[1] - item.get("chain", 0.3))
        fr.flat([bar_poly(w, low, 0.014)], STEEL_DK)
        draw_plate_face(fr, low, item.get("r", 0.1))


def draw_equipment(fr, j, fig, layer, view):
    for item in fig.get("equipment", []):
        kind = item["type"]
        if kind in FIXED:
            if layer == "back":
                draw_fixed(fr, j, item)
            continue
        if kind in CONNECTORS:
            if layer == "back":
                draw_connector(fr, j, item)
            continue
        joints = item.get("on", HELD_DEFAULT.get(kind, ["nearHand", "farHand"]))
        for name in joints:
            far = name.startswith("far")
            if (layer == "far") != far or layer == "back":
                continue
            draw_held(fr, j, item, kind, name, view)


# ---------------------------------------------------------------- figure

def contact_shadows(fr, j, fig):
    pts = [p for p in j.values() if p[1] < 0.35]
    for item in fig.get("equipment", []):
        if item["type"] in ("bench", "box", "sled", "ball", "bosu", "parallelBars", "rails", "wall", "pullupBar") and "at" in item:
            x, y = where(j, item["at"])
            if item["type"] == "bench":
                L = item.get("length", 1.2)
                pts += [(x + t * L * 0.04, 0.0) for t in range(-10, 11)]
            elif item["type"] in ("box", "sled"):
                ww = item.get("w", 0.5)
                pts += [(x + t * ww / 20, 0.0) for t in range(-10, 11)]
            elif item["type"] in ("ball", "bosu"):
                pts += [(x, 0.0)]
    m = Image.new("L", (W, W), 0)
    d = ImageDraw.Draw(m)
    for (x, y) in pts:
        h = max(0.0, y)
        rx = 0.09 + h * 0.4
        ry = 0.02 + h * 0.05
        strength = int(255 * max(0.0, 1 - h / 0.35) * 0.5)
        a, b = fr.pt((x - rx, ry)), fr.pt((x + rx, -ry))
        d.ellipse([a[0], a[1], b[0], b[1]], fill=strength)
    m = m.filter(ImageFilter.GaussianBlur(0.03 * fr.k))
    a = np.asarray(m, np.float32) / 255
    fr.img *= 1 - a[..., None] * 0.35


def limb_parts(j, side, view, color):
    """Leg and arm outlines for one side."""
    sym = view == "front"
    P = PROFILE
    if view == "front":
        foot = body_poly(j[side + "Ankle"], j[side + "Toe"], [(-0.1, 0.04, 0.04), (1.1, 0.05, 0.05)])
    else:
        foot = body_poly(j[side + "Ankle"], j[side + "Toe"], P["foot"])
    leg = [(body_poly(j[side + "Hip"], j[side + "Knee"], P["thigh"], sym=sym), color),
           (body_poly(j[side + "Knee"], j[side + "Ankle"], P["shin"], sym=sym), color),
           (foot, color)]
    arm = [(body_poly(j[side + "Shoulder"], j[side + "Elbow"], P["upperArm"], sym=sym), color),
           (body_poly(j[side + "Elbow"], j[side + "Wrist"], P["forearm"], sym=sym), color),
           (body_poly(j[side + "Wrist"], j[side + "Hand"], P["hand"], sym=sym), color)]
    return leg, arm


LEG_M = {"glutes", "quads", "hamstrings", "adductors", "abductors", "calves"}
ARM_M = {"biceps", "triceps", "forearms", "delts"}


def with_muscles(parts, side, wanted, j, view, muscles, secondary, faded):
    """Add the highlighted muscles that sit on this limb to its parts."""
    out = list(parts)
    for names, color in ((secondary, STYLE["muscle2"]), (muscles, STYLE["muscle"])):
        if faded:
            color = tuple(int(v * 0.55 + b * 0.45) for v, b in zip(color, STYLE["body_far"]))
        for m in names:
            if m in wanted:
                out += [(poly, color) for poly in muscle_shapes(m, j, side, view)]
    return out


def head_shapes(j, view):
    c = j["head"]
    color = STYLE["body"]
    if view == "front":
        return [(ellipse_poly(c, 0.088, 0.112, 0, 48), color)]
    # Side: skull, jaw and nose towards the face.
    angle = math.degrees(math.atan2(c[0] - j["neckTop"][0], c[1] - j["neckTop"][1]))
    fx, fy = unit(angle + 90)
    ux, uy = unit(angle)
    skull = ellipse_poly((c[0] - fx * 0.005, c[1] - fy * 0.005), 0.108, 0.1, -angle, 48)
    jaw = ellipse_poly((c[0] + fx * 0.045 - ux * 0.045, c[1] + fy * 0.045 - uy * 0.045), 0.06, 0.055, -angle, 32)
    nose = ellipse_poly((c[0] + fx * 0.1, c[1] + fy * 0.1), 0.022, 0.03, -angle, 16)
    return [(skull, color), (jaw, color), (nose, color)]


def draw_figure(fr, j, fig, muscles, secondary, legs_in_front=False):
    """Back to front: floor shadows, fixed equipment, far limbs, torso, head, near limbs.

    Front view draws the legs behind the torso, unless the thighs point at the
    viewer (seated), and both arms in front of it.
    """
    view = fig.get("view", "side")
    front = view == "front"
    contact_shadows(fr, j, fig)
    draw_equipment(fr, j, fig, "back", view)
    far_color = STYLE["body"] if front else STYLE["body_far"]
    leg_f, arm_f = limb_parts(j, "far", view, far_color)
    leg_n, arm_n = limb_parts(j, "near", view, STYLE["body"])
    far_leg = with_muscles(leg_f, "far", LEG_M, j, view, muscles, secondary, not front)
    far_arm = with_muscles(arm_f, "far", ARM_M, j, view, muscles, secondary, not front)
    near_leg = with_muscles(leg_n, "near", LEG_M, j, view, muscles, secondary, False)
    near_arm = with_muscles(arm_n, "near", ARM_M, j, view, muscles, secondary, False)
    legs_late = front and legs_in_front
    if front:
        if not legs_late:
            fr.shaded(far_leg)
            fr.shaded(near_leg)
    else:
        fr.shaded(far_leg)
        fr.shaded(far_arm)
    draw_equipment(fr, j, fig, "far", view)
    hip, sh = j["hip"], j["shoulder"]
    parts = [(body_poly(hip, sh, FRONT_TORSO if front else PROFILE["torso"], torso=True), STYLE["body"]),
             (body_poly(sh, j["neckTop"], PROFILE["neck"]), STYLE["body"])]
    for names, color in ((secondary, STYLE["muscle2"]), (muscles, STYLE["muscle"])):
        for m in names:
            parts += [(poly, color) for poly in torso_muscles(m, j, view)]
    fr.shaded(parts, 0.085 if front else 0.06)
    fr.shaded(head_shapes(j, view), 0.05)
    if legs_late:
        fr.shaded(far_leg)
        fr.shaded(near_leg)
    if front:
        fr.shaded(far_arm)
    else:
        fr.shaded(near_leg)
    fr.shaded(near_arm)
    draw_equipment(fr, j, fig, "front", view)


def pose_joints(fig, pose):
    view = fig.get("view", "side")
    anchor = fig.get("anchor", ["nearAnkle", [0, 0.09]])
    joints = anchored(solve(pose, view), anchor)
    if "contact" in fig:
        joints = pivot_to_contact(joints, anchor[1], *fig["contact"])
    lift = pose.get("lift", 0)
    if lift:
        joints = {k: (x, y + lift) for k, (x, y) in joints.items()}
    return joints


def pivot_to_contact(joints, pivot, name, height):
    """Rotate the figure about the anchor until `name` sits at `height`.

    Lets a pose say "toes and hands on the floor" without solving the body
    angle by hand (push-ups, planks, bridges).
    """
    def rotated(deg):
        r = math.radians(deg)
        cs, sn = math.cos(r), math.sin(r)
        out = {}
        for k, (x, y) in joints.items():
            dx, dy = x - pivot[0], y - pivot[1]
            out[k] = (pivot[0] + dx * cs - dy * sn, pivot[1] + dx * sn + dy * cs)
        return out
    best = min((abs(rotated(d / 4)[name][1] - height), d / 4) for d in range(-360, 361))
    return rotated(best[1])


def bounds(fig, frames):
    xs, ys = [], []
    for pose in frames:
        j = pose_joints(fig, pose)
        for x, y in j.values():
            xs.append(x)
            ys.append(y)
        for item in equipment(fig, pose):
            for key in ("at", "from"):
                if key in item:
                    x, y = where(j, item[key])
                    xs.append(x)
                    ys.append(y)
            if item["type"] in ("tire", "pad") and "at" in item:
                # Long props reach well past their centre.
                x, y = where(j, item["at"])
                dx, dy = unit(item.get("angle", 90))
                half = item.get("w", 0.35) / 2
                xs += [x - dx * half, x + dx * half]
                ys += [y - dy * half, y + dy * half]
            if item["type"] == "sledgehammer":
                for name in item.get("on", ["nearHand"]):
                    ux, uy, _, _ = axis(j[name.replace("Hand", "Wrist")], j[name])
                    xs.append(j[name][0] + ux * item.get("length", 0.75))
                    ys.append(j[name][1] + uy * item.get("length", 0.75))
    pad = 0.15
    return (min(xs) - pad, min(min(ys) - pad, -0.12)), (max(xs) + pad, max(ys) + pad)


def problems(fig):
    """Cheap sanity checks an author should fix before looking at the frames."""
    out = []
    if len(fig.get("poses", [])) < 2:
        out.append("needs at least two poses")
    for i, pose in enumerate(fig.get("poses", [])):
        j = pose_joints(fig, pose)
        low = [k for k, (_, y) in j.items() if y < -0.04]
        if low:
            out.append(f"pose {i}: below the floor: {', '.join(sorted(low))}")
    return out


def load(path, seen=()):
    """Read a figure, merging in the figure it `extends` (path relative to ROOT)."""
    fig = json.loads(Path(path).read_text())
    base = fig.pop("extends", None)
    if base:
        if base in seen:
            raise ValueError(f"extends loop at {base}")
        merged = load(ROOT / base, (*seen, base))
        merged.update(fig)
        return merged
    return fig


def highlighted(fig):
    """Target muscles and the distinct secondary ones, by our muscle names."""
    muscles = [m for m in fig.get("muscles", []) if m in MUSCLES]
    secondary = []
    for m in fig.get("secondary", []):
        m = ALIAS.get(m, m)
        if m in MUSCLES and m not in muscles and m not in secondary:
            secondary.append(m)
    return muscles, secondary


def render(fig, only_keys=False):
    """Every animation frame, or just the key poses (fast, for review sheets)."""
    frames = timeline(fig)
    box = bounds(fig, frames)
    muscles, secondary = highlighted(fig)
    images = []
    for pose in fig["poses"] if only_keys else frames:
        fr = Frame(box)
        posed = {**fig, "equipment": equipment(fig, pose)}
        seated = pose.get("shorten", {}).get("thigh", 1) < 0.8
        draw_figure(fr, pose_joints(posed, pose), posed, muscles, secondary, seated)
        images.append(fr.done())
    return images


def save(images, path):
    images[0].save(path, save_all=True, append_images=images[1:], duration=round(1000 / FPS),
                   loop=0, quality=80, method=6)


def contact_sheet(entries, path, thumb=180):
    """One row per figure: every key pose left to right, labelled."""
    cols = max(len(frames) for _, frames in entries)
    img = Image.new("RGB", (cols * thumb, len(entries) * thumb), (255, 255, 255))
    d = ImageDraw.Draw(img)
    for r, (label, frames) in enumerate(entries):
        for k, im in enumerate(frames):
            img.paste(im.resize((thumb, thumb)), (k * thumb, r * thumb))
        d.text((4, r * thumb + 4), label, fill=(0, 0, 0))
        d.line([(0, r * thumb), (cols * thumb, r * thumb)], fill=(180, 180, 180))
    img.save(path)


def main(argv):
    """Render loose figure files (templates and samples) by path."""
    paths = [Path(a) for a in argv if not a.startswith("--")] or sorted((ROOT / "figures").glob("*.json"))
    out = ROOT / "out"
    out.mkdir(exist_ok=True)
    entries = []
    for path in paths:
        fig = load(path)
        for p in problems(fig):
            print(f"{path}: {p}")
        save(render(fig), out / f"{path.stem}.webp")
        entries.append((path.stem, render(fig, only_keys=True)))
    contact_sheet(entries, out / "sheet.png")
    print(f"rendered {len(entries)} figure(s) into {out}")


if __name__ == "__main__":
    main(sys.argv[1:])

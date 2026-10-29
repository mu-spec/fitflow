#!/usr/bin/env python3
"""Build app-specific slim illustrated-athlete demos from licensed source art.

The body-part PNGs come from extract_character.cjs and retain Dinh Bui Xuan's
original vector artwork. Movement key poses derive from locally authored rigs
or CC0 Open Exercise Figures. The upstream kinematics helper is MIT-0.
Output WebP assets are authored derivatives under the Lottie Simple License.
This is an authoring tool, not a runtime dependency. See README and NOTICE.
"""
from __future__ import annotations

import argparse
import importlib.util
import json
import math
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path
from functools import lru_cache

import numpy as np
from PIL import Image, ImageDraw, features
from slim_squat_art import slim_squat_frame

HERE = Path(__file__).resolve().parent
APP = HERE.parents[1]
OLD_RIGS = APP / 'tools' / 'open_exercise_figures'
RIGS = HERE / 'rigs'
OUTPUT = APP / 'assets' / 'animations' / 'illustrated_athletes'
SIZE = 480

# (source path prefix, rig names); two rigs are concatenated for alternating
# movements. Side-view sprites are not used as a pretend front-view figure.
ANIMATED = {
    'bird_dog': ('local', ('bird_dog_a', 'bird_dog_b')),
    'plank_reach': ('local', ('plank_reach_a', 'plank_reach_b')),
    'donkey_kick': ('local', ('donkey_kick',)),
    'good_morning': ('local', ('good_morning',)),
    'high_knees': ('local', ('high_knees',)),
    'hip_hinge': ('local', ('hip_hinge',)),
    'hip_hinge_single_leg': ('local', ('hip_hinge_single_leg',)),
    'lunge_reverse': ('stored', ('lunge_reverse', 'lunge_reverse_b')),
    'march_in_place': ('local', ('march_in_place',)),
    'mountain_climber_standing': ('local', ('mountain_climber_standing',)),
    'pushup_wall': ('local', ('pushup_wall',)),
    'row_bent_over_dumbbell': ('local', ('row_bent_over_dumbbell',)),
    'standing_knee_raise': ('local', ('standing_knee_raise',)),
    **{n: ('stored', (n,)) for n in (
        'dead_bug', 'bridge_glute', 'bridge_single_leg', 'squat_split_static',
        'calf_raise', 'reverse_crunch', 'mountain_climbers', 'bridge_march',
        'flutter_kicks', 'leg_raise', 'fast_feet', 'squat_goblet_kettlebell',
        'superman', 'squat_goblet_dumbbell', 'deadlift_kettlebell',
        'row_resistance_band', 'squat_split_bulgarian', 'dip_chair', 'butt_kicks',
        'row_towel', 'scapular_pullup')},
    'lunge_forward': ('stored', ('lunge_forward', 'lunge_forward_b')),
    'squat_knee_drive': ('stored', ('squat_knee_drive', 'squat_knee_drive_b')),
    'shoulder_tap': ('stored', ('shoulder_tap', 'shoulder_tap_b')),
}
STATIC = ('plank_forearm', 'plank_knee', 'wall_sit', 'hollow_hold',
          'single_leg_stand', 'hip_flexor_stretch', 'childs_pose',
          'hamstring_stretch_standing', 'dead_hang_pullup_bar')
FRAME_MS = {'high_knees': 40, 'march_in_place': 45,
            'mountain_climber_standing': 45, 'fast_feet': 45,
            'mountain_climbers': 45, 'butt_kicks': 45, 'squat_knee_drive': 50}

# Points in the source's 480x480 screenshot: proximal and distal joint centres.
# The exact silhouettes and colour are from the approved character. Limbs are
# translated/rotated/scaled between each pose's corresponding rig joints.
PARTS = {
    'torso': ((227, 220), (225, 135)),
    'head': ((230, 115), (235, 94)),
    'upper_far': ((198, 132), (167, 169)),
    'fore_far': ((167, 169), (138, 207)),
    'hand_far': ((138, 207), (119, 224)),
    'thigh_far': ((213, 225), (207, 300)),
    'shin_far': ((207, 300), (191, 398)),
    'upper_near': ((245, 147), (231, 181)),
    'fore_near': ((231, 181), (219, 218)),
    'hand_near': ((219, 218), (209, 244)),
    'thigh_near': ((244, 236), (252, 303)),
    'shin_near': ((252, 303), (260, 390)),
    'shoe': ((260, 390), (297, 400)),
}


def load_solver():
    spec = importlib.util.spec_from_file_location('oef_render', HERE / 'oef_render.py')
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def refit_hip(torso):
    """Taper the squat source's broad dark hip without moving any joints."""
    pixels = np.array(torso.convert('RGBA'))
    y = np.arange(pixels.shape[0])[:, None]
    mask = ((pixels[:, :, 0] < 75) & (pixels[:, :, 1] < 75) &
            (pixels[:, :, 2] < 75) & (pixels[:, :, 3] > 0) & (y > 190))
    dark = np.zeros_like(pixels)
    dark[mask] = pixels[mask]
    pixels[mask] = 0
    hip = Image.fromarray(dark)
    bounds = hip.getchannel('A').getbbox()
    if not bounds:
        raise ValueError('Could not locate the source shorts on the torso')
    shape = hip.crop(bounds)
    width = max(1, round(shape.width * .82))
    height = max(1, round(shape.height * .78))
    shape = shape.resize((width, height), Image.Resampling.LANCZOS)
    result = Image.fromarray(pixels)
    result.alpha_composite(shape, (round((bounds[0]+bounds[2]-width)/2), bounds[1]))
    return result


class Character:
    def __init__(self, directory):
        self.parts = {}
        for name, (p1, p2) in PARTS.items():
            original = Image.open(directory / f'{name}.png').convert('RGBA')
            if name == 'torso':
                original = refit_hip(original)
                # The neck polygon extends into the original head. Clip its
                # top before independently posing the head, avoiding a spike.
                neck = Image.open(directory / 'neck.png').convert('RGBA')
                ImageDraw.Draw(neck).rectangle((0, 0, SIZE, 124), fill=(0, 0, 0, 0))
                neck.alpha_composite(original)
                original = neck
            if original.size != (SIZE, SIZE):
                raise ValueError(f'{name}: expected a 480x480 source')
            box = original.getchannel('A').getbbox()
            if not box:
                raise ValueError(f'{name}: empty source part')
            x0, y0, x1, y1 = box
            box = (max(0, x0-2), max(0, y0-2), min(SIZE, x1+2), min(SIZE, y1+2))
            self.parts[name] = (original.crop(box),
                                (p1[0]-box[0], p1[1]-box[1]),
                                (p2[0]-box[0], p2[1]-box[1]))

    def paste(self, target, name, dest1, dest2):
        part, source1, source2 = self.parts[name]
        dx, dy = source2[0]-source1[0], source2[1]-source1[1]
        ex, ey = dest2[0]-dest1[0], dest2[1]-dest1[1]
        source_length, dest_length = math.hypot(dx, dy), math.hypot(ex, ey)
        if source_length < 1e-6 or dest_length < 1e-6:
            return

        # Keep both joint endpoints and the original head, hands and shoes.
        # Only the thickness *across* each body segment is reduced: unlike
        # squeezing the whole image horizontally, this works when a limb or
        # torso rotates. The proportions are inspired by the slimmer, original
        # Jumping Jack character. They are an app-authored adaptation, not a
        # new Jumping Jack animation or a source-author-approved figure.
        widths = {
            'torso': .75,
            'thigh_near': .71, 'thigh_far': .71,
            'shin_near': .87, 'shin_far': .87,
            'upper_near': .79, 'upper_far': .79,
            'fore_near': .85, 'fore_far': .85,
        }
        sx, sy = dx/source_length, dy/source_length
        ux, uy = ex/dest_length, ey/dest_length
        along = dest_length/source_length
        across = along * widths.get(name, 1.0)
        a = along*ux*sx + across*uy*sy
        b = along*ux*sy - across*uy*sx
        c = along*uy*sx - across*ux*sy
        d = along*uy*sy + across*ux*sx
        det = a*d - b*c
        if abs(det) < 1e-8:
            return
        tx = dest1[0] - a*source1[0] - b*source1[1]
        ty = dest1[1] - c*source1[0] - d*source1[1]
        corners = [(tx+a*x+b*y, ty+c*x+d*y)
                   for x, y in ((0,0),(part.width,0),(0,part.height),(part.width,part.height))]
        left = max(0, math.floor(min(x for x, _ in corners))-2)
        top = max(0, math.floor(min(y for _, y in corners))-2)
        right = min(SIZE, math.ceil(max(x for x, _ in corners))+2)
        bottom = min(SIZE, math.ceil(max(y for _, y in corners))+2)
        if left >= right or top >= bottom:
            return
        # Pillow uses the inverse affine transform. Crop the output to the
        # part's transformed bounds rather than transforming the whole canvas.
        offset_x, offset_y = left-tx, top-ty
        inv = (d/det, -b/det, (d*offset_x-b*offset_y)/det,
               -c/det, a/det, (-c*offset_x+a*offset_y)/det)
        layer = part.transform((right-left, bottom-top), Image.Transform.AFFINE,
                               inv, resample=Image.Resampling.BICUBIC,
                               fillcolor=(0,0,0,0))
        target.alpha_composite(layer, (left, top))


def screen(box):
    (x0, y0), (x1, y1) = box
    scale = SIZE / (max(x1-x0, y1-y0)*1.08)
    cx, cy = (x0+x1)/2, (y0+y1)/2
    return lambda p: ((p[0]-cx)*scale+SIZE/2, SIZE/2-(p[1]-cy)*scale), scale


def background(fig, joints, box, solver):
    im = Image.new('RGBA', (SIZE, SIZE), (245,245,245,255))
    d = ImageDraw.Draw(im)
    pt, scale = screen(box)
    floor = pt((0, 0))[1]
    if 0 <= floor < SIZE:
        d.line([(18, floor), (SIZE-18, floor)], fill=(215,219,220,255), width=2)
    for item in fig.get('equipment', []):
        if item['type'] == 'bench':
            x, y = solver.where(joints, item.get('at', (0, 0)))
            length = item.get('length', 0.6)
            l, top = pt((x-length/2, y+.05))
            r, bottom = pt((x+length/2, y-.05))
            _, floor_y = pt((0, 0))
            legw = max(5, .035*scale)
            for lx in (l+length*scale*.16, r-length*scale*.16):
                d.rounded_rectangle((lx-legw/2, bottom, lx+legw/2, floor_y),
                                    radius=2, fill=(99,111,115,255))
            if item.get('style') == 'chair':
                d.rounded_rectangle((l, top-.40*scale, l+legw*1.5, top+2),
                                    radius=3, fill=(99,111,115,255))
                d.rectangle((l-legw*2.3, 0, l-legw*1.5, floor_y), fill=(213,218,220,255))
            d.rounded_rectangle((l, top, r, bottom), radius=4, fill=(95,108,112,255))
        if item['type'] == 'rails':
            x, y = solver.where(joints, item.get('at', (0, 0)))
            sx, sy = pt((x, y)); _, top = pt((x, y + item.get('h', 1.5)))
            w = max(6, .06 * scale)
            d.rounded_rectangle((sx-w/2, top, sx+w/2, sy), radius=3, fill=(147,158,161,255))
        if item['type'] == 'band':
            start = solver.where(joints, item['from'])
            for joint in item.get('on', ['nearHand']):
                d.line((pt(start), pt(joints[joint])), fill=(64,121,143,255), width=max(3,int(.022*scale)))
        if item['type'] == 'towel':
            ankle = joints['nearAnkle']; toe = joints['nearToe']
            loop = ((ankle[0]+toe[0])/2, (ankle[1]+toe[1])/2)
            d.line((pt(loop), pt(joints['nearWrist'])), fill=(162,143,112,255),
                   width=max(4,int(.025*scale)))
        if item['type'] == 'pullupBar':
            x, y = item.get('at', [0,2.25]); length = item.get('length', .9)
            start,end = pt((x-length/2,y)),pt((x+length/2,y))
            d.line((start,end), fill=(84,101,105,255), width=max(7,int(.045*scale)))
        if item['type'] == 'wall':
            x, _ = solver.where(joints, item.get('at', (0,0)))
            sx, sy = pt((x, 0)); thickness = max(4, .07*scale)
            d.rectangle((sx-thickness/2, 0, sx+thickness/2, sy), fill=(213,218,220,255))
            d.line((sx+thickness/2, 0, sx+thickness/2, sy), fill=(187,195,197,255), width=2)
    return im


def draw_weight(im, kind, centre, scale):
    d = ImageDraw.Draw(im)
    x, y = centre
    if kind == 'dumbbell':
        r = max(7, .085*scale)
        points = [(x+r*math.cos(math.radians(30+60*i)),
                   y+r*math.sin(math.radians(30+60*i))) for i in range(6)]
        d.polygon(points, fill=(54,60,64,255))
        d.ellipse((x-r*.34,y-r*.34,x+r*.34,y+r*.34), fill=(130,138,139,255))
    elif kind == 'verticalDumbbell':
        r = max(8, .09*scale)
        d.rounded_rectangle((x-r*.27,y,x+r*.27,y+r*2.0), radius=max(2,int(r*.22)), fill=(98,108,111,255))
        d.rounded_rectangle((x-r,y-r*.35,x+r,y+r*.42), radius=max(3,int(r*.35)), fill=(54,60,64,255))
        d.rounded_rectangle((x-r,y+r*1.4,x+r,y+r*2.15), radius=max(3,int(r*.35)), fill=(54,60,64,255))
    elif kind == 'kettlebell':
        r = max(9, .08*scale)
        d.rounded_rectangle((x-r*.6,y-r*.28,x+r*.6,y+r*.65),radius=max(2,int(r*.3)),
                            outline=(48,54,58,255),width=max(2,int(r*.25)))
        d.ellipse((x-r,y+r*.35,x+r,y+r*2.15), fill=(54,60,64,255))
        d.arc((x-r*.75,y+r*.5,x+r*.1,y+r*1.5),190,280,fill=(126,134,136,255),width=2)


def draw_pose(character, solver, fig, pose, box):
    joints = solver.pose_joints(fig, pose)
    # Equipment overrides are interpolated together with the poses.
    props = solver.equipment(fig, pose)
    actual = {**fig, 'equipment': props}
    im = background(actual, joints, box, solver)
    point, scale = screen(box)
    def part(name, a, b):
        character.paste(im, name, point(joints[a]), point(joints[b]))
    def limb(side, foreground):
        part('thigh_'+side, side+'Hip', side+'Knee')
        part('shin_'+side, side+'Knee', side+'Ankle')
        part('shoe', side+'Ankle', side+'Toe')
        part('upper_'+side, side+'Shoulder', side+'Elbow')
        part('fore_'+side, side+'Elbow', side+'Wrist')
        # Draw the weight before the hand, so the palm remains visible.
        for item in props:
            kind = item['type']
            if kind not in ('dumbbell', 'verticalDumbbell', 'kettlebell'):
                continue
            on = item.get('on', ['nearHand', 'farHand'])
            for joint in on:
                if joint.startswith(side):
                    draw_weight(im, kind, point(joints[joint]), scale)
        part('hand_'+side, side+'Wrist', side+'Hand')
    limb('far', False)
    part('torso', 'hip', 'shoulder')
    part('head', 'neckTop', 'head')
    limb('near', True)
    return im.convert('RGB')


def combine_bounds(bounds):
    return ((min(a[0][0] for a in bounds), min(a[0][1] for a in bounds)),
            (max(a[1][0] for a in bounds), max(a[1][1] for a in bounds)))


def get_figures(name):
    if name in STATIC:
        return [json.loads((RIGS / (name+'.json')).read_text())]
    kind, rigs = ANIMATED[name]
    root = OLD_RIGS if kind == 'local' else RIGS
    return [json.loads((root / (rig+'.json')).read_text()) for rig in rigs]


def render_job(args):
    name, parts_dir, output, sheet_only = args
    solver = load_solver()
    if name == 'pushup_wall':
        solver.HOLD_FRAMES = 0
        solver.FRAMES_PER_MOVE = 1
    elif name == 'squat_knee_drive':
        solver.HOLD_FRAMES = 1
        solver.FRAMES_PER_MOVE = 7
    elif name == 'mountain_climbers':
        # Extra transition poses keep one toe planted; avoid a slow loop.
        solver.HOLD_FRAMES = 0
        solver.FRAMES_PER_MOVE = 6
    figs = get_figures(name)
    if any(fig.get('view', 'side') != 'side' for fig in figs):
        raise ValueError(f'{name}: the source parts are side-view only')
    timelines = [solver.timeline(fig) if len(fig['poses']) > 1 else fig['poses'] for fig in figs]
    # Geometric checks catch gross floor/wall mistakes in intermediate poses;
    # they do not prove biomechanical or clinical correctness.
    for rig, timeline in zip(figs, timelines):
        for index, pose in enumerate(timeline):
            joints = solver.pose_joints(rig, pose)
            below = [key for key, (_, y) in joints.items() if y < -.04]
            if below:
                raise ValueError(f'{name} frame {index}: joints below floor: {below}')
            if name == 'pushup_wall' and abs(joints['nearWrist'][0] - .84) > .015:
                raise ValueError(f'{name} frame {index}: wrist left wall')
            if name in ('march_in_place', 'standing_knee_raise', 'mountain_climber_standing'):
                if min(joints['nearToe'][1], joints['farToe'][1]) > .09:
                    raise ValueError(f'{name} frame {index}: no supporting toe')
    box = combine_bounds([solver.bounds(fig, frames) for fig, frames in zip(figs, timelines)])
    for fig in figs:
        for item in fig.get('equipment', []):
            if item['type'] == 'pullupBar' and isinstance(item.get('at'), list):
                x, y = item['at']; length = item.get('length', .9)
                box = ((min(box[0][0], x-length/2-.08), box[0][1]),
                       (max(box[1][0], x+length/2+.08), max(box[1][1], y+.08)))
            if item['type'] == 'bench' and isinstance(item.get('at'), list):
                x, y = item['at']; length = item.get('length', .6)
                box = ((min(box[0][0], x-length/2-.14), box[0][1]),
                       (max(box[1][0], x+length/2+.14), box[1][1]))
    character = Character(Path(parts_dir))
    frames = []
    for fig, timeline in zip(figs, timelines):
        # Sample every authored pose for visual contact-sheet review if requested.
        poses = fig['poses'] if sheet_only else timeline
        for pose in poses:
            frames.append(draw_pose(character, solver, fig, pose, box))
    dest = Path(output)
    if sheet_only:
        for i, frame in enumerate(frames):
            frame.save(dest / f'{name}-{i:02d}.png')
    elif name in STATIC:
        frames[0].save(dest / f'{name}.webp', format='WEBP', quality=90, method=5)
    else:
        duration = [FRAME_MS.get(name,67)] * len(frames)
        if name == 'superman':
            for i in range(17, 20): duration[i] = 334  # three identical peak frames = 1 second
        frames[0].save(dest / f'{name}.webp', format='WEBP', save_all=True,
                       append_images=frames[1:], duration=duration,
                       loop=0, quality=84, method=5)
    return f'{name}: {len(frames)} frames'


def chair_frame(character_frame):
    im = Image.new('RGBA', (SIZE,SIZE), (245,245,245,255)); d = ImageDraw.Draw(im)
    # A firm chair backed against a wall. The seat top meets the original
    # athlete's hips at the lowest grounded squat frame.
    d.line((18,426,462,426), fill=(215,219,220,255), width=2)
    d.rectangle((94,38,104,426), fill=(213,218,220,255))
    d.line((104,38,104,426), fill=(187,195,197,255), width=2)
    d.rounded_rectangle((108,242,120,317), radius=4, fill=(93,106,111,255))
    d.rounded_rectangle((108,307,207,319), radius=5, fill=(95,108,112,255))
    d.rounded_rectangle((116,315,125,425), radius=3, fill=(96,106,110,255))
    d.rounded_rectangle((190,315,199,425), radius=3, fill=(96,106,110,255))
    im.alpha_composite(character_frame)
    return im.convert('RGB')


def build_chair(parts, output, sheet_only=False):
    def seq(start, end, count):
        return [round((start+(end-start)*i/(count-1))*4) for i in range(count)]
    steps = seq(9,30,42)+[120]*5+seq(30,9,42)+[36]*5
    if sheet_only:
        steps = [36, 60, 88, 120]
    @lru_cache(maxsize=100)
    def frame(step):
        original = Image.open(parts / f'squat_{step}.png').convert('RGBA')
        return chair_frame(slim_squat_frame(original))
    frames = [frame(step) for step in steps]
    if sheet_only:
        for i, frame in enumerate(frames): frame.save(output / f'squat_chair-{i:02d}.png')
    else:
        frames[0].save(output/'squat_chair.webp',format='WEBP',save_all=True,
                       append_images=frames[1:],duration=40,loop=0,quality=84,method=5)
    return f'squat_chair: {len(frames)} frames'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('parts', type=Path, help='Output of extract_character.cjs')
    parser.add_argument('--output', type=Path, default=OUTPUT)
    parser.add_argument('--workers', type=int, default=2)
    parser.add_argument('--ids', nargs='*', default=None)
    parser.add_argument('--sheet-only', action='store_true')
    args = parser.parse_args()
    if not features.check('webp'):
        raise RuntimeError('Pillow must support WebP')
    args.output.mkdir(parents=True, exist_ok=True)
    names = args.ids or [*ANIMATED, *STATIC, 'squat_chair']
    unknown = set(names)-set(ANIMATED)-set(STATIC)-{'squat_chair'}
    if unknown:
        raise ValueError(f'Unknown ids: {sorted(unknown)}')
    if 'squat_chair' in names:
        print(build_chair(args.parts, args.output, args.sheet_only), flush=True)
    jobs = [(n, args.parts.resolve(), args.output.resolve(), args.sheet_only)
            for n in names if n != 'squat_chair']
    with ProcessPoolExecutor(max_workers=max(1,args.workers)) as pool:
        for result in pool.map(render_job, jobs): print(result, flush=True)


if __name__ == '__main__':
    main()

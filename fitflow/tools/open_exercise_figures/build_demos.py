#!/usr/bin/env python3
"""Rebuild locally authored/adapted CC0 figure loops; not an app dependency.

See README.md for the pinned upstream renderer and squat source file.
"""

import argparse
import importlib.util
import json
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent

# Two rigs are concatenated for exercises that alternate sides.
RIGS = {
    'bird_dog': ('bird_dog_a', 'bird_dog_b'),
    'plank_reach': ('plank_reach_a', 'plank_reach_b'),
    'donkey_kick': ('donkey_kick',),
    'good_morning': ('good_morning',),
    'high_knees': ('high_knees',),
    'hip_hinge': ('hip_hinge',),
    'hip_hinge_single_leg': ('hip_hinge_single_leg',),
    'jumping_jacks': ('jumping_jacks_3224',),
    'lunge_reverse': ('lunge_reverse',),
    'march_in_place': ('march_in_place',),
    'mountain_climber_standing': ('mountain_climber_standing',),
    'pushup_wall': ('pushup_wall',),
    'row_bent_over_dumbbell': ('row_bent_over_dumbbell',),
    'standing_knee_raise': ('standing_knee_raise',),
}

# Shorter frames for the quicker drills. These affect the illustration only;
# the app's workout clock and prescriptions remain independent.
FRAME_MS = {'high_knees': 40, 'march_in_place': 45,
            'mountain_climber_standing': 45}


def load_renderer(path):
    spec = importlib.util.spec_from_file_location('open_exercise_renderer', path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def rig_job(job):
    name, renderer_path, output = job
    render = load_renderer(renderer_path)
    # The wall-press rig has many closely spaced inverse-kinematics poses.
    # Avoid inserting long holds between them; the fine spacing keeps the
    # wrists near the wall throughout both directions of the movement.
    if name == 'pushup_wall':
        render.HOLD_FRAMES = 0
        render.FRAMES_PER_MOVE = 1
    frames = []
    for rig in RIGS[name]:
        figure = json.loads((HERE / (rig + '.json')).read_text())
        issues = render.problems(figure)
        if issues:
            raise ValueError(f'{rig}: {issues}')
        # Check interpolated poses too, not just the authored keys.
        for index, pose in enumerate(render.timeline(figure)):
            joints = render.pose_joints(figure, pose)
            low = [joint for joint, (_, y) in joints.items() if y < -0.04]
            if low:
                raise ValueError(f'{rig} frame {index}: below floor: {low}')
            if name == 'pushup_wall' and abs(joints['nearWrist'][0] - .84) > .015:
                raise ValueError(f'{rig} frame {index}: hand left the wall')
            if name in ('march_in_place', 'standing_knee_raise',
                        'mountain_climber_standing'):
                if min(joints['nearToe'][1], joints['farToe'][1]) > .09:
                    raise ValueError(f'{rig} frame {index}: no supporting foot')
        frames.extend(render.render(figure))
    output = Path(output)
    frames[0].save(output / f'{name}.webp', save_all=True,
                   append_images=frames[1:],
                   duration=FRAME_MS.get(name, round(1000 / render.FPS)),
                   loop=0, quality=80, method=6)
    return f'{name}: {len(frames)} source frames'


def squat_jobs(source, output):
    source = Image.open(source)
    if source.n_frames != 30:
        raise ValueError('Expected the pinned 30-frame upstream 3533 squat')
    frames = []
    for index in range(source.n_frames):
        source.seek(index)
        frames.append(source.convert('RGB'))
    # Three seconds down, one second at the bottom, roughly one second up.
    duration = [200] * 15 + [1000] + [71] * 14
    frames[0].save(output / 'squat_tempo.webp', save_all=True,
                   append_images=frames[1:], duration=duration,
                   loop=0, quality=80, method=6)
    # Small movements at the bottom, not full squat repetitions.
    indexes = [12, 13, 14, 15, 14, 13]
    pulse = [frames[i] for i in indexes]
    pulse[0].save(output / 'squat_pulse.webp', save_all=True,
                  append_images=pulse[1:], duration=130,
                  loop=0, quality=80, method=6)
    print('squat_tempo and squat_pulse: generated from 3533')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--renderer', type=Path, required=True)
    parser.add_argument('--squat-source', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--workers', type=int, default=2)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    jobs = [(name, args.renderer.resolve(), args.output.resolve()) for name in RIGS]
    with ProcessPoolExecutor(max_workers=max(1, args.workers)) as pool:
        for message in pool.map(rig_job, jobs):
            print(message, flush=True)
    squat_jobs(args.squat_source, args.output)


if __name__ == '__main__':
    main()

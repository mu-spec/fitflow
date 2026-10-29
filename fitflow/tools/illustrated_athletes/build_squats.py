"""Build three motion variants from the rendered, licensed bodyweight squat.

Requires Pillow with animated-WebP support. See README.md for source/terms.
These are stylized illustrations, not professionally validated form guidance.
"""
from pathlib import Path
import argparse
from functools import lru_cache
from PIL import Image, features
from slim_squat_art import slim_squat_frame

APP = Path(__file__).resolve().parents[2]
OUTPUT = APP / 'assets' / 'animations' / 'illustrated_athletes'


def interpolate(start, end, count):
    # Poses were rasterized at quarter-frame intervals.
    return [round((start + (end - start) * i / (count - 1)) * 4)
            for i in range(count)]


@lru_cache(maxsize=100)
def slim_frame(frames_dir, step):
    frame = Image.open(frames_dir / f'squat_{step}.png').convert('RGBA')
    if frame.size != (480, 480):
        raise ValueError(f'Unexpected frame size: {step}')
    athlete = slim_squat_frame(frame)
    background = Image.new('RGBA', (480, 480), (245, 245, 245, 255))
    background.alpha_composite(athlete)
    return background.convert('RGB')


def build(frames_dir, name, timeline):
    frames, durations = [], []
    for step, duration in timeline:
        frames.append(slim_frame(frames_dir, step))
        durations.append(duration)
    output = OUTPUT / f'{name}.webp'
    frames[0].save(output, format='WEBP', save_all=True,
                   append_images=frames[1:], duration=durations, loop=0,
                   quality=84, method=5)
    print(f'{output}: {sum(durations)} ms, {output.stat().st_size} bytes')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('frames_dir', type=Path)
    args = parser.parse_args()
    if not features.check('webp'):
        raise RuntimeError('Pillow must support WebP')
    OUTPUT.mkdir(parents=True, exist_ok=True)
    # The regular bodyweight squat retains its former 2.5-second cycle.
    normal = [(step, 40) for step in interpolate(9, 30, 30)]
    normal += [(30 * 4, 80)]
    normal += [(step, 40) for step in interpolate(30, 9, 30)]
    normal += [(9 * 4, 20)]
    build(args.frames_dir, 'squat_bodyweight', normal)

    # Shallow comfortable range, followed by a return to standing.
    partial = [(step, 40) for step in interpolate(9, 15, 30)]
    partial += [(15 * 4, 200)]
    partial += [(step, 40) for step in interpolate(15, 9, 30)]
    partial += [(9 * 4, 200)]
    build(args.frames_dir, 'squat_partial', partial)

    # Three seconds down, one-second bottom pause, one second up, reset.
    tempo = [(step, 40) for step in interpolate(9, 30, 75)]
    tempo += [(30 * 4, 1000)]
    tempo += [(step, 40) for step in interpolate(30, 9, 25)]
    tempo += [(9 * 4, 200)]
    build(args.frames_dir, 'squat_tempo', tempo)

    # Remain near the bottom and pulse rather than standing between reps.
    pulse = [(step, 40) for step in interpolate(29, 24, 18)]
    pulse += [(step, 40) for step in interpolate(24, 29, 18)]
    build(args.frames_dir, 'squat_pulse', pulse)


if __name__ == '__main__':
    main()

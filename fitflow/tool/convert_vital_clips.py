"""Convert the two visually reviewed Vital clips; never rewrite source media.

Usage: python tool/convert_vital_clips.py D:/VitalAnimations.zip
Local authoring prerequisites: OpenCV and Pillow (not app dependencies).
Whole frames, original timing, no mirroring/cropping or invented transitions.
"""

import argparse
import hashlib
import json
from pathlib import Path
import tempfile
import zipfile

import cv2
from PIL import Image


CLIPS = {
    "pushup_pike": (
        "VitalAnimations/Character Samples/homeWorkout/0353.mp4",
        "66ba7e7730e0d3534d9d47c17e2025d5a27ba0f7192c98764e18aaa145a32a41",
    ),
    "squat_goblet_dumbbell": (
        "VitalAnimations/Free50/Free50/0064.mp4",
        "b15b4ea2bb75d97eb3f8a02a2de237dca7403d72518e3759307c2178e6fdede7",
    ),
}


def convert(archive, output, scratch):
    output.mkdir(parents=True, exist_ok=True)
    scratch.mkdir(parents=True, exist_ok=True)
    results = []
    with zipfile.ZipFile(archive) as pack, tempfile.TemporaryDirectory(dir=scratch) as temp:
        for exercise_id, (member, expected_hash) in CLIPS.items():
            source = pack.read(member)
            if hashlib.sha256(source).hexdigest() != expected_hash:
                raise ValueError(f"Unreviewed source file: {member}")
            path = Path(temp) / f"{exercise_id}.mp4"
            path.write_bytes(source)
            cap = cv2.VideoCapture(str(path))
            if not cap.isOpened():
                raise ValueError(f"Cannot decode {member}")
            fps = cap.get(cv2.CAP_PROP_FPS)
            expected_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            frames = []
            try:
                while True:
                    ok, frame = cap.read()
                    if not ok:
                        break
                    image = Image.fromarray(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
                    image.thumbnail((480, 480), Image.Resampling.LANCZOS)
                    frames.append(image)
            finally:
                cap.release()
            if len(frames) != expected_frames or fps <= 0:
                raise ValueError(f"Incomplete source decode: {member}")
            durations = [round((i + 1) * 1000 / fps) - round(i * 1000 / fps)
                         for i in range(len(frames))]
            target = output / f"{exercise_id}.webp"
            frames[0].save(target, save_all=True, append_images=frames[1:],
                           duration=durations, loop=0, quality=82, method=6)
            with Image.open(target) as exported:
                # libwebp coalesces identical consecutive frames, retaining time.
                assert 1 < exported.n_frames <= expected_frames
                assert exported.info["loop"] == 0
                assert exported.size == frames[0].size
                encoded_frames = exported.n_frames
                encoded_duration = 0
                for index in range(encoded_frames):
                    exported.seek(index)
                    exported.load()
                    encoded_duration += exported.info["duration"]
                assert encoded_duration == sum(durations)
            results.append({"exerciseId": exercise_id, "source": member,
                            "sourceSha256": expected_hash,
                            "sourceFrames": len(frames), "frames": encoded_frames,
                            "durationMs": sum(durations),
                            "width": frames[0].width, "height": frames[0].height,
                            "bytes": target.stat().st_size,
                            "sha256": hashlib.sha256(target.read_bytes()).hexdigest()})
    return results


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    print(json.dumps(convert(args.archive, root / "assets/animations/vital",
                             root / ".dart_tool/animation_pack_review"), indent=2))

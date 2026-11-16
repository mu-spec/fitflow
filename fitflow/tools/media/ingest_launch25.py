"""Ingest one owner-supplied exercise animation into the launch25 catalog.

This is the same publish contract the approved batches used
(tools/squat_sample/publish_*.py): validate the whole candidate, keep a hash
backup of what is replaced, write motion + poster, and prove that no other
exercise pair changed. It adds the parts that were hand-done per batch:
normalising metadata, rendering the 720x720 poster with the app's own Lottie
renderer, and reporting the pacing decision.

Examples
--------
Dry run (writes only into build/<id>-ingest, touches no app asset):
    python3 tools/media/ingest_launch25.py --id dead_bug \
        --source build/inbox/dead_bug.json --reps 2 --dry-run

Publish:
    python3 tools/media/ingest_launch25.py --id dead_bug \
        --source build/inbox/dead_bug.json --reps 2 \
        --author "supplied by app owner" --license "owner-supplied"

Supported inputs: Lottie `.json`, dotLottie `.lottie` (auto-unzipped),
animated `.gif` / `.webp`. Video needs a GIF/WebP/Lottie export first.
"""
from __future__ import annotations

import argparse
import copy
import datetime as dt
import hashlib
import json
import re
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / 'assets/animations/launch25'
CATALOG = ROOT / 'lib/features/workouts/data/exercise_catalog.dart'
REGISTRY = ROOT / 'lib/core/design/media/exercise_animation_registry.dart'
REFERENCE_REP_MS = 2680

failures: list[str] = []


def fail(msg: str) -> None:
    failures.append(msg)
    print(f'  x {msg}')


def note(msg: str) -> None:
    print(f'  - {msg}')


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def active_ids() -> set[str]:
    src = CATALOG.read_text(encoding='utf-8')
    out = set()
    for block in re.split(r'\n\s*Exercise\(', src)[1:]:
        m = re.search(r'id:\s*"([a-z0-9_]+)"', block)
        if m and re.search(r'active:\s*true', block):
            out.add(m.group(1))
    return out


def registered_ids() -> dict[str, str]:
    src = REGISTRY.read_text(encoding='utf-8')
    return dict(re.findall(r"'([a-z0-9_]+)':\s*'(assets/animations/launch25/[^']+)'", src))


def load_motion(source: Path) -> tuple[dict | None, str]:
    """Return (lottie dict or None, note). Extracts dotLottie archives."""
    if source.suffix == '.lottie' or (
            source.suffix == '.json' and source.read_bytes()[:2] == b'PK'):
        with zipfile.ZipFile(source) as zf:
            names = [n for n in zf.namelist()
                     if n.startswith('animations/') and n.endswith('.json')]
            if not names:
                fail('dotLottie archive has no animations/*.json entry')
                return None, ''
            spec = json.loads(zf.read(names[0]))
            return spec, f'extracted {names[0]} from dotLottie archive'
    if source.suffix != '.json':
        return None, ''
    return json.loads(source.read_text(encoding='utf-8')), 'plain Lottie json'


def describe_motion(spec: dict) -> dict:
    fr = spec.get('fr') or 1
    ip, op = spec.get('ip', 0), spec.get('op', 0)
    return dict(fps=round(fr, 3), frames=round(op - ip, 2),
                seconds=round((op - ip) / fr, 3),
                w=spec.get('w'), h=spec.get('h'),
                layers=len(spec.get('layers') or []),
                embedded=len(spec.get('assets') or []))


def render_poster(id_: str, motion_path: Path, out_dir: Path, frame: int,
                  flutter_bin: str) -> Path | None:
    out_dir.mkdir(parents=True, exist_ok=True)
    cmd = [flutter_bin, 'test', 'tools/review/render_lottie_test.dart',
           f'--dart-define=LOTTIE={motion_path}',
           f'--dart-define=OUT={out_dir}',
           f'--dart-define=POSTER_FRAME={frame}',
           f'--dart-define=FRAMES=24']
    print('  $ ' + ' '.join(cmd))
    proc = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
    poster = out_dir / f'{motion_path.stem}_poster.png'
    if proc.returncode != 0 or not poster.exists():
        fail('poster render failed; last output:\n' +
             '\n'.join((proc.stdout + proc.stderr).strip().splitlines()[-8:]))
        return None
    for line in proc.stdout.splitlines():
        if line.startswith('LOTTIE_OK'):
            note(line)
    return poster


def poster_from_raster(source: Path, out_dir: Path, frame: int) -> Path | None:
    try:
        from PIL import Image
    except ImportError:
        fail('Pillow is required to poster a GIF/WebP input')
        return None
    out_dir.mkdir(parents=True, exist_ok=True)
    with Image.open(source) as im:
        im.seek(min(frame, getattr(im, 'n_frames', 1) - 1))
        canvas = Image.new('RGBA', (720, 720), (245, 245, 245, 255))
        rgba = im.convert('RGBA')
        scale = min(700 / rgba.width, 700 / rgba.height)
        rgba = rgba.resize((round(rgba.width * scale), round(rgba.height * scale)),
                           Image.LANCZOS)
        canvas.paste(rgba, ((720 - rgba.width) // 2, (720 - rgba.height) // 2), rgba)
        out = out_dir / f'{source.stem}_poster.png'
        canvas.convert('RGB').save(out)
        return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--id', required=True, help='exact catalog id, e.g. dead_bug')
    ap.add_argument('--source', required=True, type=Path)
    ap.add_argument('--reps', type=int, default=None,
                    help='full repetitions contained in one loop '
                         f'(app stretches the loop to {REFERENCE_REP_MS} ms per rep)')
    ap.add_argument('--poster-frame', type=int, default=10)
    ap.add_argument('--author', default='supplied by app owner')
    ap.add_argument('--license', default='owner-supplied')
    ap.add_argument('--note', default='')
    ap.add_argument('--flutter-bin', default='flutter')
    ap.add_argument('--dry-run', action='store_true')
    args = ap.parse_args()

    id_ = args.id
    source = args.source if args.source.is_absolute() else (ROOT / args.source)
    print(f'Ingest {id_} <- {source}')

    active, registered = active_ids(), registered_ids()
    if id_ not in active:
        fail(f'{id_} is not an active catalog exercise')
    if id_ not in registered:
        fail(f'{id_} is not in ExerciseAnimationRegistry.assets — add the mapping first')
    if failures:
        return 1
    if not source.exists():
        fail(f'source not found: {source}')
        return 1

    work = ROOT / f'build/{id_}-ingest'
    work.mkdir(parents=True, exist_ok=True)

    spec, note_text = load_motion(source)
    if note_text:
        note(note_text)

    if spec is not None:
        info = describe_motion(spec)
        note(f"motion {info['fps']} fps, {info['frames']:.0f} frames, "
             f"{info['seconds']}s, canvas {info['w']}x{info['h']}, "
             f"{info['layers']} layers, {info['embedded']} embedded assets")
        if info['frames'] <= 0:
            fail('motion has no duration')
        if (info['w'], info['h']) != (720, 720):
            note(f"canvas {info['w']}x{info['h']} differs from the 720x720 "
                 'convention; the app letterboxes it with BoxFit.contain')
        published = copy.deepcopy(spec)
        published['nm'] = id_
        published.setdefault('meta', {})
        published['meta'].update(
            source=published['meta'].get('source', args.author),
            license=args.license,
            provenance=published['meta'].get('provenance', args.author),
            review_only=False,
            approved=dt.date.today().isoformat(),
            prepared_by='tools/media/ingest_launch25.py',
            source_sha256=sha(source))
        if args.note:
            published['meta']['note'] = args.note
        motion_out = work / f'{id_}.json'
        motion_out.write_text(json.dumps(published, separators=(',', ':')),
                              encoding='utf-8')
        poster = render_poster(id_, motion_out, work, args.poster_frame,
                               args.flutter_bin)
    else:
        if source.suffix not in ('.gif', '.webp'):
            fail(f'unsupported input type {source.suffix}; supply Lottie .json, '
                 '.lottie, .gif or animated .webp')
            return 1
        note('raster motion input — registry path must point at the .gif/.webp')
        motion_out = work / f'{id_}{source.suffix}'
        shutil.copyfile(source, motion_out)
        poster = poster_from_raster(source, work, args.poster_frame)

    if poster is None:
        return 1
    note(f'poster {poster.relative_to(ROOT)} ({poster.stat().st_size // 1024} KB)')

    if args.reps is None:
        note('no --reps given: keep the current repetitionsPerLoop value unless '
             'the supplied loop differs')
    else:
        paced = REFERENCE_REP_MS * args.reps / 1000
        src_seconds = (describe_motion(spec)['seconds'] if spec is not None else 0)
        note(f'--reps {args.reps} -> loop plays over {paced:.2f}s; '
             f'source lasts {src_seconds}s (playback rate '
             f'{src_seconds / paced:.2f}x)' if paced else '')

    # What is being replaced (nothing else may change).
    before = {p.name: sha(p) for p in ASSETS.iterdir() if p.suffix in ('.json', '.png')}
    backup = work / 'before-publish'
    backup.mkdir(parents=True, exist_ok=True)
    manifest = backup / 'manifest.json'
    if not manifest.exists():
        manifest.write_text(json.dumps(before, indent=2), encoding='utf-8')

    if args.dry_run:
        print(f'\nDry run: candidate staged in {work.relative_to(ROOT)}. '
              'No app asset changed.')
        print('Review the poster and frames, then re-run without --dry-run.')
        return 0

    target_motion = ASSETS / motion_out.name
    target_poster = ASSETS / f'{id_}_poster.png'
    for target in (ASSETS / f'{id_}.json', target_poster,
                   ASSETS / f'{id_}.gif', ASSETS / f'{id_}.webp'):
        if target.exists():
            shutil.copyfile(target, backup / target.name)
            if target != target_motion:
                target.unlink()  # a .json -> .gif swap must not leave both
    shutil.copyfile(motion_out, target_motion)
    shutil.copyfile(poster, target_poster)

    after = {p.name: sha(p) for p in ASSETS.iterdir() if p.suffix in ('.json', '.png')}
    changed = {n for n in set(before) | set(after) if before.get(n) != after.get(n)}
    expected = {target_motion.name, target_poster.name}
    if changed - expected:
        fail(f'unexpected assets changed: {sorted(changed - expected)}')
    note(f'changed exactly {sorted(changed)}')

    print(f"""
Published {id_}.

Now finish the contract:
  1. exercise_animation_registry.dart
       assets['{id_}'] = '{Path('assets/animations/launch25') / target_motion.name}'
       repetitionsPerLoop['{id_}'] = <reps>
  2. python3 tools/media/verify_launch25.py
  3. flutter test test/launch25_animation_test.dart test/exercise_animation_test.dart
  4. Update assets/animations/launch25/NOTICE.md and the release doc
     (docs/launch25-animation-review.md) with the source, licence and date.
  5. Eyeball build/{id_}-ingest/frames/*.png plus the poster on a phone-sized
     preview before calling it approved.
""")
    return 1 if failures else 0


if __name__ == '__main__':
    sys.exit(main())

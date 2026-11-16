"""Pre-flight verifier for the launch25 animated-exercise catalog.

Cross-checks the three places an animated exercise has to agree:

  1. lib/features/workouts/data/exercise_catalog.dart   (active ids)
  2. lib/core/design/media/exercise_animation_registry.dart
     (assets map, repetitionsPerLoop map, referenceRepetition)
  3. assets/animations/launch25/                        (motion + poster files)

Plus the pubspec asset glob. Read-only: it never edits anything.

Usage:
    python3 tools/media/verify_launch25.py
    python3 tools/media/verify_launch25.py --json
"""
from __future__ import annotations

import json
import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CATALOG = ROOT / 'lib/features/workouts/data/exercise_catalog.dart'
REGISTRY = ROOT / 'lib/core/design/media/exercise_animation_registry.dart'
ASSETS = ROOT / 'assets/animations/launch25'
PUBSPEC = ROOT / 'pubspec.yaml'

ERRORS: list[str] = []
WARNINGS: list[str] = []


def err(msg: str) -> None:
    ERRORS.append(msg)


def warn(msg: str) -> None:
    WARNINGS.append(msg)


def parse_catalog() -> tuple[list[str], list[str]]:
    src = CATALOG.read_text(encoding='utf-8')
    active, inactive = [], []
    for block in re.split(r'\n\s*Exercise\(', src)[1:]:
        m = re.search(r'id:\s*"([a-z0-9_]+)"', block)
        if not m:
            continue
        a = re.search(r'active:\s*(true|false)', block)
        (active if a and a.group(1) == 'true' else inactive).append(m.group(1))
    return active, inactive


def parse_registry():
    src = REGISTRY.read_text(encoding='utf-8')
    assets = dict(re.findall(r"'([a-z0-9_]+)':\s*'([^']+)'", src))
    reps_block = re.search(
        r'repetitionsPerLoop = <String, int>\{(.*?)\};', src, re.S)
    reps = {}
    if reps_block:
        cleaned = re.sub(r'//[^\n]*', '', reps_block.group(1))
        reps = {k: int(v) for k, v in re.findall(r"'([a-z0-9_]+)':\s*(\d+)", cleaned)}
    ref = re.search(r'referenceRepetition = Duration\(milliseconds: (\d+)\)', src)
    return assets, reps, int(ref.group(1)) if ref else 2680


def png_size(path: Path) -> tuple[int, int] | None:
    data = path.read_bytes()[:32]
    if not data.startswith(b'\x89PNG\r\n\x1a\n'):
        return None
    return struct.unpack('>II', data[16:24])


def lottie_info(path: Path) -> dict:
    spec = json.loads(path.read_text(encoding='utf-8'))
    fr = spec.get('fr') or 0
    ip, op = spec.get('ip', 0), spec.get('op', 0)
    layers = spec.get('layers', [])
    embedded = len(spec.get('assets') or [])
    return dict(
        fps=round(fr, 2),
        frames=round(op - ip, 2),
        seconds=round((op - ip) / fr, 3) if fr else 0.0,
        w=spec.get('w'),
        h=spec.get('h'),
        layers=len(layers),
        embedded_assets=embedded,
        meta=spec.get('meta') or {},
        name=spec.get('nm'),
        bytes=path.stat().st_size,
    )


def main() -> int:
    active, inactive = parse_catalog()
    assets, reps, ref_ms = parse_registry()
    rows = []

    if len(active) != 25:
        err(f'catalog has {len(active)} active exercises, expected 25')

    if set(assets) != set(active):
        err('registry assets keys != active catalog ids\n'
            f'    only in registry: {sorted(set(assets) - set(active))}\n'
            f'    only in catalog : {sorted(set(active) - set(assets))}')

    if set(reps) != set(assets):
        err('repetitionsPerLoop keys != assets keys\n'
            f'    missing pacing: {sorted(set(assets) - set(reps))}\n'
            f'    stale pacing  : {sorted(set(reps) - set(assets))}')

    for hidden in inactive:
        if hidden in assets:
            err(f'inactive exercise {hidden} is still registered for animation')

    pubspec = PUBSPEC.read_text(encoding='utf-8')
    if 'assets/animations/launch25/' not in pubspec:
        err('pubspec.yaml does not bundle assets/animations/launch25/')

    for ex_id in active:
        asset = assets.get(ex_id)
        if asset is None:
            rows.append(dict(id=ex_id, status='NO ASSET'))
            continue
        path = ROOT / asset
        if not path.exists():
            err(f'{ex_id}: missing motion file {asset}')
            continue
        if path.suffix != '.json':
            warn(f'{ex_id}: {path.suffix} motion — non-Lottie path in registry')

        poster = ASSETS / f'{ex_id}_poster.png'
        if not poster.exists():
            err(f'{ex_id}: missing poster {poster.relative_to(ROOT)}')
            continue
        size = png_size(poster)
        if size is None:
            err(f'{ex_id}: poster is not a valid PNG')
        if poster.stat().st_size <= 1000:
            err(f'{ex_id}: poster is under 1000 bytes')
        if size and size != (720, 720):
            warn(f'{ex_id}: poster is {size[0]}x{size[1]}, newer posters are 720x720')

        info = lottie_info(path)
        if info['frames'] <= 0 or info['seconds'] <= 0:
            err(f'{ex_id}: motion has no duration')
        if (info['w'], info['h']) != (720, 720):
            warn(f"{ex_id}: canvas {info['w']}x{info['h']}, others are 720x720")

        paced = ref_ms * reps.get(ex_id, 0) / 1000 if reps.get(ex_id) else info['seconds']
        meta = info['meta']
        source = meta.get('source', '—')
        approved = meta.get('approved', '')
        if not approved:
            warn(f'{ex_id}: meta has no approved date (review candidate / legacy)')

        rows.append(dict(
            id=ex_id, motion=path.name, poster=f'{poster.name}',
            poster_px=f'{size[0]}x{size[1]}' if size else '?',
            fps=info['fps'], frames=info['frames'], seconds=info['seconds'],
            reps=reps.get(ex_id), paced=round(paced, 2),
            kb=round(info['bytes'] / 1024), embedded=info['embedded_assets'],
            layers=info['layers'], approved=approved or 'legacy',
            source='adapted' if 'Military' in source else source[:28],
            status='ok'))

    if '--json' in sys.argv:
        print(json.dumps(dict(rows=rows, errors=ERRORS, warnings=WARNINGS), indent=2))
    else:
        head = (f"{'exercise':20s} {'fps':>5s} {'frames':>6s} {'sec':>6s} "
                f"{'reps':>4s} {'paced':>6s} {'KB':>6s} {'poster':>9s}  approved")
        print(head)
        print('-' * len(head))
        for r in rows:
            if r.get('status') != 'ok':
                print(f"{r['id']:20s} {r['status']}")
                continue
            print(f"{r['id']:20s} {r['fps']:5.2f} {r['frames']:6.0f} "
                  f"{r['seconds']:6.2f} {str(r['reps']):>4s} {r['paced']:6.2f} "
                  f"{r['kb']:6d} {r['poster_px']:>9s}  {r['approved']}")
        total = sum(r.get('kb', 0) for r in rows if r.get('status') == 'ok')
        print('-' * len(head))
        print(f'{len(rows)} exercises, {total / 1024:.1f} MB of motion files')

        if WARNINGS:
            print(f'\n{len(WARNINGS)} warning(s):')
            for w in WARNINGS:
                print(f'  ! {w}')
        if ERRORS:
            print(f'\n{len(ERRORS)} error(s):')
            for e in ERRORS:
                print(f'  x {e}')
        else:
            print('\nAll structural checks passed.')

    return 1 if ERRORS else 0


if __name__ == '__main__':
    sys.exit(main())

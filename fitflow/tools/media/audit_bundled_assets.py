"""Audit which bundled Flutter assets the app can actually reach.

Reads pubspec.yaml asset entries, resolves them to files on disk, then classifies
each file as used / unused at runtime by reconciling with:

  - the active catalog ids (88 definitions, 25 active)
  - ExerciseAnimationRegistry (Lottie + posters)
  - ExerciseMediaRegistry (hero/thumbnail stills)
  - program_media_registry (program covers + editorial portraits)
  - literal asset paths and files read by lib/ code (e.g. the credits NOTICE)

Read-only. Usage:
    python3 tools/media/audit_bundled_assets.py
    python3 tools/media/audit_bundled_assets.py --markdown build/asset-audit.md
"""
from __future__ import annotations

import re
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PUBSPEC = ROOT / 'pubspec.yaml'
CATALOG = ROOT / 'lib/features/workouts/data/exercise_catalog.dart'
LIB = ROOT / 'lib'


def pubspec_entries() -> list[str]:
    src = PUBSPEC.read_text(encoding='utf-8')
    block = re.search(r'^flutter:\n(.*?)(?:\n\S|\Z)', src, re.S | re.M)
    assert block, 'no flutter: block in pubspec'
    return re.findall(r'^\s{4}- (\S+)\s*$', block.group(1), re.M)


def resolve(entry: str) -> list[Path]:
    p = ROOT / entry.rstrip('/')
    if p.is_dir():
        return sorted(f for f in p.rglob('*') if f.is_file())
    return [p] if p.is_file() else []


def catalog_ids() -> tuple[set[str], set[str]]:
    src = CATALOG.read_text(encoding='utf-8')
    active, inactive = set(), set()
    for block in re.split(r'\n\s*Exercise\(', src)[1:]:
        m = re.search(r'id:\s*"([a-z0-9_]+)"', block)
        if not m:
            continue
        (active if re.search(r'active:\s*true', block) else inactive).add(m.group(1))
    return active, inactive


def lib_literals() -> tuple[set[str], set[str]]:
    """Exact asset paths + filename fragments referenced anywhere in lib/."""
    paths, names = set(), set()
    for f in LIB.rglob('*.dart'):
        text = f.read_text(encoding='utf-8')
        paths.update(re.findall(r"'(assets/[^']+)'", text))
        names.update(re.findall(r"[\w.-]+\.(?:webp|png|mp3|json|md|txt|lottie|gif)", text))
    return paths, names


def main() -> int:
    active, inactive = catalog_ids()
    literals, fragments = lib_literals()

    bundled: dict[str, list[Path]] = defaultdict(list)
    for entry in pubspec_entries():
        files = resolve(entry)
        if not files:
            print(f'  ! pubspec entry resolves to nothing: {entry}')
        for f in files:
            bundled[str(f.relative_to(ROOT))].append(Path(entry))

    rows = []
    for rel, entries in sorted(bundled.items()):
        p = ROOT / rel
        size = p.stat().st_size
        stem, suffix = p.stem, p.suffix
        if '/launch25/' in rel:
            used, why = True, 'animation registry (25 active ids)'
        elif '/real_people/' in rel and suffix in ('.md', '.txt'):
            used, why = True, 'read by Exercise artwork credits screen'
        elif '/real_people/' in rel:
            used, why = False, 'superseded motion (registry now points at launch25)'
        elif '/illustrated_athletes/' in rel:
            used, why = False, 'no reference in lib/ (stale test-only assets)'
        elif '/open_exercise_figures/' in rel:
            used, why = False, 'provenance copy; nothing loads it at runtime'
        elif '/exercises/thumb/' in rel or '/exercises/hero/' in rel:
            used = stem in active
            why = ('active exercise still' if used
                   else f'inactive catalog id ({stem})')
        elif rel in literals or p.name in fragments:
            used, why = True, 'literal path in lib/'
        elif '/programs/' in rel or '/editorial/' in rel:
            used, why = True, 'program media registry'
        elif '/audio/' in rel:
            used, why = True, 'WorkoutMusic track list'
        else:
            used, why = (rel in literals), 'unclassified'
        still = '/exercises/thumb/' in rel or '/exercises/hero/' in rel
        rows.append(dict(rel=rel, size=size, used=used, why=why, entries=len(entries),
                         inactive_id=(not used) and still and stem in inactive))

    used_bytes = sum(r['size'] for r in rows if r['used'])
    unused = [r for r in rows if not r['used']]
    unused_bytes = sum(r['size'] for r in unused)
    inactive_bytes = sum(r['size'] for r in unused if r['inactive_id'])
    stale_bytes = unused_bytes - inactive_bytes

    # Unbundled assets present in the repo (no APK cost, only repository weight).
    all_assets = [f for f in (ROOT / 'assets').rglob('*') if f.is_file()]
    unbundled = [f for f in all_assets if str(f.relative_to(ROOT)) not in bundled]
    unbundled_bytes = sum(f.stat().st_size for f in unbundled)

    print(f'{"file":68s} {"KB":>7s}  {"used":4s} reason')
    print('-' * 118)
    for r in sorted(rows, key=lambda r: (r['why'], -r['size'])):
        print(f"{r['rel']:68s} {r['size']/1024:7.1f}  {'yes' if r['used'] else 'NO ':4s} {r['why']}")
    print('-' * 118)
    print(f'bundled files: {len(rows)}   used: {len(rows)-len(unused)} '
          f'({used_bytes/1e6:.2f} MB)   unused: {len(unused)} ({unused_bytes/1e6:.2f} MB)')
    print(f'  - inactive-exercise stills: {inactive_bytes/1e6:.2f} MB')
    print(f'  - stale motion/provenance : {stale_bytes/1e6:.2f} MB')
    print(f'unbundled files in repo (no APK cost): {len(unbundled)} '
          f'({unbundled_bytes/1e6:.2f} MB)')

    if '--markdown' in sys.argv:
        out = Path(sys.argv[sys.argv.index('--markdown') + 1])
        out.parent.mkdir(parents=True, exist_ok=True)
        groups = defaultdict(list)
        for r in unused:
            groups[r['why']].append(r)
        lines = ['# Bundled asset audit', '',
                 f'- bundled files: **{len(rows)}**, used **{len(rows)-len(unused)}** '
                 f'({used_bytes/1e6:.2f} MB)',
                 f'- unused at runtime: **{len(unused)}** files, **{unused_bytes/1e6:.2f} MB**',
                 f'- unbundled but in repo (no APK cost): {len(unbundled)} files, '
                 f'{unbundled_bytes/1e6:.2f} MB', '',
                 '| unused group | files | MB |', '| --- | --- | --- |']
        for why, items in sorted(groups.items(), key=lambda kv: -sum(i['size'] for i in kv[1])):
            lines.append(f"| {why} | {len(items)} | {sum(i['size'] for i in items)/1e6:.2f} |")
        out.write_text('\n'.join(lines) + '\n', encoding='utf-8')
        print(f'wrote {out}')
    return 0


if __name__ == '__main__':
    sys.exit(main())

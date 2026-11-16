"""Publish the two owner-approved warmup previews, preserving other assets."""
import copy
import hashlib
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REVIEW = ROOT / 'build/warmup-pair-review'
TARGET = ROOT / 'assets/animations/launch25'
BACKUP = REVIEW / 'before-publish'
BACKUP.mkdir(parents=True, exist_ok=True)
IDS = ('arm_circles', 'step_jack')
changed = {f'{name}{suffix}' for name in IDS for suffix in ('.json', '_poster.png')}
before = {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
          for p in TARGET.iterdir() if p.suffix in ('.json', '.png')}
manifest = BACKUP / 'manifest.json'
if not manifest.exists():
    manifest.write_text(json.dumps(before, indent=2), encoding='utf-8')

# Validate the entire batch before replacing anything.
prepared = {}
for name in IDS:
    raw = (REVIEW / f'{name}.json').read_bytes()
    candidate = json.loads(raw)
    assert candidate['meta']['review_only'] is True
    assert candidate['meta']['approved_torso_preserved'] is True
    poster = (REVIEW / f'{name}_poster.png').read_bytes()
    assert poster.startswith(b'\x89PNG\r\n\x1a\n')
    published = copy.deepcopy(candidate)
    published['nm'] = name
    published['meta'].update(review_only=False, approved='2026-11-14',
                             approved_review_sha256=hashlib.sha256(raw).hexdigest())
    assert published['assets'] == candidate['assets']
    assert published['layers'] == candidate['layers']
    prepared[name] = (published, poster)

for filename in changed:
    if not (BACKUP / filename).exists():
        shutil.copyfile(TARGET / filename, BACKUP / filename)
for name, (published, poster) in prepared.items():
    (TARGET / f'{name}.json').write_text(json.dumps(published, separators=(',', ':')), encoding='utf-8')
    (TARGET / f'{name}_poster.png').write_bytes(poster)
for filename, digest in before.items():
    if filename not in changed:
        assert hashlib.sha256((TARGET / filename).read_bytes()).hexdigest() == digest
for name in IDS:
    installed = json.loads((TARGET / f'{name}.json').read_bytes())
    reviewed = json.loads((REVIEW / f'{name}.json').read_bytes())
    for key in reviewed.keys() - {'meta', 'nm'}:
        assert installed[key] == reviewed[key]
    assert (TARGET / f'{name}_poster.png').read_bytes() == (REVIEW / f'{name}_poster.png').read_bytes()
print('Published two approved animations and posters; all other 23 pairs unchanged. No APK built.')

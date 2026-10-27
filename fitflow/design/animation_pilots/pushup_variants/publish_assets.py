"""Publish the reviewed movement assets without changing source downloads."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[3]
source=ROOT/'design/animation_pilots/knee_pushup'
knee=json.loads((source/'knee_pushup_pilot.json').read_text(encoding='utf-8'))
knee['fr']=40
knee['nm']='Knee Push-Up'
knee['meta']['status']='Movement approved by user; 2.5-second demonstration loop'
(ROOT/'assets/animations/knee_pushup.json').write_text(json.dumps(knee,separators=(',',':')),encoding='utf-8')
for kind in ['incline','decline']:
    src=Path(__file__).parent/f'pushup_{kind}.json'
    (ROOT/f'assets/animations/pushup_{kind}.json').write_bytes(src.read_bytes())
license_text='Applies to knee_pushup.json, pushup_incline.json and pushup_decline.json.\n\n'+(source/'LICENSE.md').read_text(encoding='utf-8')
(ROOT/'assets/animations/PUSHUP_ADAPTATIONS_LICENSE.md').write_text(license_text,encoding='utf-8')

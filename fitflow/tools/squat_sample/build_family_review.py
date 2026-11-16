"""Review-only variants of the owner's approved chest-hands squat.

Resample its existing poses so character contours and proportions stay shared.
The installed catalog is read, never written.
"""
import copy
import hashlib
import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/orange_character'))
import build_character as art

OUT = ROOT / 'build/squat-family-review'
OUT.mkdir(parents=True, exist_ok=True)
SOURCE = ROOT / 'assets/animations/launch25/squat_bodyweight.json'
source_bytes = SOURCE.read_bytes()
source = json.loads(source_bytes)
source_hash = hashlib.sha256(source_bytes).hexdigest()
assert source['meta']['approved'] == '2026-11-11'


def lerp(a, b, t):
    if isinstance(a, bool):
        assert a == b
        return a
    if isinstance(a, (int, float)):
        return a + (b-a)*t
    if isinstance(a, list):
        assert len(a) == len(b)
        return [lerp(x, y, t) for x, y in zip(a, b)]
    if isinstance(a, dict):
        return {k: lerp(v, b[k], t) for k, v in a.items()}
    assert a == b
    return a


def resample(obj, times):
    if isinstance(obj, list):
        return [resample(v, times) for v in obj]
    if not isinstance(obj, dict):
        return obj
    if obj.get('a') == 1 and isinstance(obj.get('k'), list):
        keys = obj['k']
        if keys and isinstance(keys[0], dict) and 's' in keys[0]:
            assert [k['t'] for k in keys] == list(range(120))
            result = []
            for i, t in enumerate(times):
                lo = int(t)
                val = lerp(keys[lo]['s'], keys[min(lo+1,119)]['s'], t-lo)
                result.append({'t':i, 's':val, 'o':{'x':.333,'y':.333},
                               'i':{'x':.667,'y':.667}})
            return {**obj, 'k':result}
    result = {k:resample(v,times) for k,v in obj.items()}
    if isinstance(result.get('ty'), int) and 'ks' in result:
        result.update(ip=0,op=len(times),st=0)
    return result


def ease(t):
    return (1-math.cos(math.pi*t))/2


def chair_depth(t):
    # Begin seated; settle, stand, pause, return gently, settle again.
    if t <= .12: return 68.0
    if t <= .43: return 68*(1-ease((t-.12)/.31))
    if t <= .55: return 0.0
    if t <= .92: return 68*ease((t-.55)/.37)
    return 68.0


def chair_layer(frames):
    # The front edge meets the approved seated hip contour. Chair legs end on
    # the same floor as the athlete's soles; all supports are stationary.
    shapes=[]
    def panel(name, points, rgb):
        shapes.append(art.polygon(name, points, [v/255 for v in rgb]+[1]))
    panel('Left rear post', [[269,295],[280,295],[280,588],[269,588]],(83,102,116))
    panel('Right rear post', [[428,295],[439,295],[439,588],[428,588]],(83,102,116))
    panel('Rounded backrest', [[279,292],[429,292],[439,302],[439,376],
          [429,386],[279,386],[269,376],[269,302]],(113,146,164))
    panel('Backrest inset', [[284,306],[424,306],[424,371],[284,371]],(137,168,183))
    panel('Seat top', [[270,414],[438,414],[457,438],[251,438]],(151,178,190))
    panel('Left front leg', [[253,447],[266,447],[266,603],[253,603]],(69,88,104))
    panel('Right front leg', [[442,447],[455,447],[455,603],[442,603]],(69,88,104))
    panel('Front seat edge', [[251,438],[457,438],[457,450],[251,450]],(93,123,141))
    return art.shape_layer('Stable chair — fixed seat and feet',shapes,frames,300)


report={}
for name, frames in [('squat_partial',120),('squat_chair',180)]:
    depths=[32*ease(2*i/(frames-1)) if name=='squat_partial'
            else chair_depth(i/(frames-1)) for i in range(frames)]
    # Map requested depth to the approved descent. Returning through that same
    # pose sequence maintains the original silhouette and a seamless loop.
    times=[math.acos(1-2*d/68)*119/math.tau for d in depths]
    data=resample(source,times)
    data.update(fr=30,ip=0,op=frames,nm=name+' — review candidate')
    data['meta']={**source['meta'],'review_only':True,'source_approved_sha256':source_hash}
    data['meta'].pop('approved')
    data['meta']['adaptation']=('Shallow squat, hands in front of chest' if name=='squat_partial'
                                else 'Seated start, controlled stand and return to a stable chair')
    comp=next(a for a in data['assets'] if a['id']=='comp_0')
    layers={l['ind']:l for l in comp['layers']}
    original_comp=next(a for a in source['assets'] if a['id']=='comp_0')
    original_layers={l['ind']:l for l in original_comp['layers']}
    for ind in [1,206,207,208,209]:
        assert layers[ind]['shapes']==original_layers[ind]['shapes']
    for ind in [103,107]:
        assert layers[ind]['ks']==original_layers[ind]['ks']
    if name=='squat_chair':
        comp['layers'].append(chair_layer(frames))
    (OUT/(name+'.json')).write_text(json.dumps(data,separators=(',',':')),encoding='utf-8')
    report[name]={'frames':frames,'seconds':frames/30,'max_vertical_travel':max(depths),
                  'unchanged_head_torso_hands':True,'fixed_feet':True,
                  'starts_seated':name=='squat_chair','review_only':True}

assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==source_hash
(OUT/'verification.json').write_text(json.dumps(report,indent=2))
print('Created two review candidates. Installed animations were not modified.')

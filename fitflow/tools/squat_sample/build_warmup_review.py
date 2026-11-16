"""Review-only Arm Circles and Step Jack with the approved front artwork."""
import copy
import hashlib
import json
import math
from pathlib import Path
import build_standing_review as shared

art = shared.art
ROOT = shared.ROOT
OUT = ROOT / 'build/warmup-pair-review'
OUT.mkdir(parents=True, exist_ok=True)
before = {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
          for p in (ROOT / 'assets/animations/launch25').iterdir()
          if p.suffix in ('.json', '.png')}
report = {}
source = json.loads((ROOT/'assets/animations/illustrated_athletes/jumping_jacks.json').read_text())
source_layers = {l['ind']: l for a in source['assets'] if a['id']=='comp_0' for l in a['layers']}

def blend(a, b, q):
    if isinstance(a, list): return [blend(x, y, q) for x, y in zip(a, b)]
    if isinstance(a, dict): return {k: blend(v, b[k], q) for k, v in a.items()}
    if isinstance(a, bool): return a
    return a+(b-a)*q

def sample(prop, time):
    if not prop.get('a'): return copy.deepcopy(prop['k'])
    keys=prop['k']
    idx=max(i for i, k in enumerate(keys) if k['t']<=time)
    a=keys[idx]
    if idx==len(keys)-1: value=a['s']
    else:
        b=keys[idx+1]; q=(time-a['t'])/(b['t']-a['t'])
        def scalar(v): return v[0] if isinstance(v,list) else v
        ox=scalar(a.get('o',{}).get('x',.333)); oy=scalar(a.get('o',{}).get('y',.333))
        ix=scalar(a.get('i',{}).get('x',.667)); iy=scalar(a.get('i',{}).get('y',.667))
        def bez(t, x, y): return 3*(1-t)**2*t*x+3*(1-t)*t*t*y+t**3
        lo,hi=0.,1.
        for _ in range(20):
            mid=(lo+hi)/2
            if bez(mid,ox,ix)<q: lo=mid
            else: hi=mid
        value=blend(a['s'], b['s'], bez((lo+hi)/2,oy,iy))
    return value[0] if len(value)==1 else value

def source_time(angle):
    lo,hi=0.,15.
    for _ in range(22):
        mid=(lo+hi)/2
        if abs(sample(source_layers[6]['ks']['r'],mid))<angle: lo=mid
        else: hi=mid
    return (lo+hi)/2

def retime_props(obj, times):
    if isinstance(obj,list): return [retime_props(v,times) for v in obj]
    if not isinstance(obj,dict): return obj
    if obj.get('a')==1 and isinstance(obj.get('k'),list) and obj['k'] and 's' in obj['k'][0]:
        values=[sample(obj,t) for t in times]
        if isinstance(values[0],dict):
            return {'a':1,'k':[{'t':i,'s':[v],'o':{'x':.333,'y':.333},'i':{'x':.667,'y':.667}}
                               for i,v in enumerate(values)]}
        return art.keyframes(values)
    return {k:retime_props(v,times) for k,v in obj.items()}

for name, seconds in [('arm_circles', 30), ('step_jack', 8)]:
    circles = name == 'arm_circles'
    n = seconds * 30
    data = copy.deepcopy(shared.original)
    data.update(ip=0, op=n, fr=30, nm=name+' — review only')
    shared.set_duration(data, n)
    comp = next(a for a in data['assets'] if a['id'] == 'comp_0')
    ls = {l['ind']: l for l in comp['layers']}
    ls[1]['shapes'] = copy.deepcopy(shared.approved_body['shapes'])
    frames = []
    for i in range(n):
        t = i/(n-1)
        wave = math.sin(math.tau*t)
        right = max(0, wave)**2 if not circles else 0
        left = max(0, -wave)**2 if not circles else 0
        amount = right+left
        frames.append(dict(right=right, left=left, amount=amount,
                           x=8*(right-left), y=15*amount, t=t))
    bp = art.value(shared.base[1]['ks']['p'])
    ls[1]['ks']['p'] = art.keyframes([[bp[0]+f['x'], bp[1]+f['y'], 0] for f in frames])

    # Whole source arms rotate at their original shoulder pivots. Their hands
    # remain parented at the source wrists, avoiding detached or flapping hands.
    for ind, sign in [(6, -1), (8, 1)]:
        if circles:
            phase = [math.tau*5*(1-math.cos(math.tau*f['t'])) for f in frames]
            amplitude = [6+4*math.sin(math.pi*f['t'])**2 for f in frames]
            angles = [90+a*math.sin(p) for a,p in zip(amplitude,phase)]
            # Front-view depth projection: subtle length change, source width
            # preserved. This is a small shoulder circle, not a full windmill.
        else:
            angles = [158*f['amount'] for f in frames]
        hand = 7 if ind == 6 else 9
        times=[source_time(a) for a in angles]
        for limb in [ind,hand]:
            # Preserve the source's changing shoulder contour and wrist
            # attachment as the arm rises, not merely its down-pose silhouette.
            ls[limb]['ks']=retime_props(source_layers[limb]['ks'],times)
            ls[limb]['shapes']=retime_props(source_layers[limb]['shapes'],times)
        ls[ind]['ks']['r']=art.keyframes([sign*a for a in angles])
        if circles:
            ls[ind]['ks']['s']=art.keyframes([[100,98+2*math.cos(p),100] for p in phase])

    newlegs = []
    for index, side in [(2, -1), (3, 1)]:
        outer = art.matrix(index, shared.base)
        h = art.point(outer, [375.863, 323.219])
        knee = art.point(outer, [375.5, 449])
        ankle = art.point(outer, [380, 568])
        stance = side*12 if circles else -side*8
        poses = []
        contacts = []
        for f in frames:
            q = f['right' if side == 1 else 'left']
            lift = 10*math.sin(math.pi*q)**2
            foot = [ankle[0]+stance+side*70*q, ankle[1]-lift]
            hip = [h[0]+f['x'], h[1]+f['y']+4]
            kx = foot[0]-side*(5+15*q)
            ky = foot[1]-math.sqrt(math.dist(knee, ankle)**2-(foot[0]-kx)**2)
            poses.append((hip, [kx, ky], foot))
            contacts.append(lift)
        for gi, li, bone in [(0, 1, 'thigh'), (1, 3, 'thigh'), (0, 3, 'shin')]:
            g = shared.group_world(shared.legbase[li]['shapes'][gi],
                                   art.mul(outer, art.matrix(li, shared.legbase)))
            matrices = [shared.projection(h, knee, hp, kp) if bone == 'thigh'
                        else art.segment(knee, ankle, kp, fp) for hp, kp, fp in poses]
            g = shared.deform(g, [lambda p, m=m: art.point(m, p) for m in matrices])
            newlegs.append(art.shape_layer(f'{side} source {bone}', [g], n, 100+len(newlegs)))
        shoe = copy.deepcopy(shared.legbase[2])
        shoe.pop('parent', None)
        shoe.update(ip=0, op=n, st=0, sr=1, ind=100+len(newlegs))
        sm = art.mul(outer, art.matrix(2, shared.legbase))
        angle = math.degrees(math.atan2(-sm[1] if side == -1 else sm[1],
                                        -sm[0] if side == -1 else sm[0]))
        shoe['ks'] = dict(a=art.prop([0, 0, 0]),
                          p=art.keyframes([[sm[4]+fp[0]-ankle[0], sm[5]+fp[1]-ankle[1], 0]
                                           for hp, kp, fp in poses]),
                          r=art.prop(angle), s=art.prop([side*100, 100, 100]), o=art.prop(100))
        newlegs.insert(0, shoe)
    comp['layers'] = [l for l in comp['layers'] if l['ind'] not in [2, 3, 5]]+newlegs+[ls[5]]
    shared.split_positions(data)
    assert ls[1]['shapes'] == shared.approved_body['shapes']
    assert all(min(f['right'], f['left']) == 0 for f in frames)
    data['meta'] = dict(source='Jumping Jacks by Dinh Bui Xuan',
                        license='Lottie Simple License (FL 9.13.21)', review_only=True,
                        approved_torso_preserved=True, adaptation=name)
    (OUT / f'{name}.json').write_text(json.dumps(data, separators=(',', ':')), encoding='utf-8')
    report[name] = dict(seconds=seconds, review_only=True, approved_torso_preserved=True,
                        hands_parented_to_source_wrists=True, no_simultaneous_foot_lift=True)
assert all(hashlib.sha256((ROOT/'assets/animations/launch25'/k).read_bytes()).hexdigest() == v
           for k, v in before.items())
(OUT/'verification.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print('Created Arm Circles and Step Jack review candidates; production assets unchanged.')

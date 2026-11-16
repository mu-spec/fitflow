"""Review-only squat using original Jumping Jack vector artwork.

Uses source vector contours, with front-view thigh foreshortening and a
reposed shorts seam. The approved head and torso are not redrawn.
"""
import copy, json, math, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools/orange_character'))
import build_character as art
OUT = ROOT/'build/front-squat-review'
OUT.mkdir(parents=True, exist_ok=True)
source = json.loads((ROOT/'assets/animations/illustrated_athletes/jumping_jacks.json').read_text())
data = art.freeze(copy.deepcopy(source))
N = 120
data.update(ip=0, op=N, fr=30, nm='Original-artwork front squat — review only')
def duration(obj):
    if isinstance(obj, dict):
        if 'ks' in obj and isinstance(obj.get('ty'), int): obj.update(ip=0, op=N, st=0)
        for v in obj.values(): duration(v)
    elif isinstance(obj,list):
        for v in obj: duration(v)
duration(data)
comp = next(a for a in data['assets'] if a['id']=='comp_0')
leg = next(a for a in data['assets'] if a['id']=='comp_1')
layers = {l['ind']:l for l in comp['layers']}
leglayers = {l['ind']:l for l in leg['layers']}
bodypos = art.value(layers[1]['ks']['p'])
MAX_DEPTH = 68
depth = [MAX_DEPTH*(1-math.cos(i/(N-1)*math.tau))/2 for i in range(N)]
layers[1]['ks']['p'] = art.keyframes([[*bodypos[:1],bodypos[1]+d,0] for d in depth])
base = art.freeze(copy.deepcopy(source))
basecomp=next(a for a in base['assets'] if a['id']=='comp_0')
basels={l['ind']:l for l in basecomp['layers']}

def transform_group(group, matrix):
    """Bake the original group transform, including Bezier handles."""
    group=copy.deepcopy(group)
    tr=next(z for z in group['it'] if z['ty']=='tr')
    m=art.mul(matrix,art.matrix(0,{0:{'ks':tr}}))
    tr.update(p=art.prop([0,0]),a=art.prop([0,0]),s=art.prop([100,100]),r=art.prop(0))
    for z in group['it']:
        if z['ty']=='sh':
            path=z['ks']['k']
            path['v']=[art.point(m,v) for v in path['v']]
            for kind in ['i','o']:
                path[kind]=[[m[0]*x+m[2]*y,m[1]*x+m[3]*y] for x,y in path[kind]]
    return group

def foreshorten(a,b,c,d):
    # Map the along-bone axis to its projected length; keep widths at 1:1.
    sx,sy=b[0]-a[0],b[1]-a[1];sl=math.hypot(sx,sy);sx/=sl;sy/=sl
    tx,ty=d[0]-c[0],d[1]-c[1];tl=math.hypot(tx,ty);tx/=tl;ty/=tl
    r=tl/sl
    m=[r*tx*sx+ty*sy,r*ty*sx-tx*sy,
       r*tx*sy-ty*sx,r*ty*sy+tx*sx,0,0]
    m[4]=c[0]-m[0]*a[0]-m[2]*a[1]
    m[5]=c[1]-m[1]*a[0]-m[3]*a[1]
    return m

# Repose source arms in front of the torso with softly bent elbows and hands
# together. This reads clearly from the existing front camera. Body and leg
# keyframes are independent of this change.
arm_layers=[]
for arm_id,hand_id,side in [(6,7,1),(8,9,-1)]:
    mirror=lambda p: [354.1+side*(p[0]-354.1),p[1]]
    shoulder=mirror([409.7,225.65])
    elbow=mirror([430,285])
    wrist=mirror([379,259])
    src_shoulder=[409.7,225.65] if side==1 else [298.4,225.65]
    src_elbow=[418,285] if side==1 else [290.1,285]
    src_wrist=[411.6,357.5] if side==1 else [296.6,357.5]

    def warp(p):
        t=(p[1]-225.65)/(285-225.65) if p[1]<=285 else (p[1]-285)/(357.5-285)
        a,b=(shoulder,elbow) if p[1]<=285 else (elbow,wrist)
        sa,sb=(src_shoulder,src_elbow) if p[1]<=285 else (src_elbow,src_wrist)
        original_x=sa[0]+(sb[0]-sa[0])*t
        width=p[0]-original_x
        # Round the direction change at the elbow rather than introducing a
        # disconnected circular joint. Blend tangents across its contour.
        blend=max(0,min(1,(p[1]-270)/30))
        u=[elbow[0]-shoulder[0],elbow[1]-shoulder[1]]
        v=[wrist[0]-elbow[0],wrist[1]-elbow[1]]
        ul=math.hypot(*u);vl=math.hypot(*v)
        tangent=[(1-blend)*u[j]/ul+blend*v[j]/vl for j in range(2)]
        length=math.hypot(*tangent)
        return [a[0]+(b[0]-a[0])*t+width*tangent[1]/length,
                a[1]+(b[1]-a[1])*t-width*tangent[0]/length]

    groups=[]
    for original_group in basels[arm_id]['shapes']:
        group=transform_group(original_group,art.matrix(arm_id,basels))
        for shape in group['it']:
            if shape['ty']!='sh': continue
            path=shape['ks']['k'];vertices=path['v']
            mapped=[warp(p) for p in vertices]
            for kind in ['i','o']:
                path[kind]=[[q[j]-mapped[i][j] for j in range(2)]
                    for i,(p,h) in enumerate(zip(vertices,path[kind]))
                    for q in [warp([p[0]+h[0],p[1]+h[1]])]]
            path['v']=mapped
        groups.append(group)
    arm_layer=art.shape_layer(f'Original arm {side} — bent forward',groups,N,200+arm_id)
    arm_layer['ks']['p']=art.keyframes([[0,d,0] for d in depth])
    arm_layers.append(arm_layer)

    # The source hand remains a separate shape; align its wrist with the
    # forearm and let the fingertips meet near the centre of the chest.
    handtip=[src_wrist[0],407]
    targettip=mirror([351,254])
    hm=art.segment(src_wrist,handtip,wrist,targettip)
    groups=[transform_group(g,art.mul(hm,art.matrix(hand_id,basels)))
            for g in basels[hand_id]['shapes']]
    hand_layer=art.shape_layer(f'Original hand {side} — chest height',groups,N,200+hand_id)
    hand_layer['ks']['p']=art.keyframes([[0,d,0] for d in depth])
    arm_layers.insert(0,hand_layer)

# Repose the shorts' central seam so the standing leg lobes do not hang
# between the rotating thigh panels. All other torso paths remain untouched.
seam=layers[1]['shapes'][0]['it'][0]['ks']['k']
seam['v'][4][1]=8
seam['v'][5][1]=3
seam['v'][6][1]=8
for index in [4,5,6]:
    seam['i'][index]=[seam['i'][index][0]*.55,0]
    seam['o'][index]=[seam['o'][index][0]*.55,0]

newlayers=[]
measurements=[]
for index, sign in [(2,-1),(3,1)]:
    outer=art.matrix(index,basels)
    h=art.point(outer,[375.863,323.219])
    knee=art.point(outer,[375.5,449])
    ankle=art.point(outer,[380,568])
    foot=[ankle[0]+sign*28,ankle[1]]
    L1=math.dist(h,knee);L2=math.dist(knee,ankle)
    poses=[]
    for d in depth:
        q=d/MAX_DEPTH
        hip=[h[0],h[1]+d+4]
        # In a front view, the thigh moves toward the camera. Preserve the
        # original transverse widths while allowing longitudinal foreshortening.
        kx=foot[0]-sign*(18-24*q)
        ky=foot[1]-math.sqrt(L2*L2-(foot[0]-kx)**2)
        bend=[kx,ky]
        poses.append((hip,bend,foot))
        measurements.append([math.dist(hip,bend),math.dist(bend,foot)])
    for group_index,layer_id,bone in [(0,1,'thigh'),(1,3,'thigh'),(0,3,'shin')]:
        original_group=leglayers[layer_id]['shapes'][group_index]
        world=art.mul(outer,art.matrix(layer_id,leglayers))
        group=transform_group(original_group,world)
        for shape in group['it']:
            if shape['ty']!='sh':continue
            original_path=shape['ks']['k'];paths=[]
            for hip,bend,foot in poses:
                m=foreshorten(h,knee,hip,bend) if bone=='thigh' else art.segment(knee,ankle,bend,foot)
                path=copy.deepcopy(original_path)
                path['v']=[art.point(m,v) for v in path['v']]
                for kind in ['i','o']:
                    path[kind]=[[m[0]*x+m[2]*y,m[1]*x+m[3]*y] for x,y in path[kind]]
                paths.append(path)
            shape['ks']={'a':1,'k':[{'t':i,'s':[p],'i':{'x':.667,'y':.667},'o':{'x':.333,'y':.333}} for i,p in enumerate(paths)]}
        newlayers.append(art.shape_layer(f'{sign} original {bone} {layer_id}',[group],N,100+len(newlayers)))
    shoe=copy.deepcopy(leglayers[2]);shoe.pop('parent',None)
    m=art.mul(outer,art.matrix(2,leglayers));m[4]+=sign*28
    # Mirrored source leg retains its mirrored shoe and fixed sole position.
    shoe['ks']={'a':art.prop([0,0,0]),'p':art.prop([m[4],m[5],0]),
      'r':art.prop(math.degrees(math.atan2(-m[1] if sign==-1 else m[1],-m[0] if sign==-1 else m[0]))),
      's':art.prop([sign*100,100,100]),'o':art.prop(100)}
    shoe['ind']=100+len(newlayers);newlayers.insert(0,shoe)
comp['layers']=arm_layers+[l for l in comp['layers'] if l['ind'] not in [2,3,6,7,8,9]]+newlayers
# Only the central shorts seam changes; head, torso, shirt and arm art remain original.

assert layers[1]['shapes'][1:]==basels[1]['shapes'][1:]
assert all(abs(shin-L2)<1e-6 for _,shin in measurements)
(OUT/'squat.json').write_text(json.dumps(data,separators=(',',':')),encoding='utf-8')
(OUT/'reference.json').write_text(json.dumps(source,separators=(',',':')),encoding='utf-8')
(OUT/'verification.json').write_text(json.dumps({'head_torso_shapes_unchanged':True,'frames':N,'fixed_feet':True,'perspective':'Front view; thighs foreshorten in depth while contour widths remain unchanged','source':'Jumping Jack by Dinh Bui Xuan','review_only':True},indent=2))
print('Created original-artwork squat candidate:',OUT)


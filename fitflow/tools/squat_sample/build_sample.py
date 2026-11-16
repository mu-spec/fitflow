"""Review-only squat character: connected silhouettes, fixed bone lengths.

No production assets are overwritten. Coordinates are authored in screen space.
"""
import json, math, copy, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'build/squat-sample'
OUT.mkdir(parents=True, exist_ok=True)
sys.path.insert(0,str(ROOT/'tools/orange_character'))
import build_character as original_art
N = 120
SKIN = '#e6bfa3'
SHADE = '#cfaa91'
ORANGE = '#d96622'
DARK = '#303131'

def add(a,b): return (a[0]+b[0],a[1]+b[1])
def mul(a,k): return (a[0]*k,a[1]*k)
def mix(a,b,t): return add(mul(a,1-t),mul(b,t))
def direction(deg):
    a=math.radians(deg)
    return (math.sin(a),-math.cos(a))
def normal(a,b):
    dx,dy=b[0]-a[0],b[1]-a[1];l=math.hypot(dx,dy)
    return (-dy/l,dx/l)
def color(h): return [int(h[i:i+2],16)/255 for i in (1,3,5)]+[1]

def path(points, smooth=0):
    # Catmull-Rom tangents create one continuous rounded outline.
    incoming=[];outgoing=[]
    for i,p in enumerate(points):
        prev=points[(i-1)%len(points)];nxt=points[(i+1)%len(points)]
        tangent=mul((nxt[0]-prev[0],nxt[1]-prev[1]),smooth/6)
        incoming.append(mul(tangent,-1));outgoing.append(tangent)
    return {'v':points,'i':incoming,'o':outgoing,'c':True}

def limb(a,b,ra,rb):
    n=normal(a,b);u=normal((0,0),n)
    # Rounded ends overlap inside the adjoining limb, never outlined as discs.
    pts=[add(a,mul(n,ra)),add(b,mul(n,rb)),add(b,mul(u,-rb)),
         add(b,mul(n,-rb)),add(a,mul(n,-ra)),add(a,mul(u,ra))]
    return path(pts,.7)

def ellipse(c,rx,ry):
    pts=[(c[0]+rx*math.cos(i*math.tau/12),c[1]+ry*math.sin(i*math.tau/12)) for i in range(12)]
    return path(pts,1)

frames=[]
rig_frames=[]
for i in range(N):
    # Slow descent, brief turnaround and smooth ascent; exact looping endpoints.
    phase=i/(N-1)
    q=(1-math.cos(phase*math.tau))/2
    ankle=(335,570)
    knee=add(ankle,mul(direction(25*q),112))
    hip=add(knee,mul(direction(-76*q),120))
    up=direction(28*q)
    shoulder=add(hip,mul(up,132))
    neck=add(shoulder,mul(up,24))
    head=(neck[0]+3,neck[1]-27)
    # Hands extend forward. Slight elbow bend avoids a rigid cutout appearance.
    elbow=add(shoulder,(80,6))
    wrist=add(elbow,(68,-3))
    f={}
    offset=(-8,-3)
    for side,shift,skin in [('far',offset,SHADE),('near',(0,0),SKIN)]:
        a,k,h,s,e,w=[add(p,shift) for p in (ankle,knee,hip,shoulder,elbow,wrist)]
        f[side+' shin']=(limb(k,a,19,11),skin)
        f[side+' thigh']=(limb(mix(h,k,.64),k,22,20),skin)
        hem=mix(h,k,.62)
        n=normal(h,k)
        f[side+' shorts']=(path([add(h,mul(n,25)),add(hem,mul(n,22)),add(hem,mul(n,-22)),add(h,mul(n,-25)),add(h,mul(normal((0,0),n),26))],.35),DARK if side=='near' else '#232626')
        x,y=a
        f[side+' shoe']=(path([(x-15,y-7),(x+4,y-9),(x+15,y+1),(x+35,y+5),(x+37,y+15),(x-17,y+15)],.5),'#303434')
        f[side+' sole']=(path([(x-18,y+12),(x+37,y+12),(x+36,y+17),(x-17,y+17)],.2),'#e87b36')
        if side=='far':
            s=add(shoulder,(4,-3));e=add(elbow,(3,-18));w=add(wrist,(-12,-23))
        f[side+' arm']=(limb(s,e,20,14),skin)
        f[side+' forearm']=(limb(e,w,14,8),skin)
        f[side+' hand']=(path([add(w,(-2,-7)),add(w,(18,-5)),add(w,(29,-1)),add(w,(29,2)),add(w,(16,5)),add(w,(-2,6))],.5),skin)
    # Torso is constructed in its own frame; garment edges stay attached to hips.
    right=(-up[1],up[0])
    def local(x,y): return add(hip,add(mul(right,x),mul(up,y)))
    f['pelvis']=(ellipse(hip,30,20),DARK)
    hem=mix(hip,knee,.62);n=normal(hip,knee)
    back=add(hip,(-34,4));front=add(hip,(30,4))
    pants=path([add(back,(0,-8)),add(back,(-3,24*q)),add(hem,mul(n,27)),add(hem,mul(n,-27)),front,add(front,(0,-8))],.65)
    f['near shorts']=(pants,DARK)
    f['far shorts']=(pants,DARK)
    f['neck']=(limb(add(shoulder,(0,3)),neck,11,10),SKIN)
    f['shirt']=(path([back,local(-35,55),local(-32,116),local(-15,137),local(12,137),local(34,118),local(31,66),front],.45),ORANGE)
    f['shirt side']=(path([back,local(-35,55),local(-32,116),local(-25,117),local(-26,52),add(back,(8,0))],.25),'#c6551d')
    # Profile face has a distinct jaw and a visible neck; it never shares torso transforms.
    hx,hy=head
    face=[(-15,-20),(5,-22),(16,-13),(17,-2),(24,6),(17,9),(16,20),(7,27),(-8,22),(-17,8)]
    f['face']=(path([(hx+x,hy+y) for x,y in face],.35),SKIN)
    hair=[(-17,9),(-23,-4),(-20,-23),(-10,-31),(9,-29),(22,-24),(13,-16),(1,-18),(-7,-9),(-8,5)]
    f['hair']=(path([(hx+x,hy+y) for x,y in hair],.4),'#60412b')
    f['ear']=(ellipse((hx-9,hy+3),5,7),SKIN)
    rig_frames.append({
        'nearShoulder':shoulder,'nearElbow':elbow,'nearWrist':wrist,'nearHand':add(wrist,(27,0)),
        'farShoulder':add(shoulder,(4,-3)),'farElbow':add(elbow,(3,-18)),
        'farWrist':add(wrist,(-12,-23)),'farHand':add(wrist,(15,-23)),
        'nearAnkle':ankle,'nearToe':add(ankle,(30,8)),
        'farAnkle':add(ankle,offset),'farToe':add(add(ankle,offset),(30,8)),
        'head':head})
    frames.append(f)

# Painter order is intentional: far side behind torso; near arm covers sleeve opening.
order=['far shin','far thigh','far shoe','far sole','far arm','far forearm','far hand',
       'near shin','near thigh','near shorts','near shoe','near sole','neck','shirt','shirt side',
       'face','hair','ear','near arm','near forearm','near hand']
layers=[]
for index,name in enumerate(reversed(order)):
    ks={'a':1,'k':[{'t':i,'s':[f[name][0]],'h':1} for i,f in enumerate(frames)]}
    layers.append({'ty':4,'ind':index+1,'nm':name,'ip':0,'op':N,'st':0,
       'ks':{'o':{'a':0,'k':100},'r':{'a':0,'k':0},'p':{'a':0,'k':[0,0,0]},'a':{'a':0,'k':[0,0,0]},'s':{'a':0,'k':[100,100,100]}},
       'shapes':[{'ty':'sh','ks':ks},{'ty':'fl','c':{'a':0,'k':color(frames[0][name][1])},'o':{'a':0,'k':100},'r':1}]})
# Preserve the actual reference contours, colors and muscle details.
source=json.loads((ROOT/'assets/animations/pushup.json').read_text(encoding='utf-8'))
source_layers={l['ind']:l for l in source['assets'][0]['layers']}
def original_layer(index):
    layer=original_art.freeze(copy.deepcopy(source_layers[index]))
    layer.pop('parent',None);layer.update(ind=100+index,ip=0,op=N,st=0)
    base=original_art.matrix(index,source_layers);matrices=[]
    for rig in rig_frames:
        if index==5:
            transform=original_art.rigid([529,504],rig['head'],math.radians(-72),1.1)
        else:
            a,b=original_art.BONES[index]
            transform=original_art.segment(original_art.JOINTS[a],original_art.JOINTS[b],rig[a],rig[b])
        matrices.append(original_art.mul(transform,base))
    layer['ks']={'a':original_art.prop([0,0,0]),
      'p':original_art.keyframes([[m[4],m[5],0] for m in matrices]),
      'r':original_art.keyframes([math.degrees(math.atan2(m[1],m[0])) for m in matrices]),
      's':original_art.keyframes([[math.hypot(m[0],m[1])*100]*2+[100] for m in matrices]),
      'o':original_art.prop(100)}
    return layer
remove={'face','hair','ear','near arm','near forearm','near hand','far arm','far forearm','far hand','near shoe','near sole','far shoe','far sole'}
layers=[l for l in layers if l['nm'] not in remove]
# Lottie paints layers from bottom to top. Head and near arm in front, far arm behind.
layers=[original_layer(i) for i in [1,2,3,4,6,7,5,8]]+layers+[original_layer(i) for i in [19,20,21,22,14]]
data={'v':'5.7.4' ,'fr':30,'ip':0,'op':N,'w':720,'h':720,'nm':'Squat construction sample — review only','ddd':0,'assets':[],'layers':layers}
(OUT/'squat_sample.json').write_text(json.dumps(data,separators=(',',':')),encoding='utf-8')
print('Built review-only 4-second sample:',OUT/'squat_sample.json')

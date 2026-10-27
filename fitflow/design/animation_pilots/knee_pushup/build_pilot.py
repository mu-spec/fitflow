"""Build an isolated review pilot from the licensed Push-Up artwork.
No catalog or runtime mapping is changed. Original assets are never overwritten.
"""
import copy, json, math, hashlib
from pathlib import Path
ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / 'assets/animations/pushup.json'
OUT = Path(__file__).parent / 'knee_pushup_pilot.json'
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest() == '0b9707d916984d464748935502780453d5c552b8595d69dfd4c6501f5d98db97', 'Source artwork changed; review required'
data = json.loads(SOURCE.read_text())
layers = {l['ind']: l for l in data['assets'][0]['layers']}

def value(p):
    return p['k'][0]['s'] if p.get('a') else p['k']

def mul(a,b):
    return [a[0]*b[0]+a[2]*b[1],a[1]*b[0]+a[3]*b[1],a[0]*b[2]+a[2]*b[3],a[1]*b[2]+a[3]*b[3],a[0]*b[4]+a[2]*b[5]+a[4],a[1]*b[4]+a[3]*b[5]+a[5]]
def point(m,p): return [m[0]*p[0]+m[2]*p[1]+m[4],m[1]*p[0]+m[3]*p[1]+m[5]]
def matrix(i):
    l=layers[i];k=l['ks'];p=value(k['p']);a=value(k['a']);s=value(k['s']);r=value(k['r']);r=math.radians(r[0] if isinstance(r,list) else r)
    c=math.cos(r);sn=math.sin(r);m=[c*s[0]/100,sn*s[0]/100,-sn*s[1]/100,c*s[1]/100,0,0]
    m[4]=p[0]-m[0]*a[0]-m[2]*a[1];m[5]=p[1]-m[1]*a[0]-m[3]*a[1]
    return mul(matrix(l['parent']),m) if 'parent' in l else m
original={i:matrix(i) for i in layers}

def freeze(o):
    if isinstance(o,list): return [freeze(v) for v in o]
    if not isinstance(o,dict):return o
    if o.get('a')==1 and isinstance(o.get('k'),list) and o['k'] and isinstance(o['k'][0],dict) and 's' in o['k'][0]:
        s=copy.deepcopy(o['k'][0]['s'])
        o={**o,'a':0,'k':s[0] if len(s)==1 else s}
    return {k:freeze(v) for k,v in o.items()}

def rigid(src,dst,angle,scale=1):
    c=math.cos(angle)*scale;s=math.sin(angle)*scale
    return [c,s,-s,c,dst[0]-c*src[0]+s*src[1],dst[1]-s*src[0]-c*src[1]]
def segment(a,b,c,d):
    ang=math.atan2(d[1]-c[1],d[0]-c[0])-math.atan2(b[1]-a[1],b[0]-a[0])
    return rigid(a,c,ang,math.dist(c,d)/math.dist(a,b))
def elbow(s,w,upper,lower):
    dx=w[0]-s[0];dy=w[1]-s[1];d=math.hypot(dx,dy)
    assert abs(upper-lower)<d<upper+lower, (s,w,d)
    along=(upper*upper-lower*lower+d*d)/(2*d);h=math.sqrt(max(0,upper*upper-along*along))
    # Elbow bends back toward the knees; hands stay planted.
    return [s[0]+dx*along/d-dy*h/d,s[1]+dy*along/d+dx*h/d]

def prop(v):return {'a':0,'k':v}
def keyframes(vals):
    if all(v == vals[0] for v in vals): return prop(vals[0])
    return {'a':1,'k':[{'t':t,'s':v if isinstance(v,list) else [v],**({'o':{'x':.333,'y':.333},'i':{'x':.667,'y':.667}} if t<100 else {})} for t,v in enumerate(vals) if t % 2 == 0]}

new=copy.deepcopy(data);new['nm']='Knee Push-Up — review pilot';new['ip']=0;new['op']=100;new['fr']=25;new['markers']=[]
new['meta']={'source':'https://lottiefiles.com/free-animation/military-push-ups-sFmjfnsBQ9','creator':'Dinh Bui Xuan','license':'Lottie Simple License (FL 9.13.21)','status':'Review pilot; not enabled in app'}
newlayers=[]
identity=[1,0,0,1,0,0]
knee=[250.7,584.91];fixed=[285,660]
shoulders={3:[442.89,524.60],21:[483.92,529.64]}
elbows={3:[439,598],21:[483,588]}
wrists={3:[443.878,673.998],21:[494.88,650.566]}
# Flatten source parenting, preserving its authored layer order and shapes.
for i,source in layers.items():
    l=freeze(copy.deepcopy(source));l.pop('parent',None);l['ip']=0;l['op']=100;l['st']=0
    positions=[];rotations=[];scales=[]
    for t in range(101):
        bend=0 if t <= 2 or t >= 98 else (1-math.cos(2*math.pi*(t-2)/96))/2
        body=rigid(knee,fixed,math.radians(-19+19*bend))
        transform=body
        if i in [1,19,23]: transform=identity
        elif i in [8,13]:
            transform=segment([174.5,603.35],knee,[213,617],fixed)
        elif i in [14,17]:
            transform=segment([218.63,594.23],[286.83,574.36],[250,607],[321.13,649.45])
        elif i in [16,18]:
            transform=rigid([286.83,574.36],[321.13,649.45],math.radians(-19+19*bend))
        elif i in [2,3,4,6,7,20,21,22]:
            arm=3 if i in [2,3,4,6,7] else 21
            a=shoulders[arm];b=elbows[arm];c=wrists[arm]
            newshoulder=point(body,a);ne=elbow(newshoulder,c,math.dist(a,b),math.dist(b,c))
            transform=segment(a,b,newshoulder,ne) if i not in [2,20] else segment(b,c,ne,c)
        m=mul(transform,original[i])
        positions.append([round(m[4],5),round(m[5],5),0])
        rotations.append(round(math.degrees(math.atan2(m[1],m[0])),5))
        scale=math.hypot(m[0],m[1])*100;scales.append([round(scale,5),round(scale,5),100])
    l['ks']={'a':prop([0,0,0]),'p':keyframes(positions),'r':keyframes(rotations),'s':keyframes(scales),'o':prop(100)}
    newlayers.append(l)
new['assets'][0]['layers']=newlayers
# Center the demonstration in its square canvas without cropping the mat.
new['layers'][0]['ks']['p']['k'][1]=62
for l in new['layers']:l['ip']=0;l['op']=100
OUT.write_text(json.dumps(new,separators=(',',':')),encoding='utf-8')
print(OUT,OUT.stat().st_size)



"""Adapt the licensed jump character to a grounded squat; source is immutable."""
import copy,json,math,hashlib
from pathlib import Path
FOLDER=Path(__file__).parent
source=FOLDER/'source.json'
data=json.loads(source.read_text()); layers={l['ind']:l for l in data['assets'][0]['layers']}
def prop(v):return {'a':0,'k':v}
def mix(a,b,t):
 if isinstance(a,dict):return {k:mix(v,b[k],t) for k,v in a.items()}
 if isinstance(a,list):
  assert len(a)==len(b)
  return [mix(x,y,t) for x,y in zip(a,b)]
 if isinstance(a,bool):return a
 if isinstance(a,(float,int)):return a+(b-a)*t
 return a
def component(v):return v[0] if isinstance(v,list) else v
def cubic(a,b,c,d,t):return (1-t)**3*a+3*(1-t)**2*t*b+3*(1-t)*t*t*c+t**3*d
def evaluate(p,t):
 if not p.get('a'):return p['k']
 keys=p['k'];current=keys[0]
 for n,k in enumerate(keys):
  if t<k['t']:break
  current=k
  if n==len(keys)-1:return k.get('s',keys[n-1].get('e',keys[n-1]['s']))
 if t<=keys[0]['t']:return keys[0]['s']
 idx=keys.index(current);nxt=keys[idx+1]
 if current.get('h'):return current['s']
 ratio=(t-current['t'])/(nxt['t']-current['t'])
 out=current.get('o',{'x':.333,'y':.333}); inc=current.get('i',{'x':.667,'y':.667})
 lo,hi=0.,1.
 for _ in range(22):
  mid=(lo+hi)/2
  if cubic(0,component(out['x']),component(inc['x']),1,mid)<ratio:lo=mid
  else:hi=mid
 ease=cubic(0,component(out['y']),component(inc['y']),1,(lo+hi)/2)
 a=current['s'];b=nxt.get('s',current.get('e',a))
 if 'to' in current and isinstance(a,list):
  return [cubic(x,x+current['to'][i],b[i]+current.get('ti',[0]*len(a))[i],b[i],ease) for i,x in enumerate(a)]
 return mix(a,b,ease)
def matrix(i,t):
 l=layers[i];k=l['ks'];p=evaluate(k['p'],t);a=evaluate(k['a'],t);s=evaluate(k['s'],t);r=math.radians(component(evaluate(k.get('r',prop(0)),t)))
 c=math.cos(r);sn=math.sin(r);m=[c*s[0]/100,sn*s[0]/100,-sn*s[1]/100,c*s[1]/100,0,0]
 m[4]=p[0]-m[0]*a[0]-m[2]*a[1];m[5]=p[1]-m[1]*a[0]-m[3]*a[1]
 return mul(matrix(l['parent'],t),m) if 'parent' in l else m
def mul(a,b):return [a[0]*b[0]+a[2]*b[1],a[1]*b[0]+a[3]*b[1],a[0]*b[2]+a[2]*b[3],a[1]*b[2]+a[3]*b[3],a[0]*b[4]+a[2]*b[5]+a[4],a[1]*b[4]+a[3]*b[5]+a[5]]
def point(m,p):return [m[0]*p[0]+m[2]*p[1]+m[4],m[1]*p[0]+m[3]*p[1]+m[5]]
def anchor(i,t):return point(matrix(i,t),evaluate(layers[i]['ks']['a'],t))
def segment(a,b,c,d):
 theta=math.atan2(d[1]-c[1],d[0]-c[0])-math.atan2(b[1]-a[1],b[0]-a[0]);scale=math.dist(c,d)/math.dist(a,b);x=math.cos(theta)*scale;y=math.sin(theta)*scale
 return [x,y,-y,x,c[0]-x*a[0]+y*a[1],c[1]-y*a[0]-x*a[1]]
def bake_props(o,t):
 if isinstance(o,list):return [bake_props(v,t) for v in o]
 if not isinstance(o,dict):return o
 if o.get('a')==1 and 'k' in o:
  value=evaluate(o,t)
  if isinstance(value,list) and len(value)==1:value=value[0]
  return prop(value)
 return {k:bake_props(v,t) for k,v in o.items() if not(k=='x' and isinstance(v,str))}
def keyed(vals):
 if all(v==vals[0] for v in vals):return prop(vals[0])
 return {'a':1,'k':[{'t':i,'s':v if isinstance(v,list) else [v], **({'o':{'x':.333,'y':.333},'i':{'x':.667,'y':.667}} if i<60 else {})} for i,v in enumerate(vals) if i%2==0]}
def combine(samples):
 first=samples[0]
 if isinstance(first,dict):
  if first.get('a')==0 and 'k' in first:return keyed([s['k'] for s in samples])
  return {k:combine([s[k] for s in samples]) for k in first}
 if isinstance(first,list):return [combine([s[i] for s in samples]) for i in range(len(first))]
 return first

# Use the original ascent and descent, but remove vertical takeoff and pin both feet.
fixed_near=anchor(4,0);fixed_far=anchor(2,0)
frames=[]
for frame in range(61):
 progress=1 if frame<=2 or frame>=58 else (1+math.cos(2*math.pi*(frame-2)/56))/2
 t=3+12*progress
 ankle_near=anchor(3,t) if t>=8 else fixed_near
 ankle_far=anchor(1,t) if t>=8 else fixed_far
 # A shared torso translation removes the source's airborne displacement.
 shift=[fixed_near[0]-ankle_near[0],fixed_near[1]-ankle_near[1]]
 frames.append((t,ankle_near,ankle_far,shift))
result=copy.deepcopy(data);result.update(nm='Bodyweight Squat - grounded adaptation',fr=24,ip=0,op=60)
result['layers'][0].pop('tm',None);result['layers'][0]['op']=60
result['meta']={'source':'https://lottiefiles.com/free-animation/jumping-squats-9hzVV8Ohi6','creator':'Dinh Bui Xuan','license':'Lottie Simple License (FL9.13.21)','sourceSha256':hashlib.sha256(source.read_bytes()).hexdigest(),'status':'Grounded adaptation; no jumping phase'}
result_layers=[]
for i,original in layers.items():
 if i in [1,3]:continue # Always use the planted source shoes.
 samples=[];positions=[];rotations=[];scales=[];opacity=[]
 for t,ankle_near,ankle_far,shift in frames:
  layer=copy.deepcopy(original);m=matrix(i,t)
  body=[1,0,0,1,*shift]
  transform=body
  if i in [2,4,33]:m=matrix(i,0);transform=[1,0,0,1,0,0]
  elif i in [5,6,8,9,10,17,18,19,28,29]:
   near=i in [5,6,8,9,10];ankle=ankle_near if near else ankle_far;fixed=fixed_near if near else fixed_far
   hip=anchor(9 if near else 17,t)
   transform=segment(ankle,hip,fixed,[hip[0]+shift[0],hip[1]+shift[1]])
  m=mul(transform,m)
  positions.append([round(m[4],5),round(m[5]-(0 if i==33 else 65),5),0]);rotations.append(round(math.degrees(math.atan2(m[1],m[0])),5));scale=round(math.hypot(m[0],m[1])*100,5);scales.append([scale,scale,100])
  opacity.append(100 if i in [2,4,33] or original['ip']<=t<original['op'] else 0)
  samples.append(bake_props(layer.get('shapes',[]),0 if i in [2,4] else t))
 layer=copy.deepcopy(original);layer.pop('parent',None);layer.update(ip=0,op=60,st=0)
 if 'shapes' in layer:layer['shapes']=combine(samples)
 layer['ks']={'a':prop([0,0,0]),'p':keyed(positions),'r':keyed(rotations),'s':keyed(scales),'o':keyed(opacity)}
 result_layers.append(layer)
result['assets'][0]['layers']=result_layers
(FOLDER/'bodyweight_squat.json').write_text(json.dumps(result,separators=(',',':')))
print('wrote', (FOLDER/'bodyweight_squat.json').stat().st_size)

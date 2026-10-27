"""Licensed character adaptations. No timers or exercise prescriptions are changed."""
import runpy, copy, math, json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
s=runpy.run_path(str(ROOT/'design/animation_pilots/knee_pushup/build_pilot.py'))
for name in ('prop','rigid','point','segment','elbow','freeze','keyframes'):
    globals()[name]=s[name]

def polygon(name, vertices, color):
    return {'ty':'gr','nm':name,'it':[
        {'ty':'sh','ks':prop({'i':[[0,0]]*len(vertices),'o':[[0,0]]*len(vertices),'v':vertices,'c':True})},
        {'ty':'fl','c':prop(color),'o':prop(100),'r':1},
        {'ty':'tr','p':prop([0,0]),'a':prop([0,0]),'s':prop([100,100]),'r':prop(0),'o':prop(100)}]}

def bench(kind):
    if kind=='incline':
        top=[[369,569],[468,509],[529,525],[430,585]]
        face=[[369,569],[430,585],[430,604],[369,588]]
        side=[[430,585],[529,525],[529,544],[430,604]]
        legs=[[[378,588],[393,592],[393,687],[378,687]],[[506,550],[520,546],[520,661],[506,665]]]
    else:
        top=[[113,561],[211,522],[267,541],[170,580]]
        face=[[113,561],[170,580],[170,600],[113,581]]
        side=[[170,580],[267,541],[267,561],[170,600]]
        legs=[[[123,582],[137,587],[137,691],[123,691]],[[244,570],[258,565],[258,655],[244,660]]]
    shapes=[polygon('Support leg',p,[.18,.22,.23,1]) for p in legs]
    shapes += [polygon('Bench face',face,[.25,.31,.32,1]),polygon('Bench side',side,[.31,.38,.39,1]),polygon('Bench top',top,[.43,.53,.54,1])]
    return {'ddd':0,'ind':24,'ty':4,'nm':'Stable bench','sr':1,'ks':{'a':prop([0,0,0]),'p':prop([0,0,0]),'s':prop([100,100,100]),'r':prop(0),'o':prop(100)},'shapes':shapes,'ip':0,'op':100,'st':0}

for kind in ['incline','decline']:
    data=copy.deepcopy(s['data']); data.update(nm=f'{kind.title()} Push-Up',ip=0,op=100,fr=40,markers=[])
    data['meta']={**s['new']['meta'],'status':'Source-derived adaptation; reviewed locally'}
    result=[]
    for i,source in s['layers'].items():
        layer=freeze(copy.deepcopy(source));layer.pop('parent',None);layer.update(ip=0,op=100,st=0)
        positions=[];rotations=[];scales=[]
        for t in range(101):
            bend=0 if t<=2 or t>=98 else (1-math.cos(2*math.pi*(t-2)/96))/2
            angle=(-26+13*bend) if kind=='incline' else (22+8*bend)
            foot=[174.5,603.35 if kind=='incline' else 503.35]
            body=rigid([174.5,603.35],foot,math.radians(angle))
            transform=body
            if i==23: transform=s['identity']
            elif i in [8,14]:transform=rigid([0,0],[0,0 if kind=='incline' else -100],0)
            elif i in [1,19]:
                shift=([-50,-120] if i==1 else [-50,-135]) if kind=='incline' else [0,0]
                transform=rigid([0,0],shift,0)
            elif i in [2,3,4,6,7,20,21,22]:
                arm=3 if i in [2,3,4,6,7] else 21
                a=s['shoulders'][arm];b=s['elbows'][arm];c=s['wrists'][arm]
                shift=([-50,-120] if arm==3 else [-50,-135]) if kind=='incline' else [0,0]
                wrist=[c[0]+shift[0],c[1]+shift[1]]
                shoulder=point(body,a);e=elbow(shoulder,wrist,math.dist(a,b),math.dist(b,c))
                transform=segment(a,b,shoulder,e) if i not in [2,20] else segment(b,c,e,wrist)
            m=s['mul'](transform,s['original'][i]);positions.append([round(m[4],5),round(m[5],5),0]);rotations.append(round(math.degrees(math.atan2(m[1],m[0])),5))
            scale=round(math.hypot(m[0],m[1])*100,5);scales.append([scale,scale,100])
        layer['ks']={'a':prop([0,0,0]),'p':keyframes(positions),'r':keyframes(rotations),'s':keyframes(scales),'o':prop(100)}
        if i==23:result.append(bench(kind))
        result.append(layer)
    data['assets'][0]['layers']=result
    data['layers'][0]['ks']['p']['k'][1]=125
    for layer in data['layers']:layer.update(ip=0,op=100)
    target=Path(__file__).parent/f'pushup_{kind}.json';target.write_text(json.dumps(data,separators=(',',':')))
    print(target,target.stat().st_size)

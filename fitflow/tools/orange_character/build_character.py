"""Retarget the licensed push-up character artwork; authoring only.
The original orange-shirt Lottie stays unchanged. See LICENSE.md.
"""
import argparse, copy, json, math, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/open_exercise_figures'))
from build_demos import load_renderer

SOURCE=ROOT/'assets/animations/pushup.json'
def value(p):
    v=p['k'][0]['s'] if p.get('a') else p['k']
    return v

def prop(v): return {'a':0,'k':v}
def mul(a,b):
    return [a[0]*b[0]+a[2]*b[1],a[1]*b[0]+a[3]*b[1],a[0]*b[2]+a[2]*b[3],a[1]*b[2]+a[3]*b[3],a[0]*b[4]+a[2]*b[5]+a[4],a[1]*b[4]+a[3]*b[5]+a[5]]
def point(m,p):return [m[0]*p[0]+m[2]*p[1]+m[4],m[1]*p[0]+m[3]*p[1]+m[5]]
def matrix(i,layers):
    l=layers[i];k=l['ks'];p=value(k['p']);a=value(k['a']);s=value(k['s']);r=value(k['r']);r=math.radians(r[0] if isinstance(r,list) else r)
    c=math.cos(r);sn=math.sin(r);m=[c*s[0]/100,sn*s[0]/100,-sn*s[1]/100,c*s[1]/100,0,0]
    m[4]=p[0]-m[0]*a[0]-m[2]*a[1];m[5]=p[1]-m[1]*a[0]-m[3]*a[1]
    return mul(matrix(l['parent'],layers),m) if 'parent' in l else m

def freeze(o):
    if isinstance(o,list):return [freeze(v) for v in o]
    if not isinstance(o,dict):return o
    if o.get('a')==1 and isinstance(o.get('k'),list) and o['k'] and isinstance(o['k'][0],dict) and 's' in o['k'][0]:
        s=copy.deepcopy(o['k'][0]['s']);o={**o,'a':0,'k':s[0] if len(s)==1 else s}
    return {k:freeze(v) for k,v in o.items()}
def rigid(src,dst,angle,scale=1):
    c=math.cos(angle)*scale;s=math.sin(angle)*scale
    return [c,s,-s,c,dst[0]-c*src[0]+s*src[1],dst[1]-s*src[0]-c*src[1]]
def segment(a,b,c,d):
    return rigid(a,c,math.atan2(d[1]-c[1],d[0]-c[0])-math.atan2(b[1]-a[1],b[0]-a[0]),math.dist(c,d)/math.dist(a,b))
def keyframes(vals):
    if all(v==vals[0] for v in vals):return prop(vals[0])
    return {'a':1,'k':[{'t':i,'s':v if isinstance(v,list) else [v], 'o':{'x':.333,'y':.333},'i':{'x':.667,'y':.667}} for i,v in enumerate(vals)]}
def polygon(name,vs,color):
    return {'ty':'gr','nm':name,'it':[{'ty':'sh','ks':prop({'i':[[0,0]]*len(vs),'o':[[0,0]]*len(vs),'v':vs,'c':True})},{'ty':'fl','c':prop(color),'o':prop(100),'r':1},{'ty':'tr','p':prop([0,0]),'a':prop([0,0]),'s':prop([100,100]),'r':prop(0),'o':prop(100)}]}
def shape_layer(name,shapes,n,ind):
    return {'ty':4,'ind':ind,'nm':name,'sr':1,'ip':0,'op':n,'st':0,'ks':{'a':prop([0,0,0]),'p':prop([0,0,0]),'s':prop([100,100,100]),'r':prop(0),'o':prop(100)},'shapes':shapes}

JOINTS={'nearHip':[341,550],'farHip':[375,541], 'nearKnee':[250.7,584.91],'farKnee':[286.83,574.36], 'nearAnkle':[174.5,603.35],'farAnkle':[218.63,594.23], 'nearShoulder':[442.89,524.60],'farShoulder':[483.92,529.64], 'nearElbow':[439,598],'farElbow':[483,588], 'nearWrist':[443.878,673.998],'farWrist':[494.88,650.566], 'nearHand':[469,678],'farHand':[520,655], 'nearToe':[182,641],'farToe':[228,630]}
BONES={1:('nearWrist','nearHand'),2:('nearElbow','nearWrist'),3:('nearShoulder','nearElbow'),4:('nearShoulder','nearElbow'),6:('nearShoulder','nearElbow'),7:('nearShoulder','nearElbow'),8:('nearAnkle','nearToe'),12:('nearHip','nearKnee'),13:('nearKnee','nearAnkle'),14:('farAnkle','farToe'),15:('nearHip','nearKnee'),16:('farHip','farKnee'),17:('farKnee','farAnkle'),18:('farHip','farKnee'),19:('farWrist','farHand'),20:('farElbow','farWrist'),21:('farShoulder','farElbow'),22:('farShoulder','farElbow')}

def build(name,fig,poses,render,out):
    src=json.loads(SOURCE.read_text(encoding='utf-8'));layers={l['ind']:l for l in src['assets'][0]['layers']}
    original={i:matrix(i,layers) for i in layers}
    n=len(poses);allj=[dict(render.pose_joints(fig,p)) for p in poses]
    if not fig.get('topDown'):
        for j in allj:
            # The source face includes the jaw, but not the neck. Give it its
            # own anatomical clearance rather than burying it in the shirt.
            sh=j['shoulder']; hd=j['head']; length=math.dist(sh,hd)
            if length:
                j['head']=(sh[0]+(hd[0]-sh[0])*.29/length,
                           sh[1]+(hd[1]-sh[1])*.29/length)
    # One fixed camera, generous full-body margin including the wall.
    xs=[x for j in allj for x,y in j.values()];ys=[y for j in allj for x,y in j.values()]
    left=min(xs)-.25;right=max(xs)+.3;bottom=min(0,min(ys))-.15;top=max(ys)+.25
    scale=min(620/(right-left),600/(top-bottom))
    def project(p):return [360+(p[0]-(left+right)/2)*scale,360-(p[1]-(top+bottom)/2)*scale]
    transforms=[]
    for j in allj:
        target={k:project(v) for k,v in j.items()}
        # Slight perspective separation preserves the original layered silhouette.
        for k in list(target):
            if k.startswith('far') and fig['view']=='side':
                target[k][0]+=.045*scale;target[k][1]-=.015*scale
        # Garment landmarks are not the near-side arm and leg pivots. Using
        # those old pivots made the shirt climb behind the head during squats.
        body=segment([375,550],[475,520],target['nearHip'],target['nearShoulder'])
        if fig.get('topDown'):
            body=segment([375,550],[475,520],target['hip'],target['shoulder'])
        ts={}
        for i in layers:
            if i==23:continue
            if i in BONES:
                a,b=BONES[i];ts[i]=segment(JOINTS[a],JOINTS[b],target[a],target[b])
            elif i in [9,10]:
                ts[i]=segment([475,520],[529,504],target['shoulder'],target['head'])
            elif i==5:
                sh=target['shoulder'];hd=target['head']
                angle=math.atan2(hd[1]-sh[1],hd[0]-sh[0])-math.atan2(-20,54)
                sc=scale*.0038
                ts[i]=rigid([529,504],target['head'],angle,sc)
            else:ts[i]=body
        transforms.append(ts)
    result=[]
    for i,l in layers.items():
        if i in [12,16,23]:continue
        layer=freeze(copy.deepcopy(l));layer.pop('parent',None);layer.update(ip=0,op=n,st=0)
        ms=[mul(t[i],original[i]) for t in transforms]
        angles=[math.degrees(math.atan2(m[1],m[0])) for m in ms]
        for t in range(1,n):
            while angles[t]-angles[t-1]>180:angles[t]-=360
            while angles[t]-angles[t-1]<-180:angles[t]+=360
        layer['ks']={'a':prop([0,0,0]),'p':keyframes([[round(m[4],4),round(m[5],4),0] for m in ms]),'r':keyframes(angles),'s':keyframes([[math.hypot(m[0],m[1])*100]*2+[100] for m in ms]),'o':prop(100)}
        result.append(layer)
    # The original shorts were drawn for a straight push-up. Rotating that
    # entire outline at the hip creates a pointed flap in bent-leg positions.
    # Continuous rounded garment silhouettes keep both hips covered instead.
    for side,ind in [('near',12),('far',16)]:
        paths=[]
        for j in allj:
            h=project(j[side+'Hip']);k=project(j[side+'Knee'])
            if side=='far' and fig['view']=='side':
                h=[h[0]+.045*scale,h[1]-.015*scale]
                k=[k[0]+.045*scale,k[1]-.015*scale]
            dx=k[0]-h[0];dy=k[1]-h[1];length=math.hypot(dx,dy)
            ux,uy=dx/length,dy/length;vx,vy=-uy,ux
            def p(along,across):return [h[0]+ux*along+vx*across,h[1]+uy*along+vy*across]
            radius=.115*scale;hem=length*.63
            vs=[p(-radius,0),p(-radius*.65,radius*.8),p(hem,radius*.78),
                p(hem+radius*.12,0),p(hem,-radius*.78),p(-radius*.65,-radius*.8)]
            tangents=[]
            for ix in range(len(vs)):
                before=vs[(ix-1)%len(vs)];after=vs[(ix+1)%len(vs)]
                tangents.append([(after[0]-before[0])*.10,(after[1]-before[1])*.10])
            paths.append({'v':vs,'i':[[-x,-y] for x,y in tangents],'o':tangents,'c':True})
        sh=polygon(side+' rounded shorts',paths[0]['v'],[.19,.19,.19,1] if side=='near' else [.13,.13,.13,1])
        sh['it'][0]['ks']={'a':1,'k':[{'t':k,'s':[v],'i':{'x':.667,'y':.667},'o':{'x':.333,'y':.333}} for k,v in enumerate(paths)]}
        layer=shape_layer(side+' connected hip garment',[sh],n,ind)
        # In front of thigh skin, behind the shirt.
        insertion=next(ix for ix,l in enumerate(result) if l['ind']==(15 if side=='near' else 18))
        result.insert(insertion,layer)
    floor=project((0,0))[1]
    shapes=[polygon('Exercise mat',[[60,floor],[620,floor],[660,floor+18],[85,floor+18]],[.34,.70,.76,1])]
    if fig.get('topDown'):
        shapes=[polygon('Mat viewed from above',[[35,40],[685,40],[685,680],[35,680]],[.66,.85,.86,1])]
        # Back of the head makes the prone/top-view orientation unambiguous.
        head=next(l for l in result if l['ind']==5)
        head['ks']={'a':prop([0,0,0]),'p':keyframes([project(j['head'])+[0] for j in allj]),'s':prop([100,100,100]),'r':prop(0),'o':prop(100)}
        head['shapes']=[{'ty':'el','p':prop([0,0]),'s':prop([.21*scale,.18*scale])},{'ty':'fl','c':prop([.30,.18,.10,1]),'o':prop(100),'r':1}]
    if fig.get('spineCurve'):
        shirt=next(l for l in result if l['ind']==11)
        paths=[]
        for k,j in enumerate(allj):
            h=project(j['hip']);sh=project(j['shoulder']);q=(1-math.cos(k/(n-1)*math.tau))/2
            vs=[[h[0],h[1]-.08*scale],[(h[0]+sh[0])/2,h[1]+(.04-.22*q)*scale],[sh[0],sh[1]-.08*scale],[sh[0],sh[1]+.10*scale],[(h[0]+sh[0])/2,h[1]+(.20-.14*q)*scale],[h[0],h[1]+.10*scale]]
            tangents=[[0,0],[-.10*scale,0],[0,0],[0,0],[.10*scale,0],[0,0]]
            paths.append({'v':vs,'i':tangents,'o':[[-x,-y] for x,y in tangents],'c':True})
        shirt['ks']={'a':prop([0,0,0]),'p':prop([0,0,0]),'s':prop([100,100,100]),'r':prop(0),'o':prop(100)}
        shirt['shapes']=[{'ty':'sh','ks':{'a':1,'k':[{'t':k,'s':[v],'i':{'x':.667,'y':.667},'o':{'x':.333,'y':.333}} for k,v in enumerate(paths)]}} ,{'ty':'fl','c':prop([.86,.32,.10,1]),'o':prop(100),'r':1}]

    if name=='pushup_wall':
        x=project((.84,0))[0]
        shapes.append(polygon('Wall',[[x,project((0,1.8))[1]],[x+12,project((0,1.8))[1]],[x+12,floor],[x,floor]],[.43,.53,.54,1]))
    for support in fig.get('supports', []):
        x,y,w,h=support['rect']
        vs=[project((x,y)),project((x+w,y)),project((x+w,y+h)),project((x,y+h))]
        shapes.append(polygon(support['name'],vs,support.get('color',[.35,.43,.51,1])))
    result.append(shape_layer('Support',shapes,n,30))
    data={'v':'5.7.4','fr':n/fig.get('seconds',4),'ip':0,'op':n,'w':720,'h':720,'nm':name+' — licensed orange character','ddd':0,'assets':[],'layers':result,'meta':{'source':'Military Push Ups by Dinh Bui Xuan','license':'Lottie Simple License (FL 9.13.21)','adaptation':'Original character artwork retargeted to exercise-specific poses'}}
    out.mkdir(parents=True,exist_ok=True);(out/f'{name}.json').write_text(json.dumps(data,separators=(',',':')),encoding='utf-8')

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--renderer',type=Path,required=True);parser.add_argument('--output',type=Path,required=True);args=parser.parse_args()
    render=load_renderer(args.renderer)
    fig=json.loads((ROOT/'tools/open_exercise_figures/pushup_wall.json').read_text())
    build('pushup_wall',fig,fig['poses'],render,args.output)

"""Glute Bridge review: repose original artwork, never redraw muscle contours."""
import copy, hashlib, json, math
import build_press_review as press
import build_plank_review as plank
art=press.art
ROOT=press.ROOT
OUT=ROOT/'build/next-pair-review'
OUT.mkdir(parents=True,exist_ok=True)
N=80
J=press.J
before={p.name:hashlib.sha256(p.read_bytes()).hexdigest()
        for p in (ROOT/'assets/animations/launch25').iterdir() if p.suffix in ('.json','.png')}
waist=J['nearHip']
# Pivot inside the overlapping source thigh/calf contours, not their outer cap.
source_knee=[272,584]
thigh_length=math.dist(waist,J['nearKnee'])
shin_length=math.dist(source_knee,J['nearAnkle'])
source_axis=math.atan2(-30,100)
# Reuse original near-side limb pieces at their original size on the far side.
# A small perspective offset separates them, without stretching the artwork.
source_ids={14:8,16:12,17:13,18:15,19:1,20:2,21:3,22:4}
arm_ids={2,3,4,20,21,22}
source_layers={i:copy.deepcopy((plank.bent_layers if i in arm_ids else press.layers)[source_ids.get(i,i)])
               for i in press.layers if i!=23}
source_world={i:(plank.bent_world if i in arm_ids else press.original)[source_ids.get(i,i)]
              for i in source_layers}
source_layers[24]=copy.deepcopy(source_layers[12])
source_world[24]=source_world[12]

def smooth(t):
    t=max(0,min(1,t));return t*t*(3-2*t)
def knee_forward(hip,ankle):
    k=press.ik(hip,ankle,thigh_length,shin_length)
    d=[ankle[j]-hip[j] for j in range(2)]
    u=sum((k[j]-hip[j])*d[j] for j in range(2))/sum(x*x for x in d)
    mirror=[2*(hip[j]+u*d[j])-k[j] for j in range(2)]
    return max([k,mirror],key=lambda p:p[0])

def build(name):
    lunge=name=='lunge_reverse'
    N=160 if lunge else 80
    seconds=5.36 if lunge else 2.68
    transforms=[]
    for frame in range(N):
        t=(frame%80)/79
        if lunge:
            step=smooth(t/.18) if t<.18 else (1-smooth((t-.82)/.18) if t>.82 else 1)
            depth=smooth((t-.18)/.30) if t<.48 else (1-smooth((t-.58)/.24) if t>.58 else 1)
            hip=[310-40*step-30*depth,417+40*step+53*depth]
            body=art.rigid(J['nearHip'],hip,math.radians(-76))
        else:
            q=(1-math.cos(math.tau*t))/2
            hip=[300+35*q,435+20*q]
            body=art.rigid(J['nearHip'],hip,math.radians(60+8*q))
        ts={i:body for i in source_layers}
        for side in ['near','far']:
            far=side=='far';dx,dy=(8,-6) if far else (0,0)
            h=[hip[0]+dx,hip[1]+dy]
            if lunge:
                back=far if frame<80 else not far
                ankle=[335+dx-(185*step if back else 0),610+dy-(12*step+12*math.sin(math.pi*step) if back else 0)]
                shoe_angle=math.radians(-62+(35*step if back else 0))
            else:
                ankle=[240+dx,620+dy];shoe_angle=math.radians(-62)
            knee=knee_forward(h,ankle)
            thigh=art.segment(J['nearHip'],J['nearKnee'],h,knee)
            calf=art.segment(source_knee,J['nearAnkle'],knee,ankle)
            for i in ([16,18] if far else [12,15]):ts[i]=thigh
            ts[17 if far else 13]=calf
            ts[14 if far else 8]=art.rigid(J['nearAnkle'],ankle,shoe_angle)
            sh=art.point(body,J['nearShoulder']);sh=[sh[0]+dx,sh[1]+dy]
            src_sh=art.point(plank.bent_world[4],art.value(plank.bent_layers[4]['ks']['a']))
            src_el=[414,617];src_wr=J['nearWrist'];src_palm=J['nearHand']
            l1=math.dist(src_sh,src_el);l2=math.dist(src_el,src_wr)
            if lunge:
                palm=[hip[0]+dx+2,hip[1]+dy-10]
                lh=math.dist(src_wr,src_palm)
                el=press.ik(sh,palm,l1,l2+lh)
                wrist=[el[j]+(palm[j]-el[j])*l2/(l2+lh) for j in range(2)]
                angle=math.atan2(palm[1]-wrist[1],palm[0]-wrist[0])-math.atan2(src_palm[1]-src_wr[1],src_palm[0]-src_wr[0])
            else:
                wrist=[382+dx,648+dy]
                el=press.ik(sh,wrist,l1,l2)
                angle=0
            for i in ([21,22] if far else [3,4]):ts[i]=art.segment(src_sh,src_el,sh,el)
            ts[20 if far else 2]=art.segment(src_el,src_wr,el,wrist)
            ts[19 if far else 1]=art.rigid(src_wr,wrist,angle)
        transforms.append(ts)
    result=[]
    for i,source in source_layers.items():
        layer=art.freeze(copy.deepcopy(source));layer.pop('parent',None)
        layer.update(ind=i,ip=0,op=N,st=0,sr=1)
        ms=[art.mul(ts[i],source_world[i]) for ts in transforms]
        angles=[math.degrees(math.atan2(m[1],m[0])) for m in ms]
        for f in range(1,N):
            while angles[f]-angles[f-1]>180:angles[f]-=360
            while angles[f]-angles[f-1]<-180:angles[f]+=360
        layer['ks']=dict(a=art.prop([0,0,0]),p=art.keyframes([[m[4],m[5],0] for m in ms]),
            r=art.keyframes(angles),s=art.keyframes([[math.hypot(m[0],m[1])*100]*2+[100] for m in ms]),o=art.prop(100))
        assert layer['shapes']==art.freeze(copy.deepcopy(source))['shapes']
        # All pose operations are rigid, so body parts keep their original size.
        assert all(abs(math.hypot(t[i][0],t[i][1])-1)<1e-6 for t in transforms)
        # Clip two copies of the same original shorts artwork into overlapping
        # pelvis/thigh regions. Original path geometry and colors stay unchanged.
        if i in [12,16,24]:
            m=source_world[i]; det=m[0]*m[3]-m[1]*m[2]
            def local(x,y):
                x-=m[4];y-=m[5]
                return [(m[3]*x-m[2]*y)/det,(-m[1]*x+m[0]*y)/det]
            # Rounded overlap masks hide the cut edges of the unchanged
            # source shorts as the pelvis and thigh articulate independently.
            u=[100,-30] if i==24 else [J['nearKnee'][j]-J['nearHip'][j] for j in range(2)]
            length=math.hypot(*u);u=[v/length for v in u];normal=[-u[1],u[0]]
            # In the inverted pike pose a large round root cap projects above
            # the waist like a separate hump. Keep only the joint overlap.
            radius=29 if lunge else 22
            root=J['nearHip'] if lunge else [J['nearHip'][j]+18*u[j] for j in range(2)]
            def pos(a,b):return [root[j]+a*u[j]+b*normal[j] for j in range(2)]
            ps=[pos(0,-radius),pos(-radius,0),pos(0,radius),pos(220,radius),pos(220,-radius)]
            def tangent(a,b):
                return [(m[3]*(a*u[0]+b*normal[0])-m[2]*(a*u[1]+b*normal[1]))/det,
                        (-m[1]*(a*u[0]+b*normal[0])+m[0]*(a*u[1]+b*normal[1]))/det]
            k=radius*.55228475
            ins=[tangent(0,0),tangent(0,-k),tangent(-k,0),[0,0],[0,0]]
            outs=[tangent(-k,0),tangent(0,k),[0,0],[0,0],[0,0]]
            layer['masksProperties']=[dict(inv=False,mode='a',o=art.prop(100),
                pt=art.prop(dict(v=[local(*v) for v in ps],i=ins,o=outs,c=True)),x=art.prop(0))]
            layer['hasMask']=True
        result.append(layer)
    pelvis=result.pop()
    result.insert(next(i for i,l in enumerate(result) if l['ind']==12),pelvis)

    result.append(art.shape_layer('Mat',[art.polygon('Mat',[[100,630],[530,630],[560,700],[120,700]],[.34,.70,.76,1])],N,30))
    camera=dict(a=art.prop([330,450 if lunge else 550,0]),p=art.prop([360,360,0]),s=art.prop([115,115,100]),r=art.prop(0),o=art.prop(100))
    data=dict(v=press.source['v'],fr=N/seconds,ip=0,op=N,w=720,h=720,ddd=0,nm=name+' review only',assets=[dict(id='motion',layers=result)],layers=[dict(ty=0,ind=1,refId='motion',ip=0,op=N,st=0,sr=1,w=720,h=720,ks=camera)],meta=dict(source='Military Push Ups by Dinh Bui Xuan',license='Lottie Simple License (FL 9.13.21)',review_only=True,source_contours_preserved=True,source_part_sizes_preserved=True,repetitions_per_loop=2 if lunge else 1))
    press.split_positions(data)
    (OUT/(name+'.json')).write_text(json.dumps(data,separators=(',',':')))
    print(name,'candidate saved')
for name in ['lunge_reverse','pushup_pike']:build(name)
assert all(hashlib.sha256((ROOT/'assets/animations/launch25'/p).read_bytes()).hexdigest()==h for p,h in before.items())


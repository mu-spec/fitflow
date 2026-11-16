"""Glute Bridge review: repose original artwork, never redraw muscle contours."""
import copy, hashlib, json, math
import build_press_review as press
import build_plank_review as plank
art=press.art
ROOT=press.ROOT
OUT=ROOT/'build/row-bird-review'
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
    bird=name=='bird_dog'
    lunge=True # same source-preserving round clothing overlaps for both
    N=160 if bird else 80
    seconds=5.36 if bird else 2.68
    transforms=[]
    for frame in range(N):
        t=(frame%80)/79
        q=(1-math.cos(math.tau*t))/2
        if bird:
            q=smooth(t/.38) if t<.38 else (1-smooth((t-.58)/.42) if t>.58 else 1)
            body=art.rigid(J['nearHip'],[280,490],math.radians(-5))
        else:
            start=math.atan2(J['nearShoulder'][1]-J['nearAnkle'][1],J['nearShoulder'][0]-J['nearAnkle'][0])
            body=art.rigid(J['nearAnkle'],[290,620],math.radians(-110+16*q)-start)
        ts={i:body for i in source_layers}
        for side in ['near','far']:
            far=side=='far';dx,dy=((14,-8) if bird else (8,-6)) if far else (0,0)
            hip=art.point(body,J['nearHip']);hip=[hip[0]+dx,hip[1]+dy]
            sh=art.point(body,J['nearShoulder']);sh=[sh[0]+dx,sh[1]+dy]
            if bird:
                reaching_arm=not far if frame<80 else far
                reaching_leg=not reaching_arm
                u=[math.cos(math.radians(-19)),math.sin(math.radians(-19))]
                base_ankle=[hip[0]-shin_length,hip[1]+thigh_length]
                end_ankle=[hip[j]-u[j]*(thigh_length+shin_length-1) for j in range(2)]
                reach=q if reaching_leg else 0
                ankle=[base_ankle[j]+reach*(end_ankle[j]-base_ankle[j]) for j in range(2)]
                knee=knee_forward(hip,ankle)
                thigh=art.segment(J['nearHip'],J['nearKnee'],hip,knee)
                calf=art.segment(source_knee,J['nearAnkle'],knee,ankle)
                for i in ([16,18] if far else [12,15]):ts[i]=thigh
                ts[17 if far else 13]=calf
                # Preserve the source ankle/shoe relationship as the shin
                # rotates; a fixed quarter-turn made the shoes look inverted.
                ts[14 if far else 8]=calf
            else:
                for i in ([16,18,17] if far else [12,15,13]):
                    ts[i]=art.mul(art.rigid([0,0],[dx,dy],0),body)
                if far:ts[16]=body
                ts[14 if far else 8]=art.rigid(J['nearAnkle'],[290+dx,620+dy],math.radians(-62))
            src_sh=art.point(plank.bent_world[4],art.value(plank.bent_layers[4]['ks']['a']))
            src_el=[414,617];src_wr=J['nearWrist']
            l1=math.dist(src_sh,src_el);l2=math.dist(src_el,src_wr)
            if bird:
                start_wr=[sh[0]+10,sh[1]+136]
                end_wr=[sh[j]+u[j]*(l1+l2-1) for j in range(2)]
                reach=q if reaching_arm else 0
                wrist=[start_wr[j]+reach*(end_wr[j]-start_wr[j]) for j in range(2)]
                hand_angle=math.radians(-28)*reach
            else:
                wrist=[325+dx,375+dy];hand_angle=math.radians(-15)
            el=press.ik(sh,wrist,l1,l2)
            for i in ([21,22] if far else [3,4]):ts[i]=art.segment(src_sh,src_el,sh,el)
            ts[20 if far else 2]=art.segment(src_el,src_wr,el,wrist)
            ts[19 if far else 1]=art.rigid(src_wr,wrist,hand_angle)
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


    result.append(art.shape_layer('Mat',[art.polygon('Mat',[[60,600],[590,600],[670,680],[80,680]],[.34,.70,.76,1])],N,30))
    if not bird:
        # Structural jambs overlap the unchanged fingers, showing the palms
        # around a fixed edge rather than pressing against a flat wall.
        jamb=art.shape_layer('Fixed doorway jambs',[
            art.polygon('Structural jamb',[[347,200],[382,200],[382,655],[347,655]],[.58,.66,.69,1]),
            art.polygon('Jamb depth',[[374,200],[382,200],[382,655],[374,655]],[.69,.75,.77,1]),
            art.polygon('Lintel',[[347,200],[450,200],[450,222],[347,222]],[.58,.66,.69,1])],N,31)
        result.insert(0,jamb)
    camera=dict(a=art.prop([330,510 if bird else 440,0]),p=art.prop([360,360,0]),s=art.prop([100,100,100] if bird else [110,110,100]),r=art.prop(0),o=art.prop(100))
    data=dict(v=press.source['v'],fr=N/seconds,ip=0,op=N,w=720,h=720,ddd=0,nm=name+' review only',assets=[dict(id='motion',layers=result)],layers=[dict(ty=0,ind=1,refId='motion',ip=0,op=N,st=0,sr=1,w=720,h=720,ks=camera)],meta=dict(source='Military Push Ups by Dinh Bui Xuan',license='Lottie Simple License (FL 9.13.21)',review_only=True,source_contours_preserved=True,source_part_sizes_preserved=True,repetitions_per_loop=2 if bird else 1))
    press.split_positions(data)
    (OUT/(name+'.json')).write_text(json.dumps(data,separators=(',',':')))
    print(name,'candidate saved')
for name in ['row_doorway','bird_dog']:build(name)
assert all(hashlib.sha256((ROOT/'assets/animations/launch25'/p).read_bytes()).hexdigest()==h for p,h in before.items())

"""Glute Bridge review: repose original artwork, never redraw muscle contours."""
import copy, hashlib, json, math
import build_press_review as press
import build_plank_review as plank
art=press.art
ROOT=press.ROOT
OUT=ROOT/'build/final-three-review'
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
    N=160 if name=='dead_bug' else 80
    seconds=5.36 if name=='dead_bug' else 2.68
    lunge=True
    transforms=[]
    bends=[]
    for frame in range(N):
        t=(frame%80)/79
        q=(1-math.cos(math.tau*t))/2
        if name=='dead_bug':
            body=art.rigid(J['nearShoulder'],[245,595],math.radians(194))
        elif name=='cat_cow':
            body=art.rigid(J['nearHip'],[280,490],math.radians(-7))
        else:
            body=art.rigid(J['nearHip'],[300,530],math.radians(14))
        ts={i:body for i in source_layers}
        bends.append(-15*math.sin(math.tau*frame/(N-1)) if name=='cat_cow' else 0)
        if name=='cat_cow':
            neck=art.point(body,J['nearShoulder'])
            follow=art.rigid(neck,neck,math.radians(12*math.sin(math.tau*frame/(N-1))))
            for i in [5,9,10]:ts[i]=art.mul(follow,body)
        for far in [False,True]:
            dx,dy=(10,-9) if far else (0,0)
            hip=art.point(body,J['nearHip']);hip=[hip[0]+dx,hip[1]+dy]
            sh=art.point(body,J['nearShoulder']);sh=[sh[0]+dx,sh[1]+dy]
            if name=='dead_bug':
                reaching_arm=(not far) if frame<80 else far
                reach=q if not reaching_arm else 0
                knee=[hip[0]+thigh_length*math.sin(reach*1.35),hip[1]-thigh_length*math.cos(reach*1.35)]
                angle=reach*.15
                ankle=[knee[0]+shin_length*math.cos(angle),knee[1]+shin_length*math.sin(angle)]
            elif name=='cat_cow':
                knee=[hip[0],hip[1]+thigh_length]
                ankle=[knee[0]-shin_length,knee[1]]
            else:
                # Prone legs remain grounded and still.
                knee=[hip[0]-thigh_length,hip[1]]
                ankle=[knee[0]-shin_length,knee[1]]
            thigh=art.segment(J['nearHip'],J['nearKnee'],hip,knee)
            calf=art.segment(source_knee,J['nearAnkle'],knee,ankle)
            for i in ([16,18] if far else [12,15]):ts[i]=thigh
            ts[17 if far else 13]=calf
            ts[14 if far else 8]=art.mul(art.rigid(ankle,ankle,math.radians(80)),calf) if name=='reverse_snow_angel' else calf
            src_sh=art.point(plank.bent_world[4],art.value(plank.bent_layers[4]['ks']['a']))
            src_el=[414,617];src_wr=J['nearWrist']
            l1=math.dist(src_sh,src_el);l2=math.dist(src_el,src_wr)
            if name=='dead_bug':
                angle=math.radians(-90-85*(q if reaching_arm else 0))
                wrist=[sh[0]+(l1+l2-1)*math.cos(angle),sh[1]+(l1+l2-1)*math.sin(angle)]
            elif name=='cat_cow':
                wrist=[sh[0]+6,hip[1]+thigh_length]
            else:
                # Oblique view: both arms sweep away from the ribs, toward
                # overhead, with opposite screen-side arcs and fixed torso.
                angle=math.pi*(1-q)*(1 if not far else -1)
                wrist=[sh[0]+(l1+l2-1)*math.cos(angle),sh[1]+(l1+l2-1)*math.sin(angle)]
            el=press.ik(sh,wrist,l1,l2)
            for i in ([21,22] if far else [3,4]):ts[i]=art.segment(src_sh,src_el,sh,el)
            ts[20 if far else 2]=art.segment(src_el,src_wr,el,wrist)
            hand_angle=0 if name=='cat_cow' else math.atan2(wrist[1]-el[1],wrist[0]-el[0])-math.atan2(J['nearHand'][1]-src_wr[1],J['nearHand'][0]-src_wr[0])
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


    if name=='cat_cow':
        # Bend only the original shirt outline gently between fixed hip and
        # shoulder endpoints. Limbs, muscles, shoes and head retain source paths.
        shirt=next(l for l in result if l['ind']==11)
        def deform(items,parent):
            tr=next((v for v in items if v.get('ty')=='tr'),None)
            world=art.mul(parent,art.matrix(0,{0:{'ks':tr}})) if tr else parent
            a,b,c,d,e,f=world;det=a*d-b*c
            def inv(p):
                x,y=p[0]-e,p[1]-f
                return [(d*x-c*y)/det,(-b*x+a*y)/det]
            def warp(p,amount):
                w=art.point(world,p)
                u=max(0,min(1,(w[0]-J['nearHip'][0])/(J['nearShoulder'][0]-J['nearHip'][0])))
                w[1]+=amount*math.sin(math.pi*u)
                return inv(w)
            for item in items:
                if item.get('ty')=='gr':deform(item['it'],world)
                if item.get('ty')=='sh':
                    source=art.value(item['ks']);keys=[]
                    for frame,amount in enumerate(bends):
                        path=copy.deepcopy(source)
                        for j,v in enumerate(source['v']):
                            nv=warp(v,amount);path['v'][j]=nv
                            for key in ['i','o']:
                                p=warp([v[k]+source[key][j][k] for k in range(2)],amount)
                                path[key][j]=[p[k]-nv[k] for k in range(2)]
                        keys.append({'t':frame,'s':[path],'o':{'x':.333,'y':.333},'i':{'x':.667,'y':.667}})
                    item['ks']={'a':1,'k':keys}
        deform(shirt['shapes'],source_world[11])
    floor=600 if name=='cat_cow' else (635 if name=='dead_bug' else 550)
    result.append(art.shape_layer('Mat',[art.polygon('Mat',[[30,floor],[630,floor],[690,floor+85],[50,floor+85]],[.34,.70,.76,1])],N,30))
    camera=dict(a=art.prop([330,500,0]),p=art.prop([360,360,0]),s=art.prop([100,100,100]),r=art.prop(0),o=art.prop(100))
    data=dict(v=press.source['v'],fr=N/seconds,ip=0,op=N,w=720,h=720,ddd=0,nm=name+' review only',assets=[dict(id='motion',layers=result)],layers=[dict(ty=0,ind=1,refId='motion',ip=0,op=N,st=0,sr=1,w=720,h=720,ks=camera)],meta=dict(source='Military Push Ups by Dinh Bui Xuan',license='Lottie Simple License (FL 9.13.21)',review_only=True,source_contours_preserved=name!='cat_cow',source_part_sizes_preserved=True,shirt_spinal_deformation=name=='cat_cow',repetitions_per_loop=2 if name=='dead_bug' else 1))
    press.split_positions(data)
    (OUT/(name+'.json')).write_text(json.dumps(data,separators=(',',':')))
    print(name,'candidate saved')
for name in ['dead_bug','cat_cow','reverse_snow_angel']:build(name)
assert all(hashlib.sha256((ROOT/'assets/animations/launch25'/p).read_bytes()).hexdigest()==h for p,h in before.items())

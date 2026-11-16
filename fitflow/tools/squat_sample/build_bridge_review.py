"""Glute Bridge review: repose original artwork, never redraw muscle contours."""
import copy, hashlib, json, math
import build_press_review as press
import build_plank_review as plank
art=press.art
ROOT=press.ROOT
OUT=ROOT/'build/bridge-review'
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
transforms=[]
shoulder=[230,600]
waist=J['nearHip']
# Pivot inside the overlapping source thigh/calf contours, not their outer cap.
source_knee=[272,584]
thigh_length=math.dist(waist,J['nearKnee'])
shin_length=math.dist(source_knee,J['nearAnkle'])
for frame in range(N):
    q=(1-math.cos(math.tau*frame/(N-1)))/2
    body=art.rigid(J['nearShoulder'],shoulder,math.radians(200-20*q))
    ts={i:body for i in source_layers}
    # Head rests on the mat while the torso rotates around the shoulders.
    resting_neck=art.rigid(J['nearShoulder'],shoulder,math.radians(200))
    for i in [5,9,10]:ts[i]=resting_neck
    for side in ['near','far']:
        far=side=='far'; dx,dy=(0,-6) if far else (0,0)
        hip=art.point(body,waist); hip=[hip[0]+dx,hip[1]+dy]
        ankle=[400+dx,620+dy]
        k=press.ik(hip,ankle,thigh_length,shin_length)
        # Select the knee above the hip-to-foot line.
        v=[ankle[j]-hip[j] for j in range(2)]; l=math.dist(hip,ankle)
        projection=sum((k[j]-hip[j])*v[j] for j in range(2))/(l*l)
        foot=[hip[j]+projection*v[j] for j in range(2)]
        knee=[2*foot[j]-k[j] for j in range(2)]
        thigh=art.segment(waist,J['nearKnee'],hip,knee)
        calf=art.segment(source_knee,J['nearAnkle'],knee,ankle)
        for i in ([16,18] if far else [12,15]):ts[i]=thigh
        # Thigh rotates at the anatomical hip; pelvis remains on the torso.
        if far:ts[16]=ts[12]
        ts[17 if far else 13]=calf
        ts[14 if far else 8]=art.rigid(J['nearAnkle'],ankle,math.radians(-62))
        arm_dx,arm_dy=(10,-8) if far else (0,0)
        sh=[shoulder[0]+arm_dx,shoulder[1]+arm_dy]
        wrist=[342+arm_dx,628+arm_dy]
        src_sh=art.point(plank.bent_world[4],art.value(plank.bent_layers[4]['ks']['a']))
        src_el=[414,617];src_wr=J['nearWrist']
        el=press.ik(sh,wrist,math.dist(src_sh,src_el),math.dist(src_el,src_wr))
        for i in ([21,22] if far else [3,4]):ts[i]=art.segment(src_sh,src_el,sh,el)
        ts[20 if far else 2]=art.segment(src_el,src_wr,el,wrist)
        ts[19 if far else 1]=art.rigid(src_wr,wrist,0)
        assert knee[1]<hip[1] and knee[1]<ankle[1]
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
        left,right=(336,500) if i==24 else (180,354)
        vertices=[local(left,450),local(right,450),local(right,650),local(left,650)]
        layer['masksProperties']=[dict(inv=False,mode='a',o=art.prop(100),
            pt=art.prop(dict(v=vertices,i=[[0,0]]*4,o=[[0,0]]*4,c=True)),x=art.prop(0))]
        layer['hasMask']=True
    result.append(layer)
pelvis=result.pop()
result.insert(next(i for i,l in enumerate(result) if l['ind']==12),pelvis)
result.append(art.shape_layer('Mat',[art.polygon('Mat',[[100,630],[510,630],[550,675],[110,675]],
    [.34,.70,.76,1])],N,30))
data=dict(v=press.source['v'],fr=N/2.68,ip=0,op=N,w=720,h=720,ddd=0,nm='bridge_glute — review only',
    assets=[dict(id='bridge',layers=result)],layers=[dict(ty=0,ind=1,nm='Fixed camera',refId='bridge',
        ip=0,op=N,st=0,sr=1,w=720,h=720,ks=dict(a=art.prop([330,540,0]),p=art.prop([360,360,0]),
        s=art.prop([120,120,100]),r=art.prop(0),o=art.prop(100)))],
    meta=dict(source='Military Push Ups by Dinh Bui Xuan',license='Lottie Simple License (FL 9.13.21)',
        review_only=True,source_contours_preserved=True,source_part_sizes_preserved=True,source_arm_frame=31))
press.split_positions(data)
(OUT/'bridge_glute.json').write_text(json.dumps(data,separators=(',',':')),encoding='utf-8')
assert all(hashlib.sha256((ROOT/'assets/animations/launch25'/p).read_bytes()).hexdigest()==h for p,h in before.items())
(OUT/'verification.json').write_text(json.dumps(dict(source_contours_preserved=True,
    rigid_pose_only=True,fixed_supports=True,
    seconds=2.68,review_only=True),indent=2))
print('Glute Bridge candidate created; installed assets unchanged.')



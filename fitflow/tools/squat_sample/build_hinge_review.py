"""Hip Hinge review: repose original artwork, never redraw muscle contours."""
import copy, hashlib, json, math
import build_press_review as press
import build_plank_review as plank
art=press.art
ROOT=press.ROOT
OUT=ROOT/'build/hinge-review'
OUT.mkdir(parents=True,exist_ok=True)
N=80
J=press.J
before={p.name:hashlib.sha256(p.read_bytes()).hexdigest()
        for p in (ROOT/'assets/animations/launch25').iterdir() if p.suffix in ('.json','.png')}
waist=[375,550]
thigh_length=math.dist(waist,J['nearKnee'])
shin_length=math.dist(J['nearKnee'],J['nearAnkle'])
source_axis=math.atan2(-30,100)
# Reuse original near-side limb pieces at their original size on the far side.
# A small perspective offset separates them, without stretching the artwork.
source_ids={14:8,16:12,17:13,18:15,19:1,20:2,21:3,22:4}
arm_ids={2,3,4,20,21,22}
source_layers={i:copy.deepcopy((plank.bent_layers if i in arm_ids else press.layers)[source_ids.get(i,i)])
               for i in press.layers if i!=23}
source_world={i:(plank.bent_world if i in arm_ids else press.original)[source_ids.get(i,i)]
              for i in source_layers}
transforms=[]
for frame in range(N):
    q=(1-math.cos(math.tau*frame/(N-1)))/2
    knee=[300,610-shin_length]
    # A soft knee bend rather than the previous squat-like 30-degree bend.
    hip_x=290-35*q
    hip=[hip_x,knee[1]-math.sqrt(thigh_length**2-(hip_x-knee[0])**2)]
    # Anchor the posterior shirt hem to the actual shorts waistband. The old
    # center-pivot offsets separated the back at the waist during the hinge.
    near_thigh=art.segment(waist,J['nearKnee'],hip,knee)
    back_waist=art.point(near_thigh,[370.1,509.2])
    body=art.rigid([363.9,509.0],back_waist,math.radians(-90+45*q)-source_axis)
    assert math.degrees(math.asin((knee[0]-hip[0])/thigh_length))<21
    assert math.dist(art.point(body,[363.9,509.0]),back_waist)<1e-6
    ts={i:body for i in source_layers}
    for side in ['near','far']:
        far=side=='far'
        dx,dy=(8,-5) if far else (0,0)
        h=[hip[0]+dx,hip[1]+dy];k=[knee[0]+dx,knee[1]+dy];ankle=[300+dx,610+dy]
        thigh=art.segment(waist,J['nearKnee'],h,k)
        calf=art.segment(J['nearKnee'],J['nearAnkle'],k,ankle)
        ts[16 if far else 12]=thigh;ts[18 if far else 15]=thigh
        if far:
            # Both shorts panels meet the same waistband; the leg's depth
            # offset must not pull its waistband out through the shirt.
            ts[16]=ts[12]
        ts[17 if far else 13]=calf
        ts[14 if far else 8]=art.rigid(J['nearAnkle'],ankle,math.radians(-62))
        shoulder=art.point(body,J['nearShoulder'])
        # Constrain the palm at the hip, not merely the wrist. Solve the forearm
        # and hand as one aligned reach to avoid a changing bend at the wrist.
        palm=art.point(near_thigh,J['nearHip'])
        if far:
            shoulder=[shoulder[0]+6,shoulder[1]]
            palm=[palm[0]+6,palm[1]]
        sh_id=4
        src_sh=art.point(plank.bent_world[sh_id],art.value(plank.bent_layers[sh_id]['ks']['a']))
        src_el=[414,617]
        src_wr=J['nearWrist']
        src_palm=J['nearHand']
        forearm_length=math.dist(src_el,src_wr)
        hand_length=math.dist(src_wr,src_palm)
        reach=forearm_length+hand_length
        el=press.ik(shoulder,palm,math.dist(src_sh,src_el),reach)
        wrist=[el[j]+(palm[j]-el[j])*forearm_length/reach for j in range(2)]
        upper=art.segment(src_sh,src_el,shoulder,el)
        lower=art.segment(src_el,src_wr,el,wrist)
        for i in ([21,22] if far else [3,4]):ts[i]=upper
        ts[20 if far else 2]=lower
        # Rotate the unchanged source hand into alignment with its forearm.
        hand_angle=math.atan2(palm[1]-wrist[1],palm[0]-wrist[0])-math.atan2(
            src_palm[1]-src_wr[1],src_palm[0]-src_wr[0])
        ts[19 if far else 1]=art.rigid(src_wr,wrist,hand_angle)
        assert math.dist(art.point(ts[19 if far else 1],src_wr),wrist)<1e-6
        assert math.dist(art.point(ts[19 if far else 1],src_palm),palm)<1e-6
        assert abs(math.dist(el,wrist)-forearm_length)<1e-6
        assert abs(k[0]-ankle[0])<1e-6
        assert abs(math.dist(h,k)-thigh_length)<1e-6
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
    result.append(layer)
result.append(art.shape_layer('Mat',[art.polygon('Mat',[[170,625],[500,625],[540,647],[190,647]],
    [.34,.70,.76,1])],N,30))
data=dict(v=press.source['v'],fr=N/2.68,ip=0,op=N,w=720,h=720,ddd=0,nm='hip_hinge — review only',
    assets=[dict(id='hinge',layers=result)],layers=[dict(ty=0,ind=1,nm='Fixed camera',refId='hinge',
        ip=0,op=N,st=0,sr=1,w=720,h=720,ks=dict(a=art.prop([340,440,0]),p=art.prop([360,360,0]),
        s=art.prop([130,130,100]),r=art.prop(0),o=art.prop(100)))],
    meta=dict(source='Military Push Ups by Dinh Bui Xuan',license='Lottie Simple License (FL 9.13.21)',
        review_only=True,source_contours_preserved=True,source_part_sizes_preserved=True,source_arm_frame=31))
press.split_positions(data)
(OUT/'hip_hinge.json').write_text(json.dumps(data,separators=(',',':')),encoding='utf-8')
assert all(hashlib.sha256((ROOT/'assets/animations/launch25'/p).read_bytes()).hexdigest()==h for p,h in before.items())
(OUT/'verification.json').write_text(json.dumps(dict(source_contours_preserved=True,
    rigid_pose_only=True,vertical_shins=True,palms_fixed_at_hips=True,
    hands_aligned_with_forearms=True,seconds=2.68,review_only=True),indent=2))
print('Hip Hinge candidate created; installed assets unchanged.')

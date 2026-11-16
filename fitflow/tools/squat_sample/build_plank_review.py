"""Review-only forearm holds using the approved push-up character artwork."""
import copy
import hashlib
import json
import math
from pathlib import Path
import build_press_review as press

art=press.art
ROOT=press.ROOT
OUT=ROOT/'build/plank-pair-review'
OUT.mkdir(parents=True,exist_ok=True)
J=press.J
N=press.N
before={p.name:hashlib.sha256(p.read_bytes()).hexdigest()
        for p in (ROOT/'assets/animations/launch25').iterdir() if p.suffix in ('.json','.png')}
report={}

def source_bent_pose(obj):
    """Use authored source keys at the held bottom pose, without redrawing."""
    if isinstance(obj,list):return [source_bent_pose(v) for v in obj]
    if not isinstance(obj,dict):return obj
    if obj.get('a')==1 and isinstance(obj.get('k'),list) and obj['k'] and 's' in obj['k'][0]:
        keys=[k for k in obj['k'] if k['t']<=31]
        value=copy.deepcopy((keys[-1] if keys else obj['k'][0])['s'])
        return art.prop(value[0] if len(value)==1 else value)
    return {k:source_bent_pose(v) for k,v in obj.items()}

bent_layers={i:source_bent_pose(l) for i,l in press.layers.items()}
bent_world={i:art.matrix(i,bent_layers) for i in bent_layers}
ARM_IDS={2,3,4,6,7,20,21,22}

def posed_source_arm(ind,pose):
    layer=copy.deepcopy(bent_layers[ind]);layer.pop('parent',None)
    layer.update(ip=0,op=N,st=0,sr=1)
    m=art.mul(pose,bent_world[ind])
    layer['ks']=dict(a=art.prop([0,0,0]),p=art.prop([m[4],m[5],0]),
        r=art.prop(math.degrees(math.atan2(m[1],m[0]))),
        s=art.prop([math.hypot(m[0],m[1])*100]*2+[100]),o=art.prop(100))
    assert layer['shapes']==bent_layers[ind]['shapes']
    return layer

def main():
    for name in ['plank_knee','plank_forearm']:
        kneeling=name=='plank_knee'
        pivot=J['nearKnee'] if kneeling else J['nearAnkle']
        target=[260,650] if kneeling else [172,650]
        angle=math.radians(-19 if kneeling else -10)
        start=math.atan2(J['nearShoulder'][1]-pivot[1],J['nearShoulder'][0]-pivot[0])
        body=art.rigid(pivot,target,angle-start)
        transforms={i:body for i in press.layers if i!=23}
        leg_paths={}
        contacts=[]
        for side in ['near','far']:
            far=side=='far'
            shoulder=art.point(body,J[side+'Shoulder'])
            shoulder_id=22 if far else 4
            source_shoulder=art.point(bent_world[shoulder_id],art.value(bent_layers[shoulder_id]['ks']['a']))
            source_elbow=[466,598] if far else [414,617]
            source_wrist=J[side+'Wrist']
            upper_length=math.dist(source_shoulder,source_elbow)
            lower_length=math.dist(source_elbow,source_wrist)
            elbow_back=12 if not far else 9
            elbow=[shoulder[0]-elbow_back,
                   shoulder[1]+math.sqrt(upper_length**2-elbow_back**2)]
            wrist=[elbow[0]+lower_length,elbow[1]]
            upper=art.segment(source_shoulder,source_elbow,shoulder,elbow)
            lower=art.segment(source_elbow,source_wrist,elbow,wrist)
            for i in ([21,22] if far else [3,4,6,7]):transforms[i]=upper
            transforms[20 if far else 2]=lower
            transforms[19 if far else 1]=art.rigid(J[side+'Wrist'],wrist,0)
            assert abs(elbow[0]-shoulder[0])<=12
            assert abs(math.dist(shoulder,elbow)-upper_length)<1e-6
            assert abs(wrist[1]-elbow[1])<1e-6
            contacts.extend([elbow,wrist])
            if kneeling:
                # Reuse the approved fuller leg and fixed support geometry.
                support_start=art.rigid(pivot,target,math.radians(-37)-start)
                knee=art.point(support_start,J[side+'Knee'])
                hip=art.point(body,J[side+'Hip'])
                ankle=[knee[0]-62,knee[1]-47]
                if far:
                    transforms[16]=art.segment(J['farKnee'],J['farHip'],knee,hip)
                transforms[14 if far else 8]=art.segment(J[side+'Knee'],J[side+'Ankle'],knee,ankle)
                leg_paths[side]=press.supported_leg(hip,knee,ankle)
                contacts.append(knee)
            else:
                contacts.append(art.point(body,J[side+'Toe']))
        result=[]
        for i,layer in press.layers.items():
            if i==23 or (kneeling and i in [13,17]):continue
            if i in ARM_IDS:
                result.append(posed_source_arm(i,transforms[i]))
                continue
            if kneeling and i in [15,18]:
                side='near' if i==15 else 'far'
                result.append(press.leg_layer(side,[leg_paths[side]]*N))
                continue
            matrices=[transforms[i]]*N
            if i==11:
                # A small breathing expansion of the shirt only. No pumping of
                # hips or movement of the support limbs during an isometric hold.
                matrices=[art.mul(body,art.rigid([375,550],[375,550],0,
                          1+.006*(1-math.cos(math.tau*f/(N-1)))/2)) for f in range(N)]
            result.append(press.compose_layer(layer,matrices))
        result.append(art.shape_layer('Mat',[art.polygon('Mat',
            [[100,630],[590,630],[670,715],[125,715]],[.34,.70,.76,1])],N,30))
        data=dict(v=press.source['v'],fr=N/2.68,ip=0,op=N,w=720,h=720,ddd=0,
            nm=name+' â€” review only',assets=[dict(id='plank',layers=result)],
            layers=[dict(ty=0,ind=1,nm='Fixed full-body camera',refId='plank',
                ip=0,op=N,st=0,sr=1,w=720,h=720,
                ks=dict(a=art.prop([385,590,0]),p=art.prop([360,360,0]),
                    s=art.prop([110,110,100]),r=art.prop(0),o=art.prop(100)))],
            meta=dict(source='Military Push Ups by Dinh Bui Xuan',
                license='Lottie Simple License (FL 9.13.21)',review_only=True,
                source_head_torso_hands_preserved=True,
                source_bent_arm_shapes_preserved=True,source_arm_frame=31,
                approved_knee_contour_reused=kneeling,isometric_hold=True))
        press.split_positions(data)
        for layer in result:
            i=layer['ind']
            if i in ARM_IDS:
                assert layer['shapes']==bent_layers[i]['shapes']
            elif i in press.layers and not (kneeling and i in [15,18]):
                assert layer['shapes']==art.freeze(copy.deepcopy(press.layers[i]))['shapes']
        (OUT/f'{name}.json').write_text(json.dumps(data,separators=(',',':')),encoding='utf-8')
        report[name]=dict(review_only=True,isometric_hold=True,seconds=2.68,
            elbows_within_shoulder_footprint=True,elbow_backward_offset=[12,9],
            original_upper_arm_lengths_preserved=True,forearms_horizontal=True,supports=contacts,
            source_head_torso_hands_preserved=True,
            source_bent_arm_shapes_preserved=True,source_arm_frame=31)
    assert all(hashlib.sha256((ROOT/'assets/animations/launch25'/p).read_bytes()).hexdigest()==h for p,h in before.items())
    (OUT/'verification.json').write_text(json.dumps(report,indent=2))
    print('Created two plank previews; installed catalog unchanged.')

if __name__=='__main__':
    main()

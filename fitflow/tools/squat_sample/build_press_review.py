"""Review-only presses: source upper body, with a continuous supported knee."""
import copy
import hashlib
import json
import math
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'orange_character'))
import build_character as art
from build_standing_review import split_positions

ROOT=art.ROOT
OUT=ROOT/'build/press-pair-review'
OUT.mkdir(parents=True,exist_ok=True)
source=json.loads((ROOT/'assets/animations/pushup.json').read_bytes())
layers={l['ind']:l for l in source['assets'][0]['layers']}
original={i:art.matrix(i,layers) for i in layers}
N=80
J=art.JOINTS
manifest={p.name:hashlib.sha256(p.read_bytes()).hexdigest()
          for p in (ROOT/'assets/animations/launch25').iterdir() if p.suffix in ('.json','.png')}

def ik(a,b,l1,l2):
    dx,dy=b[0]-a[0],b[1]-a[1];d=math.hypot(dx,dy)
    assert abs(l1-l2)<d<l1+l2,(a,b,d,l1,l2)
    x=(l1*l1-l2*l2+d*d)/(2*d);h=math.sqrt(max(0,l1*l1-x*x))
    return [a[0]+dx*x/d-dy*h/d,a[1]+dy*x/d+dx*h/d]

def compose_layer(layer, matrices):
    result=art.freeze(copy.deepcopy(layer));result.pop('parent',None)
    result.update(ip=0,op=N,st=0,sr=1)
    ms=[art.mul(m,original[layer['ind']]) for m in matrices]
    angles=[math.degrees(math.atan2(m[1],m[0])) for m in ms]
    for i in range(1,len(angles)):
        while angles[i]-angles[i-1]>180:angles[i]-=360
        while angles[i]-angles[i-1]<-180:angles[i]+=360
    result['ks']=dict(a=art.prop([0,0,0]),p=art.keyframes([[m[4],m[5],0] for m in ms]),
                      r=art.keyframes(angles),s=art.keyframes([[math.hypot(m[0],m[1])*100]*2+[100] for m in ms]),o=art.prop(100))
    return result

def supported_leg(hip,knee,ankle):
    """Continuous thigh/calf silhouette, with a soft inner crease and patella.

    A rotated straight calf overlaps the source thigh as a square corner.
    Here the knee's lower contour stays on its support throughout the rep.
    """
    def direction(a,b):
        length=math.dist(a,b)
        return [(b[j]-a[j])/length for j in range(2)]
    u=direction(knee,hip);v=direction(knee,ankle)
    pu=[-u[1],u[0]];pv=[-v[1],v[0]]
    def offset(p,n,width):return [p[j]+n[j]*width for j in range(2)]
    def along(a,b,t):return [a[j]+(b[j]-a[j])*t for j in range(2)]
    # The approved source thigh measures ~38 units across. Retain that
    # substantial silhouette and a fuller calf before tapering to the shoe.
    # Broaden the knee upward so its existing mat-contact height stays fixed.
    vs=[offset(hip,pu,-20),
        offset(along(knee,hip,.46),pu,-19),
        [knee[0],knee[1]-17],
        offset(along(knee,ankle,.50),pv,15),
        offset(ankle,pv,9),offset(ankle,pv,-9),
        offset(along(knee,ankle,.48),pv,-16),
        [knee[0],knee[1]+11],
        offset(along(knee,hip,.46),pu,19),offset(hip,pu,20)]
    tangents=[[(vs[(i+1)%len(vs)][j]-vs[(i-1)%len(vs)][j])*.16
               for j in range(2)] for i in range(len(vs))]
    tangents[2]=[-7,0];tangents[7]=[9,0]
    return dict(v=vs,i=[[-x,-y] for x,y in tangents],o=tangents,c=True)

def leg_layer(side,paths):
    ind=15 if side=='near' else 18
    source_shapes=art.freeze(copy.deepcopy(layers[ind]))['shapes']
    def fill_color(items):
        for item in items:
            if item['ty']=='fl':return item['c']['k']
            if item['ty']=='gr':
                color=fill_color(item['it'])
                if color is not None:return color
    shape=art.polygon(side+' continuous supported knee',paths[0]['v'],fill_color(source_shapes))
    shape['it'][0]['ks']={'a':1,'k':[dict(t=i,s=[p],
        i={'x':.667,'y':.667},o={'x':.333,'y':.333}) for i,p in enumerate(paths)]}
    return art.shape_layer(side+' thigh and calf',[shape],N,ind)

def main():
    report={}
    for name in ['pushup_knee','pushup_wall']:
        wall=name=='pushup_wall'
        transforms=[];contacts=[];supports_history=[]
        leg_paths={'near':[],'far':[]}
        for frame in range(N):
            q=(1-math.cos(math.tau*frame/(N-1)))/2
            if wall:
                src=J['nearAnkle'];dest=[245,620];scale=1.35
                start=math.atan2(J['nearShoulder'][1]-src[1],J['nearShoulder'][0]-src[0])
                body=art.rigid(src,dest,math.radians(-78+14*q)-start,scale)
            else:
                src=J['nearKnee'];dest=[260,650];scale=1
                start=math.atan2(J['nearShoulder'][1]-src[1],J['nearShoulder'][0]-src[0])
                body=art.rigid(src,dest,math.radians(-37+17*q)-start,scale)
            ts={i:body for i in layers if i!=23}
            if frame==0:first_body=body
            frame_supports=[]
            for side in ['near','far']:
                far=side=='far'
                sh=art.point(body,J[side+'Shoulder'])
                if wall and far:
                    near_sh=art.point(body,J['nearShoulder'])
                    sh=[near_sh[0]+24,near_sh[1]-12]
                wrist=([510,280] if not far else [510,255]) if wall else ([442,668] if not far else [485,632])
                l1=math.dist(J[side+'Shoulder'],J[side+'Elbow'])*scale
                l2=math.dist(J[side+'Elbow'],J[side+'Wrist'])*scale
                elbow=ik(sh,wrist,l1,l2)
                upper=art.segment(J[side+'Shoulder'],J[side+'Elbow'],sh,elbow)
                lower=art.segment(J[side+'Elbow'],J[side+'Wrist'],elbow,wrist)
                for i in ([21,22] if far else [3,4,6,7]):ts[i]=upper
                ts[20 if far else 2]=lower
                # Source flat palm is kept rigid, horizontal on the mat or rotated
                # upright against the wall. Its wrist does not slide during a rep.
                ts[19 if far else 1]=art.rigid(J[side+'Wrist'],wrist,-math.pi/2 if wall else 0,scale)
                if wall:
                    ankle=[245,620] if not far else [268,610]
                    if far:
                        near_hip=art.point(body,J['nearHip'])
                        hip=[near_hip[0]+23,near_hip[1]-10]
                        far_leg=art.segment(J['farAnkle'],J['farHip'],ankle,hip)
                        for i in [17,18]:ts[i]=far_leg
                        # Keep both garment panels attached to the same pelvis.
                        # Moving the far shorts with its offset leg exposes a flap.
                        ts[16]=body
                    ts[14 if far else 8]=art.rigid(J[side+'Ankle'],ankle,math.radians(-62),scale)
                else:
                    knee=art.point(first_body,J[side+'Knee'])
                    if far:
                        hip=art.point(body,J['farHip'])
                        thigh=art.segment(J['farKnee'],J['farHip'],knee,hip)
                        for i in [16,18]:ts[i]=thigh
                    # Lower legs are raised behind supported knees. Keep the
                    # source shoes; join thigh and calf with a continuous contour.
                    ankle=[knee[0]-62,knee[1]-47]
                    shin=art.segment(J[side+'Knee'],J[side+'Ankle'],knee,ankle)
                    ts[17 if far else 13]=shin
                    ts[14 if far else 8]=shin
                    hip=art.point(body,J[side+'Hip'])
                    leg_paths[side].append(supported_leg(hip,knee,ankle))
                contacts.append(wrist)
                frame_supports.extend([wrist, ankle if wall else knee])
            supports_history.append(frame_supports)
            transforms.append(ts)
        drift=max(math.dist(p,ref) for contact in supports_history
                  for p,ref in zip(contact,supports_history[0]))
        assert drift<1e-6
        result=[compose_layer(l,[t[i] for t in transforms]) for i,l in layers.items() if i!=23]
        if not wall:
            result=[leg_layer('near' if l['ind']==15 else 'far',
                              leg_paths['near' if l['ind']==15 else 'far'])
                    if l['ind'] in [15,18] else l
                    for l in result if l['ind'] not in [13,17]]
        if wall:
            supports=[art.polygon('Floor',[[120,634],[570,634],[590,657],[130,657]],[.34,.70,.76,1]),
                      art.polygon('Wall',[[528,130],[548,130],[548,645],[528,645]],[.67,.74,.77,1])]
        else:
            supports=[art.polygon('Mat',[[120,625],[565,625],[640,695],[150,695]],[.34,.70,.76,1])]
        result.append(art.shape_layer('Support surface',supports,N,30))
        camera=dict(ty=0,ind=1,nm='Fixed full-body camera',refId='press',ip=0,op=N,st=0,sr=1,w=720,h=720,
                    ks=dict(a=art.prop([355,390,0] if wall else [380,590,0]),
                            p=art.prop([360,360,0]),s=art.prop([100,100,100] if wall else [112,112,100]),
                            r=art.prop(0),o=art.prop(100)))
        data=dict(v=source['v'],fr=N/2.68,ip=0,op=N,w=720,h=720,nm=name+' — review only',
                  ddd=0,assets=[dict(id='press',layers=result)],layers=[camera],
                  meta=dict(source='Military Push Ups by Dinh Bui Xuan',license='Lottie Simple License (FL 9.13.21)',
                            review_only=True,source_contours_preserved=wall,
                            revised_contours=[] if wall else ['near supported leg','far supported leg']))
        split_positions(data)
        for l in result:
            if l['ind'] in layers and (wall or l['ind'] not in [15,18]):
                assert l['shapes']==art.freeze(copy.deepcopy(layers[l['ind']]))['shapes']
        (OUT/f'{name}.json').write_text(json.dumps(data,separators=(',',':')),encoding='utf-8')
        report[name]=dict(source_contours_preserved=wall,upper_body_contours_preserved=True,
                          revised_contours=[] if wall else ['near supported leg','far supported leg'],seconds=2.68,
                          support_drift=drift,review_only=True)
    assert all(hashlib.sha256((ROOT/'assets/animations/launch25'/p).read_bytes()).hexdigest()==h for p,h in manifest.items())
    (OUT/'verification.json').write_text(json.dumps(report,indent=2))
    print('Created press review candidates; installed animations unchanged.')


if __name__=='__main__':
    main()

"""March and heel-raise review candidates using approved source artwork.

Does not publish assets or build an APK. Uses front-view limb projection while
keeping the source head/torso contours and clothing unchanged.
"""
import copy, hashlib, json, math, sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/orange_character'))
import build_character as art
OUT=ROOT/'build/standing-pair-review'
original=art.freeze(json.loads((ROOT/'assets/animations/illustrated_athletes/jumping_jacks.json').read_text()))
approved=art.freeze(json.loads((ROOT/'assets/animations/launch25/squat_bodyweight.json').read_text()))
basecomp=next(a for a in original['assets'] if a['id']=='comp_0')
base={l['ind']:l for l in basecomp['layers']}
leg=next(a for a in original['assets'] if a['id']=='comp_1')
legbase={l['ind']:l for l in leg['layers']}
approved_body=next(l for a in approved['assets'] if a['id']=='comp_0' for l in a['layers'] if l['ind']==1)


def group_world(group,m):
    group=copy.deepcopy(group)
    tr=next(z for z in group['it'] if z['ty']=='tr')
    m=art.mul(m,art.matrix(0,{0:{'ks':tr}}))
    tr.update(p=art.prop([0,0]),a=art.prop([0,0]),s=art.prop([100,100]),r=art.prop(0))
    for z in group['it']:
        if z['ty']!='sh':continue
        p=z['ks']['k'];p['v']=[art.point(m,v) for v in p['v']]
        for k in ['i','o']:p[k]=[[m[0]*x+m[2]*y,m[1]*x+m[3]*y] for x,y in p[k]]
    return group


def deform(group,functions):
    group=copy.deepcopy(group)
    for z in group['it']:
        if z['ty']!='sh':continue
        source=z['ks']['k'];paths=[]
        for fn in functions:
            p=copy.deepcopy(source);p['v']=[fn(v) for v in source['v']]
            for k in ['i','o']:
                p[k]=[[q[j]-p['v'][i][j] for j in range(2)]
                      for i,(v,h) in enumerate(zip(source['v'],source[k]))
                      for q in [fn([v[0]+h[0],v[1]+h[1]])]]
            paths.append(p)
        z['ks']={'a':1,'k':[{'t':i,'s':[p],'i':{'x':.667,'y':.667},'o':{'x':.333,'y':.333}}
                            for i,p in enumerate(paths)]}
    return group


def projection(a,b,c,d):
    sx,sy=b[0]-a[0],b[1]-a[1];sl=math.hypot(sx,sy);sx/=sl;sy/=sl
    tx,ty=d[0]-c[0],d[1]-c[1];tl=math.hypot(tx,ty);tx/=tl;ty/=tl
    r=tl/sl;m=[r*tx*sx+ty*sy,r*ty*sx-tx*sy,r*tx*sy-ty*sx,r*ty*sy+tx*sx,0,0]
    m[4]=c[0]-m[0]*a[0]-m[2]*a[1];m[5]=c[1]-m[1]*a[0]-m[3]*a[1]
    return m


def ease(t):return (1-math.cos(math.pi*t))/2


def calf_height(t):
    if t<.1:return 0
    if t<.4:return 18*ease((t-.1)/.3)
    if t<.55:return 18
    if t<.95:return 18*(1-ease((t-.55)/.4))
    return 0


def set_duration(obj,n):
    if isinstance(obj,list):
        for v in obj:set_duration(v,n)
    elif isinstance(obj,dict):
        if isinstance(obj.get('ty'),int) and 'ks' in obj:obj.update(ip=0,op=n,st=0,sr=1)
        for v in obj.values():set_duration(v,n)


def split_positions(obj):
    """Avoid zero-length spatial paths during heel holds and grounded steps."""
    if isinstance(obj,list):
        for v in obj:split_positions(v)
    elif isinstance(obj,dict):
        if isinstance(obj.get('ty'),int) and isinstance(obj.get('ks'),dict):
            p=obj['ks'].get('p',{})
            if p.get('a')==1:
                values=[key['s'] for key in p['k']]
                obj['ks']['p']={'s':True,'x':art.keyframes([v[0] for v in values]),
                               'y':art.keyframes([v[1] for v in values])}
        for v in obj.values():split_positions(v)


def arm_warp(side,shoulder,elbow,wrist):
    ss=[409.7,225.65] if side==1 else [298.4,225.65]
    se=[418,285] if side==1 else [290.1,285]
    sw=[411.6,357.5] if side==1 else [296.6,357.5]
    def warp(p):
        t=(p[1]-225.65)/59.35 if p[1]<=285 else (p[1]-285)/72.5
        a,b=(shoulder,elbow) if p[1]<=285 else (elbow,wrist)
        sa,sb=(ss,se) if p[1]<=285 else (se,sw)
        width=p[0]-(sa[0]+(sb[0]-sa[0])*t)
        blend=max(0,min(1,(p[1]-270)/30))
        u=[elbow[j]-shoulder[j] for j in range(2)];v=[wrist[j]-elbow[j] for j in range(2)]
        ul=math.hypot(*u);vl=math.hypot(*v)
        tangent=[(1-blend)*u[j]/ul+blend*v[j]/vl for j in range(2)]
        length=math.hypot(*tangent)
        return [a[0]+(b[0]-a[0])*t+width*tangent[1]/length,
                a[1]+(b[1]-a[1])*t-width*tangent[0]/length]
    return warp


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    manifest={p.name:hashlib.sha256(p.read_bytes()).hexdigest()
              for p in (ROOT/'assets/animations/launch25').iterdir() if p.suffix in ['.json','.png']}
    report={}
    for name,n in [('march_in_place',120),('calf_raise',150)]:
        march=name=='march_in_place'
        frames=[]
        for i in range(n):
            t=i/(n-1);wave=math.sin(math.tau*t)
            right=max(0,wave)**2 if march else 0
            left=max(0,-wave)**2 if march else 0
            rise=0 if march else calf_height(t)
            frames.append({'x':5*(left-right),'y':-rise,'right':right,'left':left,
                           'wave':wave,'rise':rise})
        data=copy.deepcopy(original);data.update(ip=0,op=n,fr=30,nm=name+' — review only')
        set_duration(data,n)
        comp=next(a for a in data['assets'] if a['id']=='comp_0')
        ls={l['ind']:l for l in comp['layers']}
        ls[1]['shapes']=copy.deepcopy(approved_body['shapes'])
        p=art.value(base[1]['ks']['p'])
        ls[1]['ks']['p']=art.keyframes([[p[0]+f['x'],p[1]+f['y'],0] for f in frames])
        newlegs=[];newarms=[]
        for index,side in [(2,-1),(3,1)]:
            outer=art.matrix(index,base)
            h=art.point(outer,[375.863,323.219]);k=art.point(outer,[375.5,449]);a=art.point(outer,[380,568])
            poses=[]
            for f in frames:
                lift=65*f['right' if side==1 else 'left'] if march else -f['y']
                hip=[h[0]+f['x'],h[1]+f['y']+4]
                knee=[k[0]+side*12,k[1]-lift]
                ankle=[a[0]+side*12,a[1]-lift]
                poses.append((hip,knee,ankle))
            for gi,li,bone in [(0,1,'thigh'),(1,3,'thigh'),(0,3,'shin')]:
                g=group_world(legbase[li]['shapes'][gi],art.mul(outer,art.matrix(li,legbase)))
                matrices=[projection(h,k,hip,knee) if bone=='thigh' else art.segment(k,a,knee,ankle)
                          for hip,knee,ankle in poses]
                g=deform(g,[lambda p,m=m:art.point(m,p) for m in matrices])
                newlegs.append(art.shape_layer(f'{side} approved {bone}',[g],n,100+len(newlegs)))
            shoe=copy.deepcopy(legbase[2]);shoe.pop('parent',None)
            shoe.update(ip=0,op=n,st=0,ind=100+len(newlegs))
            sm=art.mul(outer,art.matrix(2,legbase));sm[4]+=side*12
            angle=math.degrees(math.atan2(-sm[1] if side==-1 else sm[1],-sm[0] if side==-1 else sm[0]))
            # Toe contact at local y=49; front-view foot projection lengthens as
            # heels lift, keeping the actual toe/sole point stationary.
            pivot=art.point(sm,[16,49]);positions=[];scales=[]
            for f in frames:
                lift=65*f['right' if side==1 else 'left'] if march else 0
                stretch=1 if march else 1+f['rise']/50
                positions.append([sm[4],pivot[1]+(sm[5]-pivot[1])*stretch-lift,0])
                scales.append([side*100,stretch*100,100])
            shoe['ks']={'a':art.prop([0,0,0]),'p':art.keyframes(positions),
                        'r':art.prop(angle),'s':art.keyframes(scales),'o':art.prop(100)}
            newlegs.insert(0,shoe)

        if march:
            for arm_id,hand_id,side in [(6,7,1),(8,9,-1)]:
                warps=[];handmaps=[]
                for f in frames:
                    # Opposite arm comes forward as each knee lifts. In a front
                    # view this projects as a bent forearm rising toward the chest.
                    swing=-side*f['wave']
                    def point(x,y):return [354.1+side*(x-354.1)+f['x'],y+f['y']]
                    shoulder=point(409.7,225.65)
                    # Keep each hand on its own side of the torso. A narrower
                    # inward reach avoids a cupped/hands-together neutral pose.
                    elbow=point(421,292-12*swing)
                    wrist=point(410-4*swing,304-40*swing)
                    warps.append(arm_warp(side,shoulder,elbow,wrist))
                    u=[wrist[j]-elbow[j] for j in range(2)];length=math.hypot(*u)
                    tip=[wrist[j]+u[j]/length*32 for j in range(2)]
                    centre=354.1+f['x']
                    assert side*(wrist[0]-centre)>30
                    assert side*(tip[0]-centre)>20
                    assert wrist[1]>shoulder[1]
                    sw=[411.6,357.5] if side==1 else [296.6,357.5]
                    handmaps.append(art.segment(sw,[sw[0],407],wrist,tip))
                groups=[deform(group_world(g,art.matrix(arm_id,base)),warps) for g in base[arm_id]['shapes']]
                newarms.append(art.shape_layer(f'{side} reciprocal bent arm',groups,n,200+arm_id))
                groups=[deform(group_world(g,art.matrix(hand_id,base)),
                         [lambda p,m=m:art.point(m,p) for m in handmaps]) for g in base[hand_id]['shapes']]
                newarms.insert(0,art.shape_layer(f'{side} relaxed hand',groups,n,200+hand_id))
            removed=[2,3,6,7,8,9]
        else:
            # Original relaxed arms inherit the torso rise; no pushing with hands.
            removed=[2,3]
        # Lottie layer order is front-to-back. The original foot shadow must sit
        # behind the narrower stance, never across the toe artwork.
        comp['layers']=newarms+[l for l in comp['layers'] if l['ind'] not in removed+[5]]+newlegs+[ls[5]]
        split_positions(data)
        assert ls[1]['shapes']==approved_body['shapes']
        if march:assert all(min(f['left'],f['right'])==0 for f in frames)
        data['meta']={'source':'Jumping Jacks by Dinh Bui Xuan','license':'Lottie Simple License (FL 9.13.21)',
                      'review_only':True,'adaptation':name,'approved_torso_preserved':True}
        (OUT/(name+'.json')).write_text(json.dumps(data,separators=(',',':')),encoding='utf-8')
        report[name]={'frames':n,'seconds':n/30,'unchanged_head_torso':True,
                      'alternating_ground_contact_checked':True if march else None,
                      'review_only':True}
    assert all(hashlib.sha256((ROOT/'assets/animations/launch25'/name).read_bytes()).hexdigest()==digest
               for name,digest in manifest.items())
    (OUT/'verification.json').write_text(json.dumps(report,indent=2))
    print('Created March in Place and Calf Raise review candidates. App assets unchanged.')


if __name__ == '__main__':
    main()

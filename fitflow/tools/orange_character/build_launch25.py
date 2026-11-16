"""Exercise-specific vector adaptations of the supplied orange-shirt athlete.
Preserves original five demonstrations. Rebuild candidates then render/review.
"""
import copy,json,math,sys,shutil
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
import build_character as art
ROOT=art.ROOT
render=art.load_renderer(ROOT/'tools/illustrated_athletes/oef_render.py')
OUT=ROOT/'.dart_tool/orange_character'
def read(folder,name):return json.loads((ROOT/folder/(name+'.json')).read_text(encoding='utf-8'))
def pose(torso=0,arms=None,legs=None,**kw):return dict(torso=torso,arms=arms or [180,180],legs=legs or [180,180,95],**kw)
def fig(poses,**kw):return dict(view='side',poses=poses,**kw)
def rect(name,x,y,w,h):return dict(name=name,rect=[x,y,w,h])
def make(name,f):
 ps=list(render.timeline(f))
 if len(ps)<2:ps=ps*60
 art.build(name,f,ps,render,OUT)

# Grounded, individually authored poses; angle convention is documented by solver.
standing=pose(arms=[95,95])
# Preserve all approved front-view adaptations instead of the superseded rigs.
OUT.mkdir(parents=True,exist_ok=True)
for name in ['squat_bodyweight','squat_partial','squat_chair','march_in_place','calf_raise','arm_circles','step_jack']:
 shutil.copyfile(ROOT/'assets/animations/launch25'/(name+'.json'),
                 OUT/(name+'.json'))
for name,folder in [('dead_bug','tools/illustrated_athletes/rigs'),('plank_knee','tools/illustrated_athletes/rigs'),('plank_forearm','tools/illustrated_athletes/rigs'),('bridge_glute','tools/illustrated_athletes/rigs'),('hip_hinge','tools/open_exercise_figures'),('lunge_reverse','tools/illustrated_athletes/rigs')]:
 f=read(folder,name)
 if name=='bridge_glute':f['contact']=['shoulder',.20]
 make(name,f)
# Alternating contralateral arm/leg extension.
# Bird dog alternates fixed support contacts; generated below.
make('pushup_wall',read('tools/open_exercise_figures','pushup_wall'))

# Fixed-contact two-link inverse kinematics for presses and supported rows.
def ik(a,b,l1=.30,l2=.25,side=-1):
 dx,dy=b[0]-a[0],b[1]-a[1];d=math.hypot(dx,dy)
 if not abs(l1-l2)<d<l1+l2:raise ValueError(('unreachable contact',a,b,d))
 x=(d*d+l1*l1-l2*l2)/(2*d);h=math.sqrt(max(0,l1*l1-x*x));ux,uy=dx/d,dy/d
 return (a[0]+x*ux-side*h*uy,a[1]+x*uy+side*h*ux)
def joints(hip,shoulder,knee,ankle,wrist,elbow=None,foot=None):
 elbow=elbow or ik(shoulder,wrist)
 d=math.dist(hip,shoulder);u=((shoulder[0]-hip[0])/d,(shoulder[1]-hip[1])/d)
 j={'hip':hip,'shoulder':shoulder,'neckTop':(shoulder[0]+u[0]*.1,shoulder[1]+u[1]*.1),'head':(shoulder[0]+u[0]*.20,shoulder[1]+u[1]*.20)}
 for side in ['near','far']:
  for k,v in dict(Hip=hip,Shoulder=shoulder,Knee=knee,Ankle=ankle,Wrist=wrist,Elbow=elbow,Hand=(wrist[0]+.09,wrist[1]),Toe=foot or (ankle[0]+.16,ankle[1]-.02)).items():j[side+k]=v
 return j
class Direct:
 @staticmethod
 def pose_joints(f,p):return p
for name in ['pushup_knee','pushup_pike','row_doorway','cat_cow','reverse_snow_angel']:
 frames=[]
 for i in range(81):
  q=(1-math.cos(i/80*2*math.pi))/2
  if name=='pushup_knee':
   knee=(0,.06);hip=(.42+.03*q,.30-q*.14);shoulder=(.90+.14*q,.58-q*.33)
   j=joints(hip,shoulder,knee,(-.40,.10),(.98,.06),foot=(-.53,.13))
  elif name=='pushup_pike':
   hip=(.40,.84);angle=math.radians(-42-q*20);shoulder=(hip[0]+.52*math.cos(angle),hip[1]+.52*math.sin(angle))
   j=joints(hip,shoulder,(.18,.47),(-.04,.10),(1.02,.06),foot=(.10,.03))
  elif name=='row_doorway':
   a=math.radians(-12*(1-q));ankle=(0,.09);knee=(.43*math.sin(a),.09+.43*math.cos(a));hip=(.87*math.sin(a),.09+.87*math.cos(a));shoulder=(1.39*math.sin(a),.09+1.39*math.cos(a))
   j=joints(hip,shoulder,knee,ankle,(.12,1.15))
  elif name=='cat_cow':
   j=joints((0,.54),(.52,.54), (0,.07),(-.40,.08),(.52,.06),elbow=(.52,.30),foot=(-.53,.08))
   j['head']=(.69,.72-.28*q)
   # Rounded/extended trunk and neck, with hands and knees remaining planted.
   j['hip']=(0,.54+q*.03);j['shoulder']=(.52,.54+q*.03)
   for side in ['near','far']:
    j[side+'Hip']=j['hip'];j[side+'Shoulder']=j['shoulder']
  else:
   j=joints((0,.14),(.52,.14),(-.43,.14),(-.86,.12),(.6,.25),elbow=(.6,.30),foot=(-1,.12))
   for side,sgn in [('near',1),('far',-1)]:
    # Separate both sides in the overhead view; coincident leg pivots made
    # the previous silhouette read as a single leg.
    for joint in ['Hip','Knee','Ankle','Toe']:
     x,y=j[side+joint];j[side+joint]=(x,y+sgn*.085)
    x,y=j[side+'Shoulder'];j[side+'Shoulder']=(x,y+sgn*.12)
    a=math.radians(170-q*160);sx,sy=j[side+'Shoulder'];j[side+'Elbow']=(sx+.30*math.cos(a),sy+sgn*.30*math.sin(a));j[side+'Wrist']=(sx+.55*math.cos(a),sy+sgn*.55*math.sin(a));j[side+'Hand']=(sx+.64*math.cos(a),sy+sgn*.64*math.sin(a))
  frames.append(j)
 f={'view':'side','seconds':5,'spineCurve':name=='cat_cow','topDown':name=='reverse_snow_angel'}
 if name=='row_doorway':f['supports']=[rect('Door frame',.16,0,.045,1.9)]
 art.build(name,f,frames,Direct,OUT)

frames=[]
for side in ['a','b']:
 f=read('tools/open_exercise_figures','bird_dog_'+side)
 frames.extend(render.pose_joints(f,p) for p in render.timeline(f))
art.build('bird_dog',{'view':'side','seconds':6},frames,Direct,OUT)

# Arm circles and step jacks use the reviewed assets copied above.
print('Built candidate set while preserving approved animations')

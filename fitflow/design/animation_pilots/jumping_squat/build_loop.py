"""Bake the source's ping-pong time-remap for Flutter; review only."""
import copy, hashlib, json
from pathlib import Path
folder=Path(__file__).parent
source=folder/'source.json'
data=json.loads(source.read_text())
def strip_expressions(value):
    if isinstance(value, list):
        return [strip_expressions(v) for v in value]
    if isinstance(value, dict):
        return {k:strip_expressions(v) for k,v in value.items() if not(k=='x' and isinstance(v,str))}
    return value
result=strip_expressions(copy.deepcopy(data))
result.update(nm='Jump Squat - loop review',fr=25,ip=0,op=50)
keys=[]
for t,v in [(0,0),(22,.64),(26,.64),(50,0)]:
    keys.append({'t':t,'s':[v],'o':{'x':[.333],'y':[.333]},'i':{'x':[.667],'y':[.667]}})
result['layers'][0]['tm']={'a':1,'k':keys}
result['layers'][0]['op']=50
result['meta']={'source':'https://lottiefiles.com/free-animation/jumping-squats-9hzVV8Ohi6','creator':'Dinh Bui Xuan','license':'Lottie Simple License (FL9.13.21)','sourceSha256':hashlib.sha256(source.read_bytes()).hexdigest(),'status':'Loop repair preview only; no catalog mapping'}
(folder/'jump_squat_loop.json').write_text(json.dumps(result,separators=(',',':')))

"""Reopen the saved .blend and inspect the actual editable source."""
from pathlib import Path
import json, math, bpy
ROOT=Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'source/split_cloud_hall.blend'))
scene=bpy.context.scene
checks=[]
def check(label,ok,detail=None):checks.append(dict(check=label,passed=bool(ok),detail=detail))
check('Metric scene units',scene.unit_settings.system=='METRIC' and scene.unit_settings.scale_length==1)
objects=[o for o in scene.objects if o.type=='MESH']
check('Editable material batches',len(objects)==18,len(objects))
check('No external texture files',not any(i.source=='FILE' for i in bpy.data.images))
check('No expensive object modifiers',not any(o.modifiers for o in objects))
check('Finite mesh positions',all(math.isfinite(float(v)) for o in objects for p in o.data.vertices for v in p.co))
check('Hall and door source collections',all(bpy.data.collections.get(n) for n in ['Hall','Grand','Private']))
used={m.name for o in objects for m in o.data.materials if m}
check('Twelve shared mesh materials',len(used)==12,sorted(used))
(ROOT/'reports/native-source-audit.json').write_text(json.dumps({'checks':checks,'passed':sum(c['passed'] for c in checks),'failed':sum(not c['passed'] for c in checks)},indent=2))
print(json.dumps(checks))

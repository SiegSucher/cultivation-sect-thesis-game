"""Read/reopen the editable converted facility sources; no reexport or mutation."""
from pathlib import Path
import bpy,json,sys
R=Path(__file__).resolve().parents[1]
short=sys.argv[sys.argv.index('--')+1]
family={'training':'martial_training_ground','pavilion':'scripture_pavilion'}[short]
bpy.ops.wm.open_mainfile(filepath=str(R/'source'/(family+'_low_poly.blend')))
objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
used={m for o in objects for m in o.data.materials}
checks=[
 {'check':'Metric scale','pass':bpy.context.scene.unit_settings.system=='METRIC' and bpy.context.scene.unit_settings.scale_length==1},
 {'check':'All GLB representation/prop collections present','pass':all(bpy.data.collections.get(p.stem) for p in (R/'baseline'/('stage23_'+short)).glob('*.glb'))},
 {'check':'No texture nodes on used materials','pass':all(not any(n.type=='TEX_IMAGE' for n in m.node_tree.nodes) for m in used)},
 {'check':'Editable polygon meshes, all flat shaded','pass':len(objects)>0 and all(len(o.data.polygons)>0 and not any(p.use_smooth for p in o.data.polygons) for o in objects)},
 {'check':'No modifiers/cameras/lights in source','pass':not any(o.modifiers for o in objects) and not any(o.type in ['CAMERA','LIGHT'] for o in bpy.context.scene.objects)},
]
data={'checks':checks,'passed':sum(c['pass'] for c in checks),'failed':sum(not c['pass'] for c in checks),'mesh_batches':len(objects),'used_materials':sorted(m.name for m in used),'collections':sorted(c.name for c in bpy.data.collections if c.objects),'mutated':False}
(R/'reports/environment-conversion-stages-2-3'/(short+'-native-audit.json')).write_text(json.dumps(data,indent=2))
print(short,data['passed'],'PASS /',data['failed'],'FAIL')

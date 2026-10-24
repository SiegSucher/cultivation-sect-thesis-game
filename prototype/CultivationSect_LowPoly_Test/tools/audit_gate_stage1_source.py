"""Reopen the new gate source; remove only unused imported material datablocks."""
from pathlib import Path
import bpy,json
R=Path(__file__).resolve().parents[1]
path=R/'source/sect_gate_low_poly.blend'
bpy.ops.wm.open_mainfile(filepath=str(path))
removed=[]
for mat in list(bpy.data.materials):
    if mat.users==0:
        removed.append(mat.name);bpy.data.materials.remove(mat)
for image in list(bpy.data.images):
    if image.users==0:bpy.data.images.remove(image)
bpy.ops.wm.save_as_mainfile(filepath=str(path))
objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
used={m for o in objects for m in o.data.materials}
textures=[m.name for m in used if any(n.type=='TEX_IMAGE' for n in m.node_tree.nodes)]
checks=[{'check':'Metric scale','pass':bpy.context.scene.unit_settings.system=='METRIC' and bpy.context.scene.unit_settings.scale_length==1},{'check':'Four representation/leaf collections','pass':all(bpy.data.collections.get(n) for n in ['GateNear','GateDistant','LeftLeaf','RightLeaf'])},{'check':'No texture nodes on used materials','pass':not textures},{'check':'28 editable material batches','pass':len(objects)==28},{'check':'Eleven used palette materials','pass':len(used)==11}]
(R/'reports/environment-conversion-stage-1/native-source-audit.json').write_text(json.dumps({'checks':checks,'passed':sum(c['pass'] for c in checks),'failed':sum(not c['pass'] for c in checks),'unused_materials_removed':removed,'visible_mesh_reexported':False},indent=2))
print(json.dumps(checks))

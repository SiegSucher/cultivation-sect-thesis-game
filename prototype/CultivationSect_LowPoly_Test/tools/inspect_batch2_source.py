"""Reopen the copied shared Blender source read-only, collection by collection."""
import bpy,json
from pathlib import Path
R=Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(R/'source/claude_batch2_integrated.blend'))
checks=[];collections=[]
def check(name,ok): checks.append({'check':name,'pass':bool(ok)})
for name,batches,triangles in [('AlchemyPavilion',13,25586),('MedicineHall',15,20636)]:
    collection=bpy.data.collections.get(name)
    check(name+' editable collection',collection is not None)
    objects=[o for o in collection.all_objects if o.type=='MESH'] if collection else []
    count=0
    for o in objects:
        o.data.calc_loop_triangles();count+=len(o.data.loop_triangles)
    check(name+' expected batches',len(objects)==batches)
    check(name+' expected triangles',count==triangles)
    check(name+' flat polygons',all(not p.use_smooth for o in objects for p in o.data.polygons))
    check(name+' no image textures',all(n.type!='TEX_IMAGE' for o in objects for m in o.data.materials if m and m.node_tree for n in m.node_tree.nodes))
    collections.append({'name':name,'mesh_batches':len(objects),'triangles':count})
check('metric metres',bpy.context.scene.unit_settings.system=='METRIC' and bpy.context.scene.unit_settings.scale_length==1)
failed=sum(not c['pass'] for c in checks)
out={'passed':len(checks)-failed,'failed':failed,'checks':checks,'collections':collections,'source_saved':False}
(R/'reports/codex-alchemy-medicine/native-source.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps(out,indent=2))
if failed:raise RuntimeError('Native source check failed')

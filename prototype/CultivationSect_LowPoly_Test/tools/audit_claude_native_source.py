"""Read-only reopening of the canonical native source; no rebuild/save."""
from pathlib import Path
import bpy,json
R=Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(R/'source/claude_buildings_integrated.blend'))
names={'disciple_residence':'DisciplesResidence','elder_residence':'ElderResidence','dining_hall_kitchen':'DiningHallKitchen','spirit_herb_garden':'SpiritHerbGarden'}
summary=json.loads((R/'staging/claude_buildings/build_summary.json').read_text())
checks=[];records=[]
for aid,name in names.items():
    col=bpy.data.collections.get(name)
    meshes=[o for o in col.objects if o.type=='MESH'] if col else []
    tris=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in meshes)
    used={m for o in meshes for m in o.data.materials}
    checks.append({'check':aid+' editable collection/counts','pass':bool(meshes) and tris==summary[aid]['triangles'] and len(meshes)==summary[aid]['surfaces']})
    checks.append({'check':aid+' flat texture-free source','pass':bool(used) and all(not p.use_smooth for o in meshes for p in o.data.polygons) and all(not any(n.type=='TEX_IMAGE' for n in m.node_tree.nodes) for m in used)})
    records.append({'asset':aid,'collection':name,'triangles':tris,'mesh_batches':len(meshes),'materials':sorted(m.name for m in used)})
checks.append({'check':'Metric metres/unit scale','pass':bpy.context.scene.unit_settings.system=='METRIC' and bpy.context.scene.unit_settings.scale_length==1})
data={'checks':checks,'passed':sum(c['pass'] for c in checks),'failed':sum(not c['pass'] for c in checks),'collections':records,'source_mutated':False,'limit':'Four alternative asset collections overlap at the authoring origin; isolate a collection for editing, not a town arrangement.'}
(R/'reports/codex-claude-integration/native-source-audit.json').write_text(json.dumps(data,indent=2))
print(data['passed'],'PASS /',data['failed'],'FAIL')

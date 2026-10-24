"""Read-only Blender reopening. Never save or re-export the delivery."""
import bpy
import json
from pathlib import Path
R = Path(__file__).resolve().parents[1]
source = R / 'source/claude_mission_hall_integrated.blend'
bpy.ops.wm.open_mainfile(filepath=str(source))
meshes = [o for o in bpy.data.objects if o.type == 'MESH']
triangles = 0
for obj in meshes:
    obj.data.calc_loop_triangles()
    triangles += len(obj.data.loop_triangles)
checks = {
    '12 editable material batches': len(meshes) == 12,
    '17790 source triangles': triangles == 17790,
    'metric metres': bpy.context.scene.unit_settings.system == 'METRIC' and bpy.context.scene.unit_settings.scale_length == 1,
    'flat polygons': all(not p.use_smooth for o in meshes for p in o.data.polygons),
    'no source image textures': all(n.type != 'TEX_IMAGE' for m in bpy.data.materials if m.use_nodes for n in m.node_tree.nodes),
}
out = {'passed': sum(checks.values()), 'failed': sum(not v for v in checks.values()), 'checks': checks,
       'collections': [c.name for c in bpy.data.collections], 'mesh_objects': [o.name for o in meshes], 'triangles': triangles,
       'source_saved': False}
(R/'reports/codex-mission-hall/native-source.json').write_text(json.dumps(out, indent=2), encoding='utf-8')
print(json.dumps(out, indent=2))
if out['failed']: raise RuntimeError('Source inspection failed')

"""Read-only Blender source inspection; no save/export/mesh modification."""
from pathlib import Path
import bpy
import json
import numpy as np

root = Path(__file__).resolve().parents[2]
bpy.ops.wm.open_mainfile(filepath=str(root/'source/martial_training_ground_low_poly.blend'))
rows = []
for obj in bpy.context.scene.objects:
    if obj.type != 'MESH':
        continue
    mesh = obj.data
    mesh.calc_loop_triangles()
    xyz = np.empty(len(mesh.vertices)*3, dtype=np.float32)
    mesh.vertices.foreach_get('co', xyz)
    xyz = xyz.reshape(-1, 3).astype(float)
    ids = np.empty(len(mesh.loop_triangles)*3, dtype=np.int32)
    mesh.loop_triangles.foreach_get('vertices', ids)
    t = xyz[ids.reshape(-1, 3)]
    cross = np.cross(t[:,1]-t[:,0], t[:,2]-t[:,0])
    area2 = np.sum(cross*cross, axis=1)
    rows.append({'object':obj.name,'triangles':len(t),'zero_area':int(np.sum(area2==0)),
                 'near_zero_area_squared_below_1e_20':int(np.sum(area2<1e-20)),
                 'finite':bool(np.all(np.isfinite(xyz)))})
data={'source':'source/martial_training_ground_low_poly.blend','read_only':True,
      'objects':rows,'zero_area_total':sum(x['zero_area'] for x in rows),
      'near_zero_total':sum(x['near_zero_area_squared_below_1e_20'] for x in rows)}
(root/'reports/training-ground-fix/native-source.json').write_text(json.dumps(data,indent=2))
print('Read-only native source:',len(rows),'meshes;',data['zero_area_total'],'zero-area triangles')

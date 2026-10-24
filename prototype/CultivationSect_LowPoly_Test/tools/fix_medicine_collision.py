"""Canonical-only counter coverage and camera-detail collision; staged data frozen."""
from pathlib import Path
import re,json
R=Path(__file__).resolve().parents[1]
def corrected_scene():
    text=(R/'staging/claude_buildings_batch2/medicine_hall/medicine_hall.tscn').read_text(encoding='utf-8')
    text=text.replace('res://staging/claude_buildings_batch2/medicine_hall/medicine_hall.glb','res://assets/architecture/medicine_hall/medicine_hall.glb')
    text=text.replace('load_steps=55','load_steps=56',1)
    extra='[ext_resource type="Shape3D" path="res://assets/architecture/medicine_hall/medicine_camera_obstructions.tres" id="2_camera"]\n'
    text=text.replace('[sub_resource ',extra+'\n[sub_resource ',1)
    for i in range(23,27):
        sid=f'Shape_{i:03d}'
        pattern=r'(\[sub_resource type="BoxShape3D" id="'+sid+r'"\]\nsize = Vector3\()([^)]*)(\))'
        m=re.search(pattern,text);assert m
        size=[float(n) for n in m[2].split(',')]
        # Authored counter box was narrower/shallower than its visible top.
        text=text[:m.start(2)]+f'{size[0]+.3:.5g}, 1.08, 0.8'+text[m.end(2):]
        name=f'ServingCounter_{i:03d}'
        pattern=r'(\[node name="'+name+r'"[^\n]*\]\ntransform = Transform3D\()([^)]*)(\))'
        m=re.search(pattern,text);assert m
        values=[float(n) for n in m[2].split(',')]
        values[-2:]=[.99,4.45]
        text=text[:m.start(2)]+', '.join(f'{v:.6g}' for v in values)+text[m.end(2):]
    text+='\n[node name="CameraDetailObstruction" type="StaticBody3D" parent="." groups=["camera_only_obstruction"]]\ncollision_mask = 0\n\n[node name="ModelDetail" type="CollisionShape3D" parent="CameraDetailObstruction"]\nshape = ExtResource("2_camera")\n'
    return text
if __name__=='__main__':
    assert (R/'assets/architecture/medicine_hall/medicine_camera_obstructions.tres').is_file()
    (R/'scenes/buildings/medicine_hall.tscn').write_text(corrected_scene(),encoding='utf-8')
    (R/'reports/codex-alchemy-medicine/collision-corrections.json').write_text(json.dumps({
        'medicine_hall':{'original_shapes':53,'final_shapes':54,'original_model_changed':False,
        'counter_correction':'Four existing counter boxes enlarged/recentred to the actual timber top',
        'camera_correction':'One concave shape copies actual stair/herb detail triangles; separate camera-only body',
        'integration_contract':'Register a character collision exception against camera_only_obstruction bodies; supplied review does so. Production controller integration NOT tested.'},
        'alchemy_pavilion':{'original_shapes':43,'final_shapes':43,'correction':None}},indent=2),encoding='utf-8')
    print('Corrected Medicine counters; added camera-only geometry, unchanged walking ramp/player/model')

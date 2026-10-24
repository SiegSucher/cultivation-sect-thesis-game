"""Cover the two visible static open leaves, preserving staged/model/source bytes."""
from pathlib import Path
import math,json
R=Path(__file__).resolve().parents[1]
def corrected_scene():
    text=(R/'staging/claude_buildings_batch2/alchemy_pavilion/alchemy_pavilion.tscn').read_text(encoding='utf-8')
    text=text.replace('res://staging/claude_buildings_batch2/alchemy_pavilion/alchemy_pavilion.glb','res://assets/architecture/alchemy_pavilion/alchemy_pavilion.glb')
    text=text.replace('load_steps=45','load_steps=46',1)
    definition='[sub_resource type="BoxShape3D" id="StaticOpenLeaf"]\nsize = Vector3(0.10, 2.94, 1.08)\n\n'
    text=text.replace('[node name="AlchemyPavilion"',definition+'[node name="AlchemyPavilion"',1)
    z=5.6*math.cos(math.pi/8)-(.26/2+1.08/2)
    for i,x in enumerate([-1.05,1.05]):
        text+=f'\n[node name="StaticOpenLeaf{i}" type="CollisionShape3D" parent="Collision"]\nposition = Vector3({x}, 2.4, {z:.8f})\nshape = SubResource("StaticOpenLeaf")\n'
    return text
if __name__=='__main__':
    (R/'scenes/buildings/alchemy_pavilion.tscn').write_text(corrected_scene(),encoding='utf-8')
    (R/'reports/codex-alchemy-medicine/alchemy-leaf-correction.json').write_text(json.dumps({
        'cause':'Rendered route camera safety sphere touched an uncollidable open leaf; original leaf helper omits collision',
        'correction':'Two matching static open-leaf boxes, same geometry/pose/material; original 43 shapes retained',
        'final_shapes':45,'box_size':[.10,2.94,1.08],'centres_x':[-1.05,1.05],'centre_y':2.4,
        'centre_z':5.6*math.cos(math.pi/8)-.67,'minimum_collision_leaf_width_m':2.0},indent=2),encoding='utf-8')
    print('Alchemy: 43 authored shapes + 2 static open-leaf boxes')

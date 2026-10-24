"""Cover four static storeroom leaves so the unchanged camera sweep sees them.

Claude's leaves() helper places .78 m open leaves centred at x=+/-5.52 and
z=-2.4+/- .75. The .10 m thickness includes the cedar crossbars. The builder
omits collision for these visible leaves. Add matching boxes to the canonical
scene only; preserve all 69 delivered shapes, model, materials and source.
"""
from pathlib import Path
import json

R = Path(__file__).resolve().parents[1]
S = R/'staging/claude_exchange_hall/exchange_hall/exchange_hall.tscn'
P = R/'scenes/buildings/exchange_hall.tscn'

def corrected_scene():
    text = S.read_text(encoding='utf-8').replace(
        'res://staging/claude_exchange_hall/exchange_hall/exchange_hall.glb',
        'res://assets/architecture/exchange_hall/exchange_hall.glb')
    text = text.replace('load_steps=71', 'load_steps=72')
    definition = '[sub_resource type="BoxShape3D" id="OpenStoreroomLeaf"]\nsize = Vector3(0.78, 2.54, 0.10)\n\n'
    text = text.replace('[node name="ExchangeHall"', definition+'[node name="ExchangeHall"', 1)
    nodes = []
    for side, x in [('East',5.52), ('West',-5.52)]:
        for index, z in enumerate([-3.15,-1.65]):
            nodes.append(f'\n[node name="{side}StaticLeaf{index}" type="CollisionShape3D" parent="Collision"]\n'
                         f'position = Vector3({x}, 1.9, {z})\nshape = SubResource("OpenStoreroomLeaf")\n')
    return text+''.join(nodes)

if __name__ == '__main__':
    assert P.is_file()
    expected_before = S.read_text(encoding='utf-8').replace(
        'res://staging/claude_exchange_hall/exchange_hall/exchange_hall.glb',
        'res://assets/architecture/exchange_hall/exchange_hall.glb')
    assert P.read_text(encoding='utf-8') in [expected_before,corrected_scene()], 'Unexpected existing scene edits'
    P.write_text(corrected_scene(),encoding='utf-8')
    (R/'reports/codex-exchange-hall/collision-correction.json').write_text(json.dumps({
        'cause':'Four visible static storeroom leaves were absent from authored collision and camera sweeps',
        'change':'One shared box resource; four matching static-leaf collision nodes, canonical scene only',
        'original_shapes_preserved':69,'added_shapes':4,'total_shapes':73,
        'leaf_box_size':[.78,2.54,.10],'centres':[[x,1.9,z] for x in [5.52,-5.52] for z in [-3.15,-1.65]],
        'model_source_material_changes':False,'controller_changes':False,
        'minimum_collision_door_width_between_leaves_m':1.4
    },indent=2),encoding='utf-8')
    print('Canonical scene: 69 original shapes + 4 static-leaf boxes. No visible/source change.')

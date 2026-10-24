"""Append confirmed leaf collision to permanent scenes; never rebuild staging.

Run without arguments to write the inspection manifest. --apply additionally
requires successful before-probes and exact task-start permanent scene hashes.
The six GLBs/native sources and every existing resource/node are preserved.
"""
from pathlib import Path
import hashlib
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'reports/door-collision-fix'
FACING = {'+z': (1, 0, 0, 1), '-z': (-1, 0, 0, -1),
          '+x': (0, -1, 1, 0), '-x': (0, 1, -1, 0)}


def door(asset, name, origin, width, height, floor, u=0, thickness=.24, existing=False):
    a, b, c, d = FACING[origin[2]]
    lw = width / 2 - .02
    leaves = []
    for side in (-1, 1):
        # Union of .06 timber and the .03 cedar strips shifted .035 inward:
        # [-.05,+.03] for the positive leaf, mirrored for the negative leaf.
        along = u + side * (width / 2 - .05) - side * .01
        normal = -(thickness / 2 + lw / 2)
        pos = [origin[0] + a * along + c * normal, floor + height / 2,
               origin[1] + b * along + d * normal]
        size = [.08, height - .06, lw] if a else [lw, height - .06, .08]
        leaves.append({'side': side, 'position': pos, 'size': size})
    return {'asset': asset, 'name': name, 'origin': origin, 'u': u, 'width': width,
            'height': height, 'floor': floor, 'thickness': thickness,
            'axis_u': [a, 0, b], 'axis_n': [c, 0, d], 'leaves': leaves,
            'already_corrected': existing, 'minimum_clear_width': width - .20}


DOORS = [
    door('mission_hall', 'MainEntrance', [0, 3.5, '+z'], 3, 3.4, .75),
    door('exchange_hall', 'MainEntrance', [0, 5, '+z'], 3.2, 3.6, .6, thickness=.26),
    door('dining_hall_kitchen', 'MainEntrance', [0, 4.4, '+z'], 3, 3.3, .6),
    door('dining_hall_kitchen', 'WestEntrance', [0, 4.4, '+z'], 1.5, 2.6, .6, u=-6),
    door('dining_hall_kitchen', 'EastEntrance', [0, 4.4, '+z'], 1.5, 2.6, .6, u=6),
    door('dining_hall_kitchen', 'KitchenService', [5.6, -8.2, '+x'], 1.4, 2.5, .6),
    *[door('disciple_residence', f'Room{i+1}', [0, 2, '+z'], 1.3, 2.45, .5, u=x)
      for i, x in enumerate([-6.6, -2.2, 2.2, 6.6])],
    door('elder_residence', 'MainEntrance', [0, -2.4, '+z'], 2.2, 2.9, 1),
    door('elder_residence', 'AttendantWing', [7.4, 4, '-x'], 1.2, 2.3, .31),
    door('medicine_hall', 'BalconyEntrance', [0, 4.5, '+z'], 1.6, 2.4, 4.2),
    # Inspect/protect the earlier corrected storerooms too; never append duplicates.
    door('exchange_hall', 'EastStoreroom', [5, 0, '-x'], 1.6, 2.6, .6,
         u=-2.4, thickness=.26, existing=True),
    door('exchange_hall', 'WestStoreroom', [-5, 0, '+x'], 1.6, 2.6, .6,
         u=2.4, thickness=.26, existing=True),
]


def vec(values):
    return 'Vector3(' + ', '.join(f'{v:.9g}' for v in values) + ')'


def corrected(text, doors):
    definitions = []
    nodes = []
    for entry in doors:
        rid = 'DoorLeaf_' + entry['name']
        definitions.append(f'[sub_resource type="BoxShape3D" id="{rid}"]\n'
                           f'size = {vec(entry["leaves"][0]["size"])}\n\n')
        for leaf in entry['leaves']:
            name = rid + ('_Left' if leaf['side'] < 0 else '_Right')
            nodes.append(f'\n[node name="{name}" type="CollisionShape3D" parent="Collision"]\n'
                         f'position = {vec(leaf["position"])}\nshape = SubResource("{rid}")\n')
    first_node = text.index('[node ')
    result = text[:first_node] + ''.join(definitions) + text[first_node:] + ''.join(nodes)
    result = re.sub(r'load_steps=(\d+)', lambda m: f'load_steps={int(m[1])+len(doors)}', result, count=1)
    return result


def main():
    assert OUT.is_dir(), 'Freeze the current permanent scenes before using this tool'
    (OUT / 'door-manifest.json').write_text(json.dumps(DOORS, indent=2))
    if '--apply' not in sys.argv:
        print('Inspection manifest: 13 reported openings / 26 leaves, plus 4 preserved storeroom leaves')
        return
    before = json.loads((OUT / 'before-probes.json').read_text())
    assert before['failed'] == 0 and len(before['doors']) == len(DOORS)
    for row in before['doors']:
        expected = 30 if row['already_corrected'] else 0
        assert row['visible_ray_hits'] == 30 and row['solid_ray_hits'] == expected, row
    snapshot = json.loads((OUT / 'before-hashes.json').read_text())['test']
    changes = []
    for asset in dict.fromkeys(d['asset'] for d in DOORS):
        path = ROOT / f'scenes/buildings/{asset}.tscn'
        original = (OUT / 'before' / path.name).read_text()
        entries = [d for d in DOORS if d['asset'] == asset and not d['already_corrected']]
        candidate = corrected(original, entries)
        current = path.read_text()
        if current != candidate:
            assert hashlib.sha256(path.read_bytes()).hexdigest() == snapshot[path.relative_to(ROOT).as_posix()], f'Unexpected scene edit: {path}'
            path.write_text(candidate)
        changes.append({'asset': asset, 'file': path.relative_to(ROOT).as_posix(),
                        'added_resources': len(entries), 'added_shapes': len(entries)*2})
    (OUT / 'changes.json').write_text(json.dumps(changes, indent=2))
    print('Appended 26 leaf boxes in six permanent scenes; all existing nodes/resources retained')


if __name__ == '__main__':
    main()

"""Measure the permanent GLB, then repair only confirmed rear-veranda collision.

Default: diagnosis and candidate only. --apply requires unchanged task-start
bytes and successful independent before-probes. No Blender exporter is run.
"""
from pathlib import Path
import argparse
import copy
import hashlib
import json
import re
import struct

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'reports/main-hall-collision-fix'
REL = 'assets/architecture/tang_main_hall/main_sect_hall.json'


def components(material_name):
    """Join actual indexed triangles at identical positions, across flat normals."""
    raw = (ROOT / 'assets/architecture/tang_main_hall/main_sect_hall.glb').read_bytes()
    assert struct.unpack_from('<III', raw) == (0x46546C67, 2, len(raw))
    length, kind = struct.unpack_from('<II', raw, 12)
    assert kind == 0x4E4F534A
    gltf = json.loads(raw[20:20 + length])
    binary_length, binary_kind = struct.unpack_from('<II', raw, 20 + length)
    assert binary_kind == 0x004E4942
    binary = raw[28 + length:28 + length + binary_length]

    def accessor(index):
        a = gltf['accessors'][index]
        view = gltf['bufferViews'][a['bufferView']]
        assert not a.get('sparse') and not a.get('normalized')
        code = {5126: 'f', 5125: 'I', 5123: 'H', 5121: 'B'}[a['componentType']]
        count = {'SCALAR': 1, 'VEC3': 3}[a['type']]
        fmt = '<' + code * count
        stride = view.get('byteStride', struct.calcsize(fmt))
        start = view.get('byteOffset', 0) + a.get('byteOffset', 0)
        return [struct.unpack_from(fmt, binary, start + i * stride) for i in range(a['count'])]

    result = []
    for node in gltf['nodes']:
        if 'mesh' not in node:
            continue
        assert not any(k in node for k in ('matrix', 'translation', 'rotation', 'scale'))
        for primitive in gltf['meshes'][node['mesh']]['primitives']:
            if gltf['materials'][primitive['material']]['name'] != material_name:
                continue
            vertices = accessor(primitive['attributes']['POSITION'])
            indices = [x[0] for x in accessor(primitive['indices'])]
            unique = {}
            welded = []
            for v in vertices:
                unique.setdefault(v, len(unique))
                welded.append(unique[v])
            parents = list(range(len(unique)))

            def find(i):
                while parents[i] != i:
                    parents[i] = parents[parents[i]]
                    i = parents[i]
                return i

            for i in range(0, len(indices), 3):
                a, b, c = (find(welded[j]) for j in indices[i:i + 3])
                parents[b] = a
                parents[c] = a
            groups = {}
            for v, i in unique.items():
                groups.setdefault(find(i), []).append(v)
            for points in groups.values():
                low = [min(v[k] for v in points) for k in range(3)]
                high = [max(v[k] for v in points) for k in range(3)]
                result.append({'min': low, 'max': high,
                               'centre': [round((a + b) / 2, 6) for a, b in zip(low, high)],
                               'size': [round(b - a, 6) for a, b in zip(low, high)]})
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    original = (OUT / 'before/main_sect_hall.json.txt').read_bytes()
    old = json.loads(original)
    measured = {}
    for name, material, size in [('column', 'Timber', [.64, 5.31, .64]),
                                 ('drum', 'Coping', [.85, .6, .85])]:
        measured[name] = sorted([c for c in components(material)
                                if abs(c['centre'][2] + 9.6) < .001
                                and all(abs(a-b) < .001 for a, b in zip(c['size'], size))],
                               key=lambda c: c['centre'][0])
        assert len(measured[name]) == 8, (name, measured[name])
    assert [c['centre'][0] for c in measured['column']] == [-18, -14.4, -10.8, -7.2, 7.2, 10.8, 14.4, 18]
    candidate = copy.deepcopy(old)
    changes = []
    for i, record in enumerate(old['solid_shapes']):
        if record['name'] not in ('Substantial veranda column', 'Veranda column stone drum') or record['position'][2] != -10:
            continue
        kind = 'column' if record['type'] == 'cylinder' else 'drum'
        nearest = min(measured[kind], key=lambda c: abs(c['centre'][0] - record['position'][0]))
        row = {'old_index': i, 'name': record['name'], 'kind': kind,
               'old_position': record['position'], 'action': 'move'}
        if abs(nearest['centre'][0] - record['position'][0]) > .5:
            assert abs(abs(record['position'][0]) - 3.65) < .001
            row.update(action='remove_unmatched', new_position=None, visible=None)
        else:
            row.update(new_position=[nearest['centre'][0], record['position'][1], nearest['centre'][2]], visible=nearest)
            candidate['solid_shapes'][i]['position'] = row['new_position']
        changes.append(row)
    assert len(changes) == 20
    removed = {r['old_index'] for r in changes if r['action'] == 'remove_unmatched'}
    assert len(removed) == 4 and sum(r['action'] == 'move' for r in changes) == 16
    candidate['solid_shapes'] = [r for i, r in enumerate(candidate['solid_shapes']) if i not in removed]

    # Change position number tokens or remove just the unmatched object records.
    # Every unrelated byte, including roof collision and metadata, is retained.
    text = original.decode('utf-8')
    decoder = json.JSONDecoder()
    cursor = re.search(r'"solid_shapes"\s*:\s*\[', text).end()
    spans = []
    for record in old['solid_shapes']:
        cursor = re.search(r'\S', text[cursor:]).start() + cursor
        parsed, end = decoder.raw_decode(text, cursor)
        assert parsed == record
        spans.append((cursor, end))
        cursor = end
        comma = re.match(r'\s*,', text[cursor:])
        if comma:
            cursor += comma.end()
    patches = []
    for row in changes:
        i = row['old_index']
        start, end = spans[i]
        if row['action'] == 'remove_unmatched':
            patches.append((start, spans[i + 1][0], ''))
        else:
            position = re.search(r'"position"\s*:\s*\[([^\]]+)\]', text[start:end])
            tokens = list(re.finditer(r'-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?', position[1]))
            assert len(tokens) == 3
            for axis in (0, 2):
                token = tokens[axis]
                a = start + position.start(1) + token.start()
                b = start + position.start(1) + token.end()
                patches.append((a, b, str(float(row['new_position'][axis]))))
    for a, b, replacement in sorted(patches, reverse=True):
        text = text[:a] + replacement + text[b:]
    assert json.loads(text) == candidate
    for k in old:
        if k != 'solid_shapes':
            assert candidate[k] == old[k]
    plan = {'source': REL, 'visible_components': measured, 'changes': changes,
            'before_shapes': len(old['solid_shapes']), 'after_shapes': len(candidate['solid_shapes']),
            'moved': 16, 'removed_unmatched': 4,
            'before_sha256': hashlib.sha256(original).hexdigest(),
            'candidate_sha256': hashlib.sha256(text.encode()).hexdigest(),
            'limits': 'Only rear column/drum records. Front colonnade and every unrelated record preserved.'}
    (OUT / 'alignment-plan.json').write_text(json.dumps(plan, indent=2), encoding='utf-8')
    (OUT / 'candidate-main_sect_hall.json').write_bytes(text.encode())
    if args.apply:
        assert (ROOT / REL).read_bytes() == original, 'Permanent JSON changed; stop for review'
        before = json.loads((OUT / 'before-headless.json').read_text())
        assert before['failed'] == 0 and before['confirmed_columns_and_drums']
        (ROOT / REL).write_bytes(text.encode())
    print(json.dumps({'moved': 16, 'removed_unmatched': 4, 'before_shapes': len(old['solid_shapes']),
                      'after_shapes': len(candidate['solid_shapes']), 'applied': args.apply}))


if __name__ == '__main__':
    main()

"""Standalone GLB geometry/material audit (same criteria Codex applied to batch 1).

python -I audit_glb.py OUT.json MODEL.glb [MODEL.glb ...]
Checks: exact Split-Cloud palette (linear baseColor within 2e-5), roughness,
metallic 0, opaque, no images/textures/external URIs, finite positions, unit
normals, flat triangles (3 identical vertex normals matching the face), and no
near-zero-area triangles. Exits 1 if any model fails.
"""
import json, math, struct, sys
from pathlib import Path

PALETTE = {'Stone': '667e88', 'Coping': 'bcc6bd', 'Timber': '432d2d', 'Cedar': '896048', 'Jade': '22594f',
           'TileLight': '46796b', 'Plaster': 'e6d9b8', 'Window': '284c53', 'Bronze': 'cda668', 'Floor': '85624d',
           'Lantern': 'ffda91', 'Fabric': '456e73', 'Soil': '5d4a3a', 'Leaf': '4d7d4f', 'SpiritHerb': '8fe0c0', 'Water': '2c5f63'}
FMT = {5126: ('f', 4), 5125: ('I', 4), 5123: ('H', 2), 5121: ('B', 1)}
SIZE = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}

def audit(path):
    raw = Path(path).read_bytes()
    n = struct.unpack_from('<I', raw, 12)[0]
    j = json.loads(raw[20:20+n])
    binary = raw[20+n+8:]
    def read(i):
        acc = j['accessors'][i]
        view = j['bufferViews'][acc['bufferView']]
        code, width = FMT[acc['componentType']]
        k = SIZE[acc['type']]
        start = view.get('byteOffset', 0)+acc.get('byteOffset', 0)
        stride = view.get('byteStride', width*k)
        return [struct.unpack_from('<'+code*k, binary, start+i*stride) for i in range(acc['count'])]
    r = {'model': str(path), 'images': len(j.get('images', [])), 'textures': len(j.get('textures', [])),
         'external_uris': [b['uri'] for b in j.get('buffers', []) if 'uri' in b], 'triangles': 0,
         'zero_area_triangles': 0, 'invalid_normals': 0, 'nonfinite_positions': 0, 'nonflat_triangles': 0,
         'material_errors': []}
    for m in j['materials']:
        name, pbr = m['name'], m['pbrMetallicRoughness']
        if name not in PALETTE:
            r['material_errors'].append(name+': not in palette'); continue
        rgb = [int(PALETTE[name][i:i+2], 16)/255 for i in (0, 2, 4)]
        lin = [v/12.92 if v < .04045 else ((v+.055)/1.055)**2.4 for v in rgb]+[1]
        if max(abs(a-b) for a, b in zip(lin, pbr['baseColorFactor'])) > 2e-5: r['material_errors'].append(name+': colour')
        if abs(pbr.get('roughnessFactor', 1)-{'Bronze': .56, 'Water': .5}.get(name, .82)) > 1e-5: r['material_errors'].append(name+': roughness')
        if pbr.get('metallicFactor', 1) != 0: r['material_errors'].append(name+': metallic')
        if m.get('alphaMode', 'OPAQUE') != 'OPAQUE': r['material_errors'].append(name+': not opaque')
    r['materials'] = [m['name'] for m in j['materials']]
    for mesh in j['meshes']:
        for prim in mesh['primitives']:
            pos, nor = read(prim['attributes']['POSITION']), read(prim['attributes']['NORMAL'])
            idx = [v[0] for v in read(prim['indices'])] if 'indices' in prim else list(range(len(pos)))
            r['nonfinite_positions'] += sum(not all(math.isfinite(c) for c in p) for p in pos)
            r['invalid_normals'] += sum(abs(math.sqrt(sum(c*c for c in v))-1) > 1e-3 for v in nor)
            for t in range(0, len(idx), 3):
                a, b, c = (pos[idx[t+k]] for k in range(3))
                e1 = [b[i]-a[i] for i in range(3)]; e2 = [c[i]-a[i] for i in range(3)]
                cr = [e1[1]*e2[2]-e1[2]*e2[1], e1[2]*e2[0]-e1[0]*e2[2], e1[0]*e2[1]-e1[1]*e2[0]]
                area = math.sqrt(sum(v*v for v in cr))/2
                r['triangles'] += 1
                if area < 1e-8:
                    r['zero_area_triangles'] += 1; continue
                fn = [v/(2*area) for v in cr]
                ns = [nor[idx[t+k]] for k in range(3)]
                if any(sum(fn[i]*v[i] for i in range(3)) < .999 for v in ns): r['nonflat_triangles'] += 1
    r['pass'] = (not r['images'] and not r['textures'] and not r['external_uris'] and not r['material_errors']
                 and not r['zero_area_triangles'] and not r['invalid_normals'] and not r['nonfinite_positions']
                 and not r['nonflat_triangles'])
    return r

if __name__ == '__main__':
    results = [audit(p) for p in sys.argv[2:]]
    Path(sys.argv[1]).write_text(json.dumps(results, indent=2))
    for x in results:
        print(('PASS ' if x['pass'] else 'FAIL ')+Path(x['model']).name, {k: x[k] for k in ('triangles', 'zero_area_triangles', 'invalid_normals', 'nonflat_triangles', 'images', 'textures', 'material_errors')})
    sys.exit(0 if all(x['pass'] for x in results) else 1)

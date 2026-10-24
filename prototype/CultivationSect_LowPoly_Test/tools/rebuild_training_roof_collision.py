"""Replay the original roof math; normalize collapsed polygon corners before
collision triangulation. No Blender mesh/export code is executed or modified.
Default: diagnosis + candidate only. --apply requires exact frozen JSON bytes.
"""
from pathlib import Path
import ast
import copy
import hashlib
import json
import math
import sys
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'reports/training-ground-fix'
PATH = ROOT / 'assets/architecture/martial_training_ground/martial_training_ground.json'


def triangles(flat):
    return [flat[i:i+3] for i in range(0, len(flat), 3)]


def area_squared(t):
    a, b, c = np.asarray(t)
    return float(np.dot(np.cross(b-a, c-a), np.cross(b-a, c-a)))


def main():
    original_bytes = (OUT / 'before/martial_training_ground.json.txt').read_bytes()
    original = json.loads(original_bytes)
    author = ast.parse((OUT / 'before/build_training_ground.py.txt').read_text())
    design = ast.parse((OUT / 'before/training_design.py.txt').read_text())
    roof = next(n for n in author.body if isinstance(n, ast.FunctionDef) and n.name == 'roof')
    pavilion = next(n for n in design.body if isinstance(n, ast.FunctionDef) and n.name == 'pavilion')
    roof_call = next(n.value for n in pavilion.body if isinstance(n, ast.Expr) and isinstance(n.value, ast.Call) and isinstance(n.value.func, ast.Name) and n.value.func.id == 'roof')
    calls = [n.value for n in design.body if isinstance(n, ast.Expr) and isinstance(n.value, ast.Call) and isinstance(n.value.func, ast.Name) and n.value.func.id == 'pavilion']
    args = []
    for call in calls:
        values = [ast.literal_eval(a) for a in call.args]
        env = dict(zip([a.arg for a in pavilion.args.args], values))
        env.setdefault('demonstration', False)
        env['eave'] = env['floor'] + 3.3
        args.append([eval(compile(ast.Expression(a), '<roof argument>', 'eval'), {}, env) for a in roof_call.args])

    parts = []
    fixed_meta = []

    def replay(fixed):
        flat = []

        def emit(bottom, face, name, side):
            points = [p.tolist() for p in (bottom[i] for i in face)]
            # At a closed hip ridge the last two corners coincide. Collapse
            # consecutive duplicates before making a fan, preserving winding.
            unique = []
            for point in points:
                if not unique or point != unique[-1]:
                    unique.append(point)
            if len(unique) > 1 and unique[0] == unique[-1]:
                unique.pop()
            if len(unique) != len(points):
                fixed_meta.append({'roof': name, 'side': side, 'old_corners': len(points), 'new_corners': len(unique)})
            for k in range(1, len(unique)-1):
                tri = [unique[0], unique[k], unique[k+1]]
                assert area_squared(tri) > 0, 'Unexpected collinear geometry; stop rather than discard it'
                flat.extend(tri)

        node = copy.deepcopy(roof)
        if fixed:
            class ReplaceFan(ast.NodeTransformer):
                def visit_For(self, n):
                    if isinstance(n.target, ast.Name) and n.target.id == 'k' and ast.unparse(n.iter) == 'range(1, len(face) - 1)':
                        return ast.Expr(ast.Call(ast.Name('_emit', ast.Load()), [ast.Name(x, ast.Load()) for x in ['bottom','face','name','side']], []))
                    return self.generic_visit(n)
            node = ReplaceFan().visit(node)
        namespace = {'np': np, 'math': math, 'roof_faces': flat,
                     'geometry': lambda *a, **k: None, 'rod': lambda *a, **k: None,
                     'beam': lambda *a, **k: None, '_emit': emit}
        exec(compile(ast.fix_missing_locations(ast.Module([node], [])), '<collision-only roof replay>', 'exec'), namespace)
        for params in args:
            start = len(flat)
            namespace['roof'](*params)
            if not fixed:
                ts = triangles(flat[start:])
                bad = [i for i, t in enumerate(ts) if area_squared(t) == 0]
                parts.append({'roof': params[0], 'parameters': params, 'triangles': len(ts),
                              'zero_area': len(bad), 'zero_indices_local': bad,
                              'all_bad_have_repeated_corner': all(len(set(map(tuple, ts[i]))) < 3 for i in bad)})
        return flat

    legacy = replay(False)
    assert legacy == original['roof_collision_faces'], 'Authoring replay does not exactly match current task-start data'
    clean = replay(True)
    old_tri = triangles(legacy)
    new_tri = triangles(clean)
    valid_old = [t for t in old_tri if area_squared(t) > 0]
    assert new_tri == valid_old, 'Valid coordinate/order/winding changed'
    assert len(old_tri) == 4560 and len(new_tri) == 4476
    assert len(fixed_meta) == 84
    candidate = copy.deepcopy(original)
    candidate['roof_collision_faces'] = clean
    assert {k: v for k, v in candidate.items() if k != 'roof_collision_faces'} == {k: v for k, v in original.items() if k != 'roof_collision_faces'}
    (OUT / 'candidate-training-roof.json').write_text(json.dumps(candidate, indent=2))
    evidence = {'roof_parts': parts, 'collapsed_quads': fixed_meta, 'triangles_before': len(old_tri),
                'triangles_after': len(new_tri), 'zero_area_before': 84, 'zero_area_after': 0,
                'legacy_replay_matches_json_exactly': True, 'all_valid_triangles_coordinates_order_winding_identical': True,
                'all_other_json_fields_identical': True,
                'area_before': sum(math.sqrt(area_squared(t))*.5 for t in old_tri),
                'area_after': sum(math.sqrt(area_squared(t))*.5 for t in new_tri),
                'original_sha256': hashlib.sha256(original_bytes).hexdigest(),
                'root_cause': 'Three closed hip roofs x two collapsed end strips x fourteen quads. Manual quad fan emits one valid and one repeated-corner zero-area triangle; polygon-corner normalization prevents the invalid emission.'}
    (OUT / 'source-replay.json').write_text(json.dumps(evidence, indent=2))
    if '--apply' in sys.argv:
        assert PATH.read_bytes() == original_bytes, 'Permanent asset changed since freeze; inspect first'
        PATH.write_text(json.dumps(candidate, indent=2))
        print('Applied collision-only JSON repair; 4,476 valid faces, all other fields preserved')
    else:
        print('Exact source replay confirmed: 84 collapsed quads; 4,560 -> 4,476 candidate faces; permanent asset unchanged')


if __name__ == '__main__':
    main()

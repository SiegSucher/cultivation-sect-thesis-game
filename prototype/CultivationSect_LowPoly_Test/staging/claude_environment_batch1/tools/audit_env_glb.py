"""GLB audit for environment batch 1: the frozen staging/claude_exchange_hall/tools/audit_glb.py
checks, run against this batch's palette (read from the builder, the single source of truth).

python -B audit_env_glb.py OUT.json MODEL.glb [MODEL.glb ...]
"""
import ast, json, sys
from pathlib import Path

sys.dont_write_bytecode = True   # never write __pycache__ into the frozen folder
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[1]/'claude_exchange_hall'/'tools'))
import audit_glb

tree = ast.parse((HERE/'build_environment_batch1.py').read_text(encoding='utf-8'))
audit_glb.PALETTE = next(ast.literal_eval(n.value) for n in tree.body
                         if isinstance(n, ast.Assign) and getattr(n.targets[0], 'id', '') == 'PALETTE')

results = [audit_glb.audit(p) for p in sys.argv[2:]]
Path(sys.argv[1]).write_text(json.dumps(results, indent=2))
for x in results:
    print(('PASS ' if x['pass'] else 'FAIL ')+Path(x['model']).name, {k: x[k] for k in ('triangles', 'zero_area_triangles', 'invalid_normals', 'nonflat_triangles', 'images', 'textures', 'material_errors')})
sys.exit(0 if all(x['pass'] for x in results) else 1)

"""Replay only the author's roof function, never its Blender save/export code.

Use Blender's original float32 mathutils.Vector arithmetic so generated collider
coordinates can be compared exactly with the approved JSON. No visual meshes
are instantiated, saved or exported. --repair applies a proven collision-only
migration; without it this writes diagnosis evidence only.
"""
from pathlib import Path
import ast, json, math, sys, hashlib
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
REPORT=ROOT/'reports/roof-collision-fix-2026-10-22'
REPORT.mkdir(parents=True,exist_ok=True)
PATH=ROOT/'assets/architecture/tang_main_hall/main_sect_hall.json'
AUTHOR=ROOT/'tools/build_split_cloud.py'
tree=ast.parse(AUTHOR.read_text())
roof_node=next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='roof')
faces=[]
namespace={'Vector':Vector,'math':math,'roof_faces':faces,'geo':lambda *a,**kw:None,'beam':lambda *a,**kw:None}
if any(isinstance(n,ast.ImportFrom) and n.module=='roof_collision_geometry' for n in tree.body):
    sys.path.insert(0,str(AUTHOR.parent))
    from roof_collision_geometry import collision_polygon_triangles
    namespace['collision_polygon_triangles']=collision_polygon_triangles
exec(compile(ast.Module(body=[roof_node],type_ignores=[]),str(AUTHOR),'exec'),namespace)

def cross_squared(tri):
    a,b,c=tri
    u=[b[i]-a[i] for i in range(3)];v=[c[i]-a[i] for i in range(3)]
    q=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]]
    return sum(x*x for x in q)
def tris(flat):return [flat[i:i+3] for i in range(0,len(flat),3)]

parts=[]
for node in tree.body:
    call=node.value if isinstance(node,(ast.Expr,ast.Assign)) else None
    if not isinstance(call,ast.Call) or not isinstance(call.func,ast.Name) or call.func.id!='roof':continue
    args=[ast.literal_eval(a) for a in call.args]
    kwargs={k.arg:ast.literal_eval(k.value) for k in call.keywords}
    start=len(faces)
    namespace['roof'](*args,**kwargs)
    section=tris(faces[start:])
    degenerate=[i for i,t in enumerate(section) if cross_squared(t)==0]
    parts.append({'source_line':node.lineno,'arguments':args,'triangles':len(section),'exactly_zero_area':len(degenerate),'zero_area_indices':degenerate,'all_degenerate_faces_have_repeated_corner':all(len({tuple(p) for p in section[i]})<3 for i in degenerate)})

spec=json.loads(PATH.read_text())
current=spec['roof_collision_faces']
repair='--repair' in sys.argv
if not repair:
    assert current[:len(faces)]==faces,'Authoring replay must match the baked collider exactly'
    report={'mode':'diagnose','roof_parts':parts,'matched_authoring_prefix_vertices':len(faces),'gable_suffix_triangles':(len(current)-len(faces))//3,'total_degenerate':sum(p['exactly_zero_area'] for p in parts),'root_cause':'Closed hip end strips have two coincident ridge vertices. A valid quad normal passes the face check, then fan triangulation emits a valid triangle and an exactly collapsed triangle. Four closed roofs x two hip ends x eight strips = 64. The annular belt and folded gable do not collapse.'}
    repaired=(REPORT/'collision-repair.json').exists()
    assert report['total_degenerate']==(0 if repaired else 64)
    destination='source-replay-after.json' if repaired else 'source-diagnosis.json'
    (REPORT/destination).write_text(json.dumps(report,indent=2))
else:
    # The pre-change resource was saved before editing the generator. Existing
    # JSON must still be that exact file: never mutate an unknown scene state.
    before_path=REPORT/'before/main_sect_hall.json'
    assert PATH.read_bytes()==before_path.read_bytes()
    before=json.loads(before_path.read_text())
    previous=before['roof_collision_faces']
    old_core=previous[:-32*3]
    old_valid=[t for t in tris(old_core) if cross_squared(t)>0]
    assert tris(faces)==old_valid,'Every retained hip triangle must match exactly, in order'
    assert len(old_core)-len(faces)==64*3
    assert all(cross_squared(t)>0 for t in tris(faces))
    # Folded gable is a separate non-collapsing construction. Validate and retain
    # all 32 of its original triangles; no change to coverage or winding.
    gable=previous[-32*3:]
    assert len(gable)==96 and all(cross_squared(t)>0 for t in tris(gable))
    spec['roof_collision_faces']=faces+gable
    unchanged={k:v for k,v in spec.items() if k!='roof_collision_faces'}
    assert unchanged=={k:v for k,v in before.items() if k!='roof_collision_faces'}
    new=tris(spec['roof_collision_faces'])
    old=tris(previous)
    assert new==[t for t in old if cross_squared(t)>0]
    old_area=sum(math.sqrt(cross_squared(t))/2 for t in old)
    new_area=sum(math.sqrt(cross_squared(t))/2 for t in new)
    assert old_area==new_area
    PATH.write_text(json.dumps(spec,indent=2))
    report={'mode':'repair','roof_parts':parts,'triangles_before':len(old),'triangles_after':len(new),'exact_zero_area_removed':64,'nondegenerate_triangle_sequence_identical':True,'all_other_json_fields_identical':True,'coverage_area_before':old_area,'coverage_area_after':new_area,'coverage_proof':'All nonzero-area ordered triangle coordinates and winding are exactly identical. Only repeated-point, exactly zero-area triangles disappear. Gable, all 195 simple shapes, floor, door and scale fields are untouched.','visual_meshes_exported':False,'sha256_before':hashlib.sha256(before_path.read_bytes()).hexdigest(),'sha256_after':hashlib.sha256(PATH.read_bytes()).hexdigest()}
    (REPORT/'collision-repair.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report))

"""Claude staging: arrival-stair guardrail variants at the exact 4/11 pitch (19.983106522 deg).

Run: blender --background --factory-startup --python this_file

An addition to the safety kit, not a rebuild. build_safety_kit.py is frozen (it rebuilds and
rewrites the whole kit when run), so the guardrail profile (rail_post_at, rail_span) and the
geometry helpers, materials, export settings and scene writer are copied from it unchanged.
The only new input is the slope: rise/run = 4/11 exactly, instead of tan(integer degrees).
Writes only these files inside staging/claude_environment_safety_kit/:
  railings/rail_stair_4in11_1m.{glb,tscn}, railings/rail_stair_4in11_2m.{glb,tscn},
  source/claude_arrival_stair_rails.blend, arrival_stair_rails_summary.json
"""
from pathlib import Path
import math, json
import bpy, bmesh
from mathutils import Vector

STAGE = Path(__file__).resolve().parents[1]
RES = 'res://staging/claude_environment_safety_kit/'
SLOPE = 4/11   # arrival stair: 4 m rise over 11 m horizontal run
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
bpy.context.preferences.filepaths.save_version = 0   # no .blend1 backups in the delivery
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1

# The two Split-Cloud palette entries the guardrail uses (values as in build_safety_kit.py).
PALETTE = {'Stone': '667e88', 'Coping': 'bcc6bd'}
materials = {}
for name, color in PALETTE.items():
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    rgb = [int(color[i:i+2], 16)/255 for i in (0, 2, 4)]
    linear = [v/12.92 if v < .04045 else ((v+.055)/1.055)**2.4 for v in rgb]
    m.diffuse_color = (*linear, 1)
    p = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    p.inputs['Base Color'].default_value = (*linear, 1)
    p.inputs['Roughness'].default_value = .82
    materials[name] = m

batches, solids = {}, {}
B = None
def begin(bid):
    global B
    B = bid
    solids[bid] = []

def geo(mat, verts, faces):
    v, f = batches.setdefault((B, mat), ([], []))
    off = len(v)
    v.extend(tuple(p) for p in verts)
    f.extend(tuple(off+i for i in face) for face in faces)

def solid(name, p, s):
    solids[B].append({'name': name, 'type': 'box', 'position': list(p), 'size': list(s)})

def convex_solid(name, pts):
    solids[B].append({'name': name, 'type': 'convex', 'points': [list(p) for p in pts]})

CUBE = [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]
CUBE_FACES = [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
def box(p, s, mat, solid_name=None):
    if mat: geo(mat, [(p[0]+i*s[0]/2, p[1]+j*s[1]/2, p[2]+k*s[2]/2) for i, j, k in CUBE], CUBE_FACES)
    if solid_name: solid(solid_name, p, s)

def span(x0, x1, y0, y1, z0, z1, mat, solid_name=None):
    box(((x0+x1)/2, (y0+y1)/2, (z0+z1)/2), (x1-x0, y1-y0, z1-z0), mat, solid_name)

def cone(p, r, h, mat, sides=5, turn=0.0):
    base = [(p[0]+r*math.cos(turn+i*math.tau/sides), p[1], p[2]+r*math.sin(turn+i*math.tau/sides)) for i in range(sides)]
    geo(mat, base+[(p[0], p[1]+h, p[2])], [tuple(range(sides))]+[((i+1) % sides, i, sides) for i in range(sides)])

def out(mat, pts, inside):
    pts = [Vector(p) for p in pts]
    c = sum(pts, Vector())/len(pts)
    if (pts[1]-pts[0]).cross(pts[2]-pts[0]).dot(c-Vector(inside)) < 0: pts.reverse()
    geo(mat, [tuple(p) for p in pts], [tuple(range(len(pts)))])

def hexa(mat, lo, hi):
    lo, hi = [Vector(p) for p in lo], [Vector(p) for p in hi]
    c = sum(lo+hi, Vector())/8
    out(mat, lo, c); out(mat, hi, c)
    for k in range(4): out(mat, [lo[k], lo[(k+1) % 4], hi[(k+1) % 4], hi[k]], c)

# ---------------------------------------------------------------- guardrail (copied unchanged)
P, GUARD = .24, 1.10
def rail_post_at(x, y):
    span(x-P/2, x+P/2, y-.05, y+1.18, -P/2, P/2, 'Stone')
    span(x-.15, x+.15, y+1.18, y+1.24, -.15, .15, 'Coping')
    cone((x, y+1.24, 0), .13, .1, 'Coping', 4, math.pi/4)
    span(x-P/2, x+P/2, y-.05, y+1.24, -P/2, P/2, None, 'Rail post')

def rail_span(L, slope):
    a, b = P/2, L-P/2
    def at(x, dy, z): return (x, x*slope+dy, z)
    hexa('Stone', [at(a, -.05, -.12), at(b, -.05, -.12), at(b, -.05, .12), at(a, -.05, .12)],
                  [at(a, .16, -.12), at(b, .16, -.12), at(b, .16, .12), at(a, .16, .12)])
    hexa('Coping', [at(a, .98, -.09), at(b, .98, -.09), at(b, .98, .09), at(a, .98, .09)],
                   [at(a, GUARD, -.09), at(b, GUARD, -.09), at(b, GUARD, .09), at(a, GUARD, .09)])
    n = max(1, round((b-a)/.45))
    for i in range(n):
        x = a+(b-a)*(i+1)/(n+1)
        span(x-.045, x+.045, x*slope+.14, x*slope+1.0, -.045, .045, 'Stone')
    convex_solid('Rail', [at(x, dy, z) for x in (a, b) for dy in (-.05, GUARD) for z in (-.12, .12)])

# bid: (display name, scene root node, horizontal run L)
ASSETS = {
    'rail_stair_4in11_1m': ('Stair guardrail 4/11 pitch (19.98 deg), 1 m run', 'RailStair4in11_1m', 1),
    'rail_stair_4in11_2m': ('Stair guardrail 4/11 pitch (19.98 deg), 2 m run', 'RailStair4in11_2m', 2),
}
for bid, (_, _, L) in ASSETS.items():
    begin(bid)
    rail_post_at(0, 0)
    rail_span(L, SLOPE)

# ---------------------------------------------------------------- meshes, export, scenes
groups = {}
for (bid, mat), (verts, faces) in batches.items():
    label = ASSETS[bid][1]
    mesh = bpy.data.meshes.new(label+' / '+mat)
    mesh.from_pydata([(p[0], -p[2], p[1]) for p in verts], [], faces)  # Y-up -> Z-up
    mesh.materials.append(materials[mat])
    mesh.update()
    bm = bmesh.new(); bm.from_mesh(mesh)
    bmesh.ops.triangulate(bm, faces=list(bm.faces))
    collapsed = [f for f in bm.faces if f.calc_area() < 1e-8]
    if collapsed: bmesh.ops.delete(bm, geom=collapsed, context='FACES_ONLY')
    bm.to_mesh(mesh); bm.free(); mesh.update()
    obj = bpy.data.objects.new(label+' / '+mat, mesh)
    col = bpy.data.collections.get(label)
    if not col:
        col = bpy.data.collections.new(label); scene.collection.children.link(col)
    col.objects.link(obj)
    groups.setdefault(bid, []).append(obj)

bpy.ops.wm.save_as_mainfile(filepath=str(STAGE/'source/claude_arrival_stair_rails.blend'))

def f(v): return '%.4g' % v
def vec(p): return ', '.join(f(c) for c in p)

def shape_resources(shapes):
    sub, nodes = [], []
    for i, s in enumerate(shapes):
        sid = 'Shape_%03d' % i
        pos = s.get('position', [0, 0, 0])
        if s['type'] == 'box':
            sub.append('[sub_resource type="BoxShape3D" id="%s"]\nsize = Vector3(%s)\n' % (sid, vec(s['size'])))
        else:
            sub.append('[sub_resource type="ConvexPolygonShape3D" id="%s"]\npoints = PackedVector3Array(%s)\n' % (sid, ', '.join(vec(p) for p in s['points'])))
        name = ''.join(c for c in s['name'].title() if c.isalnum())+'_%03d' % i
        nodes.append('[node name="%s" type="CollisionShape3D" parent="Collision"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s)\nshape = SubResource("%s")\n' % (name, vec(pos), sid))
    return sub, nodes

COLLISION_HEADER = '\n[node name="Collision" type="StaticBody3D" parent="." groups=["solid_world"]]\ncollision_mask = 2\n\n'
summary = {'slope_rise_over_run': '4/11', 'degrees': math.degrees(math.atan(SLOPE))}
for bid, objs in groups.items():
    name, root, L = ASSETS[bid]
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.gltf(filepath=str(STAGE/'railings'/(bid+'.glb')), export_format='GLB', use_selection=True,
                              export_yup=True, export_materials='EXPORT', export_normals=True, export_texcoords=False)
    pts = [p for (b, _), (v, _) in batches.items() if b == bid for p in v]
    lo = [min(p[i] for p in pts) for i in range(3)]
    hi = [max(p[i] for p in pts) for i in range(3)]
    sub, nodes = shape_resources(solids[bid])
    tscn = '[gd_scene load_steps=%d format=3]\n\n[ext_resource type="PackedScene" path="%srailings/%s.glb" id="1_model"]\n\n' % (len(sub)+2, RES, bid)
    tscn += '\n'.join(sub)+'\n[node name="%s" type="Node3D"]\n\n[node name="Model" parent="." instance=ExtResource("1_model")]\n' % root
    tscn += COLLISION_HEADER+'\n'.join(nodes)
    (STAGE/'railings'/(bid+'.tscn')).write_text(tscn, encoding='utf-8')
    summary[bid] = {
        'name': name, 'scene': RES+'railings/'+bid+'.tscn', 'model': RES+'railings/'+bid+'.glb',
        'run_m': L, 'next_post_origin': [L, L*SLOPE, 0], 'top_rail_end': [L-P/2, (L-P/2)*SLOPE+GUARD],
        'triangles': sum(len(o.data.polygons) for o in objs),
        'materials': sorted(m for (b, m) in batches if b == bid),
        'bounds_min': [round(v, 4) for v in lo], 'bounds_max': [round(v, 4) for v in hi],
        'collision_shapes': len(solids[bid]),
    }
(STAGE/'arrival_stair_rails_summary.json').write_text(json.dumps(summary, indent=2))
print(json.dumps(summary, indent=1))

"""Claude staging: modular sect walls, railings, retaining walls, edging and direction sign.

Run: blender --background --factory-startup --python this_file

Material setup, geo/box/beam/cone/lathe/out and the export/scene writer are copied from
staging/claude_environment_batch1/tools/build_environment_batch1.py (earlier deliveries are
frozen and must not be rerun). Godot axes (X along a run, Y up, +Z front/outward), metres,
ground-level origins. Conventions per family are documented in reports/CLAUDE_ENVIRONMENT_SAFETY_KIT.md.
Writes only inside staging/claude_environment_safety_kit/.
"""
from pathlib import Path
import math, json
import bpy, bmesh
from mathutils import Vector

STAGE = Path(__file__).resolve().parents[1]
RES = 'res://staging/claude_environment_safety_kit/'
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
bpy.context.preferences.filepaths.save_version = 0   # no .blend1 backups in the delivery
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1

# Split-Cloud building palette plus the natural Rock tone from environment batch 1.
PALETTE = {
    'Stone': '667e88', 'Coping': 'bcc6bd', 'Timber': '432d2d', 'Cedar': '896048', 'Plaster': 'e6d9b8',
    'Jade': '22594f', 'TileLight': '46796b', 'Bronze': 'cda668', 'Rock': '646961',
    'StoneShade': '5b6f78',   # slightly darker blue-grey accent stones for retaining walls
}
materials = {}
for name, color in PALETTE.items():
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    rgb = [int(color[i:i+2], 16)/255 for i in (0, 2, 4)]
    linear = [v/12.92 if v < .04045 else ((v+.055)/1.055)**2.4 for v in rgb]
    m.diffuse_color = (*linear, 1)
    p = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    p.inputs['Base Color'].default_value = (*linear, 1)
    p.inputs['Roughness'].default_value = {'Bronze': .56}.get(name, .82)
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

def cylinder_solid(name, p, r, h):
    solids[B].append({'name': name, 'type': 'cylinder', 'position': list(p), 'radius': r, 'height': h})

def convex_solid(name, pts):
    solids[B].append({'name': name, 'type': 'convex', 'points': [list(p) for p in pts]})

CUBE = [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]
CUBE_FACES = [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
def box(p, s, mat, solid_name=None):
    """mat=None adds collision only."""
    if mat: geo(mat, [(p[0]+i*s[0]/2, p[1]+j*s[1]/2, p[2]+k*s[2]/2) for i, j, k in CUBE], CUBE_FACES)
    if solid_name: solid(solid_name, p, s)

def span(x0, x1, y0, y1, z0, z1, mat, solid_name=None):
    """Axis-aligned box from min/max corners (clearer for modular joints than centre/size)."""
    box(((x0+x1)/2, (y0+y1)/2, (z0+z1)/2), (x1-x0, y1-y0, z1-z0), mat, solid_name)

def frame(a, b):
    a, b = Vector(a), Vector(b)
    axis = (b-a).normalized()
    u = axis.cross(Vector((0,1,0)) if abs(axis.y) < .9 else Vector((1,0,0))).normalized()
    return a, b, u, axis.cross(u)

def beam(a, b, w, d, mat):
    a, b, u, v = frame(a, b)
    geo(mat, [p+u*x*w/2+v*y*d/2 for p in (a, b) for x, y in [(-1,-1),(1,-1),(1,1),(-1,1)]], CUBE_FACES)

def cone(p, r, h, mat, sides=5, turn=0.0):
    base = [(p[0]+r*math.cos(turn+i*math.tau/sides), p[1], p[2]+r*math.sin(turn+i*math.tau/sides)) for i in range(sides)]
    geo(mat, base+[(p[0], p[1]+h, p[2])], [tuple(range(sides))]+[((i+1) % sides, i, sides) for i in range(sides)])

def lathe(p, prof, mat, sides=8):
    rings = [[(p[0]+r*math.cos(i*math.tau/sides), p[1]+y, p[2]+r*math.sin(i*math.tau/sides)) for i in range(sides)] for r, y in prof]
    faces = [(j*sides+i, j*sides+(i+1) % sides, (j+1)*sides+(i+1) % sides, (j+1)*sides+i) for j in range(len(prof)-1) for i in range(sides)]
    if prof[0][0] > 0: faces.append(tuple(reversed(range(sides))))
    if prof[-1][0] > 0: faces.append(tuple(range((len(prof)-1)*sides, len(prof)*sides)))
    geo(mat, [v for rg in rings for v in rg], faces)

def out(mat, pts, inside):
    """One polygon, wound so its normal points away from an interior point."""
    pts = [Vector(p) for p in pts]
    c = sum(pts, Vector())/len(pts)
    if (pts[1]-pts[0]).cross(pts[2]-pts[0]).dot(c-Vector(inside)) < 0: pts.reverse()
    geo(mat, [tuple(p) for p in pts], [tuple(range(len(pts)))])

def hexa(mat, lo, hi):
    """Closed six-sided solid from a bottom and a top quad (same corner order): sloped plinths and rails."""
    lo, hi = [Vector(p) for p in lo], [Vector(p) for p in hi]
    c = sum(lo+hi, Vector())/8
    out(mat, lo, c); out(mat, hi, c)
    for k in range(4): out(mat, [lo[k], lo[(k+1) % 4], hi[(k+1) % 4], hi[k]], c)

# ---------------------------------------------------------------- shared roof forms
def tile_cap(x0, x1, y, hw, rise):
    """Small gabled tile coping along X: jade slopes, timber soffit, tile ribs and ridge."""
    c = ((x0+x1)/2, y+rise/3, 0)
    for s in (-1, 1): out('Jade', [(x0, y, s*hw), (x1, y, s*hw), (x1, y+rise, 0), (x0, y+rise, 0)], c)
    out('Timber', [(x0, y, -hw), (x1, y, -hw), (x1, y, hw), (x0, y, hw)], c)
    for x in (x0, x1): out('Jade', [(x, y, -hw), (x, y, hw), (x, y+rise, 0)], c)
    n = max(1, round((x1-x0)/.5))
    for k in range(n):
        x = x0+(k+.5)*(x1-x0)/n
        for s in (-1, 1): beam((x, y+.02, s*(hw-.02)), (x, y+rise+.01, 0), .05, .04, 'TileLight')
    beam((x0, y+rise+.03, 0), (x1, y+rise+.03, 0), .12, .1, 'TileLight')

def hip_roof(h, eave, rise):
    """Square hipped cap centred on the origin, with lightly upswept corners."""
    apex, lift = (0, eave+rise, 0), .06
    loop = []
    for k in range(4):
        sx, sz = (1, 1, -1, -1)[k], (1, -1, -1, 1)[k]
        loop += [(sx*h, eave+lift, sz*h), (sx*h if k % 2 == 0 else 0, eave, sz*h if k % 2 else 0)]
    c = (0, eave, 0)
    for i in range(8): out('Jade', [loop[i], loop[(i+1) % 8], apex], c)
    low = [(p[0], p[1]-.08, p[2]) for p in loop]
    for i in range(8): out('Timber', [loop[i], loop[(i+1) % 8], low[(i+1) % 8], low[i]], c)
    out('Timber', low, (0, eave+.2, 0))
    for k in range(0, 8, 2): beam((loop[k][0]*.98, loop[k][1]+.02, loop[k][2]*.98), (0, eave+rise+.02, 0), .07, .06, 'TileLight')
    lathe((0, eave+rise-.04, 0), [(.07, 0), (.1, .07), (.05, .14), (0, .2)], 'Coping', 6)

# ================================================================ 1. boundary wall
# Section: runs from x=0 to x=L on centreline z=0. Sections chain flush; piers are optional
# at straight joints and required at corners and free ends.
WALL_TOP, WALL_EAVE = 2.72, 2.36
def wall_body(x0, x1):
    span(x0, x1, 0, .12, -.33, .33, 'Stone')
    span(x0, x1, .12, .70, -.29, .29, 'Stone')
    span(x0, x1, .70, .74, -.30, .30, 'Coping')
    span(x0, x1, .74, 2.28, -.25, .25, 'Plaster')
    span(x0, x1, 2.28, WALL_EAVE, -.28, .28, 'Timber')
    tile_cap(x0, x1, WALL_EAVE, .38, .26)

def wall_section(L):
    def build():
        begin('wall_section_%dm' % L)
        wall_body(0, L)
        span(0, L, 0, WALL_EAVE, -.33, .33, None, 'Wall body')
        span(0, L, WALL_EAVE, WALL_TOP, -.38, .38, None, 'Wall cap')
    return build

def pier(w, eave, apex, name):
    """Square plaster pier on a stone base, taller than the wall cap so it hides joints."""
    span(-(w+.14)/2, (w+.14)/2, 0, .14, -(w+.14)/2, (w+.14)/2, 'Stone')
    span(-(w+.06)/2, (w+.06)/2, .14, .78, -(w+.06)/2, (w+.06)/2, 'Stone')
    span(-(w+.08)/2, (w+.08)/2, .78, .82, -(w+.08)/2, (w+.08)/2, 'Coping')
    span(-w/2, w/2, .82, eave-.1, -w/2, w/2, 'Plaster')
    span(-(w+.06)/2, (w+.06)/2, eave-.1, eave, -(w+.06)/2, (w+.06)/2, 'Timber')
    hip_roof((w+.3)/2, eave, apex-eave)
    span(-(w+.14)/2, (w+.14)/2, 0, eave, -(w+.14)/2, (w+.14)/2, None, name)
    span(-(w+.3)/2, (w+.3)/2, eave, apex, -(w+.3)/2, (w+.3)/2, None, name+' cap')

def wall_pier():
    begin('wall_pier')
    pier(.8, 2.78, 3.15, 'Pier')

def wall_corner():
    begin('wall_corner')
    pier(1.0, 2.86, 3.3, 'Corner pier')

def wall_gate_end():
    """Stepped stone abutment. Local x=0 is the gate tower face (it embeds 0.08 m into it);
    the next wall section starts at local x=0.70."""
    begin('wall_gate_end')
    span(-.08, .70, 0, .14, -.45, .45, 'Stone')
    span(-.08, .35, .14, 3.16, -.40, .40, 'Stone')
    span(-.11, .38, 3.16, 3.24, -.44, .44, 'Coping')
    span(.35, .70, .14, 2.82, -.40, .40, 'Stone')
    span(.32, .73, 2.82, 2.90, -.44, .44, 'Coping')
    span(-.08, .70, 0, 2.82, -.45, .45, None, 'Gate abutment')
    span(-.11, .38, 2.82, 3.24, -.44, .44, None, 'Gate abutment step')

# ================================================================ 2. guardrail
# Section of horizontal run L: leading post centred at x=0, rail span to the next post at x=L
# (supplied by the next section or a standalone rail_post). Centreline z=0.
P, GUARD = .24, 1.10
def rail_post_at(x, y):
    span(x-P/2, x+P/2, y-.05, y+1.18, -P/2, P/2, 'Stone')
    span(x-.15, x+.15, y+1.18, y+1.24, -.15, .15, 'Coping')
    cone((x, y+1.24, 0), .13, .1, 'Coping', 4, math.pi/4)
    span(x-P/2, x+P/2, y-.05, y+1.24, -P/2, P/2, None, 'Rail post')

def rail_post():
    begin('rail_post')
    rail_post_at(0, 0)

def rail_span(L, slope):
    """Plinth, balusters and top rail between posts, following y = x*slope."""
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

def rail_section(L):
    def build():
        begin('rail_section_%dm' % L)
        rail_post_at(0, 0)
        rail_span(L, 0)
    return build

def rail_stair(L, deg):
    def build():
        begin('rail_stair_%ddeg_%dm' % (deg, L))
        rail_post_at(0, 0)
        rail_span(L, math.tan(math.radians(deg)))
    return build

# ================================================================ 3. retaining wall
# Section: face plane z=0 faces +Z (the lower ground), body z in [-0.6, 0] runs into the
# terrace, x from 0 to 4, coping top = terrace level at y=H.
COURSES = [[1.1, .9, 1.2, .8], [.6, 1.0, 1.2, .7, .5], [.9, 1.3, .7, 1.1], [.5, 1.1, .9, 1.0, .5]]
def courses(H):
    n = round((H-.1)/.48)
    return n, (H-.1)/n

def block(x0, x1, y0, y1, z0, z1, k, i):
    g = .015
    mat = 'StoneShade' if (k*3+i*2) % 5 == 0 else 'Stone'
    span(x0+g, x1-g, y0+g, y1-g, z0, z1, mat)

def retaining(H):
    def build():
        begin('retaining_wall_4x%d' % H)
        n, hc = courses(H)
        span(0, 4, 0, H-.1, -.6, -.06, 'Rock')                    # dark core seen in the joints
        for k in range(n):
            x = 0.0
            for i, l in enumerate(COURSES[k % 4]):
                proud = .05 if k == 0 else (.012 if (k+i) % 3 == 0 else 0)
                block(x, x+l, k*hc, (k+1)*hc, -.58, proud, k, i)
                x += l
        if H > 2:
            y = round(n/2)*hc
            span(0, 4, y-.04, y+.04, -.1, .035, 'Coping')
        for i in range(4): span(i+.01, i+.99, H-.1, H, -.62, .06, 'Coping')
        span(0, 4, 0, H, -.6, .05, None, 'Retaining wall')
    return build

def quoin(H, x0, x1, z0, name):
    """Coursed corner/end stones proud of the wall faces, with a coping cap."""
    n, hc = courses(H)
    span(x0+.04, x1-.04, 0, H-.1, z0+.04, -.04, 'Rock')
    for k in range(n):
        inset = .02 if k % 2 else 0
        span(x0+inset+.015, x1-.015, k*hc+.015, (k+1)*hc-.015, z0+.015, .06-inset, 'Stone')
    span(x0-.04, x1+.04, H-.1, H, z0-.04, .1, 'Coping')
    span(x0, x1, 0, H, z0, .06, None, name)

def retaining_corner(H):
    def build():
        begin('retaining_corner_%d' % H)
        quoin(H, -.66, .06, -.66, 'Retaining corner')
    return build

def retaining_end(H):
    def build():
        begin('retaining_end_%d' % H)
        quoin(H, -.36, .36, -.66, 'Retaining end')
    return build

# ================================================================ 4. low edging (no collision)
EDGE_H = .14
def edge_stone(x0, x1, mat='Stone'):
    hexa(mat, [(x0, -.04, -.09), (x1, -.04, -.09), (x1, -.04, .09), (x0, -.04, .09)],
              [(x0, EDGE_H, -.07), (x1, EDGE_H, -.07), (x1, EDGE_H, .07), (x0, EDGE_H, .07)])

def edging_section():
    begin('edging_2m')
    for i in range(4): edge_stone(i*.5+.008, (i+1)*.5-.008)

def edging_corner():
    begin('edging_corner')
    span(-.12, .12, -.04, .16, -.12, .12, 'Stone')
    span(-.13, .13, .16, .19, -.13, .13, 'Coping')

def edging_end():
    begin('edging_end')
    hexa('Stone', [(-.11, -.04, -.11), (.11, -.04, -.11), (.11, -.04, .11), (-.11, -.04, .11)],
                  [(-.11, .15, -.11), (.11, .15, -.11), (.11, .15, .11), (-.11, .15, .11)])
    cone((0, .15, 0), .145, .06, 'Coping', 4, math.pi/4)

# ================================================================ 5. direction sign
# Post and board are separate models so each board can be re-aimed and relabelled.
def sign_post():
    begin('direction_sign_post')
    span(-.25, .25, 0, .3, -.25, .25, 'Stone')
    span(-.28, .28, .3, .34, -.28, .28, 'Coping')
    lathe((0, .34, 0), [(.075, 0), (.075, 2.56), (.1, 2.6), (.1, 2.66), (0, 2.8)], 'Timber', 8)
    span(-.25, .25, 0, .34, -.25, .25, None, 'Sign base')
    cylinder_solid('Sign post', (0, 1.6, 0), .085, 2.6)

def sign_board():
    """One arrow board pointing +X from the post axis; its bracket ring wraps the post."""
    begin('direction_sign_board')
    prof = [(.1, -.11), (1.12, -.11), (1.3, 0), (1.12, .11), (.1, .11)]
    front = [(x, y, .025) for x, y in prof]
    back = [(x, y, -.025) for x, y in prof]
    c = (.7, 0, 0)
    out('Timber', front, c); out('Timber', back, c)
    for k in range(5): out('Timber', [front[k], front[(k+1) % 5], back[(k+1) % 5], back[k]], c)
    for y in (-.1, .1): span(.1, 1.12, y-.012, y+.012, -.032, .032, 'Bronze')
    lathe((0, -.06, 0), [(.1, 0), (.1, .12)], 'Bronze', 8)
    span(.06, .12, -.06, .06, -.03, .03, 'Bronze')

ASSETS = {
    'wall_section_2m': ('Boundary wall section 2 m', 'walls', wall_section(2)),
    'wall_section_4m': ('Boundary wall section 4 m', 'walls', wall_section(4)),
    'wall_pier': ('Boundary wall pier (support/end)', 'walls', wall_pier),
    'wall_corner': ('Boundary wall corner pier', 'walls', wall_corner),
    'wall_gate_end': ('Boundary wall gate abutment', 'walls', wall_gate_end),
    'rail_section_1m': ('Guardrail section 1 m', 'railings', rail_section(1)),
    'rail_section_2m': ('Guardrail section 2 m', 'railings', rail_section(2)),
    'rail_post': ('Guardrail end/corner post', 'railings', rail_post),
    'rail_stair_22deg_1m': ('Stair guardrail 22 deg, 1 m run', 'railings', rail_stair(1, 22)),
    'rail_stair_22deg_2m': ('Stair guardrail 22 deg, 2 m run', 'railings', rail_stair(2, 22)),
    'rail_stair_24deg_1m': ('Stair guardrail 24 deg, 1 m run', 'railings', rail_stair(1, 24)),
    'rail_stair_24deg_2m': ('Stair guardrail 24 deg, 2 m run', 'railings', rail_stair(2, 24)),
    'retaining_wall_4x2': ('Retaining wall 4 x 2 m', 'retaining', retaining(2)),
    'retaining_wall_4x4': ('Retaining wall 4 x 4 m', 'retaining', retaining(4)),
    'retaining_corner_2': ('Retaining outer corner 2 m', 'retaining', retaining_corner(2)),
    'retaining_corner_4': ('Retaining outer corner 4 m', 'retaining', retaining_corner(4)),
    'retaining_end_2': ('Retaining end 2 m', 'retaining', retaining_end(2)),
    'retaining_end_4': ('Retaining end 4 m', 'retaining', retaining_end(4)),
    'edging_2m': ('Low stone edging 2 m', 'edging', edging_section),
    'edging_corner': ('Low stone edging corner', 'edging', edging_corner),
    'edging_end': ('Low stone edging end', 'edging', edging_end),
    'direction_sign_post': ('Direction sign post (part)', 'sign', sign_post),
    'direction_sign_board': ('Direction sign board (part)', 'sign', sign_board),
}
PARTS = {'direction_sign_post', 'direction_sign_board'}   # composed into sign/direction_sign.tscn
for _, _, build in ASSETS.values(): build()

# ---------------------------------------------------------------- meshes, export, scenes
groups = {}
for (bid, mat), (verts, faces) in batches.items():
    label = ''.join(w.title() for w in bid.split('_'))
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

(STAGE/'source').mkdir(exist_ok=True)
(STAGE/'source/.gdignore').write_text('')
bpy.ops.wm.save_as_mainfile(filepath=str(STAGE/'source/claude_environment_safety_kit.blend'))

def f(v): return '%.4g' % v
def vec(p): return ', '.join(f(c) for c in p)

def shape_resources(shapes, prefix=''):
    sub, nodes = [], []
    for i, s in enumerate(shapes):
        sid = prefix+'Shape_%03d' % i
        pos = s.get('position', [0, 0, 0])
        if s['type'] == 'box':
            sub.append('[sub_resource type="BoxShape3D" id="%s"]\nsize = Vector3(%s)\n' % (sid, vec(s['size'])))
        elif s['type'] == 'cylinder':
            sub.append('[sub_resource type="CylinderShape3D" id="%s"]\nheight = %s\nradius = %s\n' % (sid, f(s['height']), f(s['radius'])))
        else:
            sub.append('[sub_resource type="ConvexPolygonShape3D" id="%s"]\npoints = PackedVector3Array(%s)\n' % (sid, ', '.join(vec(p) for p in s['points'])))
        name = ''.join(c for c in s['name'].title() if c.isalnum())+'_%03d' % i
        nodes.append('[node name="%s" type="CollisionShape3D" parent="Collision"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s)\nshape = SubResource("%s")\n' % (name, vec(pos), sid))
    return sub, nodes

COLLISION_HEADER = '\n[node name="Collision" type="StaticBody3D" parent="." groups=["solid_world"]]\ncollision_mask = 2\n\n'
summary = {}
for bid, objs in groups.items():
    name, family, _ = ASSETS[bid]
    out_dir = STAGE/family
    out_dir.mkdir(exist_ok=True)
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.gltf(filepath=str(out_dir/(bid+'.glb')), export_format='GLB', use_selection=True,
                              export_yup=True, export_materials='EXPORT', export_normals=True, export_texcoords=False)
    pts = [p for (b, _), (v, _) in batches.items() if b == bid for p in v]
    lo = [min(p[i] for p in pts) for i in range(3)]
    hi = [max(p[i] for p in pts) for i in range(3)]
    if bid not in PARTS:
        sub, nodes = shape_resources(solids[bid])
        root = ''.join(w.title() for w in bid.split('_'))
        tscn = '[gd_scene load_steps=%d format=3]\n\n[ext_resource type="PackedScene" path="%s%s/%s.glb" id="1_model"]\n\n' % (len(sub)+2, RES, family, bid)
        tscn += '\n'.join(sub)+'\n[node name="%s" type="Node3D"]\n\n[node name="Model" parent="." instance=ExtResource("1_model")]\n' % root
        if nodes: tscn += COLLISION_HEADER+'\n'.join(nodes)
        (out_dir/(bid+'.tscn')).write_text(tscn, encoding='utf-8')
    summary[bid] = {
        'name': name, 'family': family,
        'scene': None if bid in PARTS else RES+family+'/'+bid+'.tscn',
        'model': RES+family+'/'+bid+'.glb',
        'triangles': sum(len(o.data.polygons) for o in objs),
        'materials': sorted(m for (b, m) in batches if b == bid),
        'bounds_min': [round(v, 3) for v in lo], 'bounds_max': [round(v, 3) for v in hi],
        'size_xyz_m': [round(hi[i]-lo[i], 2) for i in range(3)],
        'collision_shapes': len(solids[bid]),
    }

# Direction sign: post + three re-aimable boards, each with front/back Label3D (editable text).
BOARDS = [('Board1', 2.55, 0.0, 'MAIN HALL'), ('Board2', 2.25, 150.0, 'TRAINING GROUND'), ('Board3', 1.95, -65.0, 'LIVING DISTRICT')]
sub, nodes = shape_resources(solids['direction_sign_post'])
tscn = '[gd_scene load_steps=%d format=3]\n\n' % (len(sub)+3)
tscn += '[ext_resource type="PackedScene" path="%ssign/direction_sign_post.glb" id="1_post"]\n' % RES
tscn += '[ext_resource type="PackedScene" path="%ssign/direction_sign_board.glb" id="2_board"]\n\n' % RES
tscn += '\n'.join(sub)+'\n[node name="DirectionSign" type="Node3D"]\n\n[node name="Post" parent="." instance=ExtResource("1_post")]\n'
for node, y, yaw, text in BOARDS:
    c, s = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    tscn += '\n[node name="%s" type="Node3D" parent="."]\ntransform = Transform3D(%s, 0, %s, 0, 1, 0, %s, 0, %s, 0, %s, 0)\n' % (node, f(c), f(s), f(-s), f(c), f(y))
    tscn += '\n[node name="Model" parent="%s" instance=ExtResource("2_board")]\n' % node
    for label, z, flip in (('LabelFront', .028, 1), ('LabelBack', -.028, -1)):
        tscn += ('\n[node name="%s" type="Label3D" parent="%s"]\ntransform = Transform3D(%d, 0, 0, 0, 1, 0, 0, 0, %d, 0.62, 0, %s)\n'
                 'double_sided = false\nmodulate = Color(0.718, 0.631, 0.427, 1)\noutline_size = 0\npixel_size = 0.0024\nfont_size = 40\ntext = "%s"\n') % (label, node, flip, flip, f(z), text)
tscn += COLLISION_HEADER+'\n'.join(nodes)
(STAGE/'sign/direction_sign.tscn').write_text(tscn, encoding='utf-8')
summary['direction_sign'] = {'name': 'Direction sign (post + 3 boards)', 'family': 'sign', 'scene': RES+'sign/direction_sign.tscn',
                             'triangles': summary['direction_sign_post']['triangles']+3*summary['direction_sign_board']['triangles'],
                             'labels': [b[3] for b in BOARDS], 'collision_shapes': len(solids['direction_sign_post'])}
(STAGE/'build_summary.json').write_text(json.dumps(summary, indent=2))
print(json.dumps({k: (v['triangles'], v.get('size_xyz_m'), v['collision_shapes']) for k, v in summary.items()}))

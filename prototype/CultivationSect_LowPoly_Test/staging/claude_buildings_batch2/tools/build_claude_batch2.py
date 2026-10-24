"""Claude staging batch 2, Split-Cloud low-poly style: Alchemy Pavilion, Medicine Hall.

Run: blender --background --factory-startup --python this_file

Helpers are copied from staging/claude_buildings/tools/build_claude_buildings.py
(batch 1 is frozen and integrated; its generator must not be rerun). Additions:
wall frames at any angle (octagonal walls), lathe() for ceramics, ngon prisms
and poly_roof() for many-sided roofs. Godot axes (X across, Y up, +Z front),
metres, origin on the ground under the asset centre. No world placement.
Writes only inside staging/claude_buildings_batch2/.
"""
from pathlib import Path
import math, json
import bpy, bmesh
from mathutils import Vector

STAGE = Path(__file__).resolve().parents[1]
RES = 'res://staging/claude_buildings_batch2/'
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1

PALETTE = {
    'Stone': '667e88', 'Coping': 'bcc6bd', 'Timber': '432d2d',
    'Cedar': '896048', 'Jade': '22594f', 'TileLight': '46796b',
    'Plaster': 'e6d9b8', 'Window': '284c53', 'Bronze': 'cda668',
    'Floor': '85624d', 'Lantern': 'ffda91', 'Fabric': '456e73',
    'Soil': '5d4a3a', 'Leaf': '4d7d4f', 'SpiritHerb': '8fe0c0', 'Water': '2c5f63',
}
EMISSIVE = {'Lantern': .45, 'SpiritHerb': .35}
materials = {}
for name, color in PALETTE.items():
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    rgb = [int(color[i:i+2], 16)/255 for i in (0, 2, 4)]
    linear = [v/12.92 if v < .04045 else ((v+.055)/1.055)**2.4 for v in rgb]
    m.diffuse_color = (*linear, 1)
    p = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    p.inputs['Base Color'].default_value = (*linear, 1)
    p.inputs['Roughness'].default_value = {'Bronze': .56, 'Water': .5}.get(name, .82)
    if name in EMISSIVE:
        p.inputs['Emission Color'].default_value = (*linear, 1)
        p.inputs['Emission Strength'].default_value = EMISSIVE[name]
    materials[name] = m

batches, solids, labels = {}, {}, {}
B = None
def begin(bid):
    global B
    B = bid
    solids[bid], labels[bid] = [], []

def geo(mat, verts, faces):
    v, f = batches.setdefault((B, mat), ([], []))
    off = len(v)
    v.extend(tuple(p) for p in verts)
    f.extend(tuple(off+i for i in face) for face in faces)

def solid(name, p, s):
    solids[B].append({'name': name, 'type': 'box', 'position': list(p), 'size': list(s)})

def cylinder_solid(name, p, r, h):
    solids[B].append({'name': name, 'type': 'cylinder', 'position': list(p), 'radius': r, 'height': h})

CUBE = [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]
CUBE_FACES = [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
def box(p, s, mat, solid_name=None):
    geo(mat, [(p[0]+i*s[0]/2, p[1]+j*s[1]/2, p[2]+k*s[2]/2) for i, j, k in CUBE], CUBE_FACES)
    if solid_name: solid(solid_name, p, s)

def frame(a, b):
    a, b = Vector(a), Vector(b)
    axis = (b-a).normalized()
    u = axis.cross(Vector((0,1,0)) if abs(axis.y) < .9 else Vector((1,0,0))).normalized()
    return a, b, u, axis.cross(u)

def beam_points(a, b, w, d):
    a, b, u, v = frame(a, b)
    return [p+u*x*w/2+v*y*d/2 for p in (a, b) for x, y in [(-1,-1),(1,-1),(1,1),(-1,1)]]

def beam(a, b, w, d, mat, solid_name=None):
    pts = beam_points(a, b, w, d)
    geo(mat, pts, CUBE_FACES)
    if solid_name: solids[B].append({'name': solid_name, 'type': 'convex', 'points': [list(p) for p in pts]})

def rod(a, b, r, mat, sides=8):
    a, b, u, v = frame(a, b)
    verts = [p+r*(u*math.cos(i*math.tau/sides)+v*math.sin(i*math.tau/sides)) for p in (a, b) for i in range(sides)]
    faces = [tuple(reversed(range(sides))), tuple(range(sides, 2*sides))]
    faces += [(i, (i+1) % sides, (i+1) % sides+sides, i+sides) for i in range(sides)]
    geo(mat, verts, faces)

def ring(p, r, thick, mat, segments=16, axis='z'):
    def q(t):
        c, s = r*math.cos(t), r*math.sin(t)
        return {'z': (p[0]+c, p[1]+s, p[2]), 'x': (p[0], p[1]+s, p[2]+c), 'y': (p[0]+c, p[1], p[2]+s)}[axis]
    for i in range(segments):
        beam(q(i*math.tau/segments), q((i+1)*math.tau/segments), thick, thick, mat)

def cone(p, r, h, mat, sides=5, turn=0.0):
    base = [(p[0]+r*math.cos(turn+i*math.tau/sides), p[1], p[2]+r*math.sin(turn+i*math.tau/sides)) for i in range(sides)]
    geo(mat, base+[(p[0], p[1]+h, p[2])], [tuple(range(sides))]+[((i+1) % sides, i, sides) for i in range(sides)])

def crystal(p, r, up, down, mat, sides=6):
    mid = [(p[0]+r*math.cos(i*math.tau/sides), p[1]+down, p[2]+r*math.sin(i*math.tau/sides)) for i in range(sides)]
    verts = mid+[(p[0], p[1], p[2]), (p[0], p[1]+down+up, p[2])]
    geo(mat, verts, [(i, (i+1) % sides, sides) for i in range(sides)]+[((i+1) % sides, i, sides+1) for i in range(sides)])

def lathe(p, prof, mat, sides=8):
    """Revolve [(radius, height), ...] about a vertical axis at p. Jars, urns, cauldron."""
    rings = [[(p[0]+r*math.cos(i*math.tau/sides), p[1]+y, p[2]+r*math.sin(i*math.tau/sides)) for i in range(sides)] for r, y in prof]
    faces = [(j*sides+i, j*sides+(i+1) % sides, (j+1)*sides+(i+1) % sides, (j+1)*sides+i) for j in range(len(prof)-1) for i in range(sides)]
    if prof[0][0] > 0: faces.append(tuple(reversed(range(sides))))
    if prof[-1][0] > 0: faces.append(tuple(range((len(prof)-1)*sides, len(prof)*sides)))
    geo(mat, [v for rg in rings for v in rg], faces)

def ngon(n, R):
    """Corners in xz with one flat side facing +Z."""
    t0 = math.pi/2-math.pi/n
    return [(R*math.cos(t0+k*math.tau/n), R*math.sin(t0+k*math.tau/n)) for k in range(n)]

def prism(cx, cz, y0, y1, R, mat, n=8, solid_name=None):
    verts = [(cx+x, y, cz+z) for y in (y0, y1) for x, z in ngon(n, R)]
    geo(mat, verts, [tuple(reversed(range(n))), tuple(range(n, 2*n))]+[(i, (i+1) % n, (i+1) % n+n, i+n) for i in range(n)])
    if solid_name: solids[B].append({'name': solid_name, 'type': 'convex', 'points': [list(v) for v in verts]})

# Wall frames: o=(cx, cz, facing). facing is '+z'/'-z'/'+x'/'-x' or an outward
# normal angle in radians (x=cos, z=sin). u runs along the wall, n outward.
FACING = {'+z': (1,0,0,1), '-z': (-1,0,0,-1), '+x': (0,-1,1,0), '-x': (0,1,-1,0)}
def basis(f):
    if isinstance(f, str): return FACING[f]
    return (math.sin(f), -math.cos(f), math.cos(f), math.sin(f))

def at(o, u, y, n):
    a, b, c, d = basis(o[2])
    return (o[0]+a*u+c*n, y, o[1]+b*u+d*n)

def wbox(o, u, y, n, su, sy, sn, mat, solid_name=None):
    if isinstance(o[2], str):
        box(at(o, u, y, n), (su, sy, sn) if FACING[o[2]][0] else (sn, sy, su), mat, solid_name)
    else:
        beam(at(o, u-su/2, y, n), at(o, u+su/2, y, n), sn, sy, mat, solid_name)

def wsolid(o, name, u, y, n, su, sy, sn):
    if isinstance(o[2], str):
        solid(name, at(o, u, y, n), (su, sy, sn) if FACING[o[2]][0] else (sn, sy, su))
    else:
        solids[B].append({'name': name, 'type': 'convex', 'points': [list(p) for p in beam_points(at(o, u-su/2, y, n), at(o, u+su/2, y, n), sn, sy)]})

def wall(o, u0, u1, floor, top, doors=(), t=.24, dado=.55, name='Wall'):
    """Plaster wall on a stone dado, cut by (u, width, height) doorways."""
    cuts = sorted((u-w/2, u+w/2, h) for u, w, h in doors)
    edges = [u0]+[x for a, b, _ in cuts for x in (a, b)]+[u1]
    for i in range(0, len(edges), 2):
        a, b = edges[i], edges[i+1]
        if b-a < .02: continue
        m = (a+b)/2
        wbox(o, m, floor+dado/2, 0, b-a, dado, t+.06, 'Stone')
        wbox(o, m, (floor+dado+top)/2, 0, b-a, top-floor-dado, t, 'Plaster')
        wsolid(o, name, m, (floor+top)/2, 0, b-a, top-floor, t+.06)
    for a, b, h in cuts:
        m = (a+b)/2
        if top-floor-h > .02:
            wbox(o, m, (floor+h+top)/2, 0, b-a, top-floor-h, t, 'Plaster', name+' lintel')
        for x in (a-.08, b+.08):
            wbox(o, x, floor+(h+.1)/2, 0, .16, h+.1, t+.1, 'Timber')
        wbox(o, m, floor+h+.09, 0, b-a+.36, .18, t+.12, 'Timber')
        wbox(o, m, floor+.015, 0, b-a, .03, t, 'Stone')

def window(o, u, y, w, h, t=.24):
    for side in (1, -1):
        wbox(o, u, y, side*(t/2+.015), w-.2, h-.2, .03, 'Window')
    n = t/2+.05
    for x in (-w/2, w/2): wbox(o, u+x, y, n, .12, h+.12, .1, 'Cedar')
    for yy in (-h/2, h/2): wbox(o, u, y+yy, n, w+.12, .12, .1, 'Cedar')
    for i in (-1, 1): wbox(o, u+i*w*.22, y, n+.01, .05, h-.16, .05, 'Cedar')
    wbox(o, u, y, n+.01, w-.16, .05, .05, 'Cedar')
    pts = [at(o, u+a, y+b, n+.035) for a, b in [(0, .3*h), (.2*w, 0), (0, -.3*h), (-.2*w, 0)]]
    for a, b in zip(pts, pts[1:]+pts[:1]): beam(a, b, .045, .045, 'Bronze')
    wbox(o, u, y-h/2-.1, n, w+.24, .08, .18, 'Coping')

def vent(o, u, y, w, h, t=.24):
    """High louvred ventilation band: dark recess crossed by vertical cedar slats."""
    for side in (1, -1): wbox(o, u, y, side*(t/2+.015), w, h, .03, 'Window')
    for k in range(int(w/.32)+1): wbox(o, u-w/2+k*w/int(w/.32), y, t/2+.05, .06, h, .08, 'Cedar')
    for yy in (-h/2, h/2): wbox(o, u, y+yy, t/2+.05, w+.1, .08, .1, 'Cedar')

def leaves(o, u, w, h, floor, t=.24):
    lw = w/2-.02
    for s in (-1, 1):
        x = u+s*(w/2-.05)
        wbox(o, x, floor+h/2, -(t/2+lw/2), .06, h-.06, lw, 'Timber')
        for yy in (.22*h, .5*h, .8*h): wbox(o, x-s*.035, floor+yy, -(t/2+lw/2), .03, .1, lw-.08, 'Cedar')

def stairs(cx, cz, width, height, n, tread, facing='+z'):
    """(cx, cz) is the top edge; steps run outward along facing. Smooth ramp collision."""
    dx, dz = {'+z': (0,1), '-z': (0,-1), '+x': (1,0), '-x': (-1,0)}[facing]
    for i in range(n):
        h = height-i*height/n
        d, e = (i+.5)*tread, (i+.9)*tread
        box((cx+dx*d, h/2, cz+dz*d), (tread, h, width) if dx else (width, h, tread), 'Stone' if height < 1.5 else 'Cedar')
        box((cx+dx*e, h-.02, cz+dz*e), (.1, .05, width+.04) if dx else (width+.04, .05, .1), 'Coping' if height < 1.5 else 'Timber')
    L, pts = n*tread, []
    for w in (-width/2, width/2):
        ox, oz = (0, w) if dx else (w, 0)
        pts += [[cx+ox, height, cz+oz], [cx+ox, 0, cz+oz], [cx+ox+dx*L, 0, cz+oz+dz*L]]
    solids[B].append({'name': 'Stair ramp', 'type': 'convex', 'points': pts})

def column(x, z, y0, y1, r=.17):
    box((x, y0+.09, z), (r*2.8, .18, r*2.8), 'Coping')
    rod((x, y0+.18, z), (x, y1, z), r, 'Timber')
    cylinder_solid('Column', (x, (y0+y1)/2, z), r, y1-y0)

def lantern(x, y, z, top):
    rod((x, y+.25, z), (x, top, z), .02, 'Timber', 4)
    rod((x, y-.22, z), (x, y+.22, z), .17, 'Lantern')
    for dy in (-.24, .24): rod((x, y+dy-.03, z), (x, y+dy+.03, z), .19, 'Cedar')

def gable(cx, cz, w, d, eave, rise, axis='x', curve=1.35, steps=5):
    """Two swept slopes; ridge along axis. w = ridge length, d = span."""
    def P(u, v, dy=0.0):
        t = 1-abs(v)/(d/2)
        y = eave+rise*t**curve+.30*(abs(u)/(w/2))**8*(1-t)**2+dy
        x, z = (u, v) if axis == 'x' else (v, u)
        return Vector((cx+x, y, cz+z))
    across = max(4, round(w/1.6))
    for side in (-1, 1):
        top = [P(-w/2+w*i/across, side*d/2*(1-j/steps)) for j in range(steps+1) for i in range(across+1)]
        faces = []
        for j in range(steps):
            for i in range(across):
                a = j*(across+1)+i
                f = [a, a+1, a+across+2, a+across+1]
                if (top[f[1]]-top[f[0]]).cross(top[f[2]]-top[f[0]]).y < 0: f.reverse()
                faces.append(f)
        geo('Jade', top, faces)
        bottom = [p-Vector((0, .18, 0)) for p in top]
        geo('Timber', bottom, [tuple(reversed(f)) for f in faces])
        for i in range(across): geo('Cedar', [top[i], top[i+1], bottom[i+1], bottom[i]], [(0,1,2,3)])
        for i in (0, across):
            for j in range(steps):
                a = j*(across+1)+i
                geo('Cedar', [top[a], top[a+across+1], bottom[a+across+1], bottom[a]], [(0,1,2,3)])
        count = max(2, round(w/.8))
        for k in range(1, count):
            u = -w/2+w*k/count
            for j in range(steps):
                beam(P(u, side*d/2*(1-j/steps), .025), P(u, side*d/2*(1-(j+1)/steps), .025), .042, .045, 'TileLight')
    beam(P(-w/2, 0, .08), P(w/2, 0, .08), .24, .22, 'TileLight')
    return P

def poly_roof(cx, cz, n, r0, eave, rise, r1=0.0, lift=.3, steps=6, across=4):
    """Many-sided swept roof (Hall roof() profile and corner upsweep), eave
    circumradius r0 rising to r1 (0 = apex). Corners are hips."""
    c0 = ngon(n, 1.0)
    def pt(k, s, t):
        R = r0+(r1-r0)*t
        (ax, az), (bx, bz) = c0[k % n], c0[(k+1) % n]
        x, z = R*(ax+(bx-ax)*s), R*(az+(bz-az)*s)
        y = eave+rise*t**1.55+lift*(1-t)**7+.32*abs(2*s-1)**6*(1-t)**2
        return Vector((cx+x, y, cz+z))
    side_len = 2*r0*math.sin(math.pi/n)
    for k in range(n):
        top = [pt(k, i/across, j/steps) for j in range(steps+1) for i in range(across+1)]
        faces = []
        for j in range(steps):
            for i in range(across):
                a = j*(across+1)+i
                f = [a, a+1, a+across+2, a+across+1]
                nrm = (top[f[1]]-top[f[0]]).cross(top[f[2]]-top[f[0]])
                if nrm.length < 1e-7:
                    f = [a, a+1, a+across+1]
                    nrm = (top[f[1]]-top[f[0]]).cross(top[f[2]]-top[f[0]])
                if nrm.length < 1e-7: continue
                if nrm.y < 0: f.reverse()
                faces.append(f)
        geo('Jade', top, faces)
        bottom = [p-Vector((0, .18, 0)) for p in top]
        geo('Timber', bottom, [tuple(reversed(f)) for f in faces])
        for i in range(across): geo('Cedar', [top[i], top[i+1], bottom[i+1], bottom[i]], [(0,1,2,3)])
        if r1 > 0:
            off = steps*(across+1)
            for i in range(across): geo('Timber', [top[off+i], bottom[off+i], bottom[off+i+1], top[off+i+1]], [(0,1,2,3)])
        count = max(2, round(side_len/.8))
        for i in range(1, count):
            for j in range(steps):
                a, b = pt(k, i/count, j/steps), pt(k, i/count, (j+1)/steps)
                if (b-a).length > .01: beam(a+Vector((0,.025,0)), b+Vector((0,.025,0)), .042, .045, 'TileLight')
        for j in range(steps):
            a, b = pt(k, 0, j/steps), pt(k, 0, (j+1)/steps)
            if (b-a).length > .01: beam(a+Vector((0,.06,0)), b+Vector((0,.06,0)), .15, .14, 'TileLight')
        for j in range(2):
            beam(pt(k, 0, j/12)+Vector((0,.11,0)), pt(k, 0, (j+1)/12)+Vector((0,.11,0)), .075, .07, 'Bronze')
    return pt

def plaque(text, p, w, h, pixel):
    box(p, (w, h, .08), 'Timber')
    for y in (-h/2, h/2): box((p[0], p[1]+y, p[2]+.05), (w+.04, .04, .04), 'Bronze')
    for x in (-w/2, w/2): box((p[0]+x, p[1], p[2]+.05), (.04, h+.04, .04), 'Bronze')
    labels[B].append({'text': text, 'position': [p[0], p[1], p[2]+.06], 'pixel_size': pixel})

def table(x, y, z, w, d, h, name='Table'):
    box((x, y+h-.03, z), (w, .06, d), 'Cedar')
    for a in (-w/2+.08, w/2-.08):
        for b in (-d/2+.08, d/2-.08): box((x+a, y+(h-.06)/2, z+b), (.08, h-.06, .08), 'Timber')
    solid(name, (x, y+h/2, z), (w, h, d))

# Ceramic containers: jade/teal glazes and brown earthenware (ivory vanished
# against the plaster walls), with bronze lids.
JAR = [(.0, 0), (.11, 0), (.17, .1), (.18, .2), (.12, .3), (.08, .32), (.09, .36), (0, .36)]
URN = [(0, 0), (.22, 0), (.38, .25), (.42, .5), (.34, .75), (.2, .85), (.22, .9), (0, .9)]
GLAZES = ('Jade', 'Fabric', 'Floor', 'TileLight')
def jar(x, y, z, k, big=False):
    prof = URN if big else JAR
    (nr, ny), (lr, ly), (_, ty) = prof[-3:]   # neck, lid rim, lid top
    lathe((x, y, z), prof[:-2], GLAZES[k % 4])
    lathe((x, y+ny, z), [(nr, 0), (lr, ly-ny), (0, ty-ny+.02)], 'Bronze')

def basket(x, y, z, fill, r=.42):
    """Flat round drying sieve with a layer of herbs."""
    lathe((x, y, z), [(0, 0), (r, 0), (r+.04, .09), (r-.02, .09), (0, .03)], 'Cedar', 10)
    lathe((x, y+.03, z), [(r-.05, 0), (r-.12, .05), (0, .07)], fill, 10)

# ================================================================ 1. Alchemy Pavilion
def alchemy_pavilion():
    """Octagonal, double-eave pavilion with a louvred smoke lantern and bronze gourd finial."""
    begin('alchemy_pavilion')
    n, F, RW, T = 8, .9, 5.6, 6.4
    ap = RW*math.cos(math.pi/n)              # wall apothem
    prism(0, 0, 0, F-.08, 7.6, 'Stone', n, 'Podium')
    prism(0, 0, F-.08, F, 7.75, 'Coping', n, 'Podium cap')
    prism(0, 0, F, F+.02, RW-.1, 'Coping', n)   # flagstone floor
    stairs(0, 7.75*math.cos(math.pi/n), 3.4, F, 5, .32)
    # Eight walls: front door, high vent band all round, windows elsewhere.
    for k in range(n):
        m = math.pi/2+k*math.tau/n
        o = (ap*math.cos(m), ap*math.sin(m), m)
        half = RW*math.sin(math.pi/n)+.02
        wall(o, -half, half, F, T, [(0, 2.2, 3.0)] if k == 0 else [], t=.26)
        if k == 0: leaves(o, 0, 2.2, 3.0, F, .26)
        elif k % 2: window(o, 0, F+1.9, 1.5, 1.6, .26)
        vent(o, 0, 5.9, 3.4, .62, .26)
        wbox(o, 0, T+.1, 0, 2*half+.1, .2, .4, 'Timber')
        wbox(o, 0, T-.12, 0, 2*half, .12, .32, 'Cedar')
    for (x, z) in ngon(n, RW):
        box((x, F+.09, z), (.62, .18, .62), 'Coping')
        rod((x, F+.18, z), (x, T+.1, z), .23, 'Timber')
        cylinder_solid('Wall column', (x, (F+T)/2, z), .23, T-F)
        box((x, T+.25, z), (.5, .3, .5), 'Cedar')
    # Outer colonnade carrying the lower skirt roof; open on all sides.
    ring_pts = ngon(n, 7.2)
    for (x, z) in ring_pts: column(x, z, F, 4.38, .2)
    for i in range(n):
        (ax, az), (bx, bz) = ring_pts[i], ring_pts[(i+1) % n]
        beam((ax, 4.42, az), (bx, 4.42, bz), .28, .26, 'Timber')
        beam((ax, 4.2, az), (bx, 4.2, bz), .14, .2, 'Cedar')
        beam((ax, 4.3, az), (ax*.78, 5.0, az*.78), .18, .18, 'Cedar')
    poly_roof(0, 0, n, 9.2, 4.25, 1.2, RW, .25)              # lower skirt
    poly_roof(0, 0, n, 7.6, 6.55, 2.6, 1.9, .3)              # main roof
    # Louvred smoke lantern (vent cupola) and gourd finial, the alchemy emblem.
    drum = ngon(n, 1.95)
    for (ax, az), (bx, bz) in zip(drum, drum[1:]+drum[:1]):
        beam((ax, 9.6, az), (bx, 9.6, bz), .16, 1.3, 'Window')
        rod((ax, 8.9, az), (ax, 10.4, az), .07, 'Cedar', 6)
        beam((ax, 10.3, az), (bx, 10.3, bz), .14, .12, 'Cedar')
    poly_roof(0, 0, n, 2.7, 10.35, 1.25, 0, .18, 4, 2)
    lathe((0, 11.55, 0), [(.12, 0), (.28, .12), (.3, .3), (.16, .46), (.12, .5), (.2, .62), (.21, .76), (.1, .9), (.03, 1.0), (0, 1.02)], 'Bronze', 8)
    # Plaque hung under the front colonnade beam, visible from the stair.
    plaque('ALCHEMY PAVILION', (0, 3.82, 6.62), 3.0, .5, .0042)
    # Central pill furnace: octagonal dais, three-legged bronze cauldron, glowing firebox.
    prism(0, 0, F, F+.35, 1.9, 'Stone', n)
    prism(0, 0, F+.35, F+.42, 2.0, 'Coping', n)
    cylinder_solid('Furnace dais', (0, F+.21, 0), 2.0, .42)
    y0 = F+.42
    ring((0, F+.03, 0), 2.5, .07, 'Bronze', 8, 'y')   # floor inlay around the dais
    rod((0, y0, 0), (0, y0+.12, 0), .55, 'Lantern', 8)
    for k in range(3):
        a = k*math.tau/3+math.pi/2
        beam((.75*math.cos(a), y0, .75*math.sin(a)), (.5*math.cos(a), y0+.62, .5*math.sin(a)), .16, .16, 'Bronze')
    lathe((0, y0+.5, 0), [(0, 0), (.55, .05), (.85, .35), (.92, .72), (.78, 1.02), (.62, 1.08)], 'Bronze', 12)
    lathe((0, y0+1.58, 0), [(.68, 0), (.56, .2), (.26, .42), (.1, .58), (.16, .66), (0, .74)], 'Timber', 12)
    for s in (-1, 1): ring((s*.95, y0+1.35, 0), .2, .05, 'Bronze', 8, 'x')
    for k in range(3):
        a = k*math.tau/3-math.pi/2
        box((.62*math.cos(a), y0+.32, .62*math.sin(a)), (.3, .22, .3), 'Lantern')
    cylinder_solid('Pill furnace', (0, y0+1.15, 0), .95, 2.3)
    # Smoke hood and flue rising into the louvred lantern.
    lathe((0, 4.3, 0), [(1.25, 0), (.95, .45), (.38, .85)], 'Timber', 8)
    rod((0, 5.1, 0), (0, 9.7, 0), .3, 'Timber', 8)
    for y in (6.0, 8.0): ring((0, y, 0), .32, .05, 'Bronze', 8, 'y')
    # Bellows and the alchemist's cushion facing the fire.
    box((1.9, F+.3, 1.3), (.7, .4, 1.0), 'Cedar', 'Bellows')
    beam((1.9, F+.55, 1.75), (1.9, F+.95, 2.15), .08, .08, 'Timber')
    rod((0, F, 2.75), (0, F+.14, 2.75), .38, 'Fabric', 8)
    # Shelves of glazed pill jars and storage urns on the side and rear walls.
    for k in (2, 4, 6):
        m = math.pi/2+k*math.tau/n
        o = (ap*math.cos(m), ap*math.sin(m), m)
        for y in (F+.35, F+1.05, F+1.75):
            wbox(o, 0, y, -.42, 3.0, .06, .44, 'Cedar')
            for i in range(6): jar(*at(o, -1.25+i*.5, y+.03, -.42), k+i)
        for s in (-1, 1): wbox(o, s*1.5, F+1.05, -.42, .08, 2.1, .44, 'Timber')
        wsolid(o, 'Jar shelf', 0, F+1.05, -.42, 3.1, 2.1, .44)
    for k in (1, 3, 5, 7):
        m = math.pi/2+k*math.tau/n
        x, _, z = at((ap*math.cos(m), ap*math.sin(m), m), -1.3, 0, -.65)
        jar(x, F, z, k, True)
        cylinder_solid('Storage urn', (x, F+.45, z), .42, .9)
    # Grinding table with mortar beside the furnace.
    table(-2.6, F, 1.6, 1.3, .7, .82, 'Grinding table')
    lathe((-2.75, F+.82, 1.6), [(0, 0), (.2, 0), (.24, .16), (.16, .16), (0, .06)], 'Stone', 8)
    beam((-2.75, F+.9, 1.6), (-2.6, F+1.18, 1.75), .06, .06, 'Cedar')
    for (x, z) in ngon(n, 3.2)[::2]: lantern(x, 5.4, z, T+.2)
    # Fire-safety bronze water basins flanking the stair.
    for s in (-1, 1):
        lathe((s*3.3, 0, 8.75), [(0, 0), (.42, 0), (.62, .45), (.72, .8), (.66, .82)], 'Bronze', 10)
        lathe((s*3.3, .76, 8.75), [(.64, 0), (0, 0)], 'Water', 10)
        cylinder_solid('Water basin', (s*3.3, .41, 8.75), .72, .82)
    # Camera clearance under the main roof (invisible slab above the wall plate).
    solids[B].append({'name': 'Ceiling clearance', 'type': 'convex',
                      'points': [[x, y, z] for y in (T+.2, T+.3) for x, z in ngon(n, RW-.1)]})

# ================================================================ 2. Medicine Hall
def medicine_hall():
    """Two-storey shopfront with stepped white fire walls, drawer-cabinet wall,
    serving counters, and an upper drying loft with a balcony."""
    begin('medicine_hall')
    F, F2, T2 = .45, 4.2, 7.2
    box((0, .2, .4), (17.6, .4, 11.2), 'Stone', 'Podium')
    box((0, F-.03, .4), (17.8, .06, 11.4), 'Coping', 'Podium cap')   # top flush with floor and stair
    box((0, F+.01, 0), (15.5, .02, 8.7), 'Floor')
    stairs(0, 6.1, 6.0, F, 3, .3)
    # Stepped fire walls (side walls) rising above the gable roof.
    for s in (-1, 1):
        x = s*8.0
        box((x, (F+1.0)/2, .1), (.5, F+1.0, 12.6), 'Stone')
        # Steps measured from the ridge line (z=.1); each outer end gets an upturned horse-head cap.
        for d0, d1, top in ((0, 1.7, 10.45), (1.7, 3.6, 9.55), (3.6, 5.2, 8.6), (5.2, 6.3, 7.9)):
            for a, b in ([(-d1, d1)] if d0 == 0 else [(d0, d1), (-d1, -d0)]):
                z0, z1 = .1+a, .1+b
                zc, zl = (z0+z1)/2, z1-z0
                box((x, (F+1.0+top)/2, zc), (.4, top-F-1.0, zl), 'Plaster')
                solid('Fire wall', (x, top/2, zc), (.5, top, zl))
                box((x, top+.08, zc), (.72, .16, zl+.1), 'Jade')
                box((x, top+.2, zc), (.16, .1, zl+.12), 'TileLight')
                for ze, sgn in ((z0, -1), (z1, 1)):
                    if abs(ze-.1) >= d1-.01:
                        beam((x, top+.2, ze), (x, top+.5, ze+sgn*.35), .16, .14, 'TileLight')
        for zz in (-2.0, 2.0):
            window((x, zz, '+x' if s > 0 else '-x'), 0, F+1.9, 1.1, 1.1, .4)
            window((x, zz, '+x' if s > 0 else '-x'), 0, F2+1.6, 1.0, 1.0, .4)
    # Back wall, both storeys.
    back = (0, -4.5, '-z')
    wall(back, -7.8, 7.8, F, F2)
    wall(back, -7.8, 7.8, F2, T2, dado=.2)
    for u in (-4.8, 0, 4.8): window(back, u, F2+1.6, 1.4, 1.1)
    # Ground-floor shopfront: columns, central entrance, counters with propped shutters.
    xs = (-8, -4.8, -1.6, 1.6, 4.8, 8)
    for x in xs:
        if abs(x) < 8: column(x, 4.5, F, F2-.16, .2)
        box((x, F2-.25, 5.15), (.18, .24, 1.45), 'Cedar')
        beam((x, F2-1.1, 4.6), (x, F2-.3, 5.6), .12, .14, 'Cedar')
    box((0, F2-.3, 4.5), (15.6, .3, .32), 'Timber')
    box((0, F2-.6, 4.5), (15.6, .12, .26), 'Cedar')
    for a, b in ((-7.8, -4.8), (-4.8, -1.6), (1.6, 4.8), (4.8, 7.8)):
        m, w = (a+b)/2, b-a-.4
        box((m, F+.5, 4.5), (w, 1.0, .3), 'Cedar', 'Serving counter')
        box((m, F+1.04, 4.45), (w+.3, .08, .8), 'Timber')
        for i in range(3): box((m-w/3+i*w/3, F+1.12, 4.4), (.32, .08, .22), 'Plaster')  # paper herb packets
        hinge, drop = F2-.45, .55
        geo('Cedar', [(m-w/2, hinge, 4.68), (m+w/2, hinge, 4.68), (m+w/2, hinge-drop, 4.68+.8), (m-w/2, hinge-drop, 4.68+.8)], [(0, 1, 2, 3)])
        for e in (-1, 1): beam((m+e*w*.35, F+1.1, 4.62), (m+e*w*.35, hinge-drop, 5.45), .04, .04, 'Timber')
    box((0, F+.015, 4.5), (3.2, .03, .3), 'Stone')
    # Upper floor slab with a stairwell along the west fire wall.
    for (x0, x1, z0, z1) in ((-6.5, 7.8, -4.3, 4.3), (-7.8, -6.5, -4.3, -2.0), (-7.8, -6.5, 3.3, 4.3)):
        box(((x0+x1)/2, F2-.08, (z0+z1)/2), (x1-x0, .16, z1-z0), 'Floor', 'Upper floor')
    for x in (-4.8, -1.6, 1.6, 4.8): box((x, F2-.28, 0), (.2, .24, 8.6), 'Timber')
    stairs(-7.15, -2.0, 1.2, F2, 21, .25, '+z')
    beam((-6.52, F+1.0, 2.7), (-6.52, F2+1.0, -2.0), .08, .08, 'Cedar')     # stair handrail
    box((-6.52, F+.5, 2.7), (.1, 1.0, .1), 'Cedar')
    box((-6.52, F2+.5, -2.0), (.1, 1.0, .1), 'Cedar')
    box((-6.45, F2+.95, .65), (.08, .08, 5.3), 'Cedar', 'Stairwell rail')
    solid('Stairwell rail', (-6.45, F2+.5, .65), (.1, 1.0, 5.3))
    box((-7.15, F2+.95, 3.3), (1.3, .08, .08), 'Cedar', 'Stairwell rail')
    solid('Stairwell rail', (-7.15, F2+.5, 3.3), (1.3, 1.0, .1))
    # Apothecary wall: drawer cabinets along the back wall, jars on top.
    for i, cx in enumerate((-4.6, -2.0, .6, 3.2, 5.8)):
        box((cx, F+1.3, -4.1), (2.5, 2.6, .55), 'Cedar', 'Drawer cabinet')
        box((cx, F+1.3, -3.82), (2.36, 2.46, .02), 'Floor')
        for r in range(7): box((cx, F+.15+r*.39, -3.8), (2.4, .05, .04), 'Timber')
        for c in range(7): box((cx-1.2+c*.4, F+1.3, -3.8), (.05, 2.5, .04), 'Timber')
        for r in range(6):
            for c in range(6): box((cx-1.0+c*.4, F+.35+r*.39, -3.78), (.07, .07, .04), 'Bronze')
        for c in range(4): jar(cx-.9+c*.6, F+2.6, -4.1, i+c)
    # East wall jar shelves and the central preparation table.
    for y in (F+.5, F+1.2, F+1.9):
        box((7.45, y, 0), (.5, .06, 5.0), 'Cedar')
        for i in range(8): jar(7.45, y+.03, -2.1+i*.6, i)
    for zz in (-2.5, 2.5): box((7.45, F+1.2, zz), (.5, 2.3, .08), 'Timber')
    solid('Jar shelf', (7.45, F+1.2, 0), (.5, 2.3, 5.0))
    table(1.0, F, -1.6, 3.6, 1.0, .85, 'Preparation table')
    lathe((0, F+.85, -1.6), [(0, 0), (.22, 0), (.26, .18), (.18, .18), (0, .07)], 'Stone')
    box((1.2, F+.9, -1.6), (.9, .06, .35), 'Timber')                       # herb cutter board
    beam((.8, F+.95, -1.75), (1.6, F+1.05, -1.45), .04, .12, 'Bronze')       # cutter blade
    rod((2.3, F+.85, -1.6), (2.3, F+1.4, -1.6), .03, 'Timber', 4)            # balance scale
    beam((2.0, F+1.4, -1.6), (2.6, F+1.4, -1.6), .03, .03, 'Bronze')
    for s in (-1, 1): lathe((2.3+s*.3, F+1.12, -1.6), [(0, 0), (.13, .02), (.14, .05)], 'Bronze')
    for x in (-3.0, 4.0): lantern(x, F2-.85, 0, F2-.36)
    # Upper loft walls, balcony door and windows.
    front2 = (0, 4.5, '+z')
    wall(front2, -7.8, 7.8, F2, T2, [(0, 1.6, 2.4)], dado=.2)
    leaves(front2, 0, 1.6, 2.4, F2)
    for u in (-5.6, -3.0, 3.0, 5.6): window(front2, u, F2+1.55, 1.4, 1.2)
    for z in (4.5, -4.5): box((0, T2+.1, z), (15.6, .2, .36), 'Timber')
    solids[B].append({'name': 'Ceiling clearance', 'type': 'box', 'position': [0, T2+.25, 0], 'size': [15.6, .1, 9.0]})
    # Drying racks of herb sieves and hanging bundles in the loft.
    fills = ('Leaf', 'Soil', 'Bronze', 'SpiritHerb')
    for i, x in enumerate((-3.6, 0, 3.6)):
        for a in (-.5, .5):
            for b in (-1.0, 1.0): box((x+a, F2+1.0, -2.2+b), (.07, 2.0, .07), 'Timber')
        for j, y in enumerate((F2+.35, F2+.85, F2+1.35, F2+1.85)):
            box((x, y, -2.2), (1.1, .04, 2.1), 'Cedar')
            for b in (-.5, .5): basket(x, y+.02, -2.2+b, fills[(i+j) % 4])
        solid('Drying rack', (x, F2+1.0, -2.2), (1.1, 2.0, 2.1))
    for z in (.8, 2.6):
        box((0, F2+2.55, z), (13.0, .06, .06), 'Timber')
        for i in range(10): cone((-5.6+i*1.25, F2+2.52, z), .14, -.55, fills[i % 3], 5)
    # Balcony: floor, railing, posts to the eave, hanging herb bundles, plaque below.
    box((0, F2-.08, 5.15), (15.4, .16, 1.3), 'Floor', 'Balcony')
    for x in [-7.5+i*1.5 for i in range(11)]: box((x, F2+.5, 5.72), (.08, 1.0, .08), 'Cedar')
    for y in (F2+.45, F2+.95): box((0, y, 5.72), (15.2, .07, .07), 'Cedar')
    solid('Balcony rail', (0, F2+.5, 5.72), (15.2, 1.0, .1))
    for x in (-4.8, -1.6, 1.6, 4.8): rod((x, F2, 5.55), (x, 7.12, 5.55), .13, 'Timber')
    box((0, 7.1, 5.55), (15.4, .2, .2), 'Timber')
    for i in range(12): cone((-6.6+i*1.2, 6.95, 5.62), .12, -.45, fills[i % 3], 5)
    plaque('MEDICINE HALL', (0, 3.7, 5.86), 2.8, .5, .005)
    gable(0, .1, 16.0, 12.6, 7.25, 2.4)
    # Front yard drying racks flanking the stair.
    for s in (-1, 1):
        x = s*5.5
        for a in (-.8, .8): box((x+a, .8, 7.6), (.08, 1.6, .08), 'Timber')
        for j, y in enumerate((.5, .95, 1.4)):
            box((x, y, 7.6), (1.7, .04, .6), 'Cedar')
            for a in (-.42, .42): basket(x+a, y+.02, 7.6, fills[(j+int(a > 0)) % 4], .34)
        solid('Yard drying rack', (x, .8, 7.6), (1.7, 1.6, .6))

alchemy_pavilion()
medicine_hall()

# ---------------------------------------------------------------- meshes, export, scenes
NAMES = {
    'alchemy_pavilion': ('Alchemy Pavilion', 'AlchemyPavilion'),
    'medicine_hall': ('Medicine Hall', 'MedicineHall'),
}
groups = {}
for (bid, mat), (verts, faces) in batches.items():
    label = NAMES[bid][1]
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
bpy.ops.wm.save_as_mainfile(filepath=str(STAGE/'source/claude_batch2.blend'))

def f(v): return '%.4g' % v
def vec(p): return ', '.join(f(c) for c in p)

summary = {}
for bid, objs in groups.items():
    out = STAGE/bid
    out.mkdir(exist_ok=True)
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.gltf(filepath=str(out/(bid+'.glb')), export_format='GLB', use_selection=True,
                              export_yup=True, export_materials='EXPORT', export_normals=True, export_texcoords=False)
    pts = [p for (b, _), (v, _) in batches.items() if b == bid for p in v]
    lo = [min(p[i] for p in pts) for i in range(3)]
    hi = [max(p[i] for p in pts) for i in range(3)]
    sub, nodes = [], []
    for i, s in enumerate(solids[bid]):
        sid = 'Shape_%03d' % i
        pos = s.get('position', [0, 0, 0])
        if s['type'] == 'box':
            sub.append('[sub_resource type="BoxShape3D" id="%s"]\nsize = Vector3(%s)\n' % (sid, vec(s['size'])))
        elif s['type'] == 'cylinder':
            sub.append('[sub_resource type="CylinderShape3D" id="%s"]\nheight = %s\nradius = %s\n' % (sid, f(s['height']), f(s['radius'])))
        else:
            sub.append('[sub_resource type="ConvexPolygonShape3D" id="%s"]\npoints = PackedVector3Array(%s)\n' % (sid, ', '.join(vec(p) for p in s['points'])))
        name = ''.join(c for c in s['name'].title() if c.isalnum())+'_%03d' % i
        nodes.append('[node name="%s" type="CollisionShape3D" parent="Collision"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s)\nshape = SubResource("%s")\n' % (name, vec(pos), sid))
    for i, lab in enumerate(labels[bid]):
        nodes.append('[node name="Plaque%s" type="Label3D" parent="."]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s)\npixel_size = %s\nmodulate = Color(0.718, 0.631, 0.427, 1)\noutline_size = 0\ntext = "%s"\nfont_size = 64\n' % (i or '', vec(lab['position']), f(lab['pixel_size']), lab['text']))
    tscn = '[gd_scene load_steps=%d format=3]\n\n[ext_resource type="PackedScene" path="%s%s/%s.glb" id="1_model"]\n\n' % (len(sub)+2, RES, bid, bid)
    tscn += '\n'.join(sub)+'\n[node name="%s" type="Node3D"]\n\n[node name="Model" parent="." instance=ExtResource("1_model")]\n\n' % NAMES[bid][1]
    tscn += '[node name="Collision" type="StaticBody3D" parent="." groups=["solid_world"]]\ncollision_mask = 2\n\n'+'\n'.join(nodes)
    (out/(bid+'.tscn')).write_text(tscn, encoding='utf-8')
    summary[bid] = {
        'name': NAMES[bid][0],
        'scene': RES+bid+'/'+bid+'.tscn',
        'model': RES+bid+'/'+bid+'.glb',
        'triangles': sum(len(o.data.polygons) for o in objs),
        'vertices': sum(len(o.data.vertices) for o in objs),
        'surfaces': len(objs),
        'materials': sorted(m for (b, m) in batches if b == bid),
        'bounds_min': [round(v, 3) for v in lo], 'bounds_max': [round(v, 3) for v in hi],
        'size_xyz_m': [round(hi[i]-lo[i], 2) for i in range(3)],
        'collision_shapes': len(solids[bid]),
        'plaques': [l['text'] for l in labels[bid]],
    }
(STAGE/'build_summary.json').write_text(json.dumps(summary, indent=2))
print(json.dumps({k: (v['triangles'], v['size_xyz_m'], v['collision_shapes']) for k, v in summary.items()}))

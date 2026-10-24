"""Claude staging: Mission Hall, Split-Cloud low-poly style.

Run: blender --background --factory-startup --python this_file

Helpers are a verbatim copy of staging/claude_buildings_batch2/tools/build_claude_batch2.py
(lines 19-325; earlier batches are frozen and must not be rerun), followed by the
Mission Hall additions and the same export/scene writer. Godot axes (X across,
Y up, +Z front), metres, origin on the ground under the asset centre. No world
placement. Writes only inside staging/claude_mission_hall/.
"""
from pathlib import Path
import math, json
import bpy, bmesh
from mathutils import Vector

STAGE = Path(__file__).resolve().parents[1]
RES = 'res://staging/claude_mission_hall/'
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


# ---------------------------------------------------------------- Mission Hall additions
def verge(P, w, d, axis):
    """Raised verge rolls and upturned bronze ridge ends for a gable() whose ends are visible."""
    for side in (-1, 1):
        for u in (-w/2, w/2):
            for j in range(5):
                beam(P(u, side*d/2*(1-j/5), .06), P(u, side*d/2*(1-(j+1)/5), .06), .16, .15, 'TileLight')
    for u in (-w/2, w/2):
        s = 1 if u > 0 else -1
        a = P(u, 0, .08)
        beam(a, a+(Vector((s*.35, .32, 0)) if axis == 'x' else Vector((0, .32, s*.35))), .14, .15, 'Bronze')

def pent(x0, x1, z0, y0, z1, y1, steps=3):
    """Single swept lean-to slope from (z0, y0) at the wall down to the eave (z1, y1)."""
    w = x1-x0
    across = max(4, round(w/1.6))
    def P(i, j, dy=0.0):
        u, s = x0+w*i/across, j/steps
        e = abs(i/across*2-1)
        return Vector((u, y1+(y0-y1)*(1-s)**1.35+.25*e**8*s**2+dy, z0+(z1-z0)*s))
    top = [P(i, j) for j in range(steps+1) for i in range(across+1)]
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
    off = steps*(across+1)
    for i in range(across): geo('Cedar', [top[off+i], top[off+i+1], bottom[off+i+1], bottom[off+i]], [(0,1,2,3)])
    for i in (0, across):
        for j in range(steps):
            a = j*(across+1)+i
            geo('Cedar', [top[a], top[a+across+1], bottom[a+across+1], bottom[a]], [(0,1,2,3)])
    for k in range(1, round(w/.8)):
        x = x0+w*k/round(w/.8)
        for j in range(steps):
            a, b = P(0, j, .025), P(0, j+1, .025)
            beam((x, a.y, a.z), (x, b.y, b.z), .042, .045, 'TileLight')
    beam(P(0, 0, .05), P(across, 0, .05), .2, .16, 'TileLight')   # flashing against the wall

def gable_end(P, axis, u, v0, v1, ybase):
    """Plastered gable infill with a timber sill beam under a gable() at ridge position u."""
    def flat(v):
        p = P(u, v)
        return Vector((p.x, ybase, p.z))
    pts = [flat(v0), flat(v1), P(u, v1, -.21), P(u, 0, -.21), P(u, v0, -.21)]
    geo('Plaster', pts, [(0, 1, 2, 3, 4)])
    beam(pts[0], pts[1], .22, .22, 'Timber')
    for a, b in ((pts[0], pts[4]), (pts[1], pts[2])): beam(a, b, .2, .2, 'Timber')
    return pts

def emblem(c, r, normal):
    """Split-Cloud mountain strokes in a bronze ring, facing +z/-z/+x/-x."""
    o = (c[0], c[2], normal)
    ring(c, r, .09, 'Bronze', 16, 'z' if normal in ('+z', '-z') else 'x')
    pts = [(-.62*r, -.45*r), (-.22*r, .45*r), (0, .02*r), (.22*r, .45*r), (.62*r, -.45*r)]
    q = [at(o, a, c[1]+b, 0) for a, b in pts]
    for a, b in zip(q, q[1:]): beam(a, b, .1, .09, 'Bronze')

RANKS = ('Jade', 'Bronze', 'Fabric', 'Coping')
def tags(o, u0, u1, y0, rows, n, face, cols_rank=False):
    """Hanging mission tablets on a board face (n=face): one colour per rank."""
    for r in range(rows):
        for c in range(n):
            u = u0+(u1-u0)*(c+.5)/n
            mat = RANKS[(c*4)//n] if cols_rank else RANKS[r % 4]
            wbox(o, u, y0+r*.42, face, .2, .3, .03, mat)
            wbox(o, u, y0+r*.42+.19, face-.01, .03, .08, .02, 'Timber')

def bracket(x, y, z, scale=1):
    # Hall bracket (copied from batch 1): alternating timber bearing arms.
    for i in range(3):
        w = (.70+i*.40)*scale
        box((x, y+i*.18, z), (w, .14*scale, .28*scale), 'Cedar')
        box((x, y+i*.18+.09, z), (.25*scale, .14*scale, w), 'Timber')
    for s in (-1, 1):
        beam((x, y-.62*scale, z), (x+s*.75*scale, y+.05, z), .17*scale, .22*scale, 'Cedar')

def chair(x, y, z, facing):
    box((x, y+.45, z), (.5, .06, .5), 'Cedar')
    for a in (-.2, .2):
        for b in (-.2, .2): box((x+a, y+.22, z+b), (.05, .44, .05), 'Timber')
    box((x, y+.8, z-facing*.23), (.5, .65, .05), 'Cedar')
    solid('Chair', (x, y+.45, z), (.5, .9, .5))

# ================================================================ Mission Hall
def mission_hall():
    """Gable-fronted public hall: pediment emblem over a lean-to porch, an avenue of
    roofed mission boards on the forecourt, reporting counter and ranking board inside."""
    begin('mission_hall')
    F, T = .75, 5.75
    box((0, (F-.06)/2, .2), (18.8, F-.06, 19.6), 'Stone', 'Podium')
    box((0, F-.03, .2), (19.0, .06, 19.8), 'Coping', 'Podium cap')
    stairs(0, 10.1, 6.0, F, 5, .3)
    # Low balustrade along the forecourt edges, open at the stair.
    for x0, x1, z0, z1 in ((3.2, 9.4, 10.0, 10.0), (-9.4, -3.2, 10.0, 10.0), (9.4, 9.4, 4.0, 10.0), (-9.4, -9.4, 4.0, 10.0)):
        L = max(x1-x0, z1-z0)
        for i in range(round(L/1.55)+1):
            t = i/round(L/1.55)
            box((x0+(x1-x0)*t, F+.32, z0+(z1-z0)*t), (.22, .64, .22), 'Stone')
        c = ((x0+x1)/2, (z0+z1)/2)
        size = (L+.2, .08, .26) if z0 == z1 else (.26, .08, L+.2)
        box((c[0], F+.66, c[1]), size, 'Coping')
        solid('Balustrade', (c[0], F+.35, c[1]), (size[0], .7, size[2]))
    box((0, F+.01, -2.5), (13.7, .02, 11.7), 'Floor')
    box((0, F+.022, .4), (2.4, .01, 6.0), 'Stone')                       # aisle to the counter
    # Walls.
    front = (0, 3.5, '+z')
    wall(front, -7, 7, F, T, [(0, 3.0, 3.4)])
    leaves(front, 0, 3.0, 3.4, F)
    for s in (-1, 1):
        window(front, s*5.25, F+2.0, 2.0, 1.9)
        # Wall-mounted notice boards beside the door, under the porch.
        wbox(front, s*2.75, F+1.9, .2, 1.5, 1.8, .08, 'Timber')
        wsolid(front, 'Notice board', s*2.75, F+1.9, .23, 1.62, 1.9, .16)   # covers rails, tags and papers
        for y in (F+1.0, F+2.8): wbox(front, s*2.75, y, .26, 1.6, .08, .06, 'Cedar')
        tags(front, s*2.75-.6, s*2.75+.6, F+1.25, 3, 4, .26)
        wbox(front, s*2.75+.25, F+2.45, .27, .42, .32, .02, 'Plaster')
    back = (0, -8.5, '-z')
    wall(back, -7, 7, F, T)
    for o, us in (((7, -2.5, '+x'), (-3.6, 0)), ((-7, -2.5, '-x'), (3.6, 0))):   # windows at z=1.1 and -2.5
        wall(o, -6, 6, F, T)
        for u in us: window(o, u, F+2.3, 1.8, 1.8)
    for x in (-7, -3.85, -1.8, 1.8, 3.85, 7):
        box((x, (F+T)/2, 3.5), (.24 if abs(x) < 7 else .32, T-F, .32), 'Timber')
    for x, z in ((-7, -8.5), (7, -8.5), (-7, -.7), (7, -.7), (-7, -5.5), (7, -5.5), (0, -8.5)):
        box((x, (F+T)/2, z), (.32, T-F, .32), 'Timber')
    for z in (3.5, -8.5):
        box((0, T+.1, z), (14.4, .2, .36), 'Timber')
        box((0, T-.15, z), (14.0, .12, .3), 'Cedar')
    for x in (-7, 7): box((x, T+.1, -2.5), (.36, .2, 12.4), 'Timber')
    # Exposed king-post trusses (no flat ceiling); invisible clearance slab for the camera.
    for z in (-5.5, -2.5, .5):
        box((0, T+.25, z), (14.0, .3, .3), 'Timber')
        beam((0, T+.4, z), (0, 8.95, z), .26, .26, 'Timber')
        for s in (-1, 1): beam((s*6.2, T+.4, z), (0, 8.7, z), .2, .22, 'Cedar')
    solid('Ceiling clearance', (0, T+.05, -2.5), (13.7, .1, 11.7))
    # Front-facing gable roof with emblem pediment, plus lean-to porch.
    P = gable(0, -2.5, 13.6, 16.4, T+.2, 3.4, 'z')
    verge(P, 13.6, 16.4, 'z')
    for u in (6.0, -6.0): gable_end(P, 'z', u, -7, 7, T+.15)
    emblem((0, 7.15, 3.62), 1.0, '+z')
    emblem((0, 7.15, -8.62), 1.0, '-z')
    pent(-8.0, 8.0, 3.62, 5.55, 6.3, 4.6)
    for x in (-7, -4.2, -1.4, 1.4, 4.2, 7):
        column(x, 5.75, F, 4.2, .19)
        bracket(x, 3.8, 5.75, .5)
        box((x, 4.05, 4.68), (.18, .2, 2.1), 'Cedar')
    box((0, 4.35, 5.75), (14.6, .3, .3), 'Timber')
    plaque('MISSION HALL', (0, 3.95, 5.94), 2.3, .5, .0048)
    for x in (-2.8, 2.8): lantern(x, 3.75, 5.2, 4.25)
    # Mission drum on the porch: struck when new commissions are posted.
    x, z, y = -5.6, 4.7, F+1.05
    rod((x, y, z-.35), (x, y, z+.35), .55, 'Cedar', 10)
    for e in (-1, 1):
        rod((x, y, z+e*.35), (x, y, z+e*.37), .5, 'Plaster', 10)
        ring((x, y, z+e*.33), .56, .05, 'Bronze', 10)
    for e in (-1, 1): box((x+e*.62, (F+y+.2)/2, z), (.1, y+.2-F, .1), 'Timber')
    box((x, y+.22, z), (1.34, .1, .12), 'Timber')
    solid('Mission drum', (x, F+.8, z), (1.4, 1.6, .8))
    # Avenue of roofed mission boards facing the forecourt axis.
    for s in (-1, 1):
        xc, zc = s*6.4, 8.3
        o = (xc, zc, '-x' if s > 0 else '+x')
        box((xc, F+.2, zc), (.5, .4, 3.1), 'Stone')
        for e in (-1, 1): rod((xc, F, zc+e*1.45), (xc, F+3.2, zc+e*1.45), .14, 'Timber')
        box((xc, F+1.75, zc), (.16, 2.3, 2.8), 'Timber')
        for y in (F+.6, F+2.9): box((xc, y, zc), (.24, .1, 2.9), 'Cedar')
        box((xc, F+2.72, zc), (.22, .14, 2.7), 'Bronze')
        tags(o, -1.25, 1.25, F+.95, 3, 8, .1)
        for u, y in ((-.9, F+2.3), (.15, F+2.32), (.95, F+2.28)):
            wbox(o, u, y, .1, .5, .4, .02, 'Plaster')
        solid('Mission board', (xc, F+1.6, zc), (.5, 3.2, 3.1))
        g = gable(xc, zc, 3.6, 1.3, F+3.05, .45, 'z')
        verge(g, 3.6, 1.3, 'z')
    # Reporting counter, officials' desks and chairs.
    box((0, F+.55, -3.0), (9.0, 1.1, .8), 'Cedar')
    solid('Reporting counter', (0, F+.59, -3.0), (9.2, 1.18, 1.0))   # includes the overhanging top
    box((0, F+1.14, -3.0), (9.2, .08, 1.0), 'Timber')
    for x in (-3.0, 0, 3.0):
        box((x, F+.55, -2.59), (2.4, .7, .02), 'Fabric')
        ring((x, F+.55, -2.57), .22, .04, 'Bronze', 4)
    for x in (-3.6, -1.2, 1.4, 3.4):
        for k in range(3): box((x, F+1.2+k*.06, -3.05), (.36, .06, .26), 'Plaster')   # ledgers
    box((.3, F+1.22, -2.95), (.14, .1, .14), 'Bronze')                              # official seal
    for x in (-2.0, 2.2):
        box((x, F+1.2, -3.1), (.6, .05, .35), 'Cedar')
        for k in range(5): box((x-.22+k*.11, F+1.25, -3.1), (.07, .05, .2), RANKS[k % 4])   # token trays
    for x in (-2.6, 2.6):
        table(x, F, -4.9, 1.8, .8, .8, 'Officials desk')
        chair(x, F, -5.75, 1)
        box((x+.5, F+.82, -4.9), (.4, .04, .3), 'Plaster')
    box((4.0, F+.3, -2.1), (.9, .6, .6), 'Cedar', 'Returns chest')
    for dx in (-.3, .3): box((4.0+dx, F+.3, -2.1), (.06, .62, .62), 'Bronze')
    # Mission ranking board on the back wall, ranks by colour column.
    rb = (0, -8.3, '+z')
    wbox(rb, 0, F+2.9, 0, 9.6, 3.4, .12, 'Timber', 'Ranking board')
    for y in (F+1.2, F+4.6): wbox(rb, 0, y, .05, 9.8, .12, .1, 'Cedar')
    for u in (-4.85, -2.4, 0, 2.4, 4.85): wbox(rb, u, F+2.9, .05, .1, 3.4, .1, 'Cedar')
    wbox(rb, 0, F+4.3, .07, 9.4, .22, .04, 'Bronze')
    emblem((0, F+4.95, -8.22), .32, '+z')
    tags(rb, -4.6, 4.6, F+1.5, 6, 20, .08, True)
    # Gong between the desks; mission-scroll racks on both side walls.
    box((0, F+.1, -7.2), (1.6, .2, .4), 'Stone')
    for e in (-1, 1): box((e*.72, F+1.15, -7.2), (.12, 2.1, .12), 'Timber')
    box((0, F+2.2, -7.2), (1.7, .14, .16), 'Timber')
    rod((0, F+1.4, -7.25), (0, F+1.4, -7.15), .55, 'Bronze', 12)
    ring((0, F+1.4, -7.13), .45, .04, 'Timber', 12)
    for e in (-1, 1): beam((e*.4, F+2.13, -7.2), (e*.3, F+1.95, -7.2), .02, .02, 'Timber')
    solid('Gong stand', (0, F+1.1, -7.2), (1.6, 2.2, .4))
    for s in (-1, 1):
        x = s*6.62
        box((x+s*.2, F+1.2, -6.0), (.05, 2.4, 3.6), 'Timber')
        for y in [F+.05+k*.58 for k in range(5)]: box((x, y, -6.0), (.45, .05, 3.6), 'Cedar')
        for zz in [-7.8+k*.9 for k in range(5)]: box((x, F+1.2, zz), (.45, 2.4, .05), 'Cedar')
        for r in range(4):
            for c in range(8):
                zz, y = -7.65+c*.47, F+.22+r*.58
                rod((x-.2, y, zz), (x+.2, y, zz), .07, 'Plaster' if (r+c) % 3 else 'Fabric', 6)
        solid('Scroll rack', (x, F+1.2, -6.0), (.45, 2.4, 3.6))
    # Waiting benches along the side walls by the entrance.
    for s in (-1, 1):
        x = s*6.55
        box((x, F+.45, 1.0), (.36, .06, 3.2), 'Cedar')
        for zz in (-.4, 2.4): box((x, F+.22, zz), (.3, .44, .08), 'Timber')
        solid('Waiting bench', (x, F+.24, 1.0), (.36, .48, 3.2))
    for x, z in ((-3.5, .5), (3.5, .5), (-3.5, -5.5), (3.5, -5.5)): lantern(x, T-.3, z, T+.1)

mission_hall()

# ---------------------------------------------------------------- meshes, export, scenes
NAMES = {'mission_hall': ('Mission Hall', 'MissionHall')}
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
bpy.ops.wm.save_as_mainfile(filepath=str(STAGE/'source/claude_mission_hall.blend'))

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

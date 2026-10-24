"""Claude staging: Contribution / Exchange Hall, Split-Cloud low-poly style.

Run: blender --background --factory-startup --python this_file

Helpers are a verbatim copy of staging/claude_mission_hall/tools/build_mission_hall.py
lines 18-414 (earlier deliveries are frozen and must not be rerun), with ONE change:
window() also adds a collision box covering its frame and sill, so the body cannot
clip into window trim. Then the Exchange Hall code and the same export/scene writer.
Godot axes (X across, Y up, +Z front), metres, origin on the ground under the asset
centre. No world placement. Writes only inside staging/claude_exchange_hall/.
"""
from pathlib import Path
import math, json
import bpy, bmesh
from mathutils import Vector

STAGE = Path(__file__).resolve().parents[1]
RES = 'res://staging/claude_exchange_hall/'
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
    wsolid(o, 'Window frame', u, y-.04, 0, w+.26, h+.22, t+.3)   # covers frame and sill depth

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


# ---------------------------------------------------------------- Exchange Hall additions
def coin(c, r, normal):
    """Bronze square-holed coin: the contribution-token emblem (facing +z/-z/+x/-x, or 'down')."""
    q = .32*r
    if normal == 'down':
        ring(c, r, .08, 'Bronze', 16, 'y')
        pts = [(c[0]+a, c[1], c[2]+b) for a, b in ((-q, -q), (q, -q), (q, q), (-q, q))]
    else:
        o = (c[0], c[2], normal)
        ring(c, r, .08, 'Bronze', 16, 'z' if normal in ('+z', '-z') else 'x')
        pts = [at(o, a, c[1]+b, 0) for a, b in ((-q, -q), (q, -q), (q, q), (-q, q))]
    for a, b in zip(pts, pts[1:]+pts[:1]): beam(a, b, .07, .07, 'Bronze')

def outer_verge(P, d, u, axis):
    """Verge rolls and upturned bronze ridge tip at ONE gable end (the other end abuts a wall)."""
    for side in (-1, 1):
        for j in range(5):
            beam(P(u, side*d/2*(1-j/5), .06), P(u, side*d/2*(1-(j+1)/5), .06), .16, .15, 'TileLight')
    s = 1 if u > 0 else -1
    a = P(u, 0, .08)
    beam(a, a+(Vector((s*.35, .32, 0)) if axis == 'x' else Vector((0, .32, s*.35))), .14, .15, 'Bronze')

def crate(x, y, z, s=1.0):
    box((x, y+s/2, z), (s, s, s), 'Cedar')
    for e in (-1, 1): box((x+e*s*.38, y+s/2, z), (.08, s+.02, s+.02), 'Timber')

def sack(x, y, z):
    lathe((x, y, z), [(0, 0), (.3, .02), (.36, .25), (.28, .5), (.12, .6), (.16, .68), (0, .7)], 'Plaster', 7)

def barrel(x, y, z):
    lathe((x, y, z), [(0, 0), (.34, 0), (.4, .45), (.34, .9), (0, .9)], 'Cedar', 10)
    for h in (.15, .75): ring((x, y+h, z), .385, .04, 'Bronze', 10, 'y')
    cylinder_solid('Barrel', (x, y+.45, z), .4, .9)

def goods(x, y, z, k):
    """One item of exchange stock on a shelf: manual box, glazed jar, spirit stones, or scrolls."""
    kind = k % 4
    if kind == 0: box((x, y+.18, z), (.26, .36, .22), ('Fabric', 'Jade', 'Floor')[k % 3])
    elif kind == 1: jar(x, y, z, k)
    elif kind == 2:
        for i, (dx, dz, h) in enumerate(((0, 0, .34), (.09, .05, .22), (-.08, .04, .18))): crystal((x+dx, y, z+dz), .06, h, .04, 'SpiritHerb')
    else:
        for i in range(3): rod((x-.15, y+.06+i*.08, z), (x+.15, y+.06+i*.08, z), .045, 'Plaster', 6)

def shelf_unit(o, u, w, y0, h, depth, levels, k0=0, back='Timber'):
    """Shelving against the wall face o (room side is -n), stocked with goods; one collision box."""
    wbox(o, u, y0+h/2, -.03, w, h, .04, back)   # back panel against the wall
    for e in (-1, 1): wbox(o, u+e*w/2, y0+h/2, -depth/2, .06, h, depth, 'Timber')
    for i in range(levels+1): wbox(o, u, y0+.03+i*(h-.06)/levels, -depth/2, w, .05, depth, 'Cedar')
    n = max(1, int(w/.42))
    for i in range(levels):
        for j in range(n):
            x, y, z = at(o, u-w/2+(j+.5)*w/n, y0+.06+i*(h-.06)/levels, -depth/2)
            goods(x, y, z, k0+i*n+j)
    wsolid(o, 'Shelving', u, y0+h/2, -depth/2, w+.06, h, depth)

# ================================================================ Contribution / Exchange Hall
def exchange_hall():
    """Tripartite treasury: tall square exchange pavilion under a steep pyramid roof with a
    treasure-pearl finial, flanked by lower gable-roofed storeroom wings with verandas."""
    begin('exchange_hall')
    F, T1, T2 = .6, 7.6, 4.6
    box((0, (F-.06)/2, 1.25), (26, F-.06, 14.5), 'Stone', 'Podium')
    box((0, F-.03, 1.25), (26.2, .06, 14.7), 'Coping', 'Podium cap')
    stairs(0, 8.6, 5.0, F, 4, .3)
    for s in (-1, 1):   # stone lanterns flanking the approach
        x, z = s*4.6, 7.6
        box((x, F+.1, z), (.55, .2, .55), 'Stone')
        box((x, F+.6, z), (.24, .8, .24), 'Stone')
        box((x, F+1.04, z), (.5, .08, .5), 'Coping')
        box((x, F+1.28, z), (.34, .4, .34), 'Lantern')
        cone((x, F+1.48, z), .42, .3, 'Stone', 4, math.pi/4)
        solid('Stone lantern', (x, F+.8, z), (.55, 1.6, .55))
    box((0, F+.01, 0), (9.7, .02, 9.7), 'Floor')
    box((0, F+.022, 2.1), (2.2, .01, 5.5), 'Stone')
    # Central exchange pavilion: two-tier facade, door canopy, reward boards, plaque, coin emblem.
    front = (0, 5, '+z')
    wall(front, -5, 5, F, T1, [(0, 3.2, 3.6)], t=.26)
    leaves(front, 0, 3.2, 3.6, F, .26)
    for s in (-1, 1):
        window(front, s*3.0, F+5.4, 1.8, 1.3, .26)
        for x in (s*2.3, s*3.85):          # reward-list boards: tiers of exchange tablets
            wbox(front, x, F+1.9, .2, .66, 2.8, .08, 'Timber')
            wbox(front, x, F+3.36, .24, .76, .1, .08, 'Bronze')
            tags(front, x-.17, x+.17, F+.85, 6, 2, .26)
            wsolid(front, 'Reward list', x, F+1.9, .23, .78, 2.9, .16)
    plaque('CONTRIBUTION HALL', (0, F+4.45, 5.2), 3.6, .55, .0042)
    coin((0, F+5.55, 5.2), .72, '+z')
    pent(-2.3, 2.3, 5.14, F+4.0, 6.4, F+3.55)
    for s in (-1, 1): beam((s*2.0, F+3.0, 5.15), (s*2.0, F+3.5, 6.2), .12, .12, 'Cedar')
    back = (0, -5, '-z')
    wall(back, -5, 5, F, T1, t=.26)
    coin((0, F+5.0, -5.2), .72, '-z')
    for o, u in (((5, 0, '+x'), 2.4), ((-5, 0, '-x'), -2.4)):   # doors to the storerooms at z=-2.4
        wall(o, -5, 5, F, T1, [(u, 1.6, 2.6)], t=.26)
    leaves((5, 0, '-x'), -2.4, 1.6, 2.6, F, .26)      # leaves swing into the wings, off the staff lane
    leaves((-5, 0, '+x'), 2.4, 1.6, 2.6, F, .26)
    for x in (-5, 5):
        for z in (-5, 5): box((x, (F+T1)/2, z), (.34, T1-F, .34), 'Timber')
    for x in (-2.82, 2.82): box((x, (F+T1)/2, 5), (.24, T1-F, .32), 'Timber')
    for z in (-5, 5):
        box((0, T1+.1, z), (10.4, .2, .38), 'Timber')
        box((0, F+3.9, z+(.16 if z > 0 else -.16)), (10.3, .14, .08), 'Cedar')
        for x in (-5, -2.5, 2.5, 5): bracket(x, T1-.42, z, .55)
    for x in (-5, 5):
        box((x, T1+.1, 0), (.38, .2, 10.4), 'Timber')
        box((x+(.16 if x > 0 else -.16), F+3.9, 0), (.08, .14, 10.3), 'Cedar')
    poly_roof(0, 0, 4, 6.5*math.sqrt(2), T1+.15, 3.8, 0, .3, 6, 6)
    lathe((0, T1+3.85, 0), [(.26, 0), (.34, .14), (.2, .28), (.32, .44), (.38, .64), (.3, .84), (.12, .98), (0, 1.04)], 'Bronze', 8)
    crystal((0, T1+4.86, 0), .1, .4, .1, 'SpiritHerb')
    # Coffered (caisson) ceiling with a coin at its centre; doubles as camera clearance.
    box((0, T1-.04, 0), (9.74, .08, 9.74), 'Timber', 'Ceiling clearance')
    for k in (-3.6, -1.2, 1.2, 3.6):
        box((k, T1-.17, 0), (.18, .2, 9.7), 'Cedar')
        box((0, T1-.17, k), (9.7, .2, .18), 'Cedar')
    for a in (-2.4, 0, 2.4):
        for b in (-2.4, 0, 2.4):
            if a or b: box((a, T1-.1, b), (2.0, .02, 2.0), 'Fabric')
    coin((0, T1-.14, 0), .8, 'down')
    for x, z in ((-2.4, 2.4), (2.4, 2.4), (-2.4, -2.6), (2.4, -2.6)): lantern(x, F+4.6, z, T1-.27)
    # Exchange counter with abacus, token stacks, ledger and balance.
    box((0, F+.5, -1.2), (6.8, 1.0, .8), 'Cedar')
    box((0, F+1.04, -1.2), (7.0, .08, 1.0), 'Timber')
    solid('Exchange counter', (0, F+.54, -1.2), (7.0, 1.08, 1.0))   # includes the overhanging top
    for x in (-2.2, 0, 2.2):
        box((x, F+.5, -.79), (1.8, .62, .02), 'Fabric')
        coin((x, F+.5, -.77), .2, '+z')
    y, ax, az = F+1.08, -1.5, -1.2
    for e in (-1, 1):
        box((ax, y+.03, az+e*.2), (.9, .05, .04), 'Timber')
        box((ax+e*.45, y+.03, az), (.04, .05, .44), 'Timber')
    box((ax, y+.03, az-.08), (.88, .04, .03), 'Timber')
    for i in range(9):
        x = ax-.36+i*.09
        box((x, y+.02, az), (.012, .012, .38), 'Timber')
        for zz in (-.15, -.11, .0, .04, .08): box((x, y+.04, az+zz), (.06, .04, .035), 'Floor')
    for i, (x, mat) in enumerate(((.5, 'Bronze'), (.75, 'Jade'), (1.0, 'Bronze'))):
        rod((x, y, -1.25), (x, y+.05+i*.04, -1.25), .07, mat, 8)
    box((2.4, y+.03, -1.2), (.42, .06, .32), 'Fabric')
    box((2.4, y+.07, -1.2), (.38, .03, .3), 'Plaster')
    rod((-2.8, y, -1.25), (-2.8, y+.5, -1.25), .03, 'Timber', 4)
    beam((-3.1, y+.5, -1.25), (-2.5, y+.5, -1.25), .03, .03, 'Bronze')
    for e in (-1, 1): lathe((-2.8+e*.3, y+.27, -1.25), [(0, 0), (.12, .02), (.13, .05)], 'Bronze')
    for x in (-1.4, 1.4):
        rod((x, F, -2.3), (x, F+.45, -2.3), .2, 'Cedar')
        cylinder_solid('Staff stool', (x, F+.225, -2.3), .2, .45)
    # Reward racks behind the counter, ladder, and the reward list above.
    rack = (0, -4.87, '+z')
    for i, x in enumerate((-3.07, 0, 3.07)): shelf_unit((x, -4.87, '-z'), 0, 3.0, F, 3.8, .5, 4, i*40)
    beam((3.2, F, -4.0), (3.0, F+3.85, -4.32), .06, .08, 'Cedar')
    beam((2.6, F, -4.0), (2.4, F+3.85, -4.32), .06, .08, 'Cedar')
    for k in range(1, 11):
        t = k/11
        beam((2.6-.2*t, F+3.85*t, -4.0-.32*t), (3.2-.2*t, F+3.85*t, -4.0-.32*t), .04, .04, 'Cedar')
    solid('Ladder', (2.9, F+1.9, -4.17), (.7, 3.8, .35))
    wbox(rack, 0, F+5.6, .05, 8.8, 2.1, .1, 'Timber')
    wbox(rack, 0, F+6.48, .12, 8.9, .18, .06, 'Bronze')
    for u in (-2.2, 2.2): wbox(rack, u, F+5.4, .11, .06, 1.7, .04, 'Cedar')
    tags(rack, -4.1, 4.1, F+4.85, 3, 18, .12, True)
    coin((0, F+6.95, -4.76), .3, '+z')
    # Display cabinets flanking the door inside, and two treasure plinths on the aisle.
    for s in (-1, 1): shelf_unit((s*3.35, 4.87, '+z'), 0, 2.6, F, 2.2, .5, 3, 7+s, 'Window')
    for s in (-1, 1):
        x, z = s*1.95, 2.6
        box((x, F+.42, z), (.7, .84, .7), 'Stone')
        box((x, F+.87, z), (.8, .06, .8), 'Coping')
        solid('Treasure plinth', (x, F+.45, z), (.8, .9, .8))
        if s > 0:   # a reward sword on its stand
            for e in (-1, 1): box((x+e*.25, F+1.05, z), (.06, .3, .3), 'Timber')
            beam((x-.33, F+1.2, z), (x+.33, F+1.2, z), .05, .02, 'Bronze')
            beam((x+.33, F+1.2, z), (x+.48, F+1.2, z), .04, .04, 'Cedar')
        else:       # a cluster of spirit stones
            for dx, dz, h in ((0, 0, .5), (.15, .1, .32), (-.14, .08, .28), (.05, -.15, .24)):
                crystal((x+dx, F+.9, z+dz), .1, h, .06, 'SpiritHerb')
    # Storeroom wings with verandas (east: supplies; west: manuals and treasures).
    for s in (-1, 1):
        cx = s*8.5
        wf = (cx, 3.0, '+z')
        wall(wf, -3.5, 3.5, F, T2)
        for u in (-1.25, 1.25): window(wf, u, F+2.0, 1.3, 1.4)
        wbox(wf, 0, (T2+.2+5.25)/2, 0, 7.0, 5.25-T2-.2, .2, 'Plaster')
        wb = (cx, -3.6, '-z')
        wall(wb, -3.5, 3.5, F, T2)
        window(wb, 0, F+2.5, 1.2, .8)
        wo = (s*12, -.3, '+x' if s > 0 else '-x')
        wall(wo, -3.3, 3.3, F, T2)
        window(wo, 0, F+2.1, 1.4, 1.2)
        for x, z in ((s*12, 3.0), (s*12, -3.6), (cx, 3.0), (cx, -3.6)): box((x, (F+T2)/2, z), (.3, T2-F, .32), 'Timber')
        for z in (3.0, -3.6): box((cx+s*.15, T2+.1, z), (7.3, .2, .36), 'Timber')
        box((s*12, T2+.1, -.3), (.36, .2, 6.9), 'Timber')
        box((cx, T2+.02, -.3), (6.75, .06, 6.4), 'Timber', 'Wing ceiling')
        box((cx, F+.01, -.3), (6.75, .02, 6.4), 'Floor')
        for x in (s*7.4, s*9.7, s*12.0):
            column(x, 4.6, F, 4.35, .18)
            box((x, 4.2, 3.8), (.18, .2, 1.6), 'Cedar')
            bracket(x, 3.95, 4.6, .45)
        box((s*8.6, 4.45, 4.6), (7.1, .28, .28), 'Timber')
        P = gable(s*8.95, .2, 7.9, 10.4, 4.7, 2.4, 'x')
        outer_verge(P, 10.4, s*3.95, 'x')
        gable_end(P, 'x', s*3.05, -3.8, 4.4, T2+.15)
        coin((s*12.14, 5.7, .2), .5, '+x' if s > 0 else '-x')
        lantern(cx, T2-.45, -.3, T2)
    # East storeroom: supplies.
    for x, n in ((5.9, 2), (8.5, 2), (11.1, 1)):
        for k in range(n): crate(x, F+k*1.0, 2.3)
        solid('Crates', (x, F+n/2, 2.3), (1.0, n, 1.0))
    for x, z in ((7.2, 1.25), (7.8, 1.1), (10.0, 1.3)): sack(x, F, z)
    solid('Sacks', (8.6, F+.35, 1.2), (3.4, .7, .8))
    for z in (-.8, .3): barrel(11.3, F, z)
    wbox((8.5, -3.6, '-z'), 0, F+1.3, -.2, 3.2, .08, .1, 'Timber')
    for i in range(7):
        x = 10.0-i*.5
        rod((x, F+.05, -3.32), (x, F+2.3, -3.32), .03, 'Timber', 4)
        crystal((x, F+2.3, -3.32), .04, .2, .02, 'Bronze', 4)
    box((8.5, F+.1, -3.32), (3.4, .2, .25), 'Timber')
    solid('Spear rack', (8.5, F+1.2, -3.33), (3.4, 2.4, .3))
    # West storeroom: manuals, treasure chests, jade cabinet.
    for u in (-1.6, 1.0):
        shelf_unit((-8.5, -3.6+.12, '-z'), u, 2.0, F, 2.4, .42, 4, 20)
    for x in (-6.2, -8.4):
        box((x, F+.32, 2.3), (.95, .64, .62), 'Cedar')
        box((x, F+.68, 2.3), (.97, .08, .64), 'Timber')
        for dx in (-.32, .32): box((x+dx, F+.35, 2.3), (.06, .72, .66), 'Bronze')
        box((x, F+.5, 2.62), (.14, .16, .04), 'Bronze')
        solid('Treasure chest', (x, F+.36, 2.3), (.97, .72, .64))
    shelf_unit((-12+.12, -.3, '-x'), 0, 1.6, F, 2.0, .44, 3, 3, 'Window')
    # Veranda life: supplies waiting on the east, a bench on the west.
    for z in (3.8, 4.1): sack(11.3, F, z)
    crate(10.7, F, 3.9, .7)
    solid('Veranda supplies', (11.1, F+.35, 3.95), (1.3, .7, .9))
    box((-10.6, F+.45, 3.7), (2.0, .06, .4), 'Cedar')
    for dx in (-.85, .85): box((-10.6+dx, F+.22, 3.7), (.08, .44, .34), 'Timber')
    solid('Bench', (-10.6, F+.24, 3.7), (2.0, .48, .4))

exchange_hall()

# ---------------------------------------------------------------- meshes, export, scenes
NAMES = {'exchange_hall': ('Contribution / Exchange Hall', 'ExchangeHall')}
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
bpy.ops.wm.save_as_mainfile(filepath=str(STAGE/'source/claude_exchange_hall.blend'))

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

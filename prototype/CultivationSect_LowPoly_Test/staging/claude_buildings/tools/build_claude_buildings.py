"""Claude staging buildings, Split-Cloud low-poly style.

Run: blender --background --factory-startup --python this_file

Disciples' Residence, Elder Residence, Dining Hall and Kitchen, Spirit Herb
Garden. Same conventions as tools/build_split_cloud.py: Godot axes (X across,
Y up, +Z front), metres, origin on the ground under the asset centre, flat
opaque palette materials, geometry batched by material. No world placement.
Writes only inside staging/claude_buildings/.
"""
from pathlib import Path
import math, json
import bpy, bmesh
from mathutils import Vector

STAGE = Path(__file__).resolve().parents[1]
RES = 'res://staging/claude_buildings/'
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1

# Approved Split-Cloud palette (reports/LOW_POLY_STYLE_GUIDE.md) plus four
# garden-only colours. Roughness .82 everywhere except bronze/water.
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

def beam(a, b, w, d, mat):
    a, b, u, v = frame(a, b)
    verts = [p+u*x*w/2+v*y*d/2 for p in (a, b) for x, y in [(-1,-1),(1,-1),(1,1),(-1,1)]]
    geo(mat, verts, CUBE_FACES)

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

# Wall frames: o=(cx, cz, facing). u runs along the wall, n points outward.
FACING = {'+z': (1,0,0,1), '-z': (-1,0,0,-1), '+x': (0,-1,1,0), '-x': (0,1,-1,0)}
def at(o, u, y, n):
    a, b, c, d = FACING[o[2]]
    return (o[0]+a*u+c*n, y, o[1]+b*u+d*n)

def wbox(o, u, y, n, su, sy, sn, mat, solid_name=None):
    box(at(o, u, y, n), (su, sy, sn) if FACING[o[2]][0] else (sn, sy, su), mat, solid_name)

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
        solids[B].append({'name': name, 'type': 'box', 'position': list(at(o, m, (floor+top)/2, 0)),
                          'size': [b-a, top-floor, t+.06] if FACING[o[2]][0] else [t+.06, top-floor, b-a]})
    for a, b, h in cuts:
        m = (a+b)/2
        if top-floor-h > .02:
            wbox(o, m, (floor+h+top)/2, 0, b-a, top-floor-h, t, 'Plaster', name+' lintel')
        for x in (a-.08, b+.08):
            wbox(o, x, floor+(h+.1)/2, 0, .16, h+.1, t+.1, 'Timber')
        wbox(o, m, floor+h+.09, 0, b-a+.36, .18, t+.12, 'Timber')
        wbox(o, m, floor+.015, 0, b-a, .03, t, 'Stone')

def window(o, u, y, w, h, t=.24):
    # Opaque shaded recess both faces; coarse cedar grid and the bronze
    # diamond cloud motif repeated from the Hall screens.
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

def leaves(o, u, w, h, floor, t=.24):
    # Door leaves stand open against the inside wall; the doorway stays clear.
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
        box((cx+dx*d, h/2, cz+dz*d), (tread, h, width) if dx else (width, h, tread), 'Stone')
        box((cx+dx*e, h-.02, cz+dz*e), (.1, .05, width+.04) if dx else (width+.04, .05, .1), 'Coping')
    L, pts = n*tread, []
    for w in (-width/2, width/2):
        ox, oz = (0, w) if dx else (w, 0)
        pts += [[cx+ox, height, cz+oz], [cx+ox, 0, cz+oz], [cx+ox+dx*L, 0, cz+oz+dz*L]]
    solids[B].append({'name': 'Stair ramp', 'type': 'convex', 'points': pts})

def column(x, z, y0, y1, r=.17):
    box((x, y0+.09, z), (r*2.8, .18, r*2.8), 'Coping')
    rod((x, y0+.18, z), (x, y1, z), r, 'Timber')
    solid('Column', (x, (y0+y1)/2, z), (2*r, y1-y0, 2*r))

def bracket(x, y, z, scale=1):
    # Hall bracket: alternating timber bearing arms make the eave visibly supported.
    for i in range(3):
        w = (.70+i*.40)*scale
        box((x, y+i*.18, z), (w, .14*scale, .28*scale), 'Cedar')
        box((x, y+i*.18+.09, z), (.25*scale, .14*scale, w), 'Timber')
    for s in (-1, 1):
        beam((x, y-.62*scale, z), (x+s*.75*scale, y+.05, z), .17*scale, .22*scale, 'Cedar')

def lantern(x, y, z, top):
    rod((x, y+.25, z), (x, top, z), .02, 'Timber', 4)
    rod((x, y-.22, z), (x, y+.22, z), .17, 'Lantern')
    for dy in (-.24, .24): rod((x, y+dy-.03, z), (x, y+dy+.03, z), .19, 'Cedar')

def roof(cx, cz, w, d, eave, rise, lift=.34, iw=None, idp=0):
    """Hip roof from tools/build_split_cloud.py (collision export removed)."""
    iw = w*.56 if iw is None else iw
    def pt(side, s, t):
        hw = w/2+(iw-w)*t/2
        hd = d/2+(idp-d)*t/2
        if side == 0: x, z = (2*s-1)*hw, hd
        elif side == 1: x, z = hw, (1-2*s)*hd
        elif side == 2: x, z = (1-2*s)*hw, -hd
        else: x, z = -hw, (2*s-1)*hd
        y = eave+rise*t**1.55+lift*(1-t)**7+.32*abs(2*s-1)**6*(1-t)**2
        return Vector((cx+x, y, cz+z))
    for side in range(4):
        across = 12 if side % 2 == 0 else 8
        steps = 6
        top = [pt(side, i/across, j/steps) for j in range(steps+1) for i in range(across+1)]
        faces = []
        for j in range(steps):
            for i in range(across):
                a = j*(across+1)+i
                f = [a, a+1, a+across+2, a+across+1]
                n = (top[f[1]]-top[f[0]]).cross(top[f[2]]-top[f[0]])
                if n.length < 1e-7:
                    f = [a, a+1, a+across+1]
                    n = (top[f[1]]-top[f[0]]).cross(top[f[2]]-top[f[0]])
                if n.length < 1e-7: continue
                if n.y < 0: f.reverse()
                faces.append(f)
        geo('Jade', top, faces)
        bottom = [p-Vector((0, .20, 0)) for p in top]
        geo('Timber', bottom, [tuple(reversed(f)) for f in faces])
        for i in range(across):
            geo('Cedar', [top[i], top[i+1], bottom[i+1], bottom[i]], [(0,1,2,3)])
        if idp:
            off = steps*(across+1)
            for i in range(across): geo('Timber', [top[off+i], bottom[off+i], bottom[off+i+1], top[off+i+1]], [(0,1,2,3)])
        count = round((w if side % 2 == 0 else d)/.80)
        for i in range(1, count):
            for j in range(steps):
                a, b = pt(side, i/count, j/steps), pt(side, i/count, (j+1)/steps)
                if (b-a).length > .01: beam(a+Vector((0,.025,0)), b+Vector((0,.025,0)), .042, .045, 'TileLight')
            a, b = pt(side, i/count, 0), pt(side, i/count, .17)
            beam(a-Vector((0,.24,0)), b-Vector((0,.24,0)), .095, .11, 'Cedar')
        for j in range(steps):
            a, b = pt(side, 0, j/steps), pt(side, 0, (j+1)/steps)
            if (b-a).length > .01: beam(a+Vector((0,.06,0)), b+Vector((0,.06,0)), .16, .15, 'TileLight')
        for j in range(2):
            beam(pt(side, 0, j/12)+Vector((0,.11,0)), pt(side, 0, (j+1)/12)+Vector((0,.11,0)), .075, .07, 'Bronze')
    if idp == 0:
        y = eave+rise+.08
        beam((cx-iw/2, y, cz), (cx+iw/2, y, cz), .22, .20, 'TileLight')
        for sign in (-1, 1):
            pts = [(cx+sign*(iw/2-.2), y, cz), (cx+sign*(iw/2+.20), y+.18, cz), (cx+sign*(iw/2+.48), y+.46, cz)]
            for a, b in zip(pts, pts[1:]): beam(a, b, .16, .17, 'Bronze')

def gable(cx, cz, w, d, eave, rise, axis='x', curve=1.35, steps=5):
    """Two swept slopes; ridge along axis. w = ridge length, d = span. Returns P(u, v, dy)."""
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
        for u in (-w/2, w/2):
            for j in range(steps):
                beam(P(u, side*d/2*(1-j/steps), .06), P(u, side*d/2*(1-(j+1)/steps), .06), .16, .15, 'TileLight')
    beam(P(-w/2, 0, .08), P(w/2, 0, .08), .24, .22, 'TileLight')
    for u in (-w/2, w/2):
        s = 1 if u > 0 else -1
        a = P(u, 0, .08)
        beam(a, a+(Vector((s*.35, .32, 0)) if axis == 'x' else Vector((0, .32, s*.35))), .14, .15, 'Bronze')
    return P, axis

def gable_end(roofP, u, v0, v1, ybase):
    """Plastered, timber-framed gable infill under a gable() roof at ridge position u."""
    P, axis = roofP
    pts = [Vector((p.x, ybase, p.z)) for p in (P(u, v0), P(u, v1))]+[P(u, v1, -.21), P(u, 0, -.21), P(u, v0, -.21)]
    geo('Plaster', pts, [(0, 1, 2, 3, 4)])
    beam(pts[0], pts[1], .2, .2, 'Timber')
    mid = (pts[0]+pts[1])/2
    beam(mid, pts[3], .16, .16, 'Timber')
    s = 1 if u > 0 else -1
    off = Vector((s*.1, 0, 0)) if axis == 'x' else Vector((0, 0, s*.1))
    ring(tuple(mid.lerp(pts[3], .45)+off), .32, .05, 'Bronze', 8, 'x' if axis == 'x' else 'z')

def plaque(text, p, w, h, pixel):
    box(p, (w, h, .08), 'Timber')
    for y in (-h/2, h/2): box((p[0], p[1]+y, p[2]+.05), (w+.04, .04, .04), 'Bronze')
    for x in (-w/2, w/2): box((p[0]+x, p[1], p[2]+.05), (.04, h+.04, .04), 'Bronze')
    labels[B].append({'text': text, 'position': [p[0], p[1], p[2]+.06], 'pixel_size': pixel})

# ---------------------------------------------------------------- interiors
def bed(x, y, z, w=1.0, l=1.9):
    box((x, y+.2, z), (w, .4, l), 'Timber', 'Bed')
    box((x, y+.45, z), (w-.1, .1, l-.1), 'Fabric')
    box((x, y+.53, z-l/2+.25), (w-.4, .08, .28), 'Plaster')

def table(x, y, z, w, d, h, name='Table'):
    box((x, y+h-.03, z), (w, .06, d), 'Cedar')
    for a in (-w/2+.08, w/2-.08):
        for b in (-d/2+.08, d/2-.08): box((x+a, y+(h-.06)/2, z+b), (.08, h-.06, .08), 'Timber')
    solid(name, (x, y+h/2, z), (w, h, d))

def bench(x, y, z, l):
    box((x, y+.42, z), (l, .06, .32), 'Cedar')
    for a in (-l/2+.15, l/2-.15): box((x+a, y+.2, z), (.08, .4, .26), 'Timber')
    solid('Bench', (x, y+.225, z), (l, .45, .32))

# ================================================================ 1. Disciples' Residence
def disciple_residence():
    begin('disciple_residence')
    F, T = .5, 3.9
    box((0, .22, .2), (19.6, .44, 9.0), 'Stone', 'Podium')
    box((0, .47, .2), (19.8, .06, 9.2), 'Coping', 'Podium cap')
    box((0, F+.01, -.8), (17.5, .02, 5.5), 'Floor')
    stairs(0, 4.8, 5.8, F, 3, .32)
    bays = (-6.6, -2.2, 2.2, 6.6)
    front = (0, 2.0, '+z')
    wall(front, -8.8, 8.8, F, T, [(b, 1.3, 2.45) for b in bays])
    for b in bays:
        leaves(front, b, 1.3, 2.45, F)
        for s in (-1, 1): window(front, b+s*1.45, F+1.75, .9, 1.2)
    back = (0, -3.6, '-z')
    wall(back, -8.8, 8.8, F, T)
    for b in bays: window(back, b, F+2.0, 1.6, .9)
    for o in ((8.8, -.8, '+x'), (-8.8, -.8, '-x')):
        wall(o, -2.8, 2.8, F, T)
        window(o, 0, F+1.8, 1.4, 1.1)
    # Frieze closes the high front gap under the veranda roof.
    wbox(front, 0, (T+.2+5.05)/2, 0, 17.6, 5.05-T-.2, .2, 'Plaster')
    for x in (-4.4, 0, 4.4): box((x, (F+T)/2, -.8), (.16, T-F, 5.4), 'Plaster', 'Partition')
    for x in (-8.8, -4.4, 0, 4.4, 8.8):
        for z in (2.0, -3.6): box((x, (F+T)/2, z), (.3, T-F, .34), 'Timber')
        box((x, (T+.2+5.05)/2, 2.0), (.24, 5.05-T-.2, .26), 'Timber')
    for x in (-8.8, 8.8): box((x, (F+T)/2, -.8), (.34, T-F, .3), 'Timber')
    for z in (2.0, -3.6):
        box((0, T+.1, z), (17.9, .2, .36), 'Timber')
        box((0, T-.15, z), (17.6, .12, .3), 'Cedar')
    for x in (-8.8, 8.8): box((x, T+.1, -.8), (.36, .2, 5.9), 'Timber')
    box((0, T+.02, -.8), (17.4, .06, 5.4), 'Timber', 'Ceiling')
    for x in (-8.8, -4.4, 0, 4.4, 8.8):
        column(x, 3.85, F, T+.05, .16)
        box((x, T-.02, 2.92), (.18, .22, 1.8), 'Cedar')
        bracket(x, T-.42, 3.85, .45)
    box((0, T+.12, 3.85), (18.2, .3, .3), 'Timber')
    box((0, T-.12, 3.85), (17.6, .14, .24), 'Cedar')
    for b in bays: lantern(b, T-.35, 3.05, T+.4)
    roof_p = gable(0, .2, 20.6, 10.6, 3.95, 2.55)
    for u in (-8.8, 8.8): gable_end(roof_p, u, -3.8, 3.65, T+.15)
    # Each room: two sleeping platforms, a low study table, two cushions.
    for b in bays:
        for s in (-1, 1): bed(b+s*1.1, F, -2.55)
        table(b, F, -.3, 1.0, .6, .4)
        for s in (-1, 1): box((b+s*.75, F+.05, -.3), (.45, .1, .45), 'Fabric')

# ================================================================ 2. Elder Residence
def elder_residence():
    begin('elder_residence')
    # Compound wall with tiled coping and a roofed gate.
    def cwall(o, u0, u1):
        wall(o, u0, u1, 0, 2.2, t=.4, dado=.6, name='Compound wall')
        m = (u0+u1)/2
        wbox(o, m, 2.28, 0, u1-u0+.1, .16, .64, 'Jade')
        wbox(o, m, 2.4, 0, u1-u0+.1, .1, .16, 'TileLight')
    cwall((0, 10.2, '+z'), -11.2, -1.4)
    cwall((0, 10.2, '+z'), 1.4, 11.2)
    cwall((0, -10.4, '-z'), -11.2, 11.2)
    for o in ((11.0, -.1, '+x'), (-11.0, -.1, '-x')): cwall(o, -10.3, 10.3)
    for x in (-1.6, 1.6):
        box((x, .25, 10.2), (.62, .5, .62), 'Stone')
        rod((x, .5, 10.2), (x, 3.2, 10.2), .2, 'Timber')
        solid('Gate post', (x, 1.6, 10.2), (.62, 3.2, .62))
    box((0, 3.05, 10.2), (3.9, .3, .36), 'Timber')
    box((0, 2.68, 10.2), (3.2, .16, .28), 'Cedar')
    plaque('ELDER RESIDENCE', (0, 2.92, 10.42), 2.5, .38, .0034)
    roof(0, 10.2, 4.8, 2.6, 3.4, 1.05, .22, 2.2)
    # Main house on a raised podium.
    F, T = 1.0, 4.6
    box((0, .46, -5.1), (16, .92, 9), 'Stone', 'Podium')
    box((0, .96, -5.1), (16.2, .08, 9.2), 'Coping', 'Podium cap')
    box((0, F+.01, -5.4), (11.7, .02, 5.7), 'Floor')
    stairs(0, -.5, 4.2, F, 6, .3)
    for s in (-1, 1):
        beam((s*2.27, 1.12, -.55), (s*2.27, .2, 1.3), .3, .3, 'Stone')
        for a, b in ((2.4, 8.0),):
            for x in [a+i*(b-a)/4 for i in range(5)]: box((s*x, F+.32, -.68), (.24, .64, .24), 'Stone')
            box((s*(a+b)/2, F+.66, -.68), (b-a+.2, .08, .2), 'Coping', 'Rail')
    front = (0, -2.4, '+z')
    wall(front, -6, 6, F, T, [(0, 2.2, 2.9)])
    leaves(front, 0, 2.2, 2.9, F)
    for s in (-1, 1): window(front, s*3.6, F+1.85, 2.4, 1.9)
    wbox(front, 0, (T+.2+5.35)/2, 0, 12, 5.35-T-.2, .2, 'Plaster')
    back = (0, -8.4, '-z')
    wall(back, -6, 6, F, T)
    for s in (-1, 1): window(back, s*3, F+2.0, 2.0, 1.4)
    for o in ((6, -5.4, '+x'), (-6, -5.4, '-x')):
        wall(o, -3, 3, F, T)
        window(o, 0, F+1.9, 2.4, 1.6)
    for x, z in ((-6, -2.4), (6, -2.4), (-6, -8.4), (6, -8.4), (0, -8.4), (-6, -5.4), (6, -5.4)):
        box((x, (F+T)/2, z), (.32, T-F, .32), 'Timber')
    for z in (-2.4, -8.4):
        box((0, T+.1, z), (12.3, .2, .36), 'Timber')
        box((0, T-.15, z), (12, .12, .3), 'Cedar')
    for x in (-6, 6): box((x, T+.1, -5.4), (.36, .2, 6.3), 'Timber')
    box((0, T+.02, -5.4), (11.8, .06, 5.8), 'Timber', 'Ceiling')
    for x in (-6, -2.0, 2.0, 6):
        column(x, -1.15, F, T+.05, .19)
        box((x, T-.02, -1.78), (.2, .22, 1.26), 'Cedar')
        bracket(x, T-.42, -1.15, .55)
    box((0, T+.12, -1.15), (12.6, .32, .32), 'Timber')
    for x in (-4, 4): lantern(x, T-.4, -1.75, T+.5)
    roof(0, -4.9, 15.0, 10.0, 4.75, 2.7, .34, 5.0)
    # Interior: meditation dais before a mountain screen, canopy bed, scroll shelf, tea table.
    box((0, F+.15, -7.3), (3.0, .3, 1.6), 'Cedar', 'Dais')
    rod((0, F+.3, -7.3), (0, F+.42, -7.3), .42, 'Fabric')
    box((0, F+1.5, -8.15), (3.4, 2.6, .12), 'Timber')
    box((0, F+1.55, -8.07), (3.0, 2.2, .04), 'Fabric')
    ring((0, F+1.55, -8.03), 1.0, .06, 'Bronze', 16)
    pts = [(-.8, F+1.05), (-.32, F+2.0), (0, F+1.45), (.32, F+2.0), (.8, F+1.05)]
    for a, b in zip(pts, pts[1:]): beam((a[0], a[1], -8.02), (b[0], b[1], -8.02), .08, .06, 'Bronze')
    table(0, F, -5.9, .8, .5, .3, 'Incense table')
    rod((0, F+.3, -5.9), (0, F+.5, -5.9), .14, 'Bronze')
    x, z = -4.4, -5.6
    box((x, F+.22, z), (1.7, .44, 2.3), 'Timber', 'Canopy bed')
    box((x, F+.5, z), (1.55, .12, 2.15), 'Fabric')
    for a in (-.8, .8):
        for b in (-1.1, 1.1): box((x+a, F+1.3, z+b), (.1, 2.2, .1), 'Timber')
    box((x, F+2.42, z), (1.8, .08, 2.4), 'Fabric')
    box((x, F+1.1, z-1.12), (1.6, 1.2, .06), 'Cedar')
    x, z = 5.55, -5.4
    box((x+.25, F+1.1, z), (.05, 2.2, 2.6), 'Timber')
    for b in (-1.28, 1.28): box((x, F+1.1, z+b), (.5, 2.2, .06), 'Timber')
    for y in (F+.05, F+.6, F+1.15, F+1.7, F+2.2):
        box((x, y, z), (.48, .05, 2.5), 'Cedar')
        if y < F+2:
            for k in range(6): rod((x-.2, y+.08, z-1.0+k*.4), (x+.2, y+.08, z-1.0+k*.4), .06, 'Plaster', 6)
    solid('Shelf', (x, F+1.1, z), (.5, 2.2, 2.6))
    table(3.2, F, -4.2, .9, .9, .5, 'Tea table')
    for s in (-1, 1):
        rod((3.2+s*.8, F, -4.2), (3.2+s*.8, F+.42, -4.2), .2, 'Cedar')
        cylinder_solid('Stool', (3.2+s*.8, F+.21, -4.2), .2, .42)
    # Courtyard: path, two potted pines, stone table.
    box((0, .02, 5.75), (2.2, .04, 8.9), 'Coping')
    for z in (3.0, 7.5):
        x = -6.5
        box((x, .3, z), (1.0, .6, 1.0), 'Stone', 'Planter')
        box((x, .62, z), (1.1, .06, 1.1), 'Coping')
        rod((x, .6, z), (x+.15, 2.1, z), .12, 'Timber', 6)
        for y, r, h in ((1.35, .95, .9), (1.9, .72, .8), (2.4, .45, .7)): cone((x+.15, y, z), r, h, 'Leaf', 6)
    x, z = 4.0, 7.4
    rod((x, 0, z), (x, .72, z), .45, 'Stone', 8)
    rod((x, .72, z), (x, .8, z), .7, 'Coping', 8)
    cylinder_solid('Stone table', (x, .4, z), .7, .8)
    for a in range(4):
        sx, sz = x+1.05*math.cos(a*math.pi/2+.4), z+1.05*math.sin(a*math.pi/2+.4)
        rod((sx, 0, sz), (sx, .45, sz), .22, 'Stone', 6)
        cylinder_solid('Stone stool', (sx, .225, sz), .22, .45)
    # East wing: attendant room facing the courtyard.
    F2, T2 = .31, 3.3
    box((8.75, .14, 4.0), (3.5, .28, 6.4), 'Stone', 'Wing podium')
    box((8.75, .29, 4.0), (3.6, .04, 6.5), 'Coping', 'Wing podium cap')
    stairs(6.95, 4.0, 1.8, F2, 2, .3, '-x')
    wo = (7.4, 4.0, '-x')
    wall(wo, -2.8, 2.8, F2, T2, [(0, 1.2, 2.3)])
    leaves(wo, 0, 1.2, 2.3, F2)
    for s in (-1, 1): window(wo, s*1.75, F2+1.6, .9, 1.0)
    wall((10.2, 4.0, '+x'), -2.8, 2.8, F2, T2)
    for o in ((8.8, 1.2, '-z'), (8.8, 6.8, '+z')):
        wall(o, -1.4, 1.4, F2, T2)
        window(o, 0, F2+1.7, 1.0, .9)
    for x in (7.4, 10.2):
        for z in (1.2, 6.8): box((x, (F2+T2)/2, z), (.3, T2-F2, .3), 'Timber')
        box((x, T2+.1, 4.0), (.34, .2, 5.9), 'Timber')
    box((8.8, T2+.02, 4.0), (2.6, .06, 5.4), 'Timber', 'Wing ceiling')
    wing = gable(8.8, 4.0, 7.0, 4.4, T2+.05, 1.5, 'z')
    for u in (-2.8, 2.8): gable_end(wing, u, -1.4, 1.4, T2+.15)
    bed(9.5, F2, 2.5)
    table(9.4, F2, 5.6, .9, .6, .7)

# ================================================================ 3. Dining Hall and Kitchen
def dining_hall_kitchen():
    begin('dining_hall_kitchen')
    F, T, TK = .6, 4.8, 4.0
    box((0, .27, .4), (22, .54, 12.8), 'Stone', 'Podium')
    box((0, .57, .4), (22.2, .06, 13.0), 'Coping', 'Podium cap')
    box((0, .27, -9.1), (13.2, .54, 6.2), 'Stone', 'Kitchen podium')
    box((0, .57, -9.1), (13.4, .06, 6.4), 'Coping', 'Kitchen podium cap')
    stairs(0, 6.9, 6.0, F, 4, .3)
    stairs(6.7, -8.2, 1.8, F, 3, .3, '+x')
    box((0, F+.01, -.2), (19.7, .02, 9.0), 'Floor')
    box((0, F+.01, -8.2), (11.0, .02, 6.6), 'Stone')
    # Dining hall walls.
    front = (0, 4.4, '+z')
    doors = [(0, 3.0, 3.3), (-6, 1.5, 2.6), (6, 1.5, 2.6)]
    wall(front, -10, 10, F, T, doors)
    for u, w, h in doors: leaves(front, u, w, h, F)
    for u in (-8.4, -3.6, 3.6, 8.4): window(front, u, F+2.0, 1.9, 1.8)
    wbox(front, 0, (T+.2+5.75)/2, 0, 20, 5.75-T-.2, .2, 'Plaster')
    plaque('DINING HALL', (0, 4.38, 6.14), 2.9, .56, .0055)
    back = (0, -4.8, '-z')
    wall(back, -10, 10, F, T, [(0, 1.6, 2.6)])
    for u in (-8.0, 8.0): window(back, u, F+2.0, 1.8, 1.6)
    for o in ((10, -.2, '+x'), (-10, -.2, '-x')):
        wall(o, -4.6, 4.6, F, T)
        for u in (-2.2, 2.2): window(o, u, F+2.0, 2.2, 1.8)
    for x in (-10, -7.15, -4.85, -2.15, 2.15, 4.85, 7.15, 10):
        box((x, (F+T)/2, 4.4), (.3, T-F, .34), 'Timber')
        box((x, (T+.2+5.75)/2, 4.4), (.24, 5.75-T-.2, .26), 'Timber')
    for x in (-10, -5.6, 5.6, 10): box((x, (F+T)/2, -4.8), (.3, T-F, .34), 'Timber')
    for z in (4.4, -4.8):
        box((0, T+.1, z), (20.3, .2, .36), 'Timber')
        box((0, T-.15, z), (20, .12, .3), 'Cedar')
    for x in (-10, 10): box((x, T+.1, -.2), (.36, .2, 9.5), 'Timber')
    box((0, T+.02, -.2), (19.8, .06, 9.0), 'Timber', 'Ceiling')
    for x in (-10, -4.2, -1.9, 1.9, 4.2, 10):
        column(x, 5.95, F, T+.05, .2)
        box((x, T-.02, 5.17), (.2, .22, 1.5), 'Cedar')
        bracket(x, T-.42, 5.95, .55)
    box((0, T+.12, 5.95), (20.6, .32, .32), 'Timber')
    for x in (-3.0, 3.0): lantern(x, T-.4, 5.2, T+.5)
    # Hip-and-gable roof: hip skirt, then a gable crown with plastered gables.
    roof(0, .45, 23, 13.6, 4.85, 1.6, .36, 16.6, 7.2)
    crown = gable(0, .45, 17.6, 8.6, 6.3, 2.5)
    for u in (-8.3, 8.3): gable_end(crown, u, -3.6, 3.6, 6.25)
    # Dining furniture: four long tables with benches, serving counters, lanterns.
    for x in (-5.0, 5.0):
        for z in (-1.6, 2.0):
            table(x, F, z, 6.0, .9, .8, 'Long table')
            for s in (-1, 1): bench(x, F, z+s*.78, 5.8)
            lantern(x, T-.7, z, T)
    for x in (-2.6, 2.6):
        box((x, F+.5, -4.05), (3.0, 1.0, .7), 'Cedar', 'Serving counter')
        box((x, F+1.03, -4.05), (3.1, .06, .8), 'Timber')
        for s in (-1, 1):
            rod((x+s*.8, F+1.06, -4.05), (x+s*.8, F+1.46, -4.05), .3, 'Cedar')
            rod((x+s*.8, F+1.46, -4.05), (x+s*.8, F+1.48, -4.05), .27, 'Plaster')
        for k in range(3): rod((x, F+1.06+k*.07, -4.05), (x, F+1.12+k*.07, -4.05), .16, 'Coping', 8)
    # Kitchen annex (T-plan), taller stone dado, chimney through the roof.
    for o, doors_k in (((-5.6, -8.2, '-x'), []), ((5.6, -8.2, '+x'), [(0, 1.4, 2.5)])):
        wall(o, -3.4, 3.4, F, TK, doors_k, dado=1.1)
    leaves((5.6, -8.2, '+x'), 0, 1.4, 2.5, F)
    for u in (-1.6, 1.6): window((-5.6, -8.2, '-x'), u, F+2.1, 1.3, 1.1)
    window((5.6, -8.2, '+x'), 2.3, F+2.1, 1.2, 1.0)
    kb = (0, -11.6, '-z')
    wall(kb, -5.6, 5.6, F, TK, dado=1.1)
    window(kb, -2.5, F+2.3, 1.4, 1.0)
    for x in (-5.6, 5.6):
        box((x, (F+TK)/2, -11.6), (.3, TK-F, .34), 'Timber')
        box((x, TK+.1, -8.2), (.36, .2, 7.1), 'Timber')
    box((0, TK+.1, -11.6), (11.5, .2, .36), 'Timber')
    box((0, TK+.02, -8.2), (11.0, .06, 6.6), 'Timber', 'Kitchen ceiling')
    k = gable(0, -8.725, 7.75, 12.8, TK+.05, 2.2, 'z')
    for u in (-2.875, 3.875): gable_end(k, u, -5.6, 5.6, TK+.15)
    box((-4.6, 4.4, -10.9), (1.1, 7.6, 1.1), 'Stone', 'Chimney')
    box((-4.6, 8.3, -10.9), (1.4, .2, 1.4), 'Coping')
    box((-4.6, 8.45, -10.9), (.6, .1, .6), 'Timber')
    # Stove range with three woks and glowing fire mouths.
    # Whitewashed clay range on a stone plinth, so it reads against the flagstone floor.
    box((-1.6, F+.5, -10.85), (5.8, .8, 1.3), 'Plaster', 'Stove')
    box((-1.6, F+.06, -10.85), (5.9, .12, 1.36), 'Stone')
    box((-1.6, F+.92, -10.85), (5.9, .06, 1.4), 'Coping')
    for x in (-3.0, -1.2, .6):
        rod((x, F+.95, -10.8), (x, F+.99, -10.8), .42, 'Timber', 10)
        ring((x, F+.98, -10.8), .44, .05, 'Bronze', 10, 'y')
        box((x, F+.3, -10.18), (.5, .35, .06), 'Lantern')
    for x in (3.0, 4.2):
        rod((x, F, -10.9), (x, F+.9, -10.9), .42, 'Cedar')
        for y in (.2, .7): ring((x, F+y, -10.9), .43, .04, 'Bronze', 8, 'y')
        rod((x, F+.86, -10.9), (x, F+.88, -10.9), .38, 'Water')
        cylinder_solid('Water vat', (x, F+.45, -10.9), .42, .9)
    table(-2.6, F, -7.6, 2.4, 1.0, .85, 'Prep table')
    rod((-2.0, F+.85, -7.6), (-2.0, F+1.05, -7.6), .25, 'Cedar')
    x, z = -5.25, -8.2
    box((x-.18, F+1.2, z), (.05, 2.0, 1.4), 'Timber')
    for y in (F+.4, F+1.0, F+1.6, F+2.15):
        box((x, y, z), (.36, .05, 1.4), 'Cedar')
        if y < F+2:
            for kk in range(4): rod((x, y+.03, z-.5+kk*.33), (x, y+.3, z-.5+kk*.33), .1, 'Coping', 6)
    solid('Kitchen shelf', (x, F+1.1, z), (.4, 2.2, 1.4))
    # Outside the service door: firewood stack and a covered well.
    for row, y in enumerate((.12, .34, .56)):
        for kk in range(5-row): rod((6.9, y, -11.6+kk*.25+row*.12), (8.3, y, -11.6+kk*.25+row*.12), .12, 'Cedar', 6)
    solid('Firewood', (7.6, .34, -11.1), (1.4, .68, 1.3))
    wx, wz = 9.6, -10.4
    rod((wx, 0, wz), (wx, .8, wz), .8, 'Stone', 8)
    ring((wx, .82, wz), .78, .14, 'Coping', 8, 'y')
    rod((wx, .78, wz), (wx, .8, wz), .64, 'Water', 8)
    cylinder_solid('Well', (wx, .4, wz), .8, .8)
    for s in (-1, 1): box((wx+s*.75, 1.55, wz), (.14, 1.5, .14), 'Timber')
    rod((wx-.75, 1.9, wz), (wx+.75, 1.9, wz), .08, 'Cedar', 6)
    rod((wx+.2, 1.1, wz), (wx+.2, 1.4, wz), .14, 'Cedar', 6)
    gable(wx, wz, 2.0, 1.3, 2.3, .45)

# ================================================================ 4. Spirit Herb Garden
def plant(x, y, z, kind, seed):
    j = (seed*37 % 11)/11
    if kind == 'grass':
        for k in range(3):
            a = k*math.tau/3+j
            cone((x+.1*math.cos(a), y, z+.1*math.sin(a)), .06, .5+.3*j, 'Leaf', 4)
    elif kind == 'herb':
        cone((x, y, z), .24, .3+.12*j, 'Leaf', 5, j)
        cone((x, y+.16, z), .15, .32, 'Leaf', 5, j+.5)
    else:
        cone((x, y, z), .17, .26, 'Leaf', 5, j)
        rod((x, y, z), (x, y+.5+.15*j, z), .025, 'Leaf', 4)
        crystal((x, y+.45+.15*j, z), .09, .16, .08, 'SpiritHerb' if kind == 'spirit' else 'Bronze')

def herb_bed(cx, cz, kind):
    box((cx, .2, cz), (7.0, .4, 2.0), 'Stone', 'Herb bed')
    box((cx, .41, cz), (6.7, .06, 1.7), 'Soil')
    for row in (-.45, .45):
        for i in range(8): plant(cx-2.8+i*.8, .44, cz+row, kind, i+int(cz*3)+int(cx))

def fence(a, b):
    (x0, z0), (x1, z1) = a, b
    L = math.hypot(x1-x0, z1-z0)
    along_x = abs(z1-z0) < 1e-6
    c = ((x0+x1)/2, (z0+z1)/2)
    size = lambda l, h, t: (l, h, t) if along_x else (t, h, l)
    box((c[0], .225, c[1]), size(L, .45, .4), 'Stone')
    box((c[0], .47, c[1]), size(L, .05, .46), 'Coping')
    for y in (.85, 1.35): box((c[0], y, c[1]), size(L, .08, .08), 'Cedar')
    n = max(1, round(L/2))
    for i in range(n+1):
        t = i/n
        box((x0+(x1-x0)*t, .975, z0+(z1-z0)*t), (.14, 1.05, .14), 'Timber')
    solid('Garden fence', (c[0], .75, c[1]), size(L, 1.5, .4))

def stone_lantern(x, z):
    box((x, .1, z), (.55, .2, .55), 'Stone')
    box((x, .6, z), (.24, .8, .24), 'Stone')
    box((x, 1.04, z), (.5, .08, .5), 'Coping')
    box((x, 1.28, z), (.34, .4, .34), 'Lantern')
    cone((x, 1.48, z), .42, .3, 'Stone', 4, math.pi/4)
    solid('Stone lantern', (x, .8, z), (.55, 1.6, .55))

def spirit_herb_garden():
    begin('spirit_herb_garden')
    fence((-12, 12), (-1.6, 12)); fence((1.6, 12), (12, 12))
    fence((-12, -12), (12, -12))
    fence((-12, -12), (-12, 12)); fence((12, -12), (12, 12))
    for x in (-1.8, 1.8):
        box((x, .25, 12), (.7, .5, .7), 'Stone')
        rod((x, .5, 12), (x, 3.3, 12), .2, 'Timber')
        solid('Gate pillar', (x, 1.65, 12), (.7, 3.3, .7))
    box((0, 3.15, 12), (4.6, .3, .34), 'Timber')
    box((0, 2.75, 12), (3.4, .16, .26), 'Cedar')
    plaque('SPIRIT HERB GARDEN', (0, 3.62, 12.12), 3.2, .5, .0042)
    gable(0, 12, 5.2, 1.8, 3.95, .65)
    # Paths and the paved formation plaza.
    box((0, .02, 8.2), (2, .04, 7.6), 'Coping')
    box((0, .02, -3.65), (2, .04, 1.3), 'Coping')
    for s in (-1, 1): box((s*7.6, .02, 0), (8.0, .04, 2), 'Coping')
    rod((0, 0, 0), (0, .03, 0), 4.6, 'Coping', 16)
    ring((0, .045, 0), 4.2, .08, 'Bronze', 24, 'y')
    for a in range(8):
        box((4.2*math.cos(a*math.pi/4), .05, 4.2*math.sin(a*math.pi/4)), (.32, .05, .32), 'Bronze')
    # Spirit spring with its jade crystal.
    rod((0, 0, 0), (0, .5, 0), 3.0, 'Stone', 8)
    rod((0, .5, 0), (0, .53, 0), 2.7, 'Water', 8)
    ring((0, .56, 0), 2.85, .3, 'Coping', 8, 'y')
    cylinder_solid('Spirit spring', (0, .3, 0), 3.0, .6)
    rod((0, .5, 0), (0, .85, 0), .5, 'Stone', 6)
    crystal((0, .85, 0), .38, 1.5, .4, 'SpiritHerb')
    # Raised beds: ordinary herbs, jade spirit herbs, golden pills, spirit grass.
    beds = {(-7.2, 4.6): 'herb', (-7.2, 8.6): 'spirit', (7.2, 4.6): 'golden', (7.2, 8.6): 'grass',
            (-7.2, -4.6): 'spirit', (-7.2, -8.6): 'herb', (7.2, -4.6): 'golden'}
    for (x, z), kind in beds.items(): herb_bed(x, z, kind)
    # Trellis over the front-left spirit bed.
    for a in (-3.3, 3.3):
        for b in (-1.1, 1.1): box((-7.2+a, 1.15, 8.6+b), (.12, 2.3, .12), 'Timber')
    for b in (-1.1, 1.1): box((-7.2, 2.32, 8.6+b), (6.9, .1, .1), 'Cedar')
    for i in range(10):
        x = -10.3+i*.69
        box((x, 2.42, 8.6), (.07, .07, 2.5), 'Cedar')
        box((x+.3, 2.5, 8.6+(.4 if i % 2 else -.4)), (.45, .1, 1.2), 'Leaf')
        cone((x+.2, 1.9, 8.6+(-.9 if i % 2 else .9)), .1, .5, 'Leaf', 4)
    # Herb-tending pavilion, near-pyramidal roof with a jade finial.
    box((0, .22, -8.0), (5.4, .44, 5.4), 'Stone', 'Pavilion podium')
    box((0, .47, -8.0), (5.6, .06, 5.6), 'Coping', 'Pavilion podium cap')
    stairs(0, -5.2, 2.4, .5, 3, .3)
    for x in (-2.2, 2.2):
        for z in (-10.2, -5.8): column(x, z, .5, 3.4, .16)
    for z in (-10.2, -5.8): box((0, 3.5, z), (4.8, .26, .26), 'Timber')
    for x in (-2.2, 2.2): box((x, 3.5, -8.0), (.26, .26, 4.8), 'Timber')
    box((0, 3.22, -5.8), (4.0, .1, .12), 'Cedar')
    for y in (.6, 1.0):
        box((0, y, -10.2), (4.2, .08, .1), 'Cedar')
        for x in (-2.2, 2.2): box((x, y, -8.0), (.1, .08, 4.2), 'Cedar')
    solid('Pavilion rail', (0, .75, -10.2), (4.2, .5, .12))
    for x in (-2.2, 2.2): solid('Pavilion rail', (x, .75, -8.0), (.12, .5, 4.2))
    box((0, .95, -9.6), (2.6, .08, .5), 'Cedar')
    for x in (-1.1, 1.1): box((x, .72, -9.6), (.1, .44, .4), 'Timber')
    solid('Pavilion bench', (0, .75, -9.6), (2.6, .5, .5))
    rod((0, .5, -8.0), (0, 1.15, -8.0), .42, 'Stone', 8)
    cylinder_solid('Mortar table', (0, .82, -8.0), .42, .65)
    rod((0, 1.15, -8.0), (0, 1.35, -8.0), .18, 'Bronze', 8)
    roof(0, -8.0, 6.6, 6.6, 3.6, 2.0, .3, .5)
    rod((0, 5.6, -8.0), (0, 5.9, -8.0), .08, 'Bronze', 6)
    crystal((0, 5.85, -8.0), .18, .5, .15, 'SpiritHerb')
    # Tool shed in the back-right corner.
    shed = gable(9.3, -9.9, 4.6, 3.6, 2.45, .9)
    for o, u0, u1 in (((9.3, -11.2, '-z'), -1.7, 1.7), ((11.0, -9.9, '+x'), -1.3, 1.3), ((7.6, -9.9, '-x'), -1.3, 1.3)):
        wall(o, u0, u1, 0, 2.4, t=.2, dado=.4, name='Shed wall')
    for x in (7.6, 11.0): box((x, 1.2, -8.6), (.2, 2.4, .2), 'Timber', 'Shed post')
    box((9.3, 2.35, -8.6), (3.6, .2, .2), 'Timber')
    for u in (-1.7, 1.7): gable_end(shed, u, -1.3, 1.3, 2.5)
    for y in (.9, 1.5):
        box((9.3, y, -10.9), (3.0, .06, .4), 'Cedar')
        for kk in range(5): rod((8.3+kk*.5, y+.03, -10.9), (8.3+kk*.5, y+.28, -10.9), .14, 'Stone', 6)
    solid('Shed shelf', (9.3, .8, -10.9), (3.0, 1.6, .4))
    for kk in range(3):
        beam((7.95+kk*.25, 0, -10.6), (8.05+kk*.25, 1.75, -10.95), .05, .05, 'Cedar')
        box((7.95+kk*.25, .1, -10.55), (.2, .05, .14), 'Timber')
    rod((10.3, 0, -9.3), (10.3, .35, -9.3), .22, 'Cedar')
    for x, z in ((-1.7, 6.6), (1.7, 6.6), (-1.7, -4.4), (1.7, -4.4)): stone_lantern(x, z)

disciple_residence()
elder_residence()
dining_hall_kitchen()
spirit_herb_garden()

# ---------------------------------------------------------------- meshes, export, scenes
NAMES = {
    'disciple_residence': ("Disciples' Residence", 'DisciplesResidence'),
    'elder_residence': ('Elder Residence', 'ElderResidence'),
    'dining_hall_kitchen': ('Dining Hall and Kitchen', 'DiningHallKitchen'),
    'spirit_herb_garden': ('Spirit Herb Garden', 'SpiritHerbGarden'),
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
bpy.ops.wm.save_as_mainfile(filepath=str(STAGE/'source/claude_buildings.blend'))

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
    # Generated scene: model + authored simple collision + editable plaque text.
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
print(json.dumps({k: (v['triangles'], v['size_xyz_m']) for k, v in summary.items()}))

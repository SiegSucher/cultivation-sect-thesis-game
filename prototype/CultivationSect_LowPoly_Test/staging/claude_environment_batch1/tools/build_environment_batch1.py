"""Claude staging: environment batch 1, eleven reusable Split-Cloud low-poly props.

Run: blender --background --factory-startup --python this_file

Palette/material setup and box/beam/rod/cone/crystal/lathe/ngon/prism/ring/emblem are
copied from staging/claude_exchange_hall/tools/build_exchange_hall.py (earlier
deliveries are frozen and must not be rerun). New here: faceted convex-hull blobs
(rocks, foliage), tapered tubes (trunks, culms), leaves and grass blades.
Godot axes (X across, Y up, +Z front), metres, origin on the ground under each asset.
No world placement. Writes only inside staging/claude_environment_batch1/.
"""
from pathlib import Path
import math, json, random
import bpy, bmesh
from mathutils import Vector

STAGE = Path(__file__).resolve().parents[1]
RES = 'res://staging/claude_environment_batch1/'
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
bpy.context.preferences.filepaths.save_version = 0   # no .blend1 backups in the delivery
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1

# Existing Split-Cloud palette entries plus nature tones chosen to sit beside the
# jade roofs (#22594f) and blue-grey masonry without competing with them.
PALETTE = {
    'Stone': '667e88', 'Coping': 'bcc6bd', 'Timber': '432d2d', 'Cedar': '896048',
    'Bronze': 'cda668', 'Fabric': '456e73', 'Lantern': 'ffda91', 'Soil': '5d4a3a', 'Leaf': '4d7d4f',
    'Bark': '6e5a48', 'PineNeedle': '35573f', 'PineLight': '5f8450', 'Bamboo': '6d8c4a',
    'BambooNode': 'a3ac6e', 'Blossom': 'b8868a', 'Grass': '5e7d43',
    'GrassLight': '8a9d5a', 'Rock': '646961', 'RockLight': '7d8177', 'Moss': '5d7a45', 'Straw': 'a58c5a',
}
EMISSIVE = {'Lantern': .45}
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
    if name in EMISSIVE:
        p.inputs['Emission Color'].default_value = (*linear, 1)
        p.inputs['Emission Strength'].default_value = EMISSIVE[name]
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
    if solid_name: convex_solid(solid_name, pts)

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
    """Revolve [(radius, height), ...] about a vertical axis at p."""
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
    if solid_name: convex_solid(solid_name, verts)

def emblem(c, r, z_face):
    """Split-Cloud mountain strokes in a bronze ring, in the x-y plane at z = c[2]."""
    ring(c, r, .07, 'Bronze', 12, 'z')
    pts = [(-.62*r, -.45*r), (-.22*r, .45*r), (0, .02*r), (.22*r, .45*r), (.62*r, -.45*r)]
    q = [(c[0]+a, c[1]+b, c[2]) for a, b in pts]
    for a, b in zip(q, q[1:]): beam(a, b, .08, .07, 'Bronze')

# ---------------------------------------------------------------- new helpers
def out(mat, pts, inside):
    """One polygon, wound so its normal points away from an interior point."""
    pts = [Vector(p) for p in pts]
    c = sum(pts, Vector())/len(pts)
    if (pts[1]-pts[0]).cross(pts[2]-pts[0]).dot(c-Vector(inside)) < 0: pts.reverse()
    geo(mat, [tuple(p) for p in pts], [tuple(range(len(pts)))])

def hull(points, tone, solid_name=None):
    """Faceted convex blob; tone(normal_y) picks each facet's material, so tops read
    lighter (moss, sunlit needles) without textures. Collision = the same hull."""
    bm = bmesh.new()
    for p in points: bm.verts.new(p)
    res = bmesh.ops.convex_hull(bm, input=list(bm.verts))
    junk = list({g for g in res['geom_interior']+res['geom_unused'] if isinstance(g, bmesh.types.BMVert)})
    if junk: bmesh.ops.delete(bm, geom=junk, context='VERTS')
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.normal_update()
    for f in bm.faces:
        geo(tone(f.normal.y), [tuple(v.co) for v in f.verts], [tuple(range(len(f.verts)))])
    if solid_name: convex_solid(solid_name, [tuple(v.co) for v in bm.verts])
    bm.free()

def blob(rng, c, r, n=14, jitter=.16, floor=None, ceil=None):
    """Jittered points on an ellipsoid (Fibonacci spread), optionally cut flat below/above."""
    pts = []
    for i in range(n):
        y = 1-2*(i+.5)/n
        rad = math.sqrt(max(0, 1-y*y))
        th = i*2.39996+rng.uniform(0, .5)
        k = 1+rng.uniform(-jitter, jitter)
        p = [c[0]+r[0]*rad*math.cos(th)*k, c[1]+r[1]*y*k, c[2]+r[2]*rad*math.sin(th)*k]
        if floor is not None: p[1] = max(p[1], floor)
        if ceil is not None: p[1] = min(p[1], ceil)
        pts.append(tuple(p))
    return pts

def tube(path, radii, mats, sides=6, caps=True):
    """Tapered tube through path points (parallel-transported frame, no twist).
    mats is one material or one per segment. Returns the rings."""
    path = [Vector(p) for p in path]
    n, rings, u = len(path), [], None
    for i, p in enumerate(path):
        t = (path[min(i+1, n-1)]-path[max(i-1, 0)]).normalized()
        if u is None: u = t.cross(Vector((0, 0, 1)) if abs(t.z) < .9 else Vector((1, 0, 0))).normalized()
        else: u = (u-t*u.dot(t)).normalized()
        v = t.cross(u)
        rings.append([p+radii[i]*(u*math.cos(k*math.tau/sides)+v*math.sin(k*math.tau/sides)) for k in range(sides)])
    for i in range(n-1):
        mat = mats if isinstance(mats, str) else mats[i]
        a, b = rings[i], rings[i+1]
        mid = (path[i]+path[i+1])/2
        for k in range(sides): out(mat, [a[k], a[(k+1) % sides], b[(k+1) % sides], b[k]], mid)
    if caps:
        last = mats if isinstance(mats, str) else mats[-1]
        out(last, rings[-1], path[-2])
        out(mats if isinstance(mats, str) else mats[0], rings[0], path[1])
    return rings

def leaf(a, d, L, w, mat):
    """Closed, flattened bipyramid leaf (visible from both sides without double-sided materials)."""
    a, d = Vector(a), Vector(d).normalized()
    s = d.cross(Vector((0, 1, 0)))
    if s.length < 1e-3: s = d.cross(Vector((1, 0, 0)))
    s.normalize()
    t = s.cross(d).normalized()
    tip, m = a+d*L, a+d*L*.38
    ring_pts = [m+s*w, m+t*w*.22, m-s*w, m-t*w*.22]
    for k in range(4):
        out(mat, [a, ring_pts[k], ring_pts[(k+1) % 4]], m)
        out(mat, [tip, ring_pts[(k+1) % 4], ring_pts[k]], m)

def blade(base, tip, w, mat, turn):
    """Three-sided grass blade; its open base sits just below the ground."""
    base, tip = Vector(base), Vector(tip)
    pts = [base+Vector((w*math.cos(turn+k*math.tau/3), 0, w*math.sin(turn+k*math.tau/3))) for k in range(3)]
    inside = base+(tip-base)*.25
    for k in range(3): out(mat, [pts[k], pts[(k+1) % 3], tip], inside)

def slab(p0, p1, y0, y1, t, mat):
    """Vertical panel of thickness t between xz points p0, p1 (cloth strips)."""
    a, b = Vector((p0[0], 0, p0[1])), Vector((p1[0], 0, p1[1]))
    n = (b-a).cross(Vector((0, 1, 0))).normalized()*t/2
    q = [a-n, b-n, b+n, a+n]
    lo = [Vector((p.x, y0, p.z)) for p in q]
    hi = [Vector((p.x, y1, p.z)) for p in q]
    c = sum(lo+hi, Vector())/8
    out(mat, lo, c); out(mat, hi, c)
    for k in range(4): out(mat, [lo[k], lo[(k+1) % 4], hi[(k+1) % 4], hi[k]], c)

def hip_cap(y, h, rise, lift, thick, mat):
    """Square hipped stone cap; corners sweep up by `lift` like the building eaves."""
    apex = (0, y+rise, 0)
    loop = []
    for k in range(4):
        sx, sz = (1, 1, -1, -1)[k], (1, -1, -1, 1)[k]
        loop += [(sx*h, y+lift, sz*h), (sx*h if k % 2 == 0 else 0, y, sz*h if k % 2 else 0)]
    loop = [loop[i] for i in range(8)]
    centre = (0, y, 0)
    for i in range(8): out(mat, [loop[i], loop[(i+1) % 8], apex], centre)
    low = [(p[0]*.93, p[1]-thick, p[2]*.93) for p in loop]
    for i in range(8): out(mat, [loop[i], loop[(i+1) % 8], low[(i+1) % 8], low[i]], centre)
    out(mat, low, (0, y+.2, 0))

def rock_tone(mossy):
    return lambda ny: 'Moss' if mossy and ny > .74 else 'RockLight' if ny > .3 else 'Rock'

pad_tone = lambda ny: 'PineLight' if ny > .42 else 'PineNeedle'
shrub_tone = lambda ny: 'Leaf' if ny > .55 else 'PineNeedle'   # same evergreen family as the pines

def pad(rng, c, rx, ry):
    """Cloud-pad of pine needles: one broad cushion, four satellites, softly flattened below."""
    ry *= 1.45
    for k in range(5):
        if k == 0: off, s = (0, 0, 0), 1.0
        else:
            a = k*math.tau/4+rng.uniform(-.4, .4)
            off, s = (math.cos(a)*rx*.58, rng.uniform(0, .35)*ry, math.sin(a)*rx*.58), rng.uniform(.5, .68)
        cc = (c[0]+off[0], c[1]+off[1], c[2]+off[2])
        hull(blob(rng, cc, (rx*s, ry*s, rx*s*rng.uniform(.8, 1.05)), 14, .14, floor=cc[1]-ry*s*.62), pad_tone)

def trunk_collision(rings, path, top):
    """Convex pieces hugging the trunk up to `top` (pairs of segments, so bends stay tight)."""
    idx = [i for i, p in enumerate(path) if p[1] <= top+.6]
    for i in range(0, len(idx)-1, 2):
        pts = [tuple(v) for j in idx[i:i+3] for v in rings[j]]
        convex_solid('Trunk', [(x, min(y, top), z) for x, y, z in pts])

def roots(rng, n, r0):
    for k in range(n):
        a = k*math.tau/n+rng.uniform(-.3, .3)
        tube([(0, .32, 0), (math.cos(a)*r0*.9, .1, math.sin(a)*r0*.9), (math.cos(a)*r0*1.6, -.06, math.sin(a)*r0*1.6)],
             [.13, .08, .03], 'Bark', 5)

# ================================================================ assets
def pine_windswept():
    """Guest-greeting pine: leaning trunk, one long low arm, flat cloud pads."""
    begin('pine_windswept')
    rng = random.Random(11)
    path = [(0, -.1, 0), (.08, .6, .05), (.3, 1.5, .1), (.55, 2.4, .05), (.45, 3.3, -.15), (.1, 4.2, -.1), (-.2, 5.0, .05), (-.25, 5.6, .1)]
    rings = tube(path, [.34, .3, .26, .23, .2, .16, .12, .08], 'Bark', 7)
    roots(rng, 4, .45)
    arms = [
        ([(.5, 2.75, .05), (1.3, 2.95, .25), (2.2, 2.85, .45), (3.1, 3.05, .5), (3.7, 3.15, .45)], [.15, .12, .1, .08, .06]),
        ([(.4, 3.5, -.1), (-.5, 3.85, -.5), (-1.5, 4.0, -.8), (-2.1, 4.25, -.9)], [.12, .1, .08, .06]),
        ([(.2, 4.1, -.12), (.6, 4.45, -.9), (.9, 4.7, -1.5)], [.1, .08, .06]),
        ([(-.05, 4.6, -.05), (.9, 5.0, .4), (1.5, 5.15, .6)], [.09, .07, .05]),
    ]
    for p, r in arms: tube(p, r, 'Bark', 5)
    for c, rx, ry in [((2.3, 3.3, .55), 1.0, .42), ((3.55, 3.45, .45), .85, .38), ((-1.95, 4.45, -.85), .95, .4),
                      ((-.9, 4.2, -.65), .6, .3), ((.95, 4.9, -1.5), .8, .36), ((1.55, 5.35, .6), .75, .34),
                      ((-.25, 5.9, .1), 1.05, .45), ((-.55, 6.3, -.15), .55, .3)]:
        pad(rng, c, rx, ry)
    trunk_collision(rings, path, 2.6)

def pine_tiered():
    """Upright mountain pine: tall straight trunk, alternating tiers of pads."""
    begin('pine_tiered')
    rng = random.Random(23)
    path = [(0, -.1, 0), (.05, 1.0, .03), (.12, 2.2, 0), (.02, 3.4, -.06), (-.1, 4.6, 0), (-.02, 5.8, .08), (.08, 7.0, .02), (0, 8.0, 0)]
    rings = tube(path, [.3, .26, .23, .2, .17, .14, .1, .06], 'Bark', 7)
    roots(rng, 4, .4)
    for y, deg, L in [(3.0, 20, 1.7), (3.25, 195, 1.45), (4.3, 110, 1.5), (4.55, 290, 1.3), (5.5, 35, 1.2),
                      (5.75, 235, 1.0), (6.6, 150, .9), (7.15, 320, .7)]:
        a = math.radians(deg)
        x0 = .03*math.sin(y)
        p = [(x0, y, 0), (math.cos(a)*L*.5, y+.05, math.sin(a)*L*.5), (math.cos(a)*L, y+.28, math.sin(a)*L)]
        tube(p, [.09*min(1, L), .06, .04], 'Bark', 5)
        pad(rng, (math.cos(a)*L, y+.42, math.sin(a)*L), .45+.32*L, .3+.06*L)
    pad(rng, (0, 8.15, 0), .75, .38)
    trunk_collision(rings, path, 2.6)

def bamboo_cluster():
    begin('bamboo_cluster')
    rng = random.Random(5)
    hull(blob(rng, (0, -.02, 0), (.95, .16, .85), 16, .12, floor=-.12), lambda ny: 'Soil' if ny < .9 else 'Moss')
    bases = []
    for k in range(9):
        rr, a = .58*math.sqrt((k+.5)/9), k*2.39996
        x, z = rr*math.cos(a), rr*math.sin(a)
        bases.append((x, z))
        h = rng.uniform(4.2, 7.2)
        r = rng.uniform(.042, .065)
        lean = Vector((x, 0, z)).normalized()*rng.uniform(.25, .6) if rr > .1 else Vector((.15, 0, .05))
        nodes = max(6, round(h/.55))
        path = [Vector((x, 0, z))+lean*(i/nodes)**2+Vector((0, h*i/nodes, 0)) for i in range(nodes+1)]
        tube(path, [r*(1-.35*i/nodes) for i in range(nodes+1)], 'Bamboo', 5)
        for i in range(1, nodes):   # short pale node bands between the green internodes
            rod(path[i]-Vector((0, .025, 0)), path[i]+Vector((0, .025, 0)), r*1.22*(1-.35*i/nodes), 'BambooNode', 5)
        for i in range(round(nodes*.45), nodes, 2):   # leaf sprays on the upper culm
            t = i/nodes
            node = Vector((x, 0, z))+lean*t*t+Vector((0, h*t, 0))
            a2 = rng.uniform(0, math.tau)
            d = Vector((math.cos(a2), .35, math.sin(a2)))
            tip = node+d.normalized()*.32
            rod(node, tip, .012, 'Bamboo', 4)
            for j in range(4):
                ld = Vector((math.cos(a2+(j-1.5)*.55), -.35-.15*j, math.sin(a2+(j-1.5)*.55)))
                leaf(tip, ld, rng.uniform(.32, .45), .045, 'Leaf')
    for k in range(4):   # young shoots
        a = k*1.7+.4
        cone((.75*math.cos(a), -.05, .7*math.sin(a)), .05, rng.uniform(.3, .6), 'Bamboo', 5)
    R = max(math.hypot(x, z) for x, z in bases)+.12
    convex_solid('Bamboo clump', [(R*math.cos(k*math.tau/8), y, R*math.sin(k*math.tau/8)) for y in (0, 2.4) for k in range(8)])

def flowering_shrub():
    begin('flowering_shrub')
    rng = random.Random(31)
    for c, r in [((0, .45, 0), (.75, .5, .65)), ((.6, .3, .2), (.45, .34, .42)), ((-.55, .32, -.15), (.5, .36, .45)),
                 ((.1, .28, -.55), (.42, .3, .38)), ((-.2, .26, .5), (.4, .28, .36))]:
        hull(blob(rng, c, r, 24, .1, floor=-.04), shrub_tone)
    for k in range(11):   # a few muted plum-blossom clusters, not a flower carpet
        a, rr = k*2.39996, .66*math.sqrt((k+.5)/11)
        x, z = rr*math.cos(a), rr*math.sin(a)
        y = .95-.55*(rr/.62)**2
        hull(blob(rng, (x, y, z), (.11, .08, .11), 7, .2), lambda ny: 'Blossom')

def grass_tuft():
    begin('grass_tuft')
    rng = random.Random(7)
    for k in range(24):
        a = k*2.39996
        rr = .17*math.sqrt((k+.5)/24)
        h = rng.uniform(.32, .72) if k > 3 else rng.uniform(.6, .8)
        lean = rr*2.2+rng.uniform(.05, .18)
        base = (rr*math.cos(a), -.03, rr*math.sin(a))
        tip = (math.cos(a)*(rr+lean), h, math.sin(a)*(rr+lean))
        blade(base, tip, rng.uniform(.03, .045), 'GrassLight' if k % 3 == 0 else 'Grass', a)

def rock_cluster():
    """Path/pond boulders: one mossy boulder with two companions, sunk 0.15 m."""
    begin('rock_cluster')
    rng = random.Random(41)
    for i, (c, r, n) in enumerate([((0, .45, 0), (.95, .78, .72), 30), ((1.15, .22, .45), (.58, .42, .5), 20),
                                   ((-.98, .1, .58), (.36, .27, .33), 14)]):
        hull(blob(rng, c, r, n, .2, floor=-.15), rock_tone(i == 0), 'Boulder')

def rock_outcrop():
    """Stratified cliff/pond-bank outcrop: stepped ledges with a mossy crown."""
    begin('rock_outcrop')
    rng = random.Random(53)
    for x, z, rx, rz, top, n in [(0, 0, 1.75, 1.3, 1.0, 28), (-.2, -.3, 1.4, 1.0, 2.0, 26),
                                 (.15, -.5, 1.0, .75, 2.8, 22), (-.1, -.55, .6, .46, 3.4, 16)]:
        hull(blob(rng, (x, top*.45, z), (rx, top*.62, rz), n, .2, floor=-.2, ceil=top), rock_tone(True), 'Ledge')

def stone_lantern():
    """Tiered square stone lantern (taller sibling of the Herb Garden lanterns)."""
    begin('stone_lantern')
    box((0, .09, 0), (.64, .18, .64), 'Stone')
    box((0, .23, 0), (.48, .1, .48), 'Stone')
    prism(0, 0, .28, 1.05, .15, 'Stone', 8)
    box((0, 1.1, 0), (.58, .1, .58), 'Coping')
    box((0, 1.33, 0), (.3, .36, .3), 'Lantern')        # glowing fire box seen through the openings
    for sx in (-1, 1):
        for sz in (-1, 1): box((sx*.17, 1.33, sz*.17), (.08, .36, .08), 'Stone')
    box((0, 1.53, 0), (.46, .05, .46), 'Stone')
    hip_cap(1.6, .47, .3, .09, .07, 'Stone')
    lathe((0, 1.88, 0), [(.07, 0), (.11, .07), (.06, .15), (0, .24)], 'Stone', 6)
    solid('Lantern base and shaft', (0, .725, 0), (.64, 1.45, .64))
    solid('Lantern cap', (0, 1.75, 0), (.92, .6, .92))

def sect_banner():
    """Sect banner standard: stone socket, timber pole, cross arm, teal banner with the
    Split-Cloud emblem on both faces. Banner hem at 2.05 m clears the player's head."""
    begin('sect_banner')
    box((0, .17, 0), (.7, .34, .7), 'Stone')
    box((0, .37, 0), (.76, .06, .76), 'Coping')
    prism(0, 0, .4, 4.6, .075, 'Timber', 8)
    crystal((0, 4.6, 0), .1, .3, .05, 'Bronze', 6)
    beam((-.06, 4.32, 0), (1.18, 4.32, 0), .1, .1, 'Cedar')
    beam((0, 3.85, 0), (.55, 4.28, 0), .07, .07, 'Cedar')
    crystal((1.18, 4.32, 0), .06, .12, .02, 'Bronze', 4)
    for x in (.3, .95): rod((x, 4.27, 0), (x, 4.12, 0), .012, 'Timber', 4)
    rod((.2, 4.1, 0), (1.05, 4.1, 0), .025, 'Timber', 6)
    xs, zs = [.24, .45, .66, .85, 1.02], [0, .035, -.01, .035, 0]
    for i in range(4): slab((xs[i], zs[i]), (xs[i+1], zs[i+1]), 2.2, 4.08, .03, 'Fabric')
    rod((.2, 2.18, 0), (1.06, 2.18, 0), .025, 'Timber', 6)
    for x in (.3, .95): crystal((x, 2.05, 0), .035, .1, .05, 'Bronze', 4)
    for z in (.06, -.06): emblem((.63, 3.3, z), .26, z)
    convex_solid('Banner pole', [(.075*math.cos(k*math.tau/8), y, .075*math.sin(k*math.tau/8)) for y in (.4, 4.6) for k in range(8)])
    solid('Banner socket', (0, .2, 0), (.76, .4, .76))

def training_dummy_rack():
    """Courtyard practice set: straw-bound striking dummy and a small weapon rack."""
    begin('training_dummy_rack')
    dx = -.6
    box((dx, .1, 0), (.5, .2, .5), 'Stone')
    prism(dx, 0, .2, 1.72, .08, 'Cedar', 8)
    lathe((dx, .72, 0), [(.17, 0), (.23, .1), (.24, .42), (.22, .7), (.15, .8)], 'Straw', 8)
    for y in (.82, 1.08, 1.36): lathe((dx, y, 0), [(.245, 0), (.25, .04), (.24, .07)], 'Timber', 8)
    beam((dx-.48, 1.3, 0), (dx+.48, 1.3, 0), .08, .08, 'Cedar')
    for s in (-1, 1): lathe((dx+s*.42, 1.24, 0), [(.07, 0), (.075, .12), (0, .13)], 'Straw', 6)
    box((dx, 1.82, 0), (.22, .24, .2), 'Straw')
    box((dx, 1.74, 0), (.235, .04, .215), 'Timber')
    cylinder_solid('Dummy', (dx, .9, 0), .25, 1.8)
    solid('Dummy arms', (dx, 1.3, 0), (.96, .1, .1))
    rx = .75
    for sx in (-.5, .5):
        box((rx+sx, .05, 0), (.1, .1, .55), 'Cedar')
        box((rx+sx, .85, 0), (.09, 1.6, .09), 'Timber')
    for y in (.32, 1.25): box((rx, y, .02), (1.12, .07, .12), 'Cedar')
    box((rx, 1.62, 0), (1.18, .06, .14), 'Cedar')
    for i, kind in enumerate(('staff', 'spear', 'staff', 'sword')):
        x = rx-.36+i*.24
        if kind == 'sword':
            box((x, .95, .1), (.06, .8, .02), 'Coping')
            box((x, .52, .1), (.18, .04, .05), 'Bronze')
            box((x, .4, .1), (.04, .2, .04), 'Timber')
        else:
            top = 2.15 if kind == 'spear' else 1.95
            rod((x, .1, .02), (x+.03, top, .05), .022, 'Cedar' if kind == 'staff' else 'Timber', 6)
            if kind == 'spear':
                crystal((x+.03, top, .05), .035, .2, .03, 'Coping', 4)
                rod((x+.03, top-.12, .05), (x+.03, top-.02, .05), .03, 'Fabric', 4)
    solid('Weapon rack', (rx, 1.0, .02), (1.2, 2.0, .3))

def stone_bench():
    """Garden bench: thick cedar seat on two stone block legs."""
    begin('stone_bench')
    for sx in (-.62, .62):
        box((sx, .19, 0), (.34, .38, .4), 'Stone')
        box((sx, .395, 0), (.38, .03, .44), 'Coping')
    box((0, .45, 0), (1.8, .09, .44), 'Cedar')
    for sx in (-.9, .9): box((sx, .45, 0), (.04, .095, .445), 'Timber')
    for sz in (-.13, .13): box((0, .398, sz), (1.1, .05, .05), 'Timber')
    solid('Bench', (0, .2475, 0), (1.8, .495, .44))

ASSETS = {
    'pine_windswept': ('Windswept Pine', 'PineWindswept', pine_windswept),
    'pine_tiered': ('Tiered Mountain Pine', 'PineTiered', pine_tiered),
    'bamboo_cluster': ('Bamboo Cluster', 'BambooCluster', bamboo_cluster),
    'flowering_shrub': ('Flowering Shrub', 'FloweringShrub', flowering_shrub),
    'grass_tuft': ('Grass Tuft', 'GrassTuft', grass_tuft),
    'rock_cluster': ('Path and Pond Boulders', 'RockCluster', rock_cluster),
    'rock_outcrop': ('Stratified Rock Outcrop', 'RockOutcrop', rock_outcrop),
    'stone_lantern': ('Stone Lantern', 'StoneLantern', stone_lantern),
    'sect_banner': ('Sect Banner Standard', 'SectBanner', sect_banner),
    'training_dummy_rack': ('Practice Dummy and Weapon Rack', 'TrainingDummyRack', training_dummy_rack),
    'stone_bench': ('Garden Bench', 'StoneBench', stone_bench),
}
for _, _, build in ASSETS.values(): build()

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

(STAGE/'source').mkdir(exist_ok=True)
(STAGE/'source/.gdignore').write_text('')
bpy.ops.wm.save_as_mainfile(filepath=str(STAGE/'source/claude_environment_batch1.blend'))

def f(v): return '%.4g' % v
def vec(p): return ', '.join(f(c) for c in p)

summary = {}
for bid, objs in groups.items():
    out_dir = STAGE/bid
    out_dir.mkdir(exist_ok=True)
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.gltf(filepath=str(out_dir/(bid+'.glb')), export_format='GLB', use_selection=True,
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
    tscn = '[gd_scene load_steps=%d format=3]\n\n[ext_resource type="PackedScene" path="%s%s/%s.glb" id="1_model"]\n\n' % (len(sub)+2, RES, bid, bid)
    tscn += '\n'.join(sub)+'\n[node name="%s" type="Node3D"]\n\n[node name="Model" parent="." instance=ExtResource("1_model")]\n' % ASSETS[bid][1]
    if nodes:
        tscn += '\n[node name="Collision" type="StaticBody3D" parent="." groups=["solid_world"]]\ncollision_mask = 2\n\n'+'\n'.join(nodes)
    (out_dir/(bid+'.tscn')).write_text(tscn, encoding='utf-8')
    summary[bid] = {
        'name': ASSETS[bid][0],
        'scene': RES+bid+'/'+bid+'.tscn',
        'model': RES+bid+'/'+bid+'.glb',
        'triangles': sum(len(o.data.polygons) for o in objs),
        'surfaces': len(objs),
        'materials': sorted(m for (b, m) in batches if b == bid),
        'bounds_min': [round(v, 3) for v in lo], 'bounds_max': [round(v, 3) for v in hi],
        'size_xyz_m': [round(hi[i]-lo[i], 2) for i in range(3)],
        'collision_shapes': len(solids[bid]),
    }
(STAGE/'build_summary.json').write_text(json.dumps(summary, indent=2))
print(json.dumps({k: (v['triangles'], v['size_xyz_m'], v['collision_shapes']) for k, v in summary.items()}))

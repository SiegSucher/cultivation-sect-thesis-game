"""Original Split-Cloud Hall. Run with Blender --background --python this_file.

All dimensions use Godot axes (X across, Y up, +Z front), metres. The baseline
JSON supplies the gameplay contract only; no baseline visual meshes are read.
Geometry is batched by shared material, rather than one node per decoration.
"""
from pathlib import Path
import math, json
import bpy, bmesh
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'assets/architecture/tang_main_hall'
SOURCE = ROOT/'source'
SOURCE.mkdir(exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for m in list(bpy.data.materials):
    if m.users==0:bpy.data.materials.remove(m)
scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1
PALETTE = {
    'Stone': '667e88', 'Coping': 'bcc6bd', 'Timber': '432d2d',
    'Cedar': '896048', 'Jade': '22594f', 'TileLight': '46796b',
    'Plaster': 'e6d9b8', 'Window': '284c53', 'Bronze': 'cda668',
    'Floor': '85624d', 'Lantern': 'ffda91', 'Fabric': '456e73',
}
materials = {}
for name, color in PALETTE.items():
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    rgb = [int(color[i:i+2],16)/255 for i in (0,2,4)]
    linear = [v/12.92 if v<.04045 else ((v+.055)/1.055)**2.4 for v in rgb]
    m.diffuse_color = (*linear,1)
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = (*linear,1)
    p.inputs['Roughness'].default_value = .82 if name!='Bronze' else .56
    if name=='Lantern':
        p.inputs['Emission Color'].default_value = (*linear,1)
        p.inputs['Emission Strength'].default_value = .45
    materials[name] = m

batches = {}
roof_faces = []
def geo(mat, verts, faces, group='Hall'):
    v,f = batches.setdefault((group,mat),([],[]))
    off = len(v)
    v.extend([tuple(p) for p in verts])
    f.extend([tuple(off+i for i in face) for face in faces])

def box(p,s,mat,group='Hall'):
    verts=[(p[0]+i*s[0]/2,p[1]+j*s[1]/2,p[2]+k*s[2]/2) for i,j,k in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    geo(mat,verts,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],group)

def beam(a,b,w,d,mat,group='Hall'):
    a,b=Vector(a),Vector(b)
    axis=(b-a).normalized()
    u=axis.cross(Vector((0,1,0)) if abs(axis.y)<.9 else Vector((1,0,0))).normalized()
    v=axis.cross(u)
    verts=[p+u*x*w/2+v*y*d/2 for p in (a,b) for x,y in [(-1,-1),(1,-1),(1,1),(-1,1)]]
    geo(mat,verts,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],group)

def rod(a,b,r,mat,sides=8,group='Hall'):
    a,b=Vector(a),Vector(b)
    axis=(b-a).normalized()
    u=axis.cross(Vector((0,1,0)) if abs(axis.y)<.9 else Vector((1,0,0))).normalized()
    v=axis.cross(u)
    verts=[p+r*(u*math.cos(i*math.tau/sides)+v*math.sin(i*math.tau/sides)) for p in (a,b) for i in range(sides)]
    faces=[tuple(reversed(range(sides))),tuple(range(sides,2*sides))]
    faces += [(i,(i+1)%sides,(i+1)%sides+sides,i+sides) for i in range(sides)]
    geo(mat,verts,faces,group)

def ring(p,r,thick,mat,segments=16,group='Hall'):
    for i in range(segments):
        a,b=i*math.tau/segments,(i+1)*math.tau/segments
        beam((p[0]+r*math.cos(a),p[1]+r*math.sin(a),p[2]),(p[0]+r*math.cos(b),p[1]+r*math.sin(b),p[2]),thick,thick,mat,group)

def bracket(x,y,z,scale=1):
    # Alternating timber bearing arms make the roof visibly supported.
    for i in range(3):
        w=(.70+i*.40)*scale
        box((x,y+i*.18,z),(w,.14*scale,.28*scale),'Cedar')
        box((x,y+i*.18+.09,z),(.25*scale,.14*scale,w),'Timber')
    for s in (-1,1):
        beam((x,y-.62,z),(x+s*.75*scale,y+.05,z),.17*scale,.22*scale,'Cedar')

def lattice(cx,cy,z,w,h,front=True):
    sign=1 if front else -1
    box((cx,cy,z),(w,h,.20),'Plaster')
    box((cx,cy,z+sign*.115),(w-.28,h-.35,.055),'Window')
    for x in (-w/2,w/2): box((cx+x,cy,z+sign*.19),(.14,h+.14,.18),'Cedar')
    for y in (-h/2,h/2): box((cx,cy+y,z+sign*.19),(w+.14,.14,.18),'Cedar')
    for i in (-1,0,1):
        x=cx+i*w*.23
        box((x,cy,z+sign*.20),(.06,h-.20,.07),'Cedar')
    for y in (-h*.29,h*.29): box((cx,cy+y,z+sign*.20),(w,.07,.07),'Cedar')
    # Repeated diamond cloud motif; much coarser than the source fretwork.
    for x in (-w*.23,w*.23):
        pts=[(cx+x,cy+.55,z+sign*.21),(cx+x+.42,cy,z+sign*.21),(cx+x,cy-.55,z+sign*.21),(cx+x-.42,cy,z+sign*.21)]
        for a,b in zip(pts,pts[1:]+pts[:1]):beam(a,b,.055,.055,'Bronze')

def roof(cx,cz,w,d,eave,rise,lift=.34,iw=None,idp=0):
    iw=w*.56 if iw is None else iw
    def pt(side,s,t):
        hw=w/2+(iw-w)*t/2
        hd=d/2+(idp-d)*t/2
        if side==0:x,z=(2*s-1)*hw,hd
        elif side==1:x,z=hw,(1-2*s)*hd
        elif side==2:x,z=(1-2*s)*hw,-hd
        else:x,z=-hw,(2*s-1)*hd
        y=eave+rise*t**1.55+lift*(1-t)**7+.32*abs(2*s-1)**6*(1-t)**2
        return Vector((cx+x,y,cz+z))
    # Six strips carry the curvature. Surface faces are flat shaded on purpose.
    for side in range(4):
        across=12 if side%2==0 else 8
        steps=6
        top=[pt(side,i/across,j/steps) for j in range(steps+1) for i in range(across+1)]
        faces=[]
        for j in range(steps):
            for i in range(across):
                a=j*(across+1)+i
                f=[a,a+1,a+across+2,a+across+1]
                n=(top[f[1]]-top[f[0]]).cross(top[f[2]]-top[f[0]])
                if n.length<1e-7:
                    f=[a,a+1,a+across+1]
                    n=(top[f[1]]-top[f[0]]).cross(top[f[2]]-top[f[0]])
                if n.length<1e-7:continue
                if n.y<0:f.reverse()
                faces.append(f)
        geo('Jade',top,faces)
        bottom=[p-Vector((0,.20,0)) for p in top]
        geo('Timber',bottom,[tuple(reversed(f)) for f in faces])
        for f in faces:
            for k in range(1,len(f)-1):
                roof_faces.extend([list(bottom[f[0]]),list(bottom[f[k]]),list(bottom[f[k+1]])])
        for i in range(across):
            geo('Cedar',[top[i],top[i+1],bottom[i+1],bottom[i]],[(0,1,2,3)])
        if idp:
            off=steps*(across+1)
            for i in range(across):geo('Timber',[top[off+i],bottom[off+i],bottom[off+i+1],top[off+i+1]],[(0,1,2,3)])
        # Raised two-sided seams at 0.8 m spacing, not dense barrel tiles.
        count=round((w if side%2==0 else d)/.80)
        for i in range(1,count):
            for j in range(steps):
                a,b=pt(side,i/count,j/steps),pt(side,i/count,(j+1)/steps)
                if (b-a).length>.01:beam(a+Vector((0,.025,0)),b+Vector((0,.025,0)),.042,.045,'TileLight')
            a,b=pt(side,i/count,0),pt(side,i/count,.17)
            beam(a-Vector((0,.24,0)),b-Vector((0,.24,0)),.095,.11,'Cedar')
        # Strong hip outlines, with bronze only at the upswept corners.
        for j in range(steps):
            a,b=pt(side,0,j/steps),pt(side,0,(j+1)/steps)
            if (b-a).length>.01:beam(a+Vector((0,.06,0)),b+Vector((0,.06,0)),.16,.15,'TileLight')
        for j in range(2):
            beam(pt(side,0,j/12)+Vector((0,.11,0)),pt(side,0,(j+1)/12)+Vector((0,.11,0)),.075,.07,'Bronze')
    if idp==0:
        y=eave+rise+.08
        beam((cx-iw/2,y,cz),(cx+iw/2,y,cz),.22,.20,'TileLight')
        for sign in (-1,1):
            pts=[(cx+sign*(iw/2-.2),y,cz),(cx+sign*(iw/2+.20),y+.18,cz),(cx+sign*(iw/2+.48),y+.46,cz)]
            for a,b in zip(pts,pts[1:]):beam(a,b,.16,.17,'Bronze')
    return pt

# Podium and every stair retain their original dimensions and floor elevation.
for p,s,m in [((0,.18,0),(40.4,.36,24),'Stone'),((0,.85,0),(39.7,.98,23.5),'Stone'),((0,1.38,0),(40.2,.16,23.9),'Coping'),((0,1.48,0),(40.4,.08,24),'Coping'),((0,.28,12.8),(13.9,.56,2.4),'Stone'),((0,.96,12.8),(13.5,.8,2.4),'Stone'),((0,1.44,12.8),(13.9,.16,2.4),'Coping')]:box(p,s,m)
for i in range(10):
    h=(10-i)*.15;z=14+(i+.5)*.4
    box((0,h/2,z),(11.2,h,.4),'Stone')
    box((0,h-.028,z+.17),(11.25,.055,.085),'Coping')
for side in (-1,1):
    for i in range(6):
        z=14+i*.8;h=max(0,1.5-(z-14)*.375)
        box((side*5.85,h+.66,z),(.28,1.15,.28),'Stone')
        box((side*5.85,h+1.24,z),(.36,.13,.36),'Coping')
    beam((side*5.85,2.67,14),(side*5.85,1.17,18),.22,.20,'Coping')
    beam((side*5.85,1.75,13.85),(side*5.85,.23,18.05),.42,.42,'Stone')
    for x in (8,11.7,15.4,19.2):
        box((side*x,2.04,11.55),(.36,1.06,.36),'Stone')
        box((side*x,2.62,11.55),(.46,.13,.46),'Coping')
    for a,b in ((8,11.7),(11.7,15.4),(15.4,19.2)):
        box((side*(a+b)/2,2.43,11.55),(b-a,.18,.22),'Coping')
        for j in range(1,4):box((side*(a+(b-a)*j/4),2.0,11.55),(.13,.70,.12),'Stone')
    # Inlaid stone diamonds make the long podium intentional at eye level.
    for x in (9,13,17):
        ring((side*x,.85,11.80),.32,.055,'Coping',4)

roof(-14,0,13.5,22.2,7.85,2.35)
roof(14,0,13.5,22.2,7.85,2.35)
roof(0,0,29.2,23.4,8.15,3.35,.36,18.6,12.8)
upper=roof(0,0,26,20,13.35,4.20,.36)
roof(0,10.3,13.4,9.8,7.65,2.20,.35)

# An original front-facing folded cloud canopy replaces the second hip roof.
# It uses two swept gable fields, with a visible pierced mountain tympanum.
# The front/back ridge points stay below the old upper portico's 12.89 m tip.
def cloud_y(x):
    t=abs(x)/5.1
    return 12.48-2.43*t**.72+.36*t**7
for sign in (-1,1):
    for i in range(8):
        a=sign*5.1*i/8;b=sign*5.1*(i+1)/8
        top=[(a,cloud_y(a),6.7),(b,cloud_y(b),6.7),(b,cloud_y(b),13.9),(a,cloud_y(a),13.9)]
        # Recalculate normals later in Blender; sealed soffit and edge strips.
        geo('Jade',top,[(0,1,2,3)] if sign<0 else [(3,2,1,0)])
        bottom=[(x,y-.2,z) for x,y,z in top]
        geo('Timber',bottom,[(3,2,1,0)] if sign<0 else [(0,1,2,3)])
        roof_faces.extend([list(bottom[0]),list(bottom[1]),list(bottom[2]),list(bottom[0]),list(bottom[2]),list(bottom[3])])
        for z in (6.7,13.9):
            beam((a,cloud_y(a)-.08,z),(b,cloud_y(b)-.08,z),.24,.24,'Cedar')
            beam((a,cloud_y(a)+.045,z),(b,cloud_y(b)+.045,z),.065,.065,'Bronze')
    for j in range(13):
        z=6.7+j*.60
        for i in range(8):
            a=sign*5.1*i/8;b=sign*5.1*(i+1)/8
            beam((a,cloud_y(a)+.025,z),(b,cloud_y(b)+.025,z),.04,.04,'TileLight')
beam((0,12.52,6.7),(0,12.52,13.9),.20,.20,'TileLight')
for z in (6.7,13.9):
    beam((0,12.52,z),(0,12.80,z+(.20 if z>10 else -.20)),.12,.12,'Bronze')
# The open dark inset is backed with a real panel; there is no sky hole.
geo('Timber',[(-3.8,10.0,13.66),(3.8,10.0,13.66),(0,12.14,13.66)],[(0,1,2)])
for a,b in [((-2.0,10.15,13.73),(-.65,11.70,13.73)),((-.65,11.70,13.73),(0,10.8,13.73)),((0,10.8,13.73),(.65,11.70,13.73)),((.65,11.70,13.73),(2.,10.15,13.73))]:beam(a,b,.12,.11,'Bronze')
for s in (-1,1):
    beam((s*3.8,9.2,12.8),(s*2.6,10.8,12.8),.16,.18,'Cedar')

# Split mountain crest is integrated into the main ridge, below old max height.
for a,b in [((-1.4,17.63,0),(-.55,18.17,0)),((-.55,18.17,0),(0,17.72,0)),((0,17.72,0),(.55,18.17,0)),((.55,18.17,0),(1.4,17.63,0))]:beam(a,b,.12,.12,'Bronze')

xs=[-18.2,-14.6,-11,-7.4,-3.6,3.6,7.4,11,14.6,18.2]
for z in (-8.4,7.4):
    for x in xs:
        box((x,1.74,z),(.76,.46,.76),'Coping')
        rod((x,1.92,z),(x,7.7,z),.25,'Timber')
    for a,b in zip(xs,xs[1:]):
        cx=(a+b)/2;w=b-a-.42
        if z>0 and a==-3.6:
            for sign in (-1,1):box((sign*3.37,4.26,z),(.34,5.5,.52),'Cedar')
            box((0,7.22,z),(7.1,.55,.55),'Timber')
            box((0,8.1,z),(6.4,1.5,.25),'Plaster')
            continue
        box((cx,2.02,z),(w,1,.28),'Stone')
        box((cx,2.58,z),(w,.16,.4),'Cedar')
        lattice(cx,4.34,z,w-.10,3.25,z>0)
        box((cx,6.51,z),(w,.86,.27),'Plaster')
        for dx in (-.25,.25):
            ring((cx+dx*w,6.5,z+(.18 if z>0 else -.18)),.22,.055,'Cedar',4)
        box((cx,7.16,z),(w,.38,.40),'Timber')
for side in (-1,1):
    x=side*18.2
    box((x,2.03,-.5),(.30,1.05,15.8),'Stone')
    box((x,4.98,-.5),(.22,4.8,15.8),'Plaster')
    for z in (-8.4,-4.45,-.5,3.45,7.4):box((x,4.65,z),(.45,6.1,.30),'Timber')
    for y in (2.6,6.3,7.3):box((x,y,-.5),(.42,.20,16.2),'Cedar')
    for z in (-6.4,-2.5,1.5,5.4):
        box((x+side*.13,4.5,z),(.08,2.7,2.6),'Window')
        for yy in (3.1,4.5,5.9):box((x+side*.20,yy,z),(.13,.08,2.8),'Cedar')
        for dz in (-1.1,-.55,0,.55,1.1):box((x+side*.22,4.5,z+dz),(.05,2.7,.04),'Cedar')

for z in (-9.6,9.6):
    for x in (-18,-14.4,-10.8,-7.2,7.2,10.8,14.4,18):
        box((x,1.82,z),(.85,.60,.85),'Coping')
        rod((x,2.05,z),(x,7.36,z),.32,'Timber')
        bracket(x,7.03,z)
    box((0,7.38,z),(37.1,.42,.52),'Timber')
    box((0,7.11,z),(37.2,.16,.54),'Cedar')
for x in (-5.2,5.2):
    for z in (8,13.4):
        box((x,1.86,z),(1,.67,1),'Coping')
        rod((x,2.12,z),(x,7.32,z),.38,'Timber')
        rod((x,2.4,z),(x,2.55,z),.39,'Bronze')
        bracket(x,7.03,z,1.2)
    box((x,7.42,10.7),(.45,.44,6.2),'Timber')
for z in (8,13.4):box((0,7.39,z),(10.9,.48,.52),'Timber')
for z in (7.8,12.8):
    box((0,9.23,z),(8,1.75,.18),'Plaster')
    for x in (-3.8,-1.9,0,1.9,3.8):box((x,9.23,z),(.18,1.75,.25),'Timber')
    box((0,9.58,z),(8.1,.18,.26),'Cedar')

# Nava frame and fitted upper wall, using a conservative version of the roof
# height equation to avoid beams or rectangular infill piercing the hips.
def upper_y(x,z):
    t=max(0,min(1,(13-abs(x))/(13-7.28),(10-abs(z))/10))
    return 13.35+4.2*t**1.55
for x in (-9.3,9.3):
    for z in (-6.4,-2.2,2.2,6.4):
        box((x,1.84,z),(.92,.62,.92),'Coping')
        rod((x,2.08,z),(x,11,z),.39,'Timber')
        rod((x,2.45,z),(x,2.60,z),.40,'Bronze')
        bracket(x,10.96,z,1.05)
    box((x,11.47,0),(.54,.56,13.5),'Timber')
for z in (-6.4,-2.2,2.2,6.4):
    box((0,11.55,z),(19.5,.58,.48),'Timber')
    apex=upper_y(0,z)-.45
    beam((0,11.82,z),(0,apex,z),.32,.34,'Timber')
    for sign in (-1,1):
        beam((sign*9.3,9.35,z),(sign*7.5,11.5,z),.25,.31,'Cedar')
        for i in range(6):
            x0=sign*8.7*(1-i/6);x1=sign*8.7*(1-(i+1)/6)
            beam((x0,upper_y(x0,z)-.45,z),(x1,upper_y(x1,z)-.45,z),.26,.30,'Cedar')
for z in (-6.4,6.4):
    for i in range(12):
        a=-9.3+i*18.6/12;b=a+18.6/12
        h=min(upper_y(a,z),upper_y(b,z))-.35
        box(((a+b)/2,(11.6+h)/2,z),(b-a,h-11.6,.24),'Plaster')
        box(((a+b)/2,12.25,z+(.15 if z>0 else -.15)),(b-a-.16,.75,.06),'Window')
        box((a,12.1,z),(.12,1.35,.31),'Cedar')
    for y in (11.48,13.2):box((0,y,z),(19,.18,.31),'Cedar')
for x in (-9.3,9.3):
    for i in range(8):
        a=-6.4+i*1.6;b=a+1.6
        h=min(upper_y(x,a),upper_y(x,b))-.36
        box((x,(11.6+h)/2,(a+b)/2),(.24,h-11.6,b-a),'Plaster')
        box((x+(.15 if x>0 else -.15),12.2,(a+b)/2),(.06,.8,1.3),'Window')
        box((x,12.1,a),(.31,1.3,.12),'Cedar')

box((0,1.51,-.5),(36.2,.04,15.7),'Floor')
for i in range(53):
    x=-17.6+i*35.2/52
    if abs(x)>2.2:box((x,1.535,-.5),(.014,.008,15.5),'Timber')
box((0,1.537,1.8),(4.2,.025,11),'Stone')
for sign in (-1,1):box((sign*2.16,1.555,1.8),(.035,.015,11),'Bronze')
box((0,1.83,-6.45),(8.7,.60,4.5),'Timber')
box((0,2.11,-6.45),(8.9,.08,4.6),'Cedar')
for i in range(4):
    h=1.55+(i+1)*.15
    box((0,(1.55+h)/2,-2.6-(i+.5)*.40),(5.4,h-1.55,.40),'Cedar')

def chair(x,y,z,leader=False,rot=0):
    w=1.45 if leader else .9;d=.80 if leader else .66;h=.55 if leader else .48
    def p(a,b,c):return (x+a*math.cos(rot)+c*math.sin(rot),y+b,z-a*math.sin(rot)+c*math.cos(rot))
    def bar(a,b,wid,dep,m):beam(p(*a),p(*b),wid,dep,m)
    for a in (-w*.4,w*.4):
        for c in (-d*.38,d*.38):bar((a,.06,c),(a,h,c),.12,.12,'Timber')
    # Rotated seat faces use arbitrary corners rather than scaling a node.
    verts=[p(a,b,c) for a,b,c in [(-w/2,h-.07,-d/2),(w/2,h-.07,-d/2),(w/2,h+.03,-d/2),(-w/2,h+.03,-d/2),(-w/2,h-.07,d/2),(w/2,h-.07,d/2),(w/2,h+.03,d/2),(-w/2,h+.03,d/2)]]
    geo('Fabric',verts,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)])
    for a in (-w*.43,w*.43):
        bar((a,h,-d*.38),(a,h+1.0,-d*.38),.12,.12,'Cedar')
        bar((a,h+.32,-d*.38),(a,h+.32,d*.40),.12,.12,'Cedar')
    for yy in (.45,.88):bar((-w*.43,h+yy,-d*.38),(w*.43,h+yy,-d*.38),.12,.12,'Cedar')

def table(x,y,z,w,d,h):
    box((x,y+h,z),(w,.10,d),'Cedar')
    box((x,y+h-.15,z),(w-.12,.18,d-.08),'Timber')
    for a in (-w*.38,w*.38):
        for b in (-d*.34,d*.34):box((x+a,y+h*.46,z+b),(.10,h*.90,.10),'Timber')

chair(0,2.15,-7.23,True)
table(0,2.15,-5.75,3.2,1,.76)
for sign in (-1,1):
    for z in (4.2,1.2,-1.8):
        chair(sign*6.55,1.54,z,False,-math.pi/2 if sign>0 else math.pi/2)
        table(sign*4.95,1.54,z,.68,.80,.66)

box((0,4.65,-8.08),(9.4,6.2,.30),'Timber')
box((0,4.72,-7.88),(8.65,5.55,.10),'Fabric')
for x in (-4.6,4.6,-3.1,3.1):box((x,4.7,-7.77),(.14,6,.17),'Cedar')
for y in (1.74,2.52,6.95,7.65):box((0,y,-7.76),(9.2,.13,.16),'Bronze')
ring((0,5.04,-7.68),1.55,.085,'Bronze',20)
for a,b in [((-1.12,4.45,-7.57),(-.45,5.9,-7.57)),((-.45,5.9,-7.57),(0,5.0,-7.57)),((0,5.0,-7.57),(.45,5.9,-7.57)),((.45,5.9,-7.57),(1.12,4.45,-7.57))]:beam(a,b,.13,.10,'Bronze')
for sign in (-1,1):
    box((sign*3.75,4.65,-7.66),(.56,3.6,.025),'Plaster')
    for yy in (3.4,4.65,5.9):ring((sign*3.75,yy,-7.62),.20,.04,'Bronze',4)
    x=sign*11
    for a,b in ((-8.4,-1.8),(.2,7.4)):
        box((x,4.38,(a+b)/2),(.24,5.7,b-a),'Plaster')
        for z in (a+.4,b-.4):box((x-sign*.15,4.38,z),(.10,5.4,.10),'Cedar')
        box((x-sign*.15,3.0,(a+b)/2),(.10,.14,b-a),'Cedar')
        for yy in (2.7,6.3,6.6):box((x-sign*.16,yy,(a+b)/2),(.11,.10,b-a),'Cedar')
        # Two jade inserts interrupt the blank private-room partition walls.
        mid=(a+b)/2
        box((x-sign*.16,4.65,mid),(.06,2.55,2.15),'Fabric')
        for zz in (mid-1.13,mid+1.13):box((x-sign*.21,4.65,zz),(.08,2.75,.10),'Bronze')
        for yy in (3.27,6.03):box((x-sign*.21,yy,mid),(.08,.10,2.36),'Cedar')
        for zz in (mid-.55,mid,mid+.55):box((x-sign*.22,4.65,zz),(.08,2.4,.055),'Cedar')
    box((x,5.85,-.8),(.35,2.9,2),'Timber')
    box((sign*15,2.85,-7.75),(4.7,2.6,.65),'Timber')
    for yy in (1.9,2.7,3.5):box((sign*15,yy,-7.37),(4.6,.09,.13),'Cedar')
    for j in range(9):box((sign*15-1.9+j*.47,3.08,-7.30),(.29,.58,.20),'Plaster')
    table(sign*14.6,1.54,3.7,2.3,1.2,.76)
    chair(sign*14.6,1.54,5.2,False,math.pi)

spec=json.loads((ROOT/'baseline/hall/main_sect_hall.json').read_text())
for x,y,z in spec['lights']:
    rod((x,y+.4,z),(x,y+.85,z),.025,'Timber',6)
    rod((x,y-.4,z),(x,y+.4,z),.25,'Lantern')
    for dy in (-.43,.43):rod((x,y+dy-.03,z),(x,y+dy+.03,z),.28,'Cedar')
    for i in range(4):
        a=i*math.tau/4
        rod((x+.25*math.cos(a),y-.4,z+.25*math.sin(a)),(x+.25*math.cos(a),y+.4,z+.25*math.sin(a)),.02,'Timber',4)

# Editable text is supplied by the retained runtime Label3D contract.
box((0,7.03,13.72),(5.6,1.14,.20),'Timber')
for x in (-2.8,2.8):box((x,7.03,13.84),(.045,1.16,.045),'Bronze')
for y in (6.46,7.60):box((0,y,13.84),(5.65,.045,.045),'Bronze')

for group,width,height in [('Grand',6.4,5.4),('Private',2.0,2.8)]:
    lo,hi=.02,width/2-.02
    box(((lo+hi)/2,0,.21),(hi-lo,height-.06,.22),'Timber',group)
    for y in (-height*.40,0,height*.40):box(((lo+hi)/2,y,.35),(hi-lo,.16,.09),'Cedar',group)
    for x in (lo+.1,hi-.1):box((x,0,.35),(.14,height-.06,.09),'Cedar',group)
    ring(((lo+hi)/2,.25,.37),min(.65,width*.20),.045,'Bronze',4,group)
    ring((hi-.3,-.30,.48),.13,.025,'Bronze',12,group)

groups={}
for (group,mat),(verts,faces) in batches.items():
    mesh=bpy.data.meshes.new(group+' / '+mat)
    # Blender is Z-up, Godot is Y-up. Conversion preserves handedness.
    mesh.from_pydata([(p[0],-p[2],p[1]) for p in verts],[],faces)
    mesh.materials.append(materials[mat])
    mesh.update()
    # The tip of a hip collapses to a ridge; remove collapsed triangles after
    # triangulation, before export. This removes zero-area faces, not roof area.
    bm=bmesh.new();bm.from_mesh(mesh)
    bmesh.ops.triangulate(bm,faces=list(bm.faces))
    collapsed=[f for f in bm.faces if f.calc_area()<1e-8]
    if collapsed:bmesh.ops.delete(bm,geom=collapsed,context='FACES_ONLY')
    bm.to_mesh(mesh);bm.free();mesh.update()
    obj=bpy.data.objects.new(group+' / '+mat,mesh)
    col=bpy.data.collections.get(group)
    if not col:
        col=bpy.data.collections.new(group);scene.collection.children.link(col)
    col.objects.link(obj)
    groups.setdefault(group,[]).append(obj)

bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'split_cloud_hall.blend'))
def export(group,name):
    bpy.ops.object.select_all(action='DESELECT')
    for obj in groups[group]:obj.select_set(True)
    bpy.context.view_layer.objects.active=groups[group][0]
    bpy.ops.export_scene.gltf(filepath=str(OUT/name),export_format='GLB',use_selection=True,export_yup=True,export_materials='EXPORT',export_normals=True,export_texcoords=False)
export('Hall','main_sect_hall.glb')
# The cheap mesh is already economical at distance. Keep the same range contract
# without a visually discontinuous aggressive decimation experiment.
export('Hall','main_sect_hall_lod.glb')
export('Grand','grand_door_leaf.glb')
export('Private','room_door_leaf.glb')
spec['name']='Split-Cloud Main Sect Hall'
spec['revision']='2026-10-22-split-cloud-low-poly'
spec['materials']=list(PALETTE)
spec['notes']=['Original non-roof collision contract retained; roof follows new soffit geometry.','No town or production player exists in source project.','Distant representation uses the same inexpensive mesh.']
spec['roof_collision_faces']=roof_faces
(OUT/'main_sect_hall.json').write_text(json.dumps(spec,indent=2))
summary={'palette':PALETTE,'material_count':len(PALETTE),'batches':{g:len(v) for g,v in groups.items()},'source':str(SOURCE/'split_cloud_hall.blend'),'hall_vertices':sum(len(o.data.vertices) for o in groups['Hall']),'hall_triangles':sum(len(o.data.polygons) for o in groups['Hall'])}
(ROOT/'reports/build-summary.json').write_text(json.dumps(summary,indent=2))
print(json.dumps(summary))

"""Harmonize the existing gateway without redesign or changing collision data.

Run with Blender --background --python this_file. Original high-detail GLBs are
read only from the saved in-project stage baseline. All exports stay in test.
Limited dissolve removes nearly coplanar edges without moving mesh vertices;
no collapse/ratio decimation or whole-building rescaling is used.
"""
from pathlib import Path
import bpy,bmesh,json,math
from mathutils import Vector

R=Path(__file__).resolve().parents[1]
OUT=R/'assets/architecture/sect_gate'
REPORT=R/'reports/environment-conversion-stage-1'
COLORS={'Stone':'667e88','Coping':'bcc6bd','Timber':'432d2d','Cedar':'896048','Jade':'22594f','TileLight':'46796b','Plaster':'e6d9b8','Window':'284c53','Bronze':'cda668','Fabric':'456e73','Lantern':'ffda91'}
MAP={'ArchStone':'Stone','ArchStoneDark':'Stone','Ashlar':'Stone','Coping':'Coping','Paving':'Coping','Timber':'Timber','Iron':'Timber','CarvedWood':'Cedar','JadeTile':'Jade','TileEdge':'TileLight','Plaster':'Plaster','Window':'Window','Bronze':'Bronze','Fabric':'Fabric','Lantern':'Lantern'}
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene
scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
materials={}
for name,color in COLORS.items():
    mat=bpy.data.materials.new('SplitCloud_'+name);mat.use_nodes=True
    rgb=[int(color[i:i+2],16)/255 for i in (0,2,4)]
    linear=[v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in rgb]
    p=mat.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value=(*linear,1)
    p.inputs['Roughness'].default_value=.56 if name=='Bronze' else .82
    mat.diffuse_color=(*linear,1)
    if name=='Lantern':
        p.inputs['Emission Color'].default_value=(*linear,1);p.inputs['Emission Strength'].default_value=.45
    materials[name]=mat

stats=[];collections={}
for filename,label in [('sect_gate.glb','GateNear'),('sect_gate_lod.glb','GateDistant'),('gate_leaf_left.glb','LeftLeaf'),('gate_leaf_right.glb','RightLeaf')]:
    old=set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(R/'baseline/stage1_gate'/filename))
    imported=[o for o in bpy.data.objects if o not in old and o.type=='MESH']
    bounds_before=[o.matrix_world@Vector(c) for o in imported for c in o.bound_box]
    before=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in imported)
    by_material={};reductions=[]
    for obj in imported:
        original=obj.data.materials[0].name
        role=next((key for key in sorted(MAP,key=len,reverse=True) if original.startswith('Gate_'+key)),None)
        if role is None:raise RuntimeError('Unmapped gate material '+original)
        target=MAP[role]
        original_tri=sum(len(p.vertices)-2 for p in obj.data.polygons)
        bm=bmesh.new();bm.from_mesh(obj.data)
        # UV/normal seams duplicate vertices in GLB. The converted material is
        # texture-free and flat-shaded, so exact seams can be joined safely.
        bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-7)
        # Keep rounded/architectural silhouette boundaries; consolidate shallow
        # subdivisions in repetitive tile ribs more than structural surfaces.
        angle=math.radians(10 if role=='TileEdge' else 2)
        bmesh.ops.dissolve_limit(bm,angle_limit=angle,use_dissolve_boundaries=False,verts=list(bm.verts),edges=list(bm.edges),delimit=set())
        bmesh.ops.triangulate(bm,faces=list(bm.faces))
        degenerate=[f for f in bm.faces if f.calc_area()<1e-10]
        if degenerate:bmesh.ops.delete(bm,geom=degenerate,context='FACES_ONLY')
        bm.to_mesh(obj.data);bm.free();obj.data.update()
        for poly in obj.data.polygons:poly.use_smooth=False
        obj.data.materials.clear();obj.data.materials.append(materials[target])
        reductions.append({'original_role':role,'before':original_tri,'after':len(obj.data.polygons),'dissolve_angle_degrees':math.degrees(angle)})
        by_material.setdefault(target,[]).append(obj)
    col=bpy.data.collections.new(label);scene.collection.children.link(col)
    exported=[]
    for role,objects in by_material.items():
        bpy.ops.object.select_all(action='DESELECT')
        for obj in objects:obj.select_set(True)
        bpy.context.view_layer.objects.active=objects[0]
        if len(objects)>1:bpy.ops.object.join()
        obj=bpy.context.view_layer.objects.active
        # Joining preserves world coordinates. Apply transforms explicitly so
        # leaf assets remain hinge-local and the building retains local origin.
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
        obj.name=label+'_'+role
        for previous in list(obj.users_collection):previous.objects.unlink(obj)
        col.objects.link(obj);exported.append(obj)
    bounds_after=[o.matrix_world@Vector(c) for o in exported for c in o.bound_box]
    before_min=[min(p[i] for p in bounds_before) for i in range(3)]
    before_max=[max(p[i] for p in bounds_before) for i in range(3)]
    after_min=[min(p[i] for p in bounds_after) for i in range(3)]
    after_max=[max(p[i] for p in bounds_after) for i in range(3)]
    assert max(abs(a-b) for a,b in zip(before_min+before_max,after_min+after_max))<.0001,(filename,before_min,after_min,before_max,after_max)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in exported:obj.select_set(True)
    bpy.context.view_layer.objects.active=exported[0]
    bpy.ops.export_scene.gltf(filepath=str(OUT/filename),export_format='GLB',use_selection=True,export_yup=True,export_materials='EXPORT',export_texcoords=False,export_normals=True)
    stats.append({'file':filename,'triangles_before':before,'triangles_after':sum(len(o.data.polygons) for o in exported),'surfaces_after':len(exported),'bounds_before_blender':[before_min,before_max],'bounds_after_blender':[after_min,after_max],'reductions':reductions})
    collections[label]=exported

# Source groups are alternate representations, not additional buildings.
for label,objects in collections.items():
    for obj in objects:obj.hide_set(label!='GateNear')
for mat in list(bpy.data.materials):
    if mat.users==0:bpy.data.materials.remove(mat)
for image in list(bpy.data.images):
    if image.users==0:bpy.data.images.remove(image)
bpy.ops.wm.save_as_mainfile(filepath=str(R/'source/sect_gate_low_poly.blend'))
(REPORT/'conversion-build.json').write_text(json.dumps({'models':stats,'palette':COLORS,'material_map':MAP,'visual_decisions':'Retain existing fortified gateway and tower silhouettes; match opaque flat hall palette; dissolve shallow redundant detail, no vertex-collapse decimation; no JSON/script/collider changes.','shared_resources':'Palette values and in-source material objects shared; each exported GLB embeds materials and does not promise cross-file GPU resource sharing.'},indent=2))
print(json.dumps(stats))

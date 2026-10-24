"""Conservative palette/facet conversion of one authorized facility group.

Blender --background --python this_file -- training|pavilion [--props-only]
All inputs come from the frozen local baseline. No collision/runtime data is
regenerated. Retain name-sensitive paving batches and hinge-local leaf origins.
"""
from pathlib import Path
import bpy, bmesh, json, math, sys
from mathutils import Vector
R = Path(__file__).resolve().parents[1]
args = sys.argv[sys.argv.index('--')+1:]
short = args[0]
family = {'training':'martial_training_ground', 'pavilion':'scripture_pavilion'}[short]
props_only = '--props-only' in args
OUT = R/'assets/architecture'/family
E = R/'reports/environment-conversion-stages-2-3'
COLORS = {'Stone':'667e88','Coping':'bcc6bd','Timber':'432d2d','Cedar':'896048','Jade':'22594f','TileLight':'46796b','Plaster':'e6d9b8','Window':'284c53','Bronze':'cda668','Fabric':'456e73','Lantern':'ffda91','Floor':'85624d','Earth':'806b50','CourtStone':'81938d'}
MAP = {'Ashlar':'Stone','ArchStone':'Stone','ArchStoneDark':'Stone','Stone':'Stone','WornStone':'Stone','Coping':'Coping','Paving':'Stone','CourtPaving':'CourtStone','PackedEarth':'Earth','Joint':'Window','Timber':'Timber','CarvedWood':'Cedar','PracticeWood':'Floor','Iron':'Timber','JadeTile':'Jade','TileEdge':'TileLight','Plaster':'Plaster','Window':'Window','Bronze':'Bronze','Fabric':'Fabric','Rope':'Plaster','Pottery':'Jade','Lantern':'Lantern','Floor':'Floor','Indigo':'Fabric','Paper':'Plaster','Ochre':'Bronze','RedBinding':'Cedar'}
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.unit_settings.system='METRIC'; scene.unit_settings.scale_length=1
materials = {}
for role,color in COLORS.items():
    mat=bpy.data.materials.new('SplitCloud_'+role); mat.use_nodes=True
    rgb=[int(color[i:i+2],16)/255 for i in (0,2,4)]
    linear=[v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in rgb]
    p=mat.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value=(*linear,1)
    p.inputs['Roughness'].default_value=.56 if role=='Bronze' else .82
    mat.diffuse_color=(*linear,1)
    if role=='Lantern':
        p.inputs['Emission Color'].default_value=(*linear,1); p.inputs['Emission Strength'].default_value=.45
    materials[role]=mat
stats=[]
for path in sorted((R/'baseline'/('stage23_'+short)).glob('*.glb')):
    if props_only and path.stem.startswith(family): continue
    old=set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(path))
    imported=[o for o in bpy.data.objects if o not in old and o.type=='MESH']
    points=[o.matrix_world@Vector(c) for o in imported for c in o.bound_box]
    before_min=[min(p[i] for p in points) for i in range(3)]
    before_max=[max(p[i] for p in points) for i in range(3)]
    before=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in imported)
    grouped={}; details=[]
    for obj in imported:
        original=obj.data.materials[0].name
        prefix='Training_' if short=='training' else 'Scripture_'
        role=next((key for key in sorted(MAP,key=len,reverse=True) if original.startswith(prefix+key)),None)
        assert role is not None, original
        target=MAP[role]
        preserved = short=='training' and role in ['CourtPaving','Paving','PackedEarth','Joint']
        old_tri=sum(len(p.vertices)-2 for p in obj.data.polygons)
        bm=bmesh.new(); bm.from_mesh(obj.data)
        # The preserved Pavilion Timber input has duplicate/near-duplicate
        # endpoints (104 near-zero triangles, 16 exactly zero). Float32 export
        # leaves some endpoints ~1 micrometre apart. Weld that batch at 2 µm
        # before dissolve/triangulation, rather than deleting output triangles.
        # Other batches keep the original 0.1 µm seam tolerance.
        weld_distance=2e-6 if short=='pavilion' and role=='Timber' else 1e-7
        bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=weld_distance)
        # Do not change the repaired thin ground layers at all. Elsewhere only
        # dissolve near-coplanar subdivision, never collapse silhouette vertices.
        angle=math.radians(10 if role=='TileEdge' else 2)
        if not preserved:
            bmesh.ops.dissolve_limit(bm,angle_limit=angle,use_dissolve_boundaries=False,verts=list(bm.verts),edges=list(bm.edges),delimit=set())
        bmesh.ops.triangulate(bm,faces=list(bm.faces))
        deg=[f for f in bm.faces if f.calc_area()<1e-10]
        if deg: bmesh.ops.delete(bm,geom=deg,context='FACES_ONLY')
        bm.to_mesh(obj.data); bm.free(); obj.data.update()
        for p in obj.data.polygons: p.use_smooth=False
        # Imported GLBs carry explicit custom corner normals. Polygon shading
        # flags alone do not clear these; glTF would export the old smoothing.
        bpy.context.view_layer.objects.active=obj
        if obj.data.has_custom_normals: bpy.ops.mesh.customdata_custom_splitnormals_clear()
        obj.data.materials.clear(); obj.data.materials.append(materials[target])
        # The runtime explicitly recognizes these exact node names for ground
        # shadows/LOD behavior. Never merge them into other palette batches.
        key=prefix+role if preserved else target
        grouped.setdefault(key,[]).append(obj)
        details.append({'original_role':role,'target':target,'before':old_tri,'after':len(obj.data.polygons),'ground_batch_preserved':preserved,'seam_weld_tolerance_m':weld_distance})
    col=bpy.data.collections.new(path.stem); scene.collection.children.link(col)
    exported=[]
    for key,objects in grouped.items():
        bpy.ops.object.select_all(action='DESELECT')
        for obj in objects: obj.select_set(True)
        bpy.context.view_layer.objects.active=objects[0]
        if len(objects)>1: bpy.ops.object.join()
        obj=bpy.context.view_layer.objects.active
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
        obj.name=key if key.startswith('Training_') else path.stem+'_'+key
        for previous in list(obj.users_collection): previous.objects.unlink(obj)
        col.objects.link(obj); exported.append(obj)
    points=[o.matrix_world@Vector(c) for o in exported for c in o.bound_box]
    after_min=[min(p[i] for p in points) for i in range(3)]
    after_max=[max(p[i] for p in points) for i in range(3)]
    assert max(abs(a-b) for a,b in zip(before_min+before_max,after_min+after_max))<.0001, path.name
    bpy.ops.object.select_all(action='DESELECT')
    for obj in exported: obj.select_set(True)
    bpy.context.view_layer.objects.active=exported[0]
    bpy.ops.export_scene.gltf(filepath=str(OUT/path.name),export_format='GLB',use_selection=True,export_yup=True,export_materials='EXPORT',export_texcoords=False,export_normals=True)
    stats.append({'file':path.name,'triangles_before':before,'triangles_after':sum(len(o.data.polygons) for o in exported),'surfaces_after':len(exported),'bounds_before_blender':[before_min,before_max],'bounds_after_blender':[after_min,after_max],'roles':details})
    for obj in exported: obj.hide_set(path.stem!=family)
if not props_only:
    # Remove unused imported datablocks, keeping only editable palette meshes.
    for mesh in list(bpy.data.meshes):
        if mesh.users==0: bpy.data.meshes.remove(mesh)
    for mat in list(bpy.data.materials):
        if mat.users==0: bpy.data.materials.remove(mat)
    for image in list(bpy.data.images):
        if image.users==0: bpy.data.images.remove(image)
    bpy.ops.wm.save_as_mainfile(filepath=str(R/'source'/(family+'_low_poly.blend')))
(E/(short+('-props' if props_only else '')+'-build.json')).write_text(json.dumps({'models':stats,'palette':COLORS,'material_map':MAP,'preserved':'All architecture envelopes, protected ground node names, prop feet/hinge origins. No runtime/JSON/settings changes.','geometry_method':'Weld coincident seams; limited dissolve 2 degrees (10 on roof ribs), flat normals; no collapse decimation. Training repaired ground layers excluded from dissolve.'},indent=2))
print(short,'props' if props_only else 'complete',[(s['file'],s['triangles_after']) for s in stats])

extends SceneTree
## Read actual model triangles in the two failing detail regions; never re-export.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var asset: Node3D=load("res://scenes/buildings/medicine_hall.tscn").instantiate()
	root.add_child(asset)
	var regions: Array[AABB]=[
		AABB(Vector3(-7.82,-.01,-2.15),Vector3(1.44,4.55,5.6)),
		AABB(Vector3(-6.0,6.15,.5),Vector3(12.1,.62,2.4))]
	var faces:=PackedVector3Array()
	var region_triangles: Array[int]=[0,0]
	for mi: MeshInstance3D in asset.find_children("*","MeshInstance3D",true,false):
		for s in mi.mesh.get_surface_count():
			var a: Array=mi.mesh.surface_get_arrays(s)
			var vertices: PackedVector3Array=a[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array=a[Mesh.ARRAY_INDEX]
			for t in range(0,indices.size(),3):
				var tri: Array[Vector3]=[]
				for k in 3:tri.append(mi.global_transform*vertices[indices[t+k]])
				for region in regions.size():
					if tri.all(func(v):return regions[region].has_point(v)):
						for v: Vector3 in tri:faces.append(v)
						region_triangles[region]+=1;break
	assert(region_triangles.all(func(n):return n>0))
	var shape:=ConcavePolygonShape3D.new();shape.set_faces(faces)
	var result:=ResourceSaver.save(shape,"res://assets/architecture/medicine_hall/medicine_camera_obstructions.tres")
	FileAccess.open("res://reports/codex-alchemy-medicine/camera-shape.json",FileAccess.WRITE).store_string(JSON.stringify({"saved":result==OK,"triangles_by_region":region_triangles,"triangles":faces.size()/3,"source":"Actual unchanged Medicine Hall model; stair detail and hanging-herb regions only","requires_player_exception":"camera_only_obstruction group: body ignores, unchanged camera query still sees collision layer 1"},"  "))
	print("Camera detail triangles: ",region_triangles," save=",result)
	quit(0 if result==OK else 1)

extends SceneTree
## Focused data comparison; no gallery, foundation-ray or stair regression suite.
const OUT := "res://phase4c/review/mountain-profile/"
var checks: Array = []
func _initialize() -> void: call_deferred("run")
func check(label: String,passed: bool,detail: Variant = null) -> void:
	checks.append({"check":label,"pass":passed,"detail":detail})
	print("PASS " if passed else "FAIL ",label," ",detail)
func run() -> void:
	var previous: ArrayMesh = load(OUT+"previous-resources/terrain_mesh.res")
	var current: ArrayMesh = load("res://phase4c/resources/terrain_mesh.res")
	var old: PackedVector3Array = previous.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var now: PackedVector3Array = current.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	check("Terrain topology and extent unchanged",old.size()==now.size() and previous.get_aabb().position.x==current.get_aabb().position.x and previous.get_aabb().size.x==current.get_aabb().size.x and previous.get_aabb().position.z==current.get_aabb().position.z and previous.get_aabb().size.z==current.get_aabb().size.z,now.size())
	var protected_changed := 0
	var horizontal_changed := 0
	var total_changed := 0
	var protected_samples := 0
	for i in now.size():
		if old[i].x!=now[i].x or old[i].z!=now[i].z: horizontal_changed += 1
		if old[i]!=now[i]: total_changed += 1
		if old[i].x>=-156 and old[i].x<=156 and old[i].z>=-170 and old[i].z<=190:
			protected_samples += 1
			if old[i]!=now[i]: protected_changed += 1
	check("All occupied-shelf and route-envelope vertices identical",protected_changed==0,{"protected_vertices":protected_samples,"changed":protected_changed,"backdrop_vertices_changed":total_changed})
	check("Only vertical terrain positions changed",horizontal_changed==0)
	var shape: ConcavePolygonShape3D = load("res://phase4c/resources/terrain_collision.res")
	var faces := shape.get_faces()
	var max_error := 0.0
	for i in now.size(): max_error = maxf(max_error,now[i].distance_to(faces[i]))
	check("Visible and physical terrain agree within 0.1 mm",max_error<.0001,max_error)
	if DisplayServer.get_name()!="headless":
		var pines_preserved := true
		var count := 0
		var seated := 0
		for name: String in ["Mountain_pine_tiered_00","Mountain_pine_tiered_01","Mountain_pine_tiered_02","Mountain_pine_windswept_00","Mountain_pine_windswept_01","Mountain_pine_windswept_02"]:
			var a: MultiMesh = load(OUT+"previous-resources/"+name+".res")
			var b: MultiMesh = load("res://phase4c/resources/"+name+".res")
			pines_preserved = pines_preserved and a.instance_count==b.instance_count
			for i in a.instance_count:
				var pa := a.get_instance_transform(i)
				var pb := b.get_instance_transform(i)
				pines_preserved = pines_preserved and pa.basis==pb.basis and pa.origin.x==pb.origin.x and pa.origin.z==pb.origin.z
				count += 1
				if pa.origin.y!=pb.origin.y: seated += 1
		check("Existing pines retain count, horizontal placement, rotation and scale",pines_preserved,{"instances":count,"vertically_seated":seated})
	var failed := checks.filter(func(c):return not c.pass).size()
	var f := FileAccess.open(OUT+"unchanged-geometry.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"passes":checks.size()-failed,"failures":failed,"checks":checks},"\t"))
	quit(1 if failed else 0)

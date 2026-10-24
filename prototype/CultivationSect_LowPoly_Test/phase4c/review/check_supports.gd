extends SceneTree
## Short, focused checks of new support assemblies and inherited layout contracts.
var checks: Array = []
func _initialize() -> void: call_deferred("run")
func check(label: String, passed: bool, detail: Variant = null) -> void:
	checks.append({"check":label,"pass":passed,"detail":detail})
	print("PASS " if passed else "FAIL ",label," ",detail if detail!=null else "")
func run() -> void:
	var approved: Node3D = load("res://mountain_valley_compact/compact_valley.tscn").instantiate()
	var scene: Node3D = load("res://phase4c/phase4c_valley.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	for i in 12: await physics_frame
	scene.player.automated = true
	var poses_same := true
	for building: Node3D in approved.get_node("Buildings").get_children():
		poses_same = poses_same and building.transform.is_equal_approx(scene.get_node("Buildings").get_node(NodePath(building.name)).transform)
	check("All twelve building transforms equal approved compact baseline",poses_same)
	var baseline_ramp: ConcavePolygonShape3D = approved.get_node("SmoothPathRampCollision").get_child(0).shape
	var ramp: ConcavePolygonShape3D = scene.get_node("SmoothPathRampCollision").get_child(0).shape
	check("Approved smooth walking ramps retained exactly",baseline_ramp.get_faces()==ramp.get_faces())
	var ground: ConcavePolygonShape3D = scene.get_node("ValleyGroundCollision").get_child(0).shape
	var mesh: Mesh = scene.get_node("ContinuousValleyTerrain").mesh
	var physical_faces := ground.get_faces()
	var visible_faces := mesh.get_faces()
	var maximum_difference := 0.0
	if physical_faces.size()==visible_faces.size():
		for i in physical_faces.size(): maximum_difference = maxf(maximum_difference,physical_faces[i].distance_to(visible_faces[i]))
	else: maximum_difference = INF
	check("Visible and physical ground match within 0.1 mm",maximum_difference<.0001,{"physical_vertices":physical_faces.size(),"visible_vertices":visible_faces.size(),"maximum_difference_m":maximum_difference})
	var unit_yaw_only := true
	var module_count := 0
	for piece: Node3D in scene.get_node("SelectiveTerrainSupports").get_children():
		if piece.scene_file_path.is_empty(): continue
		module_count += 1
		unit_yaw_only = unit_yaw_only and piece.scale.is_equal_approx(Vector3.ONE) and absf(piece.rotation.x)<.0001 and absf(piece.rotation.z)<.0001
	check("Kit instances have original scale and upright posts",unit_yaw_only,module_count)
	# Waist-height rays distinguish the actual rail collider from the lower stone
	# strip or retaining wall that can also stop the full-height player capsule.
	var excluded: Array[RID] = [scene.player.get_rid()]
	for row: Array in [
		["Hall retaining rail",Vector3(-12,24,-46.18),Vector3.BACK],
		["Living retaining rail",Vector3(32,10,65.82),Vector3.BACK],
		["Overlook rail",Vector3(146.82,10,-45.82),Vector3.RIGHT],
		["Living stair rail",Vector3(4.35,7,57.5),Vector3.RIGHT],
		["Hall stair rail",Vector3(5.65,20,-38),Vector3.LEFT]]:
		var origin: Vector3 = row[1]+Vector3.UP*.7
		var query := PhysicsRayQueryParameters3D.create(origin,origin+row[2]*4,1,excluded)
		var hit := scene.get_world_3d().direct_space_state.intersect_ray(query)
		var collider := "" if hit.is_empty() else str(hit.collider.get_path())
		check(row[0]+" has waist-height collision","/SelectiveTerrainSupports/rail_" in collider,collider)
	approved.free()
	var failures := checks.filter(func(c): return not c.pass).size()
	var file := FileAccess.open("res://phase4c/review/support-results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passes":checks.size()-failures,"failures":failures,"checks":checks},"\t"))
	quit(1 if failures else 0)

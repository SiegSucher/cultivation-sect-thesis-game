extends "res://phase4c/review/check_terrain.gd"
## Main demonstration route, representative branches, and changed ground only.
const OUT := "res://phase4d/review/"
func run() -> void:
	scene = load("res://phase4d/phase4d_valley.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(12)
	player = scene.player
	check("Phase 4D launch and original walking speed",player.camera.current and player.speed==4)
	await press(KEY_TAB)
	check("Tab first person",not player.third_person)
	await press(KEY_TAB)
	check("Tab third person",player.third_person)
	check("Medicine camera-only walking exception preserved",player.get_collision_exceptions().size()==1)
	player.automated = true
	await main_route(true)
	await walk_to(Vector3(12,24,-58))
	await follow("scholar")
	await follow("elder")
	await follow("elder",true)
	await follow("library")
	await follow("library",true)
	await follow("scholar",true)
	await walk_to(Vector3(12,24,-47))
	await follow("grand",true)
	await walk_to(Vector3(12,16,-24))
	await follow("alchemy")
	await follow("alchemy",true)
	await walk_to(Vector3(12,16,-29))
	await follow("cloud",true)
	await walk_to(Vector3(0,10,35))
	await walk_to(Vector3(-44,10,35))
	await follow("training_link")
	await follow("training_entry")
	await follow("training_entry",true)
	await follow("training_link",true)
	await walk_to(Vector3(0,10,35))
	await walk_to(Vector3(65,10,35))
	await follow("garden")
	check_local_support()
	var baseline: Node3D = load("res://phase4c/phase4c_valley.tscn").instantiate()
	var transforms_same := true
	for building: Node3D in baseline.get_node("Buildings").get_children():
		transforms_same = transforms_same and building.transform==scene.get_node("Buildings/"+str(building.name)).transform
	check("All twelve approved building transforms preserved",transforms_same)
	for name: String in ["ContinuousValleyTerrain","RoadsCourtsAndVisibleStairs"]:
		check("Approved resource inherited: "+name,baseline.get_node(name).mesh==scene.get_node(name).mesh)
	for name: String in ["ValleyGroundCollision","SmoothPathRampCollision"]:
		check("Approved collision inherited: "+name,baseline.get_node(name).get_child(0).shape==scene.get_node(name).get_child(0).shape)
	check("No additional collision shapes",scene.get_node("DistrictEntranceConnections").find_children("*","CollisionShape3D",true,false).is_empty())
	baseline.free()
	var failed := checks.filter(func(c): return not c.pass).size()
	var f := FileAccess.open(OUT+"route-results.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"passes":checks.size()-failed,"failures":failed,"main_route_runs":main_runs,"checks":checks},"\t"))
	print("PHASE4D ROUTES ",checks.size()-failed," PASS / ",failed," FAIL")
	quit(1 if failed else 0)

func check_local_support() -> void:
	var excluded: Array[RID] = []
	for body: CollisionObject3D in scene.find_children("*","CollisionObject3D",true,false):
		if body!=scene.get_node("ValleyGroundCollision"): excluded.append(body.get_rid())
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://phase4d/entrances.json"))
	for row: Dictionary in rows:
		if row.apron==null: continue
		var p: Dictionary = row.apron
		var building: Node3D = scene.get_node("Buildings/"+row.id)
		var lo := INF
		var hi := -INF
		var supported := true
		# Centre plus near-corner samples on each short ground connection.
		for sample: Vector2 in [Vector2(0,.5),Vector2(-.95,.02),Vector2(.95,.02),Vector2(-.95,.98),Vector2(.95,.98)]:
			var local := Vector3(sample.x*lerpf(p.width_outer,p.width_inner,sample.y)*.5,0,lerpf(p.outer,p.inner,sample.y))
			var world: Vector3 = building.transform*local
			var query := PhysicsRayQueryParameters3D.create(world+Vector3.UP,world-Vector3.UP,1,excluded)
			var hit := scene.get_world_3d().direct_space_state.intersect_ray(query)
			if hit.is_empty(): supported = false
			else:
				var difference: float = hit.position.y-world.y
				lo = minf(lo,difference)
				hi = maxf(hi,difference)
				supported = supported and difference>=-.11 and difference<.02
		check("Existing ground supports local surface "+row.id,supported,{"samples":5,"ground_relative_to_terrace_m":[lo,hi]})

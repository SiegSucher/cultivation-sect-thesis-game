extends "res://phase4c/review/check_terrain.gd"
## Only intended exterior approaches and selected already-supported entrances.
const OUT := "res://phase4d/review/"
var rows: Array
func run() -> void:
	before = "--before" in OS.get_cmdline_user_args()
	scene = load("res://phase4c/phase4c_valley.tscn" if before else "res://phase4d/phase4d_valley.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(12)
	player = scene.player
	player.automated = true
	rows = JSON.parse_string(FileAccess.get_file_as_string("res://phase4d/entrances.json"))
	for row: Dictionary in rows:
		var building: Node3D = scene.get_node("Buildings/"+row.id)
		player.third_person = true
		scene.jump_to(building.transform*(vec(row.anchor)+Vector3.UP*.12),building.rotation.y)
		await frames(8)
		check("Exterior route-to-foot "+row.id,await walk_to(building.transform*vec(row.foot)),{"end":player.position})
		check("Existing building entrance/stairs "+row.id,await walk_to(building.transform*vec(row.porch)),{"end":player.position})
		if "inside" in row:
			var entered := true
			if "doorway" in row: entered = await walk_to(building.transform*vec(row.doorway))
			entered = await walk_to(building.transform*vec(row.inside)) and entered
			check("Representative supported interior "+row.id,entered,{"end":player.position})
			player.third_person = false
			var returned := true
			if "doorway" in row: returned = await walk_to(building.transform*vec(row.doorway))
			returned = await walk_to(building.transform*vec(row.porch)) and returned
			returned = await walk_to(building.transform*vec(row.foot)) and returned
			returned = await walk_to(building.transform*vec(row.anchor)) and returned
			check("Representative first-person exit "+row.id,returned,{"end":player.position})
	var failed := checks.filter(func(c): return not c.pass).size()
	var f := FileAccess.open(OUT+("before-entries.json" if before else "after-entries.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"passes":checks.size()-failed,"failures":failed,"checks":checks},"\t"))
	print("PHASE4D ENTRIES ",checks.size()-failed," PASS / ",failed," FAIL")
	quit(1 if failed else 0)

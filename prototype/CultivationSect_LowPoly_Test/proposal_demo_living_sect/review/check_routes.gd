extends "res://proposal_demo_living_sect/review/walk_boundary.gd"
## Focused route check after composing props; boundary geometry has not changed.
func run() -> void:
	demo = load("res://proposal_demo_living_sect/proposal_demo.tscn").instantiate()
	root.add_child(demo)
	current_scene = demo
	for i in 10: await physics_frame
	player = demo.player
	await put(Vector2(0, 108))
	var gate_ok := await walk_to(Vector2(0, 94)) and await walk_to(Vector2(0, 80)) and await walk_to(Vector2(0, 70))
	check("Gate passage: forest stair through Gate into arrival court", gate_ok, player.position)
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://mountain_valley_compact/layout.json"))
	for path: Dictionary in layout.paths:
		if path.id not in ["middle_stairs", "living", "street", "cloud", "grand", "hall", "training_link", "garden"]: continue
		var result := await walk_path(path.points)
		check("walk path: "+path.name, result[0], result)
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks": checks.size(), "failures": failures, "results": checks}, "  "))
	f.close()
	quit(1 if failures else 0)

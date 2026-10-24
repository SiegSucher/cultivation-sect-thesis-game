extends "res://phase4c/review/check_terrain.gd"
## Only launch, three matching views, and continuous main-route walking.
const OUT := "res://phase4c/review/mountain-profile/"

func capture(name: String) -> void:
	for i in 5: await RenderingServer.frame_post_draw
	check("Capture "+name,root.get_texture().get_image().save_png(OUT+("before-" if before else "after-")+name+".png")==OK)

func run() -> void:
	before = "--before" in OS.get_cmdline_user_args()
	scene = load(ROOT+"phase4c_valley.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(12)
	player = scene.player
	player.automated = true
	check("Phase 4C launches",player.camera.current and player.is_physics_processing())
	if DisplayServer.get_name()=="headless":
		# Continuous normal physical movement; no review jumps between landmarks.
		await main_route(true)
		await main_route(false)
	else:
		for view: Array in [["healing-overlook",Vector3(143,10.12,-46),PI/2],["hall-approach",Vector3(12,24.12,-49),0.0]]:
			scene.jump_to(view[1],view[2])
			await frames(12)
			await capture(view[0])
		scene.valley_view()
		await capture("valley-overview")
	var failed := checks.filter(func(c): return not c.pass).size()
	var suffix := "walking" if DisplayServer.get_name()=="headless" else ("before-captures" if before else "after-captures")
	var f := FileAccess.open(OUT+suffix+".json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"passes":checks.size()-failed,"failures":failed,"main_route_runs":main_runs,"checks":checks},"\t"))
	print("MOUNTAIN PROFILE ",checks.size()-failed," PASS / ",failed," FAIL")
	quit(1 if failed else 0)

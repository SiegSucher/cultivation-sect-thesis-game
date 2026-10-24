extends "res://phase4c/review/check_terrain.gd"
## Inspect assembled canonical buildings, not the separate gallery fixtures.
const OUT := "res://phase4d/review/"
var after := false
func _initialize() -> void: call_deferred("run")
func frames(n: int = 10) -> void:
	for i in n: await physics_frame
func capture(name: String) -> void:
	for i in 4: await RenderingServer.frame_post_draw
	check("Capture "+name,root.get_texture().get_image().save_png(OUT+("after-" if after else "before-")+name+".png")==OK)
func run() -> void:
	after = "--after" in OS.get_cmdline_user_args()
	scene = load("res://phase4d/phase4d_valley.tscn" if after else "res://phase4c/phase4c_valley.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(12)
	player = scene.player
	if after:
		check("Rendered Phase 4D launch",player.camera.current and player.is_physics_processing())
		await press(KEY_TAB)
		check("Rendered Tab first person",not player.third_person)
		await press(KEY_TAB)
		check("Rendered Tab third person",player.third_person)
	scene.player.automated = true
	var records: Array = []
	for b: Dictionary in scene.layout.buildings:
		var building: Node3D = scene.get_node("Buildings/"+b.id)
		var front: float = b.bounds.max[2]
		var at: Vector3 = building.transform*Vector3(0,.12,front+6)
		scene.jump_to(at,deg_to_rad(b.yaw))
		await frames(12)
		await capture(b.id+"-gameplay")
		scene.player.set_physics_process(false)
		scene.review_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		scene.review_camera.fov = 58
		var width: float = b.bounds.size[0]
		var depth: float = b.bounds.size[2]
		scene.review_camera.position = building.transform*Vector3(width*.78,maxf(5,b.bounds.size[1]*.55),front+maxf(12,depth*.75))
		scene.review_camera.look_at(building.transform*Vector3(0,1,1))
		scene.review_camera.make_current()
		await capture(b.id+"-context")
		records.append({"id":b.id,"scene":building.scene_file_path,"position":building.position,"scale":building.scale,"front_local_z":front})
		if after and b.id in ["mission_hall","medicine_hall"]:
			for third in [true,false]:
				player.third_person = third
				scene.jump_to(building.transform*Vector3(0,.12,front+2),deg_to_rad(b.yaw))
				await frames(8)
				var target := Vector3(0,.75,2.8) if b.id=="mission_hall" else Vector3(-1,.45,3.6)
				check("Rendered entry "+b.id+(" TPP" if third else " FPP"),await walk_to(building.transform*target))
			player.third_person = true
	var f := FileAccess.open(OUT+("after-inspection-record.json" if after else "inspection-record.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"buildings":records,"medicine_exception_count":scene.player.get_collision_exceptions().size(),"scene":"Phase4D" if after else "Phase4C"},"\t"))
	var failed := checks.filter(func(c): return not c.pass).size()
	var result := FileAccess.open(OUT+("rendered-results.json" if after else "inspection-results.json"),FileAccess.WRITE)
	result.store_string(JSON.stringify({"passes":checks.size()-failed,"failures":failed,"checks":checks},"\t"))
	print("Captured all twelve assembled buildings, gameplay and context; after=",after)
	quit(1 if failed else 0)

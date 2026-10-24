extends SceneTree
## One-area proposal smoke check, not a building-gallery/collision certification.
const OUT := "res://reports/phase4a/"
var scene: Node3D
var player: CharacterBody3D
var checks: Array = []
var rendered := false

func _initialize() -> void: call_deferred("run")

func frames(n: int = 5) -> void:
	for i in n: await physics_frame

func check(label: String, passed: bool, detail: Variant = null) -> void:
	checks.append({"check":label,"pass":passed,"detail":detail})
	print("PASS " if passed else "FAIL ",label," ",detail if detail != null else "")

func press(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await frames(2)
	event = InputEventKey.new()
	event.physical_keycode = code
	Input.parse_input_event(event)
	await frames(2)

func shot(label: String) -> void:
	if not rendered: return
	for i in 4: await RenderingServer.frame_post_draw
	check("Screenshot "+label,root.get_texture().get_image().save_png(OUT+label+".png")==OK)

func walk_to(target: Vector3, label: String) -> void:
	var started := player.position
	var best := 1000.0
	for i in 1500:
		var delta := target-player.position
		delta.y = 0
		best = delta.length()
		if best < .22: break
		player.drive = delta.normalized()
		player.yaw = atan2(-delta.x,-delta.z)
		await physics_frame
	player.drive = Vector3.ZERO
	await frames(8)
	check(label,best<.35 and player.is_on_floor(),{"remaining_m":best,"height":player.position.y,"travel_m":started.distance_to(player.position)})

func run() -> void:
	rendered = DisplayServer.get_name() != "headless"
	scene = load("res://phase4a/main_sect_hall_environment.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(12)
	player = scene.player
	check("Scene starts in playable third person",player.third_person and player.camera.current and player.is_physics_processing() and player.avatar.visible)
	check("Hall keeps identity transform",scene.hall.transform==Transform3D.IDENTITY)
	var ids := {}
	for node in scene.get_node("EnvironmentAssembly").get_children():
		var path: String = node.scene_file_path
		ids[path.get_file().get_basename()] = true
	check("All eleven existing environmental scenes instanced",ids.size()==11,ids.keys())
	var before: Vector3 = player.position
	var event := InputEventKey.new()
	event.physical_keycode = KEY_W
	event.pressed = true
	Input.parse_input_event(event)
	await frames(35)
	event = InputEventKey.new()
	event.physical_keycode = KEY_W
	Input.parse_input_event(event)
	await frames(4)
	check("W moves the walking player",before.distance_to(player.position)>1.0)
	await press(KEY_TAB)
	check("Tab switches to first person",not player.third_person and not player.avatar.visible)
	await press(KEY_TAB)
	check("Tab returns to third person",player.third_person and player.avatar.visible)
	await press(KEY_2)
	check("Approach preset opens",scene.review_camera.current and not player.is_physics_processing())
	await shot("01-hall-approach")
	await press(KEY_3)
	await shot("02-courtyard")
	await press(KEY_1)
	check("Walk resumes after overview",player.camera.current and player.is_physics_processing())
	player.automated = true
	player.position = Vector3(0,.05,49)
	await frames()
	await walk_to(Vector3(0,0,43),"Walk southern approach")
	player.pitch = -.10
	player.yaw = 0
	player.update_camera()
	await shot("03-third-person-gameplay")
	await walk_to(Vector3(0,0,30),"Walk into open courtyard")
	player.third_person = false
	player.update_camera()
	await shot("04-first-person-approach")
	await walk_to(Vector3(0,0,19),"Walk across clear courtyard to stair toe")
	await walk_to(Vector3(0,0,12),"Climb existing Hall front stairs")
	await walk_to(Vector3(0,0,5),"Enter existing Hall through open entrance")
	await walk_to(Vector3(0,0,22),"Return from Hall to courtyard")
	player.third_person = true
	await walk_to(Vector3(-14,0,29),"Explore western bench pocket")
	await walk_to(Vector3(0,0,33),"Cross open courtyard")
	await walk_to(Vector3(14,0,30),"Explore practice corner")
	scene.use_view(2)
	await shot("05-garden-corner")
	player.automated = false
	await press(KEY_R)
	check("R returns to safe approach spawn",player.camera.current and player.position.distance_to(Vector3(0,0,49))<.2)
	var failed := checks.filter(func(c): return not c.pass).size()
	var result := {"rendered":rendered,"passes":checks.size()-failed,"failures":failed,"checks":checks}
	var f := FileAccess.open(OUT+("rendered-results.json" if rendered else "headless-results.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"\t"))
	print("PHASE4A ",result.passes," PASS / ",failed," FAIL")
	quit(1 if failed else 0)

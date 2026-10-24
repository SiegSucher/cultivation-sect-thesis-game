extends SceneTree
## Reachability and demonstration only. No building-interior/camera regression.
const OUT := "res://reports/mountain-valley-polish/"
var scene: Node3D
var player: CharacterBody3D
var checks: Array = []
var walk_samples := 0
var travelled := 0.0
var last := Vector3.ZERO

func _initialize() -> void: call_deferred("run")

func frames(n: int = 4) -> void:
	for i in n: await physics_frame

func check(label: String, passed: bool, detail: Variant = null) -> void:
	checks.append({"check":label,"pass":passed,"detail":detail})
	print("PASS " if passed else "FAIL ",label," ",detail if detail!=null else "")

func press(code: int) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	Input.parse_input_event(e)
	await frames(2)
	e = InputEventKey.new()
	e.physical_keycode = code
	Input.parse_input_event(e)
	await frames(2)

func walk_to(point: Vector3) -> bool:
	var gap := 1000.0
	var remaining := 0
	var limit := ceili(player.position.distance_to(point)/player.speed*Engine.physics_ticks_per_second*2)+240
	var previous_gap := 1000.0
	for i in limit:
		var delta := point-player.position
		delta.y = 0
		gap = delta.length()
		if gap<.24: break
		if absf(gap-previous_gap)<.0003: remaining += 1
		else: remaining = 0
		if remaining>90: break
		previous_gap = gap
		player.drive = delta.normalized()
		player.yaw = atan2(-delta.x,-delta.z)
		last = player.position
		await physics_frame
		travelled += player.position.distance_to(last)
		walk_samples += 1
	player.drive = Vector3.ZERO
	await frames(3)
	if gap>.35 or absf(player.position.y-point.y)>1.0:
		print("BLOCKED target ",point," at ",player.position," gap ",gap)
		return false
	return true

func follow(id: String, backwards: bool = false) -> bool:
	var route: Dictionary = {}
	for p: Dictionary in scene.layout.paths:
		if p.id==id: route = p
	var points: Array = route.points.duplicate()
	if backwards: points.reverse()
	for a: Array in points:
		if not await walk_to(Vector3(a[0],a[1],a[2])):
			check("Walk route: "+id+(" reverse" if backwards else ""),false)
			return false
	check("Walk route: "+id+(" reverse" if backwards else ""),true)
	return true

func shot(name: String) -> void:
	for i in 4: await RenderingServer.frame_post_draw
	check("Screenshot "+name,root.get_texture().get_image().save_png(OUT+name+".png")==OK)

func run() -> void:
	Engine.physics_ticks_per_second = 60
	scene = load("res://mountain_valley/mountain_valley.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(12)
	player = scene.player
	check("Separate scene opens in third-person walking",player.third_person and player.camera.current and player.is_physics_processing())
	check("All twelve canonical buildings instanced",scene.get_node("Buildings").get_child_count()==12)
	var scale_ok := true
	for node: Node3D in scene.get_node("Buildings").get_children():
		scale_ok = scale_ok and node.scale.is_equal_approx(Vector3.ONE)
	check("All building root scales remain one",scale_ok)
	check("Medicine camera-only exception retained",player.get_collision_exceptions().size()==1)
	var before: Vector3 = player.position
	var e := InputEventKey.new()
	e.physical_keycode = KEY_W
	e.pressed = true
	Input.parse_input_event(e)
	await frames(50)
	e = InputEventKey.new()
	e.physical_keycode = KEY_W
	Input.parse_input_event(e)
	await frames()
	check("W moves the existing controller",player.position.distance_to(before)>1)
	await press(KEY_TAB)
	check("Tab enters first person",not player.third_person)
	await press(KEY_TAB)
	check("Tab restores visible third person",player.third_person and player.avatar.visible)
	var headless := DisplayServer.get_name()=="headless"
	if headless:
		Engine.physics_ticks_per_second = 720
		Engine.time_scale = 12
		Engine.max_physics_steps_per_frame = 32
		player.automated = true
		scene.reset_start()
		await frames()
		for id: String in ["forest","entry_stairs","arrival","middle_stairs","living","cloud","grand","hall"]:
			if not await follow(id): break
		check("Reach Main Hall forecourt",player.position.distance_to(Vector3(0,48,-173))<1)
		await walk_to(Vector3(0,48,-139))
		await follow("scholar")
		await follow("library")
		check("Reach Scripture Pavilion",player.position.distance_to(Vector3(-110,56,-192))<1)
		await follow("library",true)
		await follow("elder")
		check("Reach Elder Residence",player.position.distance_to(Vector3(-140,56,-145))<1)
		await follow("elder",true)
		await follow("scholar",true)
		await walk_to(Vector3(0,48,-116))
		await follow("grand",true)
		await follow("alchemy")
		check("Reach Alchemy Pavilion",player.position.distance_to(Vector3(101,40,-105))<1)
		await follow("alchemy",true)
		await follow("cloud",true)
		await walk_to(Vector3(0,20,31))
		await follow("mission")
		check("Reach Mission Hall",player.position.distance_to(Vector3(-52,20,24))<1)
		await follow("mission",true)
		await follow("residence")
		check("Reach Disciples Residence",player.position.distance_to(Vector3(-64,20,49))<1)
		await follow("residence",true)
		await walk_to(Vector3(0,20,31))
		await follow("exchange")
		check("Reach Exchange Hall",player.position.distance_to(Vector3(30,20,17))<1)
		await follow("exchange",true)
		await follow("dining")
		check("Reach Dining Hall",player.position.distance_to(Vector3(48,20,45))<1)
		await follow("dining",true)
		await follow("garden")
		check("Reach Spirit Herb Garden",player.position.distance_to(Vector3(175,20,-57))<1)
		await follow("garden",true)
		# The Medicine threshold is on the shared garden route.
		await walk_to(Vector3(104,20,21))
		await walk_to(Vector3(123,20,3))
		check("Reach Medicine Hall",player.position.distance_to(Vector3(123,20,3))<1)
		await walk_to(Vector3(154,20,-33))
		await follow("overlook")
		check("Reach cliff overlook",player.position.distance_to(Vector3(207,20,-78))<1)
		await follow("overlook",true)
		await walk_to(Vector3(123,20,3))
		await walk_to(Vector3(104,20,21))
		await walk_to(Vector3(76,20,31))
		await walk_to(Vector3(0,20,31))
		await walk_to(Vector3(0,20,-5))
		await follow("training_link")
		await follow("training_entry")
		check("Reach Training Ground",player.position.distance_to(Vector3(-155,28,-19))<1)
		await follow("training_entry",true)
		await follow("training_link",true)
		await walk_to(Vector3(0,20,71))
		await follow("middle_stairs",true)
		await follow("arrival",true)
		check("Return through Sect Gate",player.position.distance_to(Vector3(0,8,145))<1)
	else:
		await shot("01-forest-third-person")
		scene.map_view()
		await frames()
		await shot("02-top-down-layout")
		scene.valley_view()
		await shot("03-valley-composition")
		scene.jump_to(Vector3(0,48.1,-123),0)
		await frames(12)
		await shot("04-main-hall-third-person")
		await press(KEY_TAB)
		await shot("05-main-hall-first-person")
		await press(KEY_TAB)
		scene.jump_to(Vector3(0,20.1,45),0)
		await frames(12)
		await shot("06-living-third-person")
		scene.jump_to(Vector3(202,20.1,-77),PI/2)
		await frames(12)
		await shot("07-garden-overlook")
		scene.jump_to(Vector3(0,.1,180),0)
		await frames(12)
		await shot("08-gate-third-person")
	Engine.physics_ticks_per_second = 60
	Engine.time_scale = 1
	player.automated = false
	await press(KEY_M)
	check("Map overview opens",scene.review_camera.current and not player.is_physics_processing())
	await press(KEY_M)
	check("Walking resumes with original camera",player.camera.current and player.is_physics_processing())
	await press(KEY_R)
	check("R returns to forest start",player.position.distance_to(Vector3(12,0,320))<.5)
	var failed := checks.filter(func(c): return not c.pass).size()
	var result := {"headless":headless,"passes":checks.size()-failed,"failures":failed,"walk_samples":walk_samples,"walked_metres":travelled,"checks":checks}
	var f := FileAccess.open(OUT+("walking-results.json" if headless else "rendered-results.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"\t"))
	print("VALLEY ",result.passes," PASS / ",failed," FAIL; walked ",travelled," m")
	quit(1 if failed else 0)



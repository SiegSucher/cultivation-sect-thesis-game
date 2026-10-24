extends SceneTree
## Focused proposal review. The existing player moves at its unchanged 4 m/s.
const ROOT := "res://mountain_valley_compact/"
var scene: Node3D
var player: CharacterBody3D
var checks: Array = []
var headless := false
var main_runs: Array = []
var travelled := 0.0
var active_walk_ticks := 0

func _initialize() -> void: call_deferred("run")
func frames(n: int = 6) -> void:
	for i in n: await physics_frame
func check(label: String, okay: bool, detail: Variant = null) -> void:
	checks.append({"check":label,"pass":okay,"detail":detail})
	print("PASS " if okay else "FAIL ",label," ",detail if detail!=null else "")
func vec(a: Array) -> Vector3: return Vector3(a[0],a[1],a[2])

func press(code: int) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	Input.parse_input_event(e)
	await frames(2)
	e = InputEventKey.new()
	e.physical_keycode = code
	Input.parse_input_event(e)
	await frames(3)

func walk_to(point: Vector3) -> bool:
	var gap := 1000.0
	var stalled := 0
	var previous: Vector3 = player.position
	var limit := int(player.position.distance_to(point)/4.0*120)+300
	for i in limit:
		var delta := point-player.position
		delta.y = 0
		gap = delta.length()
		if gap<.18: break
		player.drive = delta.normalized()
		player.yaw = atan2(-delta.x,-delta.z)
		await physics_frame
		active_walk_ticks += 1
		travelled += previous.distance_to(player.position)
		if previous.distance_to(player.position)<.0002: stalled += 1
		else: stalled = 0
		previous = player.position
		if stalled>70: break
	player.drive = Vector3.ZERO
	await frames(5)
	var okay := gap<.3 and absf(player.position.y-point.y)<.85 and player.is_on_floor()
	if not okay:
		var contacts: Array = []
		for i in player.get_slide_collision_count():
			var node: Object = player.get_slide_collision(i).get_collider()
			if node is Node: contacts.append(str(node.get_path()))
		print("BLOCKED ",point," at ",player.position," contacts ",contacts)
	return okay

func follow(id: String, reverse: bool = false) -> bool:
	var points: Array = []
	for route: Dictionary in scene.layout.paths:
		if route.id==id: points = route.points.duplicate()
	if reverse: points.reverse()
	for p: Array in points:
		if not await walk_to(vec(p)):
			check("Connection "+id+(" reverse" if reverse else ""),false)
			return false
	check("Connection "+id+(" reverse" if reverse else ""),true)
	return true

func main_route(third: bool) -> void:
	scene.reset_start()
	player.third_person = third
	await frames()
	var before := travelled
	var tick := Engine.get_physics_frames()
	var active_before := active_walk_ticks
	var okay := true
	for id: String in scene.layout.main_route_ids:
		if not await follow(id):
			okay = false
			break
	var result := {"camera":"TPP" if third else "FPP","walked_metres":travelled-before,"test_elapsed_seconds":float(Engine.get_physics_frames()-tick)/Engine.physics_ticks_per_second,"active_walking_seconds":float(active_walk_ticks-active_before)/Engine.physics_ticks_per_second,"pass":okay}
	main_runs.append(result)
	check("Continuous forest-to-Hall route "+result.camera,okay,result)

func foundations() -> void:
	var excluded: Array[RID] = []
	for node: Node in scene.find_children("*","CollisionObject3D",true,false):
		if node!=scene.get_node("ValleyGroundCollision"): excluded.append(node.get_rid())
	var samples: Array = []
	for b: Dictionary in scene.layout.buildings:
		var okay := true
		var actual: Array = []
		var box: Array = b.world_envelope
		for p: Vector2 in [Vector2(box[0],box[1]),Vector2(box[2],box[1]),Vector2(box[2],box[3]),Vector2(box[0],box[3])]:
			var y: float = b.position[1]
			var query := PhysicsRayQueryParameters3D.create(Vector3(p.x,y+1,p.y),Vector3(p.x,y-2,p.y),1,excluded)
			var hit := scene.get_world_3d().direct_space_state.intersect_ray(query)
			if hit.is_empty(): okay = false
			else:
				actual.append(hit.position.y-y)
				okay = okay and hit.position.y-y>=-.20 and hit.position.y-y<=.06
		check("Ground supports measured envelope: "+b.id,okay,actual)

func stairs() -> void:
	for id: String in ["entry_stairs","middle_stairs","grand"]:
		var route: Dictionary
		for p: Dictionary in scene.layout.paths:
			if p.id==id: route = p
		var a := vec(route.points[0])
		var b := vec(route.points[1])
		var direction := Vector3(b.x-a.x,0,b.z-a.z).normalized()
		var side := Vector3(-direction.z,0,direction.x)
		for offset: float in [-route.width*.32,route.width*.32]:
			scene.jump_to(b+side*offset-direction*-.8+Vector3.UP*.12)
			await frames()
			check("Stair downhill "+id+" side "+str(offset),await walk_to(a+side*offset-direction*.8))

func shot(name: String) -> void:
	for i in 4: await RenderingServer.frame_post_draw
	check("Screenshot "+name,root.get_texture().get_image().save_png(ROOT+"review/"+name+".png")==OK)

func run() -> void:
	headless = DisplayServer.get_name()=="headless"
	scene = load(ROOT+"compact_valley.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(12)
	player = scene.player
	check("Compact scene launches",player.camera.current and player.third_person and player.is_physics_processing())
	check("Walking speed remains 4 m/s",is_equal_approx(player.speed,4))
	var scale_ok := true
	for node: Node3D in scene.get_node("Buildings").get_children(): scale_ok = scale_ok and node.scale.is_equal_approx(Vector3.ONE)
	check("All twelve full-size building instances",scale_ok and scene.get_node("Buildings").get_child_count()==12)
	check("Medicine camera exception retained",player.get_collision_exceptions().size()==1)
	await press(KEY_TAB)
	check("Tab first person",not player.third_person)
	await press(KEY_TAB)
	check("Tab third person",player.third_person)
	player.automated = true
	if headless:
		foundations()
		await main_route(false)
		await main_route(true)
		await walk_to(Vector3(12,24,-58))
		await follow("scholar")
		await follow("library")
		await follow("library",true)
		await follow("elder")
		await follow("elder",true)
		await follow("scholar",true)
		await walk_to(Vector3(12,24,-47))
		await follow("grand",true)
		await walk_to(Vector3(12,16,-24))
		await follow("alchemy")
		await follow("alchemy",true)
		await walk_to(Vector3(12,16,-29))
		await follow("cloud",true)
		await walk_to(Vector3(0,10,35))
		await follow("mission")
		await follow("mission",true)
		await follow("residence")
		await follow("residence",true)
		await walk_to(Vector3(0,10,35))
		await follow("exchange")
		await follow("exchange",true)
		await follow("dining")
		await follow("dining",true)
		await follow("garden")
		await follow("garden",true)
		await walk_to(Vector3(83,10,25))
		await walk_to(Vector3(102,10,16))
		check("Medicine exterior reached",player.position.distance_to(Vector3(102,10,16))<1)
		await walk_to(Vector3(117,10,16))
		await walk_to(Vector3(121,10,-12))
		await follow("overlook")
		await follow("overlook",true)
		await walk_to(Vector3(117,10,16))
		await walk_to(Vector3(102,10,16))
		await walk_to(Vector3(83,10,25))
		await walk_to(Vector3(65,10,35))
		await walk_to(Vector3(0,10,35))
		await walk_to(Vector3(-44,10,35))
		await follow("training_link")
		await follow("training_entry")
		await follow("training_entry",true)
		await follow("training_link",true)
		await stairs()
	else:
		# Rendered checks use ordinary short walking and real camera switching;
		# full district walking is covered above without replaying a gallery suite.
		scene.jump_to(Vector3(0,.12,109),0)
		check("Rendered arrival stair up",await walk_to(Vector3(0,4,90)))
		await shot("01-gate-arrival")
		player.third_person = false
		check("Rendered arrival stair down FPP",await walk_to(Vector3(0,0,109)))
		player.third_person = true
		scene.jump_to(Vector3(0,10.1,42),0)
		await frames(8)
		await shot("02-living-district")
		scene.jump_to(Vector3(-43,10.1,35),.95)
		await frames(8)
		await shot("03-training-connection")
		scene.jump_to(Vector3(12,24.1,-49),0)
		await frames(8)
		await shot("04-main-hall-approach")
		scene.jump_to(Vector3(0,10.1,9),0)
		await frames(8)
		await shot("05-inner-stairs")
		scene.map_view()
		await shot("06-top-down")
		scene.valley_view()
		await shot("07-valley-overview")
		scene.jump_to(Vector3(142,10.1,-45),PI/2)
		await frames(8)
		await shot("08-healing-overlook")
	player.automated = false
	scene.set_walk()
	await press(KEY_M)
	check("Map opens",scene.review_camera.current)
	await press(KEY_M)
	check("Map resumes walking",player.camera.current and player.is_physics_processing())
	var failed := checks.filter(func(c): return not c.pass).size()
	var f := FileAccess.open(ROOT+"review/"+("walking-results.json" if headless else "rendered-results.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"passes":checks.size()-failed,"failures":failed,"main_route_runs":main_runs,"checks":checks},"\t"))
	print("COMPACT ",checks.size()-failed," PASS / ",failed," FAIL")
	quit(1 if failed else 0)

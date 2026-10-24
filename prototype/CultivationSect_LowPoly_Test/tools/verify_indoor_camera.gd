extends SceneTree
## Matched before/after inspection-camera experiment. Only in-memory test fixtures
## are moved; no building, staging file, existing report or import is rewritten.
const OUT := "res://reports/indoor-camera-fix/"
const FIXTURES := {
	"hall": "res://scenes/hall_experiment.tscn",
	"disciple": "res://scenes/review/disciple_residence_walkthrough.tscn",
	"alchemy": "res://scenes/review/alchemy_pavilion_walkthrough.tscn",
}
var checks: Array = []
var samples: Array = []
var points: Array = []
var routes: Array = []
var stage: Node3D
var player: CharacterBody3D
var asset := ""
var phase := "after"
var rendered := false
var visual: StaticBody3D
var legacy_matches := 0
var legacy_mismatches: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(label: String, ok: bool, detail: Variant = null) -> void:
	checks.append({"asset":asset,"check":label,"pass":ok,"detail":detail})
	if not ok: print("FAIL ", asset, " ", label, " ", detail)

func frames(count: int) -> void:
	for i in count: await physics_frame

func overlaps(radius: float, mask: int) -> Array:
	var ball := SphereShape3D.new()
	ball.radius = radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = ball
	query.transform.origin = player.camera.global_position
	query.collision_mask = mask
	query.exclude = [player.get_rid()]
	var names: Array = []
	for hit in stage.get_world_3d().direct_space_state.intersect_shape(query, 8):
		names.append(str(hit.collider.get_path()))
	return names

func sample(label: String) -> void:
	samples.append({"asset":asset,"label":label,"distance":player.camera_distance,
		"player":[player.position.x,player.position.y,player.position.z],
		"camera":[player.camera.global_position.x,player.camera.global_position.y,player.camera.global_position.z],
		"yaw":player.yaw,"pitch":player.pitch,"solid_hits":overlaps(.18,1),"visual_hits":overlaps(.16,8)})

func capture(label: String) -> void:
	if not rendered: return
	player.camera.make_current()
	for i in 3: await RenderingServer.frame_post_draw
	var file := OUT+phase+"-"+asset+"-"+label+".png"
	check("capture "+label,root.get_texture().get_image().save_png(file)==OK)

func reset(at: Vector3, third := true) -> void:
	player.set_physics_process(false)
	player.position = at
	player.velocity = Vector3.ZERO
	player.drive = Vector3.ZERO
	player.yaw = 0
	player.pitch = 0
	player.third_person = third
	player.update_camera()
	player.camera.make_current()
	player.set_physics_process(true)
	await frames(90)

func walk(label: String, target: Vector3) -> void:
	var count := 0
	while count < 420:
		var direction := target-player.position
		direction.y = 0
		if direction.length() < .10: break
		player.drive = direction.normalized()
		player.yaw = atan2(-direction.x,-direction.z)
		await physics_frame
		sample(label)
		count += 1
	player.drive = Vector3.ZERO
	await frames(5)
	var reached := Vector2(player.position.x-target.x,player.position.z-target.z).length()<.22 and absf(player.position.y-target.y)<.18 and player.is_on_floor()
	check("movement "+label,reached,str(player.position))
	routes.append({"asset":asset,"label":label,"frames":count,"reached":reached})

func add_visual_probe(building: Node3D) -> void:
	visual = StaticBody3D.new()
	visual.collision_layer = 8
	visual.collision_mask = 0
	stage.add_child(visual)
	for mesh: MeshInstance3D in building.find_children("*","MeshInstance3D",true,false):
		# Hall's alternate distance mesh occupies the same space; audit the near
		# representation only. These layer-8 copies do not affect the camera cast.
		if "DistantExterior" in str(mesh.get_path()): continue
		if not mesh.mesh: continue
		var shape := CollisionShape3D.new()
		shape.shape = mesh.mesh.create_trimesh_shape()
		shape.transform = mesh.global_transform
		visual.add_child(shape)

func static_sweep(at: Vector3) -> void:
	await reset(at)
	player.set_physics_process(false)
	for pitch: float in [-.35,0,.35]:
		for i in 24:
			player.yaw = i*TAU/24
			player.pitch = pitch
			player.update_camera()
			var entry := {"asset":asset,"yaw":player.yaw,"pitch":pitch,"distance":player.camera_distance,
				"solid_hits":overlaps(.18,1),"visual_hits":overlaps(.16,8)}
			points.append(entry)
			if phase == "after":
				# Compare the feature-off path with the actual pre-edit measurement,
				# rather than reimplementing the controller's old cast in this test.
				var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT+"before-headless.json"))
				var expected: Dictionary = old.points[points.size()-1]
				player.indoor_camera_enabled = false
				player.update_camera()
				if absf(player.camera_distance-expected.distance)<.002:
					legacy_matches += 1
				else: legacy_mismatches.append({"expected":expected,"actual":player.camera_distance})
				player.indoor_camera_enabled = true
				player.update_camera()
	player.yaw = 0
	player.pitch = 0
	player.update_camera()
	if phase == "after":
		check("level indoor camera frames head and feet",player.camera.is_position_in_frustum(player.global_position+Vector3(0,.05,0)) and player.camera.is_position_in_frustum(player.global_position+Vector3(0,1.8,0)))
	await capture("interior")
	player.set_physics_process(true)
	# A continuous full turn uses the real physics update, rather than only
	# calling the camera at isolated angles. Pitch varies through +/- 0.35 rad.
	for i in 180:
		player.yaw = i*TAU/180
		player.pitch = .35*sin(i*TAU/180)
		await physics_frame
		sample("continuous-turn")
	player.yaw = 0
	player.pitch = 0
	await frames(90)

func run_asset(id: String) -> void:
	asset = id
	stage = load(FIXTURES[id]).instantiate()
	if id != "alchemy": stage.automated = true
	root.add_child(stage)
	player = stage.player
	player.automated = true
	player.set_process_unhandled_input(false)
	var building: Node3D
	if id == "hall":
		building = stage.hall
		for door in building.doors: door.set_open_immediate(true)
	elif id == "disciple": building = stage.facility
	else: building = stage.asset
	add_visual_probe(building)
	await frames(8)
	var exterior: Vector3
	var interior: Vector3
	var waypoints: Array
	match id:
		"hall":
			exterior = Vector3(0,.05,24)
			interior = Vector3(0,1.54,4.8)
			waypoints = [Vector3(0,1.52,10),interior,Vector3(0,1.54,-2),interior,Vector3(0,1.52,10),Vector3(0,.03,24)]
		"disciple":
			exterior = Vector3(2.2,.05,8.5)
			interior = Vector3(2.2,.5,1.2)
			# Follow the clear aisle around the study table, then pass between the
			# beds. Going only just inside the door misses lintel/boom compression.
			waypoints = [Vector3(2.2,.5,3),interior,Vector3(3.1,.5,1.2),Vector3(3.1,.5,-1),Vector3(2.2,.5,-1),Vector3(2.2,.5,-2),Vector3(2.2,.5,-1),Vector3(3.1,.5,-1),Vector3(3.1,.5,1.2),interior,Vector3(2.2,.5,3),Vector3(2.2,.03,8.5)]
		_:
			exterior = Vector3(0,.05,12)
			interior = Vector3(0,.9,3.5)
			waypoints = [Vector3(0,.9,6.7),interior,Vector3(3.2,.9,2.6),Vector3(3.5,.9,0),Vector3(3.2,.9,2.6),interior,Vector3(0,.9,6.7),Vector3(0,.03,12)]
	await reset(exterior)
	var outdoor_distance: float = player.camera_distance
	check("outdoor effective boom preserved",absf(outdoor_distance-Vector3(0,.72,4.3).length()*.975)<.005,outdoor_distance)
	await capture("outdoor")
	await static_sweep(interior)
	await reset(exterior)
	for i in waypoints.size():
		await walk("route-"+str(i),waypoints[i])
		if i == 0 or i == 1: await capture("route-"+str(i))
	await frames(150)
	check("outdoor boom recovers after exit",absf(player.camera_distance-outdoor_distance)<.015,player.camera_distance)
	await reset(interior,false)
	var eye: Vector3 = player.global_position+Vector3(0,1.65,0)
	check("first-person eye unchanged",player.camera.global_position.distance_to(eye)<.0001 and player.camera_distance==0 and not player.avatar.visible)
	# Exercise the actual existing Tab handler; this is programmatic input,
	# not a claim that a person played the scene.
	player.automated = false
	var tab := InputEventKey.new()
	tab.physical_keycode = KEY_TAB
	tab.pressed = true
	player._unhandled_input(tab)
	player.automated = true
	await frames(90)
	check("Tab restores third person",player.third_person and player.avatar.visible)
	stage.free()
	await process_frame

func run() -> void:
	var args := OS.get_cmdline_user_args()
	phase = "before" if "--before" in args else "after"
	rendered = "--rendered" in args
	root.size = Vector2i(1280,720)
	for id: String in FIXTURES: await run_asset(id)
	var solid_contacts := samples.filter(func(s):return not s.solid_hits.is_empty())
	check("moving/turning camera clears authored solids",solid_contacts.is_empty(),solid_contacts.slice(0,8))
	var point_contacts := points.filter(func(s):return not s.solid_hits.is_empty())
	check("static pitch/yaw sweep clears authored solids",point_contacts.is_empty(),point_contacts.slice(0,8))
	if phase == "after":
		check("feature-off matches 216 original camera poses",legacy_matches==216 and legacy_mismatches.is_empty(),legacy_mismatches)
		var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT+"before-headless.json"))
		var new_visual: Array = []
		for i in points.size():
			if not points[i].visual_hits.is_empty() and old.points[i].visual_hits.is_empty(): new_visual.append(points[i])
		check("no newly overlapping visible-mesh sweep poses",new_visual.is_empty(),new_visual)
		var door_before: Array = old.samples.filter(func(s):return s.asset=="disciple" and s.label=="route-5")
		var door_after: Array = samples.filter(func(s):return s.asset=="disciple" and s.label=="route-5")
		var jump_before := 0.0
		var jump_after := 0.0
		for i in range(1,door_before.size()): jump_before=maxf(jump_before,absf(door_before[i].distance-door_before[i-1].distance))
		for i in range(1,door_after.size()): jump_after=maxf(jump_after,absf(door_after[i].distance-door_after[i-1].distance))
		check("dorm low-door boom jump reduced",jump_after<jump_before*.5,{"before_m_per_frame":jump_before,"after_m_per_frame":jump_after})
	var failed := checks.filter(func(c):return not c.pass).size()
	var result := {"phase":phase,"rendered":rendered,"passed":checks.size()-failed,"failed":failed,
		"checks":checks,"samples":samples,"points":points,"routes":routes,
		"limits":"Programmatic inspection controller, three existing walkthroughs, sampled paths/angles only; no human playtest, production controller, performance or architecture/collision changes."}
	var file := OUT+phase+("-rendered" if rendered else "-headless")+".json"
	FileAccess.open(file,FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print(phase," ",checks.size()-failed," PASS / ",failed," FAIL; ",samples.size()," moving and ",points.size()," static camera samples")
	quit(1 if failed else 0)

extends Node3D
## Arrival-stair rail review: one 11 m horizontal flight rising 4 m (pitch 4/11), railed on both
## sides with five 2 m + one 1 m rail_stair_4in11 sections, continuing onto a level landing.
## Grey steps, cheeks (support strips) and the landing are review-only supports built here;
## the walking ramp under the steps is collision only. Not a map layout.
## -- --capture=<dir> writes screenshots and quits.
const KIT := "res://staging/claude_environment_safety_kit/"
const SLOPE := 4.0/11.0
const RUN := 11.0
const RISE := 4.0
const RAIL_X := 6.35        # arrival stair: 12 m path, rail line 0.35 m outside it (as Phase 4C places it)
const STEP_HALF := 6.05     # steps and walking ramp reach the inner edge of the cheeks
const RUNS := [2, 2, 2, 2, 2, 1]
const VIEWS := [
	["overview", Vector3(17, 10, 7), Vector3(0, 2, -6.5), 55.0],
	["side_elevation_right", Vector3(21, 2.8, -6.5), Vector3(6.35, 2.6, -6.5), 50.0],
	["foot_join", Vector3(9.2, 1.1, 2.6), Vector3(6.35, .6, -.6), 45.0],
	["joint_2m_2m", Vector3(8.8, 2.6, -2.3), Vector3(6.35, 2.1, -4.0), 45.0],
	["upper_landing_right", Vector3(9.6, 4.9, -8.2), Vector3(6.35, 4.4, -11.0), 50.0],
	["upper_landing_left_from_lane", Vector3(-3.2, 4.6, -8.0), Vector3(-6.35, 4.5, -11.2), 50.0],
	["upper_landing_from_landing", Vector3(3.4, 5.7, -14.8), Vector3(6.35, 4.2, -10.4), 55.0],
	["lineup", Vector3(14.6, 4.6, 17.0), Vector3(14.6, .5, 3.6), 30.0],
]
var stair_sections := []    # {node, side, t (run at origin), L}
var player: CharacterBody3D
var review_camera: Camera3D
var fill: StandardMaterial3D

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("a5c6cb")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e0e9e6")
	env.ambient_light_energy = .65
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -30, 0)
	sun.light_color = Color("fff0d8")
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 100
	add_child(sun)
	fill = StandardMaterial3D.new()
	fill.albedo_color = Color("8d9692")
	fill.roughness = 1
	var strip_mat := StandardMaterial3D.new()
	strip_mat.albedo_color = Color("7b8682")
	strip_mat.roughness = 1
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color("6b8071")
	ground_mat.roughness = 1
	block(Vector3(0, -.062, -4), Vector3(60, .1, 60), ground_mat)
	flight(strip_mat)
	lineup()
	for at in [Vector3(3.5, 0, 1.2), Vector3(4.0, 5*SLOPE, -5), Vector3(.5, RISE, -13.5)]: figure(at)
	label("arrival stair: 11 m run, 4 m rise (4/11 = 19.98 deg)", Vector3(0, 0, 2.6))
	player = CharacterBody3D.new()
	player.set_script(load("res://scripts/training_inspection_player.gd"))
	var args := " ".join(OS.get_cmdline_user_args())
	player.automated = args.contains("--capture") or args.contains("--verify")
	player.position = Vector3(0, .05, 2)
	add_child(player)
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	review_camera = Camera3D.new()
	add_child(review_camera)
	use_view(VIEWS[0])
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	canvas.add_child(panel)
	var hud := Label.new()
	hud.add_theme_font_size_override("font_size", 16)
	hud.text = "ARRIVAL STAIR RAIL REVIEW - 4/11 rail variants only, not a map layout (grey = review supports)\n1 walk/review   Tab first/third person   WASD/mouse walk   2 overview  3 stair foot  4 landing   Esc gallery"
	panel.add_child(hud)
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--capture="): capture.call_deferred(a.trim_prefix("--capture="))

func kit(path: String, at: Vector3, yaw := 0.0) -> Node3D:
	var n: Node3D = load(KIT+path+".tscn").instantiate()
	n.position = at
	n.rotation_degrees.y = yaw
	n.add_to_group("review_kit")
	add_child(n)
	return n

func block(centre: Vector3, size: Vector3, mat: Material = null) -> void:
	"""Review-only support: visible box plus matching collision."""
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mesh.position = centre
	mesh.material_override = mat if mat else fill
	add_child(mesh)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.position = centre
	body.add_child(shape)
	add_child(body)

func wedge(x0: float, x1: float, z_low: float, z_high: float, rise: float, mat: Material) -> void:
	"""Review-only sloped mass rising from z_low (y=0) to z_high (y=rise); mat=null is collision only."""
	var pts := PackedVector3Array()
	for x in [x0, x1]:
		pts.append_array([Vector3(x, 0, z_low), Vector3(x, 0, z_high), Vector3(x, rise, z_high)])
	if mat:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for f in [[0, 2, 1], [3, 4, 5], [0, 3, 5], [0, 5, 2], [1, 2, 5], [1, 5, 4], [0, 1, 4], [0, 4, 3]]:
			for i in f: st.add_vertex(pts[i])
		st.generate_normals()
		var mesh := MeshInstance3D.new()
		mesh.mesh = st.commit()
		var m: StandardMaterial3D = mat.duplicate()
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh.material_override = m
		add_child(mesh)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cs := ConvexPolygonShape3D.new()
	cs.points = pts
	shape.shape = cs
	body.add_child(shape)
	add_child(body)

func figure(at: Vector3) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("d1b177")
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = .20
	capsule.height = 1.40
	body.mesh = capsule
	body.position = at+Vector3(0, .70, 0)
	body.material_override = mat
	add_child(body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = .18
	sphere.height = .36
	head.mesh = sphere
	head.position = at+Vector3(0, 1.62, 0)
	head.material_override = mat
	add_child(head)

func label(text: String, at: Vector3) -> void:
	var l := Label3D.new()
	l.text = text
	l.position = at+Vector3(0, .03, 0)
	l.rotation_degrees.x = -90
	l.pixel_size = .004
	l.modulate = Color("1d2b2b")
	l.outline_size = 0
	add_child(l)

func flight(strip_mat: Material) -> void:
	# Foot at z=0 (y=0), head at z=-11 (y=4); the flight rises toward -Z.
	var steps := ceili(RISE/.18)
	var d := RUN/steps
	for i in steps:                              # step tops cross the ramp at mid-tread
		var h := RISE*(i+.5)/steps
		var mesh := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(2*STEP_HALF, h, d)
		mesh.mesh = bm
		mesh.position = Vector3(0, h/2, -(i+.5)*d)
		mesh.material_override = fill
		add_child(mesh)
	wedge(-STEP_HALF, STEP_HALF, 0, -RUN, RISE, null)                  # smooth walking ramp
	for s in [-1.0, 1.0]:
		wedge(s*STEP_HALF, s*(2*RAIL_X-STEP_HALF), 0, -RUN, RISE, strip_mat)   # cheek centred on the rail line
		var t := 0.0
		for L: int in RUNS:
			var n := kit("railings/rail_stair_4in11_%dm" % L, Vector3(s*RAIL_X, t*SLOPE, -t), 90)
			stair_sections.append({"node": n, "side": s, "t": t, "L": L})
			t += L
		# Upper landing: the level section's leading post is the flight's top post; a rail_post closes it.
		kit("railings/rail_section_2m", Vector3(s*RAIL_X, RISE, -RUN), 90)
		kit("railings/rail_post", Vector3(s*RAIL_X, RISE, -RUN-2))
	block(Vector3(0, RISE/2, -RUN-2.5), Vector3(16, RISE, 5))          # level upper landing

func lineup() -> void:
	var x := 10.5
	for path: String in ["railings/rail_stair_4in11_1m", "railings/rail_stair_4in11_2m", "railings/rail_stair_22deg_2m"]:
		kit(path, Vector3(x, 0, 3))
		label(path.get_file()+(" (existing, for profile)" if "22deg" in path else ""), Vector3(x+1, 0, 4.2))
		x += 3.2

func use_view(v: Array) -> void:
	review_camera.position = v[1]
	review_camera.look_at(v[2])
	review_camera.fov = v[3]
	review_camera.make_current()

func _unhandled_input(event: InputEvent) -> void:
	if player.automated or not (event is InputEventKey and event.pressed and not event.echo): return
	match event.physical_keycode:
		KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().change_scene_to_file("res://scenes/asset_gallery.tscn")
		KEY_1:
			var walking := review_camera.current
			player.set_physics_process(walking)
			player.set_process_unhandled_input(walking)
			if walking:
				player.camera.make_current()
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				review_camera.make_current()
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		KEY_2: use_view(VIEWS[0])
		KEY_3: teleport(Vector3(0, .05, 2))
		KEY_4: teleport(Vector3(0, RISE+.05, -13))

func teleport(at: Vector3) -> void:
	player.position = at
	player.velocity = Vector3.ZERO

func shot(dir: String, name: String) -> void:
	for i in 6: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join(name+".png"))
	print("captured ", name)

func capture(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	for v: Array in VIEWS:
		use_view(v)
		await shot(dir, v[0])
	player.camera.make_current()
	for mode in [["fpp-uphill-lane", false, Vector3(0, .05, 1.5), 0.0, .12],
			["tpp-lane-edge-right", true, Vector3(5.5, 5*SLOPE+.05, -5.0), deg_to_rad(-12), -.05],
			["tpp-upper-landing-left", true, Vector3(-5.4, 10*SLOPE+.05, -10.0), deg_to_rad(20), -.1],
			["fpp-downhill-from-landing", false, Vector3(2.0, RISE+.05, -13.0), PI, -.3]]:
		player.position = mode[2]
		player.third_person = mode[1]
		player.yaw = mode[3]
		player.pitch = mode[4]
		for i in 3: await get_tree().physics_frame
		player.update_camera()
		await shot(dir, mode[0])
	get_tree().quit()

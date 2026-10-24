extends Node3D
## Safety kit review fixture: short kit assemblies for inspection, not a map layout.
## Plain grey blocks (stair masses, platform fill, ramps) are review-only supports built here.
## The Sect Gate is a read-only instance used to show the wall abutment.
## -- --capture=<dir> writes screenshots and quits.
const KIT := "res://staging/claude_environment_safety_kit/"
const MODULES := ["walls/wall_section_2m", "walls/wall_section_4m", "walls/wall_pier", "walls/wall_corner", "walls/wall_gate_end",
	"railings/rail_section_1m", "railings/rail_section_2m", "railings/rail_post", "railings/rail_stair_22deg_1m",
	"railings/rail_stair_22deg_2m", "railings/rail_stair_24deg_1m", "railings/rail_stair_24deg_2m",
	"retaining/retaining_wall_4x2", "retaining/retaining_wall_4x4", "retaining/retaining_corner_2", "retaining/retaining_corner_4",
	"retaining/retaining_end_2", "retaining/retaining_end_4", "edging/edging_2m", "edging/edging_corner", "edging/edging_end",
	"sign/direction_sign"]
# Stair demos: [centre x, foot z, degrees, rail runs]; they rise toward -Z.
const STAIRS := [[-14.0, -4.0, 22.0, [2, 2, 1]], [-7.0, -4.0, 24.0, [2, 2]]]
const VIEWS := [
	["overview", Vector3(4, 22, 26), Vector3(0, 0, -10), 52.0],
	["wall_assembly", Vector3(0, 6, -16), Vector3(-9, 1.6, -29), 52.0],
	["wall_gate_abutment", Vector3(-11.6, 3.4, -24.5), Vector3(-14.4, 2.2, -30), 50.0],
	["wall_corner_and_end", Vector3(1.2, 3.2, -21), Vector3(-3.9, 1.8, -27), 50.0],
	["stair_22_side", Vector3(-4.5, 3.6, -3.5), Vector3(-14, 1.2, -7), 50.0],
	["stair_22_front", Vector3(-14, 2.6, 4.5), Vector3(-14, 1.4, -7), 52.0],
	["stair_top_join", Vector3(-9.6, 3.7, -6.6), Vector3(-12.5, 2.5, -9.0), 46.0],
	["stair_foot_join", Vector3(-11.4, 1.2, -1.6), Vector3(-12.5, .6, -4.0), 45.0],
	["stair_24_side", Vector3(1.5, 3.4, -3.0), Vector3(-7, 1.0, -6), 50.0],
	["platform_rails", Vector3(22, 5, 5), Vector3(14, 2.2, -3), 50.0],
	["platform_corner", Vector3(20.2, 3.6, .6), Vector3(17.8, 2.4, -2.4), 45.0],
	["retaining_4m_corner", Vector3(31, 4.5, 5), Vector3(25, 2.2, -3), 50.0],
	["edging_bed", Vector3(-1, 2.6, 8.5), Vector3(-1.5, 0, 3.0), 50.0],
	["direction_sign", Vector3(7.2, 2.4, 13.2), Vector3(4.5, 2.1, 9), 50.0],
	["lineup_walls", Vector3(-25, 4.5, 28), Vector3(-25, 1.4, 18), 55.0],
	["lineup_railings", Vector3(-4.2, 3.0, 26.5), Vector3(-4.2, .9, 18), 55.0],
	["lineup_retaining", Vector3(19, 4.5, 29.5), Vector3(19, 1.6, 18), 55.0],
	["lineup_edging_sign", Vector3(38, 2.8, 25.5), Vector3(38, 1.2, 18), 55.0],
]
var lineup_x := {}
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
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color("6b8071")
	ground_mat.roughness = 1
	block(Vector3(0, -.062, 0), Vector3(140, .1, 140), ground_mat)
	wall_assembly()
	for s: Array in STAIRS: stair_demo(s[0], s[1], s[2], s[3])
	platform()
	tall_retaining()
	edging_bed()
	kit("sign/direction_sign", Vector3(4.5, 0, 9), -20)
	for at in [Vector3(-16.3, 0, -26.8), Vector3(-16.8, 0, -2.4), Vector3(12.4, 0, -.9), Vector3(5.4, 0, 9.6), Vector3(-1.6, 0, 5.2), Vector3(27, 0, -1.2)]: figure(at)
	lineup()
	player = CharacterBody3D.new()
	player.set_script(load("res://scripts/training_inspection_player.gd"))
	player.automated = " ".join(OS.get_cmdline_user_args()).contains("--capture") or " ".join(OS.get_cmdline_user_args()).contains("--verify")
	player.position = Vector3(-14, .05, 2.5)
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
	hud.text = "SAFETY KIT REVIEW - kit assemblies only, not a map layout (grey blocks are review supports)\n1 walk/review   Tab first/third person   WASD/mouse walk   2 overview  3 stair  4 platform  5 wall   Esc gallery"
	panel.add_child(hud)
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--capture="): capture.call_deferred(a.trim_prefix("--capture="))

func kit(path: String, at: Vector3, yaw := 0.0) -> Node3D:
	var n: Node3D = load(KIT+path+".tscn").instantiate()
	n.position = at
	n.rotation_degrees.y = yaw
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

func wedge(x0: float, x1: float, z_low: float, z_high: float, rise: float, base := 0.0) -> void:
	"""Review-only sloped mass rising from z_low (y=base) to z_high (y=base+rise), with ramp collision."""
	var pts := PackedVector3Array()
	for x in [x0, x1]:
		pts.append_array([Vector3(x, base, z_low), Vector3(x, base, z_high), Vector3(x, base+rise, z_high)])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := [[0, 2, 1], [3, 4, 5], [0, 3, 5], [0, 5, 2], [1, 2, 5], [1, 5, 4], [0, 1, 4], [0, 4, 3]]
	for f in faces:
		for i in f: st.add_vertex(pts[i])
	st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = st.commit()
	mesh.material_override = fill
	var mat := fill.duplicate()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = mat
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

func wall_assembly() -> void:
	var gate: Node3D = load("res://scenes/buildings/sect_gate.tscn").instantiate()
	gate.position = Vector3(-30, 0, -30)
	add_child(gate)
	var c := Vector3(-14.6, 0, -30)          # the gate's right wall connector, local (15.4, 0, 0)
	kit("walls/wall_gate_end", c)
	var x := c.x+.7
	for L: int in [4, 4]:
		kit("walls/wall_section_%dm" % L, Vector3(x, 0, c.z))
		x += L
	kit("walls/wall_pier", Vector3(x, 0, c.z))
	kit("walls/wall_section_2m", Vector3(x, 0, c.z))
	x += 2
	kit("walls/wall_corner", Vector3(x, 0, c.z))
	var z := c.z
	for L: int in [4, 2]:
		kit("walls/wall_section_%dm" % L, Vector3(x, 0, z), -90)   # local +X -> world +Z
		z += L
	kit("walls/wall_pier", Vector3(x, 0, z))

func stair_demo(cx: float, z0: float, deg: float, runs: Array) -> void:
	var t := tan(deg_to_rad(deg))
	var run := 0.0
	for r in runs: run += r
	var rise := run*t
	var zt := z0-run
	var steps := ceili(rise/.18)
	var d := run/steps
	for i in steps:                              # step tops cross the ramp at mid-tread
		var h := rise*(i+.5)/steps
		var mesh := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(2.76, h, d)
		mesh.mesh = bm
		mesh.position = Vector3(cx, h/2, z0-(i+.5)*d)
		mesh.material_override = fill
		add_child(mesh)
	for s in [-1.0, 1.0]: wedge(cx+s*1.38, cx+s*1.7, z0, zt, rise)   # cheeks under the rails
	wedge(cx-1.38, cx+1.38, z0, zt, rise)                               # smooth walking ramp
	block(Vector3(cx, rise/2, zt-1.15), Vector3(3.4, rise, 2.3))       # top landing
	for xr in [cx-1.5, cx+1.5]:
		var z := z0
		var y := 0.0
		for r: int in runs:
			kit("railings/rail_stair_%ddeg_%dm" % [int(deg), r], Vector3(xr, y, z), 90)
			z -= r
			y += r*t
	kit("railings/rail_section_2m", Vector3(cx+1.5, rise, zt), 90)    # right side of landing, runs -Z
	kit("railings/rail_section_2m", Vector3(cx+1.5, rise, zt-2), 180) # back edge, runs -X
	kit("railings/rail_section_1m", Vector3(cx-.5, rise, zt-2), 180)
	kit("railings/rail_section_2m", Vector3(cx-1.5, rise, zt-2), -90) # left side, runs +Z
	kit("railings/rail_post", Vector3(cx-1.5, rise, zt))               # closes the left stair top
	label("%d deg stair, rails on cheeks" % int(deg), Vector3(cx, 0, z0+1.2))

func platform() -> void:
	# 2 m retaining platform: front run faces +Z, outer corner, side run faces +X, ends.
	kit("retaining/retaining_end_2", Vector3(10, 0, -2))
	for i in 2: kit("retaining/retaining_wall_4x2", Vector3(10+4*i, 0, -2))
	kit("retaining/retaining_corner_2", Vector3(18, 0, -2))
	kit("retaining/retaining_wall_4x2", Vector3(18, 0, -2), 90)
	kit("retaining/retaining_end_2", Vector3(18, 0, -6), 90)
	block(Vector3(13.8, 1.0, -5.0), Vector3(8.2, 2.0, 5.95))           # review fill behind the walls
	wedge(9.7, 17.9, -14.0, -7.97, 2.0)                                # review access ramp
	var x := 10.82
	for L: int in [2, 2, 2, 1]:                                        # rail line 0.18 m behind the face
		kit("railings/rail_section_%dm" % L, Vector3(x, 2, -2.18))
		x += L
	var z := -2.18
	for L: int in [2, 2]:
		kit("railings/rail_section_%dm" % L, Vector3(17.82, 2, z), 90)
		z -= L
	kit("railings/rail_post", Vector3(17.82, 2, z))
	label("2 m retaining platform, railed edge", Vector3(14, 0, -.5))

func tall_retaining() -> void:
	kit("retaining/retaining_end_4", Vector3(22, 0, -2))
	kit("retaining/retaining_wall_4x4", Vector3(22, 0, -2))
	kit("retaining/retaining_corner_4", Vector3(26, 0, -2))
	kit("retaining/retaining_wall_4x4", Vector3(26, 0, -2), 90)
	kit("retaining/retaining_end_4", Vector3(26, 0, -6), 90)
	block(Vector3(23.8, 2.0, -5.0), Vector3(4.2, 4.0, 5.95))
	label("4 m retaining corner and ends", Vector3(24, 0, -.5))

func edging_bed() -> void:
	var soil := StandardMaterial3D.new()
	soil.albedo_color = Color("5d4a3a")
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(4, .06, 2)
	m.mesh = bm
	m.position = Vector3(-2, .02, 3)
	m.material_override = soil
	add_child(m)
	# Closed 4 x 2 m bed: four corners and five 2 m sections, clockwise from (-4, 4).
	for p in [Vector3(-4, 0, 4), Vector3(0, 0, 4), Vector3(0, 0, 2), Vector3(-4, 0, 2)]: kit("edging/edging_corner", p)
	kit("edging/edging_2m", Vector3(-4, 0, 4))
	kit("edging/edging_2m", Vector3(-2, 0, 4))
	kit("edging/edging_2m", Vector3(0, 0, 4), 90)
	kit("edging/edging_2m", Vector3(0, 0, 2), 180)
	kit("edging/edging_2m", Vector3(-2, 0, 2), 180)
	kit("edging/edging_2m", Vector3(-4, 0, 2), -90)
	# Open path edging with two ends.
	kit("edging/edging_end", Vector3(2, 0, 4))
	for x in [2.0, 4.0]: kit("edging/edging_2m", Vector3(x, 0, 4))
	kit("edging/edging_end", Vector3(6, 0, 4))
	label("edging: closed bed and open run", Vector3(1, 0, 5.6))

func lineup() -> void:
	var x := -34.0
	for path: String in MODULES:
		var w := 4.2 if "4m" in path or "4x" in path else 2.6 if "2m" in path or "1m" in path or path.ends_with("_end") or "corner" in path or "pier" in path else 2.0
		if path.begins_with("sign"): w = 3.0
		var at := Vector3(x+(0.0 if "section" in path or "retaining_wall" in path or "stair" in path else w/2), 0, 18)
		kit(path, at)
		lineup_x[path] = at.x
		label(path.get_file(), Vector3(x+w/2, 0, 19.4))
		x += w+.8

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
		KEY_3: teleport(Vector3(-14, .05, 2.5))
		KEY_4: teleport(Vector3(14, 2.05, -5))
		KEY_5: teleport(Vector3(-9, .05, -27.5))

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
	for mode in [["fpp-stair-lane", false, Vector3(-14, .05, -3.2), 0.0, .18],
			["tpp-stair-lane", true, Vector3(-13.2, .84, -6.0), deg_to_rad(-12), -.05],
			["tpp-beside-wall", true, Vector3(-11.0, .05, -28.7), deg_to_rad(70), -.1],
			["fpp-platform-rail", false, Vector3(14.5, 2.05, -3.0), PI, -.32],
			["tpp-platform-rail", true, Vector3(16.6, 2.05, -3.4), deg_to_rad(-135), -.12]]:
		player.position = mode[2]
		player.third_person = mode[1]
		player.yaw = mode[3]
		player.pitch = mode[4]
		for i in 3: await get_tree().physics_frame
		player.update_camera()
		await shot(dir, mode[0])
	get_tree().quit()

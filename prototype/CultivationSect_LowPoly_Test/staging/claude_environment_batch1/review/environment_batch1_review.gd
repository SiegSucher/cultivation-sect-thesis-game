extends Node3D
## Environment batch 1 review fixture. Assets are laid out for inspection only (not
## a town layout), with the same sun/ambient/ground as the other review fixtures and
## the unchanged 1.8 m controller. The Mission Hall vignette is a read-only instance
## for comparing scale and finish. -- --capture=<dir> writes screenshots and quits.
const ROOT := "res://staging/claude_environment_batch1/"
const FIGURE_GAP := 1.2
# [asset, position, yaw degrees, scale-figure offset]
const ROWS := [
	["pine_windswept", Vector3(-22, 0, 0), 0.0, Vector3(1.0, 0, 1.4)],
	["pine_tiered", Vector3(-13, 0, 0), 0.0, Vector3(1.0, 0, 1.2)],
	["bamboo_cluster", Vector3(-6.5, 0, 0), 0.0, Vector3(1.6, 0, .8)],
	["rock_outcrop", Vector3(-1, 0, 0), 0.0, Vector3(2.3, 0, 1.0)],
	["rock_cluster", Vector3(5, 0, 0), 0.0, Vector3(-.6, 0, 1.4)],
	["stone_lantern", Vector3(-17, 0, 9), 0.0, Vector3(.9, 0, .3)],
	["sect_banner", Vector3(-12.5, 0, 9), 0.0, Vector3(-.9, 0, .4)],
	["training_dummy_rack", Vector3(-7, 0, 9), 0.0, Vector3(-1.7, 0, .4)],
	["stone_bench", Vector3(-2, 0, 9), 0.0, Vector3(1.4, 0, .4)],
	["flowering_shrub", Vector3(2.5, 0, 9), 0.0, Vector3(1.5, 0, .4)],
	["grass_tuft", Vector3(6.5, 0, 9), 0.0, Vector3(1.0, 0, .3)],
]
# [name, camera position, look target, fov]
const VIEWS := [
	["contact_sheet", Vector3(-8, 15, 30), Vector3(-8, 1.6, 4.5), 50.0],
	["row_vegetation_rocks", Vector3(-9, 4.5, 17), Vector3(-9, 2.6, 0), 55.0],
	["row_props", Vector3(-5.5, 2.6, 17), Vector3(-5.5, 1.0, 9), 52.0],
	["variation_strip", Vector3(-4, 7, -6), Vector3(-4, 0, -14), 55.0],
	["vignette_mission_hall", Vector3(44, 9, 30), Vector3(32, 3, 8), 48.0],
	["pine_windswept", Vector3(-17.5, 3.0, 8.5), Vector3(-21, 3.2, 0), 50.0],
	["pine_tiered", Vector3(-9.5, 3.5, 9), Vector3(-13, 4.0, 0), 50.0],
	["bamboo_cluster", Vector3(-3.8, 2.6, 6.5), Vector3(-6.5, 2.6, 0), 52.0],
	["rock_outcrop", Vector3(2.4, 2.4, 6.0), Vector3(-1, 1.5, 0), 50.0],
	["rock_cluster", Vector3(7.6, 1.8, 4.6), Vector3(5, .5, 0), 48.0],
	["stone_lantern", Vector3(-15.4, 1.7, 11.6), Vector3(-17, 1.1, 9), 45.0],
	["sect_banner", Vector3(-10.4, 2.6, 13.4), Vector3(-12.2, 2.4, 9), 50.0],
	["training_dummy_rack", Vector3(-5.2, 1.7, 12.2), Vector3(-7, 1.0, 9), 50.0],
	["stone_bench", Vector3(-3.5, 1.3, 11.0), Vector3(-2, .4, 9), 45.0],
	["flowering_shrub", Vector3(1.1, 1.5, 11.2), Vector3(2.5, .5, 9), 45.0],
	["grass_tuft", Vector3(5.5, .9, 10.5), Vector3(6.5, .35, 9), 45.0],
]
var player: CharacterBody3D
var review_camera: Camera3D

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
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(160, 160)
	ground.mesh = plane
	ground.position.y = -.012
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("6b8071")
	material.roughness = 1
	ground.material_override = material
	add_child(ground)
	var body := StaticBody3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(160, .10, 160)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position.y = -.062
	body.add_child(shape)
	add_child(body)
	for row: Array in ROWS:
		place(row[0], row[1], row[2], 1.0)
		figure(row[1]+row[3])
		var label := Label3D.new()
		label.text = row[0]
		label.position = row[1]+Vector3(0, -.0, 3.2) if row[1].z < 5 else row[1]+Vector3(0, 0, 1.9)
		label.position.y = .08
		label.rotation_degrees.x = -90
		label.pixel_size = .006
		label.modulate = Color("1d2b2b")
		label.outline_size = 0
		add_child(label)
	variation_strip()
	vignette()
	player = CharacterBody3D.new()
	player.set_script(load("res://scripts/training_inspection_player.gd"))
	player.automated = " ".join(OS.get_cmdline_user_args()).contains("--capture")
	player.position = Vector3(-6, .05, 16)
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
	hud.text = "ENVIRONMENT BATCH 1 - review spacing only, not a town layout\n1 walk/review   Tab first/third person   WASD/mouse walk   2-4 views   Esc gallery"
	panel.add_child(hud)
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--capture="): capture.call_deferred(a.trim_prefix("--capture="))

func place(id: String, at: Vector3, yaw_deg: float, s: float) -> Node3D:
	var node: Node3D = load(ROOT+id+"/"+id+".tscn").instantiate()
	node.position = at
	node.rotation_degrees.y = yaw_deg
	node.scale = Vector3.ONE*s
	add_child(node)
	return node

func figure(at: Vector3) -> void:
	# Same proportions as the gallery's 1.8 m scale figure.
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

func variation_strip() -> void:
	# Repetition check: the same assets with random yaw and +/-15% uniform scale.
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for i in 24:
		place("grass_tuft", Vector3(-12+(i % 8)*1.1+rng.randf_range(-.3, .3), 0, -12-(i/8)*1.0+rng.randf_range(-.3, .3)), rng.randf_range(0, 360), rng.randf_range(.85, 1.15))
	for i in 4: place("flowering_shrub", Vector3(-2+i*2.4, 0, -12), rng.randf_range(0, 360), rng.randf_range(.85, 1.15))
	for i in 3: place("rock_cluster", Vector3(-11+i*3.6, 0, -17), i*120.0, 1.0)
	for i in 3: place("bamboo_cluster", Vector3(1+i*2.6, 0, -17.5), i*120.0+rng.randf_range(-20, 20), rng.randf_range(.9, 1.1))

func vignette() -> void:
	# Scale/finish comparison beside an existing, unmodified building (read-only instance).
	var hall: Node3D = load("res://scenes/buildings/mission_hall.tscn").instantiate()
	hall.position = Vector3(32, 0, 0)
	add_child(hall)
	for s in [-1.0, 1.0]:
		place("stone_lantern", Vector3(32+s*3.6, 0, 13.2), 0, 1)
		place("pine_tiered" if s < 0 else "pine_windswept", Vector3(32+s*12.5, 0, 6), 90.0+s*40.0, 1)
		place("flowering_shrub", Vector3(32+s*10.8, 0, 11.5), s*70.0, 1)
		place("rock_cluster", Vector3(32+s*11.8, 0, 13.0), s*35.0, .9)
	place("sect_banner", Vector3(37.2, 0, 15.5), 180, 1)
	place("bamboo_cluster", Vector3(20.5, 0, -2), 30, 1)
	place("stone_bench", Vector3(26.5, 0, 14.2), 0, 1)
	for i in 10: place("grass_tuft", Vector3(19.5+i*.7, 0, 9+(i % 3)*.6), i*47.0, .9+(i % 4)*.07)

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
		KEY_3: use_view(VIEWS[1])
		KEY_4: use_view(VIEWS[2])

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
	# First/third person with the real controller camera: walking past the vegetation row.
	player.camera.make_current()
	for mode in [["third-person-pines", true, Vector3(-17.5, .05, 5.0), deg_to_rad(35), -.12],
			["first-person-props", false, Vector3(-9.8, .05, 13.5), deg_to_rad(20), -.18],
			["third-person-props", true, Vector3(-4.5, .05, 13.0), deg_to_rad(-15), -.15]]:
		player.position = mode[2]
		player.third_person = mode[1]
		player.yaw = mode[3]
		player.pitch = mode[4]
		await get_tree().physics_frame
		player.update_camera()
		await shot(dir, mode[0])
	get_tree().quit()

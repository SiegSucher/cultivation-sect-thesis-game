extends Node3D
## Exchange Hall review fixture: one asset at the local origin (not a layout),
## same sun/ambient/ground as gate_walkthrough.gd, unchanged 1.8 m controller.
## --capture writes screenshots to reports/codex-exchange-hall/integrated-captures/.
const SCENE := "res://scenes/buildings/exchange_hall.tscn"
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
	add_child(load(SCENE).instantiate())
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(120, 120)
	ground.mesh = plane
	ground.position.y = -.012
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("6b8071")
	material.roughness = 1
	ground.material_override = material
	add_child(ground)
	var body := StaticBody3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(120, .10, 120)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position.y = -.062
	body.add_child(shape)
	add_child(body)
	player = CharacterBody3D.new()
	player.set_script(load("res://scripts/training_inspection_player.gd"))
	player.automated = "--capture" in OS.get_cmdline_user_args()
	player.position = Vector3(0, .05, 13)
	add_child(player)
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	review_camera = Camera3D.new()
	review_camera.fov = 58
	add_child(review_camera)
	view(Vector3(22, 14, 26), Vector3(0, 4, 0))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	canvas.add_child(panel)
	var hud := Label.new()
	hud.add_theme_font_size_override("font_size", 16)
	hud.text = "CONTRIBUTION / EXCHANGE HALL - asset at local origin, not a town layout\n1 walk/review   Tab first/third person   WASD/mouse walk   Esc gallery"
	panel.add_child(hud)
	if player.automated: capture.call_deferred()

func view(at: Vector3, target: Vector3) -> void:
	review_camera.position = at
	review_camera.look_at(target)
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
			if walking: player.camera.make_current()
			else: review_camera.make_current()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if walking else Input.MOUSE_MODE_VISIBLE

func shot(path: String) -> void:
	for i in 3: await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://reports/codex-exchange-hall/integrated-captures/"+path))

func eye(pos: Vector3, yaw: float, pitch: float, third: bool) -> void:
	player.position = pos
	player.yaw = yaw
	player.pitch = pitch
	player.third_person = third
	player.update_camera()
	player.camera.make_current()

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/codex-exchange-hall/integrated-captures"))
	await shot("exchange_hall-three-quarter.png")
	view(Vector3(0, 6, 30), Vector3(0, 5.5, 0))
	await shot("exchange_hall-front.png")
	view(Vector3(-22, 14, -24), Vector3(0, 4, -1))
	await shot("exchange_hall-rear.png")
	view(Vector3(-30, 6, 4), Vector3(0, 5, 0))
	await shot("exchange_hall-side.png")
	eye(Vector3(0, .05, 13), 0, -.06, true)
	await shot("exchange_hall-third-person-approach.png")
	eye(Vector3(0, .6, 4.2), 0, -.12, false)
	await shot("exchange_hall-first-person-interior.png")
	eye(Vector3(0, .6, 2.0), 0, -.05, true)
	await shot("exchange_hall-third-person-interior.png")
	eye(Vector3(-.8, .6, .1), .1, -.45, false)
	await shot("exchange_hall-counter-abacus.png")
	eye(Vector3(3.9, .6, -2.0), 1.2, .25, false)
	await shot("exchange_hall-reward-racks-and-list.png")
	eye(Vector3(0, .6, 1.0), 0, 1.25, false)
	await shot("exchange_hall-caisson-ceiling.png")
	eye(Vector3(5.6, .6, -2.4), -1.25, -.12, false)
	await shot("exchange_hall-east-storeroom.png")
	eye(Vector3(-5.6, .6, -2.4), 1.25, -.12, false)
	await shot("exchange_hall-west-storeroom.png")
	eye(Vector3(6.0, .6, 4.2), -1.45, -.05, false)
	await shot("exchange_hall-east-veranda.png")
	get_tree().quit()

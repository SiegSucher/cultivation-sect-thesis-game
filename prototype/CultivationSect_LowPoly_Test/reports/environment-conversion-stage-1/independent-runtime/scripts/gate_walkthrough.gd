extends Node3D
## Separate gate review fixture. Existing controller and gate mechanics unchanged.
var automated := false
var baseline := false
var facility: Node3D
var player: CharacterBody3D
var review_camera: Camera3D
var hud: Label

func _ready() -> void:
	baseline = baseline or "--baseline" in OS.get_cmdline_user_args()
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
	sun.rotation_degrees = Vector3(-48,-30,0)
	sun.light_color = Color("fff0d8")
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 100
	add_child(sun)
	facility = Node3D.new()
	facility.set_script(load("res://baseline/stage1_gate.gd" if baseline else "res://scripts/sect_gate.gd"))
	add_child(facility)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(120,120)
	ground.mesh = plane
	ground.position.y = -.012
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("6b8071")
	material.roughness = 1
	ground.material_override = material
	add_child(ground)
	var body := StaticBody3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(120,.10,120)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position.y = -.062
	body.add_child(shape)
	add_child(body)
	player = CharacterBody3D.new()
	player.set_script(load("res://scripts/training_inspection_player.gd"))
	player.automated = automated
	player.position = Vector3(0,.05,10)
	add_child(player)
	if not automated:
		player.set_physics_process(false)
		player.set_process_unhandled_input(false)
	review_camera = Camera3D.new()
	review_camera.fov = 58
	review_camera.position = Vector3(26,17,27)
	add_child(review_camera)
	review_camera.look_at(Vector3(0,7,0))
	review_camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(18,18)
	canvas.add_child(panel)
	hud = Label.new()
	hud.add_theme_font_size_override("font_size",16)
	hud.text = ("SECT GATE / BEFORE STAGE 1" if baseline else "SECT GATE / STAGE 1 LOW-POLY")+"\n1 walk/review   WASD/mouse walk   Tab first/third person   E doors\n2 front   3 three-quarter   4 passage   Esc gallery"
	panel.add_child(hud)

func _unhandled_input(event: InputEvent) -> void:
	if automated or not (event is InputEventKey and event.pressed and not event.echo): return
	match event.physical_keycode:
		KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().change_scene_to_file("res://scenes/asset_gallery.tscn")
		KEY_E: facility.request_toggle()
		KEY_1:
			var walking := review_camera.current
			player.set_physics_process(walking)
			player.set_process_unhandled_input(walking)
			if walking: player.camera.make_current()
			else: review_camera.make_current()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if walking else Input.MOUSE_MODE_VISIBLE
		KEY_2, KEY_3, KEY_4:
			player.set_physics_process(false)
			player.set_process_unhandled_input(false)
			review_camera.make_current()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			review_camera.fov = 58
			if event.physical_keycode == KEY_2:
				review_camera.position = Vector3(0,10,32)
				review_camera.look_at(Vector3(0,7,0))
			elif event.physical_keycode == KEY_3:
				review_camera.position = Vector3(26,17,27)
				review_camera.look_at(Vector3(0,7,0))
			else:
				facility.set_open_immediate(true)
				review_camera.position = Vector3(0,2.25,5)
				review_camera.look_at(Vector3(0,3,-5))
				review_camera.fov = 80

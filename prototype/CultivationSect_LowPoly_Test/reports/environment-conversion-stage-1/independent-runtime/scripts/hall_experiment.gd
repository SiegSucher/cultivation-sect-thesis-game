extends Node3D
## Same fixture and controls in both versions; no production controller exists.
var automated := false
var baseline := false
var hall: Node3D
var player: CharacterBody3D
var hud: Label
var view_camera: Camera3D

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
	hall = Node3D.new()
	hall.set_script(load("res://baseline/tang_main_hall.gd" if baseline else "res://scripts/tang_main_hall.gd"))
	add_child(hall)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(180,180)
	ground.mesh = plane
	ground.position.y = -.012
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("6b8071")
	mat.roughness = 1
	ground.material_override = mat
	add_child(ground)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(180,.10,180)
	shape.shape = box
	shape.position.y = -.062
	body.add_child(shape)
	add_child(body)
	player = CharacterBody3D.new()
	player.set_script(load("res://scripts/training_inspection_player.gd"))
	player.automated = automated
	player.position = Vector3(0,.05,24)
	add_child(player)
	if not automated:
		player.set_physics_process(false)
		player.set_process_unhandled_input(false)
	view_camera = Camera3D.new()
	view_camera.fov = 58
	add_child(view_camera)
	view_camera.position = Vector3(33,23,41)
	view_camera.look_at(Vector3(0,8,2))
	view_camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(18,18)
	canvas.add_child(panel)
	hud = Label.new()
	hud.add_theme_font_size_override("font_size",16)
	panel.add_child(hud)
	update_hud()

func update_hud() -> void:
	if hud:
		hud.text = ("ORIGINAL BASELINE" if baseline else "SPLIT-CLOUD HALL / LOW-POLY TEST")+"\n1 walk / orbit view   Tab first / third person   E doors   Esc gallery\nWASD move / mouse look in walk mode | 2 front  3 three-quarter  4 interior"

func _unhandled_input(event: InputEvent) -> void:
	if automated or not (event is InputEventKey and event.pressed and not event.echo): return
	match event.physical_keycode:
		KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().change_scene_to_file("res://scenes/asset_gallery.tscn")
		KEY_1:
			if view_camera.current:
				player.camera.make_current()
				player.set_physics_process(true)
				player.set_process_unhandled_input(true)
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				view_camera.make_current()
				player.set_physics_process(false)
				player.set_process_unhandled_input(false)
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		KEY_E:
			for door in hall.doors: door.request_toggle()
		KEY_2, KEY_3, KEY_4:
			view_camera.make_current()
			player.set_physics_process(false)
			player.set_process_unhandled_input(false)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			view_camera.fov = 58
			if event.physical_keycode == KEY_2:
				view_camera.position = Vector3(0,13,45)
				view_camera.look_at(Vector3(0,8,2))
			elif event.physical_keycode == KEY_3:
				view_camera.position = Vector3(33,23,41)
				view_camera.look_at(Vector3(0,8,2))
			else:
				for door in hall.doors: door.set_open_immediate(true)
				view_camera.position = Vector3(0,3.22,5.9)
				view_camera.look_at(Vector3(0,4.8,-7))
				view_camera.fov = 82
	update_hud()

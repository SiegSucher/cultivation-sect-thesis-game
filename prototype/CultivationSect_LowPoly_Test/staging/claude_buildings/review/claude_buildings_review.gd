extends Node3D
## Review fixture for Claude's four staged assets. Spacing is for inspection
## only; it is NOT a town layout. Same sun/ambient/ground as gate_walkthrough.gd
## and the existing 1.8 m inspection controller, unchanged.
const ROOT := "res://staging/claude_buildings/"
const IDS := ["disciple_residence", "elder_residence", "dining_hall_kitchen", "spirit_herb_garden"]
const SPACING := 34.0
# Per asset (local coords): three-quarter camera, look target, walk-in start.
const VIEWS := {
	"disciple_residence": [Vector3(17, 10, 20), Vector3(0, 2.5, 0), Vector3(2.2, .05, 8.5)],
	"elder_residence": [Vector3(21, 16, 27), Vector3(0, 2, -1), Vector3(0, .05, 14)],
	"dining_hall_kitchen": [Vector3(22, 15, 24), Vector3(0, 3, -2), Vector3(0, .05, 11)],
	"spirit_herb_garden": [Vector3(20, 17, 24), Vector3(0, 0, -1), Vector3(0, .05, 15)],
}
var player: CharacterBody3D
var review_camera: Camera3D
var hud: Label
var current := 0

func origin(i: int) -> Vector3:
	return Vector3((i-1.5)*SPACING, 0, 0)

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
	for i in IDS.size():
		var asset: Node3D = load(ROOT+IDS[i]+"/"+IDS[i]+".tscn").instantiate()
		asset.position = origin(i)
		add_child(asset)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 120)
	ground.mesh = plane
	ground.position.y = -.012
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("6b8071")
	material.roughness = 1
	ground.material_override = material
	add_child(ground)
	var body := StaticBody3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200, .10, 120)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position.y = -.062
	body.add_child(shape)
	add_child(body)
	player = CharacterBody3D.new()
	player.set_script(load("res://scripts/training_inspection_player.gd"))
	player.automated = "--capture" in OS.get_cmdline_user_args()
	add_child(player)
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	review_camera = Camera3D.new()
	review_camera.fov = 58
	add_child(review_camera)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	canvas.add_child(panel)
	hud = Label.new()
	hud.add_theme_font_size_override("font_size", 16)
	panel.add_child(hud)
	show_asset(0)
	if player.automated: capture.call_deferred()

func show_asset(i: int) -> void:
	current = i
	var view: Array = VIEWS[IDS[i]]
	review_camera.position = origin(i)+view[0]
	review_camera.look_at(origin(i)+view[1])
	review_camera.make_current()
	player.position = origin(i)+view[2]
	player.yaw = 0.0
	player.pitch = 0.0
	player.update_camera()
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.text = "CLAUDE STAGING ASSETS - review spacing only, not a town layout\n%s\n1 walk/review   Tab first/third person   WASD/mouse walk\n2 Disciples  3 Elder  4 Dining+Kitchen  5 Herb Garden   Esc gallery" % IDS[i].replace("_", " ").to_upper()

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
		KEY_2, KEY_3, KEY_4, KEY_5:
			show_asset(event.physical_keycode-KEY_2)

func shot(path: String) -> void:
	for i in 3: await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://reports/claude-assets/"+path))

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/claude-assets"))
	review_camera.position = Vector3(0, 46, 70)
	review_camera.look_at(Vector3(0, 0, -2))
	review_camera.make_current()
	await shot("lineup.png")
	for i in IDS.size():
		show_asset(i)
		await shot(IDS[i]+"-three-quarter.png")
		var view: Array = VIEWS[IDS[i]]
		review_camera.position = origin(i)+Vector3(0, 5, view[2].z+12)
		review_camera.look_at(origin(i)+Vector3(0, 3, 0))
		await shot(IDS[i]+"-front.png")
		review_camera.position = origin(i)+Vector3(-view[0].x, view[0].y, -view[0].z)
		review_camera.look_at(origin(i)+view[1])
		await shot(IDS[i]+"-rear.png")
		player.third_person = true
		player.yaw = 0.0
		player.pitch = -.12
		player.update_camera()
		player.camera.make_current()
		await shot(IDS[i]+"-third-person.png")
		player.third_person = false
	# First-person interiors: stand just inside the entrance looking in.
	var inside := {"disciple_residence": Vector3(2.2, .5, 1.3), "elder_residence": Vector3(0, 1.0, -2.9),
		"dining_hall_kitchen": Vector3(0, .6, 3.8), "spirit_herb_garden": Vector3(0, .5, -6.2)}
	for i in IDS.size():
		show_asset(i)
		player.position = origin(i)+inside[IDS[i]]
		player.pitch = -.15
		player.update_camera()
		player.camera.make_current()
		await shot(IDS[i]+"-first-person.png")
	show_asset(2)
	player.position = origin(2)+Vector3(0, .6, -5.6)
	player.camera.make_current()
	player.update_camera()
	await shot("dining_hall_kitchen-kitchen.png")
	get_tree().quit()

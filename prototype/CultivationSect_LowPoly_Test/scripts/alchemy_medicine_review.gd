extends Node3D
## Review fixture for batch 2 (one asset at the local origin at a time; not a
## layout). Same sun/ambient/ground as gate_walkthrough.gd and the unchanged
## 1.8 m inspection controller. --capture writes reports/codex-alchemy-medicine/integrated-captures/.
@export var start_asset_index := 0
const IDS := ["alchemy_pavilion", "medicine_hall"]
# three-quarter camera, look target, walk start, first-person interior spot, interior yaw
const VIEWS := {
	"alchemy_pavilion": [Vector3(19, 13, 22), Vector3(0, 4.5, 0), Vector3(0, .05, 12), Vector3(0, .9, 4.4), 0.0],
	"medicine_hall": [Vector3(17, 11, 21), Vector3(0, 4, 0), Vector3(0, .05, 10), Vector3(-1.0, .45, 3.6), 0.25],
}
var player: CharacterBody3D
var review_camera: Camera3D
var hud: Label
var asset: Node3D

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
	add_child(player)
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
	show_asset(start_asset_index)
	if player.automated: capture.call_deferred()

func show_asset(i: int) -> void:
	if asset:
		# Remove exceptions while the old bodies still exist. Keeping their freed
		# physics IDs causes errors when the next asset's exceptions are inspected.
		for body: StaticBody3D in asset.find_children("*", "StaticBody3D", true, false):
			if body.is_in_group("camera_only_obstruction"):
				player.remove_collision_exception_with(body)
		asset.free()
	asset = load("res://scenes/buildings/"+IDS[i]+".tscn").instantiate()
	add_child(asset)
	# Detail-only camera collision must not turn the smooth walking ramp into
	# hard steps. The camera's direct-space query still sees these layer-1 bodies.
	for body: StaticBody3D in asset.find_children("*", "StaticBody3D", true, false):
		if body.is_in_group("camera_only_obstruction"):
			player.add_collision_exception_with(body)
	var view: Array = VIEWS[IDS[i]]
	review_camera.position = view[0]
	review_camera.look_at(view[1])
	review_camera.make_current()
	player.position = view[2]
	player.velocity = Vector3.ZERO
	player.yaw = 0.0
	player.pitch = 0.0
	player.third_person = false
	player.update_camera()
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.text = "ALCHEMY / MEDICINE REVIEW - one asset at local origin, not a town layout\n%s\n1 walk/review   Tab first/third person   WASD/mouse walk\n2 Alchemy Pavilion  3 Medicine Hall   Esc gallery" % IDS[i].replace("_", " ").to_upper()

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
		KEY_2, KEY_3:
			show_asset(event.physical_keycode-KEY_2)

func shot(path: String) -> void:
	for i in 3: await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://reports/codex-alchemy-medicine/integrated-captures/"+path))

func eye(pos: Vector3, yaw: float, pitch: float, third: bool) -> void:
	player.position = pos
	player.yaw = yaw
	player.pitch = pitch
	player.third_person = third
	player.update_camera()
	player.camera.make_current()

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/codex-alchemy-medicine/integrated-captures"))
	for i in IDS.size():
		show_asset(i)
		var id: String = IDS[i]
		var view: Array = VIEWS[id]
		await shot(id+"-three-quarter.png")
		review_camera.position = Vector3(0, 4, view[2].z+10)
		review_camera.look_at(Vector3(0, 4.5, 0))
		await shot(id+"-front.png")
		review_camera.position = Vector3(-view[0].x, view[0].y, -view[0].z)
		review_camera.look_at(view[1])
		await shot(id+"-rear.png")
		eye(view[2], 0, -.1, true)
		await shot(id+"-third-person.png")
		eye(view[3], view[4], -.12, false)
		await shot(id+"-first-person.png")
	show_asset(0)
	eye(Vector3(-3.2, .9, 3.0), -.6, .15, false)
	await shot("alchemy_pavilion-furnace.png")
	eye(Vector3(0, .9, 4.6), 0, .9, false)
	await shot("alchemy_pavilion-smoke-lantern.png")
	show_asset(1)
	eye(Vector3(3.0, .45, 1.8), .35, -.05, false)
	await shot("medicine_hall-drawer-wall.png")
	eye(Vector3(2.0, 4.2, 2.5), .3, -.12, false)
	await shot("medicine_hall-drying-loft.png")
	eye(Vector3(-7.15, .45, 4.0), 0, .35, false)
	await shot("medicine_hall-stair.png")
	review_camera.position = Vector3(-14, 6, 14)
	review_camera.look_at(Vector3(0, 6, 0))
	review_camera.make_current()
	await shot("medicine_hall-fire-wall.png")
	get_tree().quit()

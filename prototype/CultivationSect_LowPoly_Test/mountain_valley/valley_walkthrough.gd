extends Node3D
## Scene-local review controls. The existing walking/camera script is unchanged.
var player: CharacterBody3D
var review_camera: Camera3D
var layout: Dictionary
var overview := false
var location: Label
var model_ranges: Array = []
const STOPS := {
	KEY_2: [Vector3(0,8.1,150),0.0,"Sect entrance"],
	KEY_3: [Vector3(0,20.1,47),0.0,"Living streets"],
	KEY_4: [Vector3(-155,28.1,-10),0.0,"Training terrace"],
	KEY_5: [Vector3(0,48.1,-123),0.0,"Hall forecourt"],
	KEY_6: [Vector3(123,20.1,3),0.0,"Healing gardens"],
	KEY_7: [Vector3(-110,56.1,-180),0.0,"Scholarly ledge"],
	KEY_8: [Vector3(101,40.1,-104),0.0,"Alchemy ridge"],
}

func _ready() -> void:
	layout = JSON.parse_string(FileAccess.get_file_as_string("res://mountain_valley/layout.json"))
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var atmosphere := ProceduralSkyMaterial.new()
	atmosphere.sky_top_color = Color("658d9d")
	atmosphere.sky_horizon_color = Color("becbc4")
	atmosphere.ground_horizon_color = Color("becbc4")
	atmosphere.ground_bottom_color = Color("59675a")
	sky.sky_material = atmosphere
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d4e0db")
	env.ambient_light_energy = .58
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-43,-28,0)
	sun.light_color = Color("ffe8c6")
	sun.light_energy = .92
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 145
	add_child(sun)
	player = CharacterBody3D.new()
	player.name = "ExistingInspectionPlayer"
	player.set_script(load("res://scripts/training_inspection_player.gd"))
	player.third_person = true
	player.position = Vector3(12,.12,320)
	player.yaw = .8
	player.pitch = -.08
	add_child(player)
	# Preserve the established Medicine contract: walking ignores fine camera
	# triangles, while the camera's direct query still sees them.
	for body: StaticBody3D in $Buildings/medicine_hall.find_children("*","StaticBody3D",true,false):
		if body.is_in_group("camera_only_obstruction"): player.add_collision_exception_with(body)
	$Buildings/sect_gate.set_open_immediate(true)
	$Buildings/main_sect_hall.main_door.set_open_immediate(true)
	# Existing distant models otherwise stop at 300–400 m, hiding the Hall from
	# the arrival axis. Extend only their map-instance range, retaining near ranges.
	for item: GeometryInstance3D in $Buildings.find_children("*","GeometryInstance3D",true,false):
		if item.visibility_range_begin>0: item.visibility_range_end = 600
		model_ranges.append({"node":item,"begin":item.visibility_range_begin,"end":item.visibility_range_end,"visible":item.visible})
	review_camera = Camera3D.new()
	review_camera.name = "ValleyReviewCamera"
	review_camera.far = 1800
	add_child(review_camera)
	player.camera.make_current()
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(16,16)
	canvas.add_child(panel)
	var label := Label.new()
	label.add_theme_font_size_override("font_size",16)
	label.text = "SPLIT-CLOUD VALLEY  /  MOUNTAIN SECT / ENVIRONMENT REVIEW\nWASD move · Mouse look · Tab first/third · M map · V valley view · R forest start · Esc gallery\nReview jumps: 2 Gate · 3 Living · 4 Training · 5 Main Hall · 6 Garden · 7 Library · 8 Alchemy · E nearby doors"
	panel.add_child(label)
	location = Label.new()
	location.position = Vector2(18,672)
	location.add_theme_font_size_override("font_size",16)
	canvas.add_child(location)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(_delta: float) -> void:
	if location:
		location.text = "520 × 640 m playable valley  |  x %.0f / z %.0f m  |  elevation %.1f m  |  environment polish review"%[player.position.x,player.position.z,player.position.y]
	if player.position.y < -40: reset_start()

func set_walk() -> void:
	overview = false
	set_map_models(false)
	$MapLabels.visible = false
	player.camera.make_current()
	player.set_physics_process(true)
	player.set_process_unhandled_input(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func map_view() -> void:
	overview = true
	set_map_models(true)
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	review_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	review_camera.size = 740
	review_camera.position = Vector3(0,850,32)
	review_camera.look_at(Vector3(0,0,32),Vector3.FORWARD)
	review_camera.make_current()
	$MapLabels.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func set_map_models(enabled: bool) -> void:
	# An 850 m-high layout camera needs near models without distance culling.
	# Temporarily hide their distant duplicates, then restore normal walking ranges.
	for record: Dictionary in model_ranges:
		var item: GeometryInstance3D = record.node
		item.visible = record.visible and (not enabled or record.begin==0)
		item.visibility_range_begin = 0 if enabled else record.begin
		item.visibility_range_end = 0 if enabled else record.end

func valley_view() -> void:
	map_view()
	$MapLabels.visible = false
	review_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	review_camera.fov = 64
	review_camera.position = Vector3(285,245,365)
	review_camera.look_at(Vector3(-5,30,-44))

func jump_to(point: Vector3, yaw: float = 0.0) -> void:
	player.position = point
	player.velocity = Vector3.ZERO
	player.drive = Vector3.ZERO
	player.yaw = yaw
	player.pitch = -.08
	player.update_camera()
	set_walk()

func reset_start() -> void: jump_to(Vector3(12,.12,320),.8)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo): return
	var code: int = event.physical_keycode
	if code in STOPS:
		jump_to(STOPS[code][0],STOPS[code][1])
		return
	match code:
		KEY_M, KEY_1:
			if overview: set_walk()
			else: map_view()
		KEY_V: valley_view()
		KEY_R: reset_start()
		KEY_E:
			if player.position.distance_to($Buildings/sect_gate.position)<24: $Buildings/sect_gate.request_toggle()
			if player.position.distance_to($Buildings/main_sect_hall.position)<28:
				for door in $Buildings/main_sect_hall.doors: door.request_toggle()

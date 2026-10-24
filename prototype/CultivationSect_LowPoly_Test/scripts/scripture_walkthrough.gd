extends Node3D
## Inspection room only; uses the existing unchanged 1.8m review controller.
const PLAYER = preload("res://scripts/training_inspection_player.gd")
var automated := false
var player: CharacterBody3D
var facility: Node3D
var overlay: Label
var inspection_authorized := false
var access_message := "Archive entry locked. E: request access. G: toggle inspection authorization."
func _ready() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("8eaaa9")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d5e3da")
	environment.ambient_light_energy = .55
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-30,0)
	sun.light_color = Color("fff0d8")
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 100
	add_child(sun)
	facility = load("res://scenes/buildings/scripture_pavilion.tscn").instantiate()
	add_child(facility)
	var stage := StaticBody3D.new()
	stage.name = "InspectionStageOnly"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100,.1,100)
	shape.shape = box
	shape.position.y = -.055
	stage.add_child(shape)
	add_child(stage)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(100,100)
	ground.mesh = plane
	ground.position.y = -.006
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("52615a")
	material.roughness = 1
	ground.material_override = material
	add_child(ground)
	player = CharacterBody3D.new()
	player.set_script(PLAYER)
	player.name = "InspectionPlayer"
	player.automated = automated
	player.position = Vector3(0,.03,14)
	add_child(player)
	facility.archive_gate.authorization_check = func(_actor: Node,permission: String) -> bool: return inspection_authorized and permission == facility.specification.archive.permission_id
	facility.archive_gate.access_feedback.connect(func(message: String,_granted: bool):access_message = message)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(16,16)
	canvas.add_child(panel)
	overlay = Label.new()
	overlay.add_theme_font_size_override("font_size",16)
	panel.add_child(overlay)
	update_overlay()
func update_overlay() -> void:
	if overlay and player:
		overlay.text = "SCRIPTURE PAVILION — INSPECTION WALKTHROUGH\n1.8 m test figure · "+("Third-person" if player.third_person else "First-person")+"\nWASD move · Mouse look · Tab camera · Esc gallery\nE: archive gate · G: inspection authorization "+("GRANTED" if inspection_authorized else "DENIED")+"\n"+access_message
func _process(_delta: float) -> void: update_overlay()

func set_inspection_authorized(value: bool) -> void:
	inspection_authorized = value
	access_message = "Inspection authorization granted." if value else "Inspection authorization revoked; archive secured."
	if not value:facility.archive_gate.request_close()
	update_overlay()

func request_archive_interaction() -> Dictionary:
	var result: Dictionary = facility.archive_gate.request_open(player)
	update_overlay()
	return result

func _unhandled_input(event: InputEvent) -> void:
	if automated:return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E:request_archive_interaction()
		if event.physical_keycode == KEY_G:set_inspection_authorized(not inspection_authorized)

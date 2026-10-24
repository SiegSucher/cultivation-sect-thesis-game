extends Node3D
## Isolated rehearsal room. Stage ground/light and player are not asset exports.
const PLAYER = preload("res://scripts/training_inspection_player.gd")
var automated := false
var player: CharacterBody3D
var facility: Node3D
var overlay: Label

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
	sun.directional_shadow_max_distance = 180
	add_child(sun)
	facility = load("res://baseline/stage23_training.tscn").instantiate()
	add_child(facility)
	var floor_body := StaticBody3D.new()
	floor_body.name = "InspectionStageOnly"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(140,.10,130)
	shape.shape = box
	shape.position.y = -.055
	floor_body.add_child(shape)
	add_child(floor_body)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(140,130)
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
	player.position = Vector3(0,.32,25.5)
	add_child(player)
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
		overlay.text = "MARTIAL TRAINING GROUND — INSPECTION WALKTHROUGH\n1.8 m test figure · "+("Third-person" if player.third_person else "First-person")+"\nWASD move · Mouse look · Tab camera · Esc gallery"

func _process(_delta: float) -> void: update_overlay()

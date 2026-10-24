extends Node3D
## Standalone reusable prop. The assembled yard batches the same meshes.
const ROOT := "res://assets/architecture/martial_training_ground/"
const COLLISION = preload("res://scripts/training_collision.gd")
@export_enum("arm_dummy", "striking_post", "sword_rack", "staff_rack", "rest_bench", "stone_weight", "thrust_target") var kind := "arm_dummy"

func _ready() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"martial_training_ground.json"))
	var visual: Node3D = load(ROOT+kind+".glb").instantiate()
	visual.name = "BlenderEquipment"
	add_child(visual)
	var body := StaticBody3D.new()
	body.name = "EquipmentCollision"
	body.collision_layer = 1
	body.collision_mask = 2
	add_child(body)
	COLLISION.add_shapes(body, spec.prop_definitions[kind].solid_shapes)

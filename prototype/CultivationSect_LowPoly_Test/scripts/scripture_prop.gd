extends Node3D
## Optional independently reusable library furniture, origin at its feet.
const ROOT := "res://assets/architecture/scripture_pavilion/"
const COLLISION = preload("res://scripts/training_collision.gd")
@export var kind := "scripture_shelf"
func _ready() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"scripture_pavilion.json"))
	var model: Node3D = load(ROOT+kind+".glb").instantiate()
	model.name = "BlenderFurniture"
	add_child(model)
	var body := StaticBody3D.new()
	body.name = "FurnitureCollision"
	body.collision_layer = 1
	body.collision_mask = 2
	add_child(body)
	COLLISION.add_shapes(body,spec.prop_definitions[kind].solid_shapes)

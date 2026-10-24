extends Node3D
## New Blender-authored hall with an independent gallery door preview.

const ROOT := "res://assets/architecture/tang_main_hall/"
const DOOR = preload("res://scripts/hall_preview_door.gd")
@export var sect_name := "MAIN SECT HALL":
	set(value):
		sect_name = value
		if plaque: plaque.text = value
var plaque: Label3D
var specification: Dictionary
var doors: Array[Node3D] = []
var main_door: Node3D
var static_model: Node3D
var distant_model: Node3D

func vector(a: Array) -> Vector3:
	return Vector3(a[0],a[1],a[2])

func _ready() -> void:
	specification = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"main_sect_hall.json"))
	static_model = load(ROOT+"main_sect_hall.glb").instantiate()
	static_model.name = "BlenderArchitecture"
	add_child(static_model)
	distant_model = load(ROOT+"main_sect_hall_lod.glb").instantiate()
	distant_model.name = "DistantExterior"
	add_child(distant_model)
	for item: GeometryInstance3D in static_model.find_children("*","GeometryInstance3D",true,false):
		item.visibility_range_end = 95
	for item: GeometryInstance3D in distant_model.find_children("*","GeometryInstance3D",true,false):
		item.visibility_range_begin = 95
		item.visibility_range_end = 300
	var solid := StaticBody3D.new()
	solid.name = "AuthoredSimpleCollision"
	solid.collision_layer = 1
	solid.collision_mask = 2
	solid.add_to_group("solid_world")
	add_child(solid)
	for i in range(specification.solid_shapes.size()):
		var record: Dictionary = specification.solid_shapes[i]
		var shape := CollisionShape3D.new()
		shape.name = String(record.name).validate_node_name()+"_%03d"%i
		if record.type == "box":
			var box := BoxShape3D.new()
			box.size = vector(record.size)
			shape.shape = box
			shape.position = vector(record.position)
		elif record.type == "cylinder":
			var cylinder := CylinderShape3D.new()
			cylinder.radius = record.radius
			cylinder.height = record.height
			shape.shape = cylinder
			shape.position = vector(record.position)
		else:
			var convex := ConvexPolygonShape3D.new()
			var points := PackedVector3Array()
			for point: Array in record.points:
				points.append(vector(point))
			convex.points = points
			shape.shape = convex
		solid.add_child(shape)
	var roof := ConcavePolygonShape3D.new()
	var faces := PackedVector3Array()
	for point: Array in specification.roof_collision_faces:
		faces.append(vector(point))
	roof.set_faces(faces)
	roof.backface_collision = true
	var roof_shape := CollisionShape3D.new()
	roof_shape.name = "RoofAndCameraClearance"
	roof_shape.shape = roof
	solid.add_child(roof_shape)
	main_door = make_door("GrandDoubleEntrance",specification.door,"grand_door_leaf.glb")
	for i in range(specification.room_doors.size()):
		make_door("PrivateRoomDoor"+str(i+1),specification.room_doors[i],"room_door_leaf.glb")
	for at: Array in specification.lights:
		var light := OmniLight3D.new()
		light.name = "WarmHallLanternLight"
		light.position = vector(at)
		light.light_color = Color("ffe0a8")
		light.light_energy = 1.15
		light.omni_range = 15 if absf(float(at[0])) < 10 else 9
		light.shadow_enabled = false
		add_child(light)
	var signage := Node3D.new()
	signage.name = "CustomizableSignage"
	add_child(signage)
	plaque = Label3D.new()
	plaque.text = sect_name
	plaque.position = vector(specification.plaque.position)
	plaque.font_size = 64
	plaque.pixel_size = .007
	plaque.modulate = Color("b7a16d")
	plaque.outline_size = 0
	signage.add_child(plaque)

func make_door(label: String, record: Dictionary, leaf_file: String) -> Node3D:
	var door := Node3D.new()
	door.name = label
	door.set_script(DOOR)
	door.opening_width = float(record.width)
	door.height = float(record.height)
	door.position = vector(record.position)
	door.rotation.y = float(record.get("rotation_y",0.0))
	add_child(door)
	# Attach the newly authored Blender leaves to the gallery-only hinges.
	for i in range(door.leaves.size()):
		var body: AnimatableBody3D = door.leaves[i]
		for child: Node in body.get_children():
			if child is MeshInstance3D:
				body.remove_child(child)
				child.queue_free()
		var visual: Node3D = load(ROOT+leaf_file).instantiate()
		visual.name = "BlenderCarvedLeaf"
		if i == 1:
			visual.scale.x = -1
		body.add_child(visual)
	doors.append(door)
	return door

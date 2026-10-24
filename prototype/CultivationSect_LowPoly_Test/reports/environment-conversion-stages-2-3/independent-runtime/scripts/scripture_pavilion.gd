extends Node3D
## Standalone library; all positions are local. No gallery or player dependency.
const ROOT := "res://assets/architecture/scripture_pavilion/"
const COLLISION = preload("res://scripts/training_collision.gd")
const ACCESS_GATE = preload("res://scripts/archive_access_gate.gd")
@export var pavilion_name := "SCRIPTURE PAVILION":
	set(value):
		pavilion_name = value
		if plaque: plaque.text = value
var plaque: Label3D
var specification: Dictionary
var static_model: Node3D
var distant_model: Node3D
var furnishings: Node3D
var furniture_instances := 0
var archive_gate: Node3D

func _ready() -> void:
	specification = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"scripture_pavilion.json"))
	static_model = load(ROOT+"scripture_pavilion.glb").instantiate()
	static_model.name = "BlenderArchitecture"
	add_child(static_model)
	distant_model = load(ROOT+"scripture_pavilion_lod.glb").instantiate()
	distant_model.name = "DistantExterior"
	add_child(distant_model)
	for item: GeometryInstance3D in static_model.find_children("*","GeometryInstance3D",true,false):
		item.visibility_range_end = 100
		item.lod_bias = 128.0
	for item: GeometryInstance3D in distant_model.find_children("*","GeometryInstance3D",true,false):
		item.visibility_range_begin = 100
		item.visibility_range_end = 350
		item.lod_bias = 128.0
	var body := StaticBody3D.new()
	body.name = "AuthoredLibraryCollision"
	body.collision_layer = 1
	body.collision_mask = 2
	add_child(body)
	COLLISION.add_shapes(body,specification.solid_shapes)
	var roof := ConcavePolygonShape3D.new()
	var faces := PackedVector3Array()
	for point: Array in specification.roof_collision_faces: faces.append(COLLISION.vector(point))
	roof.set_faces(faces)
	roof.backface_collision = true
	var roof_shape := CollisionShape3D.new()
	roof_shape.name = "RoofUndersides"
	roof_shape.shape = roof
	body.add_child(roof_shape)
	furnishings = Node3D.new()
	furnishings.name = "LibraryFurniture"
	add_child(furnishings)
	for kind: String in specification.prop_definitions: make_furniture(kind)
	archive_gate = Node3D.new()
	archive_gate.name = "RestrictedArchiveGate"
	archive_gate.set_script(ACCESS_GATE)
	archive_gate.position = COLLISION.vector(specification.archive.gate_position)
	archive_gate.permission_id = specification.archive.permission_id
	add_child(archive_gate)
	for record: Dictionary in specification.plaques:
		var text := Label3D.new()
		text.text = record.text
		text.position = COLLISION.vector(record.position)
		text.font_size = 64
		text.pixel_size = record.pixel_size
		text.outline_size = 0
		text.modulate = Color("c5ad77")
		text.visibility_range_end = 100
		add_child(text)
		if record.text == "SCRIPTURE PAVILION":
			plaque = text
			plaque.text = pavilion_name
	# Few unshadowed local lights illuminate rooms without dozens of shadow maps.
	for position: Vector3 in [Vector3(0,3.8,1),Vector3(0,3.8,-4),Vector3(-5,8.1,0),Vector3(5,8.1,-4),Vector3(0,12.7,-2),Vector3(5,12.7,2)]:
		var light := OmniLight3D.new()
		light.position = position
		light.light_color = Color("ffe2af")
		light.light_energy = .85
		light.omni_range = 8.5
		light.omni_attenuation = 1.4
		light.shadow_enabled = false
		add_child(light)

func make_furniture(kind: String) -> void:
	var group := Node3D.new()
	group.name = kind.to_pascal_case()
	furnishings.add_child(group)
	var transforms: Array[Transform3D] = []
	for record: Dictionary in specification.prop_instances:
		if record.kind != kind: continue
		var local := Transform3D(Basis(Vector3.UP,float(record.rotation_y)),COLLISION.vector(record.position))
		transforms.append(local)
		var body := StaticBody3D.new()
		body.name = kind+"_%02d"%transforms.size()
		body.collision_layer = 1
		body.collision_mask = 2
		group.add_child(body)
		COLLISION.add_shapes(body,specification.prop_definitions[kind].solid_shapes,local)
		furniture_instances += 1
	var source: Node3D = load(ROOT+kind+".glb").instantiate()
	for mesh: MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = mesh.mesh
		multimesh.instance_count = transforms.size()
		for i in range(transforms.size()): multimesh.set_instance_transform(i,transforms[i]*mesh.transform)
		var visual := MultiMeshInstance3D.new()
		visual.name = kind+"_"+mesh.name
		visual.multimesh = multimesh
		visual.visibility_range_end = 100
		group.add_child(visual)
	source.free()

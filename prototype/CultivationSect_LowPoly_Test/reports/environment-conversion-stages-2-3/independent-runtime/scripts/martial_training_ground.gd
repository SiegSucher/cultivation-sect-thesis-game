extends Node3D
## Original standalone facility. All coordinates are asset-local, in metres.
const ROOT := "res://assets/architecture/martial_training_ground/"
const COLLISION = preload("res://scripts/training_collision.gd")
@export var sect_name := "MARTIAL TRAINING":
	set(value):
		sect_name = value
		if plaque: plaque.text = value
var plaque: Label3D
var specification: Dictionary
var static_model: Node3D
var distant_model: Node3D
var equipment: Node3D
var equipment_instances := 0

func _ready() -> void:
	specification = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"martial_training_ground.json"))
	static_model = load(ROOT+"martial_training_ground.glb").instantiate()
	static_model.name = "BlenderArchitecture"
	add_child(static_model)
	distant_model = load(ROOT+"martial_training_ground_lod.glb").instantiate()
	distant_model.name = "DistantExterior"
	add_child(distant_model)
	for item: GeometryInstance3D in static_model.find_children("*","GeometryInstance3D",true,false):
		item.visibility_range_end = 140
		item.lod_bias = 128.0
		# Flat ground receives equipment/roof shadows but need not cast shadows
		# onto itself. Large coplanar slab batches otherwise show shadow acne.
		if String(item.name) in ["Training_CourtPaving","Training_Paving","Training_PackedEarth","Training_Joint"]:
			item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			# Preserve the thin slab tops until the authored distant model takes
			# over. Automatic mesh reduction can collapse these into patchy faces.
			item.lod_bias = 128.0
	for item: GeometryInstance3D in distant_model.find_children("*","GeometryInstance3D",true,false):
		item.visibility_range_begin = 140
		item.visibility_range_end = 400
		item.lod_bias = 128.0
	var body := StaticBody3D.new()
	body.name = "AuthoredStructureCollision"
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
	roof_shape.name = "StaticRoofUndersides"
	roof_shape.shape = roof
	body.add_child(roof_shape)
	equipment = Node3D.new()
	equipment.name = "EquipmentByKind"
	add_child(equipment)
	for kind: String in specification.prop_definitions: make_equipment(kind)
	plaque = Label3D.new()
	plaque.name = "CustomizableInstructorPlaque"
	plaque.text = sect_name
	plaque.position = COLLISION.vector(specification.plaque.position)
	plaque.font_size = 64
	plaque.pixel_size = .005
	plaque.outline_size = 0
	plaque.modulate = Color("b7a16d")
	add_child(plaque)

func make_equipment(kind: String) -> void:
	var group := Node3D.new()
	group.name = kind.to_pascal_case()
	equipment.add_child(group)
	var records: Array = specification.prop_instances.filter(func(p: Dictionary) -> bool: return p.kind == kind)
	var transforms: Array[Transform3D] = []
	for record: Dictionary in records:
		var local := Transform3D(Basis(Vector3.UP,float(record.rotation_y)),COLLISION.vector(record.position))
		transforms.append(local)
		var body := StaticBody3D.new()
		body.name = kind+"_%02d"%transforms.size()
		body.collision_layer = 1
		body.collision_mask = 2
		group.add_child(body)
		COLLISION.add_shapes(body,specification.prop_definitions[kind].solid_shapes,local)
		equipment_instances += 1
	var source: Node3D = load(ROOT+kind+".glb").instantiate()
	# One draw batch per material for ALL instances of a given prop kind. Collision
	# stays individual, so repeated equipment does not become one giant collider.
	for mesh: MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = mesh.mesh
		multimesh.instance_count = transforms.size()
		for i in range(transforms.size()): multimesh.set_instance_transform(i,transforms[i]*mesh.transform)
		var visual := MultiMeshInstance3D.new()
		visual.name = kind+"_"+mesh.name
		visual.multimesh = multimesh
		visual.visibility_range_end = 140
		group.add_child(visual)
	source.free()

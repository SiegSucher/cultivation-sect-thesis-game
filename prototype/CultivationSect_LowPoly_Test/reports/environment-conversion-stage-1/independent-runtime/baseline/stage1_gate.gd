@tool
extends Node3D
## Standalone NEW gateway. No town/player dependency. All dimensions are metres.
## In-editor rebuilding is explicit so property changes cannot duplicate parts.
const ROOT := "res://baseline/stage1_gate/"
@export var sect_name := "SECT GATE":
	set(value):
		sect_name = value
		for plaque: Label3D in plaques:
			plaque.text = value
@export var preview_open := false
var specification: Dictionary
var static_model: Node3D
var distant_model: Node3D
var hinges: Array[Node3D] = []
var leaves: Array[AnimatableBody3D] = []
var plaques: Array[Label3D] = []
var angle := 0.0

func vec(a: Array) -> Vector3:
	return Vector3(a[0],a[1],a[2])

func _ready() -> void:
	specification = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"sect_gate.json"))
	static_model = load(ROOT+"sect_gate.glb").instantiate()
	static_model.name = "Architecture"
	add_child(static_model)
	distant_model = load(ROOT+"sect_gate_lod.glb").instantiate()
	distant_model.name = "DistantExterior"
	add_child(distant_model)
	# Distances are asset-local viewing defaults, not integrated-game tuning.
	for mesh: GeometryInstance3D in static_model.find_children("*","GeometryInstance3D",true,false):
		mesh.visibility_range_end = 90
	for mesh: GeometryInstance3D in distant_model.find_children("*","GeometryInstance3D",true,false):
		mesh.visibility_range_begin = 90
		mesh.visibility_range_end = 300
	var collision := StaticBody3D.new()
	collision.name = "StructuralCollision"
	collision.collision_layer = 1
	collision.collision_mask = 2
	add_child(collision)
	for record: Dictionary in specification.solid_shapes:
		var shape := CollisionShape3D.new()
		shape.name = String(record.name).validate_node_name()+str(collision.get_child_count())
		match record.type:
			"box":
				var box := BoxShape3D.new()
				box.size = vec(record.size)
				shape.shape = box
				shape.position = vec(record.position)
			"cylinder":
				var cylinder := CylinderShape3D.new()
				cylinder.radius = record.radius
				cylinder.height = record.height
				shape.shape = cylinder
				shape.position = vec(record.position)
			"convex":
				var convex := ConvexPolygonShape3D.new()
				var points := PackedVector3Array()
				for point: Array in record.points: points.append(vec(point))
				convex.points = points
				shape.shape = convex
		collision.add_child(shape)
	var roof := ConcavePolygonShape3D.new()
	var faces := PackedVector3Array()
	for point: Array in specification.roof_collision_faces: faces.append(vec(point))
	roof.set_faces(faces)
	roof.backface_collision = true
	var soffit := CollisionShape3D.new()
	soffit.name = "RoofShellCollision"
	soffit.shape = roof
	collision.add_child(soffit)
	var door_group := Node3D.new()
	door_group.name = "Doors"
	add_child(door_group)
	for i in range(2):
		var record: Dictionary = specification.doors[i]
		var hinge := Node3D.new()
		hinge.name = "LeftHinge" if i == 0 else "RightHinge"
		hinge.position = vec(record.position)
		door_group.add_child(hinge)
		hinges.append(hinge)
		var body := AnimatableBody3D.new()
		body.name = "TimberDoorLeaf"
		body.sync_to_physics = false
		body.collision_layer = 1
		body.collision_mask = 2
		hinge.add_child(body)
		leaves.append(body)
		body.add_child(load(ROOT+record.file).instantiate())
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		shape.name = "LeafCollision"
		box.size = Vector3(4.145,6.575,.30)
		shape.shape = box
		shape.position = Vector3(2.1025 if i == 0 else -2.1025,3.3225,.34)
		body.add_child(shape)
	var signage := Node3D.new()
	signage.name = "CustomizableSignage"
	add_child(signage)
	for side: float in [-1,1]:
		var label := Label3D.new()
		label.name = "FrontPlaque" if side == 1 else "RearPlaque"
		label.text = sect_name
		label.position = Vector3(0,10.12,side*3.30)
		label.rotation.y = PI if side == -1 else 0
		label.font_size = 64
		label.pixel_size = .006
		label.modulate = Color("b7a16d")
		label.outline_size = 0
		label.no_depth_test = false
		signage.add_child(label)
		plaques.append(label)
	for x: float in [-5.48,5.48]:
		var light := OmniLight3D.new()
		light.name = "LanternGlow"
		light.position = Vector3(x,6.4,3.8)
		light.omni_range = 3
		light.light_energy = .45
		light.light_color = Color("e8c48a")
		add_child(light)
	set_open_immediate(preview_open)

func request_toggle() -> void:
	preview_open = not preview_open

func set_open_immediate(value: bool) -> void:
	preview_open = value
	angle = 90.0 if value else 0.0
	update_hinges()

func update_hinges() -> void:
	for i in range(hinges.size()):
		hinges[i].rotation.y = deg_to_rad(angle)*float(specification.doors[i].rotation_sign)

func _physics_process(delta: float) -> void:
	angle = move_toward(angle,90.0 if preview_open else 0.0,45.0*delta)
	update_hinges()

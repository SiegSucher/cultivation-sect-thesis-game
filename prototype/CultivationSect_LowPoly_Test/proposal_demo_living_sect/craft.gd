extends RefCounted
## Small authoring helper. Static details are merged by material: many props, few draw calls.
var batches := {}
var materials := {}
var root: Node3D
func _init(parent: Node3D) -> void: root = parent
func mat(hex: String) -> StandardMaterial3D:
	if materials.has(hex): return materials[hex]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.roughness = .9
	materials[hex] = m
	return m
func add(mesh: Mesh, at: Vector3, hex: String, rotation := Vector3.ZERO, scale := Vector3.ONE) -> void:
	if not batches.has(hex):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		batches[hex] = st
	batches[hex].append_from(mesh,0,Transform3D(Basis.from_euler(rotation).scaled(scale),at))
func box(at: Vector3, size: Vector3, hex: String, yaw := 0.0, solid := false) -> void:
	var m := BoxMesh.new()
	m.size = size
	add(m,at,hex,Vector3(0,yaw,0))
	if solid: collider(at,size,yaw)
func cylinder(at: Vector3, top: float, bottom: float, height: float, hex: String, rotation := Vector3.ZERO, sides := 10) -> void:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = height
	m.radial_segments = sides
	add(m,at,hex,rotation)
func ball(at: Vector3, size: Vector3, hex: String) -> void:
	var m := SphereMesh.new()
	m.radius = .5
	m.height = 1
	m.radial_segments = 10
	m.rings = 5
	add(m,at,hex,Vector3.ZERO,size)
func beam(a: Vector3, b: Vector3, radius: float, hex: String) -> void:
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius*1.15
	m.height = a.distance_to(b)
	m.radial_segments = 7
	var basis := Basis(Quaternion(Vector3.UP,(b-a).normalized()))
	if not batches.has(hex):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		batches[hex] = st
	batches[hex].append_from(m,0,Transform3D(basis,(a+b)*.5))
func collider(at: Vector3, size: Vector3, yaw := 0.0) -> void:
	var body := StaticBody3D.new()
	body.position = at
	body.rotation.y = yaw
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	root.add_child(body)
func finish() -> void:
	for hex: String in batches:
		var mi := MeshInstance3D.new()
		mi.name = "Craft_"+hex
		mi.mesh = batches[hex].commit()
		mi.material_override = mat(hex)
		root.add_child(mi)
	batches.clear()

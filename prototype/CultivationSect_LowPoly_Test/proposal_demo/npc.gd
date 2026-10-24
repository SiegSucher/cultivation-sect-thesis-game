extends Node3D
## PHASE-LOCAL PLACEHOLDER character: the project has no character model. A simple robed figure
## with a name label, used for the stationary Guide and Mentor. It faces -Z.
## Set title, colours and prop before adding it to the tree.
var title := "Mentor"
var robe := Color("ece4cf")
var over := Color("2f6b5f")
var sash := Color("cda668")
var prop := "staff"            # "staff" or "lantern"
var beard := true

func part(mesh: Mesh, at: Vector3, color: Color, tilt := Vector3.ZERO, glow := false) -> void:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.position = at
	m.rotation_degrees = tilt
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = .9
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.5
	m.material_override = mat
	add_child(m)

func cylinder(top: float, bottom: float, height: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = height
	c.radial_segments = 10
	return c

func sphere(radius: float, hemisphere := false) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius*(1.0 if hemisphere else 2.0)
	s.is_hemisphere = hemisphere
	s.radial_segments = 12
	s.rings = 6
	return s

func _ready() -> void:
	part(cylinder(.21, .42, 1.12), Vector3(0, .56, 0), robe)
	part(cylinder(.2, .27, .52), Vector3(0, 1.36, 0), over)
	part(cylinder(.28, .28, .08), Vector3(0, 1.12, 0), sash)
	for s in [-1.0, 1.0]:
		var sleeve := CapsuleMesh.new()
		sleeve.radius = .1
		sleeve.height = .62
		part(sleeve, Vector3(s*.3, 1.25, 0), over, Vector3(0, 0, s*12))
	part(sphere(.17), Vector3(0, 1.79, 0), Color("e3c3a0"))
	part(sphere(.178, true), Vector3(0, 1.81, .015), Color("2b2420"))
	part(sphere(.085), Vector3(0, 2.0, .03), Color("2b2420"))
	if beard: part(cylinder(.07, 0.0, .22), Vector3(0, 1.6, -.12), Color("e9e6df"))
	if prop == "staff":
		part(cylinder(.025, .03, 2.05), Vector3(.44, 1.02, -.08), Color("6b4a33"))
		part(sphere(.06), Vector3(.44, 2.07, -.08), Color("7fe6ff"), Vector3.ZERO, true)
	else:
		part(cylinder(.015, .015, .5), Vector3(.42, 1.12, -.12), Color("6b4a33"))
		var lamp := BoxMesh.new()
		lamp.size = Vector3(.16, .2, .16)
		part(lamp, Vector3(.42, .8, -.12), Color("ffcf7a"), Vector3.ZERO, true)
	var name_label := Label3D.new()
	name_label.text = title
	name_label.position.y = 2.42
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.font_size = 64
	name_label.pixel_size = .006
	name_label.outline_size = 12
	name_label.modulate = Color("e6d9b8")
	add_child(name_label)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = .4
	capsule.height = 1.9
	shape.shape = capsule
	shape.position.y = .95
	body.add_child(shape)
	add_child(body)

func face(point: Vector3) -> void:
	var flat := Vector3(point.x, global_position.y, point.z)
	if flat.distance_to(global_position) > .01: look_at(flat, Vector3.UP)

extends Node3D
## A physical seal guards a short crossing; the ward stands beyond it, beside the living street.
## All new geometry is demo-local. The inherited terrain and buildings stay untouched.
const BRIDGE_AT := Vector3(-9, 10, 22)
const WARD_AT := Vector3(-9, 10, 11)
var bridge: Node3D
var ward: Node3D
var barrier: MeshInstance3D
var barrier_collision: CollisionShape3D
var bridge_rune: MeshInstance3D
var ward_stones: Array[MeshInstance3D] = []
var ward_lights: Array[OmniLight3D] = []
var veil: MeshInstance3D
var bridge_label: Label3D
var ward_label: Label3D
var crossing_open := false
var ward_active := false
var reward_tween: Tween
var result_camera: Camera3D

func material(colour: Color, energy := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = .8
	mat.emission_enabled = energy > 0
	mat.emission = colour
	mat.emission_energy_multiplier = energy
	return mat

func part(parent: Node3D, shape: Mesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.mesh = shape
	mesh.position = at
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh

func collider(parent: Node3D, at: Vector3, size: Vector3) -> CollisionShape3D:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position = at
	body.add_child(collision)
	parent.add_child(body)
	return collision

func box(parent: Node3D, at: Vector3, size: Vector3, colour: String, solid := false) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	var mesh := part(parent, shape, at, material(Color(colour)))
	if solid: collider(parent, at, size)
	return mesh

func label_at(parent: Node3D, text: String, at: Vector3) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = 34
	label.pixel_size = .006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 7
	parent.add_child(label)
	return label

func approach_ramp(parent: Node3D, at: Vector3, angle: float, width := 3.2) -> void:
	# The inherited controller walks slopes; these short ramps avoid a vertical step at each end.
	var ramp := Node3D.new()
	ramp.position = at
	ramp.rotation.x = angle
	parent.add_child(ramp)
	box(ramp, Vector3.ZERO, Vector3(width, .08, 1.2), "8f8062", true)

func setup() -> void:
	name = "MainStory"
	bridge = Node3D.new()
	bridge.name = "SilentCrossing"
	bridge.position = BRIDGE_AT
	add_child(bridge)
	box(bridge, Vector3(0, .025, -4), Vector3(4.8, .05, 4), "273a49")
	for side in [-1, 1]:
		box(bridge, Vector3(side*2.45, .18, -4), Vector3(.35, .36, 4.5), "637477", true)
		box(bridge, Vector3(side*1.65, .6, -3.5), Vector3(.12, 1.1, 6), "675945", true)
		for z in [-.5, -3.5, -6.5]: box(bridge, Vector3(side*1.65, .6, z), Vector3(.23, 1.2, .23), "887957", true)
	for i in 15: box(bridge, Vector3(0, .1, -.3-i*.43), Vector3(3.2, .2, .39), "8f8062", true)
	approach_ramp(bridge, Vector3(0, .1, .4), .17)
	approach_ramp(bridge, Vector3(0, .1, -7.0), -.17)
	# Only the new bridge is blocked; the established central route remains open.
	barrier = box(bridge, Vector3(0, 1.5, -1.2), Vector3(3.1, 2.8, .08), "6988c9")
	var mat := material(Color(.35, .55, 1, .3), 1.1)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	barrier.material_override = mat
	barrier_collision = collider(bridge, Vector3(0, 1.4, -1.2), Vector3(3.3, 2.8, .2))
	var sigil: MeshInstance3D = get_parent().sigil(.9, 1.0, Color("9bb9ff"))
	sigil.rotation_degrees.x = 90
	barrier.add_child(sigil)
	var rune := TorusMesh.new()
	rune.inner_radius = .35
	rune.outer_radius = .48
	bridge_rune = part(bridge, rune, Vector3(0, .23, .1), material(Color("e2b265"), 1))
	bridge_label = label_at(bridge, "THE SILENT CROSSING\nRestore the public basin first", Vector3(0, 3.1, -.9))
	ward = Node3D.new()
	ward.name = "ThreefoldWard"
	ward.position = WARD_AT
	add_child(ward)
	box(ward, Vector3(0, .1, 0), Vector3(4, .2, 4), "657b7f", true)
	approach_ramp(ward, Vector3(0, .1, 2.5), .17, 3.6)
	box(ward, Vector3(0, .5, 0), Vector3(1.5, .8, 1.2), "455c68", true)
	for i in 3:
		var crystal := PrismMesh.new()
		crystal.size = Vector3(.45, 1.1, .45)
		var at := Vector3(-1.25+i*1.25, 1.1, -.7 if i != 1 else .65)
		ward_stones.append(part(ward, crystal, at, material(Color("48576b"))))
		var light := OmniLight3D.new()
		light.position = at
		light.light_color = Color("88e8d5")
		light.omni_range = 4
		ward.add_child(light)
		ward_lights.append(light)
	ward_label = label_at(ward, "THE THREEFOLD WARD\nBeyond the sealed crossing", Vector3(0, 2.8, 0))
	var sphere := SphereMesh.new()
	sphere.radius = 3.0
	sphere.height = 6.0
	var veil_mat := material(Color(.25, .9, .8, .09), .45)
	veil_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	veil_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	veil = part(ward, sphere, Vector3(0, .5, 0), veil_mat)
	veil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	result_camera = Camera3D.new()
	result_camera.fov = 60
	result_camera.far = 800
	add_child(result_camera)
	reset()

func frame_result(quest_stage: int) -> void:
	var target := bridge.position+Vector3(0, 1.0, -3) if quest_stage == 3 else ward.position+Vector3.UP
	result_camera.position = target+Vector3(4.0, 2.8, 7)
	result_camera.look_at(target)
	result_camera.make_current()

func unlock_crossing() -> void:
	bridge_label.text = "THE SILENT CROSSING\nMain quest / verify the seal"

func open_crossing() -> void:
	crossing_open = true
	barrier.hide()
	barrier_collision.set_deferred("disabled", true)
	bridge_rune.material_override = material(Color("88e8d5"), 2)
	bridge_label.text = "THE SILENT CROSSING / OPEN"
	ward_label.text = "THE THREEFOLD WARD\nMain quest / restore three stones"

func activate_ward() -> void:
	ward_active = true
	if reward_tween: reward_tween.kill()
	reward_tween = create_tween().set_parallel()
	for i in 3:
		ward_stones[i].material_override = material(Color("88e8d5"), 1.8)
		reward_tween.tween_property(ward_stones[i], "position:y", 1.6, .7).set_delay(i*.3)
		reward_tween.tween_property(ward_lights[i], "light_energy", 1.0, .7).set_delay(i*.3)
	veil.show()
	veil.scale = Vector3.ONE*.15
	reward_tween.tween_property(veil, "scale", Vector3.ONE, 1.8)
	ward_label.text = "THREEFOLD WARD / PROTECTING THE SECT"

func reset() -> void:
	if reward_tween: reward_tween.kill()
	crossing_open = false
	ward_active = false
	if not barrier: return
	barrier.show()
	barrier_collision.set_deferred("disabled", false)
	bridge_rune.material_override = material(Color("e2b265"), 1)
	bridge_label.text = "THE SILENT CROSSING\nRestore the public basin first"
	ward_label.text = "THE THREEFOLD WARD\nBeyond the sealed crossing"
	veil.hide()
	for i in 3:
		ward_stones[i].position.y = 1.1
		ward_stones[i].material_override = material(Color("48576b"))
		ward_lights[i].light_energy = 0

extends Node3D
## PHASE-LOCAL PLACEHOLDER: the public basin. The project has no canonical basin model.
## Inactive: a dry stone bowl with a dim inscription ring. activate() lights the ring with qi,
## raises the water and starts the spout. reset() returns it to the inactive state.
## The water is a small animated shader (ripples and a Qi glow) that runs on the Compatibility
## renderer; a sigil on its surface lights on activation.
const WATER_SHADER := """
shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_opaque;
uniform vec4 deep : source_color = vec4(0.09, 0.33, 0.42, 1.0);
uniform vec4 shallow : source_color = vec4(0.42, 0.80, 0.88, 1.0);
uniform float glow = 0.0;
varying vec3 local;
void vertex() { local = VERTEX; }
void fragment() {
	float r = length(local.xz);
	float rings = sin(r * 15.0 - TIME * 2.6);
	float cross = sin((local.x + local.z) * 9.0 + TIME * 1.7) * sin((local.x - local.z) * 7.0 - TIME * 1.3);
	float h = 0.5 * rings + 0.5 * cross;
	ALBEDO = mix(deep.rgb, shallow.rgb, 0.35 + 0.22 * h + 0.25 * smoothstep(0.9, 1.27, r));
	ROUGHNESS = 0.12;
	SPECULAR = 0.7;
	EMISSION = shallow.rgb * glow * (0.55 + 0.45 * h);
	ALPHA = 0.9;
}
"""
const WATER_LOW := .24
const WATER_HIGH := .62
const RING_IDLE := Color("3d5a55")
const RING_QI := Color("7fe6ff")
var active := false
var water: MeshInstance3D
var water_mat: ShaderMaterial
var surface_sigil: MeshInstance3D
var ring_mat: StandardMaterial3D
var glow: OmniLight3D
var jet: CPUParticles3D
var sign_label: Label3D
var tween: Tween

func material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = .85
	return m

func part(mesh: Mesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.position = at
	m.material_override = mat
	add_child(m)
	return m

func _ready() -> void:
	var stone := material(Color("8f9a96"))
	var coping := material(Color("bcc6bd"))
	var bed := material(Color("4d5753"))
	var step := CylinderMesh.new()
	step.top_radius = 1.72
	step.bottom_radius = 1.78
	step.height = .14
	step.radial_segments = 8
	part(step, Vector3(0, .05, 0), coping)
	# Hollow octagonal bowl: an outer prism with the inner prism subtracted (floor at 0.2 m).
	var bowl := CSGCombiner3D.new()
	var outer := CSGCylinder3D.new()
	outer.radius = 1.5
	outer.height = .74
	outer.sides = 8
	outer.position.y = .37
	outer.material = stone
	var inner := CSGCylinder3D.new()
	inner.radius = 1.28
	inner.height = .8
	inner.sides = 8
	inner.position.y = .6
	inner.operation = CSGShape3D.OPERATION_SUBTRACTION
	inner.material = bed
	bowl.add_child(outer)
	bowl.add_child(inner)
	add_child(bowl)
	var column := CylinderMesh.new()
	column.top_radius = .13
	column.bottom_radius = .19
	column.height = 1.3
	column.radial_segments = 8
	part(column, Vector3(0, .85, 0), stone)
	var bud := SphereMesh.new()
	bud.radius = .2
	bud.height = .3
	part(bud, Vector3(0, 1.55, 0), coping)
	ring_mat = material(RING_IDLE)
	ring_mat.emission_enabled = true
	ring_mat.emission = RING_QI
	ring_mat.emission_energy_multiplier = 0
	var ring := TorusMesh.new()
	ring.inner_radius = .2
	ring.outer_radius = .3
	for y in [.95, 1.25]: part(ring, Vector3(0, y, 0), ring_mat)
	var shader := Shader.new()
	shader.code = WATER_SHADER
	water_mat = ShaderMaterial.new()
	water_mat.shader = shader
	var disc := CylinderMesh.new()
	disc.top_radius = 1.27
	disc.bottom_radius = 1.27
	disc.height = .04
	disc.radial_segments = 8
	water = part(disc, Vector3(0, WATER_LOW, 0), water_mat)
	surface_sigil = get_parent().sigil(1.2, 0.0) if get_parent().has_method("sigil") else MeshInstance3D.new()
	surface_sigil.position.y = .03
	water.add_child(surface_sigil)
	glow = OmniLight3D.new()
	glow.light_color = RING_QI
	glow.omni_range = 6
	glow.position.y = 1.4
	add_child(glow)
	jet = CPUParticles3D.new()
	jet.position.y = 1.7
	jet.amount = 90
	jet.lifetime = 1.0
	jet.direction = Vector3.UP
	jet.spread = 32
	jet.initial_velocity_min = 1.6
	jet.initial_velocity_max = 2.4
	jet.gravity = Vector3(0, -9.8, 0)
	var drop := SphereMesh.new()
	drop.radius = .045
	drop.height = .09
	drop.radial_segments = 6
	drop.rings = 3
	var drop_mat := material(Color("bfefff"))
	drop_mat.emission_enabled = true
	drop_mat.emission = Color("7fe6ff")
	drop_mat.emission_energy_multiplier = .8
	drop.material = drop_mat
	jet.mesh = drop
	add_child(jet)
	sign_label = Label3D.new()
	sign_label.position.y = 1.98
	sign_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign_label.font_size = 40
	sign_label.pixel_size = .006
	sign_label.outline_size = 10
	add_child(sign_label)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 1.6
	cylinder.height = .8
	shape.shape = cylinder
	shape.position.y = .4
	body.add_child(shape)
	add_child(body)
	reset()

func reset() -> void:
	if tween: tween.kill()
	active = false
	water.visible = false
	water.position.y = WATER_LOW
	water_mat.set_shader_parameter("glow", 0.0)
	if surface_sigil.material_override: surface_sigil.material_override.set_shader_parameter("strength", 0.0)
	ring_mat.albedo_color = RING_IDLE
	ring_mat.emission = RING_QI
	ring_mat.emission_energy_multiplier = 0
	glow.light_energy = 0
	jet.emitting = false
	jet.visible = false
	sign_label.text = "PUBLIC BASIN  ·  inactive"
	sign_label.modulate = Color("e6d9b8")

func activate() -> void:
	"""Qi lights the inscription ring, then water rises and the spout flows (about 2.6 s)."""
	if active: return
	active = true
	if tween: tween.kill()
	water.visible = true
	jet.visible = true
	ring_mat.albedo_color = RING_QI
	ring_mat.emission = RING_QI
	sign_label.text = "PUBLIC BASIN  ·  FLOWING"
	sign_label.modulate = Color("9ff0ff")
	tween = create_tween().set_parallel()
	tween.tween_property(ring_mat, "emission_energy_multiplier", 3.0, .8)
	tween.tween_property(glow, "light_energy", 1.8, 1.2)
	tween.tween_property(water, "position:y", WATER_HIGH, 2.4).set_delay(.4).set_trans(Tween.TRANS_SINE)
	tween.tween_property(water_mat, "shader_parameter/glow", .5, 2.4).set_delay(.4)
	if surface_sigil.material_override: tween.tween_property(surface_sigil.material_override, "shader_parameter/strength", .7, 1.6).set_delay(.9)
	tween.tween_callback(func() -> void: jet.emitting = true).set_delay(.6)

func sputter() -> void:
	"""Incorrect answer: the ring flickers amber and fades. The basin stays inactive."""
	if active: return
	if tween: tween.kill()
	ring_mat.emission = Color("ffb347")
	ring_mat.emission_energy_multiplier = 2.5
	tween = create_tween()
	tween.tween_property(ring_mat, "emission_energy_multiplier", 0.0, .7)

func stir() -> void:
	"""A correct basin inscription has run: the ring brightens in anticipation (no light, no water)."""
	if active: return
	if tween: tween.kill()
	ring_mat.emission = RING_QI
	tween = create_tween()
	tween.tween_property(ring_mat, "emission_energy_multiplier", 1.6, .4)
	tween.tween_property(ring_mat, "emission_energy_multiplier", .7, .8)

func ripple() -> void:
	"""The channelled Qi lands: a ring of light spreads across the bowl and fades."""
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = .9
	torus.outer_radius = 1.0
	ring.mesh = torus
	var m := material(RING_QI)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = m
	ring.position.y = .45
	ring.scale = Vector3(.25, .2, .25)
	add_child(ring)
	var t := ring.create_tween().set_parallel()
	t.tween_property(ring, "scale", Vector3(1.25, .2, 1.25), .8).set_ease(Tween.EASE_OUT)
	t.tween_property(m, "albedo_color:a", 0.0, .8)
	t.tween_callback(ring.queue_free).set_delay(.85)

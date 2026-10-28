extends Node3D
## Presentation director for this experiment only. Shared imported materials are never mutated:
## every changed material is duplicated and assigned as an instance override.
const WARM := Color("ffc986")
const CURRENT := Color("a8ddd3")
const GRASS_SHADER := """
shader_type spatial;
render_mode cull_back;
varying vec3 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float patches = sin(world.x * 0.055 + sin(world.z * 0.043)) * sin(world.z * 0.065);
	vec3 tint = mix(vec3(0.72, 0.84, 0.74), vec3(0.93, 0.91, 0.79), 0.5 + 0.5 * patches);
	// Match the inherited terrain's sRGB vertex colours, then add only broad tonal variation.
	ALBEDO = COLOR.rgb * tint * 0.92;
	ROUGHNESS = 1.0;
}
"""
const WIND_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform vec4 tint : source_color = vec4(0.3, 0.45, 0.3, 1.0);
uniform float amplitude = 0.025;
uniform float speed = 1.0;
void vertex() {
	float h = max(VERTEX.y, 0.0);
	float phase = MODEL_MATRIX[3].x * 0.71 + MODEL_MATRIX[3].z * 0.43;
	VERTEX.x += sin(TIME * speed + phase + h * 0.7) * amplitude * h;
	VERTEX.z += cos(TIME * speed * 0.7 + phase) * amplitude * h * 0.4;
}
void fragment() { ALBEDO = tint.rgb; ROUGHNESS = 0.92; }
"""
const FIREFLY_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, shadows_disabled;
void fragment() {
	float d = length(UV * 2.0 - 1.0);
	ALBEDO = vec3(0.8, 0.94, 0.67);
	ALPHA = smoothstep(1.0, 0.0, d) * 0.55;
}
"""

var world: Node3D
var quest: CanvasLayer
var lamps: Array[Dictionary] = []
var restored := false
var restoration_count := 0
var reward_tween: Tween
var current_motes: CPUParticles3D
var chime: AudioStreamPlayer3D
var leaf_rustle: AudioStreamPlayer3D
var wind_spots: Array[CPUParticles3D] = []
var time := 0.0
var listen_count := 0
var bench: Node3D
var rest_camera: Camera3D
var world_chip: PanelContainer
var world_caption: Label
var arrival_title: VBoxContainer
var arrival_timer := 0.0
var boot_pivots: Array[Node3D] = []

func setup(scene: Node3D) -> void:
	world = scene
	quest = world.quest
	name = "EveningDirector"
	configure_atmosphere()
	style_scene()

	light_lanterns()
	add_living_air()
	build_presentation_ui()
	bench = world.get_node("DemoDressing/Court/Court_bench_2")
	chime = AudioStreamPlayer3D.new()
	chime.name = "CourtChime"
	chime.stream = world.sound.chime([440.0, 659.25, 880.0], .24, 2.0)
	chime.bus = "Effects"
	chime.volume_db = -14
	chime.unit_size = 7
	chime.max_distance = 40
	add_child(chime)
	chime.global_position = Vector3(-7.5, 12.1, 42.5)
	leaf_rustle = AudioStreamPlayer3D.new()
	leaf_rustle.name = "BambooWind"
	leaf_rustle.stream = world.sound.wind.stream
	leaf_rustle.bus = "Ambience"
	leaf_rustle.volume_db = -20
	leaf_rustle.unit_size = 4
	leaf_rustle.max_distance = 19
	add_child(leaf_rustle)
	leaf_rustle.position = Vector3(-10.5, 12, 44)
	leaf_rustle.play()
	rest_camera = Camera3D.new()
	rest_camera.name = "ListeningCamera"
	rest_camera.fov = 58
	rest_camera.far = 600
	add_child(rest_camera)
	world.player.speed = 4.5
	world.player.camera.fov = 69
	world.sound.wind.volume_db = -20

func configure_atmosphere() -> void:
	for w: WorldEnvironment in world.find_children("*", "WorldEnvironment", true, false):
		# The inherited walkthrough constructs these per instance. Duplicate only file-backed ones.
		var env: Environment = w.environment
		if env:
			env = env.duplicate(true)
			w.environment = env
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color("8298c4")
		env.ambient_light_energy = .18
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.tonemap_exposure = 1.0
		env.fog_enabled = true
		env.fog_light_color = Color("15253f")
		env.fog_density = .0018
		env.fog_sky_affect = .65
		env.fog_height = 7.0
		env.fog_height_density = .008
		var sky: ProceduralSkyMaterial = env.sky.sky_material
		sky.sky_top_color = Color("030818")
		sky.sky_horizon_color = Color("142442")
		sky.ground_horizon_color = Color("111e34")
		sky.ground_bottom_color = Color("050b18")
		sky.sky_energy_multiplier = .35
	for sun: DirectionalLight3D in world.find_children("*", "DirectionalLight3D", true, false):
		sun.rotation_degrees = Vector3(-29, -43, 0)
		sun.light_color = Color("a9c5ff")
		sun.light_energy = .18
		sun.directional_shadow_max_distance = 130

func style_scene() -> void:
	var architecture_materials := {}
	for node: MeshInstance3D in world.get_node("Buildings").find_children("*", "MeshInstance3D", true, false):
		if not node.mesh: continue
		for surface in node.mesh.get_surface_count():
			var original := node.get_active_material(surface) as StandardMaterial3D
			if not original or original.emission_enabled or original.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED: continue
			if original.albedo_color.get_luminance() < .65: continue
			var key := original.get_instance_id()
			if not architecture_materials.has(key):
				var local: StandardMaterial3D = original.duplicate(true)
				local.albedo_color = original.albedo_color*Color(.82, .84, .86, 1)
				architecture_materials[key] = local
			node.set_surface_override_material(surface, architecture_materials[key])
	var ground := world.get_node_or_null("ContinuousValleyTerrain") as MeshInstance3D
	if ground:
		var sh := Shader.new()
		sh.code = GRASS_SHADER
		var mat := ShaderMaterial.new()
		mat.shader = sh
		ground.material_override = mat
	var wind := Shader.new()
	wind.code = WIND_SHADER
	var cache := {}
	# Only near dressing gets vertex sway. Collision and the distant instanced forest stay fixed.
	for node: MeshInstance3D in world.find_children("*", "MeshInstance3D", true, false):
		if not node.mesh: continue
		var path := str(node.get_path()).to_lower()
		if "demodressing" not in path and "retainedprovisionaldressing" not in path: continue
		for surface in node.mesh.get_surface_count():
			var original := node.get_active_material(surface) as StandardMaterial3D
			if not original: continue
			var mat_name := original.resource_name.to_lower()
			if not ("leaf" in mat_name or "foliage" in mat_name or "grass" in mat_name or "bamboo" in mat_name and "trunk" not in mat_name or "cloth" in mat_name): continue
			var key := original.get_instance_id()
			if not cache.has(key):
				var mat := ShaderMaterial.new()
				mat.shader = wind
				mat.set_shader_parameter("tint", original.albedo_color)
				mat.set_shader_parameter("amplitude", .012 if "cloth" in mat_name else .025)
				mat.set_shader_parameter("speed", .9 if "cloth" in mat_name else 1.15)
				cache[key] = mat
			node.set_surface_override_material(surface, cache[key])

func light_lanterns() -> void:
	var emitters := []
	for node: MeshInstance3D in world.find_children("*", "MeshInstance3D", true, false):
		if not node.mesh: continue
		for surface in node.mesh.get_surface_count():
			var mat := node.get_active_material(surface) as StandardMaterial3D
			if not mat or "lantern" not in mat.resource_name.to_lower(): continue
			var local: StandardMaterial3D = mat.duplicate(true)
			local.albedo_color = WARM
			local.emission_enabled = true
			local.emission = WARM
			local.emission_energy_multiplier = 1.8
			node.set_surface_override_material(surface, local)
			# Avoid duplicate near/distant building lamps and keep only lights along the route.
			var at := node.global_transform*node.get_aabb().get_center()
			if at.z < 22 or at.z > 140 or absf(at.x) > 25: continue
			var duplicate := false
			for other: Vector3 in emitters:
				if other.distance_to(at) < 1.8: duplicate = true
			if duplicate: continue
			emitters.append(at)
			var light := OmniLight3D.new()
			light.name = "LanternPool"
			light.light_color = WARM
			light.light_energy = 1.5
			light.omni_range = 5.5
			light.omni_attenuation = 1.7
			light.shadow_enabled = false
			add_child(light)
			light.global_position = at
			lamps.append({"light": light, "material": local, "base": 1.5, "court": at.z < 55 and at.z > 30, "phase": at.x*.43+at.z})

func air(at: Vector3, amount: int, extent: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "EveningMotes"
	p.position = at
	p.amount = amount
	p.lifetime = 7
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = extent
	p.direction = Vector3(.3, .6, .1)
	p.initial_velocity_min = .06
	p.initial_velocity_max = .14
	p.spread = 40
	p.gravity = Vector3.ZERO
	p.randomness = .8
	p.local_coords = true
	p.preprocess = 7
	p.seed = 1729+amount
	p.use_fixed_seed = true
	p.scale_amount_min = .035
	p.scale_amount_max = .06
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0))
	curve.add_point(Vector2(.25, 1))
	curve.add_point(Vector2(.7, .8))
	curve.add_point(Vector2(1, 0))
	p.scale_amount_curve = curve
	var quad := SphereMesh.new()
	quad.radius = .5
	quad.height = 1
	quad.radial_segments = 6
	quad.rings = 3
	var shader := Shader.new()
	shader.code = FIREFLY_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = shader
	quad.material = mat
	p.mesh = quad
	add_child(p)
	return p

func add_living_air() -> void:
	# Tiny local fireflies, not a screen-filling particle field.
	wind_spots.append(air(Vector3(8, .7, 126), 13, Vector3(3, .7, 3)))
	wind_spots.append(air(Vector3(-9, 11, 44), 12, Vector3(2, .8, 3)))
	current_motes = air(Vector3(10, 11, 41), 20, Vector3(3, .7, 3))
	current_motes.emitting = false
	current_motes.visible = false

func build_presentation_ui() -> void:
	var screen: Control = quest.get_node("Screen")
	arrival_title = VBoxContainer.new()
	arrival_title.name = "ArrivalTitle"
	arrival_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrival_title.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	arrival_title.offset_left = 32
	arrival_title.offset_top = -150
	arrival_title.offset_right = 510
	arrival_title.offset_bottom = -50
	screen.add_child(arrival_title)
	var name_label: Label = quest.label(arrival_title, "THE FIRST CURRENT", 28)
	name_label.add_theme_font_size_override("font_size", 28)
	quest.label(arrival_title, "Split-Cloud Sect · The living court", 18, Color("c6ced5"))
	world_chip = PanelContainer.new()
	world_chip.name = "WorldFeedback"
	world_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(world_chip)
	world_caption = quest.label(world_chip, "", 17)
	world_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	world_caption.add_theme_font_size_override("font_size", 17)
	world_chip.visible = false

func nearby_discovery() -> bool:
	if not bench or world.overview or quest.ui_open or quest.nearest() != "": return false
	var delta: Vector3 = world.player.global_position-bench.global_position
	return Vector2(delta.x, delta.z).length() < 2.8 and absf(delta.y) < 2

func listen() -> void:
	if not nearby_discovery(): return
	listen_count += 1
	var line := "Wind moves through the bamboo. Beyond it, the dry basin waits. This court was made for small, patient beginnings."
	if world.basin.active: line = "Water answers the bamboo now. A few lines, written in the right order, have changed the sound of this court."
	quest.say("THE LISTENING BENCH", line, [["Sound the chime", sound_chime, "ListenChime"], ["Return to the path", quest.close_ui, "ListenClose"]])
	rest_camera.global_position = Vector3(-4.5, 12.4, 48)
	rest_camera.look_at(Vector3(6, 11.0, 40))
	rest_camera.make_current()
	world.player.avatar.visible = false # A quiet view from the bench; close_ui restores the avatar.

func sound_chime() -> void:
	chime.play()
	quest.dialogue_text.text = "One clear note. Then room for the wind." if not restored else "A clear note hangs above the running water. The court is awake."
	quest.responsive_layout.call_deferred()

func restore_current(on: bool) -> void:
	if on == restored: return
	restored = on
	if reward_tween: reward_tween.kill()
	if on:
		restoration_count += 1
		current_motes.visible = true
		current_motes.emitting = true
		chime.play()
		reward_tween = create_tween().set_parallel()
		for lamp in lamps:
			if not lamp.court: continue
			reward_tween.tween_property(lamp.light, "light_color", CURRENT, 2.2)
			reward_tween.tween_property(lamp.material, "emission", CURRENT, 2.2)
	else:
		current_motes.emitting = false
		current_motes.visible = false
		for lamp in lamps:
			lamp.light.light_color = WARM
			lamp.material.emission = WARM

func reset_presentation() -> void:
	if reward_tween: reward_tween.kill()
	restore_current(false)
	restoration_count = 0
	listen_count = 0
	chime.stop()
	arrival_timer = 0
	world_chip.visible = false
	for transient in get_tree().get_nodes_in_group("creative_transient"): transient.queue_free()
	for lamp in lamps:
		lamp.light.light_energy = lamp.base
		lamp.light.light_color = WARM
		lamp.material.emission = WARM
	current_motes.emitting = false
	current_motes.visible = false

func tick(delta: float) -> void:
	time += delta
	arrival_timer += delta
	arrival_title.visible = false
	arrival_title.modulate.a = clampf((6-arrival_timer)/1.5, 0, 1)
	restore_current(world.basin.active)
	for lamp in lamps:
		lamp.light.light_energy = lamp.base*(1.0+.035*sin(time*2.3+lamp.phase))
	for i in boot_pivots.size(): boot_pivots[i].rotation.x = sin(world.stride_phase+PI*i)*.35*world.move_weight
	if not quest.ui_open and not world.player.automated:
		# Ease into a stride and into a sprint (Shift) instead of jumping straight to full speed.
		var p: CharacterBody3D = world.player
		var target := 6.2 if Input.is_physical_key_pressed(KEY_SHIFT) else 4.5
		p.speed = move_toward(p.speed, target, delta*8) if Vector2(p.velocity.x, p.velocity.z).length() > .1 else 2.6
	if nearby_discovery():
		quest.prompt.visible = true
		quest.prompt.text = "[E]  Pause at the listening bench"
	# A conversational camera is separate from the player camera, just like the code view.
	if quest.mode == "dialogue" and not rest_camera.current and (quest.speaker.text.begins_with("GUIDE") or quest.speaker.text.begins_with("MENTOR")):
		frame_conversation(world.guide if quest.speaker.text.begins_with("GUIDE") else world.mentor)
	update_world_feedback()

func frame_conversation(npc: Node3D) -> void:
	var p: Vector3 = world.player.global_position
	var focus: Vector3 = p.lerp(npc.global_position, .5)+Vector3(0, 1.15, 0)
	var direction: Vector3 = Vector3(npc.global_position.x-p.x, 0, npc.global_position.z-p.z).normalized()
	var eye := focus-direction.rotated(Vector3.UP, -.65)*5.5+Vector3(0, 1.0, 0)
	var query := PhysicsRayQueryParameters3D.create(focus, eye, 1, [world.player.get_rid()])
	var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
	if hit: eye = hit.position+(focus-eye).normalized()*.3
	rest_camera.global_position = eye
	rest_camera.look_at(focus)
	rest_camera.make_current()
	world.player.avatar.visible = true

func update_world_feedback() -> void:
	world_chip.visible = quest.mode == "code" and not quest.code.minimized
	if not world_chip.visible: return
	var screen: Vector2 = quest.get_node("Screen").size
	var rect: Rect2 = quest.code.get_rect()
	var free_right := screen.x-rect.end.x
	var free_left := rect.position.x
	var width := maxf(free_right, free_left)-32
	if width < 230:
		world_chip.visible = false
		return
	width = minf(width, 340)
	world_chip.size = Vector2(width, 52)
	world_chip.position = Vector2(rect.end.x+(free_right-width)/2 if free_right >= free_left else (free_left-width)/2, screen.y-88)
	if quest.stage in [3, 4]:
		world_caption.text = ("Ready / Release the crossing" if quest.stage == 3 else "Ready / Restore the ward") if quest.stage_solved else ("Check the seal before releasing it" if quest.stage == 3 else "Repeat one pulse for each of 3 stones")
		return
	if quest.stage_solved:
		world_caption.text = "Ready · Awaken to feel the current" if quest.stage == 1 else "Ready · Channel to restore the basin"
	else:
		world_caption.text = "Qi dormant · Basin dry" if quest.stage == 1 else "Qi %d / 3 · Basin waiting" % quest.reserve

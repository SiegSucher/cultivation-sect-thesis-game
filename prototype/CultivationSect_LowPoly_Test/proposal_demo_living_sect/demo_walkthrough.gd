extends "res://phase4d/walkthrough.gd"
## Living Sect: inherited Phase 4D geography and controller, Sect Life's complete quest,
## original articulated figures, a rebuilt entrance and populated activity courts.
## All modifications belong to this edition; shared scene/model files remain untouched.
const GUIDE_AT := Vector3(3.5, -.057, 129.0)
const MENTOR_AT := Vector3(5.8, 10.0, 43.2)
const BASIN_AT := Vector3(9.6, 9.98, 40.2)
const QI := Color("7fe6ff")
const COLUMN_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 tint : source_color = vec4(0.5, 0.9, 1.0, 1.0);
uniform float strength = 1.0;
void fragment() {
	float band = 0.5 + 0.5 * sin(UV.x * TAU * 3.0 + UV.y * 9.0 + TIME * 4.0);
	float rise = 0.5 + 0.5 * sin(UV.y * 16.0 + TIME * 6.0);
	float ends = pow(sin(UV.y * PI), 1.5);
	ALBEDO = tint.rgb;
	ALPHA = clamp(strength * ends * (0.2 + 0.8 * band * band) * (0.55 + 0.45 * rise), 0.0, 1.0);
}
"""
const SIGIL_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec4 tint : source_color = vec4(0.5, 0.9, 1.0, 1.0);
uniform float strength = 1.0;
uniform float spin = 0.4;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float outer = smoothstep(0.035, 0.0, abs(r - 0.9));
	float inner = smoothstep(0.022, 0.0, abs(r - 0.72));
	float ticks = step(0.75, fract((a + TIME * spin) / TAU * 18.0)) * step(0.75, r) * step(r, 0.87);
	float spokes = smoothstep(0.05, 0.0, abs(sin((a - TIME * spin * 0.6) * 3.0)) * r) * step(0.28, r) * step(r, 0.7);
	float core = smoothstep(0.03, 0.0, abs(r - 0.26));
	ALBEDO = tint.rgb;
	ALPHA = clamp((outer + inner * 0.8 + ticks * 0.7 + spokes * 0.45 + core * 0.6) * strength * (1.0 - smoothstep(0.93, 1.0, r)), 0.0, 1.0);
}
"""
var quest: CanvasLayer
var sound: Node
var guide: Node3D
var mentor: Node3D
var basin: Node3D
var aura: Node3D
var robe_sleeves: Array[Node3D] = []
var avatar_yaw := 0.0
var stride_phase := 0.0
var move_weight := 0.0
var step_count := 0
var phys_prev := Vector3.ZERO           # player position before the latest physics step
var cam_rel := Vector3.ZERO             # camera offset the controller set on the latest step
var cam_tick := -1
var fov_kick := 0.0
var anim_t := 0.0
var name_labels: Array[Label3D] = []
var help_panel: Control
var life: Node3D
var living: Node3D
var story: Node3D
var evening: Node3D
var player_figure: Node3D

func _ready() -> void:
	preload("res://proposal_demo_living_sect/runtime.gd").configure(get_tree())
	super._ready()
	sound = Node.new()
	sound.name = "DemoSound"
	sound.set_script(load("res://proposal_demo_living_sect/sound.gd"))
	add_child(sound)
	basin = Node3D.new()
	basin.name = "PlaceholderPublicBasin"
	basin.set_script(load("res://proposal_demo_living_sect/basin.gd"))
	basin.position = BASIN_AT
	add_child(basin)
	story = Node3D.new()
	story.set_script(preload("res://proposal_demo_living_sect/main_story.gd"))
	add_child(story)
	story.setup()
	mentor = character("PlaceholderMentor", "Mentor", MENTOR_AT)
	mentor.face(Vector3(0, 10, 50), true)            # toward the top of the living-terrace stair
	guide = character("PlaceholderGuide", "Guide", GUIDE_AT, Color("d9c9a6"), Color("3d5a80"), "lantern")
	guide.face(Vector3(8, 0, 134), true)             # toward the spawn
	quest = CanvasLayer.new()
	quest.name = "FirstCurrentQuest"
	quest.set_script(load("res://proposal_demo_living_sect/first_current_quest.gd"))
	quest.world = self
	quest.player = player
	quest.guide = guide
	quest.mentor = mentor
	quest.basin = basin
	quest.sound = sound
	add_child(quest)
	for label: Label in find_children("*", "Label", true, false):
		if label.text.begins_with("SPLIT-CLOUD VALLEY"):
			label.text = "The First Current · WASD move · Tab camera · E interact · Esc menu"
			label.get_parent().theme = quest.ui_theme          # same panel style as the quest UI
			label.add_theme_font_size_override("font_size", 15)
			help_panel = label.get_parent()
	location.visible = false
	for l: Label3D in find_children("*", "Label3D", true, false):
		if not l.get_parent().name.begins_with("Board"):
			name_labels.append(l)
			l.font_size = mini(l.font_size, 38)
			l.outline_size = 5
	if OS.has_feature("mobile") or "--touch" in OS.get_cmdline_user_args():
		var touch := CanvasLayer.new()
		touch.name = "TouchControls"
		touch.set_script(preload("res://proposal_demo_living_sect/touch_controls.gd"))
		touch.world = self
		add_child(touch)
	dress_apprentice()
	polish_palette()
	life = Node3D.new()
	life.set_script(load("res://proposal_demo_living_sect/sect_life.gd"))
	add_child(life)
	life.setup(self)
	get_tree().root.title = "The First Current - Living Sect"
	for i in 3: await get_tree().physics_frame
	living = Node3D.new()
	living.set_script(preload("res://proposal_demo_living_sect/living_sect.gd"))
	add_child(living)
	living.setup(self)
	evening = living.dusk

func character(node_name: String, title: String, at: Vector3, robe := Color("ece4cf"), over := Color("2f6b5f"), prop := "staff") -> Node3D:
	var n := Node3D.new()
	n.name = node_name
	n.set_script(load("res://proposal_demo_living_sect/npc_living.gd"))
	n.title = title
	n.robe = robe
	n.over = over
	n.prop = prop
	n.beard = prop == "staff"
	n.hat = "crown" if prop == "staff" else "straw"
	n.watch = player
	n.position = at
	add_child(n)
	return n

# ---------------------------------------------------------------- apprentice and palette
func dress_apprentice() -> void:
	# Replace only the local visual children; the tested controller/capsule stays intact.
	for child in player.avatar.get_children():
		player.avatar.remove_child(child)
		child.queue_free()
	player_figure = Node3D.new()
	player_figure.name = "ApprenticeFigure"
	player_figure.set_script(preload("res://proposal_demo_living_sect/character.gd"))
	player.avatar.add_child(player_figure)
	avatar_yaw = player.yaw

func polish_palette() -> void:
	"""Light aerial haze so distant ridges recede behind the sect; nothing near the route changes."""
	for w: WorldEnvironment in find_children("*", "WorldEnvironment", true, false):
		var env := w.environment
		env.fog_enabled = true
		env.fog_light_color = Color("c4d0ca")
		env.fog_density = .0010
		env.ambient_light_energy = .44
		env.ambient_light_color = Color("c6d0d6")
		env.fog_sky_affect = 0.0
	for sun: DirectionalLight3D in find_children("*", "DirectionalLight3D", true, false):
		sun.light_energy = .82
		sun.light_color = Color("fff1db")

func _process(delta: float) -> void:
	super._process(delta)
	anim_t += delta
	for l: Label3D in name_labels: l.visible = quest.mode != "code"
	if help_panel: help_panel.visible = not quest.ui_open
	var v := Vector2(player.velocity.x, player.velocity.z)
	var moving := player.is_physics_processing() and v.length() > .25
	if quest.ui_open: avatar_yaw = player.yaw
	elif moving: avatar_yaw = atan2(-v.x,-v.y)
	# The apprentice sits in the lotus position to awaken their Qi: while writing the awakening
	# inscription and while it takes effect. They stand again when the Mentor speaks.
	var awakening: bool = quest.ui_open and ((quest.stage == 1 and quest.mode == "code") or (quest.stage == 2 and quest.mode == "flow"))
	player_figure.activity = "lotus" if awakening else "idle"
	# One footstep per foot contact, so sound, legs and head bob share a rhythm.
	var steps := floori(player_figure.phase/PI)
	if steps != step_count:
		if moving and player.is_on_floor(): sound.play("step")
		step_count = steps
	player.avatar.rotation.y = lerp_angle(player.avatar.rotation.y,avatar_yaw,1-exp(-9*delta))
	player.avatar.rotation.x = 0
	# Draw the player between physics steps so movement and camera stay smooth at any refresh rate.
	var at := player.global_position
	if phys_prev.distance_to(at) < 1: at = phys_prev.lerp(at,Engine.get_physics_interpolation_fraction())
	player.avatar.position = at-player.global_position
	if player.camera.current: feel_camera(at)

func _physics_process(_delta: float) -> void:
	phys_prev = player.global_position   # this parent runs before the player moves

func feel_camera(at: Vector3) -> void:
	"""Walking and sprinting you can feel: the view dips on each footfall, sways toward the planted
	foot, rolls slightly and widens when sprinting. The controller's own camera stays untouched."""
	if player.is_physics_processing() and Engine.get_physics_frames() != cam_tick:
		cam_tick = Engine.get_physics_frames()
		cam_rel = player.camera.global_position-player.global_position
	var cam: Camera3D = player.camera
	var kick := 7.0*smoothstep(4.8,6.2,player_figure.speed)
	cam.fov += kick-fov_kick
	fov_kick = kick
	if player.third_person:
		if player.is_physics_processing(): cam.global_position = at+cam_rel
		return
	player.update_camera()                 # first person: the controller's eye with this frame's mouse look
	var w: float = player_figure.moving_speed
	var run: float = player_figure.run
	var phase: float = player_figure.phase
	var turn := Basis(Vector3.UP,player.yaw)
	var bob := Vector3(-sin(phase)*lerpf(.018,.032,run),-cos(phase*2)*lerpf(.028,.06,run),0)*w
	cam.global_basis = cam.global_basis*Basis(Vector3.BACK,sin(phase)*lerpf(.004,.012,run)*w)
	# First person drops to seated eye height in the lotus position.
	var seated: float = smoothstep(0,1,player_figure.shown_weight) if player_figure.shown == "lotus" else 0.0
	cam.global_position += at-player.global_position+turn*bob+Vector3.DOWN*.75*seated

# ---------------------------------------------------------------- Qi and basin effects
func glow_material(color: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m

func shader_material(code: String, strength: float, color := QI) -> ShaderMaterial:
	var s := Shader.new()
	s.code = code
	var m := ShaderMaterial.new()
	m.shader = s
	m.set_shader_parameter("tint", color)
	m.set_shader_parameter("strength", strength)
	return m

func sigil(radius: float, strength: float, color := QI) -> MeshInstance3D:
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE*radius*2
	var m := MeshInstance3D.new()
	m.mesh = plane
	m.material_override = shader_material(SIGIL_SHADER, strength, color)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m

func motes(amount: int, life: float, speed: float, spread: float, one_shot := false, color := Color("9ff0ff")) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.one_shot = one_shot
	p.explosiveness = 1.0 if one_shot else 0.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = .45
	p.direction = Vector3.UP
	p.spread = spread
	p.initial_velocity_min = speed*.5
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, .6, 0)
	p.scale_amount_curve = Curve.new()
	p.scale_amount_curve.add_point(Vector2(0, 1))
	p.scale_amount_curve.add_point(Vector2(1, 0))
	var dot := SphereMesh.new()
	dot.radius = .035
	dot.height = .07
	dot.radial_segments = 6
	dot.rings = 3
	dot.material = glow_material(color, 2.0)
	p.mesh = dot
	return p

func puff(at: Node3D, offset: Vector3, color: Color, amount: int, speed: float) -> void:
	"""A short one-shot burst of motes that removes itself."""
	var p := motes(amount, 1.0, speed, 60, true, color)
	p.position = offset
	at.add_child(p)
	p.emitting = true
	get_tree().create_timer(1.6).timeout.connect(p.queue_free)

func awaken_effect() -> void:
	"""The apprentice's Qi awakens: a spiralling column and a burst, then a lasting sigil under the
	feet, rising motes and a soft light."""
	clear_aura()
	aura = Node3D.new()
	aura.name = "QiAura"
	player.add_child(aura)
	var circle := sigil(.95, 0.0)
	circle.position.y = .04
	aura.add_child(circle)
	var rising := motes(20, 1.8, .6, 15)
	rising.position.y = .3
	aura.add_child(rising)
	var burst := motes(60, 1.2, 3.0, 180, true)
	burst.position.y = 1.0
	burst.gravity = Vector3.ZERO
	aura.add_child(burst)
	burst.emitting = true
	var tube := CylinderMesh.new()
	tube.top_radius = .55
	tube.bottom_radius = .7
	tube.height = 2.8
	tube.cap_top = false
	tube.cap_bottom = false
	var column := MeshInstance3D.new()
	column.mesh = tube
	column.position.y = 1.4
	column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	column.material_override = shader_material(COLUMN_SHADER, 0.0)
	aura.add_child(column)
	var light := OmniLight3D.new()
	light.light_color = QI
	light.omni_range = 3.5
	light.position.y = 1.0
	aura.add_child(light)
	var peak := 1.4 if player.third_person else .45         # gentler when the camera is inside it
	var t := aura.create_tween().set_parallel()
	t.tween_property(column.material_override, "shader_parameter/strength", peak, .45)
	t.tween_property(column.material_override, "shader_parameter/strength", 0.0, 1.4).set_delay(.9)
	t.tween_callback(column.queue_free).set_delay(2.4)
	t.tween_property(circle.material_override, "shader_parameter/strength", 1.5, .5)
	t.tween_property(circle.material_override, "shader_parameter/strength", .55, 1.2).set_delay(.6)
	light.light_energy = 4.0
	t.tween_property(light, "light_energy", .7, 1.6)

func clear_aura() -> void:
	if aura:
		aura.queue_free()
		aura = null

func qi_flicker() -> void:
	"""A run failed: the apprentice's Qi wavers amber for a moment (the world is otherwise unchanged)."""
	puff(player, Vector3(0, 1.0, 0), Color("ffb347"), 10, .8)

func qi_stir(stage: int) -> void:
	"""A run succeeded: a first stir of Qi is visible beside the terminal before Continue plays it out."""
	if stage == 1: puff(player, Vector3(0, .3, 0), Color("9ff0ff"), 24, 1.4)
	else: basin.stir()

func channel_effect(target: Vector3) -> void:
	"""A Qi orb arcs from the apprentice into the basin, leaving a trail, and ripples the bowl."""
	var orb := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = .2
	ball.height = .4
	orb.mesh = ball
	orb.material_override = glow_material(Color("9ff0ff"), 3.0)
	add_child(orb)
	var start := player.global_position+Vector3(0, 1.2, 0)
	var lift := start.lerp(target, .5)+Vector3(0, 1.6, 0)
	orb.global_position = start
	var trail := motes(40, .5, .3, 180)
	trail.local_coords = false
	trail.emission_sphere_radius = .12
	orb.add_child(trail)
	var t := orb.create_tween()
	t.tween_method(func(k: float) -> void: orb.global_position = start.lerp(lift, k).lerp(lift.lerp(target, k), k), 0.0, 1.0, .9).set_trans(Tween.TRANS_SINE)
	t.tween_callback(func() -> void: basin.ripple())
	t.tween_callback(orb.queue_free)

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo): return
	if event.physical_keycode == KEY_J and life and (not quest.ui_open or quest.mode == "life"):
		if quest.ui_open: quest.close_ui()
		else: life.open_journal()
		get_viewport().set_input_as_handled()
		return
	# Esc belongs to the demo (close panel / open menu), not the gallery exit in the player script.
	if event.physical_keycode == KEY_ESCAPE:
		quest.escape()
		get_viewport().set_input_as_handled()
	elif quest.handle_key(event):
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if quest.ui_open: return       # no review jumps, map, resets or doors behind a panel
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E and not overview and quest.nearest() != "":
		quest.interact()           # Guide, Mentor or basin takes the key; door toggles never see it
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E and living and living.nearest_extra() != "":
		living.interact()
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)

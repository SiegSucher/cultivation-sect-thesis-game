extends "res://phase4d/walkthrough.gd"
## Thesis proposal demo: the Phase 4D sect (unchanged, inherited) plus one playable quest,
## "The First Current". The Guide stands beside the forest path near the spawn; the Mentor and
## the basin are on the living court. All three are phase-local placeholders built here.
const GUIDE_AT := Vector3(3.5, -.057, 129.0)
const MENTOR_AT := Vector3(5.8, 10.0, 43.2)
const BASIN_AT := Vector3(9.6, 9.98, 40.2)
var quest: CanvasLayer
var guide: Node3D
var mentor: Node3D
var basin: Node3D
var aura: Node3D

func _ready() -> void:
	super._ready()
	basin = Node3D.new()
	basin.name = "PlaceholderPublicBasin"
	basin.set_script(load("res://proposal_demo/basin.gd"))
	basin.position = BASIN_AT
	add_child(basin)
	mentor = character("PlaceholderMentor", "Mentor", MENTOR_AT)
	mentor.face(Vector3(0, 10, 50))                  # toward the top of the living-terrace stair
	guide = character("PlaceholderGuide", "Guide", GUIDE_AT, Color("d9c9a6"), Color("3d5a80"), "lantern")
	guide.face(Vector3(8, 0, 134))                   # toward the spawn
	quest = CanvasLayer.new()
	quest.name = "FirstCurrentQuest"
	quest.set_script(load("res://proposal_demo/first_current_quest.gd"))
	quest.world = self
	quest.player = player
	quest.guide = guide
	quest.mentor = mentor
	quest.basin = basin
	add_child(quest)
	for label: Label in find_children("*", "Label", true, false):
		if label.text.begins_with("SPLIT-CLOUD VALLEY"):
			label.text = "SPLIT-CLOUD SECT  ·  THESIS PROPOSAL DEMO  ·  The First Current\nWASD move · Mouse look · Tab first/third person · E talk / use · Esc menu (Reset Demo)"
	location.visible = false

func character(node_name: String, title: String, at: Vector3, robe := Color("ece4cf"), over := Color("2f6b5f"), prop := "staff") -> Node3D:
	var n := Node3D.new()
	n.name = node_name
	n.set_script(load("res://proposal_demo/npc.gd"))
	n.title = title
	n.robe = robe
	n.over = over
	n.prop = prop
	n.beard = prop == "staff"
	n.position = at
	add_child(n)
	return n

func glow_material(color: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m

func motes(amount: int, life: float, speed: float, spread: float, one_shot := false) -> CPUParticles3D:
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
	var dot := SphereMesh.new()
	dot.radius = .035
	dot.height = .07
	dot.radial_segments = 6
	dot.rings = 3
	dot.material = glow_material(Color("9ff0ff"), 2.0)
	p.mesh = dot
	return p

func awaken_effect() -> void:
	"""The apprentice's Qi awakens: a burst, then a lasting ring and rising motes around the player."""
	clear_aura()
	aura = Node3D.new()
	aura.name = "QiAura"
	player.add_child(aura)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = .5
	torus.outer_radius = .58
	ring.mesh = torus
	ring.material_override = glow_material(Color("7fe6ff"), 2.5)
	ring.position.y = .06
	aura.add_child(ring)
	var rising := motes(28, 1.8, .6, 15)
	rising.position.y = .3
	aura.add_child(rising)
	var burst := motes(70, 1.2, 3.0, 180, true)
	burst.position.y = 1.0
	burst.gravity = Vector3.ZERO
	aura.add_child(burst)
	burst.emitting = true
	var light := OmniLight3D.new()
	light.light_color = Color("7fe6ff")
	light.omni_range = 3.5
	light.position.y = 1.0
	aura.add_child(light)
	ring.scale = Vector3.ONE*.2
	var t := aura.create_tween().set_parallel()
	t.tween_property(ring, "scale", Vector3.ONE*1.7, .6).set_trans(Tween.TRANS_BACK)
	t.tween_property(ring, "scale", Vector3.ONE, .8).set_delay(.6)
	light.light_energy = 4.0
	t.tween_property(light, "light_energy", .8, 1.6)

func clear_aura() -> void:
	if aura:
		aura.queue_free()
		aura = null

func channel_effect(target: Vector3) -> void:
	"""A Qi orb travels from the apprentice into the basin."""
	var orb := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = .2
	ball.height = .4
	orb.mesh = ball
	orb.material_override = glow_material(Color("9ff0ff"), 3.0)
	add_child(orb)
	orb.global_position = player.global_position+Vector3(0, 1.2, 0)
	var trail := motes(40, .5, .3, 180)
	trail.local_coords = false
	trail.emission_sphere_radius = .12
	orb.add_child(trail)
	var t := orb.create_tween()
	t.tween_property(orb, "global_position", target, .9).set_trans(Tween.TRANS_SINE)
	t.tween_callback(orb.queue_free)

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo): return
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
	super._unhandled_input(event)

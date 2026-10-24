extends SceneTree
## Real programmatic input through the gallery and canonical walkthrough.
const OUT := "res://reports/codex-exchange-hall/"
var checks: Array = []
func _initialize() -> void: call_deferred("run")
func frames(n := 8) -> void:
	for i in n: await process_frame
func event(key: int, down: bool) -> void:
	var e := InputEventKey.new(); e.physical_keycode = key; e.pressed = down; Input.parse_input_event(e)
func press(key: int) -> void:
	event(key, true); await frames(); event(key, false); await frames()
func check(label: String, ok: bool) -> void:
	checks.append({"check": label, "pass": ok}); print("PASS " if ok else "FAIL ", label)
func shot(name: String) -> void:
	await frames(15); RenderingServer.force_draw(false)
	check("capture " + name, root.get_texture().get_image().save_png(OUT+name+".png") == OK)
func run() -> void:
	root.size = Vector2i(1280,720)
	change_scene_to_file("res://scenes/asset_gallery.tscn"); await frames(25)
	check("ten distinct explicit entries", current_scene.catalog.size() == 10)
	for i in 10:
		current_scene.select_asset(i); await frames(6)
		check("gallery loads entry " + str(current_scene.catalog[i].id), is_instance_valid(current_scene.model) and not current_scene.walkthrough_button.disabled)
	check("Exchange last, canonical resource", current_scene.catalog[9].id == "exchange_hall" and current_scene.catalog[9].resource == "res://scenes/buildings/exchange_hall.tscn")
	check("source file exists", FileAccess.file_exists(current_scene.workspace_path(current_scene.catalog[9].source)))
	check("static leaves have no door toggle", current_scene.doors_button.disabled)
	await shot("gallery-exchange-exterior")
	current_scene.preset("Interior"); await frames()
	var q := PhysicsShapeQueryParameters3D.new(); var sphere := SphereShape3D.new(); sphere.radius = .17
	q.shape = sphere; q.transform.origin = current_scene.camera.global_position; q.collision_mask = 1
	check("interior preset camera clears collision", current_scene.model.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty())
	await shot("gallery-exchange-interior")
	current_scene.open_walkthrough(); await frames(20)
	var s: Node3D = current_scene
	check("canonical Walk route", s.get_script().resource_path == "res://scripts/exchange_hall_review.gd" and s.has_node("ExchangeHall"))
	check("unchanged inspection player script", s.player.get_script().resource_path == "res://scripts/training_inspection_player.gd")
	await press(KEY_1)
	check("1 starts walking", s.player.is_physics_processing() and s.player.camera.current)
	var before: Vector3 = s.player.position
	event(KEY_W, true)
	for i in 18: await physics_frame
	event(KEY_W, false); await frames()
	check("W moves", s.player.position.z < before.z-.5)
	await press(KEY_TAB)
	check("Tab third person", s.player.third_person and s.player.avatar.visible)
	await shot("input-third-person-approach")
	await press(KEY_TAB)
	check("Tab first person", not s.player.third_person and not s.player.avatar.visible)
	var yaw: float = s.player.yaw
	var motion := InputEventMouseMotion.new(); motion.relative = Vector2(20,10); Input.parse_input_event(motion); await frames()
	check("mouse look", absf(s.player.yaw-yaw) > .01)
	await press(KEY_1)
	check("1 returns to review", not s.player.is_physics_processing() and s.review_camera.current)
	await press(KEY_ESCAPE)
	check("Esc returns to gallery", current_scene is Control and current_scene.catalog.size() == 10)
	var failed := checks.filter(func(c): return not c.pass).size()
	FileAccess.open(OUT+"gallery-input.json", FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "passed": checks.size()-failed, "failed": failed, "limit": "Programmatic inputs; not human playtesting or OS source-button launch"}, "  "))
	print(checks.size()-failed, " PASS / ", failed, " FAIL")
	quit(1 if failed else 0)

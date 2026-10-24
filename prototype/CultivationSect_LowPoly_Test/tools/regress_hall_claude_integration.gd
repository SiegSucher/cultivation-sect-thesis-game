extends SceneTree
var checks: Array = []
func _initialize() -> void: call_deferred("run")
func frames(n:=8) -> void:
	for i in range(n): await process_frame
func check(label: String, ok: bool) -> void:
	checks.append({"check":label,"pass":ok})
func press(key: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await frames()
	event = InputEventKey.new()
	event.physical_keycode = key
	event.pressed = false
	Input.parse_input_event(event)
	await frames()
func run() -> void:
	change_scene_to_file("res://scenes/hall_experiment.tscn")
	await frames(24)
	var s := current_scene
	check("Default scene opens in review view",s.view_camera.current and not s.player.is_physics_processing())
	await press(KEY_1)
	check("1 starts walking with first-person camera",s.player.camera.current and s.player.is_physics_processing() and not s.player.third_person)
	await press(KEY_TAB)
	check("Tab changes to third person",s.player.third_person)
	await press(KEY_E)
	check("E requests door opening",s.hall.main_door.target_open)
	await press(KEY_3)
	check("3 returns to exterior review and pauses player",s.view_camera.current and not s.player.is_physics_processing())
	await press(KEY_ESCAPE)
	check("Esc opens copied gallery",current_scene is Control)
	current_scene.select_asset(0)
	current_scene.open_walkthrough()
	await frames(24)
	check("Gallery Hall Walk returns to experiment",current_scene.get_script().resource_path=="res://scripts/hall_experiment.gd")
	var failed := checks.filter(func(c):return not c.pass).size()
	var f := FileAccess.open("res://reports/codex-claude-integration/hall-controls.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"limits":"Programmatically dispatched input events; human rehearsal remains unperformed."},"\t"))
	f.close()
	print("Controls: "+str(checks.size()-failed)+" PASS / "+str(failed)+" FAIL")
	quit(1 if failed else 0)

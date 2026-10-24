extends SceneTree
var checks: Array = []
func _initialize() -> void: call_deferred("run")
func frames(n:=10) -> void:
	for i in range(n): await process_frame
func press(key: int) -> void:
	var e := InputEventKey.new()
	e.physical_keycode=key
	e.pressed=true
	Input.parse_input_event(e)
	await frames()
	e=InputEventKey.new();e.physical_keycode=key;e.pressed=false
	Input.parse_input_event(e)
	await frames()
func check(label: String, ok: bool) -> void: checks.append({"check":label,"pass":ok})
func run() -> void:
	change_scene_to_file("res://scenes/review/gate_walkthrough.tscn")
	await frames(24)
	var s := current_scene
	check("Review scene opens",s.review_camera.current and not s.player.is_physics_processing())
	await press(KEY_1)
	check("Walk with unchanged fixture",s.player.camera.current and s.player.is_physics_processing())
	await press(KEY_TAB)
	check("Tab third-person",s.player.third_person)
	await press(KEY_E)
	check("E uses existing gate interaction",s.facility.preview_open)
	await press(KEY_3)
	check("Review pauses fixture",s.review_camera.current and not s.player.is_physics_processing())
	await press(KEY_ESCAPE)
	check("Esc existing gallery",current_scene is Control)
	current_scene.select_asset(1)
	current_scene.open_walkthrough()
	await frames(24)
	check("Gate Walk button",current_scene.get_script().resource_path=="res://scripts/gate_walkthrough.gd")
	var fail := checks.filter(func(c):return not c.pass).size()
	var file:=FileAccess.open("res://reports/environment-conversion-stages-2-3/gate-controls-results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-fail,"failed":fail,"limits":"Programmatic events, not human keyboard rehearsal."},"\t"))
	file.close()
	print("Gate controls "+str(checks.size()-fail)+" PASS / "+str(fail)+" FAIL")
	quit(1 if fail else 0)

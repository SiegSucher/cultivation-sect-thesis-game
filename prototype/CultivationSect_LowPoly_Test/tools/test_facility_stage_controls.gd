extends SceneTree
## Programmatic real input events, not a human keyboard/mouse playtest.
var checks: Array=[]
func _initialize() -> void: call_deferred("run")
func frames(n:=10) -> void:
	for i in range(n): await process_frame
func press(key: int) -> void:
	var e:=InputEventKey.new(); e.physical_keycode=key; e.pressed=true
	Input.parse_input_event(e); await frames()
	e=InputEventKey.new(); e.physical_keycode=key; e.pressed=false
	Input.parse_input_event(e); await frames()
func check(label: String, ok: bool) -> void: checks.append({"check":label,"pass":ok})
func run() -> void:
	change_scene_to_file("res://scenes/asset_gallery.tscn")
	await frames(24)
	for i: int in [2,3]:
		var label: String="Training" if i==2 else "Pavilion"
		current_scene.select_asset(i)
		check(label+" native-source action available",not current_scene.source_button.disabled and FileAccess.file_exists(current_scene.catalog[i].source))
		current_scene.open_walkthrough(); await frames(24)
		var s: Node=current_scene
		check(label+" Walk route",s.get_script().resource_path==("res://scripts/training_walkthrough.gd" if i==2 else "res://scripts/scripture_walkthrough.gd"))
		check(label+" first-person at entry",s.player.camera.current and not s.player.third_person)
		await press(KEY_TAB)
		check(label+" Tab third-person",s.player.third_person and s.player.avatar.visible)
		await press(KEY_TAB)
		check(label+" Tab back to first-person",not s.player.third_person and not s.player.avatar.visible)
		var previous_yaw: float=s.player.yaw
		var mouse:=InputEventMouseMotion.new(); mouse.relative=Vector2(20,10)
		Input.parse_input_event(mouse); await frames()
		check(label+" mouse look",absf(s.player.yaw-previous_yaw)>.01)
		if i==3:
			await press(KEY_G)
			check("G toggles inspection permission",s.inspection_authorized)
			await press(KEY_E)
			check("E refuses remote archive request",not s.facility.archive_gate.is_open and "closer" in s.access_message)
			await press(KEY_G)
			check("G revokes inspection permission",not s.inspection_authorized)
		await press(KEY_ESCAPE)
		check(label+" Esc gallery",current_scene is Control)
	var failures:=checks.filter(func(c):return not c.pass).size()
	FileAccess.open("res://reports/environment-conversion-stages-2-3/controls-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failures,"failed":failures,"limits":"Programmatic input events, not human keyboard rehearsal. Detailed archive proximity/permission/movement tests are separate."},"\t"))
	print("Facility input: ",checks.size()-failures," PASS / ",failures," FAIL")
	quit(1 if failures else 0)

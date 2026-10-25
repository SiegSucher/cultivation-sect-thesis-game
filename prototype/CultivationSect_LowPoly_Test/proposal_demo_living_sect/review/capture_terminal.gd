extends SceneTree
## Rendered checks and captures of the inscription terminal and the presentation pass, driven by
## real mouse and key events: drag the title bar, resize from edges and corners (down to the
## minimum and against the screen edges), drag the internal pane bars, minimize/restore, Restore
## Layout, type and run with the world visible beside the window, close back to the same camera
## mode, the basin step, audio controls and Reset Demo. A drawn pointer marks the synthetic mouse,
## so a --write-movie run doubles as the recording.
## godot --path . --script res://proposal_demo_living_sect/review/capture_terminal.gd -- <out_dir> [tag]
const AT_MENTOR := Vector3(4.4, 10.05, 45.6)
const AT_BASIN := Vector3(10.4, 10.05, 42.7)
var demo: Node3D
var player: CharacterBody3D
var quest: CanvasLayer
var term: PanelContainer
var gate: Node3D
var out := ""
var tag := ""
var results := []
var failures := 0
var cursor := Vector2(900, 500)
var pointer: Polygon2D

func _initialize() -> void:
	run()

func check(name: String, ok: bool, detail = null) -> void:
	results.append({"check": name, "pass": ok, "detail": detail})
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+name+("" if detail == null else " | "+str(detail)))

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func shot(name: String) -> void:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out.path_join(name+tag+".png"))
	print("shot ", name)

func send(code: Key, unicode := 0, ctrl := false) -> void:
	for down in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.unicode = unicode
		e.ctrl_pressed = ctrl
		e.pressed = down
		Input.parse_input_event(e)
		await process_frame

func type_text(text: String, cps := 14.0) -> void:
	await send(KEY_A, 0, true)
	for ch in text:
		if ch == "\n": await send(KEY_ENTER)
		else: await send(KEY_NONE, ch.unicode_at(0))
		await wait(1.0/cps)

func press(id: String) -> void:
	var b: Button = quest.find_child(id, true, false)
	assert(b and b.is_visible_in_tree() and not b.disabled, "button not available: "+id)
	b.pressed.emit()
	for i in 2: await process_frame

func move_to(to: Vector2, seconds := .4, held := false) -> void:
	var from := cursor
	var steps := maxi(1, int(seconds*30))
	for i in steps:
		var p := from.lerp(to, float(i+1)/steps)
		var e := InputEventMouseMotion.new()
		e.position = to_window(p)
		e.global_position = e.position
		e.relative = p-cursor
		e.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
		Input.parse_input_event(e)
		cursor = p
		pointer.position = p
		await process_frame

func button(down: bool, double := false) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	e.double_click = double
	e.position = to_window(cursor)
	e.global_position = e.position
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	Input.parse_input_event(e)
	for i in 2: await process_frame

func to_window(p: Vector2) -> Vector2:
	"""Synthetic mouse events arrive in window pixels; the UI is laid out at 1280 x 720 and scaled."""
	return root.get_final_transform()*p

func drag(from: Vector2, to: Vector2, seconds := .6) -> void:
	await move_to(from, .25)
	await button(true)
	await move_to(to, seconds, true)
	await button(false)

func click(at: Vector2) -> void:
	await move_to(at, .25)
	await button(true)
	await button(false)

func centre(c: Control) -> Vector2:
	return c.get_global_rect().get_center()

func reachable(ids: Array) -> Dictionary:
	"""Each control is visible and lies wholly inside both the terminal and the screen."""
	var bad := {}
	var screen := Rect2(Vector2.ZERO, quest.get_node("Screen").size)
	for id: String in ids:
		var c: Control = quest.find_child(id, true, false)
		var r := c.get_global_rect()
		if not c.is_visible_in_tree() or not term.get_global_rect().grow(1).encloses(r) or not screen.grow(1).encloses(r) or r.size.x < 8: bad[id] = r
	return bad

func in_free_area(p: Vector3) -> bool:
	var s: Vector2 = quest.get_node("Screen").size
	var at: Vector2 = quest.code_cam.unproject_position(p)
	return not quest.code_cam.is_position_behind(p) and at.x > term.get_rect().end.x and at.x < s.x and at.y > 0 and at.y < s.y

func world_still(pos: Vector3, third: bool, gate_open: bool) -> bool:
	return player.global_position.distance_to(pos) < .01 and player.third_person == third and gate.preview_open == gate_open and quest.mode == "code"

func run() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0]
	tag = args[1] if args.size() > 1 else ""
	DirAccess.make_dir_recursive_absolute(out)
	demo = load("res://proposal_demo_living_sect/proposal_demo.tscn").instantiate()
	root.add_child(demo)
	current_scene = demo
	for i in 10: await physics_frame
	player = demo.player
	quest = demo.quest
	term = quest.code
	gate = demo.get_node("Buildings/sect_gate")
	var overlay := CanvasLayer.new()
	overlay.layer = 100
	root.add_child(overlay)
	pointer = Polygon2D.new()
	pointer.polygon = PackedVector2Array([Vector2(0, 0), Vector2(0, 22), Vector2(6, 16), Vector2(10, 25), Vector2(14, 23), Vector2(10, 15), Vector2(17, 15)])
	pointer.color = Color.WHITE
	var edge := Line2D.new()
	edge.points = pointer.polygon
	edge.closed = true
	edge.width = 1.5
	edge.default_color = Color.BLACK
	pointer.add_child(edge)
	overlay.add_child(pointer)
	print("window ", DisplayServer.window_get_size(), " screen control ", quest.get_node("Screen").size)
	await terminal_checks()
	await basin_and_audio()
	var f := FileAccess.open(out.path_join("terminal-results"+tag+".json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"failures": failures, "checks": results.size(), "window": str(DisplayServer.window_get_size()), "results": results}, "  "))
	f.close()
	print("TOTAL %d checks, %d failures" % [results.size(), failures])
	quit(1 if failures else 0)

func terminal_checks() -> void:
	demo.jump_to(AT_MENTOR, player.yaw)
	for i in 8: await physics_frame
	await send(KEY_E)
	await wait(1.2)
	await shot("30-mentor-dialogue")
	await press("Next")
	await wait(.8)
	await press("Accept")
	await wait(.6)
	await press("Choose_python")
	await wait(1.0)
	await shot("31-lesson-card")
	await press("TeachSkip")
	await wait(.6)
	var pos := player.global_position
	var gate_open: bool = gate.preview_open
	check("terminal opens at the default layout, left side, world visible on the right", term.get_rect() == term.default_rect and quest.code_cam.current, term.get_rect())
	await wait(.5)
	check("the coding view shows the apprentice and the Mentor in the free area beside the terminal", in_free_area(player.global_position+Vector3(0, 1.0, 0)) and in_free_area(demo.mentor.global_position+Vector3(0, 1.0, 0)),
		{"apprentice": quest.code_cam.unproject_position(player.global_position+Vector3(0, 1.0, 0)), "mentor": quest.code_cam.unproject_position(demo.mentor.global_position+Vector3(0, 1.0, 0))})
	await shot("32-terminal-default")
	await type_text("awaken(qi)\nqi = 3")
	await send(KEY_ENTER, 0, true)
	await wait(1.0)
	check("typing and Ctrl+Enter run in the terminal; the error shows with the world beside it", quest.console.get_parsed_text().contains("NameError"), quest.console.get_parsed_text().right(80))
	await shot("33-terminal-error-world-visible")
	# Drag the title bar; then try to drag it off screen.
	var bar: Control = term.title_bar
	var grab := bar.global_position+Vector2(160, bar.size.y/2)
	await drag(grab, grab+Vector2(300, 40), .8)
	check("dragging the title bar moves the window (and keeps it on screen)", term.position.is_equal_approx(Vector2(312, 24)), term.position)
	await shot("34-terminal-dragged")
	await drag(cursor, cursor+Vector2(900, 400), .6)
	var screen: Vector2 = quest.get_node("Screen").size
	check("the window cannot be dragged past the screen edge", term.get_rect().end.x <= screen.x+.5 and term.get_rect().end.y <= screen.y+.5 and term.position.x >= 0, term.get_rect())
	# Resize from the bottom-right corner, far past the minimum.
	await drag(term.get_global_rect().end-Vector2(4, 4), Vector2(120, 90), 1.0)
	var low: Vector2 = term.min_size()
	check("resizing from the corner stops at the minimum size", term.size.is_equal_approx(low) and low.x >= 560 and low.y >= 400, {"size": term.size, "min": low})
	var essentials := ["Run", "ResetCode", "CodeBack", "Minimize", "RestoreLayout", "Editor", "Console"]
	check("at the minimum size every essential control is visible and inside the window", reachable(essentials).is_empty(), reachable(essentials))
	check("at the minimum size the editor and output still have usable height", quest.editor.size.y >= 60 and quest.console.size.y >= 40, {"editor": quest.editor.size, "console": quest.console.size})
	await shot("35-terminal-minimum-size")
	# Resize from the left edge, out past the screen edge.
	var r: Rect2 = term.get_global_rect()
	await drag(Vector2(r.position.x+4, r.get_center().y), Vector2(-200, r.get_center().y), .8)
	check("resizing from the left edge stops at the screen edge; the right edge stays put", term.position.x >= -.5 and is_equal_approx(term.get_rect().end.x, r.end.x), term.get_rect())
	r = term.get_global_rect()
	await drag(Vector2(r.get_center().x, r.position.y+4), Vector2(r.get_center().x, -100), .6)
	check("resizing from the top edge stops at the screen edge", term.position.y >= -.5 and is_equal_approx(term.get_rect().end.y, r.end.y), term.get_rect())
	await click(centre(quest.find_child("RestoreLayout", true, false)))
	check("Restore layout puts the window back", term.get_rect() == term.default_rect, term.get_rect())
	# Internal panes: drag the bar between code and reference, then between program and output.
	var tabs_w: float = quest.tabs.size.x
	var split_x: float = quest.split_v.get_global_rect().end.x+6
	await drag(Vector2(split_x, quest.split_h.get_global_rect().get_center().y), Vector2(split_x-140, quest.split_h.get_global_rect().get_center().y), .7)
	check("dragging the code | reference bar widens the reference pane", quest.tabs.size.x > tabs_w+100, {"before": tabs_w, "after": quest.tabs.size.x})
	var console_h: float = quest.console.size.y
	var program: Control = quest.split_v.get_child(0)
	var split_y: float = program.get_global_rect().end.y+6
	await drag(Vector2(program.get_global_rect().get_center().x, split_y), Vector2(program.get_global_rect().get_center().x, split_y-70), .6)
	check("dragging the program | output bar enlarges the output pane", quest.console.size.y > console_h+50, {"before": console_h, "after": quest.console.size.y})
	await shot("36-panes-adjusted")
	# Font size, then minimize and restore (button and title double-click).
	await click(centre(quest.find_child("FontLarger", true, false)))
	check("A+ enlarges the code text", quest.code_font_size == 20)
	await click(centre(quest.find_child("Minimize", true, false)))
	await wait(.8)
	check("Minimize collapses the terminal to its title bar; the world view recentres", term.minimized and not term.body.visible and term.size.y < 70 and absf(quest.view_shift()) < .01, term.size)
	await shot("37-terminal-minimized")
	await click(centre(quest.find_child("Minimize", true, false)))
	check("Restore brings the body back with its size", not term.minimized and term.body.visible and term.size.y > 400, term.size)
	await move_to(term.title_bar.global_position+Vector2(200, 14), .3)
	await button(true, true)
	await button(false)
	check("double-clicking the title bar also minimizes", term.minimized)
	await button(true, true)
	await button(false)
	await click(centre(quest.find_child("RestoreLayout", true, false)))
	await wait(.2)
	check("Restore layout also resets the pane sizes", term.get_rect() == term.default_rect and absf(quest.tabs.size.x-300) < 2 and absf(quest.output_pane.size.y-200) < 2, {"tabs": quest.tabs.size.x, "output": quest.output_pane.size.y})
	check("no drag, resize or click moved the player, changed the camera mode or touched the Gate", world_still(pos, true, gate_open), {"moved": player.global_position.distance_to(pos)})
	# The editor still takes typing after all of that (click into it first).
	await click(centre(quest.editor))
	await type_text("qi = 3\nawaken(qi)")
	await click(centre(quest.run_button))
	await wait(1.2)
	check("after the window work, typing and Run still complete step 1; Qi stirs beside the window", quest.stage_solved and quest.console.get_parsed_text().contains("Reserve: 3"))
	await shot("38-awakening-success-terminal")
	await click(centre(quest.find_child("ResultContinue", true, false)))
	await wait(1.2)
	await shot("39-qi-awakening-effect")
	while quest.mode != "dialogue": await process_frame
	await press("ShowMe")
	await press("TeachNext")
	await press("TeachNext")
	check("closing the flow restores third person and the player's camera", quest.mode == "" and player.third_person and player.camera.is_current() and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)

func basin_and_audio() -> void:
	demo.jump_to(AT_BASIN, player.yaw)
	player.third_person = false
	for i in 8: await physics_frame
	await send(KEY_E)
	await wait(.6)
	await wait(.5)
	check("first person: the terminal opens with the coding view showing the basin beside it", quest.mode == "code" and quest.code_cam.current and not player.third_person and in_free_area(demo.basin.global_position+Vector3(0, .6, 0)),
		quest.code_cam.unproject_position(demo.basin.global_position+Vector3(0, .6, 0)))
	await type_text("reserve = qi_reserve()\nchannel_basin(5)")
	await send(KEY_ENTER, 0, true)
	await wait(.8)
	await shot("40-basin-error-basin-visible")
	await type_text("reserve = qi_reserve()\nchannel_basin(reserve)")
	await send(KEY_ENTER, 0, true)
	await wait(1.0)
	await shot("41-basin-success-ring-stirs")
	var sound: Node = demo.sound
	await press("ResultContinue")
	await wait(.5)
	await shot("42-qi-transfer-arc")
	while quest.mode != "recognition": await process_frame
	await wait(.5)
	check("the basin water sound plays positionally at the basin once it flows", sound.water.playing and sound.water.get_parent() == demo.basin)
	await shot("43-recognition")
	await press("ContinueExploring")
	check("closing returns to first person with the player's camera", not player.third_person and player.camera.is_current())
	player.third_person = true
	var view_from := Vector3(5.6, 10.05, 45.2)
	var to_basin: Vector3 = demo.basin.global_position-view_from
	demo.jump_to(view_from, atan2(-to_basin.x, -to_basin.z))
	player.pitch = -.2
	for i in 30: await physics_frame
	await wait(1.0)
	await shot("44-basin-flowing-water-shader")
	# Audio controls in the Esc menu.
	await send(KEY_ESCAPE)
	await wait(.4)
	quest.ambience_slider.value = .2
	quest.effects_slider.value = .6
	var amb := AudioServer.get_bus_index("Ambience")
	var fx := AudioServer.get_bus_index("Effects")
	check("Ambience and Effects sliders set their own buses", is_equal_approx(AudioServer.get_bus_volume_db(amb), linear_to_db(.2)) and is_equal_approx(AudioServer.get_bus_volume_db(fx), linear_to_db(.6)))
	await click(centre(quest.mute_toggle))
	check("Mute all sound mutes the master bus", AudioServer.is_bus_mute(0))
	await shot("45-menu-sound-controls")
	await click(centre(quest.mute_toggle))
	await press("MenuReset")
	await wait(.3)
	check("Reset Demo stops the basin water and Qi sounds; ambience keeps playing", not sound.water.playing and not sound.players.awaken.playing and not sound.players.basin.playing and sound.wind.playing and not AudioServer.is_bus_mute(0))
	check("Reset Demo restores the terminal layout and the player's camera", term.get_rect() == term.default_rect and player.camera.is_current() and player.third_person and quest.stage == 0)
	await wait(.5)
	await shot("46-after-reset-spawn")

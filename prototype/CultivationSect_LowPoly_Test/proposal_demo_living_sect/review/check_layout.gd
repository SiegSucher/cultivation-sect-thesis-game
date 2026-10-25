extends "res://proposal_demo_living_sect/review/capture_terminal.gd"
## Reuses the existing real mouse/key driver; assertions use actual geometry, not 720p constants.

func run() -> void:
	var path := OS.get_cmdline_user_args()[0]
	out = path.get_base_dir().path_join("layout-captures")
	DirAccess.make_dir_recursive_absolute(out)
	demo = load("res://proposal_demo_living_sect/proposal_demo.tscn").instantiate()
	root.add_child(demo)
	current_scene = demo
	for i in 15: await physics_frame
	tag = "-%dx%d" % [root.size.x, root.size.y]
	player = demo.player
	quest = demo.quest
	term = quest.code
	gate = demo.get_node("Buildings/sect_gate")
	var overlay := CanvasLayer.new()
	overlay.layer = 100
	root.add_child(overlay)
	pointer = Polygon2D.new()
	pointer.polygon = PackedVector2Array([Vector2.ZERO, Vector2(0, 14), Vector2(10, 10)])
	pointer.color = Color.WHITE
	overlay.add_child(pointer)
	demo.jump_to(AT_MENTOR, -.9)
	for i in 8: await physics_frame
	quest.stage = 1
	quest.language = "python"
	quest.show_code()
	await wait(.6)
	var expected := Vector2(root.size)
	check("canvas uses actual pixels at 100%", quest.get_node("Screen").size.is_equal_approx(expected), quest.get_node("Screen").size)
	check("default terminal responds to the viewport", term.get_rect() == term.default_rect and term.size.x <= expected.x*.66 and term.size.y <= expected.y-40, term.get_rect())
	if root.size.x == 1920: check("1080p terminal starts at 1100 x 760", term.size.is_equal_approx(Vector2(1100, 760)), term.size)
	check("reference automatically collapses in a narrow terminal", quest.tabs.visible == (term.size.x >= 980))
	check("editor and output retain readable font sizes", quest.editor.get_theme_font_size("font_size") == 20 and quest.console.get_theme_font_size("normal_font_size") == 18)
	check("world result remains beside the editor", in_free_area(player.global_position+Vector3.UP) and in_free_area(demo.mentor.global_position+Vector3.UP))
	var pos := player.global_position
	var yaw: float = player.yaw
	var pitch: float = player.pitch
	var gate_open: bool = gate.preview_open
	await click(centre(quest.editor))
	await type_text("awaken(qi)\nqi = 3", 100)
	await send(KEY_ENTER, 0, true)
	check("typed mistake and Ctrl+Enter produce a labelled language error", quest.editor.text == "awaken(qi)\nqi = 3" and quest.console.get_parsed_text().contains("Language error") and quest.console.get_parsed_text().contains("NameError"))
	await shot("error-default")
	# Window dragging and clamping, from a blank part of its title.
	var grab: Vector2 = term.title_bar.global_position+Vector2(100, 16)
	var before := term.position
	await drag(grab, grab+Vector2(55, 12), .2)
	check("title dragging moves the terminal", term.position.distance_to(before) > 20, term.position)
	grab = term.title_bar.global_position+Vector2(100, 16)
	await drag(grab, grab+Vector2(3000, 2000), .2)
	check("dragging clamps to the screen", Rect2(Vector2.ZERO, expected).grow(1).encloses(term.get_rect()), term.get_rect())
	await drag(term.get_global_rect().end-Vector2(4, 4), Vector2(120, 90), .3)
	check("corner resize stops at a usable minimum", term.size.is_equal_approx(term.min_size()) and term.size.y >= 480, term.size)
	check("essential controls remain inside the smallest terminal", reachable(["Run", "CodeBack", "Minimize", "RestoreLayout", "Editor", "Console", "ReferenceToggle", "TerminalOptions"]).is_empty(), reachable(["Run", "CodeBack", "Editor", "Console"]))
	var rect: Rect2 = term.get_global_rect()
	await drag(Vector2(rect.position.x+4, rect.get_center().y), Vector2(-100, rect.get_center().y), .3)
	check("left edge resize clamps without moving the opposite edge", term.position.x >= 0 and is_equal_approx(term.get_rect().end.x, rect.end.x), term.get_rect())
	await click(centre(quest.find_child("RestoreLayout", true, false)))
	check("Restore Layout restores the default rectangle", term.get_rect() == term.default_rect, term.get_rect())
	if not quest.tabs.visible: await click(centre(quest.reference_button))
	await wait(.2)
	check("reference can be expanded at either resolution", quest.tabs.is_visible_in_tree() and term.get_rect().end.x < expected.x-250)
	var tabs_width: float = quest.tabs.size.x
	var x: float = quest.split_v.get_global_rect().end.x+6
	await drag(Vector2(x, quest.split_h.get_global_rect().get_center().y), Vector2(x-40, quest.split_h.get_global_rect().get_center().y), .3)
	check("horizontal divider resizes reference", quest.tabs.size.x > tabs_width+20, quest.tabs.size.x)
	var h: float = quest.console.size.y
	var prog: Control = quest.split_v.get_child(0)
	var y: float = prog.get_global_rect().end.y+6
	await drag(Vector2(prog.get_global_rect().get_center().x, y), Vector2(prog.get_global_rect().get_center().x, y-35), .3)
	check("vertical divider resizes output", quest.console.size.y > h+20, quest.console.size.y)
	quest.tabs.current_tab = 2
	await wait(.2)
	check("worked solution remains locked before stronger hint", quest.solution_button.disabled and not quest.solution_view.get_parent().visible)
	await press("Hint")
	await press("Hint")
	var draft: String = quest.editor.text
	var runs: int = quest.attempts.get(quest.key(), 0)
	await press("ShowSolution")
	check("optional solution display changes no draft, run count or Qi", quest.solution_view.get_parent().visible and quest.editor.text == draft and quest.attempts.get(quest.key(), 0) == runs and quest.reserve == 0)
	# The solution is below the explanations on short screens and must scroll into view.
	var scroll: ScrollContainer = quest.solution_button.get_parent().get_parent()
	scroll.ensure_control_visible(quest.solution_view)
	await shot("reference-solution")
	await click(centre(quest.find_child("FontLarger", true, false)))
	check("code font control enlarges code and output", quest.code_font_size == 22 and quest.console.get_theme_font_size("normal_font_size") == 20)
	await click(centre(quest.minimize_button))
	check("Minimize leaves only the title bar", term.minimized and not term.body.visible and term.size.y < 80, term.size)
	await click(centre(quest.minimize_button))
	check("Restore returns the editor", not term.minimized and term.body.visible)
	await move_to(term.title_bar.global_position+Vector2(100, 16), .1)
	await button(true, true)
	await button(false)
	check("title double-click minimizes", term.minimized)
	await button(true, true)
	await button(false)
	quest.restore_terminal_layout()
	quest.set_ui_scale(1.25)
	await wait(.3)
	check("125% UI scale changes logical canvas without changing output pixels", root.size == Vector2i(expected) and quest.get_node("Screen").size.is_equal_approx(expected/1.25), quest.get_node("Screen").size)
	check("scaled terminal stays on screen", Rect2(Vector2.ZERO, quest.get_node("Screen").size).grow(1).encloses(term.get_rect()), term.get_rect())
	await shot("ui-scale-125")
	# Real title drag and resize with a scaled canvas, too.
	grab = term.title_bar.global_position+Vector2(100, 16)
	before = term.position
	await drag(grab, grab+Vector2(25, 0), .2)
	check("drag still works at 125% UI scale", term.position.x > before.x+15, term.position)
	quest.set_ui_scale(1.0)
	await wait(.3)
	quest.restore_terminal_layout()
	quest.font_step(-2)
	await click(centre(quest.options_button))
	await wait(.2)
	check("secondary actions menu opens", quest.options_button.get_popup().visible)
	await shot("options-menu")
	quest.options_button.get_popup().hide()
	await click(centre(quest.editor))
	await type_text("qi = 3\nawaken(qi)", 100)
	await click(centre(quest.run_button))
	check("typing and Run still succeed after window operations", quest.stage_solved and quest.console.get_parsed_text().contains("Success"))
	check("typing, drag, resize and UI controls leave player, camera and Gate untouched", world_still(pos, true, gate_open) and is_equal_approx(player.yaw, yaw) and is_equal_approx(player.pitch, pitch))
	await shot("success-world")
	# Test closing in both camera modes on an unsolved step, keeping the same draft.
	quest.stage_solved = false
	quest.close_ui()
	check("close restores third-person camera and input", player.third_person and player.camera.current and player.is_physics_processing() and player.is_processing_unhandled_input() and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
	player.third_person = false
	player.update_camera()
	quest.show_code()
	await wait(.2)
	quest.close_ui()
	check("close restores first-person camera and input", not player.third_person and player.camera.current and player.is_physics_processing() and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
	quest.reset_demo()
	quest.show_menu()
	await wait(.2)
	await shot("menu")
	quest.close_ui()
	check("reset clears draft, hints, solution, effects and quest", quest.stage == 0 and quest.drafts.is_empty() and quest.solutions.is_empty() and quest.hints.is_empty() and not demo.basin.active and demo.aura == null)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks": results.size(), "failures": failures, "resolution": str(root.size), "results": results}, "  "))
	f.close()
	print("LAYOUT ", root.size, ": ", results.size(), " checks; ", failures, " failures")
	quit(1 if failures else 0)

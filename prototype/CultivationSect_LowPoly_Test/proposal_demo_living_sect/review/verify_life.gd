extends "res://proposal_demo_living_sect/review/verify_refinement.gd"
## Optional-content regression, real input, physical walking, and native-resolution screenshots.
var life: Node3D
var capture_dir := ""
var rendered := false

func shot(name: String) -> void:
	if not rendered: return
	await frames(5)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(capture_dir.path_join(name+".png"))

func life_button(id: String) -> void:
	var button: Button = life.panel.find_child(id, true, false)
	check("optional button available: "+id, button != null and button.is_visible_in_tree() and not button.disabled)
	if button: button.pressed.emit()
	await frames(3)

func core_state() -> Array:
	return [quest.stage, quest.language, quest.reserve, quest.stage_solved, quest.recognitions_granted,
		quest.drafts.duplicate(true), quest.solutions.duplicate(true), demo.basin.active]

func framed(point: Vector3) -> bool:
	var camera: Camera3D = life.activity_camera
	var p: Vector2 = camera.unproject_position(point)
	return camera.current and not camera.is_position_behind(point) and p.x > life.panel.get_rect().end.x+8 and Rect2(Vector2.ZERO, root.size).has_point(p)

func walk_to(target: Vector3) -> void:
	player.automated = true
	var ticks := 0
	while Vector2(player.position.x-target.x, player.position.z-target.z).length() > .55 and ticks < 1600:
		var direction := Vector3(target.x-player.position.x, 0, target.z-player.position.z).normalized()
		player.drive = direction
		player.yaw = atan2(-direction.x, -direction.z)
		await physics_frame
		ticks += 1
	player.drive = Vector3.ZERO
	player.automated = false
	check("walk reaches "+str(target), ticks < 1600 and absf(player.position.y-target.y) < .6, player.position)

func run() -> void:
	var path: String = OS.get_cmdline_user_args()[0]
	rendered = DisplayServer.get_name() != "headless"
	demo = load("res://proposal_demo_living_sect/proposal_demo.tscn").instantiate()
	root.add_child(demo)
	current_scene = demo
	await frames(12)
	capture_dir = path.get_base_dir().path_join("screenshots-%dx%d" % [root.size.x, root.size.y])
	DirAccess.make_dir_recursive_absolute(capture_dir)
	player = demo.player
	quest = demo.quest
	life = demo.life
	gate = demo.get_node("Buildings/sect_gate")
	await tap(KEY_J)
	check("J opens journal and pauses controls", life.panel.visible and quest.mode == "life" and paused())
	check("journal names main goal and optional practice", life.body.text.contains("Guide") and life.body.text.contains("OPTIONAL"))
	await tap(KEY_J)
	check("J closes journal and restores camera and controls", live() and player.camera.current)
	await go(Vector3(0, 10.1, 48))
	await walk_to(Vector3(-5, 10, 46))
	await walk_to(Vector3(-5, 10, 38))
	await walk_to(Vector3(-7, 10, 38))
	check("Lin has a discoverable E prompt", quest.nearest() == "lin" and quest.prompt.text.contains("Lin"))
	await shot("01-lantern-court")
	var state := core_state()
	await tap(KEY_E)
	check("Lin introduction pauses safely", paused() and life.view == "lin")
	check("Lin is framed beside the conversation panel", framed(life.LIN+Vector3.UP))
	await shot("02-lin-invitation")
	await life_button("StartPractice")
	check("all three lanterns are visible beside the activity panel", framed(life.lamps[0].global_position) and framed(life.lamps[1].global_position) and framed(life.lamps[2].global_position))
	await life_button("LifeHint")
	check("hint explains without progressing", life.solved == 0 and life.feedback.text.contains("2 + 1"))
	await life_button("Answer1")
	check("wrong prediction leaves lamps unlit", life.solved == 0 and life.wrong_attempts == 1 and life.lights[0].light_energy == 0)
	await shot("03-reading-feedback")
	await life_button("Answer0")
	check("first answer lights exactly one lantern", life.solved == 1 and life.lights[0].light_energy > 0 and life.lights[1].light_energy == 0)
	life.answer(0)
	check("double activation cannot award two lamps", life.solved == 1)
	await tap(KEY_ESCAPE)
	check("leaving restores camera and keeps practice progress", live() and player.camera.current and life.solved == 1)
	await tap(KEY_E)
	await life_button("StartPractice")
	check("return resumes at second puzzle", life.heading.text.begins_with("Lantern 2"))
	await life_button("Answer1")
	await life_button("NextLantern")
	await life_button("Answer2")
	await shot("04-three-lanterns-restored")
	await life_button("NextLantern")
	check("practice seal complete without modifying main quest", life.solved == 3 and core_state() == state and life.view == "complete")
	await shot("05-practice-seal")
	await life_button("LifeJournal")
	check("journal records learned concepts", life.body.text.contains("stored receives") and life.body.text.contains("Lantern Keeper"))
	await shot("06-journal")
	for scale in [1.0, 1.25, .9]:
		quest.set_ui_scale(scale)
		await frames(5)
		var rect: Rect2 = life.panel.get_global_rect()
		var screen: Control = quest.get_node("Screen")
		check("journal fits viewport at scale "+str(scale), Rect2(Vector2.ZERO, screen.size).encloses(rect))
		var close: Button = life.panel.find_child("LifeClose", true, false)
		check("journal close always reachable at scale "+str(scale), rect.encloses(close.get_global_rect()))
	quest.set_ui_scale(1.0)
	await tap(KEY_ESCAPE)
	await walk_to(Vector3(-5, 10, 38))
	await walk_to(Vector3(0, 10, 46))
	await walk_to(Vector3(11, 10, 46))
	await walk_to(Vector3(19, 10, 46))
	await walk_to(Vector3(19, 10, 36))
	check("Mei reachable without crossing basin", quest.nearest() == "mei")
	await tap(KEY_E)
	check("Mei acknowledges dry basin", life.body.text.contains("quiet today"))
	await tap(KEY_ESCAPE)
	# Completing optional content first must not break the original typed quest.
	await quest_to_stage1("python")
	await full_run("python", true)
	check("original quest succeeds with optional content complete", quest.recognitions_granted == 1 and life.solved == 3)
	await go(Vector3(19, 10.1, 36))
	await tap(KEY_E)
	check("Mei reacts to both restored water and lanterns", life.body.text.contains("water again") and life.body.text.contains("Lin's lanterns"))
	check("Mei is framed beside her dialogue", framed(life.MEI+Vector3.UP))
	await shot("07-court-keeper-after-quest")
	await tap(KEY_ESCAPE)
	quest.reset_demo()
	await frames(6)
	check("Reset Demo clears optional and main content together", life.solved == 0 and life.wrong_attempts == 0 and life.visited.is_empty() and life.lights[0].light_energy == 0 and quest.stage == 0 and live())
	# Each language presentation, escape from first person, and mid-practice reset.
	for lang in ["python", "c", "java"]:
		await go(Vector3(-7, 10.1, 38), false)
		await tap(KEY_E)
		await life_button("Practice_"+lang)
		check(lang+": selected practice language", life.practice_language == lang)
		for index in [0, 1]:
			var result: Dictionary = quest.runner.run(lang, 1, life.snippet(index), "practice", 0, 0)
			check(lang+": reading answer agrees with interpreter "+str(index+1), result.ok and str(result.output[0][1]) == ("3" if index == 0 else "1"), result.output)
		await shot("08-practice-"+lang)
		for i in 3:
			await life_button("Answer%d" % i)
			await life_button("NextLantern")
		await tap(KEY_ESCAPE)
		check(lang+": first-person camera restored", not player.third_person and player.camera.current and live())
		quest.reset_demo()
		await frames(5)
	await go(Vector3(-7, 10.1, 38))
	life.open_practice()
	life.answer(0)
	quest.reset_demo()
	await frames(6)
	check("reset during optional camera restores spawn and no residual light", player.camera.current and not life.panel.visible and life.solved == 0 and life.lights[0].light_energy == 0 and player.position.distance_to(SPAWN) < .4)
	quest.stage = 1
	quest.language = "python"
	quest.show_code()
	quest.editor.text = ""
	quest.editor.grab_focus()
	await key(KEY_J, true, 106)
	await key(KEY_J, false, 106)
	check("J types into code instead of opening journal", quest.editor.text == "j" and quest.mode == "code" and not life.panel.visible)
	quest.close_ui()
	state = core_state()
	life.open_practice()
	life.answer(0)
	check("mid-quest practice preserves code draft and quest state", core_state() == state and quest.drafts.get("python:1") == "j")
	quest.reset_demo()
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": results.size(), "failures": failures, "resolution": str(root.size), "rendered": rendered, "results": results}, "  "))
	file.close()
	print("SECT LIFE: %d checks, %d failures" % [results.size(), failures])
	quit(1 if failures else 0)

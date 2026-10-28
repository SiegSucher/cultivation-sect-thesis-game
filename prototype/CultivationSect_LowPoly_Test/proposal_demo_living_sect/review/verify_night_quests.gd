extends SceneTree
## Run headless for progression checks; run rendered at either target resolution for PNG evidence.
const Lessons := preload("res://proposal_demo_living_sect/lessons.gd")
const Runner := preload("res://proposal_demo_living_sect/code_runner.gd")
var demo: Node3D
var quest: CanvasLayer
var failures := 0
var checks := 0
var out := "res://proposal_demo_living_sect/review/main-quests"

func _initialize() -> void:
	run()

func check(label: String, ok: bool, detail = null) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+label+(" / "+str(detail) if not ok else ""))

func frames(count := 4) -> void:
	for i in count: await physics_frame

func shot(id: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await frames(12)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(id+".png"))

func wait_mode(expected: String) -> void:
	for i in 600:
		if quest.mode == expected: return
		await physics_frame
	check("timed result reaches "+expected, false)

func run() -> void:
	Engine.time_scale = 4
	if "--export-check" in OS.get_cmdline_user_args():
		out = OS.get_executable_path().get_base_dir().path_join("CultivationSect_LowPoly_Test/proposal_demo_living_sect/review/night-export")
	var runner := Runner.new()
	for language: String in Lessons.ORDER:
		var lesson := Lessons.for_language(language)
		for stage in [3, 4]:
			var effect := "bridge" if stage == 3 else "ward"
			var result := runner.run(language, stage, lesson.solution[stage-1], lesson.files[stage-1], 0, 3)
			check(language+" authored solution "+effect, result.ok and result.effects[effect] > 0)
			for card: Array in lesson.cards[stage-1]:
				var example := runner.run(language, stage, card[2], "example", 0, 3)
				check(language+" card "+card[0], (not example.ok) if card.size() > 3 else (example.ok and example.effects[effect] == 0))
			var wrong: String = lesson.solution[stage-1].replace("charge == 3", "charge == 2") if stage == 3 else lesson.solution[stage-1].replace("range(3)", "range(2)").replace("seal < 3", "seal < 2")
			result = runner.run(language, stage, wrong, "wrong", 0, 3)
			check(language+" wrong amount rejected "+effect, (result.ok and result.effects.bridge == 0) if stage == 3 else (not result.ok and result.fail.kind == "ward_count"))
			result = runner.run(language, stage-1, lesson.solution[stage-1], "locked", 0, 3)
			check(language+" service locked before unlock "+effect, not result.ok)
			result = runner.run(language, stage, lesson.solution[stage-1]+("\nmissing_name" if language == "python" else "\nunknownCommand();"), "rollback", 0, 3)
			check(language+" later error prevents success "+effect, not result.ok)
	demo = load("res://proposal_demo_living_sect/proposal_demo.tscn").instantiate()
	root.add_child(demo)
	current_scene = demo
	await frames(40)
	out += "-%dx%d" % [root.size.x, root.size.y]
	DirAccess.make_dir_recursive_absolute(out)
	quest = demo.quest
	for environment: WorldEnvironment in demo.find_children("*", "WorldEnvironment", true, false):
		check("night ambient and dark sky", environment.environment.ambient_light_energy <= .35 and environment.environment.sky.sky_material.sky_energy_multiplier <= .4)
	for moon: DirectionalLight3D in demo.find_children("*", "DirectionalLight3D", true, false):
		check("moonlight replaces daytime sun", moon.light_energy < .35 and moon.light_color.b > moon.light_color.r)
	check("services locked before basin", not quest.nearest() in ["crossing", "ward"] and not demo.story.crossing_open and not demo.story.ward_active)
	demo.player.position = demo.story.BRIDGE_AT+Vector3(0, .3, 1)
	demo.player.automated = true
	demo.player.drive = Vector3.FORWARD
	await frames(80)
	demo.player.drive = Vector3.ZERO
	demo.player.automated = false
	check("sealed crossing physically blocks passage", demo.player.position.z > demo.story.BRIDGE_AT.z-1.2 and not demo.story.barrier_collision.disabled, demo.player.position)
	for language: String in Lessons.ORDER:
		quest.reset_demo()
		demo.player.position = Vector3(10.4, 10.05, 44.8)
		quest.accept()
		quest.choose_language(language)
		for stage in [1, 2, 3, 4]:
			check(language+" progression stage "+str(stage), quest.stage == stage)
			if stage >= 3:
				quest.close_ui()
				var target: Node3D = demo.story.bridge if stage == 3 else demo.story.ward
				demo.player.position = target.global_position+Vector3(0, .05, 2.0)
				await frames()
				check(language+" E interaction discovers service "+str(stage), quest.nearest() == ("crossing" if stage == 3 else "ward"))
				quest.interact()
				check(language+" new service teaches first "+str(stage), quest.mode == "teach" and quest.teach_stage == stage)
				quest.finish_teaching()
				await frames()
				var pixel: Vector2 = quest.code_cam.unproject_position(target.global_position+Vector3.UP*.5)
				check(language+" service framed beside editor "+str(stage), pixel.x > quest.code.get_rect().end.x and Rect2(Vector2.ZERO, root.size).has_point(pixel))
			else: quest.show_code()
			quest.editor.text = quest.lesson().solution[stage-1]
			if stage >= 3:
				quest.save_draft()
				var draft: String = quest.editor.text
				quest.close_ui()
				quest.open_story_quest()
				check(language+" service draft survives close "+str(stage), quest.editor.text == draft)
				quest.show_hint()
				quest.show_hint()
				quest.show_solution()
				check(language+" hints and worked answer available "+str(stage), quest.solution_view.text.length() > 0 and quest.editor.text == draft)
				# A valid command followed by an error must never change the world.
				quest.editor.text += "\nmissing_name" if language == "python" else "\nunknownCommand();"
				quest.run_code()
				check(language+" failed run keeps world unchanged "+str(stage), not quest.stage_solved and (not demo.story.crossing_open if stage == 3 else not demo.story.ward_active))
				quest.editor.text = draft
			quest.run_code()
			check(language+" typed run solves stage "+str(stage), quest.stage_solved)
			if language == "java" and stage >= 3: await shot("0%d-main-quest-code" % stage)
			quest.continue_after_success()
			if stage == 1: await wait_mode("dialogue")
			if stage == 2: await wait_mode("recognition")
			await frames()
			if language == "java" and stage >= 3:
				await create_timer(2.0).timeout
				await shot("0%d-main-quest-result" % stage)
		check(language+" all four completed once", quest.stage == 5 and quest.recognitions_granted == 1 and demo.basin.active and demo.story.crossing_open and demo.story.ward_active and quest.reserve == 3)
		check(language+" completed objective has no marker", quest.objective_target() == null)
		quest.close_ui()
		demo.life.open_journal()
		check(language+" journal records both services", demo.life.body.text.contains("an if condition") and demo.life.body.text.contains("a for loop"))
		quest.close_ui()
	quest.close_ui()
	demo.player.position = demo.story.BRIDGE_AT+Vector3(0, .3, 1)
	demo.player.automated = true
	demo.player.drive = Vector3.FORWARD
	for i in 360:
		if demo.player.position.z < demo.story.BRIDGE_AT.z-8: break
		await physics_frame
	demo.player.drive = Vector3.ZERO
	demo.player.automated = false
	check("released crossing is physically walkable", demo.player.position.z < demo.story.BRIDGE_AT.z-8 and demo.player.position.y > 9.8, demo.player.position)
	# Capture identical lantern cameras before/after; solving a reading must light its pool and halo.
	Engine.time_scale = 1
	demo.player.position = Vector3(-7, 10.05, 38)
	demo.life.open_practice()
	await shot("01-lanterns-unlit")
	for answer in [0, 1, 2]:
		demo.life.answer(answer)
		if demo.life.solved < 3: demo.life.open_practice()
	check("all lanterns emit warm light and visible halos", demo.life.solved == 3 and demo.life.lights[0].light_energy >= 1.5 and demo.life.halos[2].visible)
	await shot("02-lanterns-lit")
	quest.close_ui()
	var camera := Camera3D.new()
	demo.add_child(camera)
	camera.fov = 62
	camera.far = 800
	camera.position = Vector3(0, 17, 64)
	camera.look_at(Vector3(3, 10.8, 34))
	camera.make_current()
	demo.player.set_physics_process(false)
	for canvas: CanvasLayer in demo.find_children("*", "CanvasLayer", true, false): canvas.hide()
	await shot("05-night-courtyard")
	camera.position = Vector3(-1, 16, 30)
	camera.look_at(Vector3(-9, 11.2, 15))
	await shot("06-main-quests-complete")
	quest.reset_demo()
	await frames()
	check("reset clears story, drafts, lanterns and main quest", quest.stage == 0 and quest.drafts.is_empty() and not demo.story.crossing_open and not demo.story.ward_active and demo.story.barrier.visible and not demo.story.veil.visible and demo.life.solved == 0 and not demo.life.halos[0].visible and not demo.basin.active)
	var file := FileAccess.open(out.path_join("result.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "resolution": str(root.size)}, "  "))
	print("MAIN QUESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

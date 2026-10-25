extends SceneTree
## Rendered rehearsal of the presenter route, in real time:
##   spawn -> Guide introduction -> walk through the Gate to the Mentor -> accept -> language ->
##   Mentor's lesson cards -> type the awakening code with one mistake, run, fix, run -> awakening
##   -> channelling lesson -> walk to the basin -> type with one mistake, run, fix, run -> basin
##   flows -> recognition -> repeat talk -> Reset Demo.
## Walking uses the unchanged controller; typing sends real key events into the editor at about
## 7 characters per second. Pauses stand in for the presenter reading aloud. Saves screenshots
## and timings.
## godot --path . --script res://proposal_demo_living_sect/review/rehearse_demo.gd -- <out_dir> [python|c|java]
const Lessons := preload("res://proposal_demo_living_sect/lessons.gd")
const TO_GUIDE := [Vector3(4.9, 0, 130.6)]
const TO_MENTOR := [Vector3(-3, 0, 132), Vector3(-14, 0, 115), Vector3(0, 0, 105), Vector3(0, 4, 94), Vector3(0, 4, 80),
	Vector3(0, 4, 65), Vector3(0, 10, 50), Vector3(4.4, 10, 45.6)]
const TO_BASIN := [Vector3(10.4, 10, 42.7)]
# A typical first mistake per language and stage, then the fix. Python shows a language error and a
# game rule; C step 2 shows real C outside the supported subset; Java step 2 shows a lesson rule.
const MISTAKES := {
	"python": ["awaken(qi)\nqi = 3", "reserve = qi_reserve()\nchannel_basin(5)"],
	"c": ["int qi = 3\nawaken(qi);", "int reserve = qi_reserve();\nif (reserve == 3) channel_basin(reserve);"],
	"java": ["int qi;\nSect.awaken(qi);", "Sect.channelBasin(3);"],
}
var demo: Node3D
var player: CharacterBody3D
var quest: CanvasLayer
var out := ""
var marks := []
var t0 := 0
var mouse := {}

func _initialize() -> void:
	run()

func now() -> float:
	return (Time.get_ticks_msec()-t0)/1000.0

func mark(what: String) -> void:
	marks.append({"t": snappedf(now(), .01), "event": what})
	print("%7.2f  %s" % [now(), what])

func shot(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out.path_join(name+".png"))

func pause(seconds: float) -> void:
	await create_timer(seconds).timeout

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

func type_text(text: String) -> void:
	await send(KEY_A, 0, true)                     # select all, so typing replaces the draft
	for ch in text:
		if ch == "\n": await send(KEY_ENTER)
		else: await send(KEY_NONE, ch.unicode_at(0))
		await pause(1.0/7.0)

func press(id: String) -> void:
	var b: Button = quest.find_child(id, true, false)
	assert(b and b.is_visible_in_tree() and not b.disabled, "button not available: "+id)
	b.pressed.emit()
	await process_frame
	mark("pressed "+id)

func walk(route: Array) -> void:
	player.automated = true
	for p: Vector3 in route:
		var guard := 0
		while Vector2(p.x-player.position.x, p.z-player.position.z).length() > .4 and guard < 1500:
			var d := Vector3(p.x-player.position.x, 0, p.z-player.position.z).normalized()
			player.drive = d
			player.yaw = lerp_angle(player.yaw, atan2(-d.x, -d.z), .12)
			await physics_frame
			guard += 1
		if p == Vector3(0, 10, 50):
			player.drive = Vector3.ZERO
			await shot("06-living-court-mentor-and-basin")
	player.drive = Vector3.ZERO

func run() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0]
	var lang: String = args[1] if args.size() > 1 else "python"
	var lesson: Dictionary = Lessons.LESSONS[lang]
	DirAccess.make_dir_recursive_absolute(out)
	demo = load("res://proposal_demo_living_sect/proposal_demo.tscn").instantiate()
	root.add_child(demo)
	current_scene = demo
	for i in 10: await physics_frame
	player = demo.player
	quest = demo.quest
	t0 = Time.get_ticks_msec()
	mark("spawn (forest start), third person")
	await shot("01-arrival-guide-marker")
	await walk(TO_GUIDE)
	mark("beside the Guide")
	await shot("02-guide-prompt")
	await send(KEY_E)
	mouse["dialogue_open"] = Input.mouse_mode
	mark("E: Guide introduction")
	var pages: int = Lessons.GUIDE_INTRO.size()
	for i in pages:
		await pause(clampf(Lessons.GUIDE_INTRO[i].length()/16.0, 3.5, 9.0))   # read aloud
		if i == 0: await shot("03-guide-introduction")
		await press("Next")
	mouse["after_close"] = Input.mouse_mode
	await shot("04-objective-points-to-mentor")
	await walk(TO_MENTOR)
	var walked := now()
	mark("arrived beside the Mentor")
	await send(KEY_E)
	await pause(3)
	await press("Next")
	await pause(7)
	await shot("07-mentor-offer")
	await press("Accept")
	await pause(3)
	await press("Choose_"+lang)
	for i in lesson.cards[0].size():
		await pause(clampf(lesson.cards[0][i][1].length()/16.0, 4.0, 10.0))
		if i == 0: await shot("08-mentor-teaching-"+lang)
		if i == lesson.cards[0].size()-1: await shot("09-teaching-game-command-"+lang)
		await press("TeachNext")
	await pause(2)
	await shot("10-coding-interface-"+lang)
	await type_text(MISTAKES[lang][0])
	await send(KEY_ENTER, 0, true)                 # Ctrl+Enter runs
	mark("ran awakening code (mistake)")
	await pause(7)
	await shot("11-awakening-error-"+lang)
	await type_text(lesson.solution[0])
	await send(KEY_ENTER, 0, true)
	mark("ran awakening code (fixed)")
	await pause(4)
	await shot("12-awakening-success-"+lang)
	await press("ResultContinue")
	await pause(1.2)
	await shot("13-qi-awakening")
	while quest.mode != "dialogue": await process_frame
	await pause(6)
	await shot("14-mentor-introduces-basin-step")
	await press("ShowMe")
	for i in lesson.cards[1].size():
		await pause(clampf(lesson.cards[1][i][1].length()/16.0, 4.0, 10.0))
		if i == lesson.cards[1].size()-1: await shot("15-channelling-lesson-"+lang)
		await press("TeachNext")
	await shot("16-objective-points-to-basin")
	await walk(TO_BASIN)
	mark("beside the basin")
	await shot("17-basin-prompt")
	await send(KEY_E)
	await pause(2)
	await type_text(MISTAKES[lang][1])
	await send(KEY_ENTER, 0, true)
	mark("ran basin code (mistake)")
	await pause(6)
	await shot("18-basin-error-"+lang)
	await type_text(lesson.solution[1])
	await send(KEY_ENTER, 0, true)
	mark("ran basin code (fixed)")
	await pause(4)
	await shot("19-basin-success-"+lang)
	await press("ResultContinue")
	await pause(.6)
	await shot("20-qi-channelled-into-basin")
	while quest.mode != "recognition": await process_frame
	mark("recognition shown")
	await pause(.5)
	await shot("21-recognition")
	await pause(5)
	await press("ContinueExploring")
	var finished := now()
	await pause(1.5)
	await shot("22-basin-flowing-third-person")
	player.third_person = false
	player.update_camera()
	await shot("23-basin-flowing-first-person")
	player.third_person = true
	player.update_camera()
	await send(KEY_ESCAPE)
	await pause(1)
	await press("MenuReset")
	await pause(1.5)
	await shot("24-after-reset-spawn")
	var record := {"language": lang, "spawn_to_mentor_seconds": snappedf(walked, .01), "spawn_to_completion_seconds": snappedf(finished, .01),
		"total_with_reset_seconds": snappedf(now(), .01), "events": marks, "mouse_mode (0 visible, 2 captured)": mouse,
		"state_after_reset": {"stage": quest.stage, "guide_heard": quest.guide_heard, "language": quest.language, "reserve": quest.reserve,
			"recognition": quest.recognition_earned, "basin_active": demo.basin.active, "drafts": quest.drafts.size(), "player": player.position}}
	var f := FileAccess.open(out.path_join("rehearsal-%s.json" % lang), FileAccess.WRITE)
	f.store_string(JSON.stringify(record, "  "))
	f.close()
	print("REHEARSAL %s: spawn to Mentor %.1f s, spawn to completion %.1f s, total %.1f s" % [lang, walked, finished, now()])
	quit()

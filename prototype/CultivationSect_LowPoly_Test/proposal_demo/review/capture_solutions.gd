extends SceneTree
## Rendered captures of the optional worked solution in one language: the Hints tab before the
## reveal, the revealed step-1 and step-2 solutions, the revealed program typed and run by the
## student, and the hidden state again after Reset Demo.
## godot --path . --script res://proposal_demo/review/capture_solutions.gd -- <out_dir> [python|c|java]
const AT_MENTOR := Vector3(4.4, 10.05, 45.6)
const AT_BASIN := Vector3(10.4, 10.05, 42.7)
var demo: Node3D
var player: CharacterBody3D
var quest: CanvasLayer
var out := ""
var lang := ""

func _initialize() -> void:
	run()

func shot(name: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out.path_join(name+"-"+lang+".png"))
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

func type_text(text: String) -> void:
	await send(KEY_A, 0, true)
	for ch in text:
		if ch == "\n": await send(KEY_ENTER)
		else: await send(KEY_NONE, ch.unicode_at(0))

func press(id: String) -> void:
	var b: Button = quest.find_child(id, true, false)
	assert(b and b.is_visible_in_tree() and not b.disabled, "button not available: "+id)
	b.pressed.emit()
	for i in 2: await process_frame

func go(at: Vector3) -> void:
	demo.jump_to(at, player.yaw)
	for i in 8: await physics_frame

func to_editor() -> void:
	await go(AT_MENTOR)
	await send(KEY_E)
	await press("Next")
	await press("Accept")
	await press("Choose_"+lang)
	await press("TeachSkip")
	quest.tabs.current_tab = 2               # Hints
	await process_frame

func reveal() -> void:
	await press("Hint")
	await press("Hint")
	await press("ShowSolution")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0]
	lang = args[1] if args.size() > 1 else "python"
	DirAccess.make_dir_recursive_absolute(out)
	demo = load("res://proposal_demo/proposal_demo.tscn").instantiate()
	root.add_child(demo)
	current_scene = demo
	for i in 10: await physics_frame
	player = demo.player
	quest = demo.quest
	await to_editor()
	await shot("25-hints-solution-hidden")
	await reveal()
	await shot("26-worked-solution-step1")
	await type_text(quest.solution_view.get_parsed_text())
	await send(KEY_ENTER, 0, true)
	await shot("27-revealed-solution-typed-and-run")
	await press("ResultContinue")
	while quest.mode != "dialogue": await process_frame
	await press("ShowMe")
	await press("TeachNext")
	await press("TeachNext")
	await go(AT_BASIN)
	await send(KEY_E)
	quest.tabs.current_tab = 2
	await reveal()
	await shot("28-worked-solution-step2")
	await type_text(quest.solution_view.get_parsed_text())
	await send(KEY_ENTER, 0, true)
	await press("ResultContinue")
	while quest.mode != "recognition": await process_frame
	await press("RecognitionReset")
	await to_editor()
	await shot("29-after-reset-solution-hidden")
	print("CAPTURE %s done: stage %d, solutions %s" % [lang, quest.stage, quest.solutions])
	quit()

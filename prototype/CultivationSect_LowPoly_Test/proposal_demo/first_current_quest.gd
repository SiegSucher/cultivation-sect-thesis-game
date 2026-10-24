extends CanvasLayer
## "The First Current": the Guide's introduction, the Mentor's offer and syntax teaching, and two
## typed-code stages run by the sect's learning interpreter (code_runner.gd, a custom interpreter
## for a small subset of Python, C and Java). Stage 1 awakens the apprentice's Qi
## (reserve 3); stage 2, started at the basin, channels that reserve into the basin. While any
## panel is open, movement and camera look are paused and the mouse is released; closing restores
## them. Reset Demo clears everything.
const Lessons := preload("res://proposal_demo/lessons.gd")
const Runner := preload("res://proposal_demo/code_runner.gd")
const TALK_RANGE := 3.5
const BASIN_RANGE := 3.4
const GOLD := Color("ffd27a")
const TEXT := Color("f3ead2")
const CYAN := Color("7fe6ff")

class PointerArrow extends Control:
	## Small arrow pointing toward the objective, relative to the view direction.
	var angle := 0.0
	func _draw() -> void:
		var c := size/2
		var pts := PackedVector2Array()
		for p in [Vector2(0, -10), Vector2(8, 8), Vector2(0, 3), Vector2(-8, 8)]: pts.append(c+p.rotated(angle))
		draw_colored_polygon(pts, Color("ffd27a"))

var world: Node3D
var player: CharacterBody3D
var guide: Node3D
var mentor: Node3D
var basin: Node3D
var marker: MeshInstance3D
var runner := Runner.new()

# Quest state for one run. reset_demo() clears all of it.
var guide_heard := false       # introduction finished or skipped
var guide_page := 0
var met := false
var declined := false
var language := ""
var stage := 0                 # 0 not accepted, 1 awakening, 2 basin, 3 complete
var stage_solved := false      # current stage ran correctly; its world effect has not played yet
var reserve := 0
var shown_reserve := 0.0       # animated Qi indicator value
var recognition_earned := false
var recognitions_granted := 0
var drafts := {}               # "lang:stage" -> learner text
var consoles := {}             # "lang:stage" -> console BBCode
var hints := {}                # "lang:stage" -> hints revealed (0-2)
var solutions := {}            # "lang:stage" -> worked solution revealed (shown only; never typed or run)
var attempts := {}             # "lang:stage" -> runs
var taught := {}               # "lang:stage" -> lesson cards finished or skipped
var teach_stage := 1
var teach_page := 0
var teach_then := ""           # what follows the cards: "code", "basin" or "close"

var ui_open := false
var mode := ""                 # "", dialogue, language, teach, code, flow, recognition, menu
var saved_third := true
var run := 0                   # invalidates pending timed steps after Reset Demo
var bob := 0.0

var mono: SystemFont
var prompt: Label
var tracker: PanelContainer
var objective: Label
var arrow: PointerArrow
var pointer_label: Label
var qi_bar: ProgressBar
var qi_label: Label
var status: Label
var dialogue: PanelContainer
var speaker: Label
var dialogue_text: Label
var dialogue_buttons: HBoxContainer
var language_panel: PanelContainer
var teach: PanelContainer
var teach_head: Label
var teach_title: Label
var teach_text: Label
var teach_example_head: Label
var teach_example: RichTextLabel
var teach_back: Button
var teach_next: Button
var code: PanelContainer
var code_title: Label
var code_objective: Label
var change_language: Button
var header_view: RichTextLabel
var editor: CodeEdit
var footer_view: RichTextLabel
var run_button: Button
var attempts_label: Label
var console: RichTextLabel
var continue_button: Button
var tabs: TabContainer
var lesson_box: VBoxContainer
var reference_label: RichTextLabel
var hint_button: Button
var hint_label: Label
var solution_button: Button
var solution_note: Label
var solution_view: RichTextLabel
var recognition: PanelContainer
var recognition_text: Label
var menu: PanelContainer

# ---------------------------------------------------------------- construction
func _ready() -> void:
	layer = 10
	mono = SystemFont.new()
	mono.font_names = PackedStringArray(["Consolas", "Cascadia Mono", "Courier New", "monospace"])
	var screen := Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.theme = make_theme()
	add_child(screen)
	build_tracker(screen)
	prompt = label(screen, "", 24)
	prompt.position = Vector2(390, 560)
	prompt.size = Vector2(500, 40)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	prompt.add_theme_constant_override("outline_size", 8)
	build_dialogue(screen)
	build_language(screen)
	build_teach(screen)
	build_code(screen)
	build_recognition(screen)
	build_menu(screen)
	marker = MeshInstance3D.new()
	marker.name = "ObjectiveMarker"
	var cone := CylinderMesh.new()
	cone.top_radius = .22
	cone.bottom_radius = 0.0
	cone.height = .42
	cone.radial_segments = 8
	var m := StandardMaterial3D.new()
	m.albedo_color = GOLD
	m.emission_enabled = true
	m.emission = GOLD
	m.emission_energy_multiplier = .9
	cone.material = m
	marker.mesh = cone
	world.add_child(marker)
	hide_panels()
	update_status()

func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 19
	var box := StyleBoxFlat.new()
	box.bg_color = Color(.08, .12, .115, .95)
	box.border_color = Color("6fa898")
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(16)
	t.set_stylebox("panel", "PanelContainer", box)
	var looks := {"normal": "2c4a43", "hover": "3d665b", "pressed": "c79a4a", "disabled": "263230", "hover_pressed": "d4a85a"}
	for state: String in looks:
		var b := StyleBoxFlat.new()
		b.bg_color = Color(looks[state])
		b.set_corner_radius_all(6)
		b.set_content_margin_all(9)
		b.border_color = Color("6fa898")
		b.set_border_width_all(1)
		t.set_stylebox(state, "Button", b)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = GOLD
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(6)
	t.set_stylebox("focus", "Button", focus)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color("1c1608"))
	t.set_color("font_disabled_color", "Button", Color("7f8a86"))
	t.set_color("font_color", "Label", TEXT)
	return t

func panel(parent: Control, at: Vector2, size: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	p.position = at
	p.custom_minimum_size = size
	parent.add_child(p)
	return p

func label(parent: Control, text: String, size := 19, color := TEXT, width := 0.0) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if width > 0: l.custom_minimum_size = Vector2(width, 0)
	parent.add_child(l)
	return l

func button(parent: Control, text: String, action: Callable, id := "", size := 18) -> Button:
	var b := Button.new()
	b.text = text
	if id != "": b.name = id
	b.add_theme_font_size_override("font_size", size)
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func column(parent: Control, gap := 10) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", gap)
	parent.add_child(v)
	return v

func row(parent: Control, gap := 10) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", gap)
	parent.add_child(h)
	return h

func code_block(parent: Control, size := 17) -> RichTextLabel:
	var box := PanelContainer.new()
	var dark := StyleBoxFlat.new()
	dark.bg_color = Color("0d1513")
	dark.border_color = Color("3c5a52")
	dark.set_border_width_all(1)
	dark.set_corner_radius_all(5)
	dark.set_content_margin_all(8)
	box.add_theme_stylebox_override("panel", dark)
	parent.add_child(box)
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_OFF
	r.add_theme_font_override("normal_font", mono)
	r.add_theme_font_size_override("normal_font_size", size)
	box.add_child(r)
	return r

func build_tracker(screen: Control) -> void:
	tracker = panel(screen, Vector2(864, 14), Vector2(402, 0))
	tracker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := column(tracker, 6)
	label(v, "THE FIRST CURRENT", 16, GOLD)
	objective = label(v, "", 16, TEXT, 370)
	var p := row(v, 8)
	arrow = PointerArrow.new()
	arrow.custom_minimum_size = Vector2(24, 24)
	p.add_child(arrow)
	pointer_label = label(p, "", 16, GOLD)
	pointer_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	var q := row(v, 8)
	label(q, "Qi", 16, CYAN).autowrap_mode = TextServer.AUTOWRAP_OFF
	qi_bar = ProgressBar.new()
	qi_bar.max_value = 3
	qi_bar.show_percentage = false
	qi_bar.custom_minimum_size = Vector2(190, 14)
	qi_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("1d2b29")
	bg.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = CYAN
	fill.set_corner_radius_all(4)
	qi_bar.add_theme_stylebox_override("background", bg)
	qi_bar.add_theme_stylebox_override("fill", fill)
	q.add_child(qi_bar)
	qi_label = label(q, "", 16, CYAN)
	qi_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	status = label(v, "", 14, Color("b9cbc4"), 370)

func build_dialogue(screen: Control) -> void:
	dialogue = panel(screen, Vector2(140, 492), Vector2(1000, 196))
	var v := column(dialogue, 8)
	speaker = label(v, "", 17, GOLD)
	dialogue_text = label(v, "", 21, TEXT, 960)
	dialogue_buttons = row(v)
	dialogue_buttons.alignment = BoxContainer.ALIGNMENT_END

func build_language(screen: Control) -> void:
	language_panel = panel(screen, Vector2(290, 130), Vector2(700, 0))
	var v := column(language_panel, 12)
	label(v, "MENTOR  ·  Choose your inscription language", 22, GOLD)
	label(v, "I teach all three. Each version is real code for the same two steps: awaken your Qi, then channel it into the basin. Only the language changes.", 18, TEXT, 660)
	for id: String in Lessons.ORDER:
		var lesson: Dictionary = Lessons.LESSONS[id]
		var b := button(v, "%s   ·   %s" % [lesson.name, lesson.files[0]], choose_language.bind(id), "Choose_"+id, 22)
		b.add_theme_font_override("font", mono)
	button(v, "Back to exploration", close_ui, "LanguageBack")

func build_teach(screen: Control) -> void:
	teach = panel(screen, Vector2(200, 110), Vector2(880, 0))
	var v := column(teach, 12)
	teach_head = label(v, "", 17, GOLD)
	teach_title = label(v, "", 26, TEXT)
	teach_text = label(v, "", 20, TEXT, 840)
	teach_example_head = label(v, "", 14, Color("9fb5ad"))
	teach_example = code_block(v, 19)
	var r := row(v)
	button(r, "Skip lesson", finish_teaching, "TeachSkip", 16)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(spacer)
	teach_back = button(r, "Back", func() -> void: show_card(teach_page-1), "TeachBack")
	teach_next = button(r, "Next", next_card, "TeachNext")

func build_code(screen: Control) -> void:
	code = panel(screen, Vector2(14, 14), Vector2(1252, 692))
	var v := column(code, 7)
	var head := row(v)
	code_title = label(head, "", 20, GOLD)
	code_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	code_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	change_language = button(head, "Change language", show_language, "ChangeLanguage", 15)
	button(head, "Back to exploration", back_from_code, "CodeBack", 15)
	code_objective = label(v, "", 17, GOLD, 1210)
	var body := row(v, 14)
	var left := column(body, 5)
	left.custom_minimum_size = Vector2(740, 0)
	label(left, "YOUR PROGRAM  (fixed lines are dimmed; type your statements in the editor)", 13, Color("9fb5ad"))
	header_view = code_block(left, 16)
	editor = CodeEdit.new()
	editor.name = "Editor"
	editor.custom_minimum_size = Vector2(740, 150)
	editor.gutters_draw_line_numbers = true
	editor.indent_size = 4
	editor.indent_use_spaces = true
	editor.auto_brace_completion_enabled = false
	editor.add_theme_font_override("font", mono)
	editor.add_theme_font_size_override("font_size", 18)
	editor.add_theme_color_override("background_color", Color("101c19"))
	editor.add_theme_color_override("font_color", Color("f3ead2"))
	editor.add_theme_color_override("current_line_color", Color("1a2a26"))
	editor.add_theme_color_override("caret_color", GOLD)
	editor.add_theme_color_override("line_number_color", Color("55706a"))
	editor.text_changed.connect(clear_marks)
	left.add_child(editor)
	footer_view = code_block(left, 16)
	var actions := row(left, 8)
	run_button = button(actions, "▶  Run   (Ctrl+Enter)", run_code, "Run")
	button(actions, "Reset code", reset_code, "ResetCode", 15)
	attempts_label = label(actions, "", 15, Color("9fb5ad"))
	attempts_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	continue_button = button(actions, "", continue_after_success, "ResultContinue")
	var out := PanelContainer.new()
	var dark := StyleBoxFlat.new()
	dark.bg_color = Color("05090a")
	dark.border_color = Color("3c5a52")
	dark.set_border_width_all(1)
	dark.set_corner_radius_all(5)
	dark.set_content_margin_all(8)
	out.add_theme_stylebox_override("panel", dark)
	left.add_child(out)
	console = RichTextLabel.new()
	console.name = "Console"
	console.bbcode_enabled = true
	console.scroll_following = true
	console.custom_minimum_size = Vector2(720, 150)
	console.add_theme_font_override("normal_font", mono)
	console.add_theme_font_size_override("normal_font_size", 15)
	out.add_child(console)
	tabs = TabContainer.new()
	tabs.custom_minimum_size = Vector2(460, 560)
	body.add_child(tabs)
	var lesson_scroll := ScrollContainer.new()
	lesson_scroll.name = "Lesson"
	lesson_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(lesson_scroll)
	lesson_box = column(lesson_scroll, 8)
	lesson_box.custom_minimum_size = Vector2(430, 0)
	var ref_scroll := ScrollContainer.new()
	ref_scroll.name = "Commands"
	tabs.add_child(ref_scroll)
	reference_label = RichTextLabel.new()
	reference_label.bbcode_enabled = true
	reference_label.fit_content = true
	reference_label.custom_minimum_size = Vector2(440, 0)
	reference_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	reference_label.add_theme_font_override("normal_font", mono)
	reference_label.add_theme_font_size_override("normal_font_size", 13)
	ref_scroll.add_child(reference_label)
	var hint_scroll := ScrollContainer.new()
	hint_scroll.name = "Hints"
	hint_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(hint_scroll)
	var hint_page := column(hint_scroll, 10)
	label(hint_page, "Hints are optional and cost nothing. After the stronger hint you may also reveal a worked solution.", 15, Color("9fb5ad"), 430)
	hint_button = button(hint_page, "Show a hint", show_hint, "Hint", 16)
	hint_label = label(hint_page, "", 17, Color("ffe3a3"), 430)
	hint_label.add_theme_font_override("font", mono)
	solution_button = button(hint_page, "Show worked solution", show_solution, "ShowSolution", 16)
	solution_note = label(hint_page, "", 14, Color("9fb5ad"), 430)
	solution_view = code_block(hint_page, 16)

func build_recognition(screen: Control) -> void:
	recognition = panel(screen, Vector2(250, 140), Vector2(780, 0))
	var v := column(recognition, 14)
	label(v, "QUEST COMPLETE  ·  The First Current", 26, GOLD)
	recognition_text = label(v, "", 20, TEXT, 740)
	var r := row(v)
	r.alignment = BoxContainer.ALIGNMENT_END
	button(r, "Continue exploring", close_ui, "ContinueExploring")
	button(r, "Reset Demo", reset_demo, "RecognitionReset")

func build_menu(screen: Control) -> void:
	menu = panel(screen, Vector2(450, 200), Vector2(380, 0))
	var v := column(menu, 12)
	label(v, "PROPOSAL DEMO MENU", 22, GOLD)
	button(v, "Resume", close_ui, "Resume")
	button(v, "Reset Demo", reset_demo, "MenuReset")
	button(v, "Exit demo", func() -> void: get_tree().quit(), "Exit")

# ---------------------------------------------------------------- controls and interaction
func open_ui(new_mode: String) -> void:
	if not ui_open:
		saved_third = player.third_person
		ui_open = true
		player.set_physics_process(false)
		player.set_process_unhandled_input(false)
		player.velocity = Vector3.ZERO
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if mode == "code": save_draft()
	hide_panels()
	mode = new_mode

func close_ui() -> void:
	if mode == "code": save_draft()
	hide_panels()
	mode = ""
	if not ui_open: return
	ui_open = false
	player.third_person = saved_third
	player.set_physics_process(true)
	player.set_process_unhandled_input(true)
	player.camera.make_current()
	player.update_camera()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	update_status()

func hide_panels() -> void:
	for p: Control in [dialogue, language_panel, teach, code, recognition, menu]: p.visible = false

func escape() -> void:
	match mode:
		"": show_menu()
		"flow": pass
		"code": back_from_code()
		_: close_ui()

func handle_key(event: InputEventKey) -> bool:
	"""Ctrl+Enter runs the inscription while the editor is open."""
	if mode == "code" and event.ctrl_pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
		run_code()
		return true
	return false

func nearest() -> String:
	"""The single relevant interaction in range: Guide, Mentor, or the basin during stage 2."""
	var best := ""
	var best_d := INF
	var options := {"guide": [guide, TALK_RANGE], "mentor": [mentor, TALK_RANGE]}
	if stage == 2: options["basin"] = [basin, BASIN_RANGE]
	for id: String in options:
		var d: Vector3 = player.global_position-options[id][0].global_position
		var flat := Vector2(d.x, d.z).length()
		if flat < options[id][1] and absf(d.y) < 2.5 and flat < best_d:
			best = id
			best_d = flat
	return best

func interact() -> void:
	match nearest():
		"guide": talk_guide()
		"mentor": talk_mentor()
		"basin": open_basin()

func face(target: Vector3, pitch := -.08) -> void:
	var d := target-player.global_position
	player.yaw = atan2(-d.x, -d.z)
	player.pitch = pitch
	player.update_camera()

func _process(delta: float) -> void:
	update_status()
	var near := nearest() if not ui_open and not world.overview else ""
	prompt.visible = near != ""
	prompt.text = {"guide": "[E]  Talk to the Guide", "mentor": "[E]  Talk to the Mentor", "basin": "[E]  Channel Qi into the basin"}.get(near, "")
	tracker.visible = mode != "code" and mode != "teach" and mode != "language"
	var target := objective_target()
	bob += delta
	marker.visible = target != null
	if target:
		marker.global_position = target.global_position+Vector3(0, (2.75 if target == basin else 3.05)+sin(bob*2.4)*.07, 0)
		marker.rotation.y = bob
		var d: Vector3 = target.global_position-player.global_position
		var fwd := Vector2(-sin(player.yaw), -cos(player.yaw))
		var right := Vector2(cos(player.yaw), -sin(player.yaw))
		var flat := Vector2(d.x, d.z)
		arrow.angle = atan2(flat.dot(right), flat.dot(fwd))
		arrow.queue_redraw()
		pointer_label.text = "%s  ·  %d m" % [target_name(target), roundi(flat.length())]
	else:
		pointer_label.text = "No marker"
	arrow.visible = target != null
	if absf(shown_reserve-reserve) > .001:
		shown_reserve = move_toward(shown_reserve, reserve, delta*(1.5 if reserve > shown_reserve else 2.5))
	qi_bar.value = shown_reserve
	qi_label.text = ("%d / 3" % roundi(shown_reserve)) if stage >= 2 else "dormant"

func target_name(target: Node3D) -> String:
	if target == guide: return "Guide"
	if target == basin: return "Basin"
	return "Mentor"

# ---------------------------------------------------------------- objectives
func objective_target() -> Node3D:
	if stage == 3: return null
	if stage == 2: return basin
	if stage == 1 or met or declined or guide_heard: return mentor
	return guide

func objective_text() -> String:
	if stage == 3: return "Complete. The basin flows, and you have been welcomed into training."
	if stage == 2: return "Channel your Qi into the basin: walk to the basin and press E."
	if stage == 1 and language == "": return "Choose an inscription language with the Mentor."
	if stage == 1: return "Awaken your Qi: write and run the awakening inscription with the Mentor."
	if declined: return "Speak to the Mentor when you are ready."
	if met or guide_heard: return "Find the Mentor beside the basin in the living court."
	return "Talk to the Guide on the forest path, or head straight for the Mentor."

func update_status() -> void:
	objective.text = objective_text()
	var lang_name := "not chosen" if language == "" else str(Lessons.LESSONS[language].name)
	var step: String = ["not started", "1 of 2 (awaken)", "2 of 2 (basin)", "both complete"][stage]
	status.text = "Language: %s   ·   Step: %s   ·   Recognition: %s" % [lang_name, step, "earned" if recognition_earned else "not yet"]

# ---------------------------------------------------------------- dialogue
func say(who: String, text: String, choices: Array) -> void:
	open_ui("dialogue")
	speaker.text = who
	dialogue_text.text = text
	for c in dialogue_buttons.get_children():     # may be the button now emitting
		dialogue_buttons.remove_child(c)
		c.queue_free()
	for choice: Array in choices: button(dialogue_buttons, choice[0], choice[1], choice[2], 19)
	dialogue.visible = true
	(dialogue_buttons.get_child(0) as Button).grab_focus()

func talk_guide() -> void:
	guide.face(player.global_position)
	face(guide.global_position+Vector3(0, 1.5, 0))
	if guide_heard: say("GUIDE", Lessons.GUIDE_AGAIN, [["Thank you", close_ui, "Close"], ["Hear the introduction again", guide_intro.bind(0), "Again"]])
	else: guide_intro(0)

func guide_intro(page: int) -> void:
	guide_page = page
	var pages: Array = Lessons.GUIDE_INTRO
	var last := page == pages.size()-1
	if last: say("GUIDE  ·  %d / %d" % [page+1, pages.size()], pages[page], [["I'll find the Mentor", finish_guide, "Next"]])
	else: say("GUIDE  ·  %d / %d" % [page+1, pages.size()], pages[page], [["Next", guide_intro.bind(page+1), "Next"], ["Skip", finish_guide, "Skip"]])

func finish_guide() -> void:
	guide_heard = true
	close_ui()

func talk_mentor() -> void:
	mentor.face(player.global_position)
	face(mentor.global_position+Vector3(0, 1.5, 0))
	match stage:
		3: say("MENTOR", Lessons.MENTOR_DONE, [["Close", close_ui, "Close"]])
		2: say("MENTOR", Lessons.MENTOR_STAGE2, [["Close", close_ui, "Close"], ["Review the lesson", review_lesson, "Review"]])
		1:
			if language == "": say("MENTOR", Lessons.MENTOR_STAGE1, [["Continue", show_language, "Continue"], ["Not now", close_ui, "NotNow"]])
			else: say("MENTOR", Lessons.MENTOR_STAGE1, [["Continue the inscription", show_code, "Continue"], ["Review the lesson", review_lesson, "Review"], ["Not now", close_ui, "NotNow"]])
		_:
			if not met:
				met = true
				say("MENTOR", Lessons.MENTOR_GREETING, [["Next", offer, "Next"]])
			else: offer()

func offer() -> void:
	say("MENTOR", Lessons.MENTOR_OFFER, [["Accept the task", accept, "Accept"], ["Not yet", decline, "Decline"]])

func accept() -> void:
	stage = 1
	declined = false
	show_language()

func decline() -> void:
	declined = true
	say("MENTOR", Lessons.MENTOR_DECLINE, [["Back to exploring", close_ui, "Close"]])

func show_language() -> void:
	open_ui("language")
	language_panel.visible = true
	(language_panel.find_child("Choose_"+(language if language != "" else "python"), true, false) as Button).grab_focus()

func choose_language(id: String) -> void:
	language = id
	if taught.get(key(), false): show_code()
	else: show_teaching(1, "code")

# ---------------------------------------------------------------- teaching
func key(s := -1) -> String:
	return "%s:%d" % [language, stage if s < 0 else s]

func lesson() -> Dictionary:
	return Lessons.LESSONS[language]

func cards(s: int) -> Array:
	return lesson().cards[s-1]

func show_teaching(s: int, then: String) -> void:
	teach_stage = s
	teach_then = then
	open_ui("teach")
	teach.visible = true
	show_card(0)

func review_lesson() -> void:
	show_teaching(mini(stage, 2), "close")

func show_card(page: int) -> void:
	var all := cards(teach_stage)
	teach_page = clampi(page, 0, all.size()-1)
	var card: Array = all[teach_page]
	teach_head.text = "MENTOR  ·  %s lesson  ·  %s  ·  %d / %d" % [lesson().name, "Awakening" if teach_stage == 1 else "Channelling", teach_page+1, all.size()]
	teach_title.text = card[0]
	teach_text.text = card[1]
	teach_example_head.text = signature_caption() if card.size() > 3 else "EXAMPLE  ·  a short program you can try in this step"
	teach_example.text = colour_code(card[2])
	teach_back.disabled = teach_page == 0
	var last := teach_page == all.size()-1
	var final := "Close lesson"
	if teach_then == "code": final = "Write the inscription  ▶"
	elif teach_then == "basin": final = "Go to the basin  ▶"
	teach_next.text = final if last else "Next"
	teach_next.grab_focus()

func next_card() -> void:
	if teach_page < cards(teach_stage).size()-1: show_card(teach_page+1)
	else: finish_teaching()

func finish_teaching() -> void:
	taught[key(teach_stage)] = true
	if teach_then == "code": show_code()
	else: close_ui()

# ---------------------------------------------------------------- code editor
func esc(s: String) -> String:
	return s.replace("[", "\u0001").replace("]", "[rb]").replace("\u0001", "[lb]")

func colour_code(text: String) -> String:
	var out := PackedStringArray()
	for line: String in text.split("\n"):
		var c := line.find("#") if language == "python" else line.find("//")
		var cb := line.find("/*") if language != "python" else -1
		if cb >= 0 and (c < 0 or cb < c): c = cb
		if c >= 0: out.append(esc(line.substr(0, c))+"[color=#8fae9a]"+esc(line.substr(c))+"[/color]")
		else: out.append(esc(line))
	return "\n".join(out)

func scaffold(lines: Array, first: int) -> String:
	var out := PackedStringArray()
	for i in lines.size(): out.append("[color=#55706a]%2d[/color]  [color=#8c9b96]%s[/color]" % [first+i, esc(lines[i])])
	return "\n".join(out)

func highlighter() -> CodeHighlighter:
	var h := CodeHighlighter.new()
	h.number_color = Color("f2b880")
	h.symbol_color = Color("cfe3db")
	h.function_color = Color("8fd3ff")
	h.member_variable_color = Color("cfe3db")
	for kw: String in lesson().keywords: h.add_keyword_color(kw, Color("e59bd6"))
	var comment := Color("8fae9a")
	if language == "python": h.add_color_region("#", "", comment, true)
	else:
		h.add_color_region("//", "", comment, true)
		h.add_color_region("/*", "*/", comment)
	h.add_color_region("\"", "\"", Color("e6c07b"))
	return h

func open_basin() -> void:
	face(basin.global_position+Vector3(0, .6, 0), -.15)
	show_code()

func show_code() -> void:
	open_ui("code")
	code.visible = true
	var l := lesson()
	var s := stage
	code_title.text = "Step %d of 2  ·  %s  ·  %s  ·  %s" % [s, "Awaken your Qi" if s == 1 else "Channel Qi into the basin", l.name, l.files[s-1]]
	code_objective.text = "OBJECTIVE  "+Lessons.OBJECTIVE[s]
	change_language.visible = s == 1
	editor.syntax_highlighter = highlighter()
	editor.text = drafts.get(key(), l.starter[s-1])
	var header: Array = l.header[s-1]
	var footer: Array = l.footer[s-1]
	header_view.text = scaffold(header, 1)
	header_view.get_parent().visible = header.size() > 0
	footer_view.text = scaffold(footer, header.size()+editor.get_line_count()+1)
	footer_view.get_parent().visible = footer.size() > 0
	editor.set_caret_line(editor.get_line_count()-1)
	editor.set_caret_column(editor.get_line(editor.get_line_count()-1).length())
	clear_marks()
	console.text = consoles.get(key(), "[color=#8fa39b]Type your statements, then press Run (or Ctrl+Enter).\n%s[/color]" % (Lessons.INTERPRETER_NOTE % [l.name, l.name]))
	# Lesson tab: this step's cards; during step 2 the awakening cards follow.
	for c in lesson_box.get_children():
		lesson_box.remove_child(c)
		c.queue_free()
	for g in ([1] if s == 1 else [2, 1]):
		if g == 1 and s == 2: label(lesson_box, "FROM THE AWAKENING LESSON", 13, Color("9fb5ad"))
		for card: Array in cards(g):
			label(lesson_box, card[0], 17, GOLD, 420)
			label(lesson_box, card[1], 15, TEXT, 420)
			if card.size() > 3: label(lesson_box, signature_caption(), 13, Color("9fb5ad"), 420)
			var example := code_block(lesson_box, 15)
			example.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART     # wrap here rather than widen the panel
			example.custom_minimum_size = Vector2(400, 0)
			example.text = colour_code(card[2])
	reference_label.text = "[color=#cfe3db]%s[/color]" % esc(l.reference)
	refresh_code()
	editor.grab_focus()

func refresh_code() -> void:
	var n: int = attempts.get(key(), 0)
	attempts_label.text = ("Runs: %d   ·   retries are free" % n) if n > 0 else ""
	run_button.disabled = stage_solved
	continue_button.visible = stage_solved
	continue_button.text = "Feel your Qi awaken  ▶" if stage == 1 else "Channel into the basin  ▶"
	var shown: int = hints.get(key(), 0)
	var h: Array = lesson().hints[stage-1]
	hint_label.text = "\n\n".join(PackedStringArray(h.slice(0, shown)))
	hint_button.text = "Show a hint" if shown == 0 else ("Show a stronger hint" if shown < h.size() else "Both hints shown")
	hint_button.disabled = shown >= h.size()
	var revealed: bool = solutions.get(key(), false)
	solution_button.disabled = revealed or shown < h.size()          # offered after the stronger hint
	solution_button.text = "Worked solution shown below" if revealed else "Show worked solution"
	var note := "WORKED SOLUTION  ·  %s  ·  step %d\nA complete answer to read. Nothing is typed, run or changed for you: type it in the editor yourself, then press Run." % [lesson().name, stage]
	if language != "python": note += " These are the statements inside main; the rest of the program is already written."
	solution_note.text = note if revealed else ""
	solution_note.visible = revealed
	solution_view.get_parent().visible = revealed
	solution_view.text = colour_code(lesson().solution[stage-1]) if revealed else ""
	editor.editable = not stage_solved

func save_draft() -> void:
	if language != "" and stage in [1, 2]: drafts[key()] = editor.text

func clear_marks() -> void:
	for i in editor.get_line_count(): editor.set_line_background_color(i, Color(0, 0, 0, 0))

func reset_code() -> void:
	if stage_solved: return
	editor.text = lesson().starter[stage-1]
	save_draft()
	editor.grab_focus()

func show_hint() -> void:
	hints[key()] = mini(hints.get(key(), 0)+1, 2)
	refresh_code()

func show_solution() -> void:
	"""Reveals the complete answer for this language and step. Display only: the editor, console,
	run count, Qi and basin stay exactly as they were."""
	solutions[key()] = true
	refresh_code()

func signature_caption() -> String:
	return "REFERENCE  ·  a command signature, not a complete program: amount is a placeholder for your own value"

func run_code() -> void:
	if mode != "code" or stage_solved or not (stage in [1, 2]): return
	save_draft()
	attempts[key()] = attempts.get(key(), 0)+1
	var l := lesson()
	var header: Array = l.header[stage-1]
	var r: Dictionary = runner.run(language, stage, editor.text, l.files[stage-1], header.size(), reserve)
	clear_marks()
	var lines := PackedStringArray()
	var grey := "[color=#8fa39b]%s[/color]"
	# Runner status: the sect's own learning interpreter ran this, not python, gcc or javac.
	lines.append(grey % esc("[sect runner] %s %s  ·  learning interpreter, %s subset" % ["running" if language == "python" else "checking", l.files[stage-1], l.name]))
	if language != "python" and r.phase != "compile": lines.append(grey % "[sect runner] check passed; running main()")
	for o: Array in r.output:
		var colour: String = {"out": "#f3ead2", "sect": "#7fe6ff", "note": "#8fa39b"}[o[0]]
		lines.append("[color=%s]%s[/color]" % [colour, esc(o[1])])
	if not r.ok:
		var f: Dictionary = r.fail
		var file_line: int = f.line+header.size()
		var on_line: bool = f.line > 0 and f.line-1 < editor.get_line_count()
		var source := editor.get_line(f.line-1).strip_edges() if on_line else ""
		var language_error: bool = f.category in ["language", "game"]
		lines.append_array(error_lines(f, r.phase, file_line, source))
		if on_line: editor.set_line_background_color(f.line-1, Color(.55, .12, .1, .55) if language_error else Color(.55, .38, .08, .55))
		if r.effects.awaken > 0 or r.effects.channel > 0: lines.append(grey % "[sect runner] the program did not finish, so its Qi effects were not applied.")
		var note: String = Lessons.NOTES.get(f.kind, "Read the message above, then compare your line with the Lesson tab.")
		if f.kind == "uninitialized" and language == "c": note = Lessons.NOTE_C_UNINITIALIZED+" "+note
		lines.append("[color=#ffd27a]Mentor: %s%s[/color]" % [esc(note), ("  (Your line %d.)" % f.line) if language_error and on_line else ""])
		if stage == 1: basin.sputter()
	elif (stage == 1 and r.effects.awaken > 0) or (stage == 2 and r.effects.channel > 0):
		stage_solved = true
		lines.append("[color=#6fd19a]Ran without errors, top to bottom.[/color]")
		lines.append("[color=#ffd27a]Mentor: %s[/color]" % ("Good. qi held its value before the awakening command used it." if stage == 1 else "Good. You read your reserve, then passed exactly what you hold to the basin."))
	else:
		lines.append("[color=#6fd19a]Ran without errors.[/color]")
		lines.append("[color=#ffd27a]Mentor: The program ran, but %s[/color]" % ("nothing called the awakening command yet." if stage == 1 else "no Qi was channelled into the basin yet."))
	consoles[key()] = "\n".join(lines)
	console.text = consoles[key()]
	refresh_code()
	if stage_solved: continue_button.grab_focus()
	else: editor.grab_focus()

func error_lines(f: Dictionary, phase: String, file_line: int, source: String) -> PackedStringArray:
	var red := "[color=#ff8a7a]%s[/color]"
	var out := PackedStringArray()
	if f.category in ["exercise", "unsupported", "limit"]:
		# Not a language error: a lesson rule, a feature outside the subset, or a size limit.
		var amber := "[color=#ffb86b]%s[/color]"
		if source != "": out.append(amber % esc("Your line %d:  %s" % [f.line, source]))
		out.append(amber % esc(f.message))
		return out
	var name: String = lesson().files[stage-1]
	match language:
		"python":
			if phase == "compile":
				out.append(red % esc("  File \"%s\", line %d" % [name, file_line]))
			else:
				out.append(red % "Traceback (most recent call last):")
				out.append(red % esc("  File \"%s\", line %d, in <module>" % [name, file_line]))
			out.append(red % esc("    "+source))
			out.append(red % esc(f.message))
		"c":
			if phase == "compile": out.append(red % esc("%s:%d: %s" % [name, file_line, f.message]))
			else: out.append(red % esc(f.message))
		_:
			if phase == "compile":
				out.append(red % esc("%s:%d: %s" % [name, file_line, f.message]))
				out.append(red % esc("        "+source))
				out.append(red % "1 error")
			else:
				out.append(red % esc(f.message))
				out.append(red % esc("        at %s.main(%s:%d)" % [name.get_basename(), name, file_line]))
	return out

func back_from_code() -> void:
	if stage_solved: continue_after_success()
	else: close_ui()

# ---------------------------------------------------------------- results
func continue_after_success() -> void:
	"""Plays the solved stage's world result: the awakening, or channelling into the basin."""
	if not stage_solved: return
	save_draft()
	hide_panels()
	mode = ""                 # leave the editor before the stage advances, so its text stays with this stage
	stage_solved = false
	var token := run
	if stage == 1:
		stage = 2
		reserve = Runner.FIRST_RESERVE
		open_ui("flow")
		player.pitch = -.3
		player.update_camera()
		world.awaken_effect()
		update_status()
		await get_tree().create_timer(2.6).timeout
		if token != run: return
		face(mentor.global_position+Vector3(0, 1.5, 0))
		say("MENTOR", Lessons.MENTOR_STAGE2_INTRO, [["Show me", show_teaching.bind(2, "basin"), "ShowMe"]])
	else:
		stage = 3
		reserve = 0
		open_ui("flow")
		face(basin.global_position+Vector3(0, .8, 0), -.18)
		world.channel_effect(basin.global_position+Vector3(0, 1.0, 0))
		await get_tree().create_timer(.9).timeout
		if token != run: return
		basin.activate()
		update_status()
		await get_tree().create_timer(2.6).timeout
		if token != run: return
		show_recognition()
		reserve = Runner.FIRST_RESERVE     # the Mentor replenishes it after practice, as the recognition text says

func show_recognition() -> void:
	if recognition_earned:
		close_ui()
		return
	recognition_earned = true
	recognitions_granted += 1
	open_ui("recognition")
	var a1: int = attempts.get(key(1), 0)
	var a2: int = attempts.get(key(2), 0)
	recognition_text.text = "Your Qi is awake, and the public basin flows for every traveller.\n\nThe Mentor:  %s\n\nRecognition earned:  Welcomed into training  ·  Split-Cloud Sect\nLanguage:  %s   ·   Awakening runs: %d   ·   Basin runs: %d" % [Lessons.RECOGNITION, lesson().name, a1, a2]
	recognition.visible = true
	(recognition.find_child("ContinueExploring", true, false) as Button).grab_focus()
	update_status()

func show_menu() -> void:
	if world.overview: world.set_walk()
	open_ui("menu")
	menu.visible = true
	(menu.find_child("Resume", true, false) as Button).grab_focus()

func reset_demo() -> void:
	"""Spawn, Guide introduction, objectives and marker, teaching, awakening, Qi, basin, drafts, recognition."""
	run += 1
	mode = ""
	guide_heard = false
	guide_page = 0
	met = false
	declined = false
	language = ""
	stage = 0
	stage_solved = false
	reserve = 0
	shown_reserve = 0
	recognition_earned = false
	recognitions_granted = 0
	for d: Dictionary in [drafts, consoles, hints, solutions, attempts, taught]: d.clear()
	basin.reset()
	world.clear_aura()
	hide_panels()
	if ui_open:
		ui_open = false
		player.set_physics_process(true)
		player.set_process_unhandled_input(true)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player.third_person = true
	world.get_node("Buildings/sect_gate").set_open_immediate(true)
	world.reset_start()
	update_status()

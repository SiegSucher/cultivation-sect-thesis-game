extends CanvasLayer
## "The First Current": the Guide's introduction, the Mentor's offer and syntax teaching, and four
## typed-code stages run by the sect's learning interpreter (code_runner.gd, a custom interpreter
## for a small subset of Python, C and Java). Stage 1 awakens the apprentice's Qi
## (reserve 3); stage 2 restores the basin; stages 3 and 4 release the Silent Crossing and restore the Threefold Ward. While any
## panel is open, movement and camera look are paused and the mouse is released; closing restores
## them. Reset Demo clears everything.
## One shared Theme styles every panel. The inscription terminal is a movable, resizable window
## (terminal_window.gd) with adjustable code / output / reference panes; while it is open a demo
## camera keeps the step's world result in view beside it.
const Lessons := preload("res://proposal_demo_living_sect/lessons.gd")
const Runner := preload("res://proposal_demo_living_sect/code_runner.gd")
const TerminalWindow := preload("res://proposal_demo_living_sect/terminal_window.gd")
const TALK_RANGE := 3.5
const BASIN_RANGE := 3.4
const GOLD := Color("8daac7")
const TEXT := Color("e3e5e8")
const CYAN := Color("9ab9d1")
const MUTED := Color("a6acb5")
const INK := Color("23262c")
const JADE := Color("8daac7")
const BRONZE := Color("444a53")
const TABS_WIDTH := 340                 # default reference-pane width
const CONSOLE_HEIGHT := 220             # default output-pane height

class PointerArrow extends Control:
	## Small arrow pointing toward the objective, relative to the view direction.
	var angle := 0.0
	func _draw() -> void:
		var c := size/2
		var pts := PackedVector2Array()
		for p in [Vector2(0, -10), Vector2(8, 8), Vector2(0, 3), Vector2(-8, 8)]: pts.append(c+p.rotated(angle))
		draw_colored_polygon(pts, Color("8daac7"))

var world: Node3D
var player: CharacterBody3D
var guide: Node3D
var mentor: Node3D
var basin: Node3D
var sound: Node                # sound.gd, set by the walkthrough
var marker: MeshInstance3D
var runner := Runner.new()

# Quest state for one run. reset_demo() clears all of it.
var guide_heard := false       # introduction finished or skipped
var guide_page := 0
var met := false
var declined := false
var language := ""
var stage := 0                 # 0 not accepted, 1 awakening, 2 basin, 3 crossing, 4 ward, 5 complete
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

var ui_theme: Theme
var mono: SystemFont
var heading: SystemFont
var code_font_size := 20
var ui_scale := 1.0
var reference_button: Button
var options_button: MenuButton
var reference_manual := false
var code_cam: Camera3D         # coding view; the player's camera is never moved by it
var code_cam_basis := Basis()
var code_cam_shift := 0.0
var text_tween: Tween
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
var code: PanelContainer       # the terminal window (terminal_window.gd)
var code_title: Label
var code_objective: Label
var minimize_button: Button
var split_h: HSplitContainer
var split_v: VSplitContainer
var header_view: RichTextLabel
var editor: CodeEdit
var footer_view: RichTextLabel
var run_button: Button
var attempts_label: Label
var console: RichTextLabel
var console_box: PanelContainer
var output_pane: VBoxContainer
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
var ambience_slider: HSlider
var effects_slider: HSlider
var mute_toggle: CheckButton

# ---------------------------------------------------------------- construction
func _ready() -> void:
	layer = 10
	mono = SystemFont.new()
	mono.font_names = PackedStringArray(["Consolas", "Cascadia Mono", "Courier New", "monospace"])
	heading = SystemFont.new()
	heading.font_names = PackedStringArray(["Segoe UI", "Arial", "sans-serif"])
	heading.font_weight = 600
	var screen := Control.new()
	screen.name = "Screen"
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_theme = make_theme()
	screen.theme = ui_theme
	add_child(screen)
	build_tracker(screen)
	prompt = label(screen, "", 22)
	prompt.name = "Prompt"
	prompt.theme_type_variation = "PromptLabel"
	prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.offset_left = -220
	prompt.offset_right = 220
	prompt.offset_top = -96
	prompt.offset_bottom = -52
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	build_dialogue(screen)
	build_language(screen)
	build_teach(screen)
	build_code(screen)
	build_recognition(screen)
	build_menu(screen)
	scroll_panel_contents()
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
	code_cam = Camera3D.new()
	code_cam.name = "CodingViewCamera"
	code_cam.fov = 75
	code_cam.near = .05
	code_cam.far = 600
	world.add_child(code_cam)
	hide_panels()
	get_viewport().size_changed.connect(responsive_layout)
	initialize_layout.call_deferred()
	update_status()

func make_theme() -> Theme:
	"""One quiet charcoal theme shared by every demo panel."""
	var t := Theme.new()
	t.default_font = heading
	t.default_font_size = 18
	t.set_stylebox("panel", "PanelContainer", box(INK, Color("444a53"), 1, 3, 12))
	for kind in ["TerminalPanel", "TitleBar", "CodeSheet", "ConsoleSheet"]:
		t.set_type_variation(kind, "PanelContainer")
		t.set_stylebox("panel", kind, box(Color("191c21") if kind in ["CodeSheet", "ConsoleSheet"] else INK, Color("3d424b"), 1, 3, 10 if kind == "TerminalPanel" else 6))
	for kind in ["Button", "AccentButton", "TitleButton", "MenuButton"]:
		if kind in ["AccentButton", "TitleButton"]: t.set_type_variation(kind, "Button")
		for state in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
			var bg := Color("30343c")
			if state in ["hover", "hover_pressed"]: bg = Color("3b414b")
			if state == "pressed": bg = Color("252a32")
			if kind == "TitleButton": bg = Color(0, 0, 0, 0) if state == "normal" else bg
			if kind == "AccentButton": bg = Color("425a70") if state == "normal" else Color("506b84")
			if state == "disabled": bg = Color("292c32")
			var sb := box(bg, Color("484e58"), 1 if kind != "TitleButton" else 0, 3, 5)
			sb.content_margin_left = 10
			sb.content_margin_right = 10
			t.set_stylebox(state, kind, sb)
		for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]: t.set_color(c, kind, TEXT)
		t.set_color("font_disabled_color", kind, Color("7c828c"))
		t.set_stylebox("focus", kind, box(Color.TRANSPARENT, JADE, 1, 3, 0, false))
	t.set_color("font_color", "Label", TEXT)
	t.set_type_variation("HeadingLabel", "Label")
	t.set_font("font", "HeadingLabel", heading)
	t.set_color("font_color", "HeadingLabel", TEXT)
	t.set_type_variation("PromptLabel", "Label")
	t.set_stylebox("normal", "PromptLabel", box(INK, Color("444a53"), 1, 3, 8))
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_font_size("normal_font_size", "RichTextLabel", 18)
	t.set_stylebox("panel", "TabContainer", box(Color("202329"), Color("3d424b"), 1, 3, 8))
	for state in ["tab_selected", "tab_unselected", "tab_hovered"]:
		var sb := box(Color("30353e") if state == "tab_selected" else Color("24282f"), Color.TRANSPARENT, 0, 2, 6)
		if state == "tab_selected":
			sb.border_width_bottom = 1
			sb.border_color = JADE
		t.set_stylebox(state, "TabContainer", sb)
	t.set_stylebox("tab_focus", "TabContainer", box(Color.TRANSPARENT, JADE, 1, 2, 0, false))
	t.set_color("font_selected_color", "TabContainer", TEXT)
	t.set_color("font_unselected_color", "TabContainer", MUTED)
	t.set_font_size("font_size", "TabContainer", 18)
	for bar in ["VScrollBar", "HScrollBar"]:
		for style in ["scroll", "grabber", "grabber_highlight", "grabber_pressed"]:
			t.set_stylebox(style, bar, box(Color("252930") if style == "scroll" else Color("626b78"), Color.TRANSPARENT, 0, 3, 6))
	for split in ["HSplitContainer", "VSplitContainer", "SplitContainer"]:
		t.set_constant("separation", split, 12)
		t.set_constant("minimum_grab_thickness", split, 14)
		t.set_constant("autohide", split, 0)
		t.set_stylebox("split_bar_background", split, box(Color("323740"), Color.TRANSPARENT, 0, 2, 0))
	t.set_stylebox("normal", "CodeEdit", box(Color("191c21"), Color("3d424b"), 1, 3, 6))
	t.set_stylebox("focus", "CodeEdit", box(Color.TRANSPARENT, JADE, 1, 3, 0, false))
	var colors := {"background_color": "191c21", "font_color": "e3e5e8", "current_line_color": "252a32", "caret_color": "b1c5d9", "line_number_color": "8b929f", "selection_color": "3d5065", "word_highlighted_color": "303b49", "brace_mismatch_color": "e9a09b", "font_placeholder_color": "949ba6"}
	for c in colors: t.set_color(c, "CodeEdit", Color(colors[c]))
	t.set_stylebox("background", "ProgressBar", box(Color("353a43"), Color.TRANSPARENT, 0, 2, 0))
	t.set_stylebox("fill", "ProgressBar", box(JADE, Color.TRANSPARENT, 0, 2, 0))
	t.set_stylebox("panel", "TooltipPanel", box(INK, Color("555d69"), 1, 3, 8))
	t.set_color("font_color", "TooltipLabel", TEXT)
	t.set_stylebox("slider", "HSlider", box(Color("383e48"), Color.TRANSPARENT, 0, 2, 3))
	for style in ["grabber_area", "grabber_area_highlight"]: t.set_stylebox(style, "HSlider", box(JADE, Color.TRANSPARENT, 0, 2, 3))
	t.set_stylebox("panel", "PopupMenu", box(INK, Color("555d69"), 1, 3, 8))
	t.set_color("font_color", "PopupMenu", TEXT)
	return t

func box(bg: Color, border: Color, width: int, radius: int, margin: int, filled := true) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.draw_center = filled
	b.border_color = border
	b.set_border_width_all(width)
	b.set_corner_radius_all(radius)
	b.set_content_margin_all(margin)
	return b

func panel(parent: Control, at: Vector2, size: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	p.position = at
	p.size = size
	parent.add_child(p)
	return p

func label(parent: Control, text: String, size := 19, color := TEXT, width := 0.0) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", maxi(18, size))
	if color != TEXT: l.add_theme_color_override("font_color", color)
	# Width comes from the container; long text wraps without imposing a screen-wide minimum.
	parent.add_child(l)
	return l

func title(parent: Control, text: String, size := 20) -> Label:
	var l := label(parent, text, size)
	l.theme_type_variation = "HeadingLabel"
	return l

func caption(parent: Control, text: String) -> Label:
	var l := label(parent, text, 13, MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.clip_text = true
	return l

func button(parent: Control, text: String, action: Callable, id := "", size := 18, look := "") -> Button:
	var b := Button.new()
	b.text = text
	if id != "": b.name = id
	if look != "": b.theme_type_variation = look
	b.add_theme_font_size_override("font_size", size)
	b.pressed.connect(action)
	b.pressed.connect(sfx.bind("click"))
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

func spacer(parent: Control) -> void:
	var s := Control.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(s)

func code_block(parent: Control, size := 17) -> RichTextLabel:
	var box_panel := PanelContainer.new()
	box_panel.theme_type_variation = "CodeSheet"
	parent.add_child(box_panel)
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_OFF
	r.add_theme_font_override("normal_font", mono)
	r.add_theme_font_size_override("normal_font_size", size)
	box_panel.add_child(r)
	return r

func build_tracker(screen: Control) -> void:
	tracker = panel(screen, Vector2(864, 14), Vector2(402, 0))
	tracker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := column(tracker, 4)
	title(v, "THE FIRST CURRENT", 17)
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
	qi_bar.custom_minimum_size = Vector2(140, 8)
	qi_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	q.add_child(qi_bar)
	qi_label = label(q, "", 16, CYAN)
	qi_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	status = label(v, "", 14, Color("b9cbc4"), 370)

func build_dialogue(screen: Control) -> void:
	dialogue = panel(screen, Vector2(140, 486), Vector2(1000, 206))
	var v := column(dialogue, 8)
	speaker = title(v, "", 18)
	dialogue_text = label(v, "", 21, TEXT, 960)
	dialogue_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_buttons = row(v)
	dialogue_buttons.alignment = BoxContainer.ALIGNMENT_END

func build_language(screen: Control) -> void:
	language_panel = panel(screen, Vector2(290, 130), Vector2(700, 0))
	var v := column(language_panel, 12)
	title(v, "MENTOR  ·  Choose your inscription language", 22)
	label(v, "I teach all three. Each version uses the same four steps: awaken your Qi, restore the basin, release the Silent Crossing, then restore the Threefold Ward. Only the language changes.", 18, TEXT, 660)
	for id: String in Lessons.ORDER:
		var lesson: Dictionary = Lessons.LESSONS[id]
		var b := button(v, "%s   ·   %s" % [lesson.name, lesson.files[0]], choose_language.bind(id), "Choose_"+id, 22)
		b.add_theme_font_override("font", mono)
	button(v, "Back to exploration", close_ui, "LanguageBack")

func build_teach(screen: Control) -> void:
	teach = panel(screen, Vector2(200, 100), Vector2(880, 0))
	var v := column(teach, 12)
	teach_head = label(v, "", 16, GOLD)
	teach_title = title(v, "", 27)
	teach_title.add_theme_color_override("font_color", TEXT)
	teach_text = label(v, "", 20, TEXT, 840)
	teach_example_head = label(v, "", 14, MUTED)
	teach_example = code_block(v, 19)
	var r := row(v)
	button(r, "Skip lesson", finish_teaching, "TeachSkip", 16)
	spacer(r)
	teach_back = button(r, "Back", func() -> void: show_card(teach_page-1), "TeachBack")
	teach_next = button(r, "Next", next_card, "TeachNext", 18, "AccentButton")

func build_code(screen: Control) -> void:
	"""The inscription terminal: title bar (drag, Restore layout, minimize, close), a toolbar that
	stays reachable at the minimum size, then code | reference panes and the output pane."""
	code = PanelContainer.new()
	code.name = "Terminal"
	code.theme_type_variation = "TerminalPanel"
	code.set_script(TerminalWindow)
	var v := column(code, 6)
	var bar := PanelContainer.new()
	bar.name = "TitleBar"
	bar.theme_type_variation = "TitleBar"
	bar.tooltip_text = "Drag to move. Double-click to minimize or restore."
	v.add_child(bar)
	var head := row(bar, 4)
	code_title = title(head, "", 17)
	code_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	code_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	code_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	code_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	code_title.clip_text = true
	code_title.custom_minimum_size = Vector2(120, 0)
	button(head, "Layout", restore_terminal_layout, "RestoreLayout", 14, "TitleButton").tooltip_text = "Put the terminal and its panes back in their default places."
	minimize_button = button(head, "Minimize", toggle_minimize, "Minimize", 14, "TitleButton")
	minimize_button.tooltip_text = "Minimize to the title bar to see the world (click again to restore)."
	button(head, "Close", back_from_code, "CodeBack", 14, "TitleButton").tooltip_text = "Back to exploration (Esc). Your draft is kept."
	var body := column(v, 6)
	body.name = "Body"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	code.title_bar = bar
	code.body = body
	var tools := row(body, 8)
	run_button = button(tools, "Run", run_code, "Run", 18, "AccentButton")
	run_button.tooltip_text = "Run the inscription (Ctrl+Enter)."
	continue_button = button(tools, "", continue_after_success, "ResultContinue", 18, "AccentButton")
	reference_button = button(tools, "Reference", toggle_reference, "ReferenceToggle", 16)
	reference_button.tooltip_text = "Show or hide Lesson / Commands / Hints."
	attempts_label = caption(tools, "")
	attempts_label.add_theme_font_size_override("font_size", 14)
	attempts_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attempts_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button(tools, "A−", font_step.bind(-2), "FontSmaller", 15).tooltip_text = "Smaller code text"
	button(tools, "A+", font_step.bind(2), "FontLarger", 15).tooltip_text = "Larger code text"
	options_button = MenuButton.new()
	options_button.name = "TerminalOptions"
	options_button.text = "Options"
	options_button.add_theme_font_size_override("font_size", 16)
	tools.add_child(options_button)
	var pop := options_button.get_popup()
	pop.add_item("Reset code", 0)
	pop.add_item("Change language (step 1)", 1)
	pop.add_separator("Interface size")
	for i in 4: pop.add_radio_check_item(["90%", "100%", "110%", "125%"][i], 10+i)
	pop.add_separator()
	pop.add_item("Toggle fullscreen", 20)
	pop.id_pressed.connect(terminal_option)
	pop.about_to_popup.connect(func() -> void:
		pop.set_item_disabled(pop.get_item_index(1), stage != 1)
		for i in 4: pop.set_item_checked(pop.get_item_index(10+i), is_equal_approx(ui_scale, [.9, 1.0, 1.1, 1.25][i])))
	code_objective = label(body, "", 18, TEXT)
	split_h = HSplitContainer.new()
	split_h.name = "CodeAndReference"
	split_h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(split_h)
	split_v = VSplitContainer.new()
	split_v.name = "ProgramAndOutput"
	split_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split_h.add_child(split_v)
	var program := column(split_v, 4)
	program.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caption(program, "YOUR PROGRAM  ·  fixed lines are dimmed; type your statements between them")
	header_view = code_block(program, 16)
	header_view.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART     # wraps only when the pane is narrow
	editor = CodeEdit.new()
	editor.name = "Editor"
	editor.custom_minimum_size = Vector2(240, 70)
	editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor.gutters_draw_line_numbers = true
	editor.indent_size = 4
	editor.indent_use_spaces = true
	editor.indent_automatic = true
	editor.auto_brace_completion_enabled = true            # pairs ( ) and " " as you type; never writes code
	editor.auto_brace_completion_highlight_matching = true
	editor.highlight_current_line = true
	editor.caret_blink = true
	editor.add_theme_font_override("font", mono)
	editor.add_theme_font_size_override("font_size", code_font_size)
	editor.text_changed.connect(clear_marks)
	program.add_child(editor)
	footer_view = code_block(program, 16)
	footer_view.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var output := column(split_v, 4)
	output_pane = output
	caption(output, "OUTPUT  ·  the sect's learning interpreter")
	console_box = PanelContainer.new()
	console_box.theme_type_variation = "ConsoleSheet"
	console_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	output.add_child(console_box)
	console = RichTextLabel.new()
	console.name = "Console"
	console.bbcode_enabled = true
	console.scroll_following = true
	console.selection_enabled = true
	console.custom_minimum_size = Vector2(200, 56)
	console.add_theme_font_override("normal_font", mono)
	console.add_theme_font_size_override("normal_font_size", code_font_size-2)
	console_box.add_child(console)
	tabs = TabContainer.new()
	tabs.custom_minimum_size = Vector2(220, 120)
	split_h.add_child(tabs)
	var lesson_scroll := ScrollContainer.new()
	lesson_scroll.name = "Lesson"
	lesson_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(lesson_scroll)
	lesson_box = column(lesson_scroll, 8)
	lesson_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ref_scroll := ScrollContainer.new()
	ref_scroll.name = "Commands"
	tabs.add_child(ref_scroll)
	reference_label = RichTextLabel.new()
	reference_label.bbcode_enabled = true
	reference_label.fit_content = true
	reference_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	reference_label.add_theme_font_override("normal_font", mono)
	reference_label.add_theme_font_size_override("normal_font_size", 18)
	ref_scroll.add_child(reference_label)
	var hint_scroll := ScrollContainer.new()
	hint_scroll.name = "Hints"
	hint_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# Reserve the scrollbar width so revealing wrapped text cannot oscillate the
	# reference pane between two widths at the scrolling threshold.
	hint_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	tabs.add_child(hint_scroll)
	var hint_page := column(hint_scroll, 10)
	hint_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label(hint_page, "Hints are optional and cost nothing. After the stronger hint you may also reveal a worked solution.", 15, MUTED)
	hint_button = button(hint_page, "Show a hint", show_hint, "Hint", 16)
	hint_label = label(hint_page, "", 17, TEXT)
	hint_label.add_theme_font_override("font", mono)
	solution_button = button(hint_page, "Show worked solution", show_solution, "ShowSolution", 16)
	solution_note = label(hint_page, "", 14, MUTED)
	solution_view = code_block(hint_page, 16)
	solution_view.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Bound this small answer viewport instead of recursively resizing rich text
	# inside the nested tab/scroll/panel containers. Long wrapped answers can scroll.
	solution_view.fit_content = false
	solution_view.scroll_active = true
	solution_view.custom_minimum_size.y = 120
	screen.add_child(code)
	code.layout_changed.connect(terminal_layout_changed)
	restore_terminal_layout()

func build_recognition(screen: Control) -> void:
	recognition = panel(screen, Vector2(250, 130), Vector2(780, 0))
	var v := column(recognition, 14)
	title(v, "QUEST COMPLETE  ·  The First Current", 28)
	recognition_text = label(v, "", 20, TEXT, 740)
	var r := row(v)
	r.alignment = BoxContainer.ALIGNMENT_END
	button(r, "Continue exploring", close_ui, "ContinueExploring", 18, "AccentButton")
	button(r, "Reset Demo", reset_demo, "RecognitionReset")

func build_menu(screen: Control) -> void:
	menu = panel(screen, Vector2(430, 150), Vector2(420, 0))
	var v := column(menu, 12)
	title(v, "PROPOSAL DEMO MENU", 22)
	button(v, "Resume", close_ui, "Resume", 18, "AccentButton")
	button(v, "Reset Demo", reset_demo, "MenuReset")
	button(v, "Exit demo", func() -> void: get_tree().quit(), "Exit")
	label(v, "DISPLAY", 14, MUTED)
	var sizes := row(v, 6)
	for value in [.9, 1.0, 1.1, 1.25]: button(sizes, "%d%%" % roundi(value*100), set_ui_scale.bind(value), "Scale%d" % roundi(value*100), 16)
	button(v, "Toggle fullscreen", toggle_fullscreen, "Fullscreen", 16)
	label(v, "SOUND", 14, MUTED)
	ambience_slider = volume_row(v, "Ambience", "AmbienceVolume", .5)
	effects_slider = volume_row(v, "Effects", "EffectsVolume", .8)
	mute_toggle = CheckButton.new()
	mute_toggle.name = "MuteSound"
	mute_toggle.text = "Mute all sound"
	mute_toggle.add_theme_font_size_override("font_size", 17)
	mute_toggle.toggled.connect(func(on: bool) -> void: if sound: sound.set_muted(on))
	v.add_child(mute_toggle)

func volume_row(parent: Control, text: String, id: String, value: float) -> HSlider:
	var r := row(parent, 12)
	label(r, text, 17, TEXT, 100).autowrap_mode = TextServer.AUTOWRAP_OFF
	var s := HSlider.new()
	s.name = id
	s.max_value = 1.0
	s.step = .05
	s.value = value
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.custom_minimum_size = Vector2(180, 22)
	s.value_changed.connect(func(x: float) -> void: if sound: sound.set_volume(text, x))
	r.add_child(s)
	return s

# ---------------------------------------------------------------- terminal window
func restore_terminal_layout() -> void:
	"""Default terminal rectangle (left side, the world stays visible on the right) and pane sizes."""
	code.default_rect = default_terminal_rect()
	code.restore_layout()
	reference_manual = false
	update_reference()
	# Only the program pane expands, so a negative offset is the other pane's size (Godot 4.7:
	# second pane = max(its minimum, -offset)).
	split_h.split_offset = -TABS_WIDTH
	split_v.split_offset = -CONSOLE_HEIGHT

func toggle_minimize() -> void:
	code.set_minimized(not code.minimized)
	if not code.minimized: editor.grab_focus()

func font_step(d: int) -> void:
	# At high overall UI scale, long C/Java scaffolds need vertical room too.
	# Keep A+ useful without letting their fixed lines push Close outside the screen.
	var height: float = get_node("Screen").size.y
	var ceiling := 28 if height >= 800 else (24 if height >= 680 else (22 if height >= 600 else 20))
	code_font_size = clampi(code_font_size+d, 14, ceiling)
	editor.add_theme_font_size_override("font_size", code_font_size)
	console.add_theme_font_size_override("normal_font_size", code_font_size-2)
	for r: RichTextLabel in [header_view, footer_view]: r.add_theme_font_size_override("normal_font_size", code_font_size-2)
	code.clamp_to_screen.call_deferred()

func frame_code_view() -> void:
	"""Places the coding-view camera in a three-quarter view of this step's world result: the
	apprentice with the Mentor (awakening) or the apprentice at the basin (channelling). _process
	then turns it so the subject sits in the screen area the terminal leaves free."""
	var p := player.global_position
	var target: Vector3 = (world.story.bridge if stage == 3 else (world.story.ward if stage == 4 else (basin if stage == 2 else mentor))).global_position
	var flat := Vector3(target.x-p.x, 0, target.z-p.z)
	if flat.length() < .1: flat = -player.camera.global_basis.z
	flat = Vector3(flat.x, 0, flat.z).normalized()
	var focus := p.lerp(target, .55 if stage == 2 else .4)+Vector3(0, .8 if stage == 2 else 1.1, 0)
	if stage in [3, 4]: focus = target+Vector3(0, 1.3, -1.2 if stage == 3 else 0.0)
	var side := flat.rotated(Vector3.UP, deg_to_rad(40))      # beside, not over the shoulder
	var eye := focus-side*(5.6 if stage == 2 else 5.8)+Vector3(0, 1.9, 0)
	# View the new quest sites from the open side of the living street.
	if stage in [3, 4]: eye = focus+Vector3(6.5, 3.2, 2.8)
	var hit := world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(focus, eye, 1, [player.get_rid()]))
	if hit: eye = hit.position+(focus-eye).normalized()*.3
	code_cam.global_position = eye
	code_cam.look_at(focus)
	code_cam_basis = code_cam.global_basis
	code_cam_shift = view_shift()
	code_cam.global_basis = Basis(Vector3.UP, code_cam_shift)*code_cam_basis
	code_cam.make_current()
	player.avatar.visible = true               # first person hides the figure; the coding view shows it

func view_shift() -> float:
	"""Yaw that moves the view's subject to the middle of the larger free side of the terminal."""
	var s: Vector2 = code.get_parent_control().size
	if s.y < 1: return 0.0
	var r: Rect2 = code.get_rect()
	var x := s.x/2
	if not code.minimized:
		var left := r.position.x
		var right := s.x-r.end.x
		if right >= left and right > 160: x = r.end.x+right/2
		elif left > 160: x = left/2
	var tan_h := tan(deg_to_rad(code_cam.fov)/2)*s.x/s.y
	return atan((x/s.x*2-1)*tan_h)

# ---------------------------------------------------------------- responsive layout
func initialize_layout() -> void:
	responsive_layout()
	font_step(0)
	restore_terminal_layout.call_deferred()

func default_terminal_rect() -> Rect2:
	var area: Vector2 = get_node("Screen").size
	return Rect2(Vector2(24, 24), Vector2(minf(1100, area.x*.64), minf(760, area.y-48)))

func terminal_layout_changed() -> void:
	minimize_button.text = "Restore" if code.minimized else "Minimize"
	update_reference()

func update_reference() -> void:
	if not reference_manual: tabs.visible = code.size.x >= 980
	reference_button.text = "Hide reference" if tabs.visible else "Reference"

func toggle_reference() -> void:
	reference_manual = true
	tabs.visible = not tabs.visible
	update_reference()

func terminal_option(id: int) -> void:
	match id:
		0: reset_code()
		1: if stage == 1: show_language()
		10, 11, 12, 13: set_ui_scale([.9, 1.0, 1.1, 1.25][id-10])
		20: toggle_fullscreen()

func toggle_fullscreen() -> void:
	var win := get_tree().root
	win.mode = Window.MODE_WINDOWED if win.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN

func set_ui_scale(value: float) -> void:
	ui_scale = value
	preload("res://proposal_demo_living_sect/runtime.gd").scale_ui(get_tree(), ui_scale)
	initialize_layout.call_deferred()

func responsive_layout() -> void:
	if not is_instance_valid(menu): return
	var area: Vector2 = get_node("Screen").size
	# Anchored panels keep the same readable font size. Their content scrolls on short windows.
	for item: PanelContainer in [dialogue, language_panel, teach, recognition, menu]:
		var w := minf(900 if item != menu else 460, area.x-48)
		var content: Control = item.get_child(0).get_child(0)
		# Fit short cards instead of leaving a large empty panel. Taller content scrolls.
		var ceiling := minf(560 if item != dialogue else 220, area.y-64)
		var h := clampf(content.get_combined_minimum_size().y+24, 120, ceiling)
		item.set_anchors_preset(Control.PRESET_CENTER_BOTTOM if item == dialogue else Control.PRESET_CENTER)
		item.offset_left = -w/2
		item.offset_right = w/2
		item.offset_top = -h-32 if item == dialogue else -h/2
		item.offset_bottom = -32 if item == dialogue else h/2
	tracker.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tracker.offset_left = -352
	tracker.offset_right = -20
	tracker.offset_top = 20
	tracker.offset_bottom = 180
	if not code.visible: code.default_rect = default_terminal_rect()
	code.clamp_to_screen()

func scroll_panel_contents() -> void:
	# Scroll only composed panels; the terminal retains its own resizable panes.
	for item: PanelContainer in [dialogue, language_panel, teach, recognition, menu]:
		var content: Control = item.get_child(0)
		item.remove_child(content)
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		item.add_child(scroll)
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(content)
		content.minimum_size_changed.connect(func() -> void: responsive_layout.call_deferred())

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
	if code_cam.current and new_mode != "code":
		player.camera.make_current()
		player.update_camera()
	hide_panels()
	mode = new_mode
	responsive_layout()

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
	if world.life: world.life.hide_panel()

func reveal(p: Control) -> void:
	"""Show immediately; decorative UI fades are deliberately omitted."""
	p.visible = true
	p.modulate.a = 1

func escape() -> void:
	match mode:
		"": show_menu()
		"flow": pass
		"code": back_from_code()
		_: close_ui()

func handle_key(event: InputEventKey) -> bool:
	"""Ctrl+Enter runs the inscription while the editor is open."""
	if mode == "code" and event.ctrl_pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
		if code.minimized: toggle_minimize()
		run_code()
		return true
	return false

func nearest() -> String:
	"""The single relevant interaction in range: Guide, Mentor, or the basin during stage 2."""
	var best := ""
	var best_d := INF
	var options := {"guide": [guide, TALK_RANGE], "mentor": [mentor, TALK_RANGE]}
	if world.life:
		for id: String in world.life.residents: options[id] = [world.life.residents[id], 3.0]
	if stage == 2: options["basin"] = [basin, BASIN_RANGE]
	if stage == 3: options["crossing"] = [world.story.bridge, BASIN_RANGE]
	if stage == 4: options["ward"] = [world.story.ward, BASIN_RANGE]
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
		"crossing", "ward": open_story_quest()
		"lin": world.life.talk_lin()
		"mei": world.life.talk_mei()

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
	if near == "crossing": prompt.text = "[E]  The Silent Crossing / inspect the seal"
	if near == "ward": prompt.text = "[E]  The Threefold Ward / restore the stones"
	if near == "lin": prompt.text = "[E]  Lin - lantern practice (optional)"
	if near == "mei": prompt.text = "[E]  Mei - court keeper"
	tracker.visible = mode not in ["code", "teach", "language", "life"]
	if mode == "code" and code_cam.current:
		code_cam_shift = lerp_angle(code_cam_shift, view_shift(), 1.0-exp(-6.0*delta))
		code_cam.global_basis = Basis(Vector3.UP, code_cam_shift)*code_cam_basis
	var target := objective_target()
	bob += delta
	marker.visible = target != null and mode != "code"
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
	if target == world.story.bridge: return "Silent Crossing"
	if target == world.story.ward: return "Threefold Ward"
	return "Mentor"

func sfx(id: String) -> void:
	if sound: sound.play(id)

# ---------------------------------------------------------------- objectives
func objective_target() -> Node3D:
	if stage == 5: return null
	if stage == 3: return world.story.bridge
	if stage == 4: return world.story.ward
	if stage == 2: return basin
	if stage == 1 or met or declined or guide_heard: return mentor
	return guide

func objective_text() -> String:
	if stage == 5: return "Complete. The basin flows, the Silent Crossing is open and the Threefold Ward protects the sect."
	if stage == 3: return "MAIN QUEST / The Silent Crossing: follow the marker north to the sealed bridge and press E."
	if stage == 4: return "MAIN QUEST / The Threefold Ward: cross the released bridge to the shrine and press E."
	if stage == 2: return "Channel your Qi into the basin: walk to the basin and press E."
	if stage == 1 and language == "": return "Choose an inscription language with the Mentor."
	if stage == 1: return "Awaken your Qi: write and run the awakening inscription with the Mentor."
	if declined: return "Speak to the Mentor when you are ready."
	if met or guide_heard: return "Find the Mentor beside the basin in the living court."
	return "Talk to the Guide on the forest path, or head straight for the Mentor."

func update_status() -> void:
	objective.text = objective_text()
	var lang_name := "not chosen" if language == "" else str(Lessons.LESSONS[language].name)
	var step: String = ["not started", "1 of 4 (awaken)", "2 of 4 (basin)", "3 of 4 (crossing)", "4 of 4 (ward)", "all four complete"][stage]
	status.text = "Language: %s   ·   Step: %s   ·   Recognition: %s" % [lang_name, step, "earned" if recognition_earned else "not yet"]

# ---------------------------------------------------------------- dialogue
func say(who: String, text: String, choices: Array) -> void:
	var fresh := not dialogue.visible
	open_ui("dialogue")
	speaker.text = who
	dialogue_text.text = text
	for c in dialogue_buttons.get_children():     # may be the button now emitting
		dialogue_buttons.remove_child(c)
		c.queue_free()
	for i in choices.size():
		var choice: Array = choices[i]
		button(dialogue_buttons, choice[0], choice[1], choice[2], 19, "AccentButton" if i == 0 else "")
	if fresh: reveal(dialogue)
	else: dialogue.visible = true
	# The words appear briskly (Tween) while the speaker talks; buttons work at once.
	if text_tween: text_tween.kill()
	dialogue_text.visible_ratio = 1

	var npc := guide if who.begins_with("GUIDE") else mentor
	npc.speak(clampf(text.length()*.045, 1.2, 5.0))
	(dialogue_buttons.get_child(0) as Button).grab_focus()

func talk_guide() -> void:
	guide.face(player.global_position)
	face(guide.global_position+Vector3(0, 1.5, 0))
	if guide_heard: say("GUIDE", Lessons.GUIDE_AGAIN, [["Thank you", close_ui, "Close"], ["Hear the introduction again", guide_intro.bind(0), "Again"]])
	else:
		guide.greet()
		guide_intro(0)

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
		5: say("MENTOR", "The night mist is held at the shrine. You have restored the basin, checked a condition to release the crossing, and repeated an action to restore the ward. You have earned the trust of the sect.", [["Close", close_ui, "Close"]])
		3, 4: say("MENTOR", "The basin is running. Its current woke an old shrine, but the Silent Crossing is sealed and the Threefold Ward is dormant. Follow the marker north. Verify the seal first, then restore the ward beyond it.", [["Follow the quest marker", close_ui, "ContinueStory"], ["Close", close_ui, "Close"]])
		2: say("MENTOR", Lessons.MENTOR_STAGE2, [["Close", close_ui, "Close"], ["Review the lesson", review_lesson, "Review"]])
		1:
			if language == "": say("MENTOR", Lessons.MENTOR_STAGE1, [["Continue", show_language, "Continue"], ["Not now", close_ui, "NotNow"]])
			else: say("MENTOR", Lessons.MENTOR_STAGE1, [["Continue the inscription", show_code, "Continue"], ["Review the lesson", review_lesson, "Review"], ["Not now", close_ui, "NotNow"]])
		_:
			if not met:
				met = true
				mentor.greet()
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
	reveal(language_panel)
	(language_panel.find_child("Choose_"+(language if language != "" else "python"), true, false) as Button).grab_focus()

func choose_language(id: String) -> void:
	language = id
	if taught.get(key(), false): show_code()
	else: show_teaching(1, "code")

# ---------------------------------------------------------------- teaching
func key(s := -1) -> String:
	return "%s:%d" % [language, stage if s < 0 else s]

func lesson() -> Dictionary:
	return Lessons.for_language(language)

func cards(s: int) -> Array:
	return lesson().cards[s-1]

func show_teaching(s: int, then: String) -> void:
	teach_stage = s
	teach_then = then
	open_ui("teach")
	reveal(teach)
	show_card(0)

func review_lesson() -> void:
	show_teaching(clampi(stage, 1, 4), "close")

func show_card(page: int) -> void:
	var all := cards(teach_stage)
	teach_page = clampi(page, 0, all.size()-1)
	var card: Array = all[teach_page]
	teach_head.text = "MENTOR  ·  %s lesson  ·  %s  ·  %d / %d" % [lesson().name, ["Awakening", "Channelling", "The Silent Crossing", "The Threefold Ward"][teach_stage-1], teach_page+1, all.size()]
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
	mentor.speak(clampf(str(card[1]).length()*.03, 1.2, 4.0))

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
	h.number_color = Color("c7b9a3")
	h.symbol_color = Color("cfe3db")
	h.function_color = Color("a3bcd2")
	h.member_variable_color = Color("cfe3db")
	for kw: String in lesson().keywords: h.add_keyword_color(kw, Color("b9acc7"))
	var comment := Color("929caa")
	if language == "python": h.add_color_region("#", "", comment, true)
	else:
		h.add_color_region("//", "", comment, true)
		h.add_color_region("/*", "*/", comment)
	h.add_color_region("\"", "\"", Color("bdc4ab"))
	return h

func open_story_quest() -> void:
	if stage not in [3, 4]: return
	if taught.get(key(), false): show_code()
	else: show_teaching(stage, "code")

func open_basin() -> void:
	face(basin.global_position+Vector3(0, .6, 0), -.15)
	show_code()

func show_code() -> void:
	var fresh := not code.visible
	open_ui("code")
	if fresh: reveal(code)
	else: code.visible = true
	var l := lesson()
	var s := stage
	code_title.text = "%s · %s · Step %d/4" % [l.files[s-1], l.name, s]
	code_objective.text = "OBJECTIVE  "+Lessons.OBJECTIVE[s]
	options_button.get_popup().set_item_disabled(1, s != 1)
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
	for g in ([1] if s == 1 else [s, 1]):
		if g == 1 and s == 2: caption(lesson_box, "FROM THE AWAKENING LESSON")
		for card: Array in cards(g):
			title(lesson_box, card[0], 19)
			label(lesson_box, card[1], 18)
			if card.size() > 3: label(lesson_box, signature_caption(), 13, MUTED)
			var example := code_block(lesson_box, 18)
			example.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART     # wrap here rather than widen the pane
			example.text = colour_code(card[2])
	reference_label.text = "[color=#cfe3db]%s[/color]" % esc(l.reference)
	refresh_code()
	frame_code_view()
	editor.grab_focus()

func refresh_code() -> void:
	var n: int = attempts.get(key(), 0)
	attempts_label.text = ("Runs: %d" % n) if n > 0 else "Ctrl+Enter runs"
	run_button.disabled = stage_solved
	continue_button.visible = stage_solved
	continue_button.text = "Continue"
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
	if language != "" and stage in [1, 2, 3, 4]: drafts[key()] = editor.text

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

func flash_output(_colour: Color) -> void:
	# Feedback stays in the labelled output text, without whole-panel flashes.
	console_box.self_modulate = Color.WHITE

func run_code() -> void:
	if mode != "code" or stage_solved or not (stage in [1, 2, 3, 4]): return
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
		var colour: String = {"out": "#e3e5e8", "sect": "#9ab9d1", "note": "#8fa39b"}[o[0]]
		lines.append("[color=%s]%s[/color]" % [colour, esc(o[1])])
	if not r.ok:
		var f: Dictionary = r.fail
		var file_line: int = f.line+header.size()
		var on_line: bool = f.line > 0 and f.line-1 < editor.get_line_count()
		var source := editor.get_line(f.line-1).strip_edges() if on_line else ""
		var language_error: bool = f.category in ["language", "game"]
		lines.append("[b]%s[/b]" % {"language": "Language error", "game": "Game rule", "exercise": "Lesson restriction", "unsupported": "Unsupported feature", "limit": "Interpreter limit"}.get(f.category, "Feedback"))
		lines.append_array(error_lines(f, r.phase, file_line, source))
		if on_line: editor.set_line_background_color(f.line-1, Color(.55, .3, .3, .12) if language_error else Color(.5, .45, .3, .12))
		if r.effects.awaken > 0 or r.effects.channel > 0 or r.effects.bridge > 0 or r.effects.ward > 0: lines.append(grey % "[sect runner] the program did not finish, so its world effects were not applied.")
		var note: String = Lessons.NOTES.get(f.kind, "Read the message above, then compare your line with the Lesson tab.")
		if f.kind == "uninitialized" and language == "c": note = Lessons.NOTE_C_UNINITIALIZED+" "+note
		lines.append("[color=#8daac7]Mentor: %s%s[/color]" % [esc(note), ("  (Your line %d.)" % f.line) if language_error and on_line else ""])
		basin.sputter()
		world.qi_flicker()
		flash_output(Color(1.6, .7, .6) if language_error else Color(1.5, 1.2, .6))
		sfx("error" if language_error else "note")
	elif (stage == 1 and r.effects.awaken > 0) or (stage == 2 and r.effects.channel > 0) or (stage == 3 and r.effects.bridge > 0) or (stage == 4 and r.effects.ward > 0):
		stage_solved = true
		lines.append("[color=#6fd19a]Success · Ran without errors, top to bottom.[/color]")
		lines.append("[color=#8daac7]Mentor: %s[/color]" % ["Good. qi held its value before the awakening command used it.", "Good. You read your reserve, then passed exactly what you hold to the basin.", "Your condition checked the real seal before releasing the Silent Crossing.", "Your loop prepared exactly three ward pulses. The Threefold Ward is ready."][stage-1])
		world.qi_stir(stage)
		flash_output(Color(.7, 1.6, 1.0))
		sfx("success")
	else:
		lines.append("[color=#6fd19a]Ran without errors.[/color]")
		lines.append("[color=#8daac7]Mentor: The program ran, but %s[/color]" % ["nothing called the awakening command yet.", "no Qi was channelled into the basin yet.", "the seal has not been released inside a true condition. Read its charge and check it against 3.", "the ward needs exactly three pulses from a for loop."][stage-1])
		flash_output(Color(1.5, 1.2, .6))
		sfx("note")
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
		sfx("awaken")
		update_status()
		await get_tree().create_timer(2.6).timeout
		if token != run: return
		face(mentor.global_position+Vector3(0, 1.5, 0))
		mentor.greet()
		say("MENTOR", Lessons.MENTOR_STAGE2_INTRO, [["Show me", show_teaching.bind(2, "basin"), "ShowMe"]])
	elif stage == 2:
		stage = 3
		reserve = 0
		open_ui("flow")
		face(basin.global_position+Vector3(0, .8, 0), -.18)
		world.channel_effect(basin.global_position+Vector3(0, 1.0, 0))
		sfx("channel")
		await get_tree().create_timer(.9).timeout
		if token != run: return
		basin.activate()
		world.story.unlock_crossing()
		sfx("basin")
		if sound: sound.start_water(basin)
		update_status()
		await get_tree().create_timer(2.6).timeout
		if token != run: return
		show_recognition()
		reserve = Runner.FIRST_RESERVE     # the Mentor replenishes it after practice, as the recognition text says

	elif stage == 3:
		world.story.open_crossing()
		stage = 4
		sfx("channel")
		say("CROSSING INSCRIPTION", "The seal fades. A way to the old shrine is open. Beyond the bridge, three ward stones wait in the night mist. Restore their repeating inscription to protect the sect.", [["Cross to the shrine", close_ui, "ContinueStory"]])
		world.story.frame_result(3)
	elif stage == 4:
		world.story.activate_ward()
		stage = 5
		sfx("recognition")
		say("THREEFOLD WARD", "Three pulses answer as one. The stones rise and a protective veil surrounds the shrine. The night's mist can no longer pass. Your first service brought water; your next brought safe passage and protection. Main quest arc complete / Trusted by the sect.", [["Return to the sect", close_ui, "Close"]])
		world.story.frame_result(4)
	update_status()

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
	recognition_text.text += "\n\nNEXT MAIN QUEST: The Silent Crossing. The restored current has awakened an old shrine. Follow the marker north, verify the crossing seal, then restore the Threefold Ward beyond it."
	reveal(recognition)
	sfx("recognition")
	mentor.greet()
	(recognition.find_child("ContinueExploring", true, false) as Button).grab_focus()
	update_status()

func show_menu() -> void:
	if world.overview: world.set_walk()
	open_ui("menu")
	reveal(menu)
	(menu.find_child("Resume", true, false) as Button).grab_focus()

func reset_demo() -> void:
	"""Spawn, Guide introduction, objectives and marker, teaching, awakening, Qi, basin, drafts,
	recognition, the terminal's layout, and the effects and sounds they started."""
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
	world.story.reset()
	world.clear_aura()
	if sound: sound.reset()
	restore_terminal_layout()
	hide_panels()
	if ui_open:
		ui_open = false
		player.set_physics_process(true)
		player.set_process_unhandled_input(true)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player.third_person = true
	world.get_node("Buildings/sect_gate").set_open_immediate(true)
	world.reset_start()
	if world.life: world.life.reset()
	if world.living: world.living.reset()
	update_status()

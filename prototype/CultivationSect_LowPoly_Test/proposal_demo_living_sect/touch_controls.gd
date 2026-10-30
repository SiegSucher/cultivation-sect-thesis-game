extends CanvasLayer
## Phone/tablet controls. The stick and buttons press the same physical keys the desktop build
## reads (WASD, Shift, E, Tab, J, Esc), so the controller, quest and doors need no touch code.
## Dragging anywhere else turns the camera.
const RADIUS := 80.0
const LOOK := .006
var world: Node3D
var stick: Panel
var knob: Panel
var finger := -1
var held := {}
var walk_buttons: Array[Button] = []
var menu_button: Button

func _ready() -> void:
	layer = 50
	var screen := Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.theme = world.quest.ui_theme
	add_child(screen)
	stick = disc(RADIUS*2, Color(1, 1, 1, .12))
	stick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	stick.position = Vector2(40, -RADIUS*2-40)
	stick.gui_input.connect(stick_input)
	screen.add_child(stick)
	knob = disc(RADIUS, Color(1, 1, 1, .3))
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stick.add_child(knob)
	move_knob(Vector2.ZERO)
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	column.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	column.grow_vertical = Control.GROW_DIRECTION_BEGIN
	column.position = Vector2(-40, -40)
	column.add_theme_constant_override("separation", 12)
	screen.add_child(column)
	for b: Array in [["Interact", KEY_E], ["Camera", KEY_TAB], ["Journal", KEY_J]]:
		walk_buttons.append(button(column, b[0], b[1]))
	menu_button = button(screen, "Menu", KEY_ESCAPE)
	menu_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	menu_button.position = Vector2(20, 20)
	# The keyboard hint panel sits under Menu; the touch buttons label themselves.
	world.help_panel.visible = false
	world.help_panel = null

func disc(size: float, color: Color) -> Panel:
	var p := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(int(size/2))
	p.add_theme_stylebox_override("panel", style)
	p.size = Vector2(size, size)
	return p

func button(parent: Control, text: String, key: Key) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(150, 64)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(func() -> void: send(key, true); send(key, false))
	parent.add_child(b)
	return b

func send(key: Key, down: bool) -> void:
	if held.get(key, false) == down and key in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SHIFT]: return
	held[key] = down
	var e := InputEventKey.new()
	e.physical_keycode = key
	e.keycode = key
	e.pressed = down
	Input.parse_input_event(e)

func stick_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1: finger = event.index
		elif not event.pressed and event.index == finger: finger = -1
		steer(event.position if finger != -1 else stick.size/2)
	elif event is InputEventScreenDrag and event.index == finger:
		steer(event.position)

func steer(at: Vector2) -> void:
	var v := ((at-stick.size/2)/RADIUS).limit_length(1.0)
	move_knob(v)
	send(KEY_W, v.y < -.35)
	send(KEY_S, v.y > .35)
	send(KEY_A, v.x < -.35)
	send(KEY_D, v.x > .35)
	send(KEY_SHIFT, v.length() > .95)

func move_knob(v: Vector2) -> void:
	knob.position = stick.size/2+v*RADIUS-knob.size/2

func _unhandled_input(event: InputEvent) -> void:
	var player: CharacterBody3D = world.player
	if event is InputEventScreenDrag and not world.quest.ui_open and player.is_processing_unhandled_input():
		player.yaw -= event.relative.x*LOOK
		player.pitch = clampf(player.pitch-event.relative.y*LOOK, -1.1, 1.1)

func _process(_delta: float) -> void:
	# The desktop build captures the mouse for look; on touch that would turn every tap into a look.
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var walking: bool = not world.quest.ui_open
	if stick.visible and not walking:
		finger = -1
		steer(stick.size/2)
	stick.visible = walking
	for b in walk_buttons: b.visible = walking or (b.text == "Journal" and world.quest.mode == "life")

extends PanelContainer
## The inscription terminal's outer window: drag by the title bar, resize from any edge or corner,
## minimize/restore, Restore Layout. It stays inside the screen and never goes below MIN_SIZE (or
## the size its contents need). Internal panes are SplitContainers inside it; this script only
## moves and sizes the window itself. Mouse events here are consumed by the GUI, so dragging and
## resizing never reach the player, camera or doors.
signal layout_changed
const GRIP := 10.0                      # px band along the border that resizes (= the panel's content margin)
const MIN_SIZE := Vector2(650, 480)
var default_rect := Rect2(24, 24, 1100, 760)
var title_bar: Control                  # set by the builder; dragging it moves the window
var body: Control                       # hidden while minimized
var minimized := false
var _restore_size := Vector2.ZERO
var _drag := Vector2.ZERO               # pointer offset while moving
var _resizing := Vector2i.ZERO          # edges being dragged: x -1 left / 1 right, y -1 top / 1 bottom
var _moving := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	title_bar.gui_input.connect(_title_input)
	get_viewport().size_changed.connect(clamp_to_screen)
	restore_layout()

func screen() -> Rect2:
	var parent := get_parent_control()
	return parent.get_rect() if parent and parent.size.y > 0 else get_viewport_rect()

func min_size() -> Vector2:
	var need := get_combined_minimum_size()
	return Vector2(maxf(MIN_SIZE.x, need.x), need.y if minimized else maxf(MIN_SIZE.y, need.y))

func restore_layout() -> void:
	"""Default position and size, not minimized; the builder also resets the split offsets."""
	set_minimized(false)
	position = default_rect.position
	size = default_rect.size
	clamp_to_screen()

func set_minimized(on: bool) -> void:
	if on == minimized: return
	minimized = on
	if on: _restore_size = size
	body.visible = not on
	custom_minimum_size = Vector2.ZERO
	size = Vector2(size.x, 0) if on else Vector2(size.x, maxf(_restore_size.y, MIN_SIZE.y))
	clamp_to_screen()

func clamp_to_screen() -> void:
	var s := screen()
	var low := min_size().min(s.size)
	size = Vector2(clampf(size.x, low.x, s.size.x), clampf(size.y, low.y, s.size.y))
	position = Vector2(clampf(position.x, s.position.x, s.end.x-size.x), clampf(position.y, s.position.y, s.end.y-size.y))
	layout_changed.emit()

func _title_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click and event.pressed:
			set_minimized(not minimized)
			_moving = false
		else:
			_moving = event.pressed
			_drag = event.global_position-global_position
		title_bar.accept_event()
	elif event is InputEventMouseMotion and _moving:
		global_position = event.global_position-_drag
		clamp_to_screen()
		title_bar.accept_event()

func edges_at(p: Vector2) -> Vector2i:
	var e := Vector2i.ZERO
	if p.x < GRIP: e.x = -1
	elif p.x > size.x-GRIP: e.x = 1
	if not minimized:
		if p.y < GRIP: e.y = -1
		elif p.y > size.y-GRIP: e.y = 1
	return e

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_resizing = edges_at(event.position) if event.pressed else Vector2i.ZERO
		accept_event()
	elif event is InputEventMouseMotion:
		if _resizing != Vector2i.ZERO:
			resize_by(_resizing, event.global_position)
		else:
			var e := edges_at(event.position)
			mouse_default_cursor_shape = CURSOR_ARROW
			if e.x != 0 and e.y != 0: mouse_default_cursor_shape = CURSOR_FDIAGSIZE if e.x == e.y else CURSOR_BDIAGSIZE
			elif e.x != 0: mouse_default_cursor_shape = CURSOR_HSIZE
			elif e.y != 0: mouse_default_cursor_shape = CURSOR_VSIZE
		accept_event()

func resize_by(e: Vector2i, mouse: Vector2) -> void:
	"""Moves the grabbed edges to the pointer; the opposite edges stay put."""
	var s := screen()
	var low := min_size()
	var r := get_global_rect()
	mouse = mouse.clamp(s.position, s.end)
	if e.x == 1: r.size.x = maxf(low.x, mouse.x-r.position.x)
	if e.y == 1: r.size.y = maxf(low.y, mouse.y-r.position.y)
	if e.x == -1:
		var right := r.end.x
		r.position.x = minf(mouse.x, right-low.x)
		r.size.x = right-r.position.x
	if e.y == -1:
		var bottom := r.end.y
		r.position.y = minf(mouse.y, bottom-low.y)
		r.size.y = bottom-r.position.y
	global_position = r.position
	size = r.size
	clamp_to_screen()

func _draw() -> void:
	if minimized: return
	var c := Color("727c8b")        # corner grip, so resizing is discoverable
	for i in 3:
		var d := 5.0+i*4.0
		draw_line(Vector2(size.x-4, size.y-d), Vector2(size.x-d, size.y-4), c, 1.5)

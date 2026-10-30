extends "res://proposal_demo_living_sect/review/verify_refinement.gd"
## Touch overlay driven through real screen-touch events (the overlay is forced on with --touch).
## godot --headless --fixed-fps 60 --path . --script res://proposal_demo_living_sect/review/verify_touch.gd -- <out.json> --touch
func touch(at: Vector2, down: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.position = at
	e.pressed = down
	Input.parse_input_event(e)
	await frames(2)

func drag(at: Vector2, by: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.position = at+by
	e.relative = by
	Input.parse_input_event(e)
	await frames(2)

func tap_button(b: Button) -> void:
	await touch(b.get_global_rect().get_center(), true)
	await touch(b.get_global_rect().get_center(), false)

func run() -> void:
	demo = load("res://proposal_demo_living_sect/proposal_demo.tscn").instantiate()
	root.add_child(demo)
	current_scene = demo
	await frames(90)
	player = demo.player
	quest = demo.quest
	var pad: CanvasLayer = demo.get_node_or_null("TouchControls")
	check("touch overlay exists", pad != null)
	if pad == null: return finish()
	check("mouse is not captured on touch", Input.mouse_mode != Input.MOUSE_MODE_CAPTURED)
	await go(SPAWN)
	var centre: Vector2 = pad.stick.get_global_rect().get_center()
	var start := player.position
	await touch(centre, true)
	await drag(centre, Vector2(0, -pad.RADIUS))
	check("full stick push holds W and Shift", Input.is_physical_key_pressed(KEY_W) and Input.is_physical_key_pressed(KEY_SHIFT))
	await frames(40)
	check("stick moves the player", player.position.distance_to(start) > 1.5, player.position.distance_to(start))
	await touch(centre+Vector2(0, -pad.RADIUS), false)
	check("releasing the stick releases every key", not (Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_SHIFT)))
	var yaw: float = player.yaw
	var empty := Vector2(root.size)*Vector2(.6, .4)
	await touch(empty, true)
	await drag(empty, Vector2(100, 0))
	await touch(empty+Vector2(100, 0), false)
	check("dragging empty screen turns the camera", is_equal_approx(player.yaw, yaw-100*pad.LOOK), [yaw, player.yaw])
	await go(AT_GUIDE)
	await tap_button(pad.walk_buttons[0])
	check("Interact button talks to the Guide", quest.ui_open and quest.mode == "dialogue")
	await frames(2)
	check("stick hides behind a panel", not pad.stick.visible)
	yaw = player.yaw
	await touch(empty, true)
	await drag(empty, Vector2(100, 0))
	await touch(empty+Vector2(100, 0), false)
	check("no camera turn behind a panel", player.yaw == yaw)
	await tap_button(pad.menu_button)
	check("Menu button (Esc) closes the dialogue", live())
	finish()

func finish() -> void:
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks": results.size(), "failures": failures, "results": results}, "  "))
	print("TOUCH CHECKS ", results.size(), " failures ", failures)
	quit(1 if failures else 0)

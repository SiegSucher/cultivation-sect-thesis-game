extends RefCounted
## Demo-local pixel layout. Shared project.godot and all earlier phases are untouched.
static func configure(tree: SceneTree) -> void:
	var win := tree.root
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	win.content_scale_size = Vector2i.ZERO
	win.min_size = Vector2i(960, 640)
	# Explicit resolution/fullscreen arguments belong to review captures; honour them exactly.
	if DisplayServer.get_name() == "headless" or "--review-layout" in OS.get_cmdline_user_args(): return
	var area := DisplayServer.screen_get_usable_rect()
	win.size = Vector2i(mini(1600, area.size.x-48), mini(900, area.size.y-64))
	win.position = area.position+(area.size-win.size)/2

static func scale_ui(tree: SceneTree, factor: float) -> void:
	# Change logical canvas size, preserving physical output pixels and the 3D resolution.
	tree.root.content_scale_size = Vector2i(Vector2(tree.root.size)/factor)

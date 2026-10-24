extends SceneTree
## Fixed gameplay viewpoints only; no scene/controller/camera resources edited.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene: Node3D = load("res://phase4d/phase4d_valley.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	for i in 12: await physics_frame
	scene.player.automated = true
	for view: Array in [
		["living-street",Vector3(0,10.12,35),PI/2],
		["training-connection",Vector3(-58,14.12,19),1.30],
		["scholarly-ledge",Vector3(-28,28.12,-69),.45],
		["healing-district",Vector3(113,10.12,24),-.35],
		["hall-forecourt",Vector3(12,24.12,-49),0.0]]:
		scene.jump_to(view[1],view[2])
		for i in 12: await physics_frame
		for i in 4: await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("res://phase4d/review/district-"+view[0]+".png")==OK)
	print("Captured five third-person district views.")
	quit()

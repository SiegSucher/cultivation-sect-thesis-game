extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var before := "--before" in OS.get_cmdline_user_args()
	var scene: Node3D = load("res://phase4c/phase4c_valley.tscn" if before else "res://phase4d/phase4d_valley.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	for i in 12: await physics_frame
	scene.player.automated = true
	scene.player.set_physics_process(false)
	var building: Node3D = scene.get_node("Buildings/medicine_hall")
	scene.review_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	scene.review_camera.fov = 52
	scene.review_camera.position = building.transform*Vector3(4,1.7,8)
	scene.review_camera.look_at(building.transform*Vector3(0,.3,5.9))
	scene.review_camera.make_current()
	for i in 5: await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://phase4d/review/"+("before-" if before else "after-")+"medicine-threshold.png")==OK)
	quit()

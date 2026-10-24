extends SceneTree
const ROOT := "res://mountain_valley_compact/"
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene: Node3D = load(ROOT+"compact_valley.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.player.automated = true
	for view: Array in [["01-gate-arrival",Vector3(-9.8,.12,112),-.30],["03-training-connection",Vector3(-75,14.12,19),.50]]:
		scene.jump_to(view[1],view[2])
		scene.player.third_person = true
		for i in 12: await physics_frame
		for i in 4: await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png(ROOT+"review/"+view[0]+".png")==OK)
		print("Captured ",view[0])
	quit()

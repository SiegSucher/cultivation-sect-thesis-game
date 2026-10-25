extends SceneTree
func _initialize() -> void: run()
func run() -> void:
	var demo: Node3D = load("res://proposal_demo_living_sect/proposal_demo.tscn").instantiate()
	root.add_child(demo)
	current_scene = demo
	for i in 45: await physics_frame
	demo.jump_to(Vector3(0,10.05,47),0)
	for i in 5: await physics_frame
	demo.life.set_process(false)
	demo.living.set_process(false)
	for c: CanvasLayer in demo.find_children("*","CanvasLayer",true,false): c.visible = false
	for l: Label3D in demo.find_children("*","Label3D",true,false): l.hide()
	demo.quest.set_process(false)
	demo.get_node("ObjectiveMarker").hide()
	var cam := Camera3D.new()
	cam.fov = 48
	demo.add_child(cam)
	cam.make_current()
	demo.player.automated = true
	demo.player.drive = Vector3(0,0,-1)
	var out := "res://proposal_demo_living_sect/review/motion"
	DirAccess.make_dir_recursive_absolute(out)
	var start: Vector3 = demo.player.position
	for frame in 16:
		for i in 6: await physics_frame
		cam.position = demo.player.position+Vector3(2.4,1.45,-3.2)
		cam.look_at(demo.player.position+Vector3.UP*.95)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("walk-%02d.png" % frame))
	demo.player.drive = Vector3.ZERO
	var f := FileAccess.open(out.path_join("motion.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"frames":16,"physics_frames_per_capture":6,"physics_fps":60,"distance_m":demo.player.position.distance_to(start),"method":"actual CharacterBody3D movement with the ordinary animation driven by displacement"},"  "))
	print("MOTION CAPTURE ",demo.player.position.distance_to(start)," metres")
	quit()

extends SceneTree
## Sweep real walking at multiple offsets: the old centreline check missed visuals.
var scene: Node3D
var player: CharacterBody3D
var results := []
var before := false
var out: String
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in n: await physics_frame
func walk(target: Vector3) -> bool:
	var previous := player.position
	var stalled := 0
	for i in 2400:
		var d := target-player.position
		d.y=0
		if d.length()<.22:
			player.drive=Vector3.ZERO
			return absf(target.y-player.position.y)<.4
		player.drive=d.normalized()
		player.yaw=atan2(-d.x,-d.z)
		await physics_frame
		if player.position.distance_to(previous)<.001: stalled+=1
		else: stalled=0
		previous=player.position
		if stalled>90: break
	player.drive=Vector3.ZERO
	return false
func run() -> void:
	before="--before" in OS.get_cmdline_user_args()
	out=OS.get_environment("VALLEY_REVIEW_OUT")
	scene=load("res://mountain_valley/mountain_valley.tscn").instantiate()
	root.add_child(scene)
	current_scene=scene
	player=scene.player
	player.automated=true
	await frames(8)
	Engine.max_fps=0
	Engine.physics_ticks_per_second=720
	Engine.max_physics_steps_per_frame=32
	Engine.time_scale=12
	for id in ([] if "--captures-only" in OS.get_cmdline_user_args() else ["entry_stairs","middle_stairs","grand"]):
		var path: Dictionary
		for p: Dictionary in scene.layout.paths:
			if p.id==id: path=p
		var a:=Vector3(path.points[0][0],path.points[0][1],path.points[0][2])
		var b:=Vector3(path.points[1][0],path.points[1][1],path.points[1][2])
		for offset in [-4.0,-2.0,0.0,2.0,4.0]:
			for reverse in [false,true]:
				var start: Vector3=(b if reverse else a)+Vector3(offset,.12,0)
				var target: Vector3=(a if reverse else b)+Vector3(offset,0,0)
				scene.jump_to(start)
				await frames(6)
				var ok:=await walk(target)
				results.append({"route":id,"offset":offset,"reverse":reverse,"pass":ok,"end":str(player.position)})
				print("PASS " if ok else "FAIL ",id," offset ",offset," reverse ",reverse," ",player.position)
	if DisplayServer.get_name()!="headless":
		for stop in [["arrival-stairs",Vector3(0,1.1,161),0.0],["living-stairs",Vector3(0,9.1,98),0.0],["living-court",Vector3(0,20.1,57),0.0],["hall-court",Vector3(0,48.1,-121),0.0],["garden",Vector3(202,20.1,-77),PI/2]]:
			scene.jump_to(stop[1],stop[2])
			await frames(12)
			for i in 4: await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out+"/"+("before-" if before else "after-")+stop[0]+".png")
	var failed:=results.filter(func(r): return not r.pass).size()
	var f:=FileAccess.open(out+"/"+("before" if before else "after")+"-stairs.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"failures":failed,"checks":results},"\t"))
	print("STAIRS ",results.size()-failed," PASS / ",failed," FAIL")
	quit(1 if failed else 0)



extends SceneTree
## Focused Phase 4B baseline/final review. Normal 60 Hz walking, no accelerated
## time scale and no changes to the existing controller, camera or map instances.
const OUT := "res://reports/phase4b-stairs/"
var scene: Node3D
var player: CharacterBody3D
var checks: Array = []
var phase := "before"
var rendered := false

func _initialize() -> void: call_deferred("run")

func frames(n: int = 6) -> void:
	for i in n: await physics_frame

func check(label: String, passed: bool, detail: Variant = null) -> void:
	checks.append({"check":label,"pass":passed,"detail":detail})
	print("PASS " if passed else "FAIL ",label," ",detail if detail!=null else "")

func walk(start: Vector3, target: Vector3, third: bool) -> Dictionary:
	scene.jump_to(start)
	player.third_person = third
	player.pitch = -.08
	player.yaw = 0 if target.z<start.z else PI
	await frames(8)
	var last: Vector3 = player.position
	var stalled := 0
	var contacts := {}
	var reached := false
	for i in 1600:
		var delta := target-player.position
		delta.y = 0
		if delta.length()<.18:
			reached = true
			break
		player.drive = delta.normalized()
		player.yaw = atan2(-delta.x,-delta.z)
		await physics_frame
		for j in player.get_slide_collision_count():
			var hit := player.get_slide_collision(j)
			if hit.get_normal().y<.7:
				var collider: Object = hit.get_collider()
				if collider is Node: contacts[str(collider.get_path())] = true
		if player.position.distance_to(last)<.0002: stalled += 1
		else: stalled = 0
		last = player.position
		if stalled>75: break
	player.drive = Vector3.ZERO
	await frames(8)
	return {"pass":reached and absf(player.position.y-target.y)<.35 and player.is_on_floor(),"end":[player.position.x,player.position.y,player.position.z],"side_contacts":contacts.keys(),"camera_mode":"third" if third else "first"}

func local_triangles(mesh: MeshInstance3D, min_z: float, max_z: float) -> Array:
	var tris: Array = []
	for s in mesh.mesh.get_surface_count():
		var arrays: Array = mesh.mesh.surface_get_arrays(s)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
		var count := indices.size() if not indices.is_empty() else vertices.size()
		for i in range(0,count,3):
			var a: Vector3 = mesh.global_transform*vertices[indices[i] if not indices.is_empty() else i]
			var b: Vector3 = mesh.global_transform*vertices[indices[i+1] if not indices.is_empty() else i+1]
			var c: Vector3 = mesh.global_transform*vertices[indices[i+2] if not indices.is_empty() else i+2]
			if minf(a.x,minf(b.x,c.x))>6 or maxf(a.x,maxf(b.x,c.x))< -6: continue
			if minf(a.z,minf(b.z,c.z))>max_z or maxf(a.z,maxf(b.z,c.z))<min_z: continue
			tris.append([a,b,c])
	return tris

func top_at(tris: Array, x: float, z: float) -> float:
	var high := -1000.0
	for t: Array in tris:
		var a := Vector2(t[0].x,t[0].z)
		var b := Vector2(t[1].x,t[1].z)
		var c := Vector2(t[2].x,t[2].z)
		var p := Vector2(x,z)
		var area := (b-a).cross(c-a)
		if absf(area)<.00001: continue
		var u := (p-a).cross(c-a)/area
		var v := (b-a).cross(p-a)/area
		if u>=-.0001 and v>=-.0001 and u+v<=1.0001:
			high = maxf(high,t[0].y+u*(t[1].y-t[0].y)+v*(t[2].y-t[0].y))
	return high

func inspect_geometry(route: String, upper_z: float, lower_z: float) -> void:
	var ground := local_triangles(scene.get_node("ContinuousValleyTerrain"),upper_z-4,lower_z+4)
	var paths := local_triangles(scene.get_node("RoadsCourtsAndVisibleStairs"),upper_z-4,lower_z+4)
	var lanes: Array = []
	for x in [-5.5,-4.5,0.0,4.5,5.5]:
		var max_above := -1000.0
		var where := 0.0
		for i in range(1,int((lower_z-upper_z)*4)):
			var z := upper_z+i*.25
			var over := top_at(ground,x,z)-top_at(paths,x,z)
			if over>max_above:
				max_above = over
				where = z
		lanes.append({"x":x,"max_terrain_above_tread_m":max_above,"at_z":where})
	var f := FileAccess.open(OUT+phase+"-"+route+"-geometry.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(lanes,"\t"))
	print("GEOMETRY ",route," ",lanes)
	var cap_excess := -1000.0
	var top_y := 8.0 if route=="arrival" else 20.0
	var bottom_y := 0.0 if route=="arrival" else 8.0
	var count := ceili((top_y-bottom_y)/.18)
	for i in range(1,int((lower_z-upper_z)*4)):
		var z := upper_z+i*.25
		var progress := (lower_z-z)/(lower_z-upper_z)
		var tread_top := bottom_y+ceilf(progress*count)*(top_y-bottom_y)/count+.025
		cap_excess = maxf(cap_excess,top_at(paths,0,z)-tread_top)
	check(route+" has no overhanging endpoint-cap surface",cap_excess<.005,{"max_above_expected_tread_m":cap_excess})

func shot(name: String, at: Vector3, yaw: float, third: bool, pitch: float = -.08) -> void:
	scene.jump_to(at,yaw)
	player.third_person = third
	player.pitch = pitch
	await frames(10)
	player.update_camera()
	for i in 4: await RenderingServer.frame_post_draw
	check("Capture "+name,root.get_texture().get_image().save_png(OUT+phase+"-"+name+".png")==OK)

func run() -> void:
	phase = "after" if "--after" in OS.get_cmdline_user_args() else "before"
	rendered = DisplayServer.get_name()!="headless"
	var scene_path := OUT+"baseline-scene.tscn" if "--archived-before" in OS.get_cmdline_user_args() else "res://mountain_valley/mountain_valley.tscn"
	scene = load(scene_path).instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(10)
	player = scene.player
	check("Current scene launches with unchanged player",player.get_script().resource_path=="res://scripts/training_inspection_player.gd" and player.camera.current)
	player.automated = true
	if not rendered:
		inspect_geometry("arrival",145,164)
		inspect_geometry("living",71,101)
	var lanes: Array = [0.0] if rendered else [-4.5,0.0,4.5]
	var flights: Array = [] if "--captures-only" in OS.get_cmdline_user_args() else [["arrival",Vector3(0,0,168),Vector3(0,8,141)],["living",Vector3(0,8,105),Vector3(0,20,67)]]
	for flight: Array in flights:
		for third in [false,true]:
			for x: float in lanes:
				for downhill in [false,true]:
					var a: Vector3 = (flight[2] if downhill else flight[1])+Vector3(x,.12,0)
					var b: Vector3 = (flight[1] if downhill else flight[2])+Vector3(x,0,0)
					var result := await walk(a,b,third)
					check("%s %s %s lane %.1f"%[flight[0],"TPP" if third else "FPP","down" if downhill else "up",x],result.pass,result)
	if rendered:
		for third in [false,true]:
			var mode := "tpp" if third else "fpp"
			await shot("arrival-flight-"+mode,Vector3(0,.12,168),0,third)
			await shot("arrival-upper-"+mode,Vector3(0,8.12,144.3),PI,third,-.65)
			await shot("living-flight-"+mode,Vector3(0,8.12,105),0,third)
			await shot("living-upper-"+mode,Vector3(0,20.12,70.3),PI,third,-.65)
		for view: Array in [["arrival-edge",Vector3(16,15,158),Vector3(0,5,153)],["living-edge",Vector3(16,27,89),Vector3(0,15,83)]]:
			scene.player.set_physics_process(false)
			scene.review_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
			scene.review_camera.position = view[1]
			scene.review_camera.look_at(view[2])
			scene.review_camera.fov = 65
			scene.review_camera.make_current()
			for i in 4: await RenderingServer.frame_post_draw
			check("Capture "+view[0],root.get_texture().get_image().save_png(OUT+phase+"-"+view[0]+".png")==OK)
	var failed := checks.filter(func(c): return not c.pass).size()
	var suffix := "-captures.json" if "--captures-only" in OS.get_cmdline_user_args() else ("-rendered.json" if rendered else "-traversal.json")
	var f := FileAccess.open(OUT+phase+suffix,FileAccess.WRITE)
	f.store_string(JSON.stringify({"pass":failed==0,"passes":checks.size()-failed,"failures":failed,"normal_physics_hz":Engine.physics_ticks_per_second,"checks":checks},"\t"))
	print("FOCUSED ",phase," ",checks.size()-failed," PASS / ",failed," FAIL")
	quit(1 if failed else 0)

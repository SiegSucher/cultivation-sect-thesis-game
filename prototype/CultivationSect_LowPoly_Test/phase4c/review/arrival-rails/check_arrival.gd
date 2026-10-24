extends "res://phase4c/review/check_terrain.gd"
## Arrival only: unchanged controller, representative physical movement and joins.
const OUT := "res://phase4c/review/arrival-rails/"
const VIS := 1 << 19
var assembly: Node3D
var space: PhysicsDirectSpaceState3D

func h(run: float) -> float: return clampf(run,0,11)*4.0/11.0
func pos(x: float,run: float,lift: float = 0) -> Vector3: return Vector3(x,h(run)+lift,105-run)

func inspect_assembly() -> void:
	var faces := PackedVector3Array()
	var support_exclusions: Array[RID] = []
	for body: CollisionObject3D in scene.find_children("*","CollisionObject3D",true,false):
		if not String(body.name).begins_with("StoneStripCollision_"): support_exclusions.append(body.get_rid())
	for sign_value in [-1.0,1.0]:
		var x: float = sign_value*6.35
		var sections: Array[Node3D] = []
		var landing: Node3D
		var ending: Node3D
		for n: Node3D in assembly.get_children():
			if n.scene_file_path.is_empty(): continue
			if absf(n.position.x-x)>.001: continue
			if "rail_stair_4in11_" in n.scene_file_path: sections.append(n)
			elif n.position.distance_to(pos(x,11,.06))<.001: landing = n
			elif n.position.distance_to(pos(x,13,.06))<.001: ending = n
		sections.sort_custom(func(a: Node3D,b: Node3D): return a.position.z>b.position.z)
		var correct := sections.size()==6
		var lengths: Array = []
		var run := 0.0
		var max_error := 0.0
		for n: Node3D in sections:
			var length := 2 if "_2m.tscn" in n.scene_file_path else 1
			lengths.append(length)
			max_error = maxf(max_error,n.position.distance_to(pos(x,run,.06)))
			correct = correct and n.scale.is_equal_approx(Vector3.ONE) and absf(n.rotation.x)<.00001 and absf(n.rotation.z)<.00001 and n.basis.y.distance_to(Vector3.UP)<.00001
			run += length
		check("Arrival chain side "+str(sign_value),correct and lengths==[2,2,2,2,2,1] and max_error<.00001,{"lengths":lengths,"max_origin_error_m":max_error,"unit_scale_upright":correct})
		var top_count := 0
		for n: Node3D in assembly.get_children():
			if not n.scene_file_path.is_empty() and n.position.distance_to(pos(x,11,.06))<.001: top_count += 1
		check("Reuse one existing upper landing leading post side "+str(sign_value),landing!=null and ending!=null and top_count==1 and is_equal_approx(run,11),{"landing_post_count":top_count,"end_origin":pos(x,run,.06)})
		# Actual staged geometry, with no ground/supports in the visual probe layer.
		var visual_nodes: Array[Node3D] = sections.duplicate()
		if landing: visual_nodes.append(landing)
		if ending: visual_nodes.append(ending)
		for n: Node3D in visual_nodes:
			for m: MeshInstance3D in n.find_children("*","MeshInstance3D",true,false):
				for v: Vector3 in m.mesh.get_faces(): faces.append(m.global_transform*v)
		var supported := true
		var support_errors: Array = []
		for t: float in [.1,3.0,6.0,10.5,10.95,11.05,12.0,12.9]:
			var q := PhysicsRayQueryParameters3D.create(pos(x,t,.4),pos(x,t,-.8),1,support_exclusions)
			var hit := space.intersect_ray(q)
			var error: float = INF if hit.is_empty() else absf(hit.position.y-(h(t)+.04))
			supported = supported and error<.001
			support_errors.append(error)
		check("Existing stone strips support flight and landing side "+str(sign_value),supported,support_errors)
	var proxy := StaticBody3D.new()
	proxy.name = "ArrivalVisualProbeOnly"
	proxy.collision_layer = VIS
	proxy.collision_mask = 0
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	proxy.add_child(cs)
	scene.add_child(proxy)
	await frames(3)
	for sign_value in [-1.0,1.0]:
		var misses := 0
		# Representative span faces and both faces of each shared post, including
		# the short last section, landing leading post and closing post.
		var samples: Array[float] = [.2,1,3,5,7,9,10.5,12,12.8]
		for t: float in [2,4,6,8,10,11]: samples.append_array([t-.121,t-.119,t+.119,t+.121])
		for t: float in samples:
			for height: float in [.12,1.10]:
				var a := pos(sign_value*5.9,t,height)
				if space.intersect_ray(PhysicsRayQueryParameters3D.create(a,a+Vector3(sign_value,0,0),VIS)).is_empty(): misses += 1
		check("Visible plinth and top-rail faces join side "+str(sign_value),misses==0,{"rays":samples.size()*2,"misses":misses})
		var max_height_error := 0.0
		for t: float in [1,3,5,7,9,10.5,12]:
			var a := pos(sign_value*6.35,t,1.6)
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(a,a-Vector3.UP,VIS))
			max_height_error = INF if hit.is_empty() else maxf(max_height_error,absf(hit.position.y-h(t)-1.16))
		check("Top rail stays 1.16 m above walking pitch side "+str(sign_value),max_height_error<.001,max_height_error)

func traversals() -> void:
	for third in [true,false]:
		player.third_person = third
		# The landing approach is 10 m wide and the forest approach is narrower.
		# Join those existing approaches centrally, then fan out on the 12 m flight.
		for x: float in [0,-5.93,5.93]:
			for uphill in [true,false]:
				var start := -.8 if uphill else 11.8
				var finish := 11.8 if uphill else -.8
				scene.jump_to(pos(0,start,.12),0 if uphill else PI)
				await frames(8)
				var okay := true
				if x!=0:
					# Walk continuously through centre/edge waypoints; no teleport
					# between the approach, edge segment and opposite landing.
					var enter := 2.0 if uphill else 9.0
					var leave := 9.0 if uphill else 2.0
					for waypoint: Vector3 in [pos(0,enter),pos(x,enter),pos(x,leave),pos(0,leave)]:
						okay = await walk_to(waypoint) and okay
				okay = await walk_to(pos(0,finish)) and okay
				check("Arrival %s %s edge x %.2f via existing approaches"%["TPP" if third else "FPP","up" if uphill else "down",x],okay,{"end":player.position,"on_floor":player.is_on_floor()})
	for sign_value in [-1.0,1.0]:
		for t: float in [3,6,10.5,12]:
			# The existing landing shoulder falls below its narrow stone strip.
			# Begin the landing probe on that strip so it tests the actual rail.
			var start_x: float = 5.8 if t>11 else 5.0
			scene.jump_to(pos(sign_value*start_x,t,.12))
			await frames(8)
			var actual_rail := ""
			player.drive = Vector3(sign_value,0,0)
			for frame in 60:
				await physics_frame
				for i in player.get_slide_collision_count():
					var body: Node = player.get_slide_collision(i).get_collider()
					if "/rail_" in str(body.get_path()): actual_rail = str(body.get_path())
			player.drive = Vector3.ZERO
			var q := PhysicsRayQueryParameters3D.create(pos(0,t,.8),pos(sign_value*7,t,.8),1,[player.get_rid()])
			var hit := space.intersect_ray(q)
			var ray_rail := not hit.is_empty() and "/rail_" in str(hit.collider.get_path())
			check("Sideways blocked side %s run %.1f"%[sign_value,t],absf(player.position.x)>5.8 and absf(player.position.x)<6.01 and player.is_on_floor() and not actual_rail.is_empty() and ray_rail,{"end":player.position,"movement_collider":actual_rail,"waist_ray_hits_rail":ray_rail})

func capture(name: String) -> void:
	for i in 5: await RenderingServer.frame_post_draw
	check("Capture "+name,root.get_texture().get_image().save_png(OUT+name+".png")==OK)

func run() -> void:
	scene = load(ROOT+"phase4c_valley.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(12)
	player = scene.player
	check("Current Phase 4C launches",player.camera.current and player.is_physics_processing())
	if DisplayServer.get_name()=="headless":
		player.automated = true
		assembly = scene.get_node("SelectiveTerrainSupports")
		space = scene.get_world_3d().direct_space_state
		await inspect_assembly()
		await traversals()
	else:
		# Test actual Tab input before entering the automated screenshot fixture.
		await press(KEY_TAB)
		check("Tab first person",not player.third_person)
		await press(KEY_TAB)
		check("Tab third person",player.third_person)
		player.automated = true
		scene.jump_to(Vector3(0,.12,112),0)
		await frames(12)
		await capture("complete-arrival-approach")
		scene.player.set_physics_process(false)
		scene.review_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		scene.review_camera.fov = 60
		scene.review_camera.position = Vector3(18,8,101)
		scene.review_camera.look_at(Vector3(0,2,99.5))
		scene.review_camera.make_current()
		await capture("arrival-side")
		scene.review_camera.position = Vector3(3.7,6.3,97.2)
		scene.review_camera.look_at(Vector3(6.35,4.65,93.6))
		await capture("upper-landing-connection")
	var failed := checks.filter(func(c): return not c.pass).size()
	var file := FileAccess.open(OUT+("walking-results.json" if DisplayServer.get_name()=="headless" else "rendered-results.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"passes":checks.size()-failed,"failures":failed,"checks":checks},"\t"))
	print("ARRIVAL RAILS ",checks.size()-failed," PASS / ",failed," FAIL")
	quit(1 if failed else 0)

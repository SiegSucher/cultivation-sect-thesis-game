extends "res://proposal_demo_living_sect/review/verify_refinement.gd"
## Physical assertions for the additions; existing quest/UI suites run separately.
var living: Node3D
var captures := "res://proposal_demo_living_sect/review/living-captures"
func shot(id: String, from: Vector3, focus: Vector3) -> void:
	if DisplayServer.get_name() == "headless": return
	var cam := Camera3D.new()
	cam.fov = 52
	demo.add_child(cam)
	cam.position = from
	cam.look_at(focus)
	cam.make_current()
	await frames(4)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(captures.path_join(id+".png"))
	cam.queue_free()
	player.camera.make_current()
func run() -> void:
	demo = load("res://proposal_demo_living_sect/proposal_demo.tscn").instantiate()
	root.add_child(demo)
	current_scene = demo
	await frames(120)
	player = demo.player
	quest = demo.quest
	living = demo.living
	DirAccess.make_dir_recursive_absolute(captures)
	check("18 added residents, four retained quest characters",living.residents.size()==18 and demo.life.residents.size()==2 and demo.guide!=null and demo.mentor!=null)
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://mountain_valley_compact/layout.json"))
	for building: Dictionary in layout.buildings:
		var original := Vector3(building.position[0],building.position[1],building.position[2])
		check("building placement retained: "+building.id,demo.get_node("Buildings/"+building.id).position.distance_to(original)<.001)
	var wall_failures := []
	var rays := 0
	var non_wall: Array[RID] = []
	for body: CollisionObject3D in demo.find_children("*","CollisionObject3D",true,false):
		if "LivingEntranceWalls" not in str(body.get_path()): non_wall.append(body.get_rid())
	for section: Dictionary in living.walls.sections:
		var a: Vector3 = section.from
		var b: Vector3 = section.to
		var normal := (b-a).normalized().cross(Vector3.UP)
		for step in 9:
			var p := a.lerp(b,(step+.5)/9.0)
			var floor_y: float = living.walls.ground(p)
			for h in [.12,1.65,4.0]:
				p.y = floor_y+h
				for sign in [-1,1]:
					# The slope can occlude an uphill ray before it reaches the wall; test wall
					# continuity independently. Foundation-vs-terrain depth is checked above.
					var q := PhysicsRayQueryParameters3D.create(p+normal*sign*1.8,p-normal*sign*1.8,1,non_wall)
					var hit := demo.get_world_3d().direct_space_state.intersect_ray(q)
					rays += 1
					if not hit or "LivingEntranceWalls" not in str(hit.collider.get_path()): wall_failures.append(str(p))
		check("foundation buried and full-height wall at "+str(a),section.base<=section.ground_min-.20 and section.top-section.ground_max>4)
	check("wall solid from both sides at ground, eye and upper levels",wall_failures.is_empty(),{"rays":rays,"misses":wall_failures})
	for pier: Dictionary in living.walls.piers:
		check("pier has a buried foundation "+str(pier.at),pier.base<living.walls.ground(pier.at)-.1)
	var feet_errors := []
	for n in living.residents:
		if n.route.size()>1: continue
		for foot: Node3D in n.figure.feet:
			var bottom := foot.to_global(Vector3(0,-.076,-.05))
			var q := PhysicsRayQueryParameters3D.create(bottom+Vector3.UP*.45,bottom-Vector3.UP*.7,1)
			var hit := demo.get_world_3d().direct_space_state.intersect_ray(q)
			if not hit or absf(bottom.y-hit.position.y)>.13: feet_errors.append({"name":n.display_name,"bottom":bottom,"hit":hit.get("position",Vector3.ZERO)})
	check("stationary feet meet support within 13 cm, including seated and training poses",feet_errors.is_empty(),feet_errors)
	var start_positions := []
	for n in living.residents: start_positions.append(n.position)
	# Real physical routes over 45 simulated seconds, no teleports during movement.
	await frames(2700)
	for index in [10,11]:
		var n: CharacterBody3D = living.residents[index]
		check("walking resident reaches destinations: "+n.display_name,n.total_distance>8 and n.reached>=1 and n.stuck_time<1,{"metres":n.total_distance,"arrivals":n.reached})
	# Interaction arbitration and camera restoration with actual E/Esc events.
	await go(Vector3(4.4,10.05,45.6))
	check("Mentor interaction takes priority over optional residents",quest.nearest()=="mentor" and living.nearest_extra()=="")
	await go(Vector3(13,10.05,38))
	demo.basin.activate()
	await frames(1500)
	var carrier: CharacterBody3D = living.residents[11]
	check("basin restoration changes the carrier route",carrier.restoring and carrier.route.size()==3 and living.restored)
	# Move the player clear and let the carrier reach the public water.
	await go(Vector3(0,10.05,45))
	await frames(900)
	check("carrier physically visits restored basin",carrier.reached>=3,{"arrivals":carrier.reached,"position":carrier.position,"travel":carrier.total_distance})
	await go(Vector3(-9.4,4.1,93))
	player.third_person = false
	player.update_camera()
	await frames(4)
	await tap(KEY_E)
	check("guard dialogue opens with live interaction",quest.ui_open and quest.speaker.text.contains("REN"))
	await tap(KEY_ESCAPE)
	check("resident dialogue restores first-person camera and controls",not quest.ui_open and not player.third_person and player.camera.current and player.is_physics_processing())
	# At a fixed pause, inspect representative activities and limbs from multiple angles.
	quest.visible = false
	await shot("01-reading",Vector3(-14,11.7,29),Vector3(-13.3,11.1,32))
	await shot("02-sweeping",Vector3(23,11.6,51.5),Vector3(20,10.9,49))
	await shot("03-seated-tea",Vector3(27.5,11.6,40),Vector3(24.6,10.9,42.5))
	await shot("04-training",Vector3(-10,11.5,56),Vector3(-12.6,11,53.5))
	await shot("05-restored-court",Vector3(17,13,44),Vector3(10,11,39))
	quest.visible = true
	# Orbit the actual third-person controller beside both new wall wings and a corner.
	var camera_contacts := []
	var samples := 0
	for at: Vector3 in [Vector3(24,5,82),Vector3(-24,5,82),Vector3(40,5,83)]:
		at.y = living.ground(at)+.1
		await go(at)
		player.third_person = true
		for angle in 24:
			player.yaw = angle*TAU/24
			player.pitch = -.12
			player.update_camera()
			var sphere := SphereShape3D.new()
			sphere.radius = .15
			var q := PhysicsShapeQueryParameters3D.new()
			q.shape = sphere
			q.transform.origin = player.camera.global_position
			q.collision_mask = 1
			q.exclude = [player.get_rid()]
			var hit := demo.get_world_3d().direct_space_state.intersect_shape(q,4)
			samples += 1
			if hit: camera_contacts.append(str(player.camera.global_position))
	check("third-person orbit has no wall/terrain camera collisions",camera_contacts.is_empty(),{"samples":samples,"contacts":camera_contacts})
	quest.reset_demo()
	await frames(6)
	check("reset clears visits, water response and listening count",living.visits.is_empty() and not living.restored and living.dusk.listen_count==0 and not demo.basin.active)
	for n in living.residents:
		check("reset restores resident duty/route: "+n.display_name,n.duty==n.default_duty and n.route==n.default_route and not n.restoring and n.position.distance_to(n.home)<.6)
	var f := FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":results.size(),"failures":failures,"results":results},"  "))
	print("LIVING CHECKS ",results.size()," failures ",failures)
	quit(1 if failures else 0)

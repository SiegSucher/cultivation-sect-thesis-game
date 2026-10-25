extends "res://proposal_demo_living_sect/review/verify_refinement.gd"
func run() -> void:
	demo = load("res://proposal_demo_living_sect/proposal_demo.tscn").instantiate()
	root.add_child(demo)
	current_scene = demo
	await frames(90)
	player = demo.player
	quest = demo.quest
	var living: Node3D = demo.living
	var courier: CharacterBody3D = living.residents[10]
	courier.waiting = 0
	await go(Vector3(-5,10.05,25))
	var start: Vector3 = courier.position
	await frames(120)
	check("walker yields before reaching the player",courier.position.distance_to(player.position)>1.05 and courier.position.distance_to(start)<1.1,{"distance_to_player":courier.position.distance_to(player.position),"yield_frames":courier.yield_count})
	await go(Vector3(0,10.05,45))
	await frames(60)
	var samples := 0
	var slipped := 0.0
	var body_distance := 0.0
	var previous: Array[Vector3] = [courier.figure.feet[0].global_position,courier.figure.feet[1].global_position]
	var previous_body: Vector3 = courier.position
	var floor_errors := []
	for frame in 180:
		await physics_frame
		for i in 2:
			var foot: Node3D = courier.figure.feet[i]
			var cycle := fposmod(courier.figure.phase/TAU+i*.5,1.0)
			if cycle>.10 and cycle<.50 and courier.velocity.length()>.7:
				var bottom := foot.to_global(Vector3(0,-.076,-.05))
				var hit := demo.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(bottom+Vector3.UP*.3,bottom-Vector3.UP*.6,1))
				if not hit or absf(bottom.y-hit.position.y)>.10: floor_errors.append(str(bottom))
				samples += 1
				slipped += Vector2(foot.global_position.x-previous[i].x,foot.global_position.z-previous[i].z).length()
				body_distance += Vector2(courier.position.x-previous_body.x,courier.position.z-previous_body.z).length()
			previous[i] = foot.global_position
		previous_body = courier.position
	check("walking stance keeps soles near ground",samples>60 and floor_errors.is_empty(),{"samples":samples,"errors":floor_errors})
	check("planted feet remain nearly stationary as the body advances",body_distance>1 and slipped/body_distance<.35,{"stance_slip_metres":slipped,"body_metres":body_distance,"ratio":slipped/maxf(.01,body_distance)})
	await frames(420)
	check("walker resumes and completes route after player leaves",courier.reached>0 and courier.total_distance>8)
	var bench_at: Vector3 = living.dusk.bench.global_position
	await go(bench_at+Vector3(1.7,.10,.4))
	player.third_person = false
	player.update_camera()
	var state := [quest.stage,quest.language,quest.reserve,quest.drafts.duplicate(true),demo.basin.active]
	await tap(KEY_E)
	check("listening bench is reachable through normal E interaction",quest.ui_open and living.dusk.rest_camera.current and quest.speaker.text.contains("BENCH"))
	living.dusk.sound_chime()
	check("chime plays without changing quest state",living.dusk.chime.playing and state==[quest.stage,quest.language,quest.reserve,quest.drafts.duplicate(true),demo.basin.active])
	await tap(KEY_ESCAPE)
	check("listening restores first-person camera",player.camera.current and not player.third_person and not quest.ui_open)
	demo.basin.activate()
	await frames(150)
	await tap(KEY_E)
	check("listening text acknowledges actual restored water",quest.dialogue_text.text.contains("Water answers") and living.dusk.restoration_count==1)
	quest.reset_demo()
	await frames(8)
	check("reset during listening clears new state and restores camera",living.dusk.listen_count==0 and living.dusk.restoration_count==0 and not living.dusk.current_motes.emitting and player.camera.current and not quest.ui_open and not demo.basin.active)
	var f := FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":results.size(),"failures":failures,"results":results},"  "))
	print("EXTRA CHECKS ",results.size()," failures ",failures)
	quit(1 if failures else 0)

extends SceneTree
## Walking checks for the boundary wall and dressing layers, with the unchanged controller driven
## the way the rehearsal drives it (player.automated + drive):
##   1. Gate passage: forest stair foot, through the Gate, into the arrival court.
##   2. The wall stops the player: walked at from both sides at every third section.
##   3. Wall ends: an attempt to walk round each end along the wall line is reported.
##   4. Every district path in the layout, walked end to end with the layers in place, and again
##      with both layers removed, so any path the layers would block shows up as a difference.
## godot --headless --fixed-fps 60 --path . --script res://proposal_demo_living_sect/review/walk_boundary.gd -- <results.json>
const STEP := 1.0/60.0
var demo: Node3D
var player: CharacterBody3D
var checks := []
var failures := 0

func _initialize() -> void:
	run()

func check(label: String, ok: bool, detail = null) -> void:
	checks.append({"check": label, "ok": ok, "detail": detail})
	if not ok: failures += 1
	print(("PASS  " if ok else "FAIL  ")+label+("" if detail == null else "  "+str(detail)))

func ground(p: Vector2) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(p.x, 90, p.y), Vector3(p.x, -30, p.y), 1, [player.get_rid()])
	var hit := demo.get_world_3d().direct_space_state.intersect_ray(q)
	return hit.position.y if hit else 0.0

func put(p: Vector2) -> void:
	demo.jump_to(Vector3(p.x, ground(p)+.15, p.y), player.yaw)
	for i in 6: await physics_frame

func flat_pos() -> Vector2:
	return Vector2(player.global_position.x, player.global_position.z)

## Drives the player toward p; stops on arrival (0.6 m), when stuck for 3 s, or at the time limit.
func walk_to(p: Vector2, limit := 40.0) -> bool:
	player.automated = true
	var t := 0.0
	var best := INF
	var since := 0.0
	while t < limit:
		var to := p-flat_pos()
		if to.length() < .6: break
		if to.length() < best-.05:
			best = to.length()
			since = 0.0
		else:
			since += STEP
		if since > 3.0: break
		var d := Vector3(to.x, 0, to.y).normalized()
		player.drive = d
		player.yaw = atan2(-d.x, -d.z)
		await physics_frame
		t += STEP
	player.drive = Vector3.ZERO
	await physics_frame
	return (p-flat_pos()).length() < .6

func walk_path(points: Array) -> Array:
	await put(Vector2(points[0][0], points[0][2]))
	for k in range(1, points.size()):
		var p := Vector2(points[k][0], points[k][2])
		if not await walk_to(p):
			return [false, k, [snappedf(player.global_position.x, .1), snappedf(player.global_position.z, .1)]]
	return [true, points.size()-1, null]

func run() -> void:
	demo = load("res://proposal_demo_living_sect/proposal_demo.tscn").instantiate()
	root.add_child(demo)
	current_scene = demo
	for i in 10: await physics_frame
	player = demo.player
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://mountain_valley_compact/layout.json"))
	# 1. Gate passage.
	await put(Vector2(0, 108))
	var through := await walk_to(Vector2(0, 94)) and await walk_to(Vector2(0, 80)) and await walk_to(Vector2(0, 70))
	check("Gate passage: forest stair foot -> through the Gate -> arrival court", through, [snappedf(player.global_position.x, .1), snappedf(player.global_position.z, .1)])
	# 2. Walls stop the player from both sides.
	var boundary := demo.get_node("DemoBoundary")
	for run_node: Node in boundary.get_children():
		var walls: Array[Node3D] = []
		for c: Node3D in run_node.get_children():
			if "_wall_" in c.name: walls.append(c)
		var tried := 0
		var held := 0
		var leaks := []
		for i in range(0, walls.size(), 3):
			var w := walls[i]
			var d := Vector2(w.global_basis.x.x, w.global_basis.x.z).normalized()
			var n := Vector2(-d.y, d.x)
			var length := 4.0 if "4m" in w.name else 2.0
			var mid := Vector2(w.global_position.x, w.global_position.z)+d*length/2.0
			for side in [1.0, -1.0]:
				var from: Vector2 = mid+n*side*2.4
				var to: Vector2 = mid-n*side*2.4
				await put(from)
				if (flat_pos()-from).length() > .8: continue     # start spot not standable (bank, prop)
				tried += 1
				await walk_to(to, 4.0)
				var signed: float = (flat_pos()-mid).dot(n)*side
				if signed > .5: held += 1
				else: leaks.append([snappedf(mid.x, .1), snappedf(mid.y, .1), side])
		check("%s: the wall stops the player at every tested section, from both sides" % run_node.name, tried > 0 and leaks.is_empty(), {"approaches": tried, "stopped": held, "crossed": leaks})
	# 3. Wall ends: try to walk round each end, from just beside the end pier on one side to the
	# matching point on the other side.
	var ends := []
	for run_node: Node in boundary.get_children():
		var piers: Array[Node3D] = []
		for c: Node3D in run_node.get_children():
			if c.name.ends_with("_pier") or c.name.ends_with("_gate_end"): piers.append(c)
		var outcrops: Array[Node3D] = []
		for c: Node3D in run_node.get_children():
			if c.name.ends_with("_outcrop"): outcrops.append(c)
		for o: Node3D in outcrops:
			# The end pier is the pier nearest to this outcrop.
			var best: Node3D = null
			for p: Node3D in piers:
				if best == null or p.global_position.distance_to(o.global_position) < best.global_position.distance_to(o.global_position): best = p
			var at := Vector2(best.global_position.x, best.global_position.z)
			var d := Vector2(o.global_position.x, o.global_position.z)-at
			d = d.normalized()
			var n := Vector2(-d.y, d.x)
			var a: Vector2 = at-d*1.0+n*2.2
			var b: Vector2 = at-d*1.0-n*2.2
			await put(a)
			var arrived := await walk_to(b, 25.0)
			ends.append({"run": run_node.name, "end": [snappedf(at.x, .1), snappedf(at.y, .1)], "walked_round": arrived})
	print("ENDS ", ends)
	# 4. District paths with the layers, then without them.
	var with_layers := {}
	for pa: Dictionary in layout.paths:
		with_layers[pa.id] = await walk_path(pa.points)
	demo.get_node("DemoBoundary").free()
	demo.get_node("DemoDressing").free()
	for i in 4: await physics_frame
	for pa: Dictionary in layout.paths:
		var base: Array = await walk_path(pa.points)
		var now: Array = with_layers[pa.id]
		check("path '%s' (%s): walked end to end with the boundary and dressing in place%s" % [pa.id, pa.name, "" if base[0] else " (also blocked without them)"],
			now[0] or not base[0], {"with_layers": now, "without_layers": base})
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks": checks.size(), "failures": failures, "wall_ends": ends, "results": checks}, "  "))
	f.close()
	print("TOTAL %d checks, %d failures" % [checks.size(), failures])
	quit(1 if failures else 0)

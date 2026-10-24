extends SceneTree
## Headless Exchange Hall check: import/geometry/materials/collision, measured
## clearances (rays against authored collision AND visible meshes), traversal with
## the unchanged 1.8 m controller in third person, and on every route: an
## upper-body probe and the third-person camera point against the visible meshes.
## godot --headless --fixed-fps 60 --path . --script res://staging/claude_exchange_hall/review/verify_exchange_hall.gd
const ROOT := "res://staging/claude_exchange_hall/"
const ID := "exchange_hall"
const F := .6
const VISUAL := 8   # physics layer holding trimesh copies of the visible meshes
# start, drive, frames, label, pass condition on final position p
const WALKS := [
	[Vector3(0, .05, 13), Vector3(0, 0, -1), 420, "stair, terrace, door, aisle to the exchange counter", "p.z < 4 and p.z > -.7 and p.y > .55"],
	[Vector3(4.15, .65, 3.8), Vector3(0, 0, -1), 360, "staff lane past the counter end to the reward racks", "p.z < -3.5 and p.y > .55"],
	[Vector3(3.9, .65, -2.4), Vector3(1, 0, 0), 300, "east storeroom (supplies) through its side door", "p.x > 9 and p.y > .55"],
	[Vector3(-3.9, .65, -2.4), Vector3(-1, 0, 0), 300, "west storeroom (manuals and treasures) through its side door", "p.x < -9 and p.y > .55"],
	[Vector3(3.85, .65, 7.0), Vector3(0, 0, -1), 160, "front wall reward board blocks", "p.z > 5.3"],
	[Vector3(8.6, .65, 7.0), Vector3(0, 0, -1), 200, "east wing veranda walkable up to the storeroom wall", "p.z > 3.2 and p.z < 4.4 and p.y > .55"],
	[Vector3(-8.6, .65, 7.0), Vector3(0, 0, -1), 200, "west wing veranda walkable up to the storeroom wall", "p.z > 3.2 and p.z < 4.4 and p.y > .55"],
	[Vector3(0, .65, 2.5), Vector3(0, 0, 1), 360, "back out through the door and down the stair", "p.z > 9.8 and p.y < .1"],
]
var results := []
var failed := 0
var space: PhysicsDirectSpaceState3D

func _initialize() -> void:
	run.call_deferred()

func check(label: String, ok: bool, detail: Variant) -> void:
	results.append({"check": label, "pass": ok, "detail": str(detail)})
	if not ok: failed += 1
	print(("PASS " if ok else "FAIL ")+label+"  "+str(detail))

func ray(from: Vector3, dir: Vector3, length: float, mask: int) -> float:
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from+dir*length, mask))
	return from.distance_to(hit.position) if hit else length

func names_hit(query: PhysicsShapeQueryParameters3D) -> Array:
	var out := []
	for h in space.intersect_shape(query, 8):
		out.append(str(h.collider.shape_owner_get_owner(h.collider.shape_find_owner(h.shape)).get_meta("surface")))
	return out

func run() -> void:
	var summary: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"build_summary.json"))[ID]
	var ground := StaticBody3D.new()
	var plane := BoxShape3D.new()
	plane.size = Vector3(200, .1, 200)
	var plane_shape := CollisionShape3D.new()
	plane_shape.shape = plane
	plane_shape.position.y = -.05
	ground.add_child(plane_shape)
	root.add_child(ground)
	var asset: Node3D = load(ROOT+ID+"/"+ID+".tscn").instantiate()
	root.add_child(asset)
	var tris := 0
	var missing := 0
	var textured := 0
	var names := {}
	var box := AABB()
	var first := true
	var visual := StaticBody3D.new()
	visual.collision_layer = VISUAL
	visual.collision_mask = 0
	root.add_child(visual)
	for mi: MeshInstance3D in asset.find_children("*", "MeshInstance3D", true, false):
		for s in mi.mesh.get_surface_count():
			var arrays := mi.mesh.surface_get_arrays(s)
			var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			tris += idx.size()/3 if idx.size() else arrays[Mesh.ARRAY_VERTEX].size()/3
			var mat := mi.mesh.surface_get_material(s) as BaseMaterial3D
			if mat == null: missing += 1
			else:
				names[mat.resource_name] = true
				if mat.albedo_texture or mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED: textured += 1
		var b: AABB = mi.global_transform*mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
		var copy := CollisionShape3D.new()
		copy.shape = mi.mesh.create_trimesh_shape()
		copy.transform = mi.global_transform
		copy.set_meta("surface", mi.name)
		visual.add_child(copy)
	var want: Array = summary.size_xyz_m
	var want_mats: Array = summary.materials
	check("imported triangles match build", tris == int(summary.triangles), [tris, summary.triangles])
	check("imported size matches build (0.05 m)", box.size.distance_to(Vector3(want[0], want[1], want[2])) < .05, [box.size, want])
	check("sits on ground (min y ~ 0)", absf(box.position.y) < .05, box.position.y)
	check("every surface has an opaque untextured material", missing == 0 and textured == 0, [missing, textured])
	check("all palette materials present", names.size() == want_mats.size() and want_mats.all(func(m): return names.has(m)), names.keys())
	var shapes := asset.find_children("*", "CollisionShape3D", true, false).size()
	check("authored collision present", shapes == int(summary.collision_shapes) and shapes > 20, shapes)
	check("plaque text present", asset.find_children("*", "Label3D", true, false).size() == 1, summary.plaques)
	for i in 3: await physics_frame
	space = root.get_world_3d().direct_space_state
	var clear := {}
	for mask_name in ["collision", "visible"]:
		var m := 1 if mask_name == "collision" else VISUAL
		clear[mask_name] = {
			"main_door_width_at_wall": ray(Vector3(0, F+1, 5), Vector3.LEFT, 4, m)+ray(Vector3(0, F+1, 5), Vector3.RIGHT, 4, m),
			"main_door_width_inside_leaves": ray(Vector3(0, F+1, 4.4), Vector3.LEFT, 4, m)+ray(Vector3(0, F+1, 4.4), Vector3.RIGHT, 4, m),
			"main_door_headroom": ray(Vector3(0, F+.05, 5), Vector3.UP, 8, m)+.05,
			"door_canopy_headroom": ray(Vector3(0, F+.05, 6.2), Vector3.UP, 8, m)+.05,
			"aisle_width_between_plinths": ray(Vector3(0, F+1, 2.6), Vector3.LEFT, 6, m)+ray(Vector3(0, F+1, 2.6), Vector3.RIGHT, 6, m),
			"counter_end_lane_width": ray(Vector3(4.15, F+1, -1.2), Vector3.LEFT, 4, m)+ray(Vector3(4.15, F+1, -1.2), Vector3.RIGHT, 4, m),
			"storeroom_door_width": ray(Vector3(5, F+1, -2.4), Vector3.FORWARD, 3, m)+ray(Vector3(5, F+1, -2.4), Vector3.BACK, 3, m),
			"storeroom_door_width_inside_leaves": ray(Vector3(5.5, F+1, -2.4), Vector3.FORWARD, 3, m)+ray(Vector3(5.5, F+1, -2.4), Vector3.BACK, 3, m),
			"storeroom_door_headroom": ray(Vector3(5, F+.05, -2.4), Vector3.UP, 8, m)+.05,
			"storeroom_lane_width": ray(Vector3(8.5, F+1, -2.4), Vector3.FORWARD, 6, m)+ray(Vector3(8.5, F+1, -2.4), Vector3.BACK, 6, m),
			"wing_veranda_headroom": ray(Vector3(8.6, F+.05, 4.0), Vector3.UP, 8, m)+.05,
			"pavilion_clear_height": ray(Vector3(0, F+.05, 0), Vector3.UP, 12, m)+.05,
		}
	for key: String in clear.collision:
		var need := 2.1 if "headroom" in key or "height" in key else .9
		check("clearance "+key+" >= %.1f m (collision / visible)" % need, minf(clear.collision[key], clear.visible[key]) >= need, "%.2f / %.2f" % [clear.collision[key], clear.visible[key]])
	var body_probe := CapsuleShape3D.new()
	body_probe.radius = .24
	body_probe.height = 1.35
	var probe := PhysicsShapeQueryParameters3D.new()
	probe.shape = body_probe
	probe.collision_mask = VISUAL
	var eye_ball := SphereShape3D.new()
	eye_ball.radius = .1
	var cam_probe := PhysicsShapeQueryParameters3D.new()
	cam_probe.shape = eye_ball
	cam_probe.collision_mask = VISUAL
	for walk: Array in WALKS:
		var player := CharacterBody3D.new()
		player.set_script(load("res://scripts/training_inspection_player.gd"))
		player.automated = true
		player.position = walk[0]
		root.add_child(player)
		player.third_person = true
		player.drive = walk[1]
		var body_hits := {}
		var cam_hits := {}
		var samples := 0
		for i in int(walk[2]):
			await physics_frame
			if i % 5 == 0:
				samples += 1
				probe.transform = Transform3D(Basis(), player.global_position+Vector3(0, 1.175, 0))
				for n in names_hit(probe): body_hits[n] = true
				cam_probe.transform = Transform3D(Basis(), player.camera.global_position)
				for n in names_hit(cam_probe): cam_hits[n] = true
		var p := player.global_position
		var expr := Expression.new()
		expr.parse(walk[4], ["p"])
		check("walk: "+walk[3], bool(expr.execute([p])), p)
		check("walk: no visible geometry inside the upper body (%d samples): %s" % [samples, walk[3]], body_hits.is_empty(), body_hits.keys())
		check("walk: third-person camera never inside visible geometry (%d samples): %s" % [samples, walk[3]], cam_hits.is_empty(), cam_hits.keys())
		player.queue_free()
		await physics_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/codex-exchange-hall/staged-basic"))
	var out := FileAccess.open("res://reports/codex-exchange-hall/staged-basic/verify-results.json", FileAccess.WRITE)
	out.store_string(JSON.stringify({"passed": results.size()-failed, "failed": failed, "clearances_m": clear, "results": results}, "  "))
	out.close()
	print("%d PASS / %d FAIL" % [results.size()-failed, failed])
	quit(1 if failed else 0)

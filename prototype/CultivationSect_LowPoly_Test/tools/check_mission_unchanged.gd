extends SceneTree
## Headless Mission Hall check: import/geometry/materials/collision, measured
## entrance clearances (rays against authored collision AND against the visible
## meshes), walk routes with the unchanged 1.8 m controller, and upper-body
## clearance of visible geometry sampled along every route.
## godot --headless --fixed-fps 60 --path . --script res://staging/claude_mission_hall/review/verify_mission_hall.gd
const ROOT := "res://staging/claude_mission_hall/"
const ID := "mission_hall"
const F := .75
const VISUAL := 8   # physics layer holding trimesh copies of the visible meshes
# start, drive, frames, label, pass condition on final position p
const WALKS := [
	[Vector3(0, .05, 15), Vector3(0, 0, -1), 420, "stair, forecourt, porch, door, aisle to the reporting counter", "p.z < 0 and p.z > -2.6 and p.y > .7"],
	[Vector3(5.6, .8, 2.8), Vector3(0, 0, -1), 360, "side passage past the counter into the officials' area", "p.z < -6 and p.y > .7"],
	[Vector3(2.6, .8, 5.0), Vector3(0, 0, -1), 160, "front wall and notice board block beside the door", "p.z > 3.7"],
	[Vector3(3.0, .8, 8.3), Vector3(1, 0, 0), 160, "forecourt mission board blocks", "p.x < 6.1 and p.x > 5.0"],
	[Vector3(0, .8, 1.0), Vector3(0, 0, 1), 360, "walk back out through the door and down the stair", "p.z > 11.6 and p.y < .1"],
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
	var q := PhysicsRayQueryParameters3D.create(from, from+dir*length, mask)
	var hit := space.intersect_ray(q)
	return from.distance_to(hit.position) if hit else length

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
	var asset: Node3D = load("res://scenes/buildings/mission_hall.tscn").instantiate()
	root.add_child(asset)
	# Geometry, materials, collision, plaque.
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
	# Entrance clearance, measured against collision (mask 1) and visible meshes.
	var clear := {}
	for mask_name in ["collision", "visible"]:
		var m := 1 if mask_name == "collision" else VISUAL
		clear[mask_name] = {
			"door_width_at_wall": ray(Vector3(0, F+1, 3.5), Vector3.LEFT, 4, m)+ray(Vector3(0, F+1, 3.5), Vector3.RIGHT, 4, m),
			"door_width_inside_leaves": ray(Vector3(0, F+1, 2.6), Vector3.LEFT, 4, m)+ray(Vector3(0, F+1, 2.6), Vector3.RIGHT, 4, m),
			"door_headroom": ray(Vector3(0, F+.05, 3.5), Vector3.UP, 8, m)+.05,
			"porch_central_bay_width": ray(Vector3(0, F+1, 5.75), Vector3.LEFT, 4, m)+ray(Vector3(0, F+1, 5.75), Vector3.RIGHT, 4, m),
			"porch_headroom_under_plaque": ray(Vector3(0, F+.05, 5.94), Vector3.UP, 8, m)+.05,
			"forecourt_width_between_boards": ray(Vector3(0, F+1, 8.3), Vector3.LEFT, 12, m)+ray(Vector3(0, F+1, 8.3), Vector3.RIGHT, 12, m),
			"side_passage_width": ray(Vector3(5.6, F+1, -3.0), Vector3.LEFT, 4, m)+ray(Vector3(5.6, F+1, -3.0), Vector3.RIGHT, 4, m),
			"interior_clear_height_at_aisle": ray(Vector3(0, F+.05, 0), Vector3.UP, 12, m)+.05,
		}
	for key: String in clear.collision:
		var need := 2.1 if "headroom" in key or "height" in key else .9
		check("clearance "+key+" >= %.1f m (collision / visible)" % need, minf(clear.collision[key], clear.visible[key]) >= need, "%.2f / %.2f" % [clear.collision[key], clear.visible[key]])
	# Walk routes with the unchanged controller, sampling visible-mesh intersections
	# with an upper-body capsule (0.5-1.85 m above the feet, radius 0.24).
	var body_probe := CapsuleShape3D.new()
	body_probe.radius = .24
	body_probe.height = 1.35
	var probe := PhysicsShapeQueryParameters3D.new()
	probe.shape = body_probe
	probe.collision_mask = VISUAL
	for walk: Array in WALKS:
		var player := CharacterBody3D.new()
		player.set_script(load("res://scripts/training_inspection_player.gd"))
		player.automated = true
		player.position = walk[0]
		root.add_child(player)
		player.drive = walk[1]
		var hits := {}
		for i in int(walk[2]):
			await physics_frame
			if i % 5 == 0:
				probe.transform = Transform3D(Basis(), player.global_position+Vector3(0, 1.175, 0))
				for h in space.intersect_shape(probe, 8):
					hits[str(h.collider.shape_owner_get_owner(h.collider.shape_find_owner(h.shape)).get_meta("surface"))] = true
		var p := player.global_position
		var expr := Expression.new()
		expr.parse(walk[4], ["p"])
		check("walk: "+walk[3], bool(expr.execute([p])), p)
		check("walk: no visible geometry inside the upper body along: "+walk[3], hits.is_empty(), hits.keys())
		player.queue_free()
		await physics_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/codex-exchange-hall/mission-regression"))
	var out := FileAccess.open("res://reports/codex-exchange-hall/mission-regression/verify-results.json", FileAccess.WRITE)
	out.store_string(JSON.stringify({"passed": results.size()-failed, "failed": failed, "clearances_m": clear, "results": results}, "  "))
	out.close()
	print("%d PASS / %d FAIL" % [results.size()-failed, failed])
	quit(1 if failed else 0)

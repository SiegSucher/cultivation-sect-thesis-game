extends SceneTree
## Headless check for batch 2: each scene loads with geometry, materials and
## collision, and the unchanged 1.8 m inspection controller can walk the routes.
## godot --headless --fixed-fps 60 --path . --script res://staging/claude_buildings_batch2/review/verify_claude_batch2.gd
const ROOT := "res://staging/claude_buildings_batch2/"
# id, start, drive, frames, label, pass condition on final position p
const WALKS := [
	["alchemy_pavilion", Vector3(0, .05, 12), Vector3(0, 0, -1), 300, "stair, veranda and door into furnace room", "p.z < 4.8 and p.z > 1.9 and p.y > .85"],
	["alchemy_pavilion", Vector3(1.9, .95, 6.3), Vector3(0, 0, -1), 200, "solid front wall beside the door blocks", "p.z > 5.3"],
	["alchemy_pavilion", Vector3(0, .95, 3.5), Vector3(0, 0, -1), 200, "furnace dais blocks (no walking through the cauldron)", "p.z > 2.0"],
	["medicine_hall", Vector3(0, .05, 10), Vector3(0, 0, -1), 300, "stair and central entrance into shop floor", "p.z < 4.0 and p.z > -1.5 and p.y > .4"],
	["medicine_hall", Vector3(-3.2, .5, 5.6), Vector3(0, 0, -1), 160, "serving counter blocks entry", "p.z > 4.6"],
	["medicine_hall", Vector3(-7.15, .5, 3.9), Vector3(0, 0, -1), 420, "interior stair climbs to the loft", "p.y > 4.1 and p.z < -2.5"],
	["medicine_hall", Vector3(0, 4.3, 0), Vector3(0, 0, 1), 240, "loft door onto balcony, railing holds", "p.y > 4.1 and p.z > 4.7 and p.z < 5.6"],
]
var results := []
var failed := 0

func _initialize() -> void:
	run.call_deferred()

func check(label: String, ok: bool, detail: Variant) -> void:
	results.append({"check": label, "pass": ok, "detail": str(detail)})
	if not ok: failed += 1
	print(("PASS " if ok else "FAIL ")+label+"  "+str(detail))

func ground() -> StaticBody3D:
	var body := StaticBody3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200, .1, 200)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position.y = -.05
	body.add_child(shape)
	return body

func run() -> void:
	var summary: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"build_summary.json"))
	for id: String in summary:
		var asset: Node3D = load("res://scenes/buildings/"+id+".tscn").instantiate()
		root.add_child(asset)
		var tris := 0
		var missing := 0
		var textured := 0
		var names := {}
		var box := AABB()
		var first := true
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
		var shapes := asset.find_children("*", "CollisionShape3D", true, false).size()
		var want: Array = summary[id].size_xyz_m
		var want_mats: Array = summary[id].materials
		check(id+" imported triangles match build", tris == int(summary[id].triangles), [tris, summary[id].triangles])
		check(id+" imported size matches build (0.05 m)", box.size.distance_to(Vector3(want[0], want[1], want[2])) < .05, [box.size, want])
		check(id+" sits on ground (min y ~ 0)", absf(box.position.y) < .05, box.position.y)
		check(id+" every surface has an opaque untextured material", missing == 0 and textured == 0, [missing, textured])
		check(id+" all palette materials present", names.size() == want_mats.size() and want_mats.all(func(m): return names.has(m)), names.keys())
		check(id+" authored collision plus documented corrections", shapes == int(summary[id].collision_shapes)+(1 if id=="medicine_hall" else 2), shapes)
		check(id+" has plaque text", asset.find_children("*", "Label3D", true, false).size() == 1, summary[id].plaques)
		asset.queue_free()
		await process_frame
	for walk: Array in WALKS:
		var asset: Node3D = load("res://scenes/buildings/"+walk[0]+".tscn").instantiate()
		root.add_child(asset)
		var floor_body := ground()
		root.add_child(floor_body)
		var player := CharacterBody3D.new()
		player.set_script(load("res://scripts/training_inspection_player.gd"))
		player.automated = true
		player.position = walk[1]
		root.add_child(player)
		for body: StaticBody3D in asset.find_children("*", "StaticBody3D", true, false):
			if body.is_in_group("camera_only_obstruction"): player.add_collision_exception_with(body)
		player.drive = walk[2]
		for i in int(walk[3]): await physics_frame
		var p := player.global_position
		var expr := Expression.new()
		expr.parse(walk[5], ["p"])
		check(walk[0]+" walk: "+walk[4], bool(expr.execute([p])), p)
		for n: Node in [asset, floor_body, player]: n.queue_free()
		await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/codex-alchemy-medicine/canonical-basic"))
	var out := FileAccess.open("res://reports/codex-alchemy-medicine/canonical-basic/verify-results.json", FileAccess.WRITE)
	out.store_string(JSON.stringify({"passed": results.size()-failed, "failed": failed, "results": results}, "  "))
	out.close()
	print("%d PASS / %d FAIL" % [results.size()-failed, failed])
	quit(1 if failed else 0)

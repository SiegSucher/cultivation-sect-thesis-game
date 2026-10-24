extends SceneTree
## Headless check: each staged scene loads, has geometry + collision, and the
## unchanged 1.8 m inspection controller can walk in through the entrance.
## godot --headless --path . --script res://staging/claude_buildings/review/verify_claude_buildings.gd
const ROOT := "res://staging/claude_buildings/"
# id, start, drive direction, frames, pass condition on final position
const WALKS := [
	["disciple_residence", Vector3(2.2, .05, 8), 240, "room 2 reached", "p.z < 1.5 and p.y > .4"],
	["disciple_residence", Vector3(1.0, .05, 8), 240, "solid wall between doors blocks", "p.z > 2.2 and p.z < 2.6"],
	["elder_residence", Vector3(0, .05, 14), 420, "gate, stair, main room reached", "p.z < -3.0 and p.y > .9"],
	["dining_hall_kitchen", Vector3(0, .05, 11), 480, "dining hall and kitchen reached", "p.z < -6.0 and p.y > .5"],
	["spirit_herb_garden", Vector3(0, .05, 15), 200, "garden gate passable", "p.z < 11.0 and p.z > 3.0"],
	["spirit_herb_garden", Vector3(0, .05, -3.6), 240, "pavilion stair climbable", "p.z < -5.5 and p.y > .4"],
]
var results := []
var failed := 0

func _initialize() -> void:
	run.call_deferred()

func check(label: String, ok: bool, detail: Variant) -> void:
	results.append({"check": label, "pass": ok, "detail": detail})
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
		var asset: Node3D = load(ROOT+id+"/"+id+".tscn").instantiate()
		root.add_child(asset)
		var tris := 0
		var box := AABB()
		var first := true
		for mi: MeshInstance3D in asset.find_children("*", "MeshInstance3D", true, false):
			for s in mi.mesh.get_surface_count():
				var arrays := mi.mesh.surface_get_arrays(s)
				var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				tris += idx.size()/3 if idx.size() else arrays[Mesh.ARRAY_VERTEX].size()/3
			var b: AABB = mi.global_transform*mi.get_aabb()
			box = b if first else box.merge(b)
			first = false
		var shapes := asset.find_children("*", "CollisionShape3D", true, false).size()
		var want: Array = summary[id].size_xyz_m
		check(id+" imported triangles match build", tris == int(summary[id].triangles), [tris, summary[id].triangles])
		check(id+" imported size matches build (0.05 m)", box.size.distance_to(Vector3(want[0], want[1], want[2])) < .05, [box.size, want])
		check(id+" sits on ground (min y ~ 0)", absf(box.position.y) < .05, box.position.y)
		check(id+" has authored collision", shapes == int(summary[id].collision_shapes) and shapes > 10, shapes)
		asset.queue_free()
		await process_frame
	for walk: Array in WALKS:
		var asset: Node3D = load(ROOT+walk[0]+"/"+walk[0]+".tscn").instantiate()
		root.add_child(asset)
		var floor_body := ground()
		root.add_child(floor_body)
		var player := CharacterBody3D.new()
		player.set_script(load("res://scripts/training_inspection_player.gd"))
		player.automated = true
		player.position = walk[1]
		root.add_child(player)
		player.drive = Vector3(0, 0, -1)
		for i in int(walk[2]): await physics_frame
		var p := player.global_position
		var expr := Expression.new()
		expr.parse(walk[4], ["p"])
		check(walk[0]+" walk: "+walk[3], bool(expr.execute([p])), p)
		for n: Node in [asset, floor_body, player]: n.queue_free()
		await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/claude-assets"))
	var out := FileAccess.open("res://reports/claude-assets/verify-results.json", FileAccess.WRITE)
	out.store_string(JSON.stringify({"passed": results.size()-failed, "failed": failed, "results": results}, "  "))
	out.close()
	print("%d PASS / %d FAIL" % [results.size()-failed, failed])
	quit(1 if failed else 0)

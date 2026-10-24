extends SceneTree
## Headless checks for environment batch 1 with the unchanged 1.8 m inspection controller.
## godot --headless --fixed-fps 60 --path . --script res://staging/claude_environment_batch1/review/verify_environment_batch1.gd -- <out.json>
const ROOT := "res://staging/claude_environment_batch1/"
const IDS := ["pine_windswept", "pine_tiered", "bamboo_cluster", "flowering_shrub", "grass_tuft", "rock_cluster",
	"rock_outcrop", "stone_lantern", "sect_banner", "training_dummy_rack", "stone_bench"]
const BRUSH_THROUGH := ["flowering_shrub", "grass_tuft"]
const TREES := ["pine_windswept", "pine_tiered", "bamboo_cluster"]
const VIS := 512
var results := []
var failures := 0

func _initialize() -> void:
	run()

func check(asset: String, name: String, ok: bool, detail) -> void:
	results.append({"asset": asset, "check": name, "pass": ok, "detail": detail})
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+asset+" | "+name+" | "+str(detail))

func run() -> void:
	await process_frame   # the tree is not live during _initialize
	for id: String in IDS:
		await verify(id)
	var out := OS.get_cmdline_user_args()[0]
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify({"failures": failures, "checks": results.size(), "results": results}, "  "))
	f.close()
	print("TOTAL %d checks, %d failures" % [results.size(), failures])
	quit(1 if failures else 0)

func verify(id: String) -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var ground := StaticBody3D.new()
	var gs := CollisionShape3D.new()
	var gb := BoxShape3D.new()
	gb.size = Vector3(80, .1, 80)
	gs.shape = gb
	gs.position.y = -.062
	ground.add_child(gs)
	stage.add_child(ground)
	var inst: Node3D = load(ROOT+id+"/"+id+".tscn").instantiate()
	stage.add_child(inst)
	# Visible geometry: triangles, materials, bounds, and a collision copy on layer 10.
	var tris := 0
	var mats := {}
	var lo := Vector3.INF
	var hi := -Vector3.INF
	var faces := PackedVector3Array()
	for m: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
		for s in m.mesh.get_surface_count():
			var arr := m.mesh.surface_get_arrays(s)
			tris += (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size()/3
			mats[m.mesh.surface_get_material(s).resource_name] = true
		for v in m.mesh.get_faces():
			var w := m.global_transform*v
			faces.append(w)
			lo = lo.min(w)
			hi = hi.max(w)
	var vis := StaticBody3D.new()
	vis.collision_layer = VIS
	vis.collision_mask = 0
	var vshape := ConcavePolygonShape3D.new()
	vshape.backface_collision = true
	vshape.set_faces(faces)
	var vcs := CollisionShape3D.new()
	vcs.shape = vshape
	vis.add_child(vcs)
	stage.add_child(vis)
	var shapes := inst.find_children("*", "CollisionShape3D", true, false)
	var clo := Vector3.INF
	var chi := -Vector3.INF
	for cs: CollisionShape3D in shapes:
		var box := cs.shape.get_debug_mesh().get_aabb()
		for i in 8:
			var w := cs.global_transform*box.get_endpoint(i)
			clo = clo.min(w)
			chi = chi.max(w)
	for i in 3: await physics_frame
	var space := root.get_world_3d().direct_space_state
	var size := hi-lo
	check(id, "imports and instances", tris > 0, {"triangles": tris, "materials": mats.keys().size(), "size_m": [snappedf(size.x, .01), snappedf(size.y, .01), snappedf(size.z, .01)]})
	check(id, "pivot on the ground (lowest point within -0.25..0.02 m)", lo.y > -.25 and lo.y < .02, snappedf(lo.y, .001))
	check(id, "pivot inside the footprint", lo.x < 0 and hi.x > 0 and lo.z < 0 and hi.z > 0, {"x": [snappedf(lo.x, .01), snappedf(hi.x, .01)], "z": [snappedf(lo.z, .01), snappedf(hi.z, .01)]})
	var brush := id in BRUSH_THROUGH
	check(id, "collision policy ("+("none: brush-through" if brush else "solid")+")", (shapes.size() == 0) == brush, shapes.size())
	if not brush:
		var inside := clo.x >= lo.x-.05 and clo.z >= lo.z-.05 and chi.x <= hi.x+.05 and chi.z <= hi.z+.05 and chi.y <= hi.y+.05
		check(id, "collision stays within visible bounds (no invisible walls)", inside, {"collision_min": [snappedf(clo.x, .01), snappedf(clo.y, .01), snappedf(clo.z, .01)], "collision_max": [snappedf(chi.x, .01), snappedf(chi.y, .01), snappedf(chi.z, .01)]})
	# Walk straight at the pivot from four sides with the real controller. Track the
	# closest approach: brush-through assets let the body reach the pivot, solid ones do not.
	var ex: Array[RID] = [ground.get_rid()]
	var reach := maxf(maxf(-lo.x, hi.x), maxf(-lo.z, hi.z))+1.5
	var closest := []
	var on_top := 0
	for k in 4:
		var dir := Vector3(cos(k*PI/2+.3), 0, sin(k*PI/2+.3))
		var p := CharacterBody3D.new()
		p.set_script(load("res://scripts/training_inspection_player.gd"))
		p.automated = true
		p.position = -dir*reach+Vector3(0, .05, 0)
		stage.add_child(p)
		p.drive = dir
		var best := 99.0
		for frame in roundi(reach*2/4.0*60)+30:
			await physics_frame
			best = minf(best, Vector2(p.global_position.x, p.global_position.z).length())
		closest.append(snappedf(best, .01))
		if p.global_position.y > .3: on_top += 1
		p.queue_free()
		await physics_frame
	if brush: check(id, "player walks through the pivot from all four sides", closest.max() < .1, closest)
	else: check(id, "player is kept off the pivot from all four sides", closest.min() > .25, {"closest_m": closest, "ended_on_top": on_top})
	var body := CapsuleShape3D.new()
	body.radius = .28
	body.height = 1.8
	# Standing spots touching the asset (capsule fits, but an inflated capsule reaches its collision):
	# visible mesh must not enter the visible avatar's upper body (radius 0.20, 0.9-1.8 m).
	if not brush:
		var reach_probe := CapsuleShape3D.new()
		reach_probe.radius = .28+.3
		reach_probe.height = 1.8+.6
		var upper := CapsuleShape3D.new()
		upper.radius = .2
		upper.height = .9
		var spots := 0
		var clips := []
		var x := lo.x-.6
		while x <= hi.x+.6:
			var z := lo.z-.6
			while z <= hi.z+.6:
				var at := Vector3(x, 1.02, z)
				if not overlaps(space, body, at, 1, ex) and overlaps(space, reach_probe, at, 1, ex):
					spots += 1
					if overlaps(space, upper, Vector3(x, 1.35, z), VIS, []): clips.append([snappedf(x, .01), snappedf(z, .01)])
				z += .25
			x += .25
		check(id, "standing against it, visible mesh never enters the avatar's upper body", clips.is_empty(), {"spots_tested": spots, "clipping_spots": clips.slice(0, 8)})
	if id in TREES:
		var lowest := 99.0
		var x := lo.x
		while x <= hi.x:
			var z := lo.z
			while z <= hi.z:
				if not overlaps(space, body, Vector3(x, 1.02, z), 1, ex):
					var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, .3, z), Vector3(x, 20, z), VIS))
					if not hit.is_empty(): lowest = minf(lowest, hit.position.y)
				z += .25
			x += .25
		check(id, "foliage and branches over walkable ground are above head height (>= 2.2 m)", lowest >= 2.2, snappedf(lowest, .01))
	stage.queue_free()
	await process_frame

func overlaps(space: PhysicsDirectSpaceState3D, shape: Shape3D, at: Vector3, mask: int, exclude: Array[RID]) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = Transform3D(Basis(), at)
	q.collision_mask = mask
	q.exclude = exclude
	return space.intersect_shape(q, 1).size() > 0

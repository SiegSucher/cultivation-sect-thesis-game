extends SceneTree
## Proportionate checks for the safety kit with the unchanged inspection controller.
## godot --headless --fixed-fps 60 --path . --script res://staging/claude_environment_safety_kit/review/verify_safety_kit.gd -- <out.json>
const KIT := "res://staging/claude_environment_safety_kit/"
const VIS := 512
const T22 := 0.404026   # tan 22 deg
# Expected visible bounds [min, max] per module (connection conventions, metres).
const BOUNDS := {
	"walls/wall_section_2m": [Vector3(0, 0, -.38), Vector3(2, 2.7, .38)],
	"walls/wall_section_4m": [Vector3(0, 0, -.38), Vector3(4, 2.7, .38)],
	"walls/wall_pier": [Vector3(-.57, 0, -.57), Vector3(.57, 3.31, .57)],
	"walls/wall_corner": [Vector3(-.67, 0, -.67), Vector3(.67, 3.46, .67)],
	"walls/wall_gate_end": [Vector3(-.11, 0, -.45), Vector3(.73, 3.24, .45)],
	"railings/rail_section_1m": [Vector3(-.15, -.05, -.15), Vector3(.88, 1.34, .15)],
	"railings/rail_section_2m": [Vector3(-.15, -.05, -.15), Vector3(1.88, 1.34, .15)],
	"railings/rail_post": [Vector3(-.15, -.05, -.15), Vector3(.15, 1.34, .15)],
	"retaining/retaining_wall_4x2": [Vector3(0, 0, -.62), Vector3(4, 2, .06)],
	"retaining/retaining_wall_4x4": [Vector3(0, 0, -.62), Vector3(4, 4, .06)],
	"retaining/retaining_corner_2": [Vector3(-.7, 0, -.7), Vector3(.1, 2, .1)],
	"retaining/retaining_end_2": [Vector3(-.4, 0, -.7), Vector3(.4, 2, .1)],
	"edging/edging_2m": [Vector3(.008, -.04, -.09), Vector3(1.992, .14, .09)],
}
var results := []
var failures := 0
var space: PhysicsDirectSpaceState3D
var review: Node3D

func _initialize() -> void:
	run()

func check(name: String, ok: bool, detail) -> void:
	results.append({"check": name, "pass": ok, "detail": detail})
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+name+" | "+str(detail))

func run() -> void:
	await process_frame
	await module_conventions()
	review = load(KIT+"review/safety_kit_review.tscn").instantiate()
	root.add_child(review)
	for i in 6: await physics_frame
	visible_copy()
	for i in 3: await physics_frame
	space = root.get_world_3d().direct_space_state
	check("review scene opens", review.get_child_count() > 100, review.get_child_count())
	continuity()
	await walks()
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_string(JSON.stringify({"failures": failures, "checks": results.size(), "results": results}, "  "))
	f.close()
	print("TOTAL %d checks, %d failures" % [results.size(), failures])
	quit(1 if failures else 0)

func mesh_bounds(n: Node) -> AABB:
	var lo := Vector3.INF
	var hi := -Vector3.INF
	for m: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
		for v in m.mesh.get_faces():
			var w: Vector3 = m.global_transform*v
			lo = lo.min(w)
			hi = hi.max(w)
	return AABB(lo, hi-lo)

func module_conventions() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	for path: String in BOUNDS:
		var n: Node3D = load(KIT+path+".tscn").instantiate()
		stage.add_child(n)
		var b := mesh_bounds(n)
		var want: Array = BOUNDS[path]
		var err := maxf((b.position-want[0]).abs()[(b.position-want[0]).abs().max_axis_index()], (b.end-want[1]).abs()[(b.end-want[1]).abs().max_axis_index()])
		check("module bounds match connection convention: "+path, err < .012 and n.transform == Transform3D.IDENTITY, {"min": b.position, "max": b.end, "max_error_m": snappedf(err, .0001)})
		n.queue_free()
	# Stair sections: the top rail ends 1.10 m above the pitch line at the next post face.
	for deg in [22, 24]:
		for L in [1, 2]:
			var n: Node3D = load(KIT+"railings/rail_stair_%ddeg_%dm.tscn" % [deg, L]).instantiate()
			stage.add_child(n)
			var b := mesh_bounds(n)
			var expect: float = (L-.12)*tan(deg_to_rad(deg))+1.10
			check("stair rail %d deg %d m ends at the next post face, 1.10 m above the pitch line" % [deg, L], absf(b.end.x-(L-.12)) < .005 and absf(b.end.y-expect) < .005, {"end_x": snappedf(b.end.x, .001), "top_y": snappedf(b.end.y, .001), "expected_top_y": snappedf(expect, .001)})
			n.queue_free()
	await process_frame
	stage.queue_free()

func visible_copy() -> void:
	# Kit and building meshes only (review boxes, figures and labels are excluded).
	var faces := PackedVector3Array()
	for m: MeshInstance3D in review.find_children("*", "MeshInstance3D", true, false):
		if m.mesh is PrimitiveMesh or m.mesh == null or m.visibility_range_begin > 0: continue
		for v in m.mesh.get_faces(): faces.append(m.global_transform*v)
	var body := StaticBody3D.new()
	body.collision_layer = VIS
	body.collision_mask = 0
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	root.add_child(body)

func ray_depth(from: Vector3, to: Vector3) -> float:
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, VIS))
	return -1.0 if hit.is_empty() else from.distance_to(hit.position)

func sweep(name: String, origin: Callable, dir: Vector3, t0: float, t1: float, tolerance: float) -> void:
	# Rays every 2 cm along a run; a gap shows as a miss, a misaligned join as a depth jump.
	var misses := 0
	var lo := INF
	var hi := -INF
	var n := 0
	var t := t0
	while t <= t1:
		var o: Vector3 = origin.call(t)
		var d := ray_depth(o, o+dir*4.0)
		if d < 0: misses += 1
		else:
			lo = minf(lo, d)
			hi = maxf(hi, d)
		n += 1
		t += .02
	check("continuous run (no gaps, faces aligned across joints): "+name, misses == 0 and hi-lo <= tolerance, {"samples": n, "misses": misses, "depth_range_m": snappedf(hi-lo, .0001)})

func continuity() -> void:
	# Wall: gate abutment -> 4 m -> 4 m -> pier -> 2 m, stone dado and plaster, between piers.
	sweep("boundary wall dado, gate end to pier", func(t: float) -> Vector3: return Vector3(t, .4, -27.0), Vector3(0, 0, -1), -13.85, -6.5, .001)
	sweep("boundary wall plaster, gate end to pier", func(t: float) -> Vector3: return Vector3(t, 1.6, -27.0), Vector3(0, 0, -1), -13.85, -6.5, .001)
	sweep("boundary wall tile cap, across section joint", func(t: float) -> Vector3: return Vector3(t, 3.2, -30.0), Vector3(0, -1, 0), -13.8, -6.5, .02)
	# Platform front guardrail: plinth face is flush with the posts across five joints.
	sweep("platform guardrail plinth across posts", func(t: float) -> Vector3: return Vector3(t, 2.08, 0.0), Vector3(0, 0, -1), 10.82, 17.7, .001)
	sweep("platform guardrail top rail between posts", func(t: float) -> Vector3: return Vector3(t, 3.5, -2.18), Vector3(0, -1, 0), 11.0, 12.6, .001)
	# 22 deg stair, right rail: top rail sampled 1.04 m above the pitch line along 5 m of run.
	for seg in [[-5.8, -4.2], [-7.8, -6.2]]:     # between the posts at z = -4, -6, -8
		sweep("22 deg stair rail top rail follows the slope, z %s..%s" % seg, func(t: float) -> Vector3: return Vector3(-12.5, (-4.0-t)*T22+2.0, t), Vector3(0, -1, 0), seg[0], seg[1], .03)
	# Retaining platform face: joints are 3 cm recesses, so allow up to 7 cm depth variation but no holes.
	sweep("retaining wall face across the module joint", func(t: float) -> Vector3: return Vector3(t, 1.0, 1.0), Vector3(0, 0, -1), 10.4, 17.3, .075)

func walker(at: Vector3) -> CharacterBody3D:
	var p := CharacterBody3D.new()
	p.set_script(load("res://scripts/training_inspection_player.gd"))
	p.automated = true
	p.position = at
	root.add_child(p)
	return p

func walk(at: Vector3, dir: Vector3, seconds: float) -> Dictionary:
	var p := walker(at)
	p.drive = dir.normalized()
	var upper := CapsuleShape3D.new()
	upper.radius = .2         # the visible inspection avatar
	upper.height = .9
	var clips := 0
	var low_y := INF
	for frame in roundi(seconds*60):
		await physics_frame
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = upper
		q.transform = Transform3D(Basis(), p.global_position+Vector3(0, 1.35, 0))
		q.collision_mask = VIS
		if space.intersect_shape(q, 1).size() > 0: clips += 1
		low_y = minf(low_y, p.global_position.y)
	var end := p.global_position
	p.queue_free()
	await physics_frame
	return {"end": end, "travel": Vector2(end.x-at.x, end.z-at.z).length(), "clip_frames": clips, "lowest_y": snappedf(low_y, .001)}

func walks() -> void:
	var r := await walk(Vector3(-13.5, .05, -28.9), Vector3(1, 0, 0), 2.2)
	check("walks beside the boundary wall past joints and the pier", r.travel > 8.4 and r.clip_frames == 0, r)
	for x in [-11.4, -9.9]:      # mid-section and the 4 m + 4 m joint
		r = await walk(Vector3(x, .05, -27.5), Vector3(0, 0, -1), 2.0)
		check("wall blocks passage at x=%s" % x, r.end.z > -29.45, r)
	r = await walk(Vector3(-14, .05, -2.5), Vector3(0, 0, -1), 2.6)
	check("climbs the 22 deg stair lane to the landing", absf(r.end.y-2.02) < .06 and r.end.z < -9.2, r)
	r = await walk(Vector3(-12.92, .05, -2.5), Vector3(0, 0, -1), 2.6)
	check("climbs along the lane edge beside the rail without snagging or clipping", absf(r.end.y-2.02) < .06 and absf(r.end.x+12.92) < .1 and r.clip_frames == 0, r)
	for z in [-5.3, -7.1]:
		var y: float = (-4.0-z)*T22+.1
		r = await walk(Vector3(-14, y, z), Vector3(1, 0, 0), 1.5)
		check("stair rail stops sideways exit at z=%s" % z, r.end.x < -12.86, r)
	r = await walk(Vector3(14, 2.05, -4.5), Vector3(0, 0, 1), 1.8)
	check("platform guardrail stops the player at the terrace edge", r.end.z < -2.55 and r.lowest_y > 1.95, r)
	r = await walk(Vector3(16.6, 2.05, -3.4), Vector3(1, 0, 1), 1.8)
	check("platform corner holds a diagonal approach", r.end.x < 17.45 and r.end.z < -2.55 and r.lowest_y > 1.95, r)
	r = await walk(Vector3(3.0, .05, 5.0), Vector3(0, 0, -1), 1.0)
	check("open edging is crossed without a snag", r.travel > 3.7 and r.lowest_y > -.02 and r.end.y < .06, r)
	r = await walk(Vector3(2.5, .05, 9.65), Vector3(1, 0, 0), 1.3)
	check("passing the sign post: boards stay above the avatar", r.travel > 4.9 and r.clip_frames == 0, r)

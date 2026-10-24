extends SceneTree
## Focused checks for the two 4/11 arrival-stair rail variants and their review assembly,
## with the unchanged inspection controller.
## godot --headless --fixed-fps 60 --path . --script res://staging/claude_environment_safety_kit/review/verify_arrival_stair_rails.gd -- <out.json>
const KIT := "res://staging/claude_environment_safety_kit/"
const VIS := 512
const S := 4.0/11.0
const T22 := 0.404026   # tan 22 deg, the existing module the profile is compared with
const RAIL_X := 6.35
const FACE := RAIL_X-.12  # lane-side face of plinths, posts and their collision
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
	await modules()
	review = load(KIT+"review/arrival_stair_rails_review.tscn").instantiate()
	root.add_child(review)
	for i in 6: await physics_frame
	visible_copy()
	for i in 3: await physics_frame
	space = root.get_world_3d().direct_space_state
	assembly()
	joins()
	lane_and_collision()
	await walks()
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_string(JSON.stringify({"failures": failures, "checks": results.size(), "results": results}, "  "))
	f.close()
	print("TOTAL %d checks, %d failures" % [results.size(), failures])
	quit(1 if failures else 0)

# ---------------------------------------------------------------- modules on their own
func triangles(n: Node) -> Array:
	"""[[material, a, b, c], ...] in world space."""
	var tris := []
	for m: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
		for s in m.mesh.get_surface_count():
			var arr := m.mesh.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			var mat := m.mesh.surface_get_material(s).resource_name
			for i in range(0, idx.size(), 3):
				tris.append([mat, m.global_transform*v[idx[i]], m.global_transform*v[idx[i+1]], m.global_transform*v[idx[i+2]]])
	return tris

func vertex_keys(tris: Array, keep: Callable, height: Callable) -> Array:
	"""Unique vertices (mm keys) selected by keep(v), with y replaced by height(v)."""
	var keys := {}
	for t: Array in tris:
		for v: Vector3 in t.slice(1):
			if keep.call(v): keys["%d,%d,%d" % [roundi(v.x*1000), roundi(height.call(v)*1000), roundi(v.z*1000)]] = true
	var out := keys.keys()
	out.sort()
	return out

func above_pitch(L: int, slope: float) -> Callable:
	"""Height above the pitch line. Balusters are vertical boxes, so they are measured at their centre x."""
	var a := .12
	var b := L-.12
	var n := maxi(1, roundi((b-a)/.45))
	var centres := []
	for i in n: centres.append(a+(b-a)*(i+1)/(n+1))
	return func(v: Vector3) -> float:
		var x := v.x
		if absf(v.z) < .05:
			for c: float in centres:
				if absf(absf(v.x-c)-.045) < .001: x = c
		return v.y-x*slope

func sorted_keys(d: Dictionary) -> Array:
	var k := d.keys()
	k.sort()
	return k

func shapes(n: Node) -> Array:
	var out := []
	for c: CollisionShape3D in n.get_node("Collision").get_children():
		out.append(c)
	return out

func modules() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	for L in [1, 2]:
		var n: Node3D = load(KIT+"railings/rail_stair_4in11_%dm.tscn" % L).instantiate()
		var ref: Node3D = load(KIT+"railings/rail_stair_22deg_%dm.tscn" % L).instantiate()
		stage.add_child(n)
		stage.add_child(ref)
		var tris := triangles(n)
		var rtris := triangles(ref)
		var name := "rail_stair_4in11_%dm" % L
		# Bounds and endpoint: rail ends at the next post's face, top rail 1.10 m above the pitch line.
		var lo := Vector3.INF
		var hi := -Vector3.INF
		for t: Array in tris:
			for v: Vector3 in t.slice(1):
				lo = lo.min(v)
				hi = hi.max(v)
		var want_hi := Vector3(L-.12, (L-.12)*S+1.10, .15)
		var err := maxf((lo-Vector3(-.15, -.05, -.15)).abs()[(lo-Vector3(-.15, -.05, -.15)).abs().max_axis_index()], (hi-want_hi).abs()[(hi-want_hi).abs().max_axis_index()])
		check(name+": bounds match the leading-post convention, rail ends at the next post face", err < .001 and n.transform == Transform3D.IDENTITY,
			{"min": lo, "max": hi, "expected_max": want_hi, "max_error_m": snappedf(err, .00001)})
		# Pitch from the top rail's two upper edges -> rise at the next post's origin.
		var ya := -INF
		var yb := -INF
		for t: Array in tris:
			if t[0] != "Coping": continue
			for v: Vector3 in t.slice(1):
				if absf(v.x-.12) < 1e-4: ya = maxf(ya, v.y)
				if absf(v.x-(L-.12)) < 1e-4: yb = maxf(yb, v.y)
		var slope: float = (yb-ya)/(L-.24)
		check(name+": top rail pitch is 4/11 and the next post origin rises %.9f m" % (L*S), absf(slope-S) < 1e-5 and absf(ya-(.12*S+1.10)) < 1e-5,
			{"measured_slope": "%.7f" % slope, "expected_slope": "%.7f" % S, "measured_degrees": "%.6f" % rad_to_deg(atan(slope)),
			 "implied_endpoint_rise_m": "%.7f" % (L*slope), "top_rail_at_leading_post_face_m": "%.5f" % ya, "top_rail_at_far_post_face_m": "%.5f" % yb})
		# Same kit profile as the existing 22 deg module: identical post; every span vertex beyond the post,
		# measured from the pitch line, identical; same triangles and materials.
		var post := func(v: Vector3) -> bool: return v.x < .11
		var beyond := func(v: Vector3) -> bool: return v.x > .16
		var plain := func(v: Vector3) -> float: return v.y
		var post_new := vertex_keys(tris, post, plain)
		var post_ref := vertex_keys(rtris, post, plain)
		var span_new := vertex_keys(tris, beyond, above_pitch(L, S))
		var span_ref := vertex_keys(rtris, beyond, above_pitch(L, T22))
		var mats := {}
		var rmats := {}
		for t: Array in tris: mats[t[0]] = true
		for t: Array in rtris: rmats[t[0]] = true
		check(name+": profile, thickness and materials identical to rail_stair_22deg_%dm (measured from the pitch line)" % L,
			post_new == post_ref and span_new == span_ref and tris.size() == rtris.size() and sorted_keys(mats) == sorted_keys(rmats),
			{"triangles": tris.size(), "reference_triangles": rtris.size(), "materials": sorted_keys(mats), "post_vertices": post_new.size(), "span_vertices": span_new.size()})
		# Upright: every face is axis-aligned or lies along the pitch, except the post's pyramid cap.
		var odd := 0
		var pitch_faces := 0
		for t: Array in tris:
			var nrm: Vector3 = (t[2]-t[1]).cross(t[3]-t[1]).normalized()
			var a := nrm.abs()
			if a[a.max_axis_index()] > .99999: continue
			if absf(nrm.z) < 1e-5 and absf(nrm.x+nrm.y*S) < 1e-5:
				pitch_faces += 1
				continue
			var cap: bool = t[0] == "Coping"
			for v: Vector3 in t.slice(1): cap = cap and v.y > 1.239 and absf(v.x) < .151
			if not cap: odd += 1
		check(name+": posts and balusters vertical (only the plinth and top rail follow the pitch)", odd == 0 and pitch_faces > 0, {"tilted_faces": odd, "pitch_faces": pitch_faces})
		# Collision: same post box and body settings; rail slab points at the exact 4/11 pitch,
		# written to 4 significant digits like every kit scene (<= 0.5 mm).
		var cs := shapes(n)
		var rcs := shapes(ref)
		var post_same: bool = cs.size() == 2 and rcs.size() == 2 and cs[0].shape is BoxShape3D and cs[0].shape.size == rcs[0].shape.size and cs[0].position == rcs[0].position
		var pts: PackedVector3Array = cs[1].shape.points
		var rpts: PackedVector3Array = rcs[1].shape.points
		var slab_err := 0.0
		var i := 0
		for x in [.12, L-.12]:
			for dy in [-.05, 1.10]:
				for z in [-.12, .12]:
					slab_err = maxf(slab_err, pts[i].distance_to(Vector3(x, x*S+dy, z)))
					slab_err = maxf(slab_err, Vector2(pts[i].x-rpts[i].x, pts[i].z-rpts[i].z).length())
					i += 1
		var body: StaticBody3D = n.get_node("Collision")
		var rbody: StaticBody3D = ref.get_node("Collision")
		check(name+": collision matches the kit (post box + pitched convex rail slab, solid_world body)",
			post_same and pts.size() == 8 and slab_err <= .0005 and body.collision_layer == rbody.collision_layer and body.collision_mask == rbody.collision_mask and body.is_in_group("solid_world"),
			{"post_box": cs[0].shape.size, "slab_points": pts.size(), "slab_max_error_vs_exact_m": snappedf(slab_err, .00001), "layer": body.collision_layer, "mask": body.collision_mask})
		n.queue_free()
		ref.queue_free()
	await process_frame
	stage.queue_free()

# ---------------------------------------------------------------- review assembly
func visible_copy() -> void:
	# Kit meshes only (review supports, figures and labels are excluded).
	var faces := PackedVector3Array()
	for k: Node in review.get_tree().get_nodes_in_group("review_kit"):
		for m: MeshInstance3D in k.find_children("*", "MeshInstance3D", true, false):
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

func h(t: float) -> float:
	return minf(t, 11.0)*S

func kit_at(file: String, at: Vector3) -> Node3D:
	for k: Node3D in review.get_tree().get_nodes_in_group("review_kit"):
		if k.scene_file_path.ends_with(file) and k.global_position.distance_to(at) < 1e-4: return k
	return null

func assembly() -> void:
	for s in [-1.0, 1.0]:
		var side := "right" if s > 0 else "left"
		var secs: Array = review.stair_sections.filter(func(e: Dictionary) -> bool: return e.side == s)
		var lengths := secs.map(func(e: Dictionary) -> int: return e.L)
		var err := 0.0
		var upright := true
		var t := 0.0
		for e: Dictionary in secs:
			var n: Node3D = e.node
			err = maxf(err, n.global_position.distance_to(Vector3(s*RAIL_X, t*S, -t)))
			var b := n.global_transform.basis
			upright = upright and b.y.distance_to(Vector3.UP) < 1e-6 and absf(b.get_scale().length()-sqrt(3)) < 1e-6 and b.x.distance_to(Vector3(0, 0, -1)) < 1e-6
			t += e.L
		check("%s side: five 2 m + one 1 m section chained at (+L run, +L*4/11 rise), unit scale, yaw only" % side,
			lengths == [2, 2, 2, 2, 2, 1] and err < 1e-5 and upright, {"sections_m": lengths, "max_origin_error_m": snappedf(err, 1e-7), "upright_unit_scale": upright})
		# Upper landing: the 1 m section's endpoint is the level section's leading post, on the landing.
		var last: Node3D = secs[-1].node
		var top: Vector3 = last.global_position+Vector3(0, S, -1)
		var landing := kit_at("rail_section_2m.tscn", top)
		var closer := kit_at("rail_post.tscn", top+Vector3(0, 0, -2))
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(top+Vector3(s*.2, .5, -.05), top+Vector3(s*.2, -1, -.05), 1))
		var support_y: float = hit.position.y if hit else -1.0
		check("%s side: flight ends at y = 4.000 on the landing rail's leading post, closed by a rail_post" % side,
			absf(top.y-4.0) < 1e-5 and absf(top.z+11.0) < 1e-5 and landing != null and closer != null and absf(support_y-4.0) < .001,
			{"top_post_origin": top, "landing_section_found": landing != null, "closing_post_found": closer != null, "landing_surface_y": snappedf(support_y, .0001), "post_base_embed_m": .05})

func ray_depth(from: Vector3, to: Vector3) -> float:
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, VIS))
	return -1.0 if hit.is_empty() else from.distance_to(hit.position)

func sweep(name: String, origin: Callable, dir: Vector3, segments: Array, tolerance: float, probes := []) -> void:
	# Rays every 1 cm, offset 5 mm so none lands exactly on a flush module boundary (such a ray can
	# graze between the two coincident faces), plus probes 1 mm either side of each joint.
	# A gap shows as a miss, a misaligned join as a depth jump.
	var misses := 0
	var lo := INF
	var hi := -INF
	var n := 0
	var odd := []      # first samples off the expected depth, with their run position
	var first := -1.0
	var samples := []
	for seg: Array in segments:
		var t: float = seg[0]+.005
		while t <= seg[1]:
			samples.append(t)
			t += .01
	for b: float in probes: samples.append_array([b-.001, b+.001])
	for t: float in samples:
		var o: Vector3 = origin.call(t)
		var d := ray_depth(o, o+dir*2.0)
		if d < 0: misses += 1
		else:
			lo = minf(lo, d)
			hi = maxf(hi, d)
			if first < 0: first = d
			if absf(d-first) > tolerance and odd.size() < 8: odd.append([snappedf(t, .001), snappedf(d, .0001)])
		n += 1
	check("continuous run (no gaps, faces aligned across joints): "+name, misses == 0 and hi-lo <= tolerance,
		{"samples": n, "misses": misses, "depth_min_m": snappedf(lo, .0001), "depth_range_m": snappedf(hi-lo, .0001), "off_depth_samples_run_m_depth_m": odd})

func joins() -> void:
	for s in [-1.0, 1.0]:
		var side := "right" if s > 0 else "left"
		# Lane-side faces from the foot post through the top post to the landing's closing post.
		var joints := []       # post faces: every place a span meets a post
		for p in [0.0, 2.0, 4.0, 6.0, 8.0, 10.0, 11.0, 13.0]:
			if p > 0: joints.append(p-.12)
			if p < 13: joints.append(p+.12)
		sweep(side+" plinth face, foot post to landing rail_post (7 stair posts)", func(t: float) -> Vector3: return Vector3(s*(FACE-.25), h(t)+.06, -t), Vector3(s, 0, 0), [[0.0, 13.0]], .001, joints)
		sweep(side+" top rail face across every post (posts stand 3 cm proud of the rail)", func(t: float) -> Vector3: return Vector3(s*(FACE-.25), h(t)+1.04, -t), Vector3(s, 0, 0), [[0.0, 13.0]], .031, joints)
		# Top rail upper surface between posts: straight along the pitch, then level on the landing.
		var segs := []
		for k in [0.0, 2.0, 4.0, 6.0, 8.0]: segs.append([k+.17, k+2-.17])
		segs.append([10.17, 10.83])
		segs.append([11.17, 12.83])
		sweep(side+" top rail upper surface between posts, 6 stair spans + landing", func(t: float) -> Vector3: return Vector3(s*RAIL_X, h(t)+1.6, -t), Vector3(0, -1, 0), segs, .001)

func lane_and_collision() -> void:
	# Nothing with kit collision intrudes into the lane between the rails' lane-side faces.
	var hw := FACE-.005
	var flight := ConvexPolygonShape3D.new()
	flight.points = PackedVector3Array([Vector3(-hw, .02, 0), Vector3(hw, .02, 0), Vector3(-hw, 2.2, 0), Vector3(hw, 2.2, 0),
		Vector3(-hw, 4.02, -11), Vector3(hw, 4.02, -11), Vector3(-hw, 6.2, -11), Vector3(hw, 6.2, -11)])
	var land := BoxShape3D.new()
	land.size = Vector3(2*hw, 2.18, 2.5)
	var blocking := []
	for q in [[flight, Transform3D.IDENTITY], [land, Transform3D(Basis(), Vector3(0, 5.11, -12.25))]]:
		var p := PhysicsShapeQueryParameters3D.new()
		p.shape = q[0]
		p.transform = q[1]
		p.collision_mask = 1
		for r: Dictionary in space.intersect_shape(p, 32): blocking.append(str(r.collider.get_path()))
	check("walking lane clear of all collision between the rail faces (12.46 m wide, 2.2 m high)", blocking.is_empty(), {"lane_width_m": 2*FACE, "blocking": blocking})
	# Waist-height rays from the lane centre reach the rail collision itself, not the supports below it.
	var widths := []
	var ok := true
	for t in [1.0, 3.0, 6.0, 9.0, 10.5, 11.0, 12.0]:
		var hits := []
		for s in [-1.0, 1.0]:
			var o := Vector3(0, h(t)+.9, -t)
			var r := space.intersect_ray(PhysicsRayQueryParameters3D.create(o, o+Vector3(s*8, 0, 0), 1))
			var owner := ""
			if r:
				var body: CollisionObject3D = r.collider
				owner = body.shape_owner_get_owner(body.shape_find_owner(r.shape)).name
				ok = ok and body.is_in_group("solid_world") and (owner.begins_with("Rail")) and absf(absf(r.position.x)-FACE) < .002
			else: ok = false
			hits.append(owner)
		widths.append({"run_m": t, "hit_shapes": hits})
	check("waist-height rays hit rail collision at both faces (sections, joints, top post, landing)", ok, widths)

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
	var r := await walk(Vector3(0, .05, 1.5), Vector3(0, 0, -1), 4.0)
	check("climbs the lane centre from the foot onto the landing", absf(r.end.y-4.0) < .06 and r.end.z < -12 and r.clip_frames == 0, r)
	for s in [-1.0, 1.0]:
		var x: float = s*(FACE-.30)
		r = await walk(Vector3(x, .05, 1.0), Vector3(0, 0, -1), 3.7)
		check("climbs along the %s lane edge 0.30 m from the rail face without snagging or clipping" % ("right" if s > 0 else "left"),
			absf(r.end.y-4.0) < .06 and r.end.z < -11.5 and absf(r.end.x-x) < .1 and r.clip_frames == 0, r)
	r = await walk(Vector3(0, 4.05, -13.5), Vector3(0, 0, 1), 4.4)
	check("descends the lane centre from the landing to the foot", absf(r.end.y) < .06 and r.end.z > 1.5 and r.clip_frames == 0, r)
	for s in [-1.0, 1.0]:
		for t in [3.0, 6.0, 10.5, 12.0]:     # mid 2 m section, post joint, mid 1 m section, landing rail
			r = await walk(Vector3(s*5.0, h(t)+.05, -t), Vector3(s, 0, 0), 1.0)
			check("%s rail stops a sideways exit at run %.1f m" % ["right" if s > 0 else "left", t],
				absf(r.end.x) > 5.8 and absf(r.end.x) < FACE-.25 and r.lowest_y > h(t)-.1, r)

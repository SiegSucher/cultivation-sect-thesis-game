extends SceneTree
## Independent routes against canonical Mission Hall; no asset/controller edits.
const OUT := "res://reports/codex-mission-hall/"
var stage: Node3D
var checks: Array = []
var movement: Array = []
var camera_hits: Array = []
var visual_hits: Array = []
var samples := 0
var rendered := false

func _initialize() -> void: call_deferred("run")
func settle(n := 5) -> void:
	for i in n: await physics_frame
func check(label: String, ok: bool, detail: Variant = null) -> void:
	checks.append({"check": label, "pass": ok, "detail": detail})
	print("PASS " if ok else "FAIL ", label, " ", detail)
func sample() -> void:
	var space: PhysicsDirectSpaceState3D = stage.get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	var ball := SphereShape3D.new(); ball.radius = .16
	q.shape = ball; q.collision_mask = 1 | 8
	q.transform.origin = stage.player.camera.global_position
	if not space.intersect_shape(q, 1).is_empty():
		camera_hits.append({"third": stage.player.third_person, "at": str(q.transform.origin)})
	var body := CapsuleShape3D.new(); body.height = 1.35; body.radius = .24
	q.shape = body; q.collision_mask = 8
	q.transform.origin = stage.player.global_position + Vector3(0, 1.175, 0)
	if not space.intersect_shape(q, 1).is_empty():
		visual_hits.append({"third": stage.player.third_person, "at": str(stage.player.position)})
	samples += 1
func walk(label: String, target: Vector3) -> void:
	var p: CharacterBody3D = stage.player
	var count := 0
	while count < 450:
		var d: Vector3 = target - p.position; d.y = 0
		if d.length() < .12: break
		p.drive = d.normalized(); p.yaw = atan2(-d.x, -d.z)
		await physics_frame
		if count % 8 == 0: sample()
		count += 1
	p.drive = Vector3.ZERO; await settle()
	var error := Vector2(p.position.x - target.x, p.position.z - target.z).length()
	var detail := {"third": p.third_person, "target": str(target), "actual": str(p.position), "frames": count}
	movement.append(detail)
	check(label, error < .22 and absf(p.position.y - target.y) < .18 and p.is_on_floor(), detail)
func reset(pos: Vector3, third: bool) -> void:
	stage.player.position = pos; stage.player.velocity = Vector3.ZERO; stage.player.drive = Vector3.ZERO
	stage.player.yaw = 0; stage.player.pitch = 0; stage.player.third_person = third
	stage.player.set_physics_process(true); await settle()
func shot(name: String) -> void:
	if not rendered: return
	stage.player.set_physics_process(false)
	stage.player.camera.make_current()
	for i in 4: await RenderingServer.frame_post_draw
	check("route capture " + name, root.get_texture().get_image().save_png(OUT+name+".png") == OK)
	stage.player.set_physics_process(true)
func block(label: String, at: Vector3, dir: Vector3, third: bool, axis: String, limit: float) -> void:
	await reset(at, third)
	stage.player.drive = dir; stage.player.yaw = atan2(-dir.x, -dir.z)
	for i in 100:
		await physics_frame
		if i % 8 == 0: sample()
	stage.player.drive = Vector3.ZERO; await settle()
	var coordinate: float = stage.player.position[axis]
	check(label, coordinate > limit if axis == "z" else absf(coordinate) < limit, str(stage.player.position))
func run() -> void:
	rendered = "--rendered" in OS.get_cmdline_user_args()
	root.size = Vector2i(1280,720)
	stage = load("res://scenes/review/mission_hall_walkthrough.tscn").instantiate()
	root.add_child(stage)
	stage.player.automated = true
	var asset: Node3D = stage.get_node("MissionHall")
	check("identity root / metres", asset.transform == Transform3D.IDENTITY)
	var shapes: Array = asset.find_children("*", "CollisionShape3D", true, false)
	check("37 enabled authored collision shapes", shapes.size() == 37 and shapes.all(func(s): return s.shape != null and not s.disabled))
	check("collision layers match unchanged player", asset.get_node("Collision").collision_layer == 1 and asset.get_node("Collision").collision_mask == 2)
	check("no asset lights/cameras/scripts", asset.get_script() == null and asset.find_children("*", "Camera3D", true, false).is_empty() and asset.find_children("*", "Light3D", true, false).is_empty())
	for name: String in ["MissionBoard_023", "MissionBoard_024", "ReportingCounter_025", "RankingBoard_031", "NoticeBoard_010", "NoticeBoard_011"]:
		check("authored architectural feature " + name, asset.has_node("Collision/" + name))
	var visual := StaticBody3D.new(); visual.collision_layer = 8; visual.collision_mask = 0
	stage.add_child(visual)
	for mi: MeshInstance3D in asset.find_children("*", "MeshInstance3D", true, false):
		var shape := CollisionShape3D.new(); shape.shape = mi.mesh.create_trimesh_shape()
		shape.transform = mi.global_transform; visual.add_child(shape)
	await settle()
	for third: bool in [false, true]:
		var mode := "TPP " if third else "FPP "
		await reset(Vector3(0, .05, 15), third)
		for waypoint: Array in [
			["stair and forecourt", Vector3(0,.75,9)],
			["porch", Vector3(0,.75,5)],
			["door and aisle", Vector3(0,.75,1)],
			["counter approach", Vector3(0,.75,-2.05)],
			# The returns chest occupies x=4,z=-2.1. Route around its front,
			# then turn into the side passage instead of walking through it.
			["step back from counter and chest", Vector3(0,.75,0)],
			["east side passage approach", Vector3(5.6,.75,0)],
			["officials east", Vector3(5.6,.75,-6.6)],
			["behind officials desks", Vector3(-5.6,.75,-6.6)],
			["west side passage", Vector3(-5.6,.75,0)],
			["return to central aisle", Vector3(0,.75,0)],
			["door and porch exit", Vector3(0,.75,6.8)],
			["west board approach", Vector3(-5.4,.75,8.3)],
			["between boards", Vector3(5.4,.75,8.3)],
			["return to stair", Vector3(0,.75,9.8)],
			["descend to ground", Vector3(0,.03,14)]
		]:
			await walk(mode + waypoint[0], waypoint[1])
			if waypoint[0] in ["door and aisle", "officials east", "west board approach"]:
				await shot(("tpp-" if third else "fpp-") + waypoint[0].replace(" ", "-"))
		await block(mode+"counter blocks", Vector3(0,.8,0), Vector3.FORWARD, third, "z", -2.4)
		await block(mode+"front noticeboard/wall blocks", Vector3(2.6,.8,5), Vector3.FORWARD, third, "z", 3.9)
		await block(mode+"east board blocks", Vector3(3,.8,8.3), Vector3.RIGHT, third, "x", 6.1)
		await block(mode+"west board blocks", Vector3(-3,.8,8.3), Vector3.LEFT, third, "x", 6.1)
	stage.player.set_physics_process(false)
	check("sampled upper body clears visible geometry", visual_hits.is_empty(), visual_hits)
	check("sampled FPP/TPP camera clears solids and visible meshes", camera_hits.is_empty(), camera_hits)
	var failed := checks.filter(func(c): return not c.pass).size()
	FileAccess.open(OUT+("rendered-routes.json" if rendered else "independent-routes.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "passed": checks.size()-failed, "failed": failed, "sampled_volumes": samples, "camera_hits": camera_hits, "visual_hits": visual_hits, "movement": movement, "limits": "Automated fixed-fps routes; not human playtesting, performance or exhaustive collision testing"}, "  "))
	print(checks.size()-failed, " PASS / ", failed, " FAIL; sampled ", samples)
	quit(1 if failed else 0)

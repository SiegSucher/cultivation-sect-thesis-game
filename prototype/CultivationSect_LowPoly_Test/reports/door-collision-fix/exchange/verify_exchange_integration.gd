extends SceneTree
## Independent routes against canonical Exchange Hall, unchanged controller.
const OUT := "res://reports/door-collision-fix/exchange/"
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
	stage = load("res://scenes/review/exchange_hall_walkthrough.tscn").instantiate()
	root.add_child(stage)
	stage.player.automated = true
	var asset: Node3D = stage.get_node("ExchangeHall")
	check("identity root / metres", asset.transform == Transform3D.IDENTITY)
	var shapes: Array = asset.find_children("*", "CollisionShape3D", true, false)
	check("69 original plus 4 retained storeroom and 2 main-leaf collision shapes", shapes.size() == 75 and shapes.all(func(s): return s.shape != null and not s.disabled))
	for leaf: String in ["EastStaticLeaf0", "EastStaticLeaf1", "WestStaticLeaf0", "WestStaticLeaf1"]:
		var node: CollisionShape3D = asset.get_node("Collision/"+leaf)
		check("static leaf camera/body coverage "+leaf, node.shape is BoxShape3D and node.shape.size.is_equal_approx(Vector3(.78,2.54,.10)))
	check("collision layers match unchanged player", asset.get_node("Collision").collision_layer == 1 and asset.get_node("Collision").collision_mask == 2)
	check("no asset lights/cameras/scripts", asset.get_script() == null and asset.find_children("*", "Camera3D", true, false).is_empty() and asset.find_children("*", "Light3D", true, false).is_empty())
	for name: String in ["ExchangeCounter_022", "Shelving_025", "TreasurePlinth_031", "RewardList_009", "WindowFrame_008", "WingCeiling_040"]:
		check("authored architectural feature " + name, asset.has_node("Collision/" + name))
	var visual := StaticBody3D.new(); visual.collision_layer = 8; visual.collision_mask = 0
	stage.add_child(visual)
	for mi: MeshInstance3D in asset.find_children("*", "MeshInstance3D", true, false):
		var shape := CollisionShape3D.new(); shape.shape = mi.mesh.create_trimesh_shape()
		shape.transform = mi.global_transform; visual.add_child(shape)
	await settle()
	for third: bool in [false, true]:
		var mode := "TPP " if third else "FPP "
		await reset(Vector3(0, .05, 13), third)
		for waypoint: Array in [
			["stair and terrace", Vector3(0,.6,7)],
			["main doorway", Vector3(0,.6,4)],
			["aisle and counter", Vector3(0,.6,0)],
			["east customer lane", Vector3(4.15,.6,0)],
			["east counter end", Vector3(4.15,.6,-2.4)],
			["east storeroom", Vector3(9.8,.6,-2.4)],
			["east storeroom return", Vector3(4.15,.6,-2.4)],
			["staff east behind stools", Vector3(4.15,.6,-3.1)],
			["reward racks staff lane", Vector3(-4.15,.6,-3.1)],
			["west side doorway", Vector3(-4.15,.6,-2.4)],
			["west storeroom", Vector3(-9.8,.6,-2.4)],
			["west storeroom return", Vector3(-4.15,.6,-2.4)],
			["west counter end", Vector3(-4.15,.6,0)],
			["central aisle return", Vector3(0,.6,0)],
			["main door exit", Vector3(0,.6,6.6)],
			["east veranda approach", Vector3(8.6,.6,6.6)],
			["east veranda", Vector3(8.6,.6,3.9)],
			["east veranda return", Vector3(8.6,.6,6.6)],
			["west veranda approach", Vector3(-8.6,.6,6.6)],
			["west veranda", Vector3(-8.6,.6,3.9)],
			["west veranda return", Vector3(-8.6,.6,6.6)],
			["return to stair", Vector3(0,.6,6.6)],
			["descend to ground", Vector3(0,.03,13)]
		]:
			await walk(mode + waypoint[0], waypoint[1])
			if waypoint[0] in ["aisle and counter", "east storeroom", "west storeroom", "reward racks staff lane"]:
				await shot(("tpp-" if third else "fpp-") + waypoint[0].replace(" ", "-"))
		await block(mode+"counter blocks", Vector3(0,.65,1), Vector3.FORWARD, third, "z", -.6)
		await block(mode+"front reward board blocks", Vector3(3.85,.65,7), Vector3.FORWARD, third, "z", 5.3)
		await block(mode+"east veranda wall blocks", Vector3(8.6,.65,7), Vector3.FORWARD, third, "z", 3.2)
		await block(mode+"west veranda wall blocks", Vector3(-8.6,.65,7), Vector3.FORWARD, third, "z", 3.2)

	stage.player.set_physics_process(false)
	check("sampled upper body clears visible geometry", visual_hits.is_empty(), visual_hits)
	check("sampled FPP/TPP camera clears solids and visible meshes", camera_hits.is_empty(), camera_hits)
	var failed := checks.filter(func(c): return not c.pass).size()
	FileAccess.open(OUT+("rendered-routes.json" if rendered else "independent-routes.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "passed": checks.size()-failed, "failed": failed, "sampled_volumes": samples, "camera_hits": camera_hits, "visual_hits": visual_hits, "movement": movement, "limits": "Automated fixed-fps routes; not human playtesting, performance or exhaustive collision testing"}, "  "))
	print(checks.size()-failed, " PASS / ", failed, " FAIL; sampled ", samples)
	quit(1 if failed else 0)

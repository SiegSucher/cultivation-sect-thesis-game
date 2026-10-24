extends SceneTree
## Focused follow-up after moving the pond clear of the garden footprint.
var player: CharacterBody3D
var checks: Array = []
func _initialize() -> void: call_deferred("run")

func walk(point: Vector3) -> bool:
	for i in 6000:
		var delta := point-player.position
		delta.y = 0
		if delta.length()<.24:
			player.drive = Vector3.ZERO
			return absf(player.position.y-point.y)<.4
		player.drive = delta.normalized()
		await physics_frame
	return false

func run() -> void:
	var scene: Node3D = load("res://mountain_valley/mountain_valley.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.player
	player.automated = true
	scene.jump_to(Vector3(76,20.1,31))
	for i in 8: await physics_frame
	var passed := true
	for p: Vector3 in [Vector3(104,20,21),Vector3(123,20,3),Vector3(154,20,-33),Vector3(175,20,-48),Vector3(175,20,-57),Vector3(154,20,-33),Vector3(180,20,-29),Vector3(204,20,-47),Vector3(207,20,-78)]:
		var okay := await walk(p)
		checks.append({"target":[p.x,p.y,p.z],"pass":okay})
		passed = passed and okay
		if not okay: break
	var terrain = load("res://mountain_valley/terrain_builder.gd").new()
	terrain.setup(scene.layout)
	# The Herb Garden's four ground corners should stay on the +20 m shelf.
	for p: Vector2 in [Vector2(163,-86),Vector2(187,-86),Vector2(163,-62),Vector2(187,-62)]:
		var okay: bool = absf(terrain.height(p.x,p.y)-20)<.1
		checks.append({"garden_corner":[p.x,p.y],"pass":okay})
		passed = passed and okay
	var f := FileAccess.open("res://reports/mountain-valley/garden-follow-up.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"pass":passed,"checks":checks},"\t"))
	print("Garden/overlook follow-up: ","PASS" if passed else "FAIL"," (",checks.size()," checks)")
	quit(0 if passed else 1)

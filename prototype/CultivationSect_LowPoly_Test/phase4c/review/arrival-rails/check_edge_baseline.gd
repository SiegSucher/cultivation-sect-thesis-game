extends "res://phase4c/review/check_terrain.gd"
## Diagnose only the reproduced outside-margin condition, without changing terrain.
const OUT := "res://phase4c/review/arrival-rails/"
func run() -> void:
	scene = load(ROOT+"phase4c_valley.tscn").instantiate()
	var supports: Node = scene.get_node("SelectiveTerrainSupports")
	scene.remove_child(supports)
	supports.free()
	var old: Node3D = load(OUT+"preexisting-safety.tscn").instantiate()
	scene.add_child(old)
	root.add_child(scene)
	current_scene = scene
	await frames(12)
	player = scene.player
	player.automated = true
	var rows: Array = []
	for x: float in [-5.93,-5.65,-5.3,5.3,5.65,5.93]:
		scene.jump_to(Vector3(x,.12,105.8))
		await frames(8)
		var okay := await walk_to(Vector3(x,4,93.2))
		rows.append({"x":x,"uphill_without_new_rails":okay,"end":player.position})
		print("BASELINE EDGE ",rows[-1])
	for x: float in [-5.65,5.65]:
		scene.jump_to(Vector3(x,4.12,93.2),PI)
		await frames(8)
		var okay := await walk_to(Vector3(x,0,105.8))
		rows.append({"x":x,"downhill_without_new_rails":okay,"end":player.position})
		print("BASELINE UPPER MARGIN ",rows[-1])
	var f := FileAccess.open(OUT+"preexisting-edge-diagnosis.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"new_arrival_rails_removed_in_fixture_only":true,"results":rows},"\t"))
	quit()

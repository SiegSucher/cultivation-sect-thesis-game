extends SceneTree
## Bounds inspection only. No gallery regression or collision suite.
const OUT := "res://reports/mountain-valley/"
func _initialize() -> void: call_deferred("run")

func bounds(node: Node3D) -> Dictionary:
	var box := AABB()
	var started := false
	for mesh: MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
		if not mesh.mesh: continue
		# Ignore preserved distant duplicates. Near geometry establishes footprint.
		if "Distant" in str(mesh.get_path()): continue
		var b: AABB = node.global_transform.affine_inverse()*mesh.global_transform*mesh.get_aabb()
		box = box.merge(b) if started else b
		started = true
	return {"min":[box.position.x,box.position.y,box.position.z],"max":[box.end.x,box.end.y,box.end.z],"size":[box.size.x,box.size.y,box.size.z]}

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var catalog: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/gallery/catalog.json"))
	var result := {"buildings":{},"environment":{}}
	for item: Dictionary in catalog:
		var node: Node3D = load(item.resource).instantiate()
		root.add_child(node)
		result.buildings[item.id] = bounds(node)
		result.buildings[item.id]["resource"] = item.resource
		print(item.id," ",result.buildings[item.id].size)
		node.free()
	for id: String in ["pine_windswept","pine_tiered","bamboo_cluster","flowering_shrub","grass_tuft","rock_cluster","rock_outcrop","stone_lantern","sect_banner","training_dummy_rack","stone_bench"]:
		var node: Node3D = load("res://staging/claude_environment_batch1/"+id+"/"+id+".tscn").instantiate()
		root.add_child(node)
		result.environment[id] = bounds(node)
		node.free()
	var player := CharacterBody3D.new()
	player.set_script(load("res://scripts/training_inspection_player.gd"))
	player.automated = true
	root.add_child(player)
	var capsule: CapsuleShape3D = player.get_node("InspectionCapsule_1_8m").shape
	result["player"] = {"height":capsule.height,"width":capsule.radius*2,"speed":player.speed,"eye":1.65,"max_slope_degrees":rad_to_deg(player.floor_max_angle)}
	var file := FileAccess.open(OUT+"asset-measurements.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	quit()

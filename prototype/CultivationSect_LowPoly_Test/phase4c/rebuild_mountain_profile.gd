extends SceneTree
## Rebuild only terrain and vertically seat the existing distant pine batches.
## The scene, kit assemblies, stairs, paths and occupied shelves are untouched.
const OUT := "res://phase4c/review/mountain-profile/"
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if DisplayServer.get_name()=="headless":
		printerr("Use rendered Godot to retain MultiMesh transforms.")
		quit(1)
		return
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://mountain_valley_compact/layout.json"))
	var holder := Node3D.new()
	var terrain = load("res://phase4c/terrain_builder.gd").new()
	terrain.setup(layout)
	terrain.build(holder,true)
	var sampler = load("res://phase4c/terrain_sampler.gd").new()
	sampler.setup(terrain.vertices)
	var scene: Node3D = load("res://phase4c/phase4c_valley.tscn").instantiate()
	var records: Array = []
	for node: Node3D in scene.get_node("RetainedProvisionalDressing").get_children():
		if not node is MultiMeshInstance3D: continue
		var mm: MultiMesh = node.multimesh.duplicate()
		var changed := 0
		for i in mm.instance_count:
			var pose := mm.get_instance_transform(i)
			# Preserve all pine poses inside the unchanged district envelope too.
			if absf(pose.origin.x)<=156 and pose.origin.z>=-170 and pose.origin.z<=190: continue
			var h: float = sampler.height(pose.origin.x,pose.origin.z)-.08
			if absf(h-pose.origin.y)>.025:
				pose.origin.y = h
				mm.set_instance_transform(i,pose)
				changed += 1
		assert(ResourceSaver.save(mm,"res://phase4c/resources/"+String(node.name)+".res")==OK)
		records.append({"batch":str(node.name),"existing_pines_seated_vertically":changed,"total":mm.instance_count})
	var f := FileAccess.open(OUT+"rebuild.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"terrain_vertices":terrain.vertices.size(),"unchanged_interior_xz":[-156,-170,156,190],"blend_distance_m":48,"pine_batches":records},"\t"))
	print("Backdrop rebuilt; existing mountain pines seated vertically: ",records)
	scene.free()
	holder.free()
	quit()

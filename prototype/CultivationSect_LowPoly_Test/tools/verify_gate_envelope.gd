extends SceneTree
## Match actual imported runtime bounds, including hinge-local leaf assets.
func _initialize() -> void: call_deferred("run")
func measure(model: Node3D) -> Dictionary:
	var first := true
	var bounds := AABB()
	var triangles := 0
	var surfaces := 0
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		var box: AABB = mesh.global_transform*mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first=false
		for i in range(mesh.mesh.get_surface_count()):
			var a: Array = mesh.mesh.surface_get_arrays(i)
			triangles += a[Mesh.ARRAY_INDEX].size()/3 if a[Mesh.ARRAY_INDEX]!=null else a[Mesh.ARRAY_VERTEX].size()/3
			surfaces += 1
	return {"bounds":str(bounds),"min":bounds.position,"max":bounds.end,"triangles":triangles,"surfaces":surfaces}
func run() -> void:
	var names := ["sect_gate.glb","sect_gate_lod.glb","gate_leaf_left.glb","gate_leaf_right.glb"]
	var checks: Array = []
	for file in names:
		var previous: Node3D = load("res://baseline/stage1_gate/"+file).instantiate()
		var current: Node3D = load("res://assets/architecture/sect_gate/"+file).instantiate()
		root.add_child(previous);root.add_child(current)
		var before:=measure(previous)
		var after:=measure(current)
		var ok: bool = before.min.distance_to(after.min)<.0001 and before.max.distance_to(after.max)<.0001
		checks.append({"file":file,"pass":ok,"before":before,"after":after})
		root.remove_child(previous);previous.free()
		root.remove_child(current);current.free()
	var failed:=checks.filter(func(c):return not c.pass).size()
	var output:=FileAccess.open("res://reports/environment-conversion-stage-1/envelope-results.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"tolerance":.0001},"\t"))
	output.close()
	print("Gate bounds: "+str(checks.size()-failed)+" PASS / "+str(failed)+" FAIL")
	quit(1 if failed else 0)

extends SceneTree
## Compare actual Godot-imported feet/hinges/envelopes, not authoring JSON counts.
const OUT := "res://reports/environment-conversion-stages-2-3/"
func _initialize() -> void: call_deferred("run")
func measure(model: Node3D) -> Dictionary:
	var first:=true
	var box:=AABB()
	var triangles:=0
	var surfaces:=0
	for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		var aabb: AABB=mesh.global_transform*mesh.get_aabb()
		box=aabb if first else box.merge(aabb)
		first=false
		for i in range(mesh.mesh.get_surface_count()):
			var a: Array=mesh.mesh.surface_get_arrays(i)
			triangles+=a[Mesh.ARRAY_INDEX].size()/3 if a[Mesh.ARRAY_INDEX]!=null else a[Mesh.ARRAY_VERTEX].size()/3
			surfaces+=1
	return {"min":box.position,"max":box.end,"bounds":str(box),"triangles":triangles,"surfaces":surfaces}
func run() -> void:
	var args:=OS.get_cmdline_user_args()
	var short: String="pavilion" if "--pavilion" in args else "training"
	var props_only: bool="--props-only" in args
	var family: String="scripture_pavilion" if short=="pavilion" else "martial_training_ground"
	var base: String="res://baseline/stage23_"+short+"/"
	var checks: Array=[]
	for file: String in DirAccess.get_files_at(base):
		if not file.ends_with(".glb"):continue
		if props_only and file.begins_with(family):continue
		var previous: Node3D=load(base+file).instantiate()
		var current: Node3D=load("res://assets/architecture/"+family+"/"+file).instantiate()
		root.add_child(previous); root.add_child(current)
		var before:=measure(previous)
		var after:=measure(current)
		checks.append({"file":file,"pass":before.min.distance_to(after.min)<.0001 and before.max.distance_to(after.max)<.0001,"before":before,"after":after})
		root.remove_child(previous); previous.free()
		root.remove_child(current); current.free()
	if short=="training" and not props_only:
		var facility: Node3D=load("res://scenes/buildings/martial_training_ground.tscn").instantiate()
		root.add_child(facility)
		for protected: String in ["Training_CourtPaving","Training_Paving","Training_PackedEarth","Training_Joint"]:
			var node: Node=facility.static_model.find_child(protected,true,false)
			checks.append({"check":protected+" shadow/LOD contract retained","pass":node!=null and node.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and node.lod_bias==128})
		root.remove_child(facility);facility.free()
	var failures:=checks.filter(func(c):return not c.pass).size()
	var report: Dictionary={"checks":checks,"passed":checks.size()-failures,"failed":failures,"tolerance":.0001}
	FileAccess.open(OUT+short+("-props" if props_only else "")+"-envelope.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(short," envelopes: ",report.passed," PASS / ",failures," FAIL")
	quit(1 if failures else 0)

extends SceneTree
## Save an inherited scene and changed resources only. The approved compact
## scene is never packed, overwritten or regenerated.
const ROOT := "res://phase4c/"
var overrides: Array[String] = []
var ext: Array[String] = []
var seated: Array = []
var ext_index := 10
func _initialize() -> void: call_deferred("run")
func own(node: Node,owner_node: Node) -> void:
	for child: Node in node.get_children():
		child.owner = owner_node
		if child.scene_file_path.is_empty(): own(child,owner_node)
func external(type: String,path: String) -> String:
	ext_index += 1
	var id := "r%d"%ext_index
	ext.append('[ext_resource type="%s" path="%s" id="%s"]'%[type,path,id])
	return 'ExtResource("%s")'%id
func run() -> void:
	if DisplayServer.get_name()=="headless":
		printerr("Use the rendered engine so cloned forest batches keep their transforms.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT+"resources"))
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://mountain_valley_compact/layout.json"))
	var temporary := Node3D.new()
	var terrain = load(ROOT+"terrain_builder.gd").new()
	terrain.setup(layout)
	terrain.build(temporary)
	var sampler = load(ROOT+"terrain_sampler.gd").new()
	sampler.setup(terrain.vertices)
	var approved: Node3D = load("res://mountain_valley_compact/compact_valley.tscn").instantiate()
	var ground: StaticBody3D = approved.get_node("ValleyGroundCollision")
	var shape_name: String = ground.get_child(0).name
	var terrain_ref := external("ArrayMesh",ROOT+"resources/terrain_mesh.res")
	var collision_ref := external("Shape3D",ROOT+"resources/terrain_collision.res")
	var paths_ref := external("ArrayMesh",ROOT+"resources/paths_mesh.res")
	overrides.append('[node name="ContinuousValleyTerrain" parent="." index=0]\nmesh = '+terrain_ref+'\n')
	overrides.append('[node name="'+shape_name+'" parent="ValleyGroundCollision" index=0]\nshape = '+collision_ref+'\n')
	overrides.append('[node name="RoadsCourtsAndVisibleStairs" parent="." index=2]\nmesh = '+paths_ref+'\n')
	# Existing dressing is only seated vertically where the changed terrain would
	# otherwise leave it floating/buried. No new plants or furniture are added.
	for node: Node3D in approved.get_node("RetainedProvisionalDressing").get_children():
		if node is MultiMeshInstance3D:
			var mm: MultiMesh = node.multimesh.duplicate()
			var changed := 0
			for i in mm.instance_count:
				var pose: Transform3D = node.multimesh.get_instance_transform(i)
				var h: float = sampler.height(pose.origin.x,pose.origin.z)-.08
				if absf(h-pose.origin.y)>.025:
					pose.origin.y = h
					changed += 1
				mm.set_instance_transform(i,pose)
			var path := ROOT+"resources/"+String(node.name)+".res"
			assert(ResourceSaver.save(mm,path)==OK)
			var ref := external("MultiMesh",path)
			overrides.append('[node name="'+String(node.name)+'" parent="RetainedProvisionalDressing"]\nmultimesh = '+ref+'\n')
			seated.append({"batch":str(node.name),"instances_seated_vertically":changed})
		else:
			var p := node.position
			var h: float = sampler.height(p.x,p.z)
			if absf(h-p.y)>.025:
				p.y = h
				overrides.append('[node name="'+String(node.name)+'" parent="RetainedProvisionalDressing"]\nposition = Vector3(%0.8f,%0.8f,%0.8f)\n'%[p.x,p.y,p.z])
				seated.append({"prop":str(node.name),"old_y":node.position.y,"new_y":p.y})
	var safety = load(ROOT+"safety_assembly.gd").new()
	load(ROOT+"import_kit.gd").new().prepare()
	var supports: Node3D = safety.build(temporary,layout,sampler)
	temporary.remove_child(supports)
	own(supports,supports)
	var packed := PackedScene.new()
	assert(packed.pack(supports)==OK)
	assert(ResourceSaver.save(packed,ROOT+"resources/safety_assembly.tscn")==OK)
	var safety_ref := external("PackedScene",ROOT+"resources/safety_assembly.tscn")
	var text := '[gd_scene format=3]\n\n[ext_resource type="PackedScene" path="res://mountain_valley_compact/compact_valley.tscn" id="base"]\n[ext_resource type="Script" path="res://phase4c/walkthrough.gd" id="script"]\n'
	text += "\n".join(ext)+"\n\n"
	text += '[node name="Phase4C_CompactValley" instance=ExtResource("base")]\nscript = ExtResource("script")\n\n'
	text += "\n".join(overrides)
	text += '\n[node name="SelectiveTerrainSupports" parent="." instance='+safety_ref+']\n'
	var f := FileAccess.open(ROOT+"phase4c_valley.tscn",FileAccess.WRITE)
	f.store_string(text)
	var summary := FileAccess.open(ROOT+"review/build-summary.json",FileAccess.WRITE)
	summary.store_string(JSON.stringify({"terrain_triangles":terrain.vertices.size()/3,"path_triangles":terrain.road_vertices.size()/3,"kit_counts":safety.counts,"guard_runs":safety.guard_runs,"stair_assemblies":safety.stair_records,"existing_dressing_seated":seated,"unchanged_layout":"res://mountain_valley_compact/layout.json","architecture_inherited":true,"walking_ramps_inherited_unchanged":true},"\t"))
	print("Phase 4C inherited scene saved; terrain ",terrain.vertices.size()/3," triangles; kit ",safety.counts)
	supports.free()
	temporary.free()
	approved.free()
	quit()

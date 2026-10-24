extends RefCounted
## Ordinary phase-local Godot imports of unchanged staged GLBs. Never run the
## Blender builder or write .import metadata beside the protected staging files.
const SOURCE := "res://staging/claude_environment_safety_kit/"
const TARGET := "res://phase4c/resources/kit/"
const IDS := ["railings/rail_stair_22deg_2m","railings/rail_stair_22deg_1m","railings/rail_stair_24deg_2m","railings/rail_section_2m","railings/rail_section_1m","railings/rail_post","retaining/retaining_wall_4x4","retaining/retaining_end_4","retaining/retaining_wall_4x2","retaining/retaining_end_2","retaining/retaining_corner_2","railings/rail_stair_4in11_1m","railings/rail_stair_4in11_2m"]
func prepare(ids: Array = IDS,report_path: String = "res://phase4c/review/kit-imports.json") -> void:
	var records: Array = []
	for id: String in ids:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path((TARGET+id).get_base_dir()))
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		assert(document.append_from_file(SOURCE+id+".glb",state)==OK,"Cannot read staged GLB: "+id)
		var model: Node = document.generate_scene(state)
		assert(model!=null)
		var packed := PackedScene.new()
		assert(packed.pack(model)==OK)
		assert(ResourceSaver.save(packed,TARGET+id+"_model.scn")==OK)
		var source := FileAccess.get_file_as_string(SOURCE+id+".tscn")
		var adapter := source.replace(SOURCE+id+".glb",TARGET+id+"_model.scn")
		assert(adapter!=source)
		var f := FileAccess.open(TARGET+id+".tscn",FileAccess.WRITE)
		f.store_string(adapter)
		records.append({"module":id,"unchanged_glb_sha256":FileAccess.get_sha256(SOURCE+id+".glb"),"scene_change":"model resource path only; staged collision unchanged"})
		model.free()
	var report := FileAccess.open(report_path,FileAccess.WRITE)
	report.store_string(JSON.stringify(records,"\t"))

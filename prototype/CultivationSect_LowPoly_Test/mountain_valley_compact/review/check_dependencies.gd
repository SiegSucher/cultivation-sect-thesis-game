extends SceneTree
## Read-only resource check: compact runtime must not reference the large map.
func _initialize() -> void:
	var bad: Array = []
	var files: Array = ["res://mountain_valley_compact/compact_valley.tscn"]
	for file: String in DirAccess.get_files_at("res://mountain_valley_compact/resources"):
		files.append("res://mountain_valley_compact/resources/"+file)
	for file: String in files:
		for dependency: String in ResourceLoader.get_dependencies(file):
			if "res://mountain_valley/" in dependency: bad.append({"file":file,"dependency":dependency})
	var f := FileAccess.open("res://mountain_valley_compact/review/runtime-dependencies.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checked_resources":files.size(),"large_map_dependencies":bad},"\t"))
	print("Compact runtime resources: ",files.size()," checked / ",bad.size()," large-map dependencies")
	quit(0 if bad.is_empty() else 1)

extends SceneTree
## Duplicate import metadata was copied with the baseline. Give those imports
## unique local IDs; resource paths stay explicit and the original is untouched.
func _initialize() -> void:
	var dir := DirAccess.open("res://baseline/hall")
	for name in dir.get_files():
		if not name.ends_with(".import"): continue
		var path := "res://baseline/hall/"+name
		var config := ConfigFile.new()
		if config.load(path) == OK:
			config.set_value("remap","uid",ResourceUID.id_to_text(ResourceUID.create_id()))
			config.save(path)
	print("Baseline import identifiers made unique")
	quit()

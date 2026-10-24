extends SceneTree
## Real mixed-state gallery captures, not an invented town arrangement.
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in range(n): await process_frame
func run() -> void:
	root.size = Vector2i(1280,720)
	var gallery: Control = load("res://scenes/asset_gallery.tscn").instantiate()
	root.add_child(gallery)
	await frames(30)
	var records: Array = []
	var names: Array[String] = ["approved-hall","converted-gate","unconverted-training","unconverted-pavilion"]
	for i in range(4):
		gallery.select_asset(i)
		gallery.preset("3/4")
		await frames(45)
		RenderingServer.force_draw(false)
		var file: String = "res://reports/environment-conversion-stage-1/"+names[i]+".png"
		var ok := root.get_texture().get_image().save_png(file)==OK
		records.append({"name":names[i],"catalog":gallery.catalog[i],"file":file,"captured":ok})
	var output := FileAccess.open("res://reports/environment-conversion-stage-1/context-captures.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(records,"\t"))
	output.close()
	print("Mixed-state gallery captures: "+str(records.size()))
	quit(0 if records.all(func(r):return r.captured) else 1)

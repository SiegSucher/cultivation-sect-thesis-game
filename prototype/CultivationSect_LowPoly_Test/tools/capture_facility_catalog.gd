extends SceneTree
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in range(n): await process_frame
func run() -> void:
	root.size=Vector2i(1280,720)
	var gallery: Control=load("res://scenes/asset_gallery.tscn").instantiate()
	root.add_child(gallery); await frames(30)
	var records: Array=[]
	var names: Array[String]=["preserved-approved-hall","preserved-stage1-gate","converted-training","converted-pavilion"]
	for i in range(4):
		gallery.select_asset(i); gallery.preset("3/4"); await frames(45)
		RenderingServer.force_draw(false)
		var file: String="res://reports/environment-conversion-stages-2-3/"+names[i]+".png"
		records.append({"file":file,"catalog":gallery.catalog[i],"pass":root.get_texture().get_image().save_png(file)==OK})
	FileAccess.open("res://reports/environment-conversion-stages-2-3/catalog-captures.json",FileAccess.WRITE).store_string(JSON.stringify(records,"\t"))
	print("Current catalog captures: ",records.size())
	quit(0 if records.all(func(r):return r.pass) else 1)

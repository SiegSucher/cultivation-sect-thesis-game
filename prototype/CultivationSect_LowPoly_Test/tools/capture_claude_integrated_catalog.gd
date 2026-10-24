extends SceneTree
const OUT := "res://reports/codex-claude-integration/"
var captures: Array=[]
func _initialize() -> void:call_deferred("run")
func frames(n: int) -> void:
	for i in range(n):await process_frame
func save(name: String) -> void:
	await frames(20);RenderingServer.force_draw(false)
	var file:=OUT+name+".png"
	captures.append({"file":file,"pass":root.get_texture().get_image().save_png(file)==OK})
func run() -> void:
	root.size=Vector2i(1280,720)
	var gallery: Control=load("res://scenes/asset_gallery.tscn").instantiate();root.add_child(gallery)
	await frames(30)
	for i in range(4,8):
		gallery.select_asset(i);await save("gallery-"+str(gallery.catalog[i].id))
		gallery.preset("Interior");await save("gallery-"+str(gallery.catalog[i].id)+"-interior")
	root.remove_child(gallery);gallery.free()
	var room:=Node3D.new();room.set_script(load("res://scripts/claude_asset_review.gd"));room.automated=true
	root.add_child(room);room.show_asset("dining_hall_kitchen");await frames(10)
	room.review_camera.make_current();room.review_camera.fov=75
	room.review_camera.position=Vector3(4.2,3,-6.2);room.review_camera.look_at(Vector3(-1.6,1.5,-10.6))
	await save("dining-kitchen-wide")
	room.review_camera.position=Vector3(0,3.2,3.4);room.review_camera.look_at(Vector3(0,2.1,-4.2))
	await save("dining-room-wide")
	FileAccess.open(OUT+"final-captures.json",FileAccess.WRITE).store_string(JSON.stringify(captures,"\t"))
	print("Final integration captures: ",captures.size())
	quit(0 if captures.all(func(c):return c.pass) else 1)

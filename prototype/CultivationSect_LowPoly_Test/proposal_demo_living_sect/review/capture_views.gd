extends SceneTree
const VIEWS := {
	"01-gate-distance": [Vector3(0,6.5,124), Vector3(0,8,80)],
	"02-gate-eye": [Vector3(12,5.65,99), Vector3(22,7,80)],
	"03-wall-join": [Vector3(23,7.5,88), Vector3(16,8,80)],
	"04-courtyard": [Vector3(0,17,64), Vector3(1,10.8,30)],
	"05-study-court": [Vector3(-3,12.3,41), Vector3(-13,11,29)],
	"06-social-court": [Vector3(28,12.5,47.5), Vector3(25,11,41)],
	"07-training": [Vector3(-80,17,5), Vector3(-95,15,-4)],
	"08-mentor": [Vector3(3,11.65,47), Vector3(5.8,11.05,43.2)],
	"09-lin": [Vector3(-6.8,11.5,41), Vector3(-9,11,38)],
	"10-overview": [Vector3(4,68,116), Vector3(0,10,25)],
	"11-living-practice": [Vector3(-2,12,58), Vector3(-12,11,53)],
}
var demo: Node3D
func _initialize() -> void: run()
func shot(out: String, id: String) -> void:
	for i in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(id+".png"))
func run() -> void:
	var variant := OS.get_cmdline_user_args()[0]
	var folder := {"before":"proposal_demo_sectlife", "creative":"proposal_demo_creative", "after":"proposal_demo_living_sect"}[variant] as String
	demo = load("res://"+folder+"/proposal_demo.tscn").instantiate()
	root.add_child(demo)
	current_scene = demo
	for i in 45: await physics_frame
	var out := "res://proposal_demo_living_sect/review/views/"+variant
	DirAccess.make_dir_recursive_absolute(out)
	demo.player.set_physics_process(false)
	demo.player.set_process_unhandled_input(false)
	demo.quest.set_process(false)
	demo.set_process(false)
	if "life" in demo and demo.life: demo.life.set_process(false)
	if "living" in demo and demo.living: demo.living.set_process(false)
	for c: CanvasLayer in demo.find_children("*", "CanvasLayer",true,false): c.visible = false
	for l: Label3D in demo.find_children("*","Label3D",true,false): l.visible = false
	demo.get_node("ObjectiveMarker").hide()
	var cam := Camera3D.new()
	cam.far = 900
	cam.fov = 62
	demo.add_child(cam)
	cam.make_current()
	for id: String in VIEWS:
		cam.position = VIEWS[id][0]
		cam.look_at(VIEWS[id][1])
		await shot(out,id)
	demo.player.position = Vector3(1,10.05,46)
	demo.player.avatar.rotation.y = PI
	demo.player.avatar.show()
	cam.position = Vector3(2.5,11.4,49)
	cam.look_at(Vector3(1,11,46))
	await shot(out,"12-player")
	var f := FileAccess.open(out.path_join("views.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"resolution":str(root.size),"cameras":VIEWS},"  "))
	print("CAPTURES ",variant," ",root.size)
	quit()

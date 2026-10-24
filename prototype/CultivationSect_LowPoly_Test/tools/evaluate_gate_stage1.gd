extends SceneTree
const OUT := "res://reports/environment-conversion-stage-1/"
var stage: Node3D
var variant := "after"
var checks: Array = []
var samples: Array = []
var cameras: Array = []
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in range(n): await process_frame
func check(label: String, ok: bool, detail: Variant = null) -> void:
	checks.append({"check":label,"pass":ok,"detail":detail})
	if not ok: push_warning(label+" "+str(detail))
func shot(name: String, at: Vector3, target: Vector3, fov:=58.0) -> void:
	stage.review_camera.make_current()
	stage.review_camera.position = at
	stage.review_camera.fov = fov
	stage.review_camera.look_at(target)
	await frames(24)
	RenderingServer.force_draw(false)
	check("Capture "+name,root.get_texture().get_image().save_png(OUT+variant+"-"+name+".png")==OK)
	cameras.append({"name":name,"position":str(at),"target":str(target),"fov":fov})
func sample(view: String, sweep:=false) -> void:
	await frames(45)
	var dt: Array[float] = []
	var previous := Time.get_ticks_usec()
	var draws := 0.0
	var primitives := 0.0
	var objects := 0.0
	for i in range(240):
		if sweep:
			stage.review_camera.position = Vector3(sin(i*TAU/240)*33,13,cos(i*TAU/240)*33)
			stage.review_camera.look_at(Vector3(0,6,0))
		await process_frame
		var now := Time.get_ticks_usec()
		dt.append((now-previous)/1000.0)
		previous = now
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		primitives += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		objects += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	var mean := 0.0
	for d in dt: mean += d/240
	dt.sort()
	samples.append({"view":view,"frames":240,"mean_ms":mean,"p50_ms":dt[120],"p95_ms":dt[228],"max_ms":dt[-1],"fps":1000/mean,"mean_draw_calls":draws/240,"mean_primitives":primitives/240,"mean_objects":objects/240,"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC)})
func walk(label: String, start: Vector3, finish: Vector3) -> void:
	var p: CharacterBody3D = stage.player
	p.position = start
	p.velocity = Vector3.ZERO
	for i in range(8): await physics_frame
	var n:=0
	while Vector2(p.position.x-finish.x,p.position.z-finish.z).length()>.15 and n<600:
		var direction: Vector3 = finish-p.position
		direction.y = 0
		p.drive = direction.normalized()
		await physics_frame
		n += 1
	p.drive = Vector3.ZERO
	check(label,Vector2(p.position.x-finish.x,p.position.z-finish.z).length()<.2 and p.is_on_floor(),{"position":str(p.position),"frames":n})
func run() -> void:
	variant = "before" if "--baseline" in OS.get_cmdline_user_args() else "after"
	root.size = Vector2i(1280,720)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	stage = Node3D.new()
	stage.set_script(load("res://scripts/gate_walkthrough.gd"))
	stage.automated = true
	stage.baseline = variant=="before"
	root.add_child(stage)
	await frames(60)
	check("Original local position orientation scale",stage.facility.transform==Transform3D.IDENTITY)
	var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://baseline/stage1_gate/sect_gate.json"))
	check("Complete collision and scale specification unchanged",stage.facility.specification==baseline)
	check("Two original moving leaves",stage.facility.leaves.size()==2)
	await shot("front",Vector3(0,10,32),Vector3(0,7,0))
	await sample("front")
	await shot("three-quarter",Vector3(26,17,27),Vector3(0,7,0))
	await sample("three-quarter")
	await sample("360 sweep",true)
	stage.facility.set_open_immediate(true)
	await frames(10)
	await shot("roof",Vector3(15,18,19),Vector3(0,10,0),56)
	await shot("passage",Vector3(0,2.25,5),Vector3(0,3,-5),80)
	await sample("passage")
	stage.player.camera.make_current()
	await walk("Front stair and gateway crossing",Vector3(0,.05,10),Vector3(0,.05,-9))
	await walk("Rear stair return",Vector3(0,.05,-9),Vector3(0,.61,0))
	check("Retained platform elevation",abs(stage.player.position.y-.60)<.10,stage.player.position.y)
	stage.player.position = Vector3(0,.61,1)
	stage.player.velocity = Vector3.ZERO
	stage.player.third_person = false
	stage.player.yaw = 0
	stage.player.pitch = -.12
	stage.player.camera.make_current()
	await frames(24)
	RenderingServer.force_draw(false)
	check("First-person image",root.get_texture().get_image().save_png(OUT+variant+"-first-person.png")==OK)
	check("First-person compatibility",stage.player.camera.current and not stage.player.avatar.visible)
	await sample("first-person")
	stage.player.third_person = true
	await frames(30)
	RenderingServer.force_draw(false)
	check("Third-person image",root.get_texture().get_image().save_png(OUT+variant+"-third-person.png")==OK)
	check("Third-person compatibility",stage.player.camera.current and stage.player.avatar.visible and stage.player.camera_distance>0)
	await sample("third-person")
	stage.facility.set_open_immediate(false)
	stage.player.position = Vector3(0,.61,4)
	stage.player.drive = Vector3(0,0,-1)
	for i in range(80): await physics_frame
	stage.player.drive = Vector3.ZERO
	check("Closed gate blocks player",stage.player.position.z>2.55,stage.player.position.z)
	stage.facility.request_toggle()
	for i in range(130): await physics_frame
	check("Existing interaction animates open",stage.facility.angle>89)
	var failed := checks.filter(func(c):return not c.pass).size()
	var file:=FileAccess.open(OUT+variant+"-results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"variant":variant,"utc":Time.get_datetime_string_from_system(true),"project_root":ProjectSettings.globalize_path("res://"),"adapter":RenderingServer.get_video_adapter_name(),"godot":Engine.get_version_info().string,"renderer":"gl_compatibility","resolution":[1280,720],"msaa":ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d"),"vsync":false,"samples":samples,"checks":checks,"camera_poses":cameras,"passed":checks.size()-failed,"failed":failed,"lighting":"Same hall-matched environment, one 100m shadowed sun and unchanged two unshadowed gate lanterns","limits":"Automated unchanged inspection fixture, not human playtest or integrated town/target hardware."},"\t"))
	file.close()
	print("Gate "+variant+": "+str(checks.size()-failed)+" PASS / "+str(failed)+" FAIL")
	quit(1 if failed else 0)

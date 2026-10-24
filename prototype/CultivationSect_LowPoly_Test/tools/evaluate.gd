extends SceneTree
## Reproducible rendered comparison using actual shared inspection movement.
var stage: Node3D
var baseline := false
var variant := "optimized"
var checks: Array = []
var samples: Array = []
var captures: Array = []
var geometry := {}

func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in range(n): await process_frame
func verify(label: String, ok: bool, detail: Variant = null) -> void:
	checks.append({"check":label,"pass":ok,"detail":detail})
	if not ok: push_warning(label+" "+str(detail))

func sample(label: String, sweep := false) -> void:
	await frames(45)
	var deltas: Array[float] = []
	var previous := Time.get_ticks_usec()
	var draws := 0.0
	var primitives := 0.0
	for i in range(240):
		if sweep:
			stage.view_camera.position = Vector3(sin(i*TAU/240)*48,18,cos(i*TAU/240)*48)
			stage.view_camera.look_at(Vector3(0,7,0))
		await process_frame
		var now := Time.get_ticks_usec()
		deltas.append(float(now-previous)/1000)
		previous = now
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		primitives += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var average := 0.0
	for d in deltas: average += d/240
	deltas.sort()
	samples.append({"view":label,"frames":240,"mean_ms":average,"average_fps":1000/average,"p50_ms":deltas[120],"p95_ms":deltas[228],"max_ms":deltas[-1],"frames_over_33ms":deltas.filter(func(v): return v>33.3).size(),"mean_draw_calls":draws/240,"mean_rendered_primitives":primitives/240,"static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)})

func shot(name: String, at: Vector3, target: Vector3, fov: float) -> void:
	stage.view_camera.make_current()
	stage.view_camera.position = at
	stage.view_camera.fov = fov
	stage.view_camera.look_at(target)
	await frames(24)
	RenderingServer.force_draw(false)
	var path := "res://reports/screenshots/"+variant+"-"+name+".png"
	verify("Screenshot "+name,root.get_texture().get_image().save_png(path) == OK)
	captures.append({"file":path,"position":str(at),"target":str(target),"fov":fov})

func walk(label: String, start: Vector3, finish: Vector3) -> void:
	var p: CharacterBody3D = stage.player
	p.position = start
	p.velocity = Vector3.ZERO
	for i in range(8): await physics_frame
	var n := 0
	while Vector2(p.position.x-finish.x,p.position.z-finish.z).length() > .15 and n < 700:
		var v := finish-p.position
		v.y = 0
		p.drive = v.normalized()
		await physics_frame
		n += 1
	p.drive = Vector3.ZERO
	verify(label,Vector2(p.position.x-finish.x,p.position.z-finish.z).length()<.20,{"actual":str(p.position),"target":str(finish),"physics_frames":n,"floor":p.is_on_floor()})
	verify(label+" stable floor",p.is_on_floor() and p.position.y>-.05)

func run() -> void:
	baseline = "--baseline" in OS.get_cmdline_user_args()
	variant = "baseline" if baseline else "optimized"
	root.size = Vector2i(1280,720)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	stage = Node3D.new()
	stage.set_script(load("res://scripts/hall_experiment.gd"))
	stage.automated = true
	stage.baseline = baseline
	root.add_child(stage)
	await frames(60)
	verify("Identity transform and origin",stage.hall.transform==Transform3D.IDENTITY)
	verify("All three doors loaded",stage.hall.doors.size()==3)
	var triangles := 0
	var surfaces := 0
	var bounds := AABB()
	var first := true
	for mesh in stage.hall.static_model.find_children("*","MeshInstance3D",true,false):
		var aabb: AABB = mesh.global_transform*mesh.get_aabb()
		bounds = aabb if first else bounds.merge(aabb)
		first = false
		for s in range(mesh.mesh.get_surface_count()):
			var a: Array = mesh.mesh.surface_get_arrays(s)
			triangles += a[Mesh.ARRAY_INDEX].size()/3 if a[Mesh.ARRAY_INDEX]!=null else a[Mesh.ARRAY_VERTEX].size()/3
			surfaces += 1
	geometry = {"near_static_triangles":triangles,"near_static_surfaces":surfaces,"bounds":str(bounds),"bounds_min":[bounds.position.x,bounds.position.y,bounds.position.z],"bounds_max":[bounds.end.x,bounds.end.y,bounds.end.z]}
	verify("Inside existing envelope",bounds.position.x>=-20.843 and bounds.end.x<=20.843 and bounds.position.z>=-12.001 and bounds.end.z<=18.181 and bounds.end.y<=18.311,geometry)
	await shot("front",Vector3(0,13,45),Vector3(0,8,2),58)
	await sample("front")
	await shot("three-quarter",Vector3(33,23,41),Vector3(0,8,2),58)
	await sample("three-quarter")
	await sample("360-degree exterior sweep",true)
	await shot("roof-detail",Vector3(18,19,24),Vector3(0,11,4),56)
	for door in stage.hall.doors: door.set_open_immediate(true)
	await frames(10)
	await shot("interior",Vector3(0,3.22,5.9),Vector3(0,4.8,-7),82)
	await sample("interior")
	stage.player.camera.make_current()
	stage.player.third_person = false
	await walk("Main stair, door and central aisle",Vector3(0,.05,24),Vector3(0,1.55,-2.3))
	await walk("Dais stair climb",Vector3(0,1.55,-2.3),Vector3(0,2.15,-4.6))
	verify("Dais elevation",abs(stage.player.position.y-2.15)<.12,stage.player.position.y)
	await walk("West administration room",Vector3(0,1.56,-.8),Vector3(-13,1.56,-.8))
	await walk("East administration room",Vector3(0,1.56,-.8),Vector3(13,1.56,-.8))
	stage.player.position = Vector3(0,1.56,4.8)
	stage.player.velocity = Vector3.ZERO
	stage.player.yaw = 0
	stage.player.pitch = .04
	stage.player.third_person = false
	stage.player.camera.make_current()
	await frames(24)
	RenderingServer.force_draw(false)
	verify("First-person capture",root.get_texture().get_image().save_png("res://reports/screenshots/"+variant+"-first-person.png")==OK)
	verify("First-person camera",stage.player.camera.current and not stage.player.avatar.visible)
	await sample("first-person interior")
	stage.player.third_person = true
	await frames(30)
	verify("Third-person camera",stage.player.camera.current and stage.player.avatar.visible and stage.player.camera_distance>0,stage.player.camera_distance)
	RenderingServer.force_draw(false)
	verify("Third-person capture",root.get_texture().get_image().save_png("res://reports/screenshots/"+variant+"-third-person.png")==OK)
	await sample("third-person interior")
	# Push the real controller into a closed door; verify it cannot cross it.
	for door in stage.hall.doors: door.set_open_immediate(false)
	stage.player.position = Vector3(0,1.56,9)
	stage.player.drive = Vector3(0,0,-1)
	for i in range(100): await physics_frame
	stage.player.drive = Vector3.ZERO
	verify("Closed entrance blocks movement",stage.player.position.z>7.4,stage.player.position.z)
	var result := {"variant":variant,"godot":Engine.get_version_info().string,"adapter":RenderingServer.get_video_adapter_name(),"renderer":"gl_compatibility","resolution":[1280,720],"vsync":false,"msaa_setting":ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d"),"geometry":geometry,"samples":samples,"checks":checks,"captures":captures,"limits":"Automated real inspection controller; no human playtest, production player, populated world, exported game or target low-end hardware."}
	result["measured_utc"] = Time.get_datetime_string_from_system(true)
	result["project_root"] = ProjectSettings.globalize_path("res://")
	result["user_data_dir"] = ProjectSettings.globalize_path("user://")
	result["application_name"] = ProjectSettings.get_setting("application/config/name")
	var file := FileAccess.open("res://reports/"+variant+"-results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	file.close()
	var failed := checks.filter(func(c): return not c.pass).size()
	print(variant+": "+str(checks.size()-failed)+" PASS / "+str(failed)+" FAIL")
	quit(1 if failed else 0)

extends SceneTree
## Real rendered comparison. This does not change the working review fixtures.
const OUT := "res://reports/training-ground-fix/benchmarks/"
var stage: Node3D
var review: Camera3D
var short := "training"
var variant := "after"
var suffix := ""
var samples: Array = []
var poses: Array = []
var captures: Array = []
var label := ""
var static_only := false
var physics_off := false
var no_shadows := false
var gpu_timing := false
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in range(n): await process_frame
func capture(view: String) -> void:
	await frames(24)
	RenderingServer.force_draw(false)
	var file := OUT+short+"-"+variant+suffix+"-"+view+".png"
	captures.append({"file":file,"pass":root.get_texture().get_image().save_png(file)==OK})
func pose(view: String, at: Vector3, target: Vector3, fov := 65.0) -> void:
	review.make_current()
	review.position=at; review.fov=fov; review.look_at(target)
	poses.append({"view":view,"position":str(at),"target":str(target),"fov":fov})
	await capture(view)
func sample(view: String, sweep := false) -> void:
	await frames(45)
	print("PROFILE_BEGIN ",label," ",view)
	var times: Array[float] = []
	var previous := Time.get_ticks_usec()
	var draws := 0.0
	var primitives := 0.0
	var objects := 0.0
	var process_ms := 0.0
	var physics_ms := 0.0
	var gpu_ms := 0.0
	var gpu_cpu_ms := 0.0
	for i in range(240):
		if sweep:
			var radius := 60.0 if short=="training" else 32.0
			review.position=Vector3(sin(i*TAU/240)*radius,32 if short=="training" else 19,cos(i*TAU/240)*radius)
			review.look_at(Vector3(0,2 if short=="training" else 8,0))
		await process_frame
		var now:=Time.get_ticks_usec()
		times.append((now-previous)/1000.0); previous=now
		draws+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		primitives+=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		objects+=Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
		process_ms+=Performance.get_monitor(Performance.TIME_PROCESS)*1000.0
		physics_ms+=Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0
		if gpu_timing:
			gpu_ms+=RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid())
			gpu_cpu_ms+=RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid())
	var mean:=0.0
	for t in times: mean+=t/240
	times.sort()
	samples.append({"view":view,"frames":240,"mean_ms":mean,"p50_ms":times[120],"p95_ms":times[228],"max_ms":times[-1],"fps":1000/mean,"mean_draw_calls":draws/240,"mean_primitives":primitives/240,"mean_objects":objects/240,"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"process_ms":process_ms/240,"physics_ms":physics_ms/240,"viewport_gpu_ms":gpu_ms/240,"viewport_render_cpu_ms":gpu_cpu_ms/240})
	print("PROFILE_END ",label," ",view)
func run() -> void:
	var args:=OS.get_cmdline_user_args()
	short="pavilion" if "--pavilion" in args else "training"
	variant="before" if "--baseline" in args else "after"
	for arg: String in args:
		if arg.begins_with("--run="):label=arg.trim_prefix("--run=")
	suffix="-"+label
	static_only="--static-only" in args
	physics_off="--physics-off" in args
	no_shadows="--no-shadows" in args
	root.size=Vector2i(1280,720)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED); Engine.max_fps=0
	var script_name := "training_walkthrough" if short=="training" else "scripture_walkthrough"
	stage=Node3D.new()
	stage.set_script(load(("res://baseline/stage23_" if variant=="before" else "res://scripts/")+script_name+".gd"))
	stage.automated=true
	root.add_child(stage)
	# Lock the historical camera policy equally in baseline/current comparisons;
	# the approved current indoor camera/controller is never edited.
	stage.player.indoor_camera_enabled=false
	if "--old-roof" in args or "--clean-roof" in args:
		var resource: String="res://reports/training-ground-fix/before/martial_training_ground.json.txt" if "--old-roof" in args else "res://reports/training-ground-fix/candidate-training-roof.json"
		var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(resource))
		var faces:=PackedVector3Array()
		for point: Array in data.roof_collision_faces:faces.append(Vector3(point[0],point[1],point[2]))
		stage.facility.get_node("AuthoredStructureCollision/StaticRoofUndersides").shape.set_faces(faces)
	if no_shadows:
		for light: DirectionalLight3D in stage.find_children("*","DirectionalLight3D",true,false):light.shadow_enabled=false
	if physics_off:
		stage.player.set_physics_process(false)
		PhysicsServer3D.set_active(false)
	gpu_timing=RenderingServer.has_method("viewport_set_measure_render_time")
	if gpu_timing:RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	review=Camera3D.new(); stage.add_child(review)
	await frames(60)
	if short=="training":
		await pose("overview",Vector3(48,38,50),Vector3(0,1,-1),52)
		await sample("overview")
		await pose("court",Vector3(0,2.1,25),Vector3(0,2.3,-20),78)
		await sample("court")
		await pose("shelter",Vector3(12,5.3,-8.5),Vector3(0,2.8,-22),68)
		await sample("shelter")
		await pose("equipment",Vector3(-18.6,2.3,14.2),Vector3(-23.9,1.2,8),65)
		await pose("racks",Vector3(20.6,2.4,23.2),Vector3(25.3,1.5,17.5),68)
	else:
		await pose("overview",Vector3(27,22,32),Vector3(0,8,0),50)
		await sample("overview")
		await pose("ground-library",Vector3(0,2.74,5.4),Vector3(0,2.7,-4),80)
		await sample("ground-library")
		await pose("ordinary-gallery",Vector3(4,7,4.8),Vector3(-6.6,7,-4),80)
		await sample("ordinary-gallery")
		await pose("archive",Vector3(0,11.55,4.7),Vector3(0,11.5,-3.8),84)
		await sample("archive")
		await pose("stairs",Vector3(6.3,2.8,3.8),Vector3(6.3,5,-1.5),75)
	await sample("360 sweep",true)
	if not static_only:
		stage.player.position=Vector3(0,.32,-21.4) if short=="training" else Vector3(0,1.10,5.4)
		stage.player.velocity=Vector3.ZERO
		stage.player.yaw=PI if short=="training" else 0.0
		stage.player.pitch=-.08
		stage.player.camera.make_current()
		for third: bool in [false,true]:
			stage.player.third_person=third
			await frames(30)
			var name: String = "third-person" if third else "first-person"
			poses.append({"view":name,"player":str(stage.player.position),"yaw":stage.player.yaw,"pitch":stage.player.pitch,"fov":stage.player.camera.fov})
			await capture(name)
			await sample(name)
	var report: Dictionary = {"facility":short,"variant":variant,"run":label,"physics_off":physics_off,"shadows_off":no_shadows,"static_only":static_only,"viewport_timer_enabled":gpu_timing,"legacy_camera_policy":true,"utc":Time.get_datetime_string_from_system(true),"project_root":ProjectSettings.globalize_path("res://"),"adapter":RenderingServer.get_video_adapter_name(),"godot":Engine.get_version_info().string,"renderer":"gl_compatibility","resolution":[1280,720],"msaa":ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d"),"vsync":false,"samples":samples,"camera_poses":poses,"captures":captures,"failed":captures.filter(func(c):return not c.pass).size(),"conditions":"Existing per-facility walkthrough rig: ambient .55, shadowed sun 180m Training / 100m Pavilion; Pavilion retains six unshadowed lights. 45-frame warmups, 240 measured frames, uncapped. No fixed-fps used for benchmark.","limits":"Short local rendered observations. No human, populated town, representative low-end hardware or sustained thermal test."}
	FileAccess.open(OUT+short+"-"+variant+suffix+"-results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(short," ",variant,suffix,": ",samples.size()," rendered samples; captures failed: ",report.failed)
	quit(1 if report.failed else 0)

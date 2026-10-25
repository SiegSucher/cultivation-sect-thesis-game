extends SceneTree
## Frame-time probe (vsync off, real window): the forest arrival, the
## living court with the basin flowing and the Qi aura on, the terminal open beside the court, and
## (boundary round) the Gate with both wall wings and the whole compound with every wall in view.
## godot --path . --script res://proposal_demo_living_sect/review/perf_probe.gd -- <out.json>
const AT_MENTOR := Vector3(4.4, 10.05, 45.6)
var demo: Node3D

func _initialize() -> void:
	run()

func sample(label: String, seconds := 8.0) -> Dictionary:
	for i in 30: await process_frame                 # settle
	var times := []
	var t0 := Time.get_ticks_usec()
	var last := t0
	while Time.get_ticks_usec()-t0 < seconds*1e6:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append((now-last)/1000.0)
		last = now
	times.sort()
	var avg := 0.0
	for t: float in times: avg += t
	avg /= times.size()
	var r := {"view": label, "frames": times.size(), "avg_ms": snappedf(avg, .01), "avg_fps": snappedf(1000.0/avg, .1),
		"p95_ms": snappedf(times[int(times.size()*.95)], .01), "worst_ms": snappedf(times[-1], .01),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
	print(r)
	return r

func run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	demo = load("res://proposal_demo_living_sect/proposal_demo.tscn").instantiate()
	root.add_child(demo)
	current_scene = demo
	for i in 10: await physics_frame
	var quest: CanvasLayer = demo.quest
	var out := []
	out.append(await sample("forest arrival, Guide in view"))
	demo.jump_to(AT_MENTOR, -.9)
	demo.awaken_effect()
	demo.basin.activate()
	demo.sound.start_water(demo.basin)
	out.append(await sample("living court: basin flowing, Qi aura, water sound"))
	quest.stage = 1
	quest.language = "python"
	quest.show_code()
	out.append(await sample("terminal open with the coding view"))
	# Boundary round: the Gate with both wings, and the whole compound with every wall in frame.
	quest.visible = false
	var cam := Camera3D.new()
	cam.far = 900
	demo.add_child(cam)
	cam.make_current()
	quest.close_ui()
	cam.make_current()
	cam.position = Vector3(0,15,56)
	cam.look_at(Vector3(0,11,30))
	out.append(await sample("populated court panorama: reading, training, tea and moving residents"))
	cam.position = Vector3(0, 6.5, 124)
	cam.look_at(Vector3(0, 6, 80))
	out.append(await sample("Gate and both wall wings in view"))
	cam.position = Vector3(0, 95, 215)
	cam.look_at(Vector3(0, 6, 10))
	out.append(await sample("valley view: the whole compound and every wall in frame"))
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_string(JSON.stringify({"gpu": RenderingServer.get_video_adapter_name(),"cpu":OS.get_processor_name(),"logical_processors":OS.get_processor_count(),"ram":OS.get_memory_info(),"vsync":"disabled","sample_seconds":8,"warmup_frames_per_view":30,"additional_residents":demo.living.residents.size(),"total_characters_including_player":23,"godot":Engine.get_version_info(), "renderer": RenderingServer.get_current_rendering_method(), "window": str(DisplayServer.window_get_size()), "godot_static_memory_mib": snappedf(float(OS.get_static_memory_usage())/1048576.0, .1), "lantern_light_count": demo.evening.lamps.size(), "samples": out}, "  "))
	f.close()
	quit()

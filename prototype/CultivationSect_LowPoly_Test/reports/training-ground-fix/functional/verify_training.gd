## Local adapter of existing regression. Preservation is audited separately against the stage manifest.
extends SceneTree
## Standalone physics, gallery, and inspection-controller rehearsal evidence.
var OUT := "res://reports/training-ground-fix/functional/"
var checks: Array[Dictionary] = []
var gallery: Control
var yard: Node3D
var space: PhysicsDirectSpaceState3D
var walkthrough: Node3D
var captures: Array[String] = []
var camera_poses: Array[Dictionary] = []
var performance_sample: Dictionary = {}
var movement_samples: Array[Dictionary] = []
var capture := false

func _initialize() -> void: call_deferred("run")

func check(words: String, passed: bool, detail: Variant = null) -> void:
	checks.append({"check":words,"pass":passed,"detail":detail})
	if not passed: push_error(words+" "+str(detail))

func frames(count := 4) -> void:
	for i in range(count): await process_frame

func settle() -> void:
	await physics_frame
	await physics_frame
	await process_frame

func support(x: float,z: float) -> Dictionary:
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x,3.2,z),Vector3(x,-.15,z),1))

func human_clear(ground: Vector3) -> bool:
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.8
	capsule.radius = .28
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform.origin = ground+Vector3(0,.94,0)
	query.collision_mask = 1
	query.margin = .001
	return space.intersect_shape(query,1).is_empty()

func route(words: String, points: Array[Vector2]) -> void:
	var failures: Array = []
	for p: Vector2 in points:
		var ground := support(p.x,p.y)
		if ground.is_empty(): failures.append({"at":str(p),"problem":"No support"})
		elif not human_clear(ground.position): failures.append({"at":str(p),"problem":"Capsule obstructed"})
	check(words,failures.is_empty(),{"samples":points.size(),"failures":failures})

func line(a: Vector2,b: Vector2,spacing := .25) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var count := ceili(a.distance_to(b)/spacing)
	for i in range(count+1): points.append(a.lerp(b,float(i)/count))
	return points

func verify_geometry() -> void:
	var roof: ConcavePolygonShape3D = yard.get_node("AuthoredStructureCollision/StaticRoofUndersides").shape
	var rf := roof.get_faces()
	var invalid := 0
	for i in range(0,rf.size(),3):
		if (rf[i+1]-rf[i]).cross(rf[i+2]-rf[i]).length_squared()==0: invalid+=1
	check("Permanent roof has 4476 valid faces and no degenerate triangles",rf.size()/3==4476 and invalid==0)
	var spec: Dictionary = yard.specification
	check("New facility, shared metre scale and adult reference",spec.metres_per_unit == 1 and spec.reference_character_height == 1.8 and spec.revision == "2026-10-18-new-training-ground")
	check("Ground-centered identity transform",yard.transform.is_equal_approx(Transform3D.IDENTITY) and Vector3(spec.origin_local[0],spec.origin_local[1],spec.origin_local[2]).is_zero_approx())
	check("Full envelope measured including entrance steps",absf(gallery.bounds.size.x-68.0) < .03 and absf(gallery.bounds.size.z-57.2) < .03 and gallery.bounds.size.y > 6.7 and gallery.bounds.size.y < 6.8,str(gallery.bounds.size))
	check("One complete training catalog entry",gallery.catalog.size() == 12 and gallery.catalog[2].id == "martial_training_ground")
	check("Organized repeated equipment and seven reusable kinds",yard.equipment_instances == 27 and spec.prop_definitions.size() == 7)
	check("Near and distant complexity budgets",spec.assembled_triangles < 180000 and spec.lod.triangles < 20000,{"near":spec.assembled_triangles,"distant_static":spec.lod.triangles})
	check("Repeated equipment uses shared instanced mesh batches",yard.equipment.find_children("*","MultiMeshInstance3D",true,false).size() < 35)
	var grid: Array[Vector2] = []
	for x in range(-16,17,2):
		for z in range(-14,15,2): grid.append(Vector2(x,z))
	route("Central 34x30m court has support and clear adult volume",grid)
	route("Front approach and instructor dais access",line(Vector2(0,29),Vector2(0,-22)))
	for side: float in [-1,1]:
		route("Main side circulation "+str(side),line(Vector2(side*19.1,24),Vector2(side*19.1,-18)))
		route("Side entrance threshold "+str(side),line(Vector2(side*33.9,0),Vector2(side*18.9,0)))
		route("Rear shelter entrance "+str(side),line(Vector2(side*24.6,-16.6),Vector2(side*24.6,-22)))
	for z: float in [-12,-6,0,6,12]: route("Sword station cross aisle "+str(z),line(Vector2(-19.2,z),Vector2(-30.5,z)))
	route("Sword rows circulation",line(Vector2(-26.6,13),Vector2(-26.6,-13)))
	route("Staff lane circulation",line(Vector2(22,10),Vector2(22,-10)))
	route("Staff lane outside posts",line(Vector2(29.7,10),Vector2(29.7,-10)))
	for p: Vector2 in [Vector2(-24,9),Vector2(25.6,-1.5),Vector2(-25.3,18.2),Vector2(25.3,18.2),Vector2(12,27.4),Vector2(32.4,10)]:
		check("Solid equipment/boundary blocks at "+str(p),not human_clear(Vector3(p.x,.31,p.y)))
	for p: Vector3 in [Vector3(0,.91,-22),Vector3(-24.6,.61,-22),Vector3(24.6,.61,-22)]:
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3(0,2,0),p+Vector3(0,8,0),1))
		check("Shelter roof has standing clearance "+str(p),not hit.is_empty() and hit.position.y-p.y > 3.0,str(hit.get("position")))
	var bad_camera: Array = []
	for x: float in [-19.1,0,19.1]:
		for z in range(-15,26,5):
			var ground := support(x,z)
			for height: float in [1.65,2.6]:
				var ball := SphereShape3D.new()
				ball.radius = .20
				var query := PhysicsShapeQueryParameters3D.new()
				query.shape = ball
				query.transform.origin = ground.position+Vector3(0,height,0)
				query.collision_mask = 1
				if not space.intersect_shape(query,1).is_empty(): bad_camera.append([x,z,height])
	check("54 camera-volume clearance samples on main routes",bad_camera.is_empty(),bad_camera)
	for kind: String in spec.prop_definitions:
		var prop: Node3D = load("res://scenes/props/training/"+kind+".tscn").instantiate()
		gallery.stage.add_child(prop)
		check("Reusable standalone prop loads: "+kind,prop.get_node_or_null("BlenderEquipment") != null and prop.get_node_or_null("EquipmentCollision") != null)
		gallery.stage.remove_child(prop)
		prop.free()
	for path: String in ["res://scripts/martial_training_ground.gd","res://scripts/training_prop.gd","res://scripts/training_collision.gd","res://assets/gallery/catalog.json"]:
		var text := FileAccess.get_file_as_string(path)
		check("No discarded project dependency "+path,"reedwell-3d" not in text and "res://assets/town/" not in text and "architecture-lab" not in text)
	check("Walk asset action available, no door controls for yard",not gallery.walkthrough_button.disabled and gallery.doors_button.disabled)

func shot(name: String, position: Vector3, target: Vector3, fov := 58.0) -> void:
	var offset := position-target
	gallery.target = target
	gallery.distance = offset.length()
	gallery.pitch = asin(offset.y/offset.length())
	gallery.yaw = atan2(offset.x,offset.z)
	gallery.camera.fov = fov
	gallery.update_camera()
	await frames(16)
	check("Camera pose "+name,gallery.camera.position.distance_to(position) < .001)
	camera_poses.append({"image":name,"position":str(position),"target":str(target),"fov":fov})
	RenderingServer.force_draw(false)
	check("Rendered "+name,root.get_texture().get_image().save_png(OUT+name) == OK)
	captures.append(name)

func gallery_evidence() -> void:
	gallery.scale_figure.position = Vector3(-22.5,.31,9)
	await shot("01-elevated-overview.png",Vector3(40,44,50),Vector3(0,0,-1),46)
	await shot("02-main-ground-view.png",Vector3(0,2.0,25.0),Vector3(0,2.2,-20),78)
	await shot("03-three-quarter.png",Vector3(48,30,43),Vector3(0,1,-1),50)
	await shot("04-dummy-human-scale.png",Vector3(-18.6,2.3,14.2),Vector3(-23.9,1.2,8.0),65)
	await shot("05-weapon-racks.png",Vector3(20.6,2.4,23.2),Vector3(25.3,1.5,17.5),68)
	await shot("06-instructor-pavilion.png",Vector3(12,5.3,-8.5),Vector3(0,2.8,-22),68)
	await shot("07-sword-zone.png",Vector3(-19.0,3.0,15),Vector3(-26,1.2,-3),78)
	await shot("08-staff-zone.png",Vector3(19.5,3.0,12),Vector3(26.0,1.4,-6),78)
	gallery.preset("3/4")
	await frames(30)
	var deltas: Array[float] = []
	var previous := Time.get_ticks_usec()
	for i in range(180):
		await process_frame
		var now := Time.get_ticks_usec()
		deltas.append(float(now-previous)/1000)
		previous = now
	deltas.sort()
	performance_sample={"adapter":RenderingServer.get_video_adapter_name(),"renderer":"GL Compatibility","window":str(root.size),"frames":180,"frame_ms_p50":deltas[90],"frame_ms_p95":deltas[171],"draw_calls_whole_window":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"limits":"Isolated asset and UI only; populated world, export and target-device performance unverified."}

func reset_player(p: Vector3, third: bool) -> void:
	walkthrough.player.global_position = p
	walkthrough.player.velocity = Vector3.ZERO
	walkthrough.player.drive = Vector3.ZERO
	walkthrough.player.third_person = third
	walkthrough.player.yaw = 0
	walkthrough.player.pitch = 0
	await settle()

func walk_to(words: String,target: Vector3,max_frames: int) -> void:
	var player: CharacterBody3D = walkthrough.player
	var count := 0
	var highest_error := 0.0
	while count < max_frames:
		var offset := target-player.global_position
		offset.y = 0
		if offset.length() < .16: break
		player.drive = offset.normalized()
		await physics_frame
		count += 1
		highest_error = maxf(highest_error,absf(player.global_position.y-target.y))
	player.drive = Vector3.ZERO
	await settle()
	var end: Vector3 = player.global_position
	var remaining := Vector2(end.x-target.x,end.z-target.z).length()
	var passed := remaining < .23 and absf(end.y-target.y) < .15
	var detail := {"end":str(end),"target":str(target),"frames":count,"remaining_m":remaining,"camera":"third" if player.third_person else "first","fixture":"1.8m/.28m capsule, move_and_slide at 4m/s"}
	movement_samples.append(detail)
	check(words,passed,detail)

func walkthrough_capture(name: String) -> void:
	walkthrough.update_overlay()
	await frames(16)
	RenderingServer.force_draw(false)
	check("Inspection gameplay capture "+name,root.get_texture().get_image().save_png(OUT+name) == OK)
	captures.append(name)

func movement_rehearsal() -> void:
	gallery.visible = false
	gallery.viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	walkthrough = load("res://scenes/review/training_walkthrough.tscn").instantiate()
	walkthrough.automated = true
	root.add_child(walkthrough)
	await settle()
	for third: bool in [false,true]:
		var mode := "Third-person fixture" if third else "First-person fixture"
		await reset_player(Vector3(0,.02,30.5),third)
		await walk_to(mode+" climbs front threshold",Vector3(0,.31,25),180)
		await walk_to(mode+" traverses full court",Vector3(0,.31,-16.5),720)
		await walk_to(mode+" climbs instructor dais",Vector3(0,.91,-21.4),150)
		if capture:
			walkthrough.player.yaw = PI
			walkthrough.player.pitch = -.12
			walkthrough.player.update_camera()
			await walkthrough_capture("10-third-person-dais.png" if third else "09-first-person-dais.png")
			walkthrough.player.yaw = 0
			walkthrough.player.pitch = 0
		await walk_to(mode+" leaves instructor dais",Vector3(0,.31,-15.5),150)
		await walk_to(mode+" reaches west lane",Vector3(-19.2,.31,-15.5),360)
		await walk_to(mode+" approaches sword stations",Vector3(-19.2,.31,6),380)
		await walk_to(mode+" crosses between dummy rows",Vector3(-26.6,.31,6),180)
		if capture and third:
			walkthrough.player.yaw = -.80
			walkthrough.player.update_camera()
			await walkthrough_capture("11-third-person-dummy-lane.png")
		await reset_player(Vector3(19.5,.32,13),third)
		await walk_to(mode+" reaches staff lane",Vector3(22,.31,10),120)
		await walk_to(mode+" traverses staff lane",Vector3(22,.31,-10),380)
		if capture and not third: await walkthrough_capture("12-first-person-staff-lane.png")
	# A real movement attempt against a dummy must stop rather than tunnel.
	await reset_player(Vector3(-21.7,.32,9),true)
	walkthrough.player.drive = Vector3.LEFT
	for i in range(90): await physics_frame
	walkthrough.player.drive = Vector3.ZERO
	check("Inspection movement stops at wooden dummy",walkthrough.player.position.x > -23.7 and walkthrough.player.position.x < -22.7,str(walkthrough.player.position))
	# Face inward under the pavilion: the boom behind the player must retract
	# before it crosses the rear structural column at eye height.
	await reset_player(Vector3(0,.92,-23.8),true)
	walkthrough.player.yaw = PI
	walkthrough.player.update_camera()
	await settle()
	check("Third-person inspection boom retracts at timber column",walkthrough.player.camera_distance < 1.1,walkthrough.player.camera_distance)
	if capture: await walkthrough_capture("13-third-person-camera-boundary.png")
	root.remove_child(walkthrough)
	walkthrough.free()
	gallery.visible = true
	gallery.viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

func run() -> void:
	if "--props-only" in OS.get_cmdline_user_args(): OUT = OUT.replace("training-verification/", "training-props-verification/")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.size=Vector2i(1280,720)
	capture = "--capture" in OS.get_cmdline_user_args()
	gallery = load("res://scenes/asset_gallery.tscn").instantiate()
	root.add_child(gallery)
	current_scene = gallery
	await frames(6)
	gallery.select_asset(2)
	await settle()
	yard = gallery.model
	space = yard.get_world_3d().direct_space_state
	verify_geometry()
	if capture: await gallery_evidence()
	await movement_rehearsal()
	var failures := checks.filter(func(c: Dictionary) -> bool: return not c.pass).size()
	var report := {"project_root":ProjectSettings.globalize_path("res://"),"passed":checks.size()-failures,"failed":failures,"checks":checks,"captures":captures,"camera_poses":camera_poses,"movement_samples":movement_samples,"performance_note":"This fixed-fps functional test is not a performance benchmark; use benchmark_facility_stages.gd results.",
		"not_tested":["Future production character/controller and its cameras","Human keyboard/mouse rehearsal","Reserved plot/map fit and world connection","Populated-world/target-device performance","Exported executable","NPC navigation mesh/pathfinding","Open source button"]}
	FileAccess.open(OUT+("rendered-results.json" if capture else "headless-results.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("MARTIAL TRAINING GROUND: ",report.passed," PASS / ",failures," FAIL")
	quit(1 if failures else 0)

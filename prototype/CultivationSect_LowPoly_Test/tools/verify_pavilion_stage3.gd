## Local adapter of the existing three-storey/archive regression. No outside-project dependencies.
extends SceneTree
var OUT := "res://reports/environment-conversion-stages-2-3/pavilion-verification/"
var room: Node3D
var checks: Array[Dictionary] = []
var movement: Array[Dictionary] = []
var captures: Array[Dictionary] = []
var camera_bad: Array = []
var capture := false
var audit_visuals: StaticBody3D
var camera_samples := 0
func _initialize() -> void: call_deferred("run")
func check(name: String,passed: bool,detail: Variant = null) -> void:
	checks.append({"check":name,"pass":passed,"detail":detail})
	if not passed:push_error(name+" "+str(detail))
func settle(n := 3) -> void:
	for i in range(n):await physics_frame
func reset(at: Vector3,third: bool) -> void:
	room.player.position = at
	room.player.velocity = Vector3.ZERO
	room.player.drive = Vector3.ZERO
	room.player.third_person = third
	room.player.yaw = 0
	room.player.pitch = 0
	await settle()
func sample_camera() -> void:
	camera_samples += 1
	var sphere := SphereShape3D.new()
	sphere.radius = .17
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = sphere
	q.transform.origin = room.player.camera.global_position
	q.collision_mask = 1
	if not room.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty():camera_bad.append(str(q.transform.origin))
func walk_to(name: String,target: Vector3,max_frames := 260) -> bool:
	var p: CharacterBody3D = room.player
	var n := 0
	while n<max_frames:
		var d := target-p.position
		d.y = 0
		if d.length()<.14:break
		p.drive = d.normalized()
		await physics_frame
		if n%10==0:sample_camera()
		n += 1
	p.drive = Vector3.ZERO
	await settle()
	var remaining := Vector2(p.position.x-target.x,p.position.z-target.z).length()
	var passed := remaining<.24 and absf(p.position.y-target.y)<.16 and p.is_on_floor()
	var detail := {"end":str(p.position),"target":str(target),"frames":n,"third_person":p.third_person,"actual_controller":"unchanged 1.8m/.28m, move_and_slide at 4m/s"}
	movement.append(detail)
	check(name,passed,detail)
	return passed
func shot(name: String,position: Vector3,target: Vector3,fov := 75.0) -> void:
	if not capture:return
	room.player.set_physics_process(false)
	room.player.avatar.hide()
	room.player.camera.fov = fov
	room.player.camera.global_position = position
	room.player.camera.look_at(target)
	room.update_overlay()
	for i in range(12):await process_frame
	RenderingServer.force_draw(false)
	check("Rendered "+name,root.get_texture().get_image().save_png(OUT+name)==OK)
	captures.append({"image":name,"position":str(position),"target":str(target),"fov":fov})
	room.player.set_physics_process(true)
	room.player.camera.fov = 75
	room.player.update_camera()
func gameplay_shot(name: String) -> void:
	if not capture:return
	room.update_overlay()
	for i in range(12):await process_frame
	RenderingServer.force_draw(false)
	check("Gameplay capture "+name,root.get_texture().get_image().save_png(OUT+name)==OK)
	captures.append({"image":name,"player":str(room.player.position),"camera":str(room.player.camera.global_position),"feedback":room.access_message})

func headroom() -> void:
	audit_visuals = StaticBody3D.new()
	audit_visuals.name = "ReadOnlyVisualHeadroomAudit"
	audit_visuals.collision_layer = 16
	audit_visuals.collision_mask = 0
	room.add_child(audit_visuals)
	for mesh: MeshInstance3D in room.facility.static_model.find_children("*","MeshInstance3D",true,false):
		var cs := CollisionShape3D.new()
		cs.shape = mesh.mesh.create_trimesh_shape()
		cs.transform = mesh.global_transform
		audit_visuals.add_child(cs)
	await settle()
	var failures: Array = []
	var count := 0
	for flight: Dictionary in [
		{"xs":[5.5,6.3,7.1],"y0":1.086,"y1":5.35,"z0":4.2,"z1":-3.2},
		{"xs":[-5.15,-4.6,-4.05],"y0":5.35,"y1":9.9,"z0":4.2,"z1":-3.6}]:
		for x: float in flight.xs:
			for i in range(81):
				var t := float(i)/80
				var p := Vector3(x,lerpf(flight.y0,flight.y1,t),lerpf(flight.z0,flight.z1,t))
				var capsule := CapsuleShape3D.new()
				capsule.height = 1.5
				capsule.radius = .28
				var q := PhysicsShapeQueryParameters3D.new()
				q.shape = capsule
				q.transform.origin = p+Vector3(0,1.05,0)
				q.collision_mask = 16
				if not room.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty():failures.append(str(p))
				count += 1
	check("Visible mesh headroom throughout both stair widths",failures.is_empty(),{"samples":count,"obstructed":failures})
	audit_visuals.free()
	await settle()

func ordinary_route(mode: String) -> void:
	await walk_to(mode+" climbs entrance",Vector3(0,1.05,8.4))
	await walk_to(mode+" enters ordinary library",Vector3(0,1.086,5.4))
	await walk_to(mode+" traverses ordinary ground aisle",Vector3(0,1.086,-3.4))
	await walk_to(mode+" returns to front cross aisle",Vector3(0,1.086,5.45))
	await walk_to(mode+" reaches cleared east stair approach",Vector3(8.0,1.086,6.1))
	await walk_to(mode+" follows formerly blocked approach",Vector3(7.05,1.086,4.0))
	await walk_to(mode+" aligns on original stair",Vector3(6.3,1.20,4.0))
	await walk_to(mode+" climbs original stair naturally",Vector3(6.3,5.35,-3.9),300)
	await walk_to(mode+" leaves original landing",Vector3(4.0,5.35,-4.6))
	await walk_to(mode+" crosses released ordinary rear reading aisle",Vector3(-6.6,5.35,-4.6))
	await walk_to(mode+" returns across ordinary rear aisle",Vector3(4.0,5.35,-4.6))
	await walk_to(mode+" traverses ordinary east gallery",Vector3(4.0,5.35,5.0))
	await walk_to(mode+" crosses ordinary front gallery",Vector3(-6.6,5.35,5.0))
	await walk_to(mode+" browses unchanged west scripture shelves",Vector3(-6.6,5.35,-4.4))
	await walk_to(mode+" returns along west browsing aisle",Vector3(-6.6,5.35,5.0))
	await walk_to(mode+" approaches archive staircase",Vector3(-4.6,5.35,5.0))
	await walk_to(mode+" enters archive stair",Vector3(-4.6,5.35,4.2))
	await walk_to(mode+" climbs to dedicated archive landing",Vector3(-4.6,9.9,-4.05),320)

func archive_access(mode: String) -> void:
	var gate: Node3D = room.facility.archive_gate
	var original_check: Callable = gate.authorization_check
	gate.authorization_check = Callable()
	var result: Dictionary = room.request_archive_interaction()
	check(mode+" no configured provider denies entry",not result.granted and not gate.is_open and "denied" in result.message)
	gate.authorization_check = original_check
	room.set_inspection_authorized(false)
	result = room.request_archive_interaction()
	check(mode+" unauthorized request denied with feedback",not result.granted and not gate.is_open and "authorization required" in room.access_message)
	room.player.drive = Vector3.FORWARD
	for i in range(70):await physics_frame
	room.player.drive = Vector3.ZERO
	check(mode+" cannot walk through closed secured gate",room.player.position.z> -4.57 and room.player.position.y>9.8,str(room.player.position))
	if room.player.third_person:await gameplay_shot("07-unauthorized-attempt.png")
	room.set_inspection_authorized(true)
	room.request_archive_interaction()
	await settle(40)
	room.set_inspection_authorized(false)
	await settle(4)
	check(mode+" permission boundary handles an already-open gate",gate.is_open and gate.pending_close)
	room.player.drive = Vector3.FORWARD
	for i in range(50):await physics_frame
	room.player.drive = Vector3.ZERO
	check(mode+" revoked authorization cannot follow through open leaves",room.player.position.z> -4.57,str(room.player.position))
	room.set_inspection_authorized(true)
	result = room.request_archive_interaction()
	await settle(40)
	check(mode+" authorized request opens fitted leaves",result.granted and gate.is_open and not gate.busy)
	check(mode+" gate collision stays enabled during opening",gate.left.collision_layer==1 and gate.right.collision_layer==1)
	await walk_to(mode+" enters authorized archive",Vector3(-4.6,9.9,-5.70))
	if room.player.third_person:await gameplay_shot("08-authorized-entry.png")
	await shot("04-new-floor-from-entrance.png",Vector3(3.6,11.55,-5.7),Vector3(0,11.2,1.2),80)
	await walk_to(mode+" traverses archive rear corridor",Vector3(3.5,9.9,-5.7))
	await walk_to(mode+" reaches rare collection cross aisle",Vector3(3.5,9.9,-2.7))
	await walk_to(mode+" enters central archive aisle",Vector3(0,9.9,-2.7))
	await walk_to(mode+" explores dedicated archive interior",Vector3(0,9.9,4.7))
	if room.player.third_person:await gameplay_shot("10-third-person-archive.png")
	await shot("05-archive-interior.png",Vector3(0,11.55,4.7),Vector3(0,11.5,-3.8),84)
	await walk_to(mode+" returns through archive central aisle",Vector3(0,9.9,-2.7))
	await walk_to(mode+" returns around rare shelves",Vector3(3.5,9.9,-2.7))
	await walk_to(mode+" returns to archive rear corridor",Vector3(3.5,9.9,-5.7))
	await walk_to(mode+" returns to secured doorway",Vector3(-4.6,9.9,-5.7))
	var closed: bool = gate.request_close()
	check(mode+" occupied doorway delays safe closing",not closed and gate.pending_close)
	await settle(40)
	room.set_inspection_authorized(false)
	result = room.request_archive_interaction()
	await settle(40)
	check(mode+" egress remains possible after permission revocation",result.granted and gate.is_open)
	await walk_to(mode+" exits archive to controlled landing",Vector3(-4.6,9.9,-4.05))
	room.set_inspection_authorized(false)
	await settle(40)
	await walk_to(mode+" descends archive stair",Vector3(-4.6,5.35,4.6),320)
	await walk_to(mode+" returns to ordinary front gallery",Vector3(4.0,5.35,5.0))
	await walk_to(mode+" returns to east stair landing",Vector3(4.0,5.35,-4.6))
	await walk_to(mode+" aligns for original stair descent",Vector3(6.3,5.35,-3.9))
	room.player.yaw = PI
	await walk_to(mode+" descends original stair",Vector3(6.3,1.086,4.7),320)
	await walk_to(mode+" returns to ground cross aisle",Vector3(0,1.086,5.45))
	await walk_to(mode+" leaves through unchanged entrance",Vector3(0,1.05,8.4))
	await walk_to(mode+" descends entrance steps",Vector3(0,0,14))
	check(mode+" permission sensor restores the original player collision mask",room.player.collision_mask==1,room.player.collision_mask)

func barrier_test() -> void:
	var gate: Node3D = room.facility.archive_gate
	room.set_inspection_authorized(false)
	gate.request_close()
	await settle(40)
	for direction: Vector3 in [Vector3.LEFT,Vector3.RIGHT]:
		await reset(Vector3(-4.6,9.91,-4.1),true)
		room.player.drive = direction
		for i in range(70):await physics_frame
		room.player.drive = Vector3.ZERO
		check("Stairwell wall prevents walking around gate "+str(direction),room.player.position.x> -5.66 and room.player.position.x< -3.54,str(room.player.position))
	await reset(Vector3(-4.6,9.91,-4.05),false)
	await shot("06-secured-entrance.png",Vector3(-4.6,11.3,-2.8),Vector3(-4.6,11.2,-4.85),75)

func run() -> void:
	if "--props-only" in OS.get_cmdline_user_args(): OUT=OUT.replace("pavilion-verification/", "pavilion-props-verification/")
	root.size=Vector2i(1280,720)
	capture = "--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	room = load("res://scenes/review/scripture_walkthrough.tscn").instantiate()
	room.automated = true
	root.add_child(room)
	await settle()
	var s: Dictionary = room.facility.specification
	check("Dedicated third floor above ordinary collection",s.explorable_storeys==3 and s.floor_heights==[1.086,5.35,9.9])
	check("Exactly identified ground stair shelf removed",s.prop_instances.filter(func(p: Dictionary) -> bool:return p.kind=="scripture_shelf" and absf(p.position[0]-8)<.01 and absf(p.position[1]-1.086)<.01 and absf(p.position[2]-5.05)<.01).is_empty())
	check("Preserved metre convention and independent origin",s.metres_per_unit==1 and room.facility.transform.is_equal_approx(Transform3D.IDENTITY))
	check("Runtime default authorization denied",not room.inspection_authorized and not room.facility.archive_gate.is_open)
	var gate_visuals: Array[Node] = room.facility.archive_gate.find_children("*","GeometryInstance3D",true,false)
	check("Moving gate follows the near-model visibility range",not gate_visuals.is_empty() and gate_visuals.all(func(n: Node) -> bool:return n.visibility_range_end==100))
	var remote_request: Dictionary = room.request_archive_interaction()
	check("Gate cannot be opened remotely from another floor",not remote_request.granted and not room.facility.archive_gate.is_open)
	await headroom()
	await shot("01-stair-entrance.png",Vector3(5.5,2.8,6.2),Vector3(6.3,2.7,3.0))
	await shot("02-bottom-looking-up.png",Vector3(6.3,2.8,3.8),Vector3(6.3,5.0,-1.5))
	await shot("03-upper-landing.png",Vector3(6.3,7.0,-4.2),Vector3(6.3,4.3,1.0))
	await shot("09-exterior.png",Vector3(27,22,32),Vector3(0,8.0,0),50)
	for third: bool in [false,true]:
		await reset(Vector3(0,.03,14),third)
		room.set_inspection_authorized(false)
		room.facility.archive_gate.request_close()
		await settle(40)
		var mode := "Third-person" if third else "First-person"
		await ordinary_route(mode)
		await archive_access(mode)
	await barrier_test()
	check("Camera volumes stay outside solids on tested paths",camera_bad.is_empty(),{"sample_count":camera_samples,"failures":camera_bad.slice(0,12)})
	var failures := checks.filter(func(c: Dictionary) -> bool:return not c.pass).size()
	var report := {"project_root":ProjectSettings.globalize_path("res://"),"passed":checks.size()-failures,"failed":failures,"checks":checks,"movement":movement,"captures":captures,"camera_samples":camera_samples,"camera_failures":camera_bad,"limitations":["Programmatically driven unchanged inspection controller; no human-input rehearsal","No production controller, full rank/key/quest system or multiplayer authority","World placement, exported executable and target hardware not tested"]}
	FileAccess.open(OUT+("rendered-results.json" if capture else "headless-results.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("SCRIPTURE FIXES: ",report.passed," PASS / ",failures," FAIL")
	quit(1 if failures else 0)

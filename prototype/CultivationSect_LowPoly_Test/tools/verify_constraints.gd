extends SceneTree
var stage: Node3D
var checks: Array = []
func _initialize() -> void: call_deferred("run")
func check(label: String, ok: bool, detail: Variant = null) -> void:
	checks.append({"check":label,"pass":ok,"detail":detail})
	if not ok: push_warning(label+" "+str(detail))
func settle(n:=8) -> void:
	for i in range(n): await physics_frame
func run() -> void:
	stage = Node3D.new()
	stage.set_script(load("res://scripts/hall_experiment.gd"))
	stage.automated = true
	root.add_child(stage)
	await settle()
	var p: CharacterBody3D = stage.player
	var before: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://baseline/hall/main_sect_hall.json"))
	var after: Dictionary = stage.hall.specification
	for key in ["solid_shapes","door","room_doors","floor_y","terrace_y","foundation_m","main_wall_shell_m","stairs","lights","plaque"]:
		check("Preserved gameplay contract: "+key,before[key]==after[key])
	for door in stage.hall.doors: door.set_open_immediate(true)
	p.camera.make_current()
	p.third_person = true
	p.position = Vector3(0,1.56,4.8)
	await settle()
	var free_distance: float = p.camera_distance
	check("Follow camera normal range",free_distance>4.0,free_distance)
	# Turn toward the open aisle while standing in front of the rear screen.
	# The camera wants to go behind the screen, so sphere casting must retract it.
	p.position = Vector3(2.4,2.16,-6.7)
	p.yaw = PI
	p.pitch = 0
	await settle()
	check("Follow camera retracts before rear screen",p.camera_distance<free_distance-.5,{"free":free_distance,"near_screen":p.camera_distance})
	var sphere := SphereShape3D.new()
	sphere.radius = .18
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform.origin = p.camera.global_position
	query.collision_mask = 1
	query.exclude = [p.get_rid()]
	var overlaps := p.get_world_3d().direct_space_state.intersect_shape(query,3)
	var details: Array = []
	for hit in overlaps:
		details.append({"collider":str(hit.collider.get_path()),"shape":hit.shape,"camera":str(p.camera.global_position)})
	check("Retracted camera clears solid geometry",overlaps.is_empty(),details)
	# Continuous motion into a side partition must be blocked by the real body.
	p.position = Vector3(9.7,1.56,3)
	p.drive = Vector3.RIGHT
	await settle(80)
	p.drive = Vector3.ZERO
	check("Wall blocks actual controller",p.position.x<10.8,p.position.x)
	check("No fall during wall contact",p.is_on_floor() and p.position.y>1.4,p.position.y)
	# Sample the LOD handover with actual rendered frames in a separate run.
	stage.view_camera.make_current()
	for distance in [94.0,96.0,140.0]:
		stage.view_camera.position = Vector3(0,18,distance)
		stage.view_camera.look_at(Vector3(0,8,0))
		await process_frame
		await process_frame
		check("Distance resource loads at "+str(distance),is_instance_valid(stage.hall.static_model) and is_instance_valid(stage.hall.distant_model))
	var failed := checks.filter(func(c):return not c.pass).size()
	var f := FileAccess.open("res://reports/constraints-results.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"limits":"Distance checks confirm loaded resources only; no exhaustive camera orientation or LOD pixel analysis."},"\t"))
	f.close()
	print("Supplemental constraints: "+str(checks.size()-failed)+" PASS / "+str(failed)+" FAIL")
	quit(1 if failed else 0)

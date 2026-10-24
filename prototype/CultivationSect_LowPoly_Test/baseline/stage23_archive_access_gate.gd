extends Node3D
## Local configurable permission boundary. A future game supplies a Callable
## taking (actor, permission_id). Missing provider = denied entry by default.
signal access_feedback(message: String,granted: bool)
@export var permission_id := "restricted_archive"
@export var interaction_distance := 2.7
@export var actor_collision_layers := 2
@export var admission_collision_layer := 4
var authorization_check: Callable
var is_open := false
var busy := false
var last_feedback := "Archive locked — authorization required."
var left: AnimatableBody3D
var right: AnimatableBody3D
var pending_close := false
var admission_boundary: StaticBody3D
var admission_sensor: Area3D
var tracked: Dictionary = {}
const ROOT := "res://baseline/stage23_pavilion/"

func _ready() -> void:
	left = make_leaf("left",Vector3(-1.1,0,0),.55)
	right = make_leaf("right",Vector3(1.1,0,0),-.55)
	# The admission boundary enforces each actor's permission even if the
	# wooden leaves are still open. It uses a separate collision layer so the
	# existing camera boom can pass through an authorized open doorway.
	admission_boundary = StaticBody3D.new()
	admission_boundary.name = "ArchivePermissionBoundary"
	admission_boundary.collision_layer = admission_collision_layer
	admission_boundary.collision_mask = actor_collision_layers
	add_child(admission_boundary)
	var plane := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2,2.56,.08)
	plane.shape = box
	plane.position.y = 1.28
	admission_boundary.add_child(plane)
	admission_sensor = Area3D.new()
	admission_sensor.name = "ArchiveActorPermissionSensor"
	admission_sensor.collision_layer = 0
	admission_sensor.collision_mask = actor_collision_layers
	add_child(admission_sensor)
	var sensor_shape := CollisionShape3D.new()
	var sensor_box := BoxShape3D.new()
	sensor_box.size = Vector3(3.2,4.0,6.0)
	sensor_shape.shape = sensor_box
	sensor_shape.position.y = 1.2
	admission_sensor.add_child(sensor_shape)
	admission_sensor.body_entered.connect(track_actor)
	admission_sensor.body_exited.connect(untrack_actor)

func make_leaf(side: String,hinge: Vector3,center_x: float) -> AnimatableBody3D:
	var body := AnimatableBody3D.new()
	body.name = side.capitalize()+"SecureLeaf"
	body.position = hinge
	body.sync_to_physics = false
	body.collision_layer = 1
	body.collision_mask = 2
	add_child(body)
	var model: Node3D = load(ROOT+"archive_gate_"+side+".glb").instantiate()
	body.add_child(model)
	for mesh: GeometryInstance3D in model.find_children("*","GeometryInstance3D",true,false):
		mesh.visibility_range_end = 100
		mesh.lod_bias = 128.0
	var shape := CollisionShape3D.new()
	shape.name = "SolidWoodenLeaf"
	var box := BoxShape3D.new()
	box.size = Vector3(1.1,2.56,.12)
	shape.shape = box
	shape.position = Vector3(center_x,1.28,0)
	body.add_child(shape)
	return body

func permitted(actor: Node) -> bool:
	return authorization_check.is_valid() and bool(authorization_check.call(actor,permission_id))

func feedback(message: String,granted: bool) -> Dictionary:
	last_feedback = message
	access_feedback.emit(message,granted)
	return {"granted":granted,"message":message,"open":is_open}

func request_open(actor: Node3D) -> Dictionary:
	if not is_instance_valid(actor) or not actor.is_inside_tree():return feedback("No actor at archive entrance.",false)
	var at := to_local(actor.global_position)
	if at.length()>interaction_distance or absf(at.y)>1.0:return feedback("Move closer to the archive gate.",false)
	# Egress is always possible so revoking entry permission cannot trap a
	# visitor inside. This grants exit only from the secured side of the gate.
	var exiting := at.z < -.35
	if not exiting and not permitted(actor):
		if is_open: request_close()
		return feedback("Access denied — Restricted Archive authorization required.",false)
	if busy:return feedback("Gate is moving; wait a moment.",true)
	pending_close = false
	if not is_open: animate_gate(true)
	return feedback("Archive exit released." if exiting else "Access granted — Restricted Archive unlocked.",true)

func portal_occupied() -> bool:
	var box := BoxShape3D.new()
	box.size = Vector3(2.65,2.8,1.30)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = box
	query.transform = global_transform*Transform3D(Basis.IDENTITY,Vector3(0,1.40,0))
	query.collision_mask = actor_collision_layers
	return not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func request_close() -> bool:
	if not is_open or busy:return false
	if portal_occupied():
		pending_close = true
		feedback("Step clear of the gate to close it safely.",false)
		return false
	pending_close = false
	animate_gate(false)
	return true

func _physics_process(_delta: float) -> void:
	for id: int in tracked.keys():
		var record: Dictionary = tracked[id]
		var actor: PhysicsBody3D = record.reference.get_ref()
		if not is_instance_valid(actor):
			tracked.erase(id)
			continue
		var at := to_local(actor.global_position)
		if at.z < -.05:record.egress = true
		if at.z > .75:record.egress = false
		var allowed: bool = permitted(actor) or record.egress
		if allowed != record.allowed:
			if allowed:admission_boundary.add_collision_exception_with(actor)
			else:admission_boundary.remove_collision_exception_with(actor)
		if not allowed and is_open:
			pending_close = true
			if at.z>0 and at.z<1.1 and record.allowed:feedback("Access denied — authorization revoked; archive entry remains blocked.",false)
		record.allowed = allowed
	if pending_close and not busy and not portal_occupied():request_close()

func track_actor(actor: Node3D) -> void:
	if not actor is PhysicsBody3D:return
	var body := actor as PhysicsBody3D
	var id := body.get_instance_id()
	if tracked.has(id):return
	tracked[id] = {"reference":weakref(body),"original_mask":body.collision_mask,"egress":false,"allowed":false}
	body.collision_mask |= admission_collision_layer

func untrack_actor(actor: Node3D) -> void:
	var id := actor.get_instance_id()
	if not tracked.has(id):return
	if actor is PhysicsBody3D:
		actor.collision_mask = tracked[id].original_mask
		admission_boundary.remove_collision_exception_with(actor)
	tracked.erase(id)

func _exit_tree() -> void:
	for record: Dictionary in tracked.values():
		var actor: PhysicsBody3D = record.reference.get_ref()
		if is_instance_valid(actor):actor.collision_mask = record.original_mask

func animate_gate(opening: bool) -> void:
	busy = true
	var tween := create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_parallel(true)
	tween.tween_property(left,"rotation:y",-PI/2 if opening else 0.0,.45)
	tween.tween_property(right,"rotation:y",PI/2 if opening else 0.0,.45)
	tween.chain().tween_callback(func():
		is_open = opening
		busy = false
	)

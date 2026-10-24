extends CharacterBody3D
## New inspection fixture, NOT the production game's player/controller.
## Test and manual modes share the same move_and_slide and camera code.
var automated := false
var drive := Vector3.ZERO
var third_person := false
var yaw := 0.0
var pitch := 0.0
var camera: Camera3D
var avatar: Node3D
var camera_distance := 0.0
var speed := 4.0

@export_group("Inspection third-person camera")
# Disable this one option to restore the original fixed-boom camera exactly.
@export var indoor_camera_enabled := true
@export_range(.8,4.3,.05) var indoor_camera_distance := 2.2
@export_range(0,.72,.01) var indoor_camera_rise := .12
@export_range(0,1.5,.05) var indoor_camera_look_down := .65
@export_range(1,20,.5) var indoor_camera_transition_speed := 8.0
@export_range(1,20,.5) var camera_recovery_speed := 5.0
var camera_indoor_weight := 0.0
var _camera_cover_hold := 0.0
var _camera_was_third := false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = .32
	floor_max_angle = deg_to_rad(50)
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.8
	capsule.radius = .28
	var shape := CollisionShape3D.new()
	shape.name = "InspectionCapsule_1_8m"
	shape.shape = capsule
	shape.position.y = .90
	add_child(shape)
	avatar = Node3D.new()
	avatar.name = "InspectionFigure"
	add_child(avatar)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("b39764")
	var body := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.height = 1.4
	mesh.radius = .20
	body.mesh = mesh
	body.position.y = .70
	body.material_override = material
	avatar.add_child(body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = .18
	sphere.height = .36
	head.mesh = sphere
	head.position.y = 1.62
	head.material_override = material
	avatar.add_child(head)
	camera = Camera3D.new()
	camera.name = "InspectionCamera"
	camera.fov = 75
	camera.near = .05
	camera.far = 600
	add_child(camera)
	camera.make_current()
	if not automated: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	update_camera()

func _unhandled_input(event: InputEvent) -> void:
	if automated: return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x*.003
		pitch = clampf(pitch-event.relative.y*.003,-1.1,1.1)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_TAB: third_person = not third_person
		if event.physical_keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().change_scene_to_file("res://scenes/asset_gallery.tscn")

func _physics_process(delta: float) -> void:
	var direction := drive
	if not automated:
		var keyboard := Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
		direction = Basis(Vector3.UP,yaw)*keyboard.normalized()
	velocity.x = direction.x*speed
	velocity.z = direction.z*speed
	if is_on_floor(): velocity.y = -.4
	else: velocity.y -= 20.0*delta
	move_and_slide()
	update_camera(delta)

func _has_camera_cover(eye: Vector3) -> bool:
	# Existing roof/ceiling collision is enough for the standalone walkthroughs;
	# no building volumes or architectural edits are needed. Look slightly ahead
	# while walking so a porch starts lowering the boom before its lintel.
	var ahead := Vector3(velocity.x,0,velocity.z).normalized()*.65
	for at: Vector3 in [eye,eye+ahead]:
		var ray := PhysicsRayQueryParameters3D.create(at,at+Vector3.UP*16.0,1,[get_rid()])
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
			return true
	return false

func update_camera(delta: float = 0.0) -> void:
	if not camera: return
	avatar.visible = third_person
	var eye := global_position+Vector3(0,1.65,0)
	var basis := Basis(Vector3.UP,yaw)*Basis(Vector3.RIGHT,pitch)
	var offset := basis*Vector3(0,.72,4.3) if third_person else Vector3.ZERO
	if third_person and is_inside_tree():
		if indoor_camera_enabled:
			var covered := _has_camera_cover(eye)
			_camera_cover_hold = .25 if covered else (maxf(0.0,_camera_cover_hold-delta) if delta>0 else 0.0)
			var target := 1.0 if covered or (delta>0 and _camera_cover_hold>0) else 0.0
			if delta<=0 or not _camera_was_third:
				camera_indoor_weight = target
			else:
				camera_indoor_weight = lerpf(camera_indoor_weight,target,1.0-exp(-indoor_camera_transition_speed*delta))
			var indoor := Vector3(0,indoor_camera_rise,indoor_camera_distance)
			offset = basis*Vector3(0,.72,4.3).lerp(indoor,camera_indoor_weight)
		var sphere := SphereShape3D.new()
		sphere.radius = .20
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = sphere
		query.transform.origin = eye
		query.motion = offset
		query.collision_mask = 1
		query.exclude = [get_rid()]
		var travel := get_world_3d().direct_space_state.cast_motion(query)
		if indoor_camera_enabled:
			# Keep the original outdoor safety margin in metres. Subtracting a
			# fraction of the shortened boom would halve the margin indoors.
			var margin := Vector3(0,.72,4.3).length()*.025
			offset = offset.normalized()*maxf(0.0,offset.length()*travel[0]-margin)
		else:
			offset *= maxf(0.0,travel[0]-.025)
		if indoor_camera_enabled and delta>0 and _camera_was_third and offset.length()>camera_distance:
			# Only outward recovery is delayed. Smoothing an inward collision clamp
			# would leave the camera inside a wall or ceiling for several frames.
			var distance := lerpf(camera_distance,offset.length(),1.0-exp(-camera_recovery_speed*delta))
			offset = offset.normalized()*distance
	else:
		camera_indoor_weight = 0.0
		_camera_cover_hold = 0.0
	_camera_was_third = third_person
	camera_distance = offset.length()
	camera.global_position = eye+offset
	camera.global_basis = basis
	if third_person:
		# The shorter boom needs a slightly lower aim point to keep the feet in
		# view. At zero indoor weight the original outdoor framing is exact.
		var look_down := indoor_camera_look_down*camera_indoor_weight if indoor_camera_enabled else 0.0
		camera.look_at(eye-basis.z*4.0-Vector3.UP*look_down,Vector3.UP)

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
	update_camera()

func update_camera() -> void:
	if not camera: return
	avatar.visible = third_person
	var eye := global_position+Vector3(0,1.65,0)
	var basis := Basis(Vector3.UP,yaw)*Basis(Vector3.RIGHT,pitch)
	var offset := basis*Vector3(0,.72,4.3) if third_person else Vector3.ZERO
	if third_person and is_inside_tree():
		var sphere := SphereShape3D.new()
		sphere.radius = .20
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = sphere
		query.transform.origin = eye
		query.motion = offset
		query.collision_mask = 1
		query.exclude = [get_rid()]
		var travel := get_world_3d().direct_space_state.cast_motion(query)
		offset *= maxf(0.0,travel[0]-.025)
	camera_distance = offset.length()
	camera.global_position = eye+offset
	camera.global_basis = basis
	if third_person: camera.look_at(eye-basis.z*4.0,Vector3.UP)

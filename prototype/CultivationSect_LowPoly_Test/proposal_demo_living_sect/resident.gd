extends CharacterBody3D
## Short authored routes use physical movement, gravity and player yielding.
var display_name := "Resident"
var role := "apprentice"
var duty := "idle"
var coat := Color("687c75")
var variant := 0
var route: Array[Vector3] = []
var home := Vector3.ZERO
var home_yaw := 0.0
var watch: Node3D
var figure: Node3D
var destination := 1
var waiting := 4.0
var speed := 1.05
var talking := 0.0
var total_distance := 0.0
var reached := 0
var yield_count := 0
var restoring := false
var default_route: Array[Vector3] = []
var default_duty := "idle"
var stuck_time := 0.0
func _ready() -> void:
	collision_layer = 4
	collision_mask = 7
	floor_snap_length = .3
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = .25
	capsule.height = 1.75
	shape.shape = capsule
	shape.position.y = .875
	add_child(shape)
	figure = Node3D.new()
	figure.name = "Figure"
	figure.set_script(preload("res://proposal_demo_living_sect/character.gd"))
	figure.role = role
	figure.coat = coat
	figure.cloth = Color("bfbca4") if role != "guard" else Color("777d79")
	figure.skin = [Color("cfaa87"),Color("ad805e"),Color("d7b996"),Color("bb9170")][variant%4]
	figure.hairstyle = variant%2
	figure.elder = role == "teacher"
	figure.hair_color = Color("777e79") if role == "teacher" else Color("252c2b")
	figure.activity = duty
	add_child(figure)
	if duty == "sit": figure.position.y = -.37
	home = position
	home_yaw = rotation.y
	default_route = route.duplicate()
	default_duty = duty
	waiting = 3.0+variant*.75
	figure.time = variant*1.71
func _physics_process(delta: float) -> void:
	talking = maxf(0,talking-delta)
	figure.speaking = talking if duty != "converse" else .8
	if duty == "sit": return
	var direction := Vector3.ZERO
	var near_player := watch and global_position.distance_to(watch.global_position) < 1.35
	if talking > 0 and watch:
		var d := watch.global_position-global_position
		rotation.y = lerp_angle(rotation.y,atan2(-d.x,-d.z),1-exp(-4*delta))
	elif route.size() > 1:
		if waiting > 0:
			waiting -= delta
			figure.activity = duty
		else:
			var d := route[destination]-position
			d.y = 0
			if d.length() < .22:
				destination = (destination+1)%route.size()
				waiting = 4.0+variant*.27
				reached += 1
			elif not near_player:
				direction = d.normalized()
				rotation.y = lerp_angle(rotation.y,atan2(-d.x,-d.z),1-exp(-4*delta))
				figure.activity = "idle"
			else: yield_count += 1
	else:
		figure.activity = duty
	velocity.x = direction.x*speed
	velocity.z = direction.z*speed
	velocity.y = -.4 if is_on_floor() else velocity.y-18*delta
	var before := position
	move_and_slide()
	var distance := Vector2(position.x-before.x,position.z-before.z).length()
	total_distance += distance
	if direction.length() > .1 and distance < .002:
		stuck_time += delta
		if stuck_time > 2:
			destination = (destination+1)%route.size()
			waiting = 1
			stuck_time = 0
	else: stuck_time = 0
func reset() -> void:
	position = home
	rotation.y = home_yaw
	velocity = Vector3.ZERO
	route = default_route.duplicate()
	duty = default_duty
	destination = 1
	waiting = 3.0+variant*.75
	talking = 0
	restoring = false
	total_distance = 0
	reached = 0
	yield_count = 0
	figure.activity = duty
	figure.time = variant*1.71
	figure.phase = 0
	figure.moving_speed = 0
	figure.stride_span = .33
	figure.speaking = 0
	figure.last_position = global_position

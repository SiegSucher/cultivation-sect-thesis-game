extends Node3D
## Independent inspection hinges for the NEW hall. This is a door animation
## preview, not an imported gameplay component or a traversal certification.
@export var opening_width := 4.8
@export var height := 4.5
var leaves: Array[AnimatableBody3D] = []
var hinges: Array[Node3D] = []
var target_open := false
var angle := 0.0

func _ready() -> void:
	for side: float in [-1,1]:
		var hinge := Node3D.new()
		hinge.position.x = side*opening_width*.5
		add_child(hinge)
		hinges.append(hinge)
		var leaf := AnimatableBody3D.new()
		leaf.sync_to_physics = false
		leaf.collision_layer = 1
		leaf.collision_mask = 2
		# New leaves are hinge-local. Positive local depth is intentional: the
		# thick timber and ring pulls swing inside the jamb instead of through it.
		hinge.add_child(leaf)
		leaves.append(leaf)
		var box := BoxShape3D.new()
		box.size = Vector3(opening_width*.5-.04,height-.06,.22)
		var shape := CollisionShape3D.new()
		shape.shape = box
		shape.name = "LeafCollision"
		shape.position = Vector3(-side*opening_width*.25,0,.21)
		leaf.add_child(shape)

func request_toggle() -> void:
	target_open = not target_open

func set_open_immediate(value: bool) -> void:
	target_open = value
	angle = 90.0 if value else 0.0
	update_hinges()

func update_hinges() -> void:
	for i in range(hinges.size()):
		hinges[i].rotation.y = deg_to_rad(angle)*(1 if i == 0 else -1)

func _physics_process(delta: float) -> void:
	angle = move_toward(angle,90.0 if target_open else 0.0,100.0*delta)
	update_hinges()

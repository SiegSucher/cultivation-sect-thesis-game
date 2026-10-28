extends Node3D
## Quest-compatible wrapper around the articulated figure.
var title := "Mentor"
var robe := Color("ece4cf")
var over := Color("2f6b5f")
var sash := Color("cda668")
var prop := "staff"
var beard := true
var hat := "crown"
var watch: Node3D
var bow := 0.0
var talk := 0.0
var yaw_target := 0.0
var figure: Node3D
func _ready() -> void:
	figure = Node3D.new()
	figure.set_script(preload("res://proposal_demo_living_sect/character.gd"))
	figure.coat = over
	figure.cloth = robe
	figure.trim = sash
	figure.role = "teacher" if beard else "apprentice"
	figure.elder = beard
	if beard: figure.hair_color = Color("8c938a")
	figure.straw = title == "Guide"
	if title.begins_with("Mei"):
		figure.role = "worker"
		figure.hairstyle = 1
		figure.skin = Color("b98d6c")
	if title.begins_with("Lin"):
		figure.hairstyle = 1
		figure.skin = Color("d3b18c")
	figure.look_target = watch
	figure.name = "ArticulatedFigure"
	add_child(figure)
	var label := Label3D.new()
	label.text = title
	label.position.y = 2.18
	label.font_size = 34
	label.pixel_size = .005
	label.outline_size = 5
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("e6d9b8")
	add_child(label)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.75
	capsule.radius = .28
	shape.shape = capsule
	shape.position.y = .875
	body.add_child(shape)
	add_child(body)
	yaw_target = rotation.y
func face(point: Vector3, snap := false) -> void:
	var d := point-global_position if is_inside_tree() else point-position
	if Vector2(d.x,d.z).length() < .01: return
	yaw_target = atan2(-d.x,-d.z)
	if snap: rotation.y = yaw_target
func speak(seconds: float) -> void: talk = maxf(talk,seconds)
func greet() -> void:
	var tw := create_tween()
	tw.tween_property(self,"bow",.28,.35)
	tw.tween_interval(.12)
	tw.tween_property(self,"bow",0.0,.45)
func _process(delta: float) -> void:
	rotation.y = lerp_angle(rotation.y,yaw_target,1.0-exp(-5*delta))
	talk = maxf(0,talk-delta)
	figure.speaking = talk
	figure.bow = bow

extends Node3D
## Additive local review area. All building and environment instances are in the
## .tscn so their placements can be inspected without running this script.
var player: CharacterBody3D
var review_camera: Camera3D
var walking := true
@onready var hall: Node3D = $MainSectHall
const VIEWS := [
	[Vector3(0, 8, 66), Vector3(0, 7, 8), 57.0],
	[Vector3(35, 23, 51), Vector3(0, 4.5, 15), 58.0],
	[Vector3(-17, 3.8, 38), Vector3(1, 3.0, 20), 66.0],
]

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var atmosphere := ProceduralSkyMaterial.new()
	atmosphere.sky_top_color = Color("6b919f")
	atmosphere.sky_horizon_color = Color("c3d1ca")
	atmosphere.ground_horizon_color = Color("c3d1ca")
	atmosphere.ground_bottom_color = Color("697b63")
	sky.sky_material = atmosphere
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d7e2de")
	env.ambient_light_energy = .57
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42,-32,0)
	sun.light_color = Color("ffe8c8")
	sun.light_energy = .9
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 130
	add_child(sun)
	build_ground()
	player = CharacterBody3D.new()
	player.name = "InspectionPlayer"
	player.set_script(load("res://scripts/training_inspection_player.gd"))
	player.position = Vector3(0,.05,49)
	player.third_person = true
	player.pitch = -.12
	add_child(player)
	review_camera = Camera3D.new()
	review_camera.name = "ReviewCamera"
	add_child(review_camera)
	player.camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Open only this scene's entrance for the proposal walkthrough.
	hall.main_door.set_open_immediate(true)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(18,18)
	canvas.add_child(panel)
	var label := Label.new()
	label.add_theme_font_size_override("font_size",16)
	label.text = "PHASE 4A  /  MAIN SECT HALL\nWASD move  ·  Mouse look  ·  Tab first / third person  ·  E doors\n1 walk / review  ·  2 approach  ·  3 courtyard  ·  4 garden  ·  R return  ·  Esc gallery"
	panel.add_child(label)

func material(hex: String) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(hex)
	mat.roughness = 1.0
	return mat

func surface(label: String, points: PackedVector2Array, height: float, mat: Material) -> void:
	# Ground dressing only: these thin surfaces share the original flat floor's
	# collision, avoiding extra steps or a second collision system.
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var triangles := Geometry2D.triangulate_polygon(points)
	for i in range(0,triangles.size(),3):
		# Godot renders clockwise faces; triangulate_polygon's order is already
		# correct when its 2D Y coordinate becomes our ground's Z coordinate.
		for j in 3:
			var p := points[triangles[i+j]]
			vertices.append(Vector3(p.x,height,p.y))
			normals.append(Vector3.UP)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.material_override = mat
	add_child(node)

func rect(label: String, x: float, z: float, w: float, d: float, y: float, mat: Material) -> void:
	surface(label,PackedVector2Array([Vector2(x-w/2,z-d/2),Vector2(x+w/2,z-d/2),Vector2(x+w/2,z+d/2),Vector2(x-w/2,z+d/2)]),y,mat)

func build_ground() -> void:
	var green := material("56644b")
	var stone := material("858a80")
	var coping := material("a0a396")
	var soil := material("77715b")
	var seams := material("6e756d")
	rect("Meadow",0,5,2000,2000,-.025,green)
	rect("CourtyardBorder",0,28.5,42,21,.002,coping)
	rect("CourtyardStone",0,28.5,40.8,19.8,.006,stone)
	rect("ApproachBorder",0,53,8.6,29,.002,coping)
	rect("SouthApproach",0,53,7.6,29,.006,stone)
	# Sparse scored joints give the broad stone court human scale without
	# hundreds of raised blocks or trip edges.
	for z in range(20,39,3): rect("CourtJoint",0,z,40.8,.035,.009,seams)
	for x in range(-18,20,3): rect("CourtJoint",x,28.5,.035,19.8,.009,seams)
	for z in range(40,68,3): rect("ApproachJoint",0,z,7.6,.035,.009,seams)
	# Softer irregular ground under the two garden pockets.
	surface("WestGarden",PackedVector2Array([Vector2(-32,17),Vector2(-21,18),Vector2(-21,39),Vector2(-14,45),Vector2(-17,51),Vector2(-29,44),Vector2(-34,29)]),-.008,soil)
	surface("EastGarden",PackedVector2Array([Vector2(21,18),Vector2(29,15),Vector2(34,28),Vector2(28,44),Vector2(17,50),Vector2(12,46),Vector2(22,39)]),-.008,soil)
	var body := StaticBody3D.new()
	body.name = "FlatReviewGround"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(240,.1,240)
	shape.shape = box
	shape.position = Vector3(0,-.075,5)
	body.add_child(shape)
	add_child(body)

func set_walking(value: bool) -> void:
	walking = value
	player.set_physics_process(value)
	player.set_process_unhandled_input(value)
	if value:
		player.camera.make_current()
	else:
		review_camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if value else Input.MOUSE_MODE_VISIBLE

func use_view(index: int) -> void:
	var v: Array = VIEWS[index]
	review_camera.position = v[0]
	review_camera.look_at(v[1])
	review_camera.fov = v[2]
	set_walking(false)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo): return
	match event.physical_keycode:
		KEY_1:
			if walking: use_view(1)
			else: set_walking(true)
		KEY_2: use_view(0)
		KEY_3: use_view(1)
		KEY_4: use_view(2)
		KEY_E:
			for door in hall.doors: door.request_toggle()
		KEY_R:
			player.position = Vector3(0,.05,49)
			player.velocity = Vector3.ZERO
			player.yaw = 0
			player.pitch = -.12
			player.update_camera()
			set_walking(true)

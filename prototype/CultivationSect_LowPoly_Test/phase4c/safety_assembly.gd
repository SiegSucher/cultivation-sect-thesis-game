extends RefCounted
## Only staged retaining/guardrail modules, at unit scale and yaw rotations.
const KIT := "res://phase4c/resources/kit/"
var root: Node3D
var counts := {}
var guard_runs: Array = []
var stair_records: Array = []
var sampler: RefCounted
func kit(id: String,at: Vector3,yaw: float = 0) -> void:
	var node: Node3D = load(KIT+id+".tscn").instantiate()
	assert(node.has_node("Model") and node.has_node("Collision"),"Incomplete kit import: "+id)
	counts[id] = counts.get(id,0)+1
	node.name = id.get_file()+"_%03d"%counts[id]
	node.position = at
	node.rotation.y = yaw
	root.add_child(node)
func material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("667e88")
	m.roughness = .9
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m
func strip(a: Vector3,b: Vector3,width: float) -> void:
	var direction := Vector3(b.x-a.x,0,b.z-a.z).normalized()
	var side := Vector3(-direction.z,0,direction.x)*width*.5
	var p := PackedVector3Array([a-side,a+side,b+side,b-side,a-side-Vector3.UP*.55,a+side-Vector3.UP*.55,b+side-Vector3.UP*.55,b-side-Vector3.UP*.55])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f: Array in [[0,1,2],[0,2,3],[4,6,5],[4,7,6],[0,4,5],[0,5,1],[1,5,6],[1,6,2],[2,6,7],[2,7,3],[3,7,4],[3,4,0]]:
		for i: int in f: st.add_vertex(p[i])
	st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name = "SupportedStoneStrip_%03d"%root.get_child_count()
	mesh.mesh = st.commit()
	mesh.material_override = material()
	root.add_child(mesh)
	var body := StaticBody3D.new()
	body.name = "StoneStripCollision_%03d"%root.get_child_count()
	var shape := CollisionShape3D.new()
	var convex := ConvexPolygonShape3D.new()
	convex.points = p
	shape.shape = convex
	body.add_child(shape)
	root.add_child(body)
func flat_guard(a: Vector3,b: Vector3,close_end: bool = true) -> void:
	var d := (b-a).normalized()
	var yaw := atan2(-d.z,d.x)
	var length := a.distance_to(b)
	assert(absf(length-roundf(length))<.001)
	var x := 0.0
	while x<length-.01:
		var n := 2 if length-x>1.5 else 1
		kit("railings/rail_section_%dm"%n,a+d*x,yaw)
		x += n
	if close_end: kit("railings/rail_post",b)
	guard_runs.append({"type":"flat","a":[a.x,a.y,a.z],"b":[b.x,b.y,b.z]})
func retaining(a: Vector3,b: Vector3,height: int,rail: bool = true,cap_start: bool = true,cap_end: bool = true) -> void:
	var d := (b-a).normalized()
	var yaw := atan2(-d.z,d.x)
	var length := a.distance_to(b)
	assert(is_equal_approx(fmod(length,4),0))
	for i in int(length/4): kit("retaining/retaining_wall_4x%d"%height,a+d*i*4,yaw)
	if cap_start: kit("retaining/retaining_end_%d"%height,a,yaw)
	if cap_end: kit("retaining/retaining_end_%d"%height,b,yaw)
	if rail:
		var inward := Basis(Vector3.UP,yaw)*Vector3(0,0,-.18)
		flat_guard(a+inward+Vector3.UP*(height+.04),b+inward+Vector3.UP*(height+.04))
func stair_module(route: String,nominal: int,span: int) -> String:
	if route=="entry_stairs": return "railings/rail_stair_4in11_%dm"%span
	return "railings/rail_stair_%ddeg_%dm"%[nominal,span]
func stairs(layout: Dictionary) -> void:
	for path: Dictionary in layout.paths:
		if path.id not in ["entry_stairs","middle_stairs","cloud","grand"]: continue
		for i in range(path.points.size()-1):
			var a := Vector3(path.points[i][0],path.points[i][1],path.points[i][2])
			var b := Vector3(path.points[i+1][0],path.points[i+1][1],path.points[i+1][2])
			if absf(a.y-b.y)<.1: continue
			var d := Vector3(b.x-a.x,0,b.z-a.z).normalized()
			var side := Vector3(-d.z,0,d.x)
			var run := Vector2(b.x-a.x,b.z-a.z).length()
			var grade := (b.y-a.y)/run
			var nominal := 24 if path.id=="grand" else 22
			var exact_arrival: bool = path.id=="entry_stairs"
			for sign_value in [-1.0,1.0]:
				var shift: Vector3 = side*(path.width*.5+.35)*sign_value
				strip(a+shift+Vector3.UP*.04,b+shift+Vector3.UP*.04,.8)
				var at := 0.0
				while at<run-.01:
					var n := 2 if run-at>1.5 else 1
					# Every post is re-anchored to the measured pitch, so nominal
					# module tolerance never accumulates along the full flight.
					var p := a+d*at+Vector3.UP*(grade*at+.06)+shift
					kit(stair_module(path.id,nominal,n),p,atan2(-d.z,d.x))
					at += n
				var top: Vector3 = b+shift+Vector3.UP*.06
				if path.id=="cloud": kit("railings/rail_post",top)
				else:
					strip(b+shift+Vector3.UP*.04,b+d*2+shift+Vector3.UP*.04,.8)
					flat_guard(top,top+d*2)
				guard_runs.append({"type":"stair","route":path.id,"a":[(a+shift).x,a.y,(a+shift).z],"b":[(b+shift).x,b.y,(b+shift).z]})
			stair_records.append({"route":path.id,"degrees":rad_to_deg(atan(grade)),"nominal":null if exact_arrival else nominal,"module_pitch":"4/11" if exact_arrival else str(nominal)+"deg","max_2m_joint_difference_mm":0.0 if exact_arrival else absf(tan(deg_to_rad(nominal))-grade)*2000,"accumulated_error":false})
func build(world: Node3D,layout: Dictionary,terrain_sampler: RefCounted) -> Node3D:
	sampler = terrain_sampler
	root = Node3D.new()
	root.name = "SelectiveTerrainSupports"
	stairs(layout)
	for row: Array in [[-20,-4,-44,20],[28,44,-44,20],[-40,-24,64,6],[24,40,68,6]]:
		retaining(Vector3(row[0],row[3],row[2]),Vector3(row[1],row[3],row[2]),4)
	# Two exposed overlook edges only; leave its approach and west side open.
	retaining(Vector3(149,8,-40),Vector3(149,8,-52),2,false,true,false)
	retaining(Vector3(149,8,-52),Vector3(137,8,-52),2,false,false,true)
	kit("retaining/retaining_corner_2",Vector3(149,8,-52),PI/2)
	flat_guard(Vector3(148.82,10.04,-39.82),Vector3(148.82,10.04,-51.82),false)
	flat_guard(Vector3(148.82,10.04,-51.82),Vector3(136.82,10.04,-51.82))
	world.add_child(root)
	return root

extends SceneTree
## Compare isolated old/new roof physics; no persistent resource mutation.
const OUT := "res://reports/training-ground-fix/"
var stage: Node3D
var checks: Array = []
var points: Array[Vector3] = []
func _initialize() -> void:call_deferred("run")
func check(label: String, ok: bool, detail: Variant = null) -> void:
	checks.append({"check":label,"pass":ok,"detail":detail})
	if not ok:print("FAIL ",label," ",detail)
func make_roof(data: Array, layer: int) -> ConcavePolygonShape3D:
	var body:=StaticBody3D.new();body.collision_layer=layer;body.collision_mask=0
	var shape:=ConcavePolygonShape3D.new();shape.backface_collision=true
	var faces:=PackedVector3Array()
	for p: Array in data:faces.append(Vector3(p[0],p[1],p[2]))
	shape.set_faces(faces)
	var node:=CollisionShape3D.new();node.shape=shape;body.add_child(node);stage.add_child(body)
	return shape
func ray(p: Vector3, layer: int, upward := false) -> Dictionary:
	var a:=Vector3(p.x,-1 if upward else 20,p.z)
	var b:=Vector3(p.x,20 if upward else -1,p.z)
	return stage.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a,b,layer))
func zero_count(shape: ConcavePolygonShape3D) -> int:
	var f:=shape.get_faces();var count:=0
	for i in range(0,f.size(),3):
		if (f[i+1]-f[i]).cross(f[i+2]-f[i]).length_squared()==0:count+=1
	return count
func run() -> void:
	stage=Node3D.new();root.add_child(stage)
	var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OUT+"before/martial_training_ground.json.txt"))
	var clean: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OUT+"candidate-training-roof.json"))
	var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OUT+"source-replay.json"))
	var old_shape:=make_roof(old.roof_collision_faces,16)
	var clean_shape:=make_roof(clean.roof_collision_faces,32)
	for i in 3:await physics_frame
	check("Godot old shape retains 4560 faces / 84 degenerate",old_shape.get_faces().size()/3==4560 and zero_count(old_shape)==84)
	check("Godot candidate has 4476 nondegenerate faces",clean_shape.get_faces().size()/3==4476 and zero_count(clean_shape)==0)
	for part: Dictionary in source.roof_parts:
		var a: Array=part.parameters
		var nx:=ceili(float(a[3])/.25);var nz:=ceili(float(a[4])/.25)
		for ix in nx+1:
			for iz in nz+1:points.append(Vector3(float(a[1])-float(a[3])/2+float(a[3])*ix/nx,0,float(a[2])-float(a[4])/2+float(a[4])*iz/nz))
	var mismatches: Array=[];var hit_count:=0;var zero_normals:=0
	for p: Vector3 in points:
		for upward: bool in [false,true]:
			var a:=ray(p,16,upward);var b:=ray(p,32,upward)
			if not a.is_empty():
				hit_count+=1
				if a.normal.length()<.1:zero_normals+=1
			if a.is_empty()!=b.is_empty() or (not a.is_empty() and a.position.distance_to(b.position)>.00002):
				mismatches.append({"at":str(p),"upward":upward,"old":str(a.get("position")),"clean":str(b.get("position"))})
	check("bidirectional quarter-metre roof hit coverage/positions unchanged",mismatches.is_empty(),mismatches.slice(0,10))
	check("original ray hits have valid normals",zero_normals==0,zero_normals)
	var sphere:=SphereShape3D.new();sphere.radius=.2
	var q:=PhysicsShapeQueryParameters3D.new();q.shape=sphere
	var sphere_mismatch:=0
	for i in range(0,points.size(),7):
		q.transform.origin=Vector3(points[i].x,10,points[i].z);q.motion=Vector3(0,-12,0)
		q.collision_mask=16;var a:=stage.get_world_3d().direct_space_state.cast_motion(q)
		q.collision_mask=32;var b:=stage.get_world_3d().direct_space_state.cast_motion(q)
		if absf(a[0]-b[0])>.00002:sphere_mismatch+=1
	check("camera-sphere sweep fractions unchanged",sphere_mismatch==0,sphere_mismatch)
	# Alternating order limits cache/order bias. These are synchronous query
	# microbenchmarks, not total game-physics or GPU/frame-time measurements.
	var timings: Array=[]
	for batch in 8:
		for layer: int in ([16,32] if batch%2==0 else [32,16]):
			var start:=Time.get_ticks_usec()
			for i in 10000:ray(points[(i*13)%points.size()],layer)
			var ray_us: float=(Time.get_ticks_usec()-start)/10000.0
			q.collision_mask=layer
			start=Time.get_ticks_usec()
			for i in 4000:
				var p: Vector3=points[(i*17)%points.size()]
				q.transform.origin=Vector3(p.x,10,p.z);q.motion=Vector3(0,-12,0)
				stage.get_world_3d().direct_space_state.cast_motion(q)
			var cast_us: float=(Time.get_ticks_usec()-start)/4000.0
			timings.append({"batch":batch,"faces":4560 if layer==16 else 4476,"ray_microseconds":ray_us,"sphere_cast_microseconds":cast_us})
	var failed:=checks.filter(func(c):return not c.pass).size()
	FileAccess.open(OUT+"roof-physics.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"ray_comparisons":points.size()*2,"ray_hits":hit_count,"position_mismatches":mismatches,"sphere_comparisons":ceili(points.size()/7.0),"sphere_mismatches":sphere_mismatch,"timings":timings},"  "))
	print(checks.size()-failed," PASS / ",failed," FAIL; ",points.size()*2," rays; ",ceili(points.size()/7.0)," sphere casts")
	quit(1 if failed else 0)

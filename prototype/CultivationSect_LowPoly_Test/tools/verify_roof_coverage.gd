extends SceneTree
## Compare actual Godot physics against identical world-space roof colliders.
## Dedicated collision layers isolate the two versions from all stage geometry.
var checks: Array = []
var world: Node3D
var space: PhysicsDirectSpaceState3D
var comparisons := 0
var hits := 0
var mismatches: Array = []
const OUT := "res://reports/roof-collision-fix-2026-10-22/"
func _initialize() -> void: call_deferred("run")
func check(label: String, ok: bool, detail: Variant = null) -> void:
	checks.append({"check":label,"pass":ok,"detail":detail})
	if not ok: push_error(label+" "+str(detail))
func make_roof(data: Array, layer: int) -> void:
	var points := PackedVector3Array()
	for p: Array in data: points.append(Vector3(p[0],p[1],p[2]))
	var mesh := ConcavePolygonShape3D.new()
	mesh.set_faces(points)
	mesh.backface_collision = true
	var shape := CollisionShape3D.new()
	shape.shape = mesh
	var body := StaticBody3D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	body.add_child(shape)
	world.add_child(body)
func compare_ray(a: Vector3, b: Vector3) -> void:
	var old := space.intersect_ray(PhysicsRayQueryParameters3D.create(a,b,16))
	var fixed := space.intersect_ray(PhysicsRayQueryParameters3D.create(a,b,32))
	comparisons += 1
	if not old.is_empty(): hits += 1
	if old.is_empty()!=fixed.is_empty():
		mismatches.append({"from":str(a),"to":str(b),"problem":"hit coverage differs"})
	elif not old.is_empty() and old.position.distance_to(fixed.position)>.0001:
		mismatches.append({"from":str(a),"to":str(b),"old":str(old.position),"fixed":str(fixed.position)})
func run() -> void:
	var before: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT+"before/main_sect_hall.json"))
	var after: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/architecture/tang_main_hall/main_sect_hall.json"))
	world = Node3D.new()
	root.add_child(world)
	make_roof(before.roof_collision_faces,16)
	make_roof(after.roof_collision_faces,32)
	await physics_frame
	await physics_frame
	space = world.get_world_3d().direct_space_state
	for ix in range(85):
		for iz in range(57):
			var x := -21.0+ix*.5
			var z := -12.0+iz*.5
			compare_ray(Vector3(x,24,z),Vector3(x,1,z))
			compare_ray(Vector3(x,1,z),Vector3(x,24,z))
	var degenerates := 0
	for i in range(0,before.roof_collision_faces.size(),3):
		var p: Array = before.roof_collision_faces[i]
		var q: Array = before.roof_collision_faces[i+1]
		var r: Array = before.roof_collision_faces[i+2]
		var a := Vector3(p[0],p[1],p[2])
		var b := Vector3(q[0],q[1],q[2])
		var c := Vector3(r[0],r[1],r[2])
		if (b-a).cross(c-a).length_squared()==0:
			degenerates += 1
			var center := (a+b+c)/3
			for dx in [-.005,0.0,.005]:
				for dz in [-.005,0.0,.005]:
					compare_ray(Vector3(center.x+dx,24,center.z+dz),Vector3(center.x+dx,1,center.z+dz))
	check("Original 64 collapsed faces reproduced",degenerates==64,degenerates)
	check("Broad roof grid and ridge probes exercise surfaces",hits>5000,{"comparisons":comparisons,"hits":hits})
	check("Roof hit coverage and positions unchanged",mismatches.is_empty(),mismatches.slice(0,12))
	check("Expected collision-only triangle reduction",before.roof_collision_faces.size()/3==2432 and after.roof_collision_faces.size()/3==2368)
	var failed := checks.filter(func(c):return not c.pass).size()
	var file := FileAccess.open(OUT+"coverage-physics-results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"ray_comparisons":comparisons,"hits":hits,"mismatch_count":mismatches.size(),"position_tolerance":.0001,"limits":"Finite grid/ridge sampling; exact preservation of every valid triangle is separately proved by collision-repair.json."},"\t"))
	file.close()
	print("Roof coverage: "+str(checks.size()-failed)+" PASS / "+str(failed)+" FAIL; "+str(comparisons)+" ray comparisons")
	quit(1 if failed else 0)

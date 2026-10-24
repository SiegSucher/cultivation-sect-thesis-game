extends RefCounted
## Additive map dressing. Canonical architecture and environmental scenes stay intact.
const ASSETS := "res://staging/claude_environment_batch1/"
var root: Node3D
var terrain: RefCounted
var rng := RandomNumberGenerator.new()
var batches := {}
var sources := {}

func box(size: Vector3, at: Vector3, color: String, basis: Basis = Basis.IDENTITY) -> void:
	var key := str(size)+color
	if not batches.has(key): batches[key] = {"size":size,"color":color,"poses":[]}
	batches[key].poses.append(Transform3D(basis,at))

func prop(id: String, x: float, z: float, yaw: float = 0) -> void:
	if not sources.has(id): sources[id] = load(ASSETS+id+"/"+id+".tscn")
	var item: Node3D = sources[id].instantiate()
	item.position = Vector3(x,terrain.height(x,z),z)
	item.rotation.y = yaw
	root.add_child(item)

func build(world: Node3D, ground: RefCounted, data: Dictionary) -> void:
	terrain = ground
	rng.seed = 241024
	root = Node3D.new()
	root.name = "ValleyPolish"
	world.add_child(root)
	# Narrow edge stones and joints add human scale to long uninterrupted roads.
	# They are visual accents outside the walking surface, without hidden blockers.
	for path: Dictionary in data.paths:
		for i in range(path.points.size()-1):
			var a: Vector3 = terrain.vec(path.points[i])
			var b: Vector3 = terrain.vec(path.points[i+1])
			var delta := b-a
			var length := Vector2(delta.x,delta.z).length()
			var side := Vector3(-delta.z,0,delta.x).normalized()
			var basis := Basis.looking_at(delta.normalized(),Vector3.UP)
			var count := ceili(length/2.5)
			for j in count:
				var at := a.lerp(b,(j+.5)/count)
				for sign_value in [-1,1]:
					box(Vector3(.32,.20,delta.length()/count-.06),at+side*(path.width*.5+.22)*sign_value+Vector3.UP*.08,"687168",basis)
				if path.kind=="stone" and absf(delta.y)<.1:
					box(Vector3(path.width-.3,.012,.025),at+Vector3.UP*.034,"626b61",basis)
			# Stone lanterns mark longer stairs, always outside the route clearance.
			if absf(delta.y)>1:
				for f in [.06,.50,.94]:
					var at := a.lerp(b,f)
					for sign_value in [-1,1]:
						var q: Vector3 = at+side*(path.width*.5+2.0)*sign_value
						if not terrain.near_building(q.x,q.z,3): prop("stone_lantern",q.x,q.z)
	# Inlaid court paving: slim joints with a contrasting perimeter, centre open.
	for court: Dictionary in data.forecourts:
		var at: Vector3 = terrain.vec(court.position)
		var w: float = court.size[0]
		var d: float = court.size[1]
		for x in range(1,int(w/3)):
			box(Vector3(.025,.012,d-.5),at+Vector3(-w/2+x*3,.05,0),"687064")
		for z in range(1,int(d/3)):
			box(Vector3(w-.5,.012,.025),at+Vector3(0,.05,-d/2+z*3),"687064")
		for side in [-1,1]:
			box(Vector3(w,.025,.30),at+Vector3(0,.055,side*(d/2-.2)),"626e64")
			box(Vector3(.30,.025,d),at+Vector3(side*(w/2-.2),.055,0),"626e64")
	# Layered planted islands around districts; exclude buildings, routes, courts,
	# steep ground, and the pond. Scatter within islands instead of uniform rows.
	var islands := [Vector2(-29,113),Vector2(29,113),Vector2(-31,61),Vector2(25,60),Vector2(-90,18),Vector2(70,9),Vector2(-43,-33),Vector2(55,-40),Vector2(-41,-128),Vector2(41,-130),Vector2(-43,-159),Vector2(42,-165),Vector2(-88,-172),Vector2(-146,-193),Vector2(104,-38),Vector2(199,-10),Vector2(196,-91),Vector2(80,-127)]
	for center: Vector2 in islands:
		for i in 28:
			var q := center+Vector2(rng.randf_range(-10,10),rng.randf_range(-9,9))
			if terrain.near_route(q.x,q.y,2.8) or terrain.near_building(q.x,q.y,3): continue
			var court_hit := false
			for court: Dictionary in data.forecourts:
				if absf(q.x-court.position[0])<court.size[0]/2+1 and absf(q.y-court.position[2])<court.size[1]/2+1: court_hit=true
			if court_hit: continue
			var h: float = terrain.height(q.x,q.y)
			if maxf(absf(terrain.height(q.x+1,q.y)-h),absf(terrain.height(q.x,q.y+1)-h))>.32: continue
			if Vector2((q.x-data.pond.center[0])/14,(q.y-data.pond.center[1])/14).length()<1.1: continue
			var id := "grass_tuft"
			if i%13==0: id="pine_tiered"
			elif i%11==0: id="rock_cluster"
			elif i%7==0: id="bamboo_cluster"
			elif i%3==0: id="flowering_shrub"
			prop(id,q.x,q.y,rng.randf_range(0,TAU))
	# Small rest pockets frame the Hall and the garden without filling the courts.
	for q: Vector2 in [Vector2(-34,-145),Vector2(34,-145),Vector2(-80,42),Vector2(190,-17)]:
		if not terrain.near_building(q.x,q.y,3): prop("stone_bench",q.x,q.y,PI/2)
	# Batch repeated paving into a few draws rather than thousands of nodes.
	for key in batches:
		var batch: Dictionary = batches[key]
		var mesh := BoxMesh.new()
		mesh.size = batch.size
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(batch.color)
		mat.roughness = .95
		mesh.material = mat
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = batch.poses.size()
		for i in mm.instance_count: mm.set_instance_transform(i,batch.poses[i])
		var visual := MultiMeshInstance3D.new()
		visual.multimesh = mm
		visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(visual)
	print("Polish: ",root.get_child_count()," planting/paving groups")


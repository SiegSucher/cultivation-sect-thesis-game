extends RefCounted
## Simple baked blockout geometry. The heightfield is continuous; paths carve
## broad corridors into it. Stair visuals use the project's smooth-ramp convention.
var data: Dictionary
var pads: Array = []
var segments: Array = []
var colors := PackedColorArray()
var vertices := PackedVector3Array()
var normals := PackedVector3Array()
var road_vertices := PackedVector3Array()
var road_colors := PackedColorArray()
var road_normals := PackedVector3Array()
var ramp_faces := PackedVector3Array()
var mountain_profile = preload("res://phase4c/mountain_profile.gd").new()

func setup(layout: Dictionary) -> void:
	data = layout
	for pad: Dictionary in data.pads:
		var poly := PackedVector2Array()
		for p: Array in pad.polygon: poly.append(Vector2(p[0],p[1]))
		pads.append({"polygon":poly,"y":float(pad.y),"id":pad.id})
	for path: Dictionary in data.paths:
		for i in range(path.points.size()-1):
			segments.append({"a":vec(path.points[i]),"b":vec(path.points[i+1]),"width":float(path.width),"kind":path.kind,"id":path.id})

func vec(a: Array) -> Vector3: return Vector3(a[0],a[1],a[2])

func segment_sample(p: Vector2, a: Vector3, b: Vector3) -> Vector2:
	var u := Vector2(a.x,a.z)
	var delta := Vector2(b.x-a.x,b.z-a.z)
	var t := clampf((p-u).dot(delta)/maxf(.001,delta.length_squared()),0,1)
	return Vector2(p.distance_to(u+delta*t),lerpf(a.y,b.y,t))

func polygon_distance(p: Vector2, poly: PackedVector2Array) -> float:
	var distance := 10000.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i+1)%poly.size()]
		distance = minf(distance,p.distance_to(Geometry2D.get_closest_point_to_segment(p,a,b)))
	return distance

func height(x: float, z: float) -> float:
	var p := Vector2(x,z)
	# Retain the reviewed foothill calculation inside the occupied valley.
	# Outside it, the connected crest profile below replaces these radial peaks.
	var radius := Vector2(x/205.0,(z-10)/235.0).length()
	var h := 28.0*pow(clampf((radius-.62)/.9,0,1),1.3)
	var peak := 0.0
	for ridge: Array in [[-205,-225,154,110,122],[185,-250,168,115,110],[-255,-35,126,88,140],[256,25,116,90,140],[-205,240,132,110,112],[205,245,112,112,118],[-78,-305,82,100,65],[65,-326,68,115,65]]:
		var q := Vector2((x-ridge[0])/ridge[3],(z-ridge[1])/ridge[4]).length()
		peak = maxf(peak,pow(maxf(0,1-q),.82)*ridge[2])
	h += peak
	var rough := clampf((radius-.53)*1.5,0,1)
	h += (sin(x*.061+z*.026)*3.2+sin(x*.022-z*.059)*2.1)*rough
	# Replace only the outer backdrop, feathering into the exact previous ground.
	# Every occupied shelf, route, retaining cut and stair lies inside this box.
	var outside := Vector2(maxf(absf(x)-156.0,0.0),maxf(maxf(-170.0-z,z-190.0),0.0)).length()
	var backdrop_weight := smoothstep(0.0,48.0,outside)
	if backdrop_weight>0:
		var foothill := 28.0*pow(clampf((radius-.62)/.9,0,1),1.3)
		h = lerpf(h,foothill+mountain_profile.height(x,z),backdrop_weight)
	for pad: Dictionary in pads:
		var inside := Geometry2D.is_point_in_polygon(p,pad.polygon)
		var edge := 0.0 if inside else polygon_distance(p,pad.polygon)
		var shoulder := 17.0+3.5*sin(x*.045+z*.027)
		if edge < shoulder:
			var weight := 1.0 if inside else smoothstep(0.0,1.0,1.0-edge/shoulder)
			h = lerpf(h,pad.y,weight)
	# Keep shallow water on its own shelf rather than cutting the whole valley.
	var pond: Dictionary = data.pond
	var q := Vector2((x-pond.center[0])/pond.radius[0],(z-pond.center[1])/pond.radius[1]).length()
	if q<1.15: h = lerpf(h,float(pond.floor_y),clampf((1.15-q)*4.0,0,1))
	var nearest := 10000.0
	var desired := h
	var blend := 0.0
	for s: Dictionary in segments:
		# Reject far segments before the distance calculation.
		if x<minf(s.a.x,s.b.x)-s.width-6 or x>maxf(s.a.x,s.b.x)+s.width+6: continue
		if z<minf(s.a.z,s.b.z)-s.width-6 or z>maxf(s.a.z,s.b.z)+s.width+6: continue
		var sample := segment_sample(p,s.a,s.b)
		var edge: float = sample.x-s.width*.5
		if edge<5 and edge<nearest:
			nearest = edge
			desired = sample.y-.075
			blend = clampf(1.0-maxf(edge,0)/5.0,0,1)
	h = lerpf(h,desired,blend)
	for b: Dictionary in data.buildings:
		var at := vec(b.position)
		var local := Basis(Vector3.UP,-deg_to_rad(b.yaw))*Vector3(x-at.x,0,z-at.z)
		if local.x>=b.bounds.min[0]-4.1 and local.x<=b.bounds.max[0]+4.1 and local.z>=b.bounds.min[2]-4.1 and local.z<=b.bounds.max[2]+4.1:
			return at.y-.015
	for court: Dictionary in data.forecourts:
		if absf(x-court.position[0])<=court.size[0]*.5+.5 and absf(z-court.position[2])<=court.size[1]*.5+.5:
			return float(court.position[1])-.015
	return h

func near_route(x: float, z: float, clearance: float = 5.0) -> bool:
	for s: Dictionary in segments:
		if segment_sample(Vector2(x,z),s.a,s.b).x<s.width*.5+clearance: return true
	return false

func near_building(x: float, z: float, margin: float = 5.0) -> bool:
	for b: Dictionary in data.buildings:
		var at := vec(b.position)
		var p := Basis(Vector3.UP,-deg_to_rad(b.yaw))*Vector3(x-at.x,0,z-at.z)
		var lo: Array = b.bounds.min
		var hi: Array = b.bounds.max
		if p.x>lo[0]-margin and p.x<hi[0]+margin and p.z>lo[2]-margin and p.z<hi[2]+margin: return true
	return false

func tint(x: float, z: float, h: float, normal: Vector3) -> Color:
	var color := Color("606e50")
	if h>65: color = Color("5b655f").lerp(Color("858c80"),clampf((h-70)/150,0,1))
	if absf(normal.y)<.78: color = Color("64716c").lerp(Color("7a8278"),clampf(h/180,0,1))
	# A tiny spatial hash breaks up facets without visible periodic stripes.
	var r := fposmod(sin(x*12.9898+z*78.233)*43758.5453,1.0)*.035-.0175
	return color.lightened(r) if r>0 else color.darkened(-r)

func tri(a: Vector3,b: Vector3,c: Vector3) -> void:
	var n := (c-a).cross(b-a).normalized()
	var color := tint((a.x+b.x+c.x)/3.0,(a.z+b.z+c.z)/3.0,(a.y+b.y+c.y)/3.0,n)
	for p: Vector3 in [a,b,c]:
		vertices.append(p)
		normals.append(n)
		colors.append(color)

func road_tri(a: Vector3,b: Vector3,c: Vector3,color: Color,normal: Vector3 = Vector3.UP) -> void:
	# Paths can face any compass direction. Normalize triangle winding so the
	# two-sided shader never flips the intended upward normal below the ground.
	if (c-a).cross(b-a).dot(normal)<0:
		var swap := b
		b = c
		c = swap
	for p: Vector3 in [a,b,c]:
		road_vertices.append(p)
		road_normals.append(normal)
		road_colors.append(color)

func road_quad(a: Vector3,b: Vector3,c: Vector3,d: Vector3,color: Color,normal: Vector3 = Vector3.UP) -> void:
	road_tri(a,b,c,color,normal)
	road_tri(a,c,d,color,normal)

func add_ramp(a: Vector3,b: Vector3,side: Vector3) -> void:
	for p: Vector3 in [a-side,a+side,b+side,a-side,b+side,b-side]: ramp_faces.append(p)

func make_mesh(v: PackedVector3Array,n: PackedVector3Array,c: PackedColorArray) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_NORMAL] = n
	arrays[Mesh.ARRAY_COLOR] = c
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 1
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0,mat)
	return mesh

func build(root: Node3D,terrain_only: bool = false) -> void:
	var step := int(data.dimensions.grid)
	var min_x := int(data.dimensions.terrain_bounds[0])
	var min_z := int(data.dimensions.terrain_bounds[1])
	var max_x := int(data.dimensions.terrain_bounds[2])
	var max_z := int(data.dimensions.terrain_bounds[3])
	var heights := {}
	for x in range(min_x,max_x+step,step):
		for z in range(min_z,max_z+step,step): heights[Vector2i(x,z)] = height(x,z)
	for x in range(min_x,max_x,step):
		for z in range(min_z,max_z,step):
			var a := Vector3(x,heights[Vector2i(x,z)],z)
			var b := Vector3(x+step,heights[Vector2i(x+step,z)],z)
			var c := Vector3(x+step,heights[Vector2i(x+step,z+step)],z+step)
			var d := Vector3(x,heights[Vector2i(x,z+step)],z+step)
			tri(a,b,c)
			tri(a,c,d)
	var cuts = load("res://phase4c/retaining_terrain.gd").new()
	var cut: Dictionary = cuts.apply(vertices,normals,colors)
	vertices = cut.vertices
	normals = cut.normals
	colors = cut.colors
	# Phase 4B keeps this focused terrain correction reproducible without
	# changing any building, path, stair ramp, world tier or decoration recipe.
	var fitter = load("res://phase4c/focused_stair_terrain.gd").new()
	var fitted: Dictionary = fitter.apply(vertices,normals,colors,data)
	vertices = fitted.vertices
	normals = fitted.normals
	colors = fitted.colors
	var terrain_mesh := make_mesh(vertices,normals,colors)
	ResourceSaver.save(terrain_mesh,"res://phase4c/resources/terrain_mesh.res")
	var ground := MeshInstance3D.new()
	ground.name = "ContinuousValleyTerrain"
	ground.mesh = terrain_mesh
	# The broad continuous mesh produced distracting self-shadow stripes. Terrain
	# still receives tree/building shadows; faceted normals describe the cliffs.
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ground)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(vertices)
	shape.backface_collision = true
	ResourceSaver.save(shape,"res://phase4c/resources/terrain_collision.res")
	var body := StaticBody3D.new()
	body.name = "ValleyGroundCollision"
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	root.add_child(body)
	# Focused backdrop rebuilds preserve existing roads, visible stairs and ramps.
	if terrain_only: return
	for s: Dictionary in segments:
		var a: Vector3 = s.a
		var b: Vector3 = s.b
		var direction := Vector3(b.x-a.x,0,b.z-a.z).normalized()
		var side: Vector3 = Vector3(-direction.z,0,direction.x)*s.width*.5
		var color := Color("817966") if s.kind=="earth" else Color("7e867b")
		add_ramp(a,b,side)
		if s.kind=="stairs" and absf(b.y-a.y)>1.0:
			if a.y>b.y:
				var swap := a
				a = b
				b = swap
			var count := ceili((b.y-a.y)/.18)
			for i in count:
				var p := a.lerp(b,float(i)/count)
				var q := a.lerp(b,float(i+1)/count)
				var high := q.y+.025
				road_quad(Vector3(p.x,high,p.z)-side,Vector3(p.x,high,p.z)+side,Vector3(q.x,high,q.z)+side,Vector3(q.x,high,q.z)-side,color.lightened(.035 if i%4==0 else 0))
				var nose_dir := Vector3(q.x-p.x,0,q.z-p.z).normalized()*.045
				var nose_a := Vector3(p.x,high+.002,p.z)
				road_quad(nose_a-side,nose_a+side,nose_a+nose_dir+side,nose_a+nose_dir-side,Color("9aa394"))
				var outward := Vector3(a.x-b.x,0,a.z-b.z).normalized()
				road_quad(p-side,p+side,Vector3(p.x,high,p.z)+side,Vector3(p.x,high,p.z)-side,Color("4f6267"),outward)
		else:
			road_quad(a-side+Vector3.UP*.025,a+side+Vector3.UP*.025,b+side+Vector3.UP*.025,b-side+Vector3.UP*.025,color)
		# Flat circular caps close turns; stair endpoints have matching heights.
		for p: Vector3 in [a,b]:
			# A level end disk must never project over a rising flight. It made
			# floating dark shelves across the stairs shown in the user's video.
			var slope_join := false
			for adjacent: Dictionary in segments:
				if absf(adjacent.a.y-adjacent.b.y)>.1 and (p.distance_to(adjacent.a)<.1 or p.distance_to(adjacent.b)<.1):
					slope_join = true
			if slope_join: continue
			for i in 12:
				var u: Vector3 = Vector3(cos(i*TAU/12),0,sin(i*TAU/12))*s.width*.5
				var v: Vector3 = Vector3(cos((i+1)*TAU/12),0,sin((i+1)*TAU/12))*s.width*.5
				road_tri(p+Vector3.UP*.027,p+u+Vector3.UP*.027,p+v+Vector3.UP*.027,color)
	for court: Dictionary in data.forecourts:
		var p := vec(court.position)+Vector3.UP*.04
		var w: float = court.size[0]/2.0
		var d: float = court.size[1]/2.0
		road_quad(p+Vector3(-w,0,-d),p+Vector3(w,0,-d),p+Vector3(w,0,d),p+Vector3(-w,0,d),Color("858b7b"))
	var roads := MeshInstance3D.new()
	roads.name = "RoadsCourtsAndVisibleStairs"
	roads.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	roads.mesh = make_mesh(road_vertices,road_normals,road_colors)
	ResourceSaver.save(roads.mesh,"res://phase4c/resources/paths_mesh.res")
	root.add_child(roads)
	var ramps := StaticBody3D.new()
	ramps.name = "SmoothPathRampCollision"
	var ramp := CollisionShape3D.new()
	var ramp_shape := ConcavePolygonShape3D.new()
	ramp_shape.set_faces(ramp_faces)
	ramp_shape.backface_collision = true
	ramp.shape = ramp_shape
	ResourceSaver.save(ramp_shape,"res://phase4c/resources/path_collision.res")
	ramps.add_child(ramp)
	root.add_child(ramps)
	print("Terrain triangles: ",vertices.size()/3," / visible path triangles: ",road_vertices.size()/3)

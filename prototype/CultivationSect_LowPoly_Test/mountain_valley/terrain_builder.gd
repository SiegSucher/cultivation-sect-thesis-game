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

func setup(layout: Dictionary) -> void:
	data = layout
	for pad: Dictionary in data.pads:
		var poly := PackedVector2Array()
		for p: Array in pad.polygon: poly.append(Vector2(p[0],p[1]))
		pads.append({"polygon":poly,"y":float(pad.y),"id":pad.id})
	for path: Dictionary in data.paths:
		for i in range(path.points.size()-1):
			segments.append({"a":vec(path.points[i]),"b":vec(path.points[i+1]),"width":float(path.width),"kind":path.kind})

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
	var radius := Vector2(x/315.0,(z-10.0)/365.0).length()
	var angle := atan2(z-10,x)
	var ring := pow(clampf((radius-.68)/.88,0,1),1.28)
	var crest := 180.0+36.0*sin(angle*5.0+.4)+22.0*sin(angle*9.0)
	# The southern cleft opens into the winding forest; north/west ridges stay high.
	var opening := 1.0-.40*exp(-pow((angle-PI/2.0)/.30,2))
	var h := ring*crest*opening+sin(x*.027)*cos(z*.023)*3.5*(1.0-ring)
	for pad: Dictionary in pads:
		var inside := Geometry2D.is_point_in_polygon(p,pad.polygon)
		var edge := 0.0 if inside else polygon_distance(p,pad.polygon)
		if edge < 14:
			var weight := 1.0 if inside else pow(1.0-edge/14.0,.65)
			h = lerpf(h,pad.y,weight)
	# Keep shallow water on its own shelf rather than cutting the whole valley.
	var pond: Dictionary = data.pond
	var q := Vector2((x-pond.center[0])/pond.radius[0],(z-pond.center[1])/pond.radius[1]).length()
	if q<1.15: h = lerpf(h,18.55,clampf((1.15-q)*4.0,0,1))
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
	return lerpf(h,desired,blend)

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
	var color := Color("637552")
	if h>65: color = Color("626c61").lerp(Color("879285"),clampf((h-70)/150,0,1))
	if absf(normal.y)<.78: color = Color("5d6966").lerp(Color("78827a"),clampf(h/180,0,1))
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

func build(root: Node3D) -> void:
	var step := int(data.dimensions.grid)
	var lo := -560
	var hi := 560
	var heights := {}
	for x in range(lo,hi+step,step):
		for z in range(lo,hi+step,step): heights[Vector2i(x,z)] = height(x,z)
	for x in range(lo,hi,step):
		for z in range(lo,hi,step):
			var a := Vector3(x,heights[Vector2i(x,z)],z)
			var b := Vector3(x+step,heights[Vector2i(x+step,z)],z)
			var c := Vector3(x+step,heights[Vector2i(x+step,z+step)],z+step)
			var d := Vector3(x,heights[Vector2i(x,z+step)],z+step)
			tri(a,b,c)
			tri(a,c,d)
	# Phase 4B keeps this focused terrain correction reproducible without
	# changing any building, path, stair ramp, world tier or decoration recipe.
	var fitter = load("res://mountain_valley/focused_stair_terrain.gd").new()
	var fitted: Dictionary = fitter.apply(vertices,normals,colors,data)
	vertices = fitted.vertices
	normals = fitted.normals
	colors = fitted.colors
	var terrain_mesh := make_mesh(vertices,normals,colors)
	ResourceSaver.save(terrain_mesh,"res://mountain_valley/resources/terrain_mesh.res")
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
	ResourceSaver.save(shape,"res://mountain_valley/resources/terrain_collision.res")
	var body := StaticBody3D.new()
	body.name = "ValleyGroundCollision"
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	root.add_child(body)
	for s: Dictionary in segments:
		var a: Vector3 = s.a
		var b: Vector3 = s.b
		var direction := Vector3(b.x-a.x,0,b.z-a.z).normalized()
		var side: Vector3 = Vector3(-direction.z,0,direction.x)*s.width*.5
		var color := Color("817966") if s.kind=="earth" else Color("777d72")
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
				var outward := Vector3(a.x-b.x,0,a.z-b.z).normalized()
				road_quad(p-side,p+side,Vector3(p.x,high,p.z)+side,Vector3(p.x,high,p.z)-side,Color("667b80"),outward)
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
	ResourceSaver.save(roads.mesh,"res://mountain_valley/resources/paths_mesh.res")
	root.add_child(roads)
	var ramps := StaticBody3D.new()
	ramps.name = "SmoothPathRampCollision"
	var ramp := CollisionShape3D.new()
	var ramp_shape := ConcavePolygonShape3D.new()
	ramp_shape.set_faces(ramp_faces)
	ramp_shape.backface_collision = true
	ramp.shape = ramp_shape
	ResourceSaver.save(ramp_shape,"res://mountain_valley/resources/path_collision.res")
	ramps.add_child(ramp)
	root.add_child(ramps)
	print("Terrain triangles: ",vertices.size()/3," / visible path triangles: ",road_vertices.size()/3)

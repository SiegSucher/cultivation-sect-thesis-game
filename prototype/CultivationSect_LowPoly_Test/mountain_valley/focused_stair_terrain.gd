extends RefCounted
## Phase 4B: local ground fitting beneath the arrival/living flights only.
## Preserve all vertices outside the narrow strips. Existing stair ramps remain.
var flights: Array = []
var changed_vertices := 0
var refined_triangles := 0
var result_vertices := PackedVector3Array()
var result_normals := PackedVector3Array()
var result_colors := PackedColorArray()

func setup(layout: Dictionary) -> void:
	flights.clear()
	for path: Dictionary in layout.paths:
		if path.id not in ["entry_stairs","middle_stairs"]: continue
		var a: Array = path.points[0]
		var b: Array = path.points[1]
		flights.append({"x":float(a[0]),"za":float(a[2]),"zb":float(b[2]),"ya":float(a[1]),"yb":float(b[1]),"half_width":float(path.width)*.5})

func fit(p: Vector3) -> Vector3:
	var result := p
	for f: Dictionary in flights:
		var side: float = absf(p.x-f.x)
		var beyond: float = maxf(minf(f.za,f.zb)-p.z,p.z-maxf(f.za,f.zb))
		if side>f.half_width+1.5 or beyond>4: continue
		# The full 12 m stair stays clear. Fade within the existing shoulders;
		# lanterns at +/-8 m and their supporting terrain remain untouched.
		var width_weight: float = 1.0-clampf((side-f.half_width-.2)/1.3,0,1)
		var end_weight := 1.0-clampf((beyond-1.0)/3.0,0,1)
		var t: float = clampf((p.z-f.za)/(f.zb-f.za),0,1)
		var under: float = lerpf(f.ya,f.yb,t)-.075
		result.y = lerpf(result.y,minf(result.y,under),width_weight*end_weight)
	return result

func affected(a: Vector3,b: Vector3,c: Vector3) -> bool:
	for f: Dictionary in flights:
		if maxf(a.x,maxf(b.x,c.x))<f.x-f.half_width-1.5: continue
		if minf(a.x,minf(b.x,c.x))>f.x+f.half_width+1.5: continue
		if maxf(a.z,maxf(b.z,c.z))<minf(f.za,f.zb)-4: continue
		if minf(a.z,minf(b.z,c.z))>maxf(f.za,f.zb)+4: continue
		return true
	return false

func emit(a: Vector3,b: Vector3,c: Vector3,color: Color) -> void:
	var p := fit(a)
	var q := fit(b)
	var r := fit(c)
	for pair: Array in [[a,p],[b,q],[c,r]]:
		if absf(pair[0].y-pair[1].y)>.000001: changed_vertices += 1
	var normal := (r-p).cross(q-p).normalized()
	for v: Vector3 in [p,q,r]:
		result_vertices.append(v)
		result_normals.append(normal)
		result_colors.append(color)

func apply(vertices: PackedVector3Array,normals: PackedVector3Array,colors: PackedColorArray,layout: Dictionary) -> Dictionary:
	setup(layout)
	result_vertices = PackedVector3Array()
	result_normals = PackedVector3Array()
	result_colors = PackedColorArray()
	changed_vertices = 0
	refined_triangles = 0
	for i in range(0,vertices.size(),3):
		var a := vertices[i]
		var b := vertices[i+1]
		var c := vertices[i+2]
		if not affected(a,b,c):
			# Byte-identical payload for every triangle outside these approaches.
			for j in 3:
				result_vertices.append(vertices[i+j])
				result_normals.append(normals[i+j])
				result_colors.append(colors[i+j])
			continue
		refined_triangles += 1
		# Split each affected 4 m triangle into 1 m pieces. Samples along existing
		# triangle edges stay on the same lines, so the outer terrain has no seam.
		var u := (b-a)/4.0
		var v := (c-a)/4.0
		for x in 4:
			for z in range(4-x):
				var p := a+u*x+v*z
				var q := a+u*(x+1)+v*z
				var r := a+u*x+v*(z+1)
				emit(p,q,r,colors[i])
				if x+z<3: emit(q,a+u*(x+1)+v*(z+1),r,colors[i])
	return {"vertices":result_vertices,"normals":result_normals,"colors":result_colors,"refined_original_triangles":refined_triangles,"lowered_vertex_occurrences":changed_vertices}

extends RefCounted
## Compact copy of the Phase 4B fitting method, generalized to rotated flights.
## Only ground under sloped routes is refined; architecture and ramps stay intact.
var flights: Array = []
var result_vertices := PackedVector3Array()
var result_normals := PackedVector3Array()
var result_colors := PackedColorArray()
var refined_triangles := 0

func setup(layout: Dictionary) -> void:
	flights.clear()
	for path: Dictionary in layout.paths:
		for i in range(path.points.size()-1):
			var av: Array = path.points[i]
			var bv: Array = path.points[i+1]
			if absf(av[1]-bv[1])<.1: continue
			var a := Vector2(av[0],av[2])
			var b := Vector2(bv[0],bv[2])
			var direction := (b-a).normalized()
			flights.append({"a":a,"b":b,"direction":direction,"side":Vector2(-direction.y,direction.x),"length":a.distance_to(b),"ya":float(av[1]),"yb":float(bv[1]),"half":float(path.width)*.5})

func fit(p: Vector3) -> Vector3:
	var result := p
	for f: Dictionary in flights:
		var delta: Vector2 = Vector2(p.x,p.z)-f.a
		var along: float = delta.dot(f.direction)
		var side: float = absf(delta.dot(f.side))
		var beyond: float = maxf(-along,along-f.length)
		if side>f.half+1.5 or beyond>4: continue
		var w: float = (1-clampf((side-f.half-.2)/1.3,0,1))*(1-clampf((beyond-1)/3,0,1))
		var y: float = lerpf(f.ya,f.yb,clampf(along/f.length,0,1))-.075
		result.y = lerpf(result.y,minf(result.y,y),w)
	return result

func affected(a: Vector3,b: Vector3,c: Vector3) -> bool:
	for f: Dictionary in flights:
		var margin: float = f.half+5.5
		if maxf(a.x,maxf(b.x,c.x))<minf(f.a.x,f.b.x)-margin or minf(a.x,minf(b.x,c.x))>maxf(f.a.x,f.b.x)+margin: continue
		if maxf(a.z,maxf(b.z,c.z))<minf(f.a.y,f.b.y)-margin or minf(a.z,minf(b.z,c.z))>maxf(f.a.y,f.b.y)+margin: continue
		return true
	return false

func emit(a: Vector3,b: Vector3,c: Vector3,color: Color) -> void:
	var p := fit(a)
	var q := fit(b)
	var r := fit(c)
	var normal := (r-p).cross(q-p).normalized()
	for v: Vector3 in [p,q,r]:
		result_vertices.append(v)
		result_normals.append(normal)
		result_colors.append(color)

func apply(vertices: PackedVector3Array,normals: PackedVector3Array,colors: PackedColorArray,layout: Dictionary) -> Dictionary:
	setup(layout)
	for i in range(0,vertices.size(),3):
		var a := vertices[i]
		var b := vertices[i+1]
		var c := vertices[i+2]
		if not affected(a,b,c):
			for j in 3:
				result_vertices.append(vertices[i+j])
				result_normals.append(normals[i+j])
				result_colors.append(colors[i+j])
			continue
		refined_triangles += 1
		var u := (b-a)/4.0
		var v := (c-a)/4.0
		for x in 4:
			for z in range(4-x):
				var p := a+u*x+v*z
				var q := a+u*(x+1)+v*z
				var r := a+u*x+v*(z+1)
				emit(p,q,r,colors[i])
				if x+z<3: emit(q,a+u*(x+1)+v*(z+1),r,colors[i])
	return {"vertices":result_vertices,"normals":result_normals,"colors":result_colors}

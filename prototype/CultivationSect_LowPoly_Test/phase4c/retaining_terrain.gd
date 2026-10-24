extends RefCounted
## Local cuts hidden behind four constructed edges and the overlook corner.
## Everything else keeps the continuous terrain/rock-shoulder treatment.
const CUTS := [
	[Vector2(-20,-44),Vector2(-4,-44),Vector2(0,1),20.02],
	[Vector2(28,-44),Vector2(44,-44),Vector2(0,1),20.02],
	[Vector2(-40,64),Vector2(-24,64),Vector2(0,1),6.02],
	[Vector2(24,68),Vector2(40,68),Vector2(0,1),6.02],
	[Vector2(149,-40),Vector2(149,-52),Vector2(1,0),8.02],
	[Vector2(149,-52),Vector2(137,-52),Vector2(0,-1),8.02],
]
var v := PackedVector3Array()
var n := PackedVector3Array()
var c := PackedColorArray()
func fit(p: Vector3) -> Vector3:
	var result := p
	for cut: Array in CUTS:
		var direction: Vector2 = (cut[1]-cut[0]).normalized()
		var delta := Vector2(p.x,p.z)-Vector2(cut[0])
		var along := delta.dot(direction)
		var out: float = delta.dot(cut[2])
		var length: float = cut[0].distance_to(cut[1])
		if along<-.3 or along>length+.3 or out<0 or out>10: continue
		var wx := 1.0-clampf(maxf(-along,along-length)/.3,0,1)
		var wz := 1.0-smoothstep(4.0,10.0,out)
		result.y = lerpf(result.y,minf(result.y,float(cut[3])),wx*wz)
	return result
func affected(a: Vector3,b: Vector3,c0: Vector3) -> bool:
	for cut: Array in CUTS:
		var lo: Vector2 = Vector2(cut[0]).min(cut[1])-Vector2.ONE
		var hi: Vector2 = Vector2(cut[0]).max(cut[1])+Vector2.ONE
		lo = lo.min(lo+cut[2]*10)
		hi = hi.max(hi+cut[2]*10)
		if maxf(a.x,maxf(b.x,c0.x))<lo.x or minf(a.x,minf(b.x,c0.x))>hi.x: continue
		if maxf(a.z,maxf(b.z,c0.z))<lo.y or minf(a.z,minf(b.z,c0.z))>hi.y: continue
		return true
	return false
func emit(a: Vector3,b: Vector3,c0: Vector3,color: Color) -> void:
	var p := fit(a)
	var q := fit(b)
	var r := fit(c0)
	var normal := (r-p).cross(q-p).normalized()
	var shade := Color("65716b") if normal.y<.75 else color
	for at: Vector3 in [p,q,r]:
		v.append(at)
		n.append(normal)
		c.append(shade)
func apply(vertices: PackedVector3Array,normals: PackedVector3Array,colors: PackedColorArray) -> Dictionary:
	for i in range(0,vertices.size(),3):
		var a := vertices[i]
		var b := vertices[i+1]
		var c0 := vertices[i+2]
		if not affected(a,b,c0):
			for j in 3:
				v.append(vertices[i+j]);n.append(normals[i+j]);c.append(colors[i+j])
			continue
		var u := (b-a)/8.0
		var w := (c0-a)/8.0
		for x in 8:
			for z in range(8-x):
				var p := a+u*x+w*z
				var q := a+u*(x+1)+w*z
				var r := a+u*x+w*(z+1)
				emit(p,q,r,colors[i])
				if x+z<7: emit(q,a+u*(x+1)+w*(z+1),r,colors[i])
	return {"vertices":v,"normals":n,"colors":c}

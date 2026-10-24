extends RefCounted
## Query the actual baked terrain, including local fits, before seating props.
var vertices: PackedVector3Array
var buckets := {}
func setup(v: PackedVector3Array) -> void:
	vertices = v
	for i in range(0,v.size(),3):
		var lo := Vector2(v[i].x,v[i].z).min(Vector2(v[i+1].x,v[i+1].z)).min(Vector2(v[i+2].x,v[i+2].z))
		var hi := Vector2(v[i].x,v[i].z).max(Vector2(v[i+1].x,v[i+1].z)).max(Vector2(v[i+2].x,v[i+2].z))
		for x in range(floori(lo.x/8),floori(hi.x/8)+1):
			for z in range(floori(lo.y/8),floori(hi.y/8)+1):
				var key := Vector2i(x,z)
				if not buckets.has(key): buckets[key] = []
				buckets[key].append(i)
func height(x: float,z: float) -> float:
	var high := -1000.0
	var p := Vector2(x,z)
	for i: int in buckets.get(Vector2i(floori(x/8),floori(z/8)),[]):
		var a := Vector2(vertices[i].x,vertices[i].z)
		var b := Vector2(vertices[i+1].x,vertices[i+1].z)
		var c := Vector2(vertices[i+2].x,vertices[i+2].z)
		var area := (b-a).cross(c-a)
		if absf(area)<.000001: continue
		var u := (p-a).cross(c-a)/area
		var v := (b-a).cross(p-a)/area
		if u>=-.0001 and v>=-.0001 and u+v<=1.0001:
			high = maxf(high,vertices[i].y+u*(vertices[i+1].y-vertices[i].y)+v*(vertices[i+2].y-vertices[i].y))
	return high

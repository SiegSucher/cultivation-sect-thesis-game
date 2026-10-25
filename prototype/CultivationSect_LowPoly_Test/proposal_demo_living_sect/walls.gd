extends Node3D
## Metre-scale masonry on the original footprints, with sampled, buried foundations.
const Craft := preload("res://proposal_demo_living_sect/craft.gd")
var world: Node3D
var craft: RefCounted
var terrain_exclude: Array[RID] = []
var sections := []
var piers := []
func ground(at: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(at+Vector3.UP*60,at-Vector3.UP*80,1,terrain_exclude)
	for i in 20:
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if not hit: return at.y
		if "ValleyGroundCollision" in str(hit.collider.get_path()): return hit.position.y
		var excluded := q.exclude
		excluded.append(hit.rid)
		q.exclude = excluded
	return at.y
func setup(scene: Node3D) -> void:
	world = scene
	name = "LivingEntranceWalls"
	for c: CollisionObject3D in world.find_children("*","CollisionObject3D",true,false):
		if "ValleyGroundCollision" not in str(c.get_path()): terrain_exclude.append(c.get_rid())
	craft = Craft.new(self)
	for wing in ["GateWest","GateEast"]:
		var old: Node3D = world.get_node("DemoBoundary/"+wing)
		var saved := []
		for module: Node3D in old.get_children(): saved.append({"name":str(module.name),"xf":module.global_transform})
		world.get_node("DemoBoundary").remove_child(old)
		old.queue_free()
		for item: Dictionary in saved:
			var id: String = item.name
			var xf: Transform3D = item.xf
			if "wall_" in id: build_section(xf,4.0 if "4m" in id else 2.0)
			elif "pier" in id or "corner" in id or "gate_end" in id: build_pier(xf,"gate_end" in id)
			elif "outcrop" in id or "rocks" in id:
				var kind := "rock_outcrop" if "outcrop" in id else "rock_cluster"
				var rock: Node3D = load("res://staging/claude_environment_batch1/"+kind+"/"+kind+".tscn").instantiate()
				add_child(rock)
				rock.global_transform = xf
	craft.finish()
func build_section(xf: Transform3D, length: float) -> void:
	var at := xf.origin
	var axis := xf.basis.x
	var yaw := xf.basis.get_euler().y
	var lo := INF
	var hi := -INF
	for i in 9:
		for offset in [-.72,0,.72]:
			var g := ground(at+axis*length*i/8.0+xf.basis.z*offset)
			lo = minf(lo,g)
			hi = maxf(hi,g)
	var base := lo-.22
	var top := at.y+5.5
	var center := at+axis*length*.5
	var plinth_top := maxf(hi+.28,at.y+1.05)
	craft.box(Vector3(center.x,(base+plinth_top)*.5,center.z),Vector3(length+.03,plinth_top-base,1.22),"727e78",yaw,true)
	craft.box(Vector3(center.x,(plinth_top+top)*.5,center.z),Vector3(length+.03,top-plinth_top,1.04),"c2c1a6",yaw,true)
	for y in [plinth_top+.03,top-.16]: craft.box(Vector3(center.x,y,center.z),Vector3(length+.05,.16,1.22),"9caa9b",yaw)
	var y := base+.45
	while y < plinth_top-.12:
		craft.box(Vector3(center.x,y,center.z),Vector3(length,.022,1.235),"5f6d68",yaw)
		y += .46
	for j in range(1,int(length)):
		var c := at+axis*j
		craft.box(Vector3(c.x,plinth_top-.24,c.z),Vector3(.025,.43,1.24),"5f6d68",yaw)
	cap(center,top,length+.10,yaw)
	sections.append({"from":at,"to":at+axis*length,"base":base,"top":top,"ground_min":lo,"ground_max":hi,"width":1.22})
func cap(at: Vector3, top: float, length: float, yaw: float) -> void:
	craft.box(Vector3(at.x,top,at.z),Vector3(length,.16,1.48),"675e4a",yaw)
	var basis := Basis(Vector3.UP,yaw)
	for side: float in [-1.0,1.0]:
		var center := Vector3(at.x,top+.27,at.z)+basis.z*side*.35
		var m := BoxMesh.new()
		m.size = Vector3(length,.13,.80)
		craft.add(m,center,"3f6964",Vector3(side*.40,yaw,0))
		for j in int(length/.32)+1:
			var pos := center+basis.x*(-length*.5+j*.32)
			craft.beam(pos-basis.z*.35+Vector3.UP*side*.14,pos+basis.z*.35-Vector3.UP*side*.14,.018,"577d71")
	craft.box(Vector3(at.x,top+.47,at.z),Vector3(length+.06,.13,.16),"567e70",yaw)
func build_pier(xf: Transform3D, abutment: bool) -> void:
	var at := xf.origin
	var lo := INF
	for x in [-.9,.9]:
		for z in [-.9,.9]: lo = minf(lo,ground(at+Vector3(x,0,z)))
	var top := at.y+6.08
	var base := lo-.26
	var width := 1.64 if abutment else 1.48
	craft.box(Vector3(at.x,(base+top)*.5,at.z),Vector3(width,top-base,width),"87968a",xf.basis.get_euler().y,true)
	craft.box(Vector3(at.x,lo+.32,at.z),Vector3(width+.25,.65,width+.25),"697771",xf.basis.get_euler().y,true)
	craft.box(Vector3(at.x,top-.2,at.z),Vector3(width+.16,.2,width+.16),"b4b99e",xf.basis.get_euler().y)
	cap(at,top,width+.4,xf.basis.get_euler().y)
	piers.append({"at":at,"base":base,"top":top,"width":width,"abutment":abutment})

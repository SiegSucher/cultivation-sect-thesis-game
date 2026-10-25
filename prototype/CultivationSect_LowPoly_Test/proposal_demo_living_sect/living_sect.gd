extends Node3D
## Living spaces, residents and one optional scenic interaction. Core learning state stays in quest.
const Craft := preload("res://proposal_demo_living_sect/craft.gd")
const Resident := preload("res://proposal_demo_living_sect/resident.gd")
var world: Node3D
var craft: RefCounted
var residents: Array[CharacterBody3D] = []
var spaces := []
var restored := false
var visits := {}
var near_id := ""
var dusk: Node3D
var walls: Node3D
var populated := false
var terrain_exclude: Array[RID] = []
func setup(scene: Node3D) -> void:
	world = scene
	name = "LivingSect"
	for c: CollisionObject3D in world.find_children("*","CollisionObject3D",true,false):
		if "ValleyGroundCollision" not in str(c.get_path()) and "SmoothPathRampCollision" not in str(c.get_path()): terrain_exclude.append(c.get_rid())
	craft = Craft.new(self)
	build_spaces()
	craft.finish()
	# The clothes are a separate material batch, so only their free lower edges move.
	var laundry: MeshInstance3D = get_node("Craft_a5ac97")
	var cloth_shader := Shader.new()
	cloth_shader.code = "shader_type spatial; render_mode cull_disabled; void vertex(){float loose=clamp((12.2-VERTEX.y),0.0,1.0); VERTEX.z+=sin(TIME*1.5+VERTEX.x)*0.06*loose;} void fragment(){ALBEDO=vec3(0.57,0.63,0.52);ROUGHNESS=0.95;}"
	var cloth_material := ShaderMaterial.new()
	cloth_material.shader = cloth_shader
	laundry.material_override = cloth_material
	populate()
	walls = Node3D.new()
	walls.set_script(preload("res://proposal_demo_living_sect/walls.gd"))
	add_child(walls)
	walls.setup(world)
	dusk = Node3D.new()
	dusk.set_script(preload("res://proposal_demo_living_sect/evening.gd"))
	add_child(dusk)
	dusk.setup(world)
	world.player.collision_mask = 5
	populated = true
func ground(at: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(at+Vector3.UP*50,at-Vector3.UP*70,1,terrain_exclude)
	for i in 16:
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if not hit: return at.y
		if "ValleyGroundCollision" in str(hit.collider.get_path()) or "SmoothPathRampCollision" in str(hit.collider.get_path()): return hit.position.y
		var excluded := q.exclude
		excluded.append(hit.rid)
		q.exclude = excluded
	return at.y
func asset(kind: String, at: Vector3, yaw := 0.0, scale_value := 1.0) -> void:
	at.y = ground(at)
	var n: Node3D = load("res://staging/claude_environment_batch1/"+kind+"/"+kind+".tscn").instantiate()
	n.position = at
	n.rotation.y = yaw
	n.scale = Vector3.ONE*scale_value
	add_child(n)
func paving(at: Vector3, width: int, depth: int) -> void:
	# Flush pavers leave the inherited collision and principal elevations unchanged.
	for x in width:
		for z in depth:
			var pos := at+Vector3((x-(width-1)*.5)*.85,.025,(z-(depth-1)*.5)*.85)
			pos.y = ground(pos)+.026
			craft.box(pos,Vector3(.82,.045,.82),["9b9f89","a5a58e","929d8b"][(x+z*2)%3])
func bench(at: Vector3, yaw := 0.0) -> void:
	craft.box(at+Vector3.UP*.48,Vector3(2.1,.14,.55),"80745a",yaw,true)
	for side in [-.75,.75]:
		var p := at+Basis(Vector3.UP,yaw)*Vector3(side,.22,0)
		craft.box(p,Vector3(.22,.45,.44),"6d7770",yaw,true)
func table(at: Vector3) -> void:
	craft.box(at+Vector3.UP*.78,Vector3(2.5,.12,1.1),"71604a",0,true)
	for x in [-1,1]:
		for z in [-.35,.35]: craft.box(at+Vector3(x,.39,z),Vector3(.12,.78,.12),"5e503e",0,true)
	for x in [-.65,.5]:
		craft.box(at+Vector3(x,.86,0),Vector3(.36,.035,.26),"d2c29e")
		for j in 4: craft.box(at+Vector3(x,.881,-.07+j*.04),Vector3(.22,.005,.008),"8c7d60")
	craft.cylinder(at+Vector3(.95,.95,0),.075,.08,.24,"475d57")
func bed(at: Vector3, size: Vector2) -> void:
	craft.box(at+Vector3.UP*.06,Vector3(size.x,.12,size.y),"626b4a")
	for side in [-1,1]:
		craft.box(at+Vector3(side*size.x*.5,.12,0),Vector3(.17,.24,size.y+.15),"7e8b7a",0,true)
		craft.box(at+Vector3(0,.12,side*size.y*.5),Vector3(size.x,.24,.17),"7e8b7a",0,true)
	for x in int(size.x/1.5):
		for z in int(size.y/1.5):
			var p := at+Vector3(-size.x*.5+.75+x*1.5,0,-size.y*.5+.75+z*1.5)
			asset("flowering_shrub",p, float(x+z),.60)
func plaque(at: Vector3, text: String) -> void:
	craft.box(at+Vector3.UP*.36,Vector3(1.4,.72,.14),"626e65",0,true)
	var label := Label3D.new()
	label.position = at+Vector3(0,.43,.079)
	label.text = text
	label.font_size = 36
	label.pixel_size = .003
	label.outline_size = 0
	label.modulate = Color("e1d6b4")
	add_child(label)
func build_spaces() -> void:
	# The southern court stays open. These pockets occupy its edges, not the stair or quest triangle.
	paving(Vector3(-15,10,53),8,6)
	plaque(Vector3(-17,10,56),"MORNING FORMS")
	asset("training_dummy_rack",Vector3(-16,10,50),0,.85)
	bed(Vector3(-18,10,58),Vector2(3,3))
	spaces.append({"name":"Morning forms","center":Vector3(-12,10,53)})
	paving(Vector3(-12,10,28.8),11,8)
	table(Vector3(-12,10,28.5))
	# A modest open reading shade gives this court a recognisable silhouette.
	for x in [-15.5,-8.5]:
		for z in [26.5,30.5]:
			craft.cylinder(Vector3(x,10.13,z),.22,.26,.26,"7e8b7a")
			craft.cylinder(Vector3(x,11.65,z),.075,.10,3.05,"756346")
			craft.collider(Vector3(x,11.65,z),Vector3(.18,3.05,.18))
		craft.beam(Vector3(x,13.15,25.9),Vector3(x,13.15,31.1),.10,"756346")
	for z in [26.5,30.5]: craft.beam(Vector3(-16,13.17,z),Vector3(-8,13.17,z),.11,"756346")
	for x in 13:
		craft.beam(Vector3(-15.8+x*.63,13.32,25.9),Vector3(-15.8+x*.63,13.32,31.1),.045,"8c8961")
	for z in 8:
		craft.beam(Vector3(-15.7,13.38,26+z*.70),Vector3(-8.3,13.38,26+z*.70),.035,"a29d74")
	bench(Vector3(-12,10,30))
	bench(Vector3(-12,10,27))
	bed(Vector3(-18,10,29),Vector2(2.8,6))
	asset("pine_windswept",Vector3(-19,10,33),.5,.80)
	plaque(Vector3(-17,10,33),"READING COURT")
	spaces.append({"name":"Reading court","center":Vector3(-12,10,29)})
	paving(Vector3(25,10,41),9,7)
	table(Vector3(25,10,41))
	bench(Vector3(25,10,42.5))
	bench(Vector3(25,10,39.5))
	for x in [24.5,25.4]: craft.cylinder(Vector3(x,10.9,41.1),.065,.05,.14,"a4b8a9")
	craft.cylinder(Vector3(25,11.0,40.9),.10,.18,.26,"6b8c7c")
	bed(Vector3(30,10,41.2),Vector2(3,3))
	asset("pine_tiered",Vector3(33,10,38.5),.8,.80)
	plaque(Vector3(29.2,10,38.2),"TEA & WATER")
	spaces.append({"name":"Tea court","center":Vector3(25,10,41)})
	# Storage, tools and laundry show everyday work near the dining side.
	paving(Vector3(20,10,53),5,7)
	for z in [50,51.5]:
		craft.box(Vector3(20,10.4,z),Vector3(.9,.8,.8),"8f7855",0,true)
		for y in [10.13,10.65]: craft.box(Vector3(20,y,z),Vector3(.94,.075,.84),"5e5946")
	for x in [18.5,23.5]: craft.cylinder(Vector3(x,11.15,56),.045,.065,2.3,"776345")
	craft.beam(Vector3(18.5,12.25,56),Vector3(23.5,12.25,56),.012,"c4b98f")
	for x in [19.3,20.7,22.1]: craft.box(Vector3(x,11.7,56),Vector3(.8,1,.025),"a5ac97")
	bed(Vector3(22,10,46),Vector2(2.8,4))
	spaces.append({"name":"Court maintenance","center":Vector3(20,10,51)})
	# Footpaths are visual invitations, flush to the living terrace.
	for x in range(5,23,2): craft.box(Vector3(x,10.028,33),Vector3(1.5,.05,1.15),"a1a78e")
	for z in range(42,51,2): craft.box(Vector3(-10,10.028,z),Vector3(1.3,.05,1.5),"a1a78e")
	# Gate duty stations remain clear of the 8 m wide entrance.
	for side in [-1,1]:
		var p := Vector3(side*9.4,4,91)
		p.y = ground(p)
		paving(p,4,3)
		asset("sect_banner",p+Vector3(side*2,0,-.6),0,.85)
	# Larger terraces retain open space for training and ceremonies.
	bench(Vector3(-84,14,-1),PI/2)
	plaque(Vector3(-86,14,5),"TRAINING TERRACE")
	spaces.append({"name":"Training terrace","center":Vector3(-95,14,-3)})
	# A quiet ledge close to the existing herb garden, away from its doorway.
	asset("stone_bench",Vector3(109,10,-20),0,1)
	spaces.append({"name":"Healing garden","center":Vector3(113,10,-23)})
func resident(id: String, role: String, duty: String, at: Vector3, color: String, yaw: float, route_points: Array[Vector3] = []) -> CharacterBody3D:
	var n := CharacterBody3D.new()
	n.set_script(Resident)
	n.name = id.replace(" ","")
	n.display_name = id
	n.role = role
	n.duty = duty
	n.coat = Color(color)
	n.variant = residents.size()
	at.y = ground(at)+.04
	n.position = at
	n.rotation.y = yaw
	for i in route_points.size(): route_points[i].y = ground(route_points[i])+.04
	n.route = route_points
	n.watch = world.player
	add_child(n)
	residents.append(n)
	return n
func populate() -> void:
	resident("Guard Ren","guard","idle",Vector3(-9.4,4.1,91),"405b5c",PI)
	resident("Guard Suyin","guard","idle",Vector3(9.4,4.1,91),"405b5c",PI)
	resident("Yun","apprentice","train",Vector3(-12,10.05,53),"648079",-.5)
	resident("Shen","apprentice","train",Vector3(-13.5,10.05,55.5),"74645b",.4)
	resident("Reader Fei","apprentice","read",Vector3(-13.3,10.05,32),"637f86",0)
	resident("Archivist Wen","teacher","read",Vector3(-10.3,10.05,26),"8a8566",PI)
	resident("Aya","apprentice","sit",Vector3(24.6,10.05,42.5),"6f7288",0)
	resident("Cook Bao","worker","tea",Vector3(25,10.05,38),"9b7954",PI)
	resident("Keeper Tao","worker","sweep",Vector3(20,10.05,49),"8b8066",-.45)
	resident("Gardener Su","worker","tend",Vector3(24,10.05,46),"657d5d",PI/2)
	resident("Courier Ji","apprentice","idle",Vector3(-5,10.05,23),"536e85",0,[Vector3(-5,10.05,23),Vector3(-5,10.05,32)])
	resident("Water carrier Lian","worker","idle",Vector3(13,10.05,25),"8d6856",0,[Vector3(13,10.05,25),Vector3(13,10.05,31)])
	resident("Instructor Qiao","teacher","idle",Vector3(-89,14.05,-3),"66745e",PI/2)
	resident("Disciple Han","apprentice","train",Vector3(-94,14.05,-4),"708a83",-PI/2)
	resident("Disciple Rui","apprentice","train",Vector3(-98,14.05,-4),"88685b",-PI/2)
	resident("Herbalist An","worker","tend",Vector3(112,10.05,-23),"748663",-.4)
	resident("Scholar Pei","teacher","read",Vector3(-40,28.05,-111),"6c7887",.3)
	resident("Hall attendant","guard","idle",Vector3(2,24.05,-70),"576a6c",PI)
func nearest_extra() -> String:
	if not populated or world.overview or world.quest.ui_open: return ""
	# Core quest/lantern targets always win even when a resident is closer.
	if world.quest.nearest() != "": return ""
	var best := 2.5
	var id := ""
	for i in residents.size():
		var d: float = world.player.global_position.distance_to(residents[i].global_position)
		if d < best:
			id = str(i)
			best = d
	if id == "" and dusk.nearby_discovery(): return "bench"
	return id
func interact() -> void:
	var id := nearest_extra()
	if id == "": return
	if id == "bench":
		dusk.listen()
		return
	var n: CharacterBody3D = residents[int(id)]
	visits[n.display_name] = true
	n.talking = 20
	var lines := {
		"guard":"Welcome to Split-Cloud. Keep the middle stair clear; the court and your first lesson are ahead.",
		"teacher":"Practice has a rhythm: read carefully, try one change, then look at what actually happened.",
		"worker":"A sect lives by small duties. Someone sweeps the paths; someone keeps the water moving.",
		"apprentice":"We practise here before the evening bell. Lin's lanterns are a good place to practise patience, too."
	}
	var line: String = lines[n.role]
	if world.basin.active and n.role == "worker": line = "The basin is running again. We can fill our cups here instead of carrying water up the stair. Thank you."
	if world.basin.active and n.display_name == "Water carrier Lian": line = "Your inscription changed my afternoon. The public basin is part of our daily round again."
	world.quest.say(n.display_name.to_upper(),line,[["Return to the court",world.quest.close_ui,"ResidentClose"]])
	dusk.frame_conversation(n)
func reset() -> void:
	visits.clear()
	restored = false
	for n in residents: n.reset()
	world.player_figure.phase = 0
	world.player_figure.moving_speed = 0
	world.player_figure.last_position = world.player_figure.global_position
	if dusk: dusk.reset_presentation()
func _process(delta: float) -> void:
	if not populated: return
	dusk.tick(delta)
	if world.basin.active and not restored:
		restored = true
		var n: CharacterBody3D = residents[11]
		var water_route: Array[Vector3] = [n.position,Vector3(13,10.05,35),Vector3(13,10.05,40)]
		n.route = water_route
		n.destination = 1
		n.waiting = 0
		n.duty = "tea"
		n.restoring = true
	if not world.quest.ui_open:
		for n in residents: n.talking = 0
		near_id = nearest_extra()
		if near_id != "":
			world.quest.prompt.show()
			world.quest.prompt.text = "[E]  Pause at the listening bench" if near_id == "bench" else "[E]  "+residents[int(near_id)].display_name

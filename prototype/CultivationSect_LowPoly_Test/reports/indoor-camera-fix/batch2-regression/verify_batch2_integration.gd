extends SceneTree
## Independent tests of candidate permanent copies; no production controller edits.
const OUT := "res://reports/indoor-camera-fix/batch2-regression/"
const IDS := ["alchemy_pavilion", "medicine_hall"]
var stage: Node3D
var checks: Array = []
var movements: Array = []
var contacts: Array = []
var measurements: Dictionary = {}
var samples: Dictionary = {}
var asset_id := ""
var route_name := ""
var rendered := false
func _initialize() -> void: call_deferred("run")
func settle(n := 5) -> void:
	for i in n: await physics_frame
func check(label: String, ok: bool, detail: Variant = null) -> void:
	checks.append({"asset":asset_id,"check":label,"pass":ok,"detail":detail})
	if not ok: print("FAIL ",asset_id," ",label," ",detail)
func hit_names(q: PhysicsShapeQueryParameters3D) -> Array:
	var result: Array = []
	for hit in stage.get_world_3d().direct_space_state.intersect_shape(q,8):
		var owner: Node = hit.collider.shape_owner_get_owner(hit.collider.shape_find_owner(hit.shape))
		result.append(owner.get_meta("surface",owner.name))
	return result
func sample() -> void:
	var q := PhysicsShapeQueryParameters3D.new()
	var ball := SphereShape3D.new(); ball.radius = .16
	q.shape=ball; q.collision_mask=1|8; q.transform.origin=stage.player.camera.global_position
	var hits:=hit_names(q)
	if not hits.is_empty(): contacts.append({"asset":asset_id,"route":route_name,"third":stage.player.third_person,"kind":"camera","at":str(q.transform.origin),"hits":hits})
	var capsule:=CapsuleShape3D.new();capsule.height=1.35;capsule.radius=.24
	q.shape=capsule;q.collision_mask=8;q.transform.origin=stage.player.position+Vector3(0,1.175,0)
	hits=hit_names(q)
	if not hits.is_empty():contacts.append({"asset":asset_id,"route":route_name,"third":stage.player.third_person,"kind":"body","at":str(stage.player.position),"hits":hits})
	samples[asset_id]=samples.get(asset_id,0)+1
func walk(label: String, target: Vector3) -> void:
	route_name=label
	var count:=0
	while count<500:
		var d: Vector3=target-stage.player.position;d.y=0
		if d.length()<.11:break
		stage.player.drive=d.normalized();stage.player.yaw=atan2(-d.x,-d.z)
		await physics_frame
		if count%8==0:sample()
		count+=1
	stage.player.drive=Vector3.ZERO;await settle()
	var actual: Vector3=stage.player.position
	var result: Dictionary={"asset":asset_id,"third":stage.player.third_person,"route":label,"target":str(target),"actual":str(actual),"frames":count}
	movements.append(result)
	check(label,Vector2(actual.x-target.x,actual.z-target.z).length()<.22 and absf(actual.y-target.y)<.18 and stage.player.is_on_floor(),result)
func reset(at: Vector3, third: bool) -> void:
	stage.player.position=at;stage.player.velocity=Vector3.ZERO;stage.player.drive=Vector3.ZERO
	stage.player.third_person=third;stage.player.yaw=0;stage.player.pitch=0
	stage.player.set_physics_process(true);stage.player.camera.make_current();await settle()
func block(label: String, at: Vector3, direction: Vector3, third: bool, axis: String, low: float, high: float) -> void:
	await reset(at,third);route_name=label
	stage.player.drive=direction;stage.player.yaw=atan2(-direction.x,-direction.z)
	for i in 100:
		await physics_frame
		if i%8==0:sample()
	stage.player.drive=Vector3.ZERO;await settle()
	var value: float=stage.player.position[axis]
	check(label,value>low and value<high,str(stage.player.position))
func shot(label: String, exterior:=false) -> void:
	if not rendered:return
	stage.player.set_physics_process(false)
	if exterior:stage.review_camera.make_current()
	else:stage.player.camera.make_current()
	for i in 4:await RenderingServer.frame_post_draw
	check("image "+label,root.get_texture().get_image().save_png(OUT+asset_id+"-"+label+".png")==OK)
	stage.player.set_physics_process(true);stage.player.camera.make_current()
func ray(at: Vector3, direction: Vector3, length: float, mask: int) -> float:
	var q:=PhysicsRayQueryParameters3D.create(at,at+direction*length,mask)
	var hit: Dictionary=stage.get_world_3d().direct_space_state.intersect_ray(q)
	return at.distance_to(hit.position) if hit else length
func measure() -> void:
	var a: Node3D=stage.asset
	check("root identity / metre scale",a.transform==Transform3D.IDENTITY)
	check("unchanged inspection player",stage.player.get_script().resource_path=="res://scripts/training_inspection_player.gd")
	check("no asset script/lights/cameras",a.get_script()==null and a.find_children("*","Light3D",true,false).is_empty() and a.find_children("*","Camera3D",true,false).is_empty())
	var shapes: Array=a.find_children("*","CollisionShape3D",true,false)
	check("active collision layers and shapes",shapes.all(func(s):return not s.disabled and s.shape!=null) and a.get_node("Collision").collision_layer==1 and a.get_node("Collision").collision_mask==2)
	var clear: Dictionary={}
	for mask: int in [1,8]:
		var m: Dictionary={}
		if asset_id==IDS[0]:
			m.door_width=ray(Vector3(0,1.9,5.174),Vector3.LEFT,3,mask)+ray(Vector3(0,1.9,5.174),Vector3.RIGHT,3,mask)
			m.door_headroom=ray(Vector3(0,.95,5.174),Vector3.UP,6,mask)+.05
			m.porch_plaque_headroom=ray(Vector3(0,.95,6.62),Vector3.UP,6,mask)+.05
		else:
			m.ground_entrance_width=ray(Vector3(0,1.45,4.5),Vector3.LEFT,3,mask)+ray(Vector3(0,1.45,4.5),Vector3.RIGHT,3,mask)
			m.ground_entrance_headroom=ray(Vector3(0,.5,4.5),Vector3.UP,6,mask)+.05
			m.balcony_door_width=ray(Vector3(0,5.2,4.5),Vector3.LEFT,3,mask)+ray(Vector3(0,5.2,4.5),Vector3.RIGHT,3,mask)
			m.balcony_door_headroom=ray(Vector3(0,4.25,4.5),Vector3.UP,6,mask)+.05
		for key: String in m:check(("collision " if mask==1 else "visible ")+key,float(m[key])>=(2.1 if "headroom" in key else .9),m[key])
		clear["collision" if mask==1 else "visible"]=m
	measurements[asset_id]={"clearances_m":clear,"collision_shapes":shapes.size()}
func routes(third: bool) -> void:
	var mode: String="TPP " if third else "FPP "
	if asset_id==IDS[0]:
		await reset(Vector3(0,.05,12),third)
		for w: Array in [["stair and porch",Vector3(0,.9,6.7)],["door into furnace room",Vector3(0,.9,3.5)],
			["east aisle",Vector3(3.2,.9,2.6)],["east furnace side",Vector3(3.5,.9,0)],
			["rear east",Vector3(2.7,.9,-2.7)],["rear aisle",Vector3(0,.9,-3.5)],
			["rear west",Vector3(-2.7,.9,-2.7)],["west furnace side",Vector3(-3.5,.9,0)],
			["return rear west",Vector3(-2.7,.9,-2.7)],["return rear",Vector3(0,.9,-3.5)],
			["return east",Vector3(3.5,.9,0)],["return east front",Vector3(3.2,.9,2.6)],
			["return central aisle",Vector3(0,.9,3.5)],["door exit",Vector3(0,.9,6.7)]]:
			await walk(mode+w[0],w[1])
			if w[0] in ["door into furnace room","rear aisle"]:await shot(("tpp-" if third else "fpp-")+w[0].replace(" ","-"))
		# Colonnade circuit follows face centres; chords clear wall-corner posts.
		for i in range(1,9):
			var angle:=i*TAU/8
			await walk(mode+"outer veranda sector "+str(i),Vector3(6.7*sin(angle),.9,6.7*cos(angle)))
		await walk(mode+"descend front stair",Vector3(0,.03,12))
		await block(mode+"furnace dais blocks",Vector3(0,.95,3.5),Vector3.FORWARD,third,"z",2.0,3.0)
		await block(mode+"solid front wall blocks",Vector3(1.9,.95,6.3),Vector3.FORWARD,third,"z",5.3,6.3)
	else:
		await reset(Vector3(0,.05,10),third)
		for w: Array in [["front stair",Vector3(0,.45,5.5)],["central shop entrance",Vector3(0,.45,2.8)],
			["west shop aisle",Vector3(-4.8,.45,1.5)],["stair foot approach",Vector3(-5.8,.45,3.8)],
			["stair foot",Vector3(-7.15,.45,3.8)],["climb loft stair",Vector3(-7.15,4.2,-2.8)],
			["loft landing",Vector3(-5.7,4.2,-2.8)],["loft west aisle",Vector3(-5.7,4.2,0)],
			["drying loft front aisle",Vector3(0,4.2,0)],["balcony door approach",Vector3(0,4.2,3)],
			["balcony entry",Vector3(0,4.2,5.05)],["balcony east",Vector3(3,4.2,5.05)],
			["balcony west",Vector3(-3,4.2,5.05)],["balcony centre",Vector3(0,4.2,5.05)],
			["balcony exit",Vector3(0,4.2,3)],["return loft front",Vector3(0,4.2,0)],
			["return loft west",Vector3(-5.7,4.2,0)],["return loft landing",Vector3(-5.7,4.2,-2.8)],
			["stair top",Vector3(-7.15,4.2,-2.8)],["descend interior stair",Vector3(-7.15,.45,3.8)],
			["return shop front",Vector3(0,.45,3.8)],["return shop exit",Vector3(0,.45,5.5)],
			["descend front stair",Vector3(0,.03,10)]]:
			await walk(mode+w[0],w[1])
			if w[0] in ["central shop entrance","drying loft front aisle","balcony entry"]:await shot(("tpp-" if third else "fpp-")+w[0].replace(" ","-"))
		await block(mode+"serving counter blocks",Vector3(-3.2,.5,5.6),Vector3.FORWARD,third,"z",4.6,5.6)
		await block(mode+"balcony rail holds",Vector3(0,4.25,5.05),Vector3.BACK,third,"z",5.0,5.6)
func run() -> void:
	rendered="--rendered" in OS.get_cmdline_user_args();root.size=Vector2i(1280,720)
	for aid: String in IDS:
		asset_id=aid
		stage=load("res://scenes/review/"+aid+"_walkthrough.tscn").instantiate();root.add_child(stage)
		stage.player.automated=true
		var visual:=StaticBody3D.new();visual.collision_layer=8;visual.collision_mask=0;stage.add_child(visual)
		for mi: MeshInstance3D in stage.asset.find_children("*","MeshInstance3D",true,false):
			var shape:=CollisionShape3D.new();shape.shape=mi.mesh.create_trimesh_shape();shape.transform=mi.global_transform;shape.set_meta("surface",mi.name);visual.add_child(shape)
		await settle();measure();await shot("three-quarter",true)
		for third: bool in [false,true]:await routes(third)
		stage.player.set_physics_process(false)
		var hits: Array=contacts.filter(func(c):return c.asset==asset_id)
		check("sampled camera/body clearance",hits.is_empty(),hits)
		stage.queue_free();await process_frame
	var failed:=checks.filter(func(c):return not c.pass).size()
	var per_asset: Dictionary={}
	for aid: String in IDS:
		var group: Array=checks.filter(func(c):return c.asset==aid)
		var n:=group.filter(func(c):return not c.pass).size()
		per_asset[aid]={"passed":group.size()-n,"failed":n}
	FileAccess.open(OUT+("rendered-results.json" if rendered else "headless-results.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"per_asset":per_asset,"sampled_pairs":samples,"contacts":contacts,"measurements":measurements,"movements":movements},"  "))
	print(checks.size()-failed," PASS / ",failed," FAIL; ",per_asset,"; samples ",samples)
	quit(1 if failed else 0)

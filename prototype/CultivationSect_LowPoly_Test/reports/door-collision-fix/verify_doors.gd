extends SceneTree
## Before/after physics against canonical scenes and read-only visual copies.
const OUT := "res://reports/door-collision-fix/"
var checks: Array = []
var doors: Array = []
var rows: Array = []
var movements: Array = []
var contacts: Array = []
var aid := ""
var before := false
var rendered := false
var stage: Node3D
var player: CharacterBody3D
var samples := 0

func _initialize() -> void: call_deferred("run")
func frames(n := 5) -> void:
	for i in n: await physics_frame
func v(a: Array) -> Vector3: return Vector3(a[0],a[1],a[2])
func check(label: String, passed: bool, detail: Variant = null) -> void:
	checks.append({"asset":aid,"check":label,"pass":passed,"detail":detail})
	if not passed: print("FAIL ",aid," ",label," ",detail)

func ray(at: Vector3, to: Vector3, mask: int) -> Dictionary:
	return stage.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(at,to,mask))

func hits(shape: Shape3D, at: Vector3, mask: int) -> Array:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape=shape;query.transform.origin=at;query.collision_mask=mask;query.exclude=[player.get_rid()]
	var result: Array = []
	for hit in stage.get_world_3d().direct_space_state.intersect_shape(query,6):
		var owner: Node=hit.collider.shape_owner_get_owner(hit.collider.shape_find_owner(hit.shape))
		result.append(str(owner.get_path()))
	return result

func sample(label: String) -> void:
	var ball := SphereShape3D.new();ball.radius=.18
	var solid_hits := hits(ball,player.camera.global_position,1)
	ball.radius=.16
	var visual_hits := hits(ball,player.camera.global_position,8)
	var body := CapsuleShape3D.new();body.radius=.24;body.height=1.35
	var body_hits := hits(body,player.global_position+Vector3(0,1.175,0),8)
	if not solid_hits.is_empty() or not visual_hits.is_empty() or not body_hits.is_empty():
		contacts.append({"asset":aid,"test":label,"third":player.third_person,"player":str(player.position),"camera":str(player.camera.global_position),"solid_camera":solid_hits,"visible_camera":visual_hits,"visible_body":body_hits})
	samples+=1

func probe(entry: Dictionary) -> void:
	var u := v(entry.axis_u)
	var n := v(entry.axis_n)
	var visible_count := 0
	var solid_count := 0
	var max_gap := 0.0
	var detail: Array = []
	for leaf: Dictionary in entry.leaves:
		var centre := v(leaf.position)
		var length: float = entry.width/2-.02
		for height: float in [.15,.22,.5,.8,.9]:
			for depth: float in [-.35,0,.35]:
				var at := centre+n*length*depth
				at.y=entry.floor+entry.height*height
				var visible := ray(at-u*.12,at+u*.12,8)
				var solid := ray(at-u*.12,at+u*.12,1)
				if not visible.is_empty():visible_count+=1
				if not solid.is_empty():solid_count+=1
				var gap := -1.0
				if not visible.is_empty() and not solid.is_empty():
					gap=visible.position.distance_to(solid.position);max_gap=maxf(max_gap,gap)
				detail.append({"side":leaf.side,"height_fraction":height,"depth_fraction":depth,"visual_hit":not visible.is_empty(),"solid_hit":not solid.is_empty(),"surface_gap_m":gap})
	var row: Dictionary={"asset":aid,"door":entry.name,"already_corrected":entry.already_corrected,"visible_ray_hits":visible_count,"solid_ray_hits":solid_count,"max_surface_gap_m":max_gap,"samples":detail}
	check(entry.name+" actual visible leaves at authored coordinates",visible_count==30,row)
	check(entry.name+(" initial collision condition" if before else " leaf collision coverage"),solid_count==(30 if not before or entry.already_corrected else 0),row)
	if not before:
		check(entry.name+" collision surfaces match leaf/crossbar envelope",max_gap<.025,row)
		var origin: Vector3 = Vector3(entry.origin[0],entry.floor+entry.height*.5,entry.origin[1])+u*entry.u
		var lw: float = entry.width/2-.02
		origin-=n*(entry.thickness/2+lw/2)
		var left := ray(origin,origin-u*entry.width,1)
		var right := ray(origin,origin+u*entry.width,1)
		var width: float = left.position.distance_to(right.position) if not left.is_empty() and not right.is_empty() else -1.0
		row["measured_leaf_clear_width_m"]=width
		check(entry.name+" player opening retained",width>=.9 and absf(width-entry.minimum_clear_width)<.025,width)
	rows.append(row)

func reset(at: Vector3, third: bool) -> void:
	player.position=at;player.velocity=Vector3.ZERO;player.drive=Vector3.ZERO
	player.third_person=third;player.yaw=0;player.pitch=0;player.update_camera()
	player.set_physics_process(true);player.camera.make_current()
	await frames(6)

func walk(label: String, target: Vector3) -> void:
	var count := 0
	while count<180:
		var d:=target-player.position;d.y=0
		if d.length()<.09:break
		player.drive=d.normalized();player.yaw=atan2(-d.x,-d.z)
		await physics_frame
		if count%4==0:sample(label)
		count+=1
	player.drive=Vector3.ZERO;await frames()
	var reached:=Vector2(player.position.x-target.x,player.position.z-target.z).length()<.18 and absf(player.position.y-target.y)<.16 and player.is_on_floor()
	movements.append({"asset":aid,"door":label,"third":player.third_person,"target":str(target),"actual":str(player.position),"reached":reached})
	check(label+" traversal "+("TPP" if player.third_person else "FPP"),reached,str(player.position))

func passage(entry: Dictionary) -> void:
	var u:=v(entry.axis_u);var n:=v(entry.axis_n)
	var origin: Vector3=Vector3(entry.origin[0],entry.floor,entry.origin[1])+u*entry.u
	var outside: Vector3=origin+n*.35
	var inside: Vector3=origin-n*(entry.thickness/2+entry.width/2-.02+.35)
	for third: bool in [false,true]:
		await reset(outside+Vector3.UP*.04,third)
		await walk(entry.name+" enter",inside)
		if rendered and entry.name in ["MainEntrance","BalconyEntrance"]:
			for i in 3:await RenderingServer.frame_post_draw
			check("capture "+entry.name,root.get_texture().get_image().save_png(OUT+aid+"-"+entry.name+("-TPP.png" if third else "-FPP.png"))==OK)
		await walk(entry.name+" leave",outside)
		for leaf: Dictionary in entry.leaves:
			var centre:=v(leaf.position)
			var at: Vector3=centre-u*leaf.side*.50;at.y=entry.floor+.04
			await reset(at,third)
			player.drive=u*leaf.side;player.yaw=atan2(-player.drive.x,-player.drive.z)
			for i in 35:
				await physics_frame
				if i%5==0:sample(entry.name+" leaf blocking")
			player.drive=Vector3.ZERO;await frames()
			var distance: float=(player.position-centre).dot(u)*leaf.side
			check(entry.name+" leaf blocks real player "+str(leaf.side)+(" TPP" if third else " FPP"),distance<-.29 and player.is_on_floor(),distance)
	player.set_physics_process(false)

func run() -> void:
	before="--before" in OS.get_cmdline_user_args();rendered="--rendered" in OS.get_cmdline_user_args()
	doors=JSON.parse_string(FileAccess.get_file_as_string(OUT+"door-manifest.json"));root.size=Vector2i(1280,720)
	var catalog: Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/gallery/catalog.json"))
	var ids: Array=[]
	for d: Dictionary in doors:
		if d.asset not in ids:ids.append(d.asset)
	for asset: String in ids:
		aid=asset
		var entry: Dictionary=catalog.filter(func(e):return e.id==aid)[0]
		stage=load(entry.walkthrough).instantiate();root.add_child(stage)
		player=stage.player;player.automated=true;player.set_process_unhandled_input(false);player.set_physics_process(false)
		var facility: Node3D
		if aid=="mission_hall":facility=stage.get_node("MissionHall")
		elif aid=="exchange_hall":facility=stage.get_node("ExchangeHall")
		elif aid=="medicine_hall":facility=stage.asset
		else:facility=stage.facility
		var visual:=StaticBody3D.new();visual.collision_layer=8;visual.collision_mask=0;stage.add_child(visual)
		for mesh: MeshInstance3D in facility.find_children("*","MeshInstance3D",true,false):
			var shape:=CollisionShape3D.new();shape.shape=mesh.mesh.create_trimesh_shape();shape.transform=mesh.global_transform;visual.add_child(shape)
		await frames()
		for d: Dictionary in doors.filter(func(e):return e.asset==aid):
			probe(d)
			if not before:await passage(d)
		stage.free();await process_frame
	if not before:check("sampled player and camera clearance",contacts.is_empty(),contacts.slice(0,16))
	var failed:=checks.filter(func(c):return not c.pass).size()
	var file:=OUT+("before-probes.json" if before else ("after-rendered.json" if rendered else "after-headless.json"))
	FileAccess.open(file,FileAccess.WRITE).store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"doors":rows,"movements":movements,"contacts":contacts,"sampled_camera_body_pairs":samples},"  "))
	print(checks.size()-failed," PASS / ",failed," FAIL; ",rows.size()," openings; ",samples," camera/body pairs")
	quit(1 if failed else 0)

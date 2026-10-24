extends SceneTree
## Diagnostic: canonical fixture, layer-8 copies of actual near visual meshes.
const OUT := "res://reports/main-hall-collision-fix/"
var checks: Array = []
var probes: Array = []
var movements: Array = []
var contacts: Array = []
var samples := 0
var before := false
var rendered := false
var camera_only := false
var old_collision := false
var stage: Node3D
var player: CharacterBody3D
var plan: Dictionary

func _initialize() -> void: call_deferred("run")
func frames(n := 5) -> void:
	for i in n: await physics_frame
func vec(a: Array) -> Vector3: return Vector3(a[0],a[1],a[2])
func arr(v: Vector3) -> Array: return [v.x,v.y,v.z]
func check(label: String, ok: bool, detail: Variant = null) -> void:
	checks.append({"check":label,"pass":ok,"detail":detail})
	if not ok: print("FAIL ",label," ",str(detail).left(400)," (full details in JSON)")
func ray(at: Vector3, to: Vector3, mask: int) -> Dictionary:
	return stage.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(at,to,mask))
func ray_record(hit: Dictionary) -> Dictionary:
	if hit.is_empty(): return {"hit":false}
	var owner: Node = hit.collider.shape_owner_get_owner(hit.collider.shape_find_owner(hit.shape))
	return {"hit":true,"position":arr(hit.position),"shape":str(owner.name)}

func probe_alignment() -> void:
	for row: Dictionary in plan.changes:
		var old := vec(row.old_position)
		var heights: Array = [2.4,3.5,5.5] if row.kind=="column" else [1.68,1.82,2.0]
		var detail: Array = []
		if row.action=="remove_unmatched":
			var clear := true
			var expected_solid := true
			for y: float in heights:
				var a := Vector3(old.x,y,-10.8)
				var b := Vector3(old.x,y,-9.0)
				var visible := ray(a,b,8)
				var solid := ray(a,b,1)
				clear = clear and visible.is_empty()
				expected_solid = expected_solid and (not solid.is_empty() if before else solid.is_empty())
				detail.append({"height":y,"visible":ray_record(visible),"solid":ray_record(solid)})
			check("unmatched %s x=%.2f has no visible counterpart"%[row.kind,old.x],clear)
			check("unmatched %s x=%.2f %s"%[row.kind,old.x,"confirmed ghost" if before else "ghost removed"],expected_solid)
		else:
			var centre := vec(row.new_position)
			var max_gap := 0.0
			var complete := true
			for y: float in heights:
				for side: float in [-1.0,1.0]:
					# Keep both endpoints outside the inner wall at z=-8.4.
					var a := Vector3(centre.x,y,centre.z+(-1.15 if side<0 else .65))
					var b := Vector3(centre.x,y,centre.z+(.65 if side<0 else -1.15))
					var visible := ray(a,b,8)
					var solid := ray(a,b,1)
					complete = complete and not visible.is_empty() and not solid.is_empty()
					var gap: float = visible.position.distance_to(solid.position) if not visible.is_empty() and not solid.is_empty() else 999.0
					max_gap=maxf(max_gap,gap)
					detail.append({"height":y,"side":side,"visible":ray_record(visible),"solid":ray_record(solid),"surface_gap_m":gap})
			check("%s x=%.2f both sides have measured surfaces"%[row.kind,centre.x],complete)
			check("%s x=%.2f %s"%[row.kind,centre.x,"offset confirmed" if before else "aligned"],max_gap>.1 and max_gap<.7 if before else max_gap<.025,max_gap)
		probes.append({"old_index":row.old_index,"kind":row.kind,"action":row.action,"old_position":row.old_position,"new_position":row.new_position,"rays":detail})

func overlaps(shape: Shape3D, at: Vector3, mask: int) -> Array:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape=shape;q.transform.origin=at;q.collision_mask=mask;q.exclude=[player.get_rid()]
	var result: Array = []
	for hit in stage.get_world_3d().direct_space_state.intersect_shape(q,8):
		var owner: Node = hit.collider.shape_owner_get_owner(hit.collider.shape_find_owner(hit.shape))
		result.append(str(owner.name))
	return result
func sample(label: String) -> void:
	var ball := SphereShape3D.new();ball.radius=.18
	var solid := overlaps(ball,player.camera.global_position,1)
	ball.radius=.16
	var visible := overlaps(ball,player.camera.global_position,8)
	var body := CapsuleShape3D.new();body.radius=.24;body.height=1.35
	var body_hits := overlaps(body,player.position+Vector3(0,1.175,0),8)
	if not solid.is_empty() or not visible.is_empty() or not body_hits.is_empty():
		contacts.append({"label":label,"third":player.third_person,"yaw":player.yaw,"pitch":player.pitch,"player":arr(player.position),"camera":arr(player.camera.global_position),"solid_camera":solid,"visible_camera":visible,"visible_body":body_hits})
	samples+=1
func reset(at: Vector3, third: bool) -> void:
	player.set_physics_process(false)
	player.position=at;player.velocity=Vector3.ZERO;player.drive=Vector3.ZERO
	player.third_person=third;player.yaw=0;player.pitch=0;player.update_camera()
	player.camera.make_current();player.set_physics_process(true)
	await frames(6)
func walk(label: String, target: Vector3, must_reach := true, limit := 180) -> void:
	var start := player.position
	var count := 0
	var column_contacts: Array = []
	while count<limit:
		var direction := target-player.position;direction.y=0
		if direction.length()<.07: break
		player.drive=direction.normalized();player.yaw=atan2(-direction.x,-direction.z)
		await physics_frame
		for i in player.get_slide_collision_count():
			var collision: KinematicCollision3D=player.get_slide_collision(i)
			var collider: CollisionObject3D=collision.get_collider()
			var owner: Node=collider.shape_owner_get_owner(collider.shape_find_owner(collision.get_collider_shape_index()))
			if "veranda column" in str(owner.name).to_lower() and not arr(owner.position) in column_contacts:
				column_contacts.append(arr(owner.position))
		if count%3==0: sample(label)
		count+=1
	player.drive=Vector3.ZERO;await frames()
	var error := Vector2(player.position.x-target.x,player.position.z-target.z).length()
	var reached := error<.16 and absf(player.position.y-target.y)<.12 and player.is_on_floor()
	movements.append({"label":label,"third":player.third_person,"start":arr(start),"target":arr(target),"end":arr(player.position),"frames":count,"reached":reached,"target_error":error,"column_contacts":column_contacts})
	check(label+(" reached" if must_reach else " blocked"),reached if must_reach else not reached and error>.3 and player.is_on_floor(),movements[-1])
func capture(label: String) -> void:
	if not rendered: return
	for i in 3: await RenderingServer.frame_post_draw
	check("capture "+label,root.get_texture().get_image().save_png(OUT+("before-" if before else "after-")+label+".png")==OK)

func movement_tests() -> void:
	for third: bool in [false,true]:
		var mode := "TPP" if third else "FPP"
		await reset(Vector3(0,.05,18.8),third)
		await walk(mode+" unchanged front stair",Vector3(0,1.52,12.8),true,180)
		await walk(mode+" unchanged main doorway inward",Vector3(0,1.52,4.8),true,220)
		await walk(mode+" unchanged main doorway and stair outward",Vector3(0,0,18.8),true,300)
		# Both directions along the outer veranda, without touching phantom columns.
		await reset(Vector3(-19,1.53,-11.0),third)
		await walk(mode+" outer veranda east",Vector3(19,1.52,-11.0),true,660)
		await walk(mode+" outer veranda west",Vector3(-19,1.52,-11.0),true,660)
		# Each actual column/drum must stop the real player from the outer side.
		for c: Dictionary in plan.visible_components.column:
			var x: float=c.centre[0]
			await reset(Vector3(x,1.53,-11.0),third)
			await walk(mode+" column %.2f outer approach"%x,Vector3(x,1.52,-9.6),false,32)
			check(mode+" column %.2f contact matches drum edge"%x,player.position.z< -10.20 and player.position.z> -10.40,arr(player.position))
			await reset(Vector3(x+.9,1.53,-8.95),third)
			await walk(mode+" column %.2f inboard approach"%x,Vector3(x,1.52,-9.6),false,32)
			var contacts_here: Array=movements[-1].column_contacts
			check(mode+" column %.2f inboard hits intended column/drum"%x,contacts_here.any(func(at):return absf(at[0]-x)<.001 and absf(at[2]+9.6)<.001),contacts_here)
		# Walk through the two places where unmatched old column/drum pairs stood.
		for x: float in [-3.65,3.65]:
			await reset(Vector3(x,1.53,-11.0),third)
			await walk(mode+" former ghost %.2f inward"%x,Vector3(x,1.52,-9.1))
			await walk(mode+" former ghost %.2f outward"%x,Vector3(x,1.52,-11.0))
		# A real gap between each adjacent visible pair remains traversable.
		var columns: Array=plan.visible_components.column
		for i in range(columns.size()-1):
			var x: float=(columns[i].centre[0]+columns[i+1].centre[0])*.5
			await reset(Vector3(x,1.53,-11.0),third)
			await walk(mode+" gap %d inward"%i,Vector3(x,1.52,-9.1))
			await walk(mode+" gap %d outward"%i,Vector3(x,1.52,-11.0))
		await reset(Vector3(7.2,1.53,-10.9),third)
		player.yaw=PI;player.update_camera()
		await capture(mode+"-rear-column")
	await diagnostic_capture()
	await camera_tests()

func diagnostic_capture() -> void:
	if not rendered:return
	# Orange lines show actual rear collision in this diagnostic viewport only.
	var lines := ImmediateMesh.new();lines.surface_begin(Mesh.PRIMITIVE_LINES)
	for r: Dictionary in stage.hall.specification.solid_shapes:
		if r.name not in ["Substantial veranda column","Veranda column stone drum"] or r.position[2]> -9:continue
		var at := vec(r.position)
		if r.type=="box":
			var size := vec(r.size)*.5
			for i in 8:
				for axis in [1,2,4]:
					if i&axis:continue
					for j: int in [i,i|axis]:
						lines.surface_add_vertex(at+Vector3(size.x*(1 if j&1 else -1),size.y*(1 if j&2 else -1),size.z*(1 if j&4 else -1)))
		else:
			for i in 16:
				for y: float in [-r.height*.5,r.height*.5]:
					for j: int in [i,i+1]:lines.surface_add_vertex(at+Vector3(cos(j*TAU/16)*r.radius,y,sin(j*TAU/16)*r.radius))
				for y: float in [-r.height*.5,r.height*.5]:lines.surface_add_vertex(at+Vector3(cos(i*TAU/16)*r.radius,y,sin(i*TAU/16)*r.radius))
	lines.surface_end()
	var overlay := MeshInstance3D.new();overlay.mesh=lines
	var material := StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.albedo_color=Color("ff7733")
	overlay.material_override=material;stage.add_child(overlay)
	stage.view_camera.position=Vector3(22,12,-26);stage.view_camera.look_at(Vector3(0,3.7,-9.6));stage.view_camera.make_current()
	await capture("rear-overview-collision-outline")
	stage.view_camera.position=Vector3(10.8,5.2,-14.2);stage.view_camera.look_at(Vector3(7.2,3.0,-9.6))
	await capture("rear-closeup-collision-outline")
	overlay.free()

func camera_tests() -> void:
	# Identical sweep can be run against the frozen old shapes, in memory only.
	for x: float in [-18,-14.4,-10.8,-7.2,0,7.2,10.8,14.4,18]:
		for z: float in [-10.5,-9.1]:
			# At z=-9.1 a column is too close to stand at its centre; offset sideways.
			await reset(Vector3(x+(.9 if z> -10 else 0.0),1.53,z),true)
			player.set_physics_process(false)
			for pitch: float in [-.35,0.0,.35]:
				for i in 24:
					player.yaw=TAU*i/24.0;player.pitch=pitch;player.update_camera(1.0/60)
					sample("veranda sweep")
	check("sampled authored-camera clearance",contacts.all(func(c):return c.solid_camera.is_empty()),contacts.slice(0,20))
	check("sampled visible player-body clearance",contacts.all(func(c):return c.visible_body.is_empty()),contacts.slice(0,20))
	var targeted: Array=[]
	for c: Dictionary in contacts:
		for mesh_name: String in c.visible_camera:
			if "Timber" in mesh_name or "Coping" in mesh_name:targeted.append(c)
	check("sampled visible column/drum camera clearance",targeted.is_empty(),targeted.slice(0,20))
	# Retain this broader failure if unrelated decorative trim overlaps persist.
	check("all visible camera samples clear",contacts.all(func(c):return c.visible_camera.is_empty()),contacts.slice(0,20))

func run() -> void:
	before="--before" in OS.get_cmdline_user_args();rendered="--rendered" in OS.get_cmdline_user_args()
	camera_only="--camera-only" in OS.get_cmdline_user_args();old_collision="--old-collision" in OS.get_cmdline_user_args()
	plan=JSON.parse_string(FileAccess.get_file_as_string(OUT+"alignment-plan.json"))
	stage=Node3D.new();stage.set_script(load("res://scripts/hall_experiment.gd"));stage.automated=true;root.add_child(stage)
	player=stage.player;player.set_physics_process(false)
	if old_collision:
		var frozen: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OUT+"before/main_sect_hall.json.txt"))
		var solid: StaticBody3D=stage.hall.get_node("AuthoredSimpleCollision")
		for child: Node in solid.get_children():
			if child.name!="RoofAndCameraClearance":child.free()
		load("res://scripts/training_collision.gd").add_shapes(solid,frozen.solid_shapes)
		stage.hall.specification=frozen
	for door in stage.hall.doors:door.set_open_immediate(true)
	var visual := StaticBody3D.new();visual.collision_layer=8;visual.collision_mask=0;stage.add_child(visual)
	for mesh: MeshInstance3D in stage.hall.static_model.find_children("*","MeshInstance3D",true,false):
		var shape := CollisionShape3D.new();shape.name=mesh.name;shape.shape=mesh.mesh.create_trimesh_shape();shape.transform=mesh.global_transform;visual.add_child(shape)
	await frames()
	check("permanent authored shape count",stage.hall.specification.solid_shapes.size()==(195 if before or old_collision else 191))
	if not camera_only:probe_alignment()
	if camera_only:await camera_tests()
	elif not before:await movement_tests()
	else:
		await reset(Vector3(7.2,1.53,-10.9),true)
		player.yaw=PI;player.update_camera()
		await capture("TPP-facing-column")
		await diagnostic_capture()
	var failed := checks.filter(func(c):return not c.pass).size()
	var name := ("before-" if before else "after-")+("rendered" if rendered else "headless")
	if camera_only:name="camera-"+("old-" if old_collision else "current-")+("rendered" if rendered else "headless")
	FileAccess.open(OUT+name+".json",FileAccess.WRITE).store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"probes":probes,"movements":movements,"sampled_camera_body_pairs":samples,"contacts":contacts,"confirmed_columns_and_drums":before and failed==0,"limits":"Automated imported-mesh/physics/player tests, not human playtesting."},"  "))
	print(checks.size()-failed," PASS / ",failed," FAIL; ",samples," camera/body samples")
	quit(1 if failed else 0)

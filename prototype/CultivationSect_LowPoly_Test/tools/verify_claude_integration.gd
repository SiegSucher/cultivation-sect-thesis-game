extends SceneTree
## Canonical-copy verification using the unchanged working inspection player.
const OUT := "res://reports/codex-claude-integration/"
const IDS := ["disciple_residence","elder_residence","dining_hall_kitchen","spirit_herb_garden"]
var stage: Node3D
var checks: Array=[]
var movement: Array=[]
var captures: Array=[]
var geometry: Array=[]
var camera_failures: Array=[]
var visual_failures: Array=[]
var sampled_volumes:=0
var visual_audit: StaticBody3D
var capture:=false
func _initialize() -> void: call_deferred("run")
func frames(n: int) -> void:
	for i in range(n):await process_frame
func settle(n:=5) -> void:
	for i in range(n):await physics_frame
func check(label: String, ok: bool, detail: Variant=null) -> void:
	checks.append({"check":label,"pass":ok,"detail":detail})
	if not ok:push_warning(label+" "+str(detail))
func reset(at: Vector3, third: bool) -> void:
	stage.player.position=at; stage.player.velocity=Vector3.ZERO; stage.player.drive=Vector3.ZERO
	stage.player.third_person=third; stage.player.yaw=0; stage.player.pitch=0
	stage.set_walking(true); await settle()
func sample_volumes() -> void:
	var ball:=SphereShape3D.new();ball.radius=.17
	var q:=PhysicsShapeQueryParameters3D.new();q.shape=ball;q.collision_mask=1
	q.transform.origin=stage.player.camera.global_position
	var space: PhysicsDirectSpaceState3D=stage.get_world_3d().direct_space_state
	if not space.intersect_shape(q,1).is_empty():camera_failures.append({"asset":stage.asset_id,"third":stage.player.third_person,"position":str(q.transform.origin)})
	var body:=CapsuleShape3D.new();body.height=1.5;body.radius=.28
	q=PhysicsShapeQueryParameters3D.new();q.shape=body;q.collision_mask=16
	q.transform.origin=stage.player.global_position+Vector3(0,1.08,0)
	if not space.intersect_shape(q,1).is_empty():visual_failures.append({"asset":stage.asset_id,"position":str(stage.player.position)})
	sampled_volumes+=1
func walk(label: String, target: Vector3, max_frames:=700) -> void:
	var p: CharacterBody3D=stage.player
	var n:=0
	while n<max_frames:
		var d: Vector3=target-p.position;d.y=0
		if d.length()<.12:break
		p.drive=d.normalized()
		p.yaw=atan2(-d.x,-d.z)
		await physics_frame
		if n%12==0:sample_volumes()
		n+=1
	p.drive=Vector3.ZERO;await settle()
	var remaining:=Vector2(p.position.x-target.x,p.position.z-target.z).length()
	var detail: Dictionary={"asset":stage.asset_id,"third":p.third_person,"target":str(target),"actual":str(p.position),"frames":n,"horizontal_error_m":remaining}
	movement.append(detail)
	check(label,remaining<.22 and absf(p.position.y-target.y)<.18 and p.is_on_floor(),detail)
func add_visual_audit() -> void:
	visual_audit=StaticBody3D.new();visual_audit.name="ReadOnlyVisualVolumeAudit"
	visual_audit.collision_layer=16;visual_audit.collision_mask=0;stage.add_child(visual_audit)
	for mi: MeshInstance3D in stage.facility.find_children("*","MeshInstance3D",true,false):
		var shape:=CollisionShape3D.new();shape.shape=mi.mesh.create_trimesh_shape();shape.transform=mi.global_transform
		visual_audit.add_child(shape)
	await settle()
func measure() -> void:
	var box:=AABB();var first:=true;var triangles:=0;var surfaces:=0
	var materials: Array=[];var invalid: Array=[]
	for mi: MeshInstance3D in stage.facility.find_children("*","MeshInstance3D",true,false):
		var bounds: AABB=mi.global_transform*mi.get_aabb()
		box=bounds if first else box.merge(bounds);first=false
		for i in range(mi.mesh.get_surface_count()):
			var a: Array=mi.mesh.surface_get_arrays(i)
			triangles+=a[Mesh.ARRAY_INDEX].size()/3 if a[Mesh.ARRAY_INDEX]!=null else a[Mesh.ARRAY_VERTEX].size()/3
			surfaces+=1
			var m: Material=mi.get_active_material(i)
			if not m is StandardMaterial3D:invalid.append("Missing/non-standard material")
			else:
				if m.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED or m.albedo_texture!=null:invalid.append(m.resource_name)
				materials.append({"name":m.resource_name,"color":str(m.albedo_color),"roughness":m.roughness,"metallic":m.metallic,"emission_enabled":m.emission_enabled})
	var shapes: Array=stage.facility.find_children("*","CollisionShape3D",true,false)
	check(stage.asset_id+" root identity/metre convention",stage.facility.transform==Transform3D.IDENTITY)
	check(stage.asset_id+" imported materials opaque/texture-free/present",invalid.is_empty(),invalid)
	check(stage.asset_id+" static collision active on expected layers",shapes.all(func(s):return s.shape!=null and not s.disabled) and stage.facility.get_node("Collision").collision_layer==1 and stage.facility.get_node("Collision").collision_mask==2)
	check(stage.asset_id+" no asset scripts/cameras/lights",stage.facility.get_script()==null and stage.facility.find_children("*","Light3D",true,false).is_empty() and stage.facility.find_children("*","Camera3D",true,false).is_empty())
	geometry.append({"asset":stage.asset_id,"bounds":str(box),"size":str(box.size),"min_y":box.position.y,"triangles":triangles,"surfaces":surfaces,"collision_shapes":shapes.size(),"materials":materials})
func shot(name: String, at: Vector3, target: Vector3, fov:=58.0) -> void:
	if not capture:return
	stage.player.set_physics_process(false)
	stage.review_camera.position=at;stage.review_camera.fov=fov;stage.review_camera.look_at(target);stage.review_camera.make_current()
	await frames(15);RenderingServer.force_draw(false)
	var file: String=OUT+stage.asset_id+"-"+name+".png"
	var ok:=root.get_texture().get_image().save_png(file)==OK
	captures.append({"file":file,"pass":ok,"camera":str(at),"target":str(target)})
	check("Rendered "+stage.asset_id+" "+name,ok)
	stage.player.set_physics_process(true);stage.player.camera.make_current()
func gameplay_shot(name: String) -> void:
	check(stage.asset_id+" "+name+" camera mode",stage.player.camera.current and stage.player.avatar.visible==stage.player.third_person)
	sample_volumes()
	if not capture:return
	await frames(15);RenderingServer.force_draw(false)
	var file: String=OUT+stage.asset_id+"-"+name+".png"
	var ok:=root.get_texture().get_image().save_png(file)==OK
	captures.append({"file":file,"pass":ok,"player":str(stage.player.position),"camera":str(stage.player.camera.global_position)})
	check("Gameplay image "+name,ok)
func routes(id: String, third: bool) -> void:
	var mode: String="TPP " if third else "FPP "
	await reset(stage.VIEWS[id][2],third)
	match id:
		"disciple_residence":
			await walk(mode+"climb dorm stair",Vector3(2.2,.5,3))
			for x: float in [-6.6,-2.2,2.2,6.6]:
				await walk(mode+"veranda to room "+str(x),Vector3(x,.5,3))
				await walk(mode+"enter room "+str(x),Vector3(x,.5,1.2))
				if x==2.2:await gameplay_shot("third-person-interior" if third else "first-person-interior")
				await walk(mode+"leave room "+str(x),Vector3(x,.5,3))
			await walk(mode+"return to dorm stair",Vector3(2.2,.5,3))
			await walk(mode+"descend dorm stair",Vector3(2.2,.03,7))
		"elder_residence":
			await walk(mode+"enter compound gate",Vector3(0,.03,3))
			await walk(mode+"climb elder stair and enter main room",Vector3(0,1,-3.4))
			await gameplay_shot("third-person-interior" if third else "first-person-interior")
			await walk(mode+"descend elder stair",Vector3(0,.03,3))
			await walk(mode+"approach attendant wing",Vector3(5.8,.03,4))
			await walk(mode+"climb west-facing wing stair and enter",Vector3(8.3,.31,4))
			await walk(mode+"leave attendant wing",Vector3(5.8,.03,4))
		"dining_hall_kitchen":
			await walk(mode+"climb dining entrance",Vector3(0,.6,5.2))
			for x: float in [-6,6]:
				await walk(mode+"veranda to side entrance "+str(x),Vector3(x,.6,5.2))
				await walk(mode+"enter side dining door "+str(x),Vector3(x,.6,3.4))
				await walk(mode+"return through side door "+str(x),Vector3(x,.6,5.2))
			await walk(mode+"return to main dining door",Vector3(0,.6,5.2))
			await walk(mode+"enter main dining aisle",Vector3(0,.6,3.4))
			await gameplay_shot("third-person-interior" if third else "first-person-interior")
			await walk(mode+"pass through kitchen door",Vector3(0,.6,-9.5))
			if not third:await gameplay_shot("first-person-kitchen")
			await walk(mode+"kitchen cross aisle",Vector3(0,.6,-8.2))
			await walk(mode+"approach service door",Vector3(4.6,.6,-8.2))
			await walk(mode+"exit service door and descend stair",Vector3(9,.03,-8.2))
			await walk(mode+"reenter service door and climb stair",Vector3(4.6,.6,-8.2))
		"spirit_herb_garden":
			await walk(mode+"garden gate and front path",Vector3(0,.03,4.1))
			await walk(mode+"spring approach",Vector3(3.4,.03,4.1))
			await walk(mode+"pass spring east side",Vector3(3.4,.03,-3.2))
			await walk(mode+"approach pavilion",Vector3(0,.03,-3.8))
			await walk(mode+"climb herb pavilion stair",Vector3(0,.5,-6.3))
			await gameplay_shot("third-person-interior" if third else "first-person-interior")
			await walk(mode+"descend herb pavilion stair",Vector3(0,.03,-3.8))
			await walk(mode+"return east of spring",Vector3(3.4,.03,-3.2))
			await walk(mode+"east cross path",Vector3(11.25,.03,-3.2))
			await walk(mode+"bed/fence circulation",Vector3(11.25,.03,-7.5))
			await walk(mode+"shed approach",Vector3(9.3,.03,-7.5))
			await walk(mode+"enter tool shed",Vector3(9.3,.03,-9.5))
func run() -> void:
	capture="--capture" in OS.get_cmdline_user_args();root.size=Vector2i(1280,720)
	stage=Node3D.new();stage.set_script(load("res://scripts/claude_asset_review.gd"));stage.automated=true;root.add_child(stage)
	await frames(15)
	for id: String in IDS:
		stage.show_asset(id);await frames(5);await settle();measure()
		await add_visual_audit()
		var view: Array=stage.VIEWS[id]
		await shot("three-quarter",view[0],view[1])
		await shot("rear",Vector3(-view[0].x,view[0].y,-view[0].z),view[1])
		for third: bool in [false,true]:await routes(id,third)
		if id=="disciple_residence":
			await reset(Vector3(1,.03,8),false)
			stage.player.drive=Vector3.FORWARD;await settle(160);stage.player.drive=Vector3.ZERO
			check("Dorm wall between doors blocks real movement",stage.player.position.z>2.2 and stage.player.position.z<2.6,str(stage.player.position))
		if id=="spirit_herb_garden":
			await reset(Vector3(7.2,.03,6.8),false)
			stage.player.drive=Vector3.FORWARD;await settle(80);stage.player.drive=Vector3.ZERO
			check("Raised herb bed blocks real movement",stage.player.position.z>5.8 and stage.player.position.z<6.3,str(stage.player.position))
		visual_audit.free();await settle()
	check("Camera spheres clear authored solids on sampled routes",camera_failures.is_empty(),{"samples":sampled_volumes,"failures":camera_failures})
	check("Upper body clears visible architecture on sampled routes",visual_failures.is_empty(),{"samples":sampled_volumes,"failures":visual_failures})
	var failed:=checks.filter(func(c):return not c.pass).size()
	var result: Dictionary={"project_root":ProjectSettings.globalize_path("res://"),"checks":checks,"passed":checks.size()-failed,"failed":failed,"geometry":geometry,"movement":movement,"captures":captures,"sampled_camera_and_visual_volumes":sampled_volumes,"camera_failures":camera_failures,"visual_failures":visual_failures,"limits":["Programmatic unchanged inspection controller; no human playtest","Inspection floor provided; no production terrain or world placement","No performance measurement or representative low-end/executable test","No exhaustive collisions, camera angles, roof-walking, LOD, navigation or interactions","Static open door leaves and visual-only small props/paths retained from authored assets"]}
	FileAccess.open(OUT+("rendered-results.json" if capture else "headless-results.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("Canonical Claude assets: ",checks.size()-failed," PASS / ",failed," FAIL")
	quit(1 if failed else 0)

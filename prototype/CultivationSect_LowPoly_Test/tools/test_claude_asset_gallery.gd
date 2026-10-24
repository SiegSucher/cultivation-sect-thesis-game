extends SceneTree
## Real programmatic key/mouse events and gallery routes; no human playtest.
const OUT := "res://reports/codex-claude-integration/"
const IDS := ["disciple_residence","elder_residence","dining_hall_kitchen","spirit_herb_garden"]
var checks: Array=[]
var captures: Array=[]
func _initialize() -> void:call_deferred("run")
func frames(n:=10) -> void:
	for i in range(n):await process_frame
func event(key: int, down: bool) -> void:
	var e:=InputEventKey.new();e.physical_keycode=key;e.pressed=down;Input.parse_input_event(e)
func press(key: int) -> void:
	event(key,true);await frames();event(key,false);await frames()
func check(label: String, ok: bool, detail: Variant=null) -> void:
	checks.append({"check":label,"pass":ok,"detail":detail})
	if not ok:push_warning(label+" "+str(detail))
func shot(name: String) -> void:
	await frames(20);RenderingServer.force_draw(false)
	var file: String=OUT+name+".png"
	var ok:=root.get_texture().get_image().save_png(file)==OK
	captures.append({"file":file,"pass":ok});check("Gallery capture "+name,ok)
func run() -> void:
	root.size=Vector2i(1280,720)
	change_scene_to_file("res://scenes/asset_gallery.tscn");await frames(30)
	check("Eight explicit catalog entries, no world scan",current_scene.catalog.size()==8)
	for i in range(4):
		current_scene.select_asset(i)
		check("Existing gallery entry loads "+str(i),is_instance_valid(current_scene.model) and not current_scene.walkthrough_button.disabled)
	for i in range(4):
		var id: String=IDS[i]
		current_scene.select_asset(i+4);await frames()
		check(id+" canonical gallery resource",current_scene.catalog[i+4].id==id and current_scene.catalog[i+4].resource=="res://scenes/buildings/"+id+".tscn")
		check(id+" source resolves to copied native file",not current_scene.source_button.disabled and FileAccess.file_exists(current_scene.workspace_path(current_scene.catalog[i+4].source)))
		check(id+" static doors correctly have no toggle action",current_scene.doors_button.disabled)
		check(id+" Walk action enabled",not current_scene.walkthrough_button.disabled)
		await shot("gallery-"+id)
		current_scene.preset("Interior");await frames(12)
		var q:=PhysicsShapeQueryParameters3D.new();var sphere:=SphereShape3D.new();sphere.radius=.17
		q.shape=sphere;q.transform.origin=current_scene.camera.global_position;q.collision_mask=1
		var space: PhysicsDirectSpaceState3D=current_scene.model.get_world_3d().direct_space_state
		check(id+" gallery interior camera clears solids",space.intersect_shape(q,1).is_empty(),str(q.transform.origin))
		await shot("gallery-"+id+"-interior")
		current_scene.open_walkthrough();await frames(24)
		var s: Node=current_scene
		check(id+" Walk opens correct wrapper",s.get_script().resource_path=="res://scripts/claude_asset_review.gd" and s.asset_id==id and s.facility.transform==Transform3D.IDENTITY)
		await press(KEY_1)
		check(id+" 1 starts walk with existing player",s.walking and s.player.camera.current and s.player.is_physics_processing())
		var before: Vector3=s.player.position
		event(KEY_W,true)
		for n in range(15):await physics_frame
		event(KEY_W,false);await frames()
		check(id+" W moves inspection player",s.player.position.z<before.z-.4,{"before":str(before),"after":str(s.player.position)})
		await press(KEY_TAB)
		check(id+" Tab selects third person",s.player.third_person and s.player.avatar.visible)
		await press(KEY_TAB)
		check(id+" Tab returns to first person",not s.player.third_person and not s.player.avatar.visible)
		var yaw: float=s.player.yaw
		var motion:=InputEventMouseMotion.new();motion.relative=Vector2(20,10);Input.parse_input_event(motion);await frames()
		check(id+" mouse look",absf(s.player.yaw-yaw)>.01)
		await press(KEY_1)
		check(id+" 1 pauses walk for review",not s.walking and s.review_camera.current and not s.player.is_physics_processing())
		for k in range(4):
			await press(KEY_2+k)
			check("Review switch "+str(k)+" from "+id,s.asset_id==IDS[k] and s.facility.transform==Transform3D.IDENTITY and not s.walking)
		await press(KEY_ESCAPE)
		check(id+" Esc returns to eight-asset gallery",current_scene is Control and current_scene.catalog.size()==8)
	var failures:=checks.filter(func(c):return not c.pass).size()
	FileAccess.open(OUT+"gallery-input-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failures,"failed":failures,"captures":captures,"limits":["Programmatic real input events, not human keyboard/mouse rehearsal","Native-source path and file tested; OS Open source button launch not executed"]},"\t"))
	print("Claude gallery/input: ",checks.size()-failures," PASS / ",failures," FAIL")
	quit(1 if failures else 0)

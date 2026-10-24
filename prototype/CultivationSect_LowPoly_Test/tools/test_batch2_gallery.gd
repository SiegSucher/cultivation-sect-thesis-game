extends SceneTree
## Current twelve-entry gallery and real programmatic inputs for both new routes.
const OUT := "res://reports/codex-alchemy-medicine/"
const IDS := ["alchemy_pavilion","medicine_hall"]
var checks: Array=[]
var aid: String="gallery"
func _initialize() -> void:call_deferred("run")
func frames(n:=8) -> void:
	for i in n:await process_frame
func event(key: int, down: bool) -> void:
	var e:=InputEventKey.new();e.physical_keycode=key;e.pressed=down;Input.parse_input_event(e)
func press(key: int) -> void:
	event(key,true);await frames();event(key,false);await frames()
func check(label: String, ok: bool) -> void:
	checks.append({"asset":aid,"check":label,"pass":ok})
	if not ok:print("FAIL ",aid," ",label)
func shot(label: String) -> void:
	await frames(15);RenderingServer.force_draw(false)
	check("image "+label,root.get_texture().get_image().save_png(OUT+aid+"-"+label+".png")==OK)
func run() -> void:
	root.size=Vector2i(1280,720)
	change_scene_to_file("res://scenes/asset_gallery.tscn");await frames(25)
	check("12 explicit entries",current_scene.catalog.size()==12)
	for i in 12:
		current_scene.select_asset(i);await frames(5)
		check("entry loads "+str(current_scene.catalog[i].id),is_instance_valid(current_scene.model) and not current_scene.walkthrough_button.disabled)
	for j in 2:
		aid=IDS[j]
		current_scene.select_asset(10+j);await frames()
		check("canonical entry",current_scene.catalog[10+j].id==aid and current_scene.catalog[10+j].resource=="res://scenes/buildings/"+aid+".tscn")
		check("source copy exists",FileAccess.file_exists(current_scene.workspace_path(current_scene.catalog[10+j].source)))
		check("static leaves have no toggle",current_scene.doors_button.disabled)
		await shot("gallery-exterior")
		current_scene.preset("Interior");await frames()
		var sphere:=SphereShape3D.new();sphere.radius=.17
		var q:=PhysicsShapeQueryParameters3D.new();q.shape=sphere;q.transform.origin=current_scene.camera.global_position;q.collision_mask=1
		check("interior camera clears solids",current_scene.model.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty())
		await shot("gallery-interior")
		current_scene.open_walkthrough();await frames(20)
		var s: Node=current_scene
		check("correct standalone Walk asset",s.get_script().resource_path=="res://scripts/alchemy_medicine_review.gd" and s.start_asset_index==j and s.asset.transform==Transform3D.IDENTITY)
		check("unchanged inspection controller",s.player.get_script().resource_path=="res://scripts/training_inspection_player.gd")
		await press(KEY_1);check("1 starts walk",s.player.is_physics_processing() and s.player.camera.current)
		var before: Vector3=s.player.position
		event(KEY_W,true)
		for i in 18:await physics_frame
		event(KEY_W,false);await frames();check("W moves",s.player.position.z<before.z-.5)
		await press(KEY_TAB);check("Tab third-person",s.player.third_person and s.player.avatar.visible)
		await shot("input-third-person")
		await press(KEY_TAB);check("Tab first-person",not s.player.third_person and not s.player.avatar.visible)
		var old_yaw: float=s.player.yaw
		var motion:=InputEventMouseMotion.new();motion.relative=Vector2(20,10);Input.parse_input_event(motion);await frames()
		check("mouse look",absf(s.player.yaw-old_yaw)>.01)
		await press(KEY_1);check("1 pauses walk",not s.player.is_physics_processing() and s.review_camera.current)
		for k in 2:
			await press(KEY_2+k)
			check("review switches to "+IDS[k],s.asset.name==("AlchemyPavilion" if k==0 else "MedicineHall") and not s.player.is_physics_processing() and s.player.velocity==Vector3.ZERO)
			if k==1:
				var exceptions: Array=s.player.get_collision_exceptions()
				check("Medicine has exactly its live camera-only exception",exceptions.size()==1 and exceptions.has(s.asset.get_node("CameraDetailObstruction")))
			else:
				check("Alchemy has no stale Medicine exceptions",s.player.get_collision_exceptions().is_empty())
		await press(KEY_ESCAPE);check("Esc returns to twelve-entry gallery",current_scene is Control and current_scene.catalog.size()==12)
	var failed:=checks.filter(func(c):return not c.pass).size()
	FileAccess.open(OUT+"gallery-input.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"limit":"Programmatic inputs, not human playtesting or OS source-button launch"},"  "))
	print(checks.size()-failed," PASS / ",failed," FAIL")
	quit(1 if failed else 0)

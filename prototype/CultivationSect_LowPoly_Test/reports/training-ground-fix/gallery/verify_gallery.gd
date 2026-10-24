extends SceneTree
## Diagnostic only: exercise the existing button and inputs in memory. No asset,
## controller, gallery, scene or previous evidence is rewritten.
const OUT := "res://reports/training-ground-fix/gallery/"
const REVIEW_IDS := ["sect_gate","disciple_residence","elder_residence","dining_hall_kitchen","spirit_herb_garden","mission_hall","exchange_hall","alchemy_pavilion","medicine_hall"]
const FIRST_FOUR := {
	"main_sect_hall":"res://scenes/hall_experiment.tscn",
	"sect_gate":"res://scenes/review/gate_walkthrough.tscn",
	"martial_training_ground":"res://scenes/review/training_walkthrough.tscn",
	"scripture_pavilion":"res://scenes/review/scripture_walkthrough.tscn",
}
var checks: Array = []
var rows: Array = []
var aid := ""

func _initialize() -> void: call_deferred("run")

func frames(n := 8) -> void:
	for i in n: await process_frame

func check(label: String, passed: bool, detail: Variant = null) -> void:
	checks.append({"asset":aid,"check":label,"pass":passed,"detail":detail})
	if not passed: print("FAIL ",aid," ",label," ",detail)

func key(code: int, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)

func press(code: int) -> void:
	key(code,true); await frames(3); key(code,false); await frames(5)

func vector(v: Vector3) -> Array: return [v.x,v.y,v.z]

func state(scene: Node, player: CharacterBody3D) -> Dictionary:
	var active := scene.get_viewport().get_camera_3d()
	return {"scene":scene.scene_file_path,"scene_script":scene.get_script().resource_path,
		"player_path":str(player.get_path()),"controller":player.get_script().resource_path,
		"player_position":vector(player.global_position),"player_visible_in_tree":player.is_visible_in_tree(),
		"avatar_visible":player.avatar.visible,"avatar_visible_in_tree":player.avatar.is_visible_in_tree(),
		"avatar_mesh_count":player.avatar.find_children("*","MeshInstance3D",true,false).size(),
		"automated":player.automated,"physics_enabled":player.is_physics_processing(),
		"unhandled_input_enabled":player.is_processing_unhandled_input(),"third_person":player.third_person,
		"player_camera_current":player.camera.current,"current_camera":str(active.get_path()) if active else "NONE",
		"camera_position":vector(active.global_position) if active else [],
		"avatar_centre_in_current_frustum":active.is_position_in_frustum(player.global_position+Vector3(0,.9,0)) if active else false,
		"camera_distance":player.camera_distance,"mouse_captured":Input.mouse_mode==Input.MOUSE_MODE_CAPTURED}

func shot(label: String) -> void:
	if false: return # Capture every catalog entry in this audit.
	for i in 3: await RenderingServer.frame_post_draw
	check("capture "+label,root.get_texture().get_image().save_png(OUT+aid+"-"+label+".png")==OK)

func hold_w(player: CharacterBody3D, count := 24) -> float:
	var before := player.global_position
	key(KEY_W,true)
	await frames(2)
	check("physical W key initialized",Input.is_physical_key_pressed(KEY_W))
	for i in count: await physics_frame
	key(KEY_W,false)
	await frames(5)
	return Vector2(player.global_position.x-before.x,player.global_position.z-before.z).length()

func mouse_look(player: CharacterBody3D, expected: bool, label: String) -> void:
	var yaw: float = player.yaw
	var pitch: float = player.pitch
	var mouse := InputEventMouseMotion.new()
	mouse.relative = Vector2(20,10)
	Input.parse_input_event(mouse)
	await frames(5)
	check(label,(absf(player.yaw-yaw)>.01 and absf(player.pitch-pitch)>.01) if expected else (player.yaw==yaw and player.pitch==pitch))

func audit_controls(scene: Node, player: CharacterBody3D, row: Dictionary) -> void:
	await mouse_look(player,true,"mouse look works while walking")
	if aid in ["martial_training_ground","scripture_pavilion"]:
		# These two fixtures have no overview camera or documented 1 binding.
		await press(KEY_1)
		check("1 intentionally has no mode binding",player.camera.current and player.is_physics_processing() and player.is_processing_unhandled_input() and player.third_person)
		row["overview"] = "N/A: walk-only fixture; 1 not documented or implemented"
	else:
		await press(KEY_1)
		check("1 enters overview and releases mouse",not player.camera.current and not player.is_physics_processing() and not player.is_processing_unhandled_input() and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
		await shot("overview")
		var paused_distance: float = await hold_w(player,12)
		check("overview intentionally stops movement",paused_distance<.001,paused_distance)
		await mouse_look(player,false,"overview does not turn the walking player")
		await press(KEY_TAB)
		check("Tab in overview does not trap or change player mode",player.third_person and not player.is_physics_processing())
		await press(KEY_1)
		check("1 resumes third-person walk and captures mouse",player.camera.current and player.is_physics_processing() and player.is_processing_unhandled_input() and player.third_person and player.avatar.visible and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED)
		check("movement resumes after overview",await hold_w(player,12)>.3)
		await mouse_look(player,true,"mouse look resumes after overview")
		row["overview"] = "PASS: 1 enters and exits; movement/mouse restored"
	# Verify both directions of Tab again after the mode cycle.
	await press(KEY_TAB)
	check("Tab returns to first person",not player.third_person and not player.avatar.visible and player.camera.current)
	await press(KEY_TAB)
	check("Tab returns to visible third person",player.third_person and player.avatar.is_visible_in_tree() and player.camera.current)
	if aid in ["main_sect_hall","sect_gate"]:
		if aid=="main_sect_hall":
			var was_open: bool = scene.hall.main_door.target_open
			await press(KEY_E)
			check("E toggles Hall door target",scene.hall.main_door.target_open!=was_open)
		else:
			var was_open: bool = scene.facility.preview_open
			await press(KEY_E)
			check("E toggles Gate door target",scene.facility.preview_open!=was_open)
		for preset: int in [KEY_2,KEY_3,KEY_4]:
			await press(preset)
			check("preset "+str(preset-KEY_0)+" selects overview",not player.camera.current and not player.is_physics_processing() and not player.is_processing_unhandled_input() and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
			await press(KEY_1)
			check("walk recovers after preset "+str(preset-KEY_0),player.camera.current and player.is_physics_processing() and player.third_person)
		row["other_controls"] = "E door target + 2/3/4 overview presets and return PASS; full door traversal not repeated"
	elif aid=="scripture_pavilion":
		await press(KEY_G)
		check("G enables inspection authorization",scene.inspection_authorized)
		await press(KEY_E)
		check("E rejects remote archive request",not scene.facility.archive_gate.is_open and "closer" in scene.access_message)
		await press(KEY_G)
		check("G revokes inspection authorization",not scene.inspection_authorized)
		row["other_controls"] = "G authorization + E remote denial PASS; archive traversal not repeated"
	elif aid in ["disciple_residence","elder_residence","dining_hall_kitchen","spirit_herb_garden"]:
		for i in 4:
			await press(KEY_2+i)
			check("asset key "+str(2+i)+" resets to documented review",scene.asset_id==scene.IDS[i] and not player.is_physics_processing() and not player.is_processing_unhandled_input() and not player.third_person and scene.review_camera.current and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
			await press(KEY_1)
			check("switched asset resumes walk",player.is_physics_processing() and player.camera.current and player.is_processing_unhandled_input())
			await press(KEY_TAB)
			check("switched asset has visible third-person avatar",player.third_person and player.avatar.visible)
		row["other_controls"] = "2/3/4/5 switch all four assets; 1/Tab recover after each PASS"
	elif aid in ["alchemy_pavilion","medicine_hall"]:
		for i in 2:
			await press(KEY_2+i)
			check("utility asset key "+str(2+i)+" resets to review",scene.asset.name==("AlchemyPavilion" if i==0 else "MedicineHall") and not player.is_physics_processing() and not player.is_processing_unhandled_input() and not player.third_person and scene.review_camera.current)
			var exceptions: Array = player.get_collision_exceptions()
			check("utility camera exception lifecycle",exceptions.is_empty() if i==0 else exceptions.size()==1 and exceptions.has(scene.asset.get_node("CameraDetailObstruction")))
			await press(KEY_1)
			await press(KEY_TAB)
			check("utility switched asset resumes visible third-person walk",player.is_physics_processing() and player.is_processing_unhandled_input() and player.camera.current and player.third_person and player.avatar.visible)
		row["other_controls"] = "2/3 switch utilities; 1/Tab recovery and Medicine exception lifecycle PASS"
	else:
		row["other_controls"] = "No additional interaction keys documented"
	await press(KEY_ESCAPE)
	check("Esc returns to gallery with mouse released",current_scene is Control and current_scene.catalog.size()==12 and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
	if current_scene is Control:
		# A fresh GUI click must work after returning, not just keyboard events.
		current_scene.select_asset(0)
		check("gallery remains usable after return",is_instance_valid(current_scene.model) and not current_scene.walkthrough_button.disabled)

func check_automated_hall() -> void:
	aid = "automated_hall"
	var scene: Node3D = load("res://scenes/hall_experiment.tscn").instantiate()
	scene.automated = true
	root.add_child(scene)
	await frames(5)
	check("automated Hall startup retained",scene.player.automated and not scene.player.third_person and scene.view_camera.current and scene.player.is_physics_processing())
	scene.free()

func run() -> void:
	root.size = Vector2i(1280,720)
	var catalog: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/gallery/catalog.json"))
	check("canonical catalog contains twelve entries",catalog.size()==12)
	for i in catalog.size():
		change_scene_to_file("res://scenes/asset_gallery.tscn")
		await frames(18)
		var gallery: Control = current_scene
		gallery.select_asset(i)
		await frames(8)
		var entry: Dictionary = gallery.catalog[i]
		aid = entry.id
		var expected: String = FIRST_FOUR.get(aid,entry.get("walkthrough",""))
		check("Walk button enabled",not gallery.walkthrough_button.disabled)
		# Send real GUI mouse events to the existing button; do not call the
		# walkthrough method or toggle the scene's mode directly.
		var at: Vector2 = gallery.walkthrough_button.get_global_rect().get_center()
		for down: bool in [true,false]:
			var click := InputEventMouseButton.new()
			click.position = at; click.global_position = at
			click.button_index = MOUSE_BUTTON_LEFT; click.pressed = down
			Input.parse_input_event(click)
			await frames(3)
		await frames(16)
		check("button launches exact expected scene",current_scene.scene_file_path==expected,{"expected":expected,"actual":current_scene.scene_file_path})
		if current_scene == gallery: continue
		var scene: Node = current_scene
		var player: CharacterBody3D = scene.player
		check("inspection player instantiated",is_instance_valid(player) and player.is_inside_tree())
		check("procedural character and capsule exist",player.avatar.find_children("*","MeshInstance3D",true,false).size()==2 and player.find_children("*","CollisionShape3D",true,false).size()==1)
		var row := {"asset":aid,"catalog_building_resource":entry.resource,"expected_launch_scene":expected,"initial":state(scene,player)}
		check("manual startup mode matches intended behavior",not player.automated and player.third_person==(aid=="main_sect_hall") and player.avatar.visible==(aid=="main_sect_hall"))
		var legacy_flags := [player.is_physics_processing(),player.is_processing_unhandled_input(),player.camera.current,player.avatar.visible]
		player.indoor_camera_enabled = false; player.update_camera()
		check("indoor feature switch does not change launch/input flags",legacy_flags==[player.is_physics_processing(),player.is_processing_unhandled_input(),player.camera.current,player.avatar.visible])
		player.indoor_camera_enabled = true; player.update_camera()
		await shot("initial")
		var initial_move: float = await hold_w(player)
		row["W_distance_before_mode_change_m"] = initial_move
		if aid in REVIEW_IDS:
			check("initial overview disables movement/input/player camera",not player.is_physics_processing() and not player.is_processing_unhandled_input() and not player.camera.current)
			check("W cannot move while overview is active",initial_move<.001,initial_move)
			await press(KEY_1)
		else:
			check("immediate-walk scene already accepts movement",initial_move>.5,initial_move)
		check("walking activates physics/input/follow camera",player.is_physics_processing() and player.is_processing_unhandled_input() and player.camera.current)
		if player.third_person: await press(KEY_TAB)
		check("first-person hides only avatar",not player.third_person and not player.avatar.visible and player.camera.current)
		row["walking_first_person"] = state(scene,player)
		await shot("walking-first-person")
		var walked: float = await hold_w(player)
		check("W moves real controller after walking starts",walked>.5,walked)
		row["W_distance_in_walk_m"] = walked
		check("first-person camera follows real player",player.camera.global_position.distance_to(player.global_position+Vector3(0,1.65,0))<.001)
		await press(KEY_TAB)
		check("Tab reveals third-person character",player.third_person and player.avatar.is_visible_in_tree() and player.camera.current and player.camera_distance>.5)
		check("character centre inside follow-camera frustum",player.camera.is_position_in_frustum(player.global_position+Vector3(0,.9,0)))
		row["walking_third_person"] = state(scene,player)
		await shot("walking-third-person")
		await audit_controls(scene,player,row)
		rows.append(row)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await check_automated_hall()
	var failed := checks.filter(func(c):return not c.pass).size()
	FileAccess.open(OUT+"launch-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"passed":checks.size()-failed,"failed":failed,"entries":rows,"limits":"Rendered programmatic GUI/input reproduction, not human playtesting or observation of the user's live editor/debugger. Existing runtime sources unchanged."},"  "))
	print(checks.size()-failed," PASS / ",failed," FAIL; ",rows.size()," gallery launches")
	quit(1 if failed else 0)

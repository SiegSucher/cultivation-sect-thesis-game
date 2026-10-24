extends SceneTree
## Repeat the known doorway camera overlap poses without editing camera code.
const OUT := "res://reports/door-collision-fix/"
var stage: Node3D
var contacts: Array = []
var checks: Array = []
var data: Array = []
func _initialize() -> void:call_deferred("run")
func check(label: String, ok: bool) -> void:
	checks.append({"check":label,"pass":ok})
	if not ok:print("FAIL ",label)
func sample(room: float, mode: String, i: int) -> void:
	var ball:=SphereShape3D.new();ball.radius=.16
	var q:=PhysicsShapeQueryParameters3D.new();q.shape=ball;q.collision_mask=1|8;q.transform.origin=stage.player.camera.global_position
	var overlaps:=stage.get_world_3d().direct_space_state.intersect_shape(q,6)
	if not overlaps.is_empty():contacts.append({"room_x":room,"mode":mode,"index":i,"camera":str(q.transform.origin)})
	data.append({"room_x":room,"mode":mode,"distance":stage.player.camera_distance,"overlap":not overlaps.is_empty()})
func run() -> void:
	stage=load("res://scenes/review/disciple_residence_walkthrough.tscn").instantiate();stage.automated=true;root.add_child(stage)
	stage.player.automated=true
	var visual:=StaticBody3D.new();visual.collision_layer=8;visual.collision_mask=0;stage.add_child(visual)
	for mesh: MeshInstance3D in stage.facility.find_children("*","MeshInstance3D",true,false):
		var shape:=CollisionShape3D.new();shape.shape=mesh.mesh.create_trimesh_shape();shape.transform=mesh.global_transform;visual.add_child(shape)
	for i in 5:await physics_frame
	for x: float in [-6.6,-2.2,2.2,6.6]:
		stage.player.set_physics_process(false);stage.player.drive=Vector3.ZERO;stage.player.velocity=Vector3.ZERO
		stage.player.position=Vector3(x,.5,1.2);stage.player.third_person=true
		for pitch: float in [-.35,0,.35]:
			for i in 24:
				stage.player.pitch=pitch;stage.player.yaw=i*TAU/24;stage.player.update_camera();sample(x,"static",i)
		stage.player.set_physics_process(true)
		for i in 180:
			stage.player.yaw=i*TAU/180;stage.player.pitch=.35*sin(i*TAU/180)
			await physics_frame
			sample(x,"turn",i)
		check("room "+str(x)+" camera clears authored and visible geometry",contacts.filter(func(c):return c.room_x==x).is_empty())
	var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://reports/indoor-camera-fix/after-headless.json"))
	var baseline_static: int=old.points.filter(func(s):return s.asset=="disciple" and not s.visual_hits.is_empty()).size()
	var baseline_turn: int=old.samples.filter(func(s):return s.asset=="disciple" and not s.visual_hits.is_empty()).size()
	var failed:=checks.filter(func(c):return not c.pass).size()
	FileAccess.open(OUT+"dorm-camera.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"samples":data,"contacts":contacts,"prior_indoor_camera_stage_room_x_2_2":{"static_visual_overlaps":baseline_static,"turn_visual_overlaps":baseline_turn},"camera_code_changed":false},"  "))
	print(checks.size()-failed," PASS / ",failed," FAIL; ",data.size()," doorway camera poses; ",contacts.size()," overlaps")
	quit(1 if failed else 0)

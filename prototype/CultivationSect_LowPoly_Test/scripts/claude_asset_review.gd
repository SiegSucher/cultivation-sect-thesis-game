extends Node3D
## One asset at local origin. The review floor is not a terrain/layout asset.
const IDS := ["disciple_residence","elder_residence","dining_hall_kitchen","spirit_herb_garden"]
const VIEWS := {
	"disciple_residence":[Vector3(17,10,20),Vector3(0,2.5,0),Vector3(2.2,.05,8.5)],
	"elder_residence":[Vector3(21,16,27),Vector3(0,2,-1),Vector3(0,.05,14)],
	"dining_hall_kitchen":[Vector3(22,15,24),Vector3(0,3,-2),Vector3(0,.05,11)],
	"spirit_herb_garden":[Vector3(20,17,24),Vector3(0,0,-1),Vector3(0,.05,15)],
}
@export var asset_id := "disciple_residence"
var automated := false
var facility: Node3D
var player: CharacterBody3D
var review_camera: Camera3D
var hud: Label
var walking := false
func _ready() -> void:
	var environment:=Environment.new()
	environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color("a5c6cb")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("e0e9e6")
	environment.ambient_light_energy=.65
	var world:=WorldEnvironment.new(); world.environment=environment; add_child(world)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-48,-30,0); sun.light_color=Color("fff0d8")
	sun.shadow_enabled=true; sun.directional_shadow_max_distance=100; add_child(sun)
	var floor_body:=StaticBody3D.new(); floor_body.name="InspectionFloorOnly"
	var box:=BoxShape3D.new(); box.size=Vector3(100,.1,100)
	var shape:=CollisionShape3D.new(); shape.shape=box; shape.position.y=-.062
	floor_body.add_child(shape); add_child(floor_body)
	var ground:=MeshInstance3D.new(); ground.name="InspectionGroundOnly"
	var plane:=PlaneMesh.new(); plane.size=Vector2(100,100); ground.mesh=plane; ground.position.y=-.012
	var material:=StandardMaterial3D.new(); material.albedo_color=Color("6b8071"); material.roughness=1
	ground.material_override=material; add_child(ground)
	player=CharacterBody3D.new(); player.set_script(load("res://scripts/training_inspection_player.gd"))
	player.name="UnchangedInspectionPlayer"; player.automated=automated; add_child(player)
	review_camera=Camera3D.new(); review_camera.fov=58; add_child(review_camera)
	var canvas:=CanvasLayer.new(); add_child(canvas)
	var panel:=PanelContainer.new(); panel.position=Vector2(16,16); canvas.add_child(panel)
	hud=Label.new(); hud.add_theme_font_size_override("font_size",16); panel.add_child(hud)
	show_asset(asset_id)
func show_asset(id: String) -> void:
	assert(id in IDS)
	if is_instance_valid(facility):
		remove_child(facility); facility.queue_free()
	asset_id=id
	facility=load("res://scenes/buildings/"+asset_id+".tscn").instantiate()
	facility.name="AssetAtLocalOrigin"; add_child(facility)
	var view: Array=VIEWS[asset_id]
	review_camera.position=view[0]; review_camera.look_at(view[1]); review_camera.make_current()
	player.position=view[2]; player.velocity=Vector3.ZERO; player.drive=Vector3.ZERO
	player.yaw=0; player.pitch=0; player.third_person=false; player.update_camera()
	set_walking(false)
func set_walking(value: bool) -> void:
	walking=value
	player.set_physics_process(value); player.set_process_unhandled_input(value)
	if value: player.camera.make_current()
	else: review_camera.make_current()
	if not automated: Input.mouse_mode=Input.MOUSE_MODE_CAPTURED if value else Input.MOUSE_MODE_VISIBLE
	update_hud()
func update_hud() -> void:
	if hud:
		hud.text=asset_id.replace("_"," ").to_upper()+" — ASSET INSPECTION\n1 walk/review · WASD/mouse · Tab first/third person · Esc gallery\n2 Disciples · 3 Elder · 4 Dining/Kitchen · 5 Herb Garden\nOne asset at its local origin; inspection ground only"
func _unhandled_input(event: InputEvent) -> void:
	if automated or not (event is InputEventKey and event.pressed and not event.echo):return
	match event.physical_keycode:
		KEY_1:set_walking(not walking)
		KEY_2,KEY_3,KEY_4,KEY_5:show_asset(IDS[event.physical_keycode-KEY_2])
		KEY_ESCAPE:
			Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
			get_tree().change_scene_to_file("res://scenes/asset_gallery.tscn")

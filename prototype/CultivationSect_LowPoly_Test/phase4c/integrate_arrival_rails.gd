extends SceneTree
## Targeted import and textual append: never calls the terrain/world builders.
## All existing support nodes and resource declarations remain verbatim.
const OUT := "res://phase4c/review/arrival-rails/"
const ASSEMBLY := "res://phase4c/resources/safety_assembly.tscn"
const MODULES := ["railings/rail_stair_4in11_1m","railings/rail_stair_4in11_2m"]
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var original := FileAccess.get_file_as_string(ASSEMBLY)
	if 'id="arrival_exact_2m"' in original:
		print("Arrival rails already installed; resources retained.")
		quit()
		return
	load("res://phase4c/import_kit.gd").new().prepare(MODULES,OUT+"kit-imports.json")
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://mountain_valley_compact/layout.json"))
	var flight: Dictionary
	for path: Dictionary in layout.paths:
		if path.id=="entry_stairs": flight = path
	var a := Vector3(flight.points[0][0],flight.points[0][1],flight.points[0][2])
	var b := Vector3(flight.points[1][0],flight.points[1][1],flight.points[1][2])
	var run := Vector2(b.x-a.x,b.z-a.z).length()
	assert(is_equal_approx(run,11.0) and is_equal_approx(b.y-a.y,4.0))
	var d := Vector3(b.x-a.x,0,b.z-a.z).normalized()
	var side := Vector3(-d.z,0,d.x)
	var yaw := atan2(-d.z,d.x)
	var holder := Node3D.new()
	var safety = load("res://phase4c/safety_assembly.gd").new()
	safety.root = holder
	var declarations := ""
	for length in [1,2]:
		declarations += '[ext_resource type="PackedScene" path="res://phase4c/resources/kit/railings/rail_stair_4in11_%dm.tscn" id="arrival_exact_%dm"]\n'%[length,length]
	var nodes := ""
	var records: Array = []
	for sign_value in [-1.0,1.0]:
		var shift: Vector3 = side*(flight.width*.5+.35)*sign_value
		var at := 0.0
		for length in [2,2,2,2,2,1]:
			var p := a+d*at+shift+Vector3.UP*(at*4.0/11.0+.06)
			safety.kit(safety.stair_module("entry_stairs",20,length),p,yaw)
			var node: Node3D = holder.get_child(-1)
			nodes += '\n[node name="%s" parent="." instance=ExtResource("arrival_exact_%dm")]\nposition = Vector3(%.9f, %.9f, %.9f)\nrotation = Vector3(0, %.12f, 0)\n'%[node.name,length,p.x,p.y,p.z,yaw]
			records.append({"node":str(node.name),"side":sign_value,"span":length,"run_origin_m":at,"position":[p.x,p.y,p.z]})
			at += length
		assert(is_equal_approx(at,run))
	# Add declarations before subresources and append nodes after the existing
	# payload. No landing post is added: its existing leading post closes the flight.
	var insertion := original.find("[sub_resource")
	assert(insertion>0)
	var result := original.insert(insertion,declarations+"\n")+nodes
	var file := FileAccess.open(ASSEMBLY,FileAccess.WRITE)
	file.store_string(result)
	file.close()
	var report := FileAccess.open(OUT+"integration.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"added_sections":records,"existing_payload_preserved_verbatim":true,"terrain_rebuilt":false,"landing_posts_reused":true,"rail_pitch_offset_m":.06},"\t"))
	holder.free()
	print("Appended 12 exact-pitch arrival sections; existing assembly and terrain retained.")
	quit()

extends SceneTree
## Independent compact assembly. The large scene is read-only stock for existing
## provisional props/mesh batches; no source asset or large-map file is saved.
const ROOT := "res://mountain_valley_compact/"
var layout: Dictionary
var world: Node3D
var terrain: RefCounted
var stock := {}
var used := {}
var retained: Array = []
var nature: Node3D
var large: Node3D

func _initialize() -> void: call_deferred("run")
func vec(a: Array) -> Vector3: return Vector3(a[0],a[1],a[2])
func own(node: Node) -> void:
	for child: Node in node.get_children():
		child.owner = world
		if child.scene_file_path.is_empty(): own(child)

func add_existing(source: Node3D, at: Vector3, yaw: float) -> void:
	if used.has(source.get_instance_id()): return
	used[source.get_instance_id()] = true
	var node: Node3D = source.duplicate(Node.DUPLICATE_USE_INSTANTIATION)
	var id := source.scene_file_path.get_file().get_basename()
	node.name = id+"_%03d"%retained.size()
	node.position = Vector3(at.x,terrain.height(at.x,at.z),at.z)
	node.rotation.y = yaw
	node.scale = Vector3.ONE
	nature.add_child(node)
	retained.append({"asset":id,"source_node":str(large.get_path_to(source)),"position":[node.position.x,node.position.y,node.position.z]})

func take(id: String,x: float,z: float,yaw: float = 0) -> void:
	for source: Node3D in stock.get(id,[]):
		if not used.has(source.get_instance_id()):
			add_existing(source,Vector3(x,0,z),deg_to_rad(yaw))
			return
	push_error("No unused existing prop available: "+id)

func reuse_props() -> void:
	nature = Node3D.new()
	nature.name = "RetainedProvisionalDressing"
	world.add_child(nature)
	for group: String in ["LightEnvironmentalFraming","ValleyPolish"]:
		for node: Node in large.get_node(group).get_children():
			if not node is Node3D or node.scene_file_path.is_empty(): continue
			var id := node.scene_file_path.get_file().get_basename()
			if not stock.has(id): stock[id] = []
			stock[id].append(node)
	var placed: Array[Vector2] = []
	for id: String in ["pine_windswept","pine_tiered"]:
		var kept := 0
		for source: Node3D in stock.get(id,[]):
			if kept>=16: break
			if source.position.z<170 or source.position.z>345: continue
			var q := Vector2(source.position.x*.36,103+(source.position.z-170)*.35)
			if terrain.near_route(q.x,q.y,4.5) or terrain.near_building(q.x,q.y,4): continue
			var close := false
			for p: Vector2 in placed:
				if q.distance_to(p)<5.5: close = true
			if close: continue
			add_existing(source,Vector3(q.x,0,q.y),source.rotation.y)
			placed.append(q)
			kept += 1
	for row: Array in [["pine_windswept",-29,85,210],["pine_windswept",30,87,30],["pine_tiered",-138,-49,45],["pine_windswept",46,-111,120],["pine_tiered",-69,-140,50],["pine_tiered",142,-60,250]]:
		take(row[0],row[1],row[2],row[3])
	for p: Vector2 in [Vector2(-8,97),Vector2(8,97),Vector2(-8,58),Vector2(8,58),Vector2(-16,-65),Vector2(40,-65)]: take("stone_lantern",p.x,p.y)
	take("sect_banner",-18,94)
	take("sect_banner",18,94,180)
	take("stone_bench",139,-46,90)
	take("stone_bench",-18,-57,90)
	take("training_dummy_rack",-126,17,10)
	for p: Vector2 in [Vector2(134,-59),Vector2(138,-57),Vector2(141,-55)]: take("bamboo_cluster",p.x,p.y,p.x*5)
	for p: Vector2 in [Vector2(68,23),Vector2(73,21),Vector2(-42,55)]: take("flowering_shrub",p.x,p.y,30)
	for p: Vector2 in [Vector2(-30,115),Vector2(28,128),Vector2(24,125),Vector2(-31,117),Vector2(26,127)]: take("grass_tuft",p.x,p.y,p.x*7)
	for p: Vector2 in [Vector2(-34,119),Vector2(31,111),Vector2(83,-34),Vector2(90,-45),Vector2(99,-42)]: take("rock_cluster",p.x,p.y,p.x*3)
	take("rock_outcrop",-43,127,20)
	take("rock_outcrop",148,-62,210)

func reuse_mountain_batches() -> int:
	var total := 0
	var selected := {}
	for node: Node in large.get_node("LightEnvironmentalFraming").get_children():
		if not node is MultiMeshInstance3D: continue
		var source: MultiMesh = node.multimesh
		var species := "tiered" if "tiered" in node.name else "windswept"
		if not selected.has(species):
			var ids: Array = []
			for i in source.instance_count:
				if ids.size()>=240: break
				var old := source.get_instance_transform(i)
				var x := old.origin.x*640.0/1120.0
				var z := old.origin.z*720.0/1120.0
				var h: float = terrain.height(x,z)
				if h<32 or h>155 or terrain.near_route(x,z,10) or terrain.near_building(x,z,10): continue
				ids.append(i)
			selected[species] = ids
			total += ids.size()
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = source.mesh
		mm.instance_count = selected[species].size()
		for j in mm.instance_count:
			var pose := source.get_instance_transform(selected[species][j])
			pose.origin.x *= 640.0/1120.0
			pose.origin.z *= 720.0/1120.0
			pose.origin.y = terrain.height(pose.origin.x,pose.origin.z)-.08
			mm.set_instance_transform(j,pose)
		var visual := MultiMeshInstance3D.new()
		visual.name = node.name
		visual.multimesh = mm
		ResourceSaver.save(mm,ROOT+"resources/"+node.name+".res")
		nature.add_child(visual)
	return total

func run() -> void:
	if DisplayServer.get_name()=="headless":
		printerr("Use a rendered run to retain the existing forest MultiMesh transforms.")
		quit(1)
		return
	layout = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"layout.json"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT+"resources"))
	world = Node3D.new()
	world.name = "CompactSplitCloudValley"
	world.set_script(load(ROOT+"valley_walkthrough.gd"))
	terrain = load(ROOT+"terrain_builder.gd").new()
	terrain.setup(layout)
	terrain.build(world)
	var buildings := Node3D.new()
	buildings.name = "Buildings"
	world.add_child(buildings)
	for b: Dictionary in layout.buildings:
		var node: Node3D = load(b.resource).instantiate()
		node.name = b.id
		node.position = vec(b.position)
		node.rotation_degrees.y = b.yaw
		buildings.add_child(node)
	large = load("res://mountain_valley/mountain_valley.tscn").instantiate()
	reuse_props()
	var mountain_pines := reuse_mountain_batches()
	var pond := MeshInstance3D.new()
	pond.name = "RepositionedExistingPond"
	pond.mesh = large.get_node("GardenPond_Blockout").mesh
	pond.material_override = large.get_node("GardenPond_Blockout").material_override
	pond.position = Vector3(layout.pond.center[0],layout.pond.water_y,layout.pond.center[1])
	pond.scale = Vector3(layout.pond.radius[0],1,layout.pond.radius[1])
	world.add_child(pond)
	var labels := Node3D.new()
	labels.name = "MapLabels"
	labels.visible = false
	world.add_child(labels)
	for b: Dictionary in layout.buildings:
		var label := Label3D.new()
		label.text = b.label+"\n+%d m"%b.position[1]
		label.position = vec(b.position)+Vector3(0,22,-3)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.font_size = 48
		label.pixel_size = .10
		label.outline_size = 8
		labels.add_child(label)
	own(world)
	var packed := PackedScene.new()
	var error := packed.pack(world)
	if error==OK: error = ResourceSaver.save(packed,ROOT+"compact_valley.tscn")
	var f := FileAccess.open(ROOT+"review/build-summary.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"save_error":error,"retained_prop_count":retained.size(),"retained_props":retained,"mountain_pines_repositioned":mountain_pines,"all_building_and_prop_scales":1,"terrain_triangles":terrain.vertices.size()/3,"main_route_metres":layout.main_route_metres},"\t"))
	print("Compact scene saved: ",error,"; retained props ",retained.size(),"; existing mountain pines ",mountain_pines)
	large.free()
	world.free()
	quit(0 if error==OK else 1)

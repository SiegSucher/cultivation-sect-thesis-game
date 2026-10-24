extends SceneTree
## Bake only the new map. Existing scenes are instanced, never saved or rebuilt.
const TERRAIN = preload("res://mountain_valley/terrain_builder.gd")
const ASSETS := "res://staging/claude_environment_batch1/"
var layout: Dictionary
var terrain: RefCounted
var world: Node3D
var nature: Node3D
var counts := {}
var rng := RandomNumberGenerator.new()

func _initialize() -> void: call_deferred("run")

func vec(a: Array) -> Vector3: return Vector3(a[0],a[1],a[2])

func own(node: Node) -> void:
	for child: Node in node.get_children():
		child.owner = world
		# Preserve inherited scene contents; only own the instance root.
		if child.scene_file_path.is_empty(): own(child)

func place(id: String, x: float, z: float, yaw: float = 0) -> void:
	var node: Node3D = load(ASSETS+id+"/"+id+".tscn").instantiate()
	counts[id] = counts.get(id,0)+1
	node.name = id+"_%03d"%counts[id]
	node.position = Vector3(x,terrain.height(x,z),z)
	node.rotation_degrees.y = yaw
	nature.add_child(node)

func source_meshes(node: Node3D, transform: Transform3D = Transform3D.IDENTITY) -> Array:
	var items: Array = []
	var local := transform*node.transform
	if node is MeshInstance3D and node.mesh: items.append([node.mesh,local])
	for child: Node in node.get_children():
		if child is Node3D: items.append_array(source_meshes(child,local))
	return items

func distant_pines() -> void:
	# Repeated original meshes are batched, with no new LOD or rescaled trees.
	# Mountain dressing is visual framing; nearby route trees use full .tscn collision.
	var points: Array[Transform3D] = []
	for i in 6500:
		if points.size()>=1250: break
		var x := rng.randf_range(-495,495)
		var z := rng.randf_range(-465,480)
		var h: float = terrain.height(x,z)
		if h<45 or h>190 or terrain.near_route(x,z,9) or terrain.near_building(x,z,10): continue
		var slope: float = maxf(absf(terrain.height(x+2,z)-h),absf(terrain.height(x,z+2)-h))
		if slope>2.0: continue
		points.append(Transform3D(Basis(Vector3.UP,rng.randf_range(0,TAU)),Vector3(x,h-.08,z)))
	for id: String in ["pine_tiered","pine_windswept"]:
		var source: Node3D = load(ASSETS+id+"/"+id+".glb").instantiate()
		var items := source_meshes(source)
		for i in items.size():
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = items[i][0]
			mm.instance_count = points.size()/2
			for j in mm.instance_count: mm.set_instance_transform(j,points[j*2+(0 if id=="pine_tiered" else 1)]*items[i][1])
			ResourceSaver.save(mm,"res://mountain_valley/resources/"+id+"_batch_%02d.res"%i)
			var visual := MultiMeshInstance3D.new()
			visual.name = "Mountain_"+id+"_%02d"%i
			visual.multimesh = mm
			nature.add_child(visual)
		source.free()
	counts["mountain_pines_batched"] = points.size()

func run() -> void:
	if DisplayServer.get_name()=="headless":
		printerr("Use a rendered Godot run to bake MultiMesh transforms; the headless renderer discards them.")
		quit(1)
		return
	layout = JSON.parse_string(FileAccess.get_file_as_string("res://mountain_valley/layout.json"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://mountain_valley/resources"))
	world = Node3D.new()
	world.name = "SplitCloudMountainValley"
	world.set_script(load("res://mountain_valley/valley_walkthrough.gd"))
	terrain = TERRAIN.new()
	terrain.setup(layout)
	terrain.build(world)
	var buildings := Node3D.new()
	buildings.name = "Buildings"
	world.add_child(buildings)
	for b: Dictionary in layout.buildings:
		var instance: Node3D = load(b.resource).instantiate()
		instance.name = b.id
		instance.position = vec(b.position)
		instance.rotation_degrees.y = b.yaw
		buildings.add_child(instance)
	nature = Node3D.new()
	nature.name = "LightEnvironmentalFraming"
	world.add_child(nature)
	rng.seed = 240026
	# Sparse route framing; not a full district decoration pass.
	for i in 160:
		var x := rng.randf_range(-106,94)
		var z := rng.randf_range(171,340)
		if terrain.near_route(x,z,7): continue
		place("pine_windswept" if i%3==0 else "pine_tiered",x,z,rng.randf_range(0,360))
	for x in range(-200,221,24):
		for z in [-106,-236]:
			if not terrain.near_route(x,z,9) and not terrain.near_building(x,z,9): place("pine_tiered",x,z,rng.randf_range(0,360))
	for x: float in [-19,19]:
		place("sect_banner",x,146,0 if x<0 else 180)
		place("stone_lantern",x,110)
		place("stone_lantern",x,-156)
	for at: Vector2 in [Vector2(-83,238),Vector2(-37,195),Vector2(53,263),Vector2(190,-95),Vector2(207,-38),Vector2(-190,-100)]:
		place("rock_outcrop",at.x,at.y,rng.randf_range(0,360))
	for at: Vector2 in [Vector2(134,-74),Vector2(143,-85),Vector2(156,-79),Vector2(147,-58),Vector2(-39,215),Vector2(33,177)]:
		place("rock_cluster",at.x,at.y,rng.randf_range(0,360))
	for i in 10: place("bamboo_cluster",188+rng.randf_range(-5,7),-103+rng.randf_range(-4,10),rng.randf_range(0,360))
	for i in 9:
		place("flowering_shrub",142+rng.randf_range(-3,10),-8+rng.randf_range(-2,8),rng.randf_range(0,360))
		place("grass_tuft",-82+rng.randf_range(-4,7),242+rng.randf_range(-7,10),rng.randf_range(0,360))
	place("stone_bench",203,-83,90)
	place("stone_bench",-55,-119,0)
	place("training_dummy_rack",-187,-8,12)
	var polish = load("res://mountain_valley/environment_polish.gd").new()
	polish.build(world,terrain,layout)
	distant_pines()
	# A calm opaque blockout pond. The terrain below remains shallow and continuous.
	var water := MeshInstance3D.new()
	water.name = "GardenPond_Blockout"
	var disk := CylinderMesh.new()
	disk.top_radius = 1
	disk.bottom_radius = 1
	disk.height = .06
	disk.radial_segments = 28
	water.mesh = disk
	water.position = Vector3(layout.pond.center[0],layout.pond.water_y,layout.pond.center[1])
	water.scale = Vector3(layout.pond.radius[0],1,layout.pond.radius[1])
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("3e7378")
	mat.roughness = .85
	water.material_override = mat
	world.add_child(water)
	var labels := Node3D.new()
	labels.name = "MapLabels"
	labels.visible = false
	world.add_child(labels)
	for b: Dictionary in layout.buildings:
		var label := Label3D.new()
		label.name = b.id+"_MapLabel"
		label.text = b.label+"\n+%d m"%b.position[1]
		label.position = vec(b.position)+Vector3(0,25,-5)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.font_size = 48
		label.pixel_size = .12
		label.outline_size = 8
		labels.add_child(label)
	own(world)
	var packed := PackedScene.new()
	var error := packed.pack(world)
	if error==OK: error = ResourceSaver.save(packed,"res://mountain_valley/mountain_valley.tscn")
	var report := FileAccess.open("res://reports/mountain-valley/build-summary.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"save_error":error,"environment_counts":counts,"buildings":12,"terrain_triangles":terrain.vertices.size()/3},"\t"))
	print("Map save: ",error," / nature ",counts)
	world.free()
	quit(0 if error==OK else 1)

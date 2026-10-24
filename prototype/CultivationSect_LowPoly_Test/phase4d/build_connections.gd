extends SceneTree
## Local surface connections only. No terrain, stairs, kit or architecture builder.
const OUT := "res://phase4d/"
var vertices := PackedVector3Array()
var normals := PackedVector3Array()
var colors := PackedColorArray()
func _initialize() -> void: call_deferred("run")
func tri(a: Vector3,b: Vector3,c: Vector3,color: Color) -> void:
	var n := (b-a).cross(c-a).normalized()
	# Godot uses clockwise front faces; retain the outward normal above.
	for p: Vector3 in [a,c,b]:
		vertices.append(p)
		normals.append(n)
		colors.append(color)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT+"resources"))
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://mountain_valley_compact/layout.json"))
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string(OUT+"entrances.json"))
	var terrain_mesh: ArrayMesh = load("res://phase4c/resources/terrain_mesh.res")
	var sampler = load("res://phase4c/terrain_sampler.gd").new()
	sampler.setup(terrain_mesh.get_faces())
	var records: Array = []
	var total_area := 0.0
	for row: Dictionary in rows:
		if row.apron==null: continue
		var building: Dictionary
		for b: Dictionary in layout.buildings:
			if b.id==row.id: building = b
		var pose := Transform3D(Basis(Vector3.UP,deg_to_rad(building.yaw)),Vector3(building.position[0],building.position[1],building.position[2]))
		var p: Dictionary = row.apron
		var corners: Array[Vector3] = [
			pose*Vector3(-p.width_outer*.5,.04,p.outer),pose*Vector3(p.width_outer*.5,.04,p.outer),
			pose*Vector3(p.width_inner*.5,.04,p.inner),pose*Vector3(-p.width_inner*.5,.04,p.inner)]
		var color := Color("817966") if p.style=="earth" else Color("7e867b")
		var bottoms: Array[Vector3] = []
		for corner: Vector3 in corners:
			bottoms.append(Vector3(corner.x,minf(sampler.height(corner.x,corner.z)-.02,corner.y-.06),corner.z))
		# Same surface convention as approved paving/courts. A short buried edge
		# meets the existing support ground; no collision or walking ramp is added.
		tri(corners[0],corners[1],corners[2],color)
		tri(corners[0],corners[2],corners[3],color)
		for i in 4:
			var a := corners[i]
			var b := corners[(i+1)%4]
			var c := bottoms[(i+1)%4]
			var d := bottoms[i]
			tri(a,d,c,color.darkened(.08))
			tri(a,c,b,color.darkened(.08))
		var area: float = (p.outer-p.inner)*(p.width_outer+p.width_inner)*.5
		total_area += area
		records.append({"building":row.id,"style":p.style,"length_m":p.outer-p.inner,"outer_width_m":p.width_outer,"inner_width_m":p.width_inner,"area_m2":area,"local_bounds":[-maxf(p.width_outer,p.width_inner)*.5,p.inner,maxf(p.width_outer,p.width_inner)*.5,p.outer],"world_top_corners":corners})
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	# Reuse the approved ground material, including its vertex-color convention.
	var existing: ArrayMesh = load("res://phase4c/resources/paths_mesh.res")
	mesh.surface_set_material(0,existing.surface_get_material(0))
	assert(ResourceSaver.save(mesh,OUT+"resources/entrance_surfaces.res")==OK)
	var geometry := Node3D.new()
	geometry.name = "DistrictEntranceConnections"
	var surface := MeshInstance3D.new()
	surface.name = "LocalGroundTransitions"
	surface.mesh = mesh
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	geometry.add_child(surface)
	surface.owner = geometry
	var packed := PackedScene.new()
	assert(packed.pack(geometry)==OK)
	assert(ResourceSaver.save(packed,OUT+"resources/entrance_connections.tscn")==OK)
	var f := FileAccess.open(OUT+"review/build-summary.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"connections":records,"total_area_m2":total_area,"terrain_rebuilt":false,"new_collision_shapes":0,"architecture_inherited":true},"\t"))
	geometry.free()
	print("Saved ",records.size()," local entrance connections, ",total_area," square metres; inherited ground collision unchanged.")
	quit()

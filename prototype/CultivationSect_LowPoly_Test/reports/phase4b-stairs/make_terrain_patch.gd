extends SceneTree
## Generate only corrected terrain resources. Never re-save the full scene or
## its MultiMeshes: headless rendering does not retain their instance buffers.
const OUT := "res://reports/phase4b-stairs/"
func _initialize() -> void: call_deferred("run")

func run() -> void:
	var scene: Node3D = load("res://mountain_valley/mountain_valley.tscn").instantiate()
	var ground: MeshInstance3D = scene.get_node("ContinuousValleyTerrain")
	var original: ArrayMesh = ground.mesh
	var arrays: Array = original.surface_get_arrays(0)
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://mountain_valley/layout.json"))
	var fitter = load("res://mountain_valley/focused_stair_terrain.gd").new()
	var fitted: Dictionary = fitter.apply(arrays[Mesh.ARRAY_VERTEX],arrays[Mesh.ARRAY_NORMAL],arrays[Mesh.ARRAY_COLOR],layout)
	var mesh := ArrayMesh.new()
	var result := []
	result.resize(Mesh.ARRAY_MAX)
	result[Mesh.ARRAY_VERTEX] = fitted.vertices
	result[Mesh.ARRAY_NORMAL] = fitted.normals
	result[Mesh.ARRAY_COLOR] = fitted.colors
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,result)
	mesh.surface_set_material(0,original.surface_get_material(0).duplicate())
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(fitted.vertices)
	shape.backface_collision = true
	assert(ResourceSaver.save(mesh,OUT+"patched-terrain.tres")==OK)
	assert(ResourceSaver.save(shape,OUT+"patched-collision.tres")==OK)
	assert(ResourceSaver.save(mesh,OUT+"terrain_mesh.res")==OK)
	assert(ResourceSaver.save(shape,OUT+"terrain_collision.res")==OK)
	var f := FileAccess.open(OUT+"terrain-patch.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"original_triangles":arrays[Mesh.ARRAY_VERTEX].size()/3,"final_triangles":fitted.vertices.size()/3,"refined_original_triangles":fitted.refined_original_triangles,"lowered_vertex_occurrences":fitted.lowered_vertex_occurrences},"\t"))
	print("Terrain patch: ",fitted.refined_original_triangles," triangles refined; ",fitted.lowered_vertex_occurrences," vertex occurrences lowered")
	scene.free()
	quit()

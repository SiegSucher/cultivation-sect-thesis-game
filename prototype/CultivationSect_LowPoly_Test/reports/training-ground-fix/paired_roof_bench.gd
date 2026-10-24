extends "res://reports/training-ground-fix/bench.gd"
## Same process/scene/materials, alternating only the roof shape outside warmup.
func run() -> void:
	root.size=Vector2i(1280,720)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED);Engine.max_fps=0
	stage=Node3D.new();stage.set_script(load("res://scripts/training_walkthrough.gd"));stage.automated=true;root.add_child(stage)
	stage.player.indoor_camera_enabled=false
	review=Camera3D.new();stage.add_child(review)
	gpu_timing=true;RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	var shapes: Array[PackedVector3Array]=[]
	for path: String in ["res://reports/training-ground-fix/before/martial_training_ground.json.txt","res://reports/training-ground-fix/candidate-training-roof.json"]:
		var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
		var faces:=PackedVector3Array()
		for p: Array in data.roof_collision_faces:faces.append(Vector3(p[0],p[1],p[2]))
		shapes.append(faces)
	await frames(120)
	for view: Array in [["overview",Vector3(48,38,50),Vector3(0,1,-1),52.0],["court",Vector3(0,2.1,25),Vector3(0,2.3,-20),78.0],["shelter",Vector3(12,5.3,-8.5),Vector3(0,2.8,-22),68.0]]:
		suffix="-paired";variant="after"
		await pose(view[0],view[1],view[2],view[3])
		var order: Array[int]=[0,1,1,0,1,0,0,1]
		for i in order.size():
			stage.facility.get_node("AuthoredStructureCollision/StaticRoofUndersides").shape.set_faces(shapes[order[i]])
			await physics_frame;await physics_frame
			label="paired-"+view[0]+"-"+str(i)
			await sample(view[0])
			samples[-1]["roof_faces"]=4560 if order[i]==0 else 4476
			samples[-1]["block"]=i
	FileAccess.open(OUT+"paired-roof-results.json",FileAccess.WRITE).store_string(JSON.stringify({"samples":samples,"captures":captures,"failed":captures.filter(func(c):return not c.pass).size(),"conditions":"Same live converted scene, old/clean/clean/old/clean/old/old/clean per view, same 45 warmup and 240 measured frames. Only roof faces switched outside timing; no scene/material reload."},"  "))
	print("Paired roof: ",samples.size()," same-process blocks")
	quit()

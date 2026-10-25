extends SceneTree
func _initialize() -> void: run()
func run() -> void:
	var demo: Node3D = load("res://proposal_demo_living_sect/proposal_demo.tscn").instantiate()
	root.add_child(demo)
	current_scene = demo
	for i in 30: await physics_frame
	print("LIVING SMOKE residents=",demo.living.residents.size()," walls=",demo.living.walls.sections.size())
	quit()

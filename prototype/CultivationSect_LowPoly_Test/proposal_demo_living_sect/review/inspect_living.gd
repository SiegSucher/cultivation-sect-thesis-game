extends SceneTree
func _initialize() -> void: run()
func run() -> void:
	var d: Node3D = load("res://proposal_demo_living_sect/proposal_demo.tscn").instantiate()
	root.add_child(d)
	current_scene = d
	for i in 120: await physics_frame
	for n in d.living.residents: print(n.display_name," POS ",n.position," FLOOR ",n.is_on_floor()," TERRAIN ",d.living.ground(n.position))
	for at: Vector3 in [Vector3(-12,10,53),Vector3(-12,10,29),Vector3(25,10,33.5),Vector3(20,10,53)]: print("SPACE ",at," GROUND ",d.living.ground(at))
	quit()

from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
HERE=Path(__file__).resolve().parent
t=(ROOT/'mountain_valley_compact/review/check_compact.gd').read_text(encoding='utf-8')
t=t.replace('const ROOT := "res://mountain_valley_compact/"','const ROOT := "res://phase4c/"')
t=t.replace('var checks: Array = []','var checks: Array = []\nvar before := false')
t=t.replace('scene = load(ROOT+"compact_valley.tscn").instantiate()', '''before = "--before" in OS.get_cmdline_user_args()
	scene = load("res://mountain_valley_compact/compact_valley.tscn" if before else ROOT+"phase4c_valley.tscn").instantiate()''')
start=t.index('\t\tawait walk_to(Vector3(12,24,-58))',t.index('if headless:'))
end=t.index('\n\telse:',start)
t=t[:start]+'''		await walk_to(Vector3(12,24,-58))
		await follow("scholar")
		await follow("library")
		await follow("library",true)
		await follow("scholar",true)
		await walk_to(Vector3(12,24,-47))
		await follow("grand",true)
		await walk_to(Vector3(12,16,-24))
		await follow("alchemy")
		await follow("alchemy",true)
		await walk_to(Vector3(12,16,-29))
		await follow("cloud",true)
		await walk_to(Vector3(0,10,35))
		await walk_to(Vector3(65,10,35))
		await follow("garden")
		await follow("garden",true)
		await walk_to(Vector3(-44,10,35))
		await follow("training_link")
		await follow("training_entry")
		await stairs()
		await guard_tests()
''' + t[end:]
start=t.index('\t\t# Rendered checks use ordinary')
end=t.index('\n\tplayer.automated = false',start)
t=t[:start]+'''		if not before:
			scene.jump_to(Vector3(0,4.12,69),0)
			check("Rendered living stair up TPP",await walk_to(Vector3(0,10,46)))
			player.third_person = false
			check("Rendered living stair down FPP",await walk_to(Vector3(0,4,69)))
			player.third_person = true
		for view: Array in [["gate-approach",Vector3(-9.8,.12,112),-.30],["living-terrace",Vector3(0,10.12,42),0.0],["inner-stairs",Vector3(0,10.12,9),0.0],["hall-approach",Vector3(12,24.12,-49),0.0]]:
			scene.jump_to(view[1],view[2])
			await frames(12)
			await shot(view[0])
		scene.valley_view()
		await shot("valley-overview")
		if not before:
			scene.jump_to(Vector3(143,10.12,-46),PI/2)
			await frames(12)
			await shot("guarded-overlook")
''' + t[end:]
t=t.replace('ROOT+"review/"+name+".png"','ROOT+"review/"+("before-" if before else "after-")+name+".png"')
t=t.replace('("walking-results.json" if headless else "rendered-results.json")','("walking-results.json" if headless else ("before-rendered.json" if before else "rendered-results.json"))')
t=t.replace('print("COMPACT ",','print("PHASE4C ",')
new='''
func guard_probe(label: String, at: Vector3, outward: Vector3) -> void:
	scene.jump_to(at+Vector3.UP*.12)
	await frames(10)
	var origin: Vector3 = player.position
	var maximum := -1000.0
	var collider := ""
	player.drive = outward
	for i in 100:
		await physics_frame
		maximum = maxf(maximum,(player.position-origin).dot(outward))
		for j in player.get_slide_collision_count():
			var node: Object = player.get_slide_collision(j).get_collider()
			if node is Node and "SelectiveTerrainSupports" in str(node.get_path()): collider = str(node.get_path())
	player.drive = Vector3.ZERO
	check("Guard blocks outward travel: "+label,maximum>1.0 and maximum<2.1 and not collider.is_empty(),{"outward_metres":maximum,"collider":collider})

func guard_tests() -> void:
	await guard_probe("Hall retaining edge",Vector3(-12,24,-46.18),Vector3.BACK)
	await guard_probe("Living retaining edge",Vector3(32,10,65.82),Vector3.BACK)
	await guard_probe("Overlook east",Vector3(146.82,10,-45.82),Vector3.RIGHT)
	await guard_probe("Living stair side",Vector3(4.35,7,57.5),Vector3.RIGHT)
	await guard_probe("Hall stair side",Vector3(5.65,20,-38),Vector3.LEFT)
'''
t += new
(HERE/'review/check_terrain.gd').write_text(t,encoding='utf-8')
print('Prepared focused Phase 4C traversal and matching capture fixture')

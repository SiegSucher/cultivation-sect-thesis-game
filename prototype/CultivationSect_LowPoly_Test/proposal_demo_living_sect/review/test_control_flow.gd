extends SceneTree
const Lessons := preload("res://proposal_demo_living_sect/lessons.gd")
const Runner := preload("res://proposal_demo_living_sect/code_runner.gd")
var checks := 0
var failures := 0

func check(label: String, ok: bool, detail = null) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+label+("" if ok else " / "+str(detail)))

func _initialize() -> void:
	var runner := Runner.new()
	for lang: String in Lessons.ORDER:
		var data := Lessons.for_language(lang)
		var py := lang == "python"
		var java := lang == "java"
		var bridge := "Sect.unsealBridge();" if java else ("unseal_bridge()" if py else "unseal_bridge();")
		var pulse := "Sect.pulseWard();" if java else ("pulse_ward()" if py else "pulse_ward();")
		var cases := [
			[3, data.solution[2], true, "", 1],
			[3, data.solution[2].replace("charge == 3", "charge == 2"), true, "", 0],
			[3, bridge, false, "bridge_guard", 0],
			[3, data.solution[2].replace("seal_charge()", "3").replace("Sect.sealCharge()", "3"), false, "bridge_guard", 0],
			[3, data.solution[2].replace("seal_charge()", "qi_reserve()").replace("Sect.sealCharge()", "Sect.qiReserve()"), false, "bridge_guard", 0],
			[4, data.solution[3], true, "", 3],
			[4, data.solution[3].replace("range(3)", "range(2)").replace("seal < 3", "seal < 2"), false, "ward_count", 0],
			[4, data.solution[3].replace("range(3)", "range(4)").replace("seal < 3", "seal < 4"), false, "ward_count", 0],
			[4, data.solution[3].replace("range(3)", "range(0)").replace("seal < 3", "seal < 0"), true, "", 0],
			[4, pulse+"\n"+pulse+"\n"+pulse, false, "ward_loop", 0],
			[3, data.solution[3], false, "quest_order", 0],
			[4, "basin_water()" if py else "Sect.basinWater();" if java else "basin_water();", false, "", 0],
		]
		for index in cases.size():
			var item: Array = cases[index]
			var result: Dictionary = runner.run(lang, item[0], item[1], "control", 0, 3)
			var effect: int = result.effects.bridge if item[0] == 3 else result.effects.ward
			check(lang+" control case "+str(index+1), result.ok == item[2] and (result.fail.get("kind", "") == item[3] if item[3] != "" else true) and (effect == item[4] if result.ok else true), result)
		# Every teaching example should run without solving a quest; signatures are labelled references.
		for stage in [3, 4]:
			for card: Array in data.cards[stage-1]:
				var result: Dictionary = runner.run(lang, stage, card[2], "example", 0, 3)
				check(lang+" lesson / "+card[0], not result.ok if card.size() > 3 else (result.ok and result.effects.bridge == 0 and result.effects.ward == 0), result)
		var stuck := "for count in range(17):\n    value = 1" if py else "for (int count = 0; count < 2; count = count) {\n    int value = 1;\n}"
		var result: Dictionary = runner.run(lang, 4, stuck, "limit", 0, 3)
		check(lang+" bad loop is bounded", not result.ok and result.fail.category == "limit", result)
		var broken: String = data.solution[2].replace(":", "") if py else data.solution[2].replace("}", "")
		result = runner.run(lang, 3, broken, "syntax", 0, 3)
		check(lang+" missing block punctuation is reported", not result.ok and result.fail.category == "language", result)
		if not py:
			var printer := "System.out.println(count);" if java else "printf(\"%d\", count);"
			result = runner.run(lang, 4, "for (int count = 0; count < 1; count = count + 1) {}\n"+printer, "scope", 0, 3)
			check(lang+" for counter does not leak from its scope", not result.ok and result.fail.kind == "undeclared", result)
	# Python dedents resume the outer block; incorrect indentation reports a readable error.
	var result: Dictionary = runner.run("python", 3, "value = 0\nif value == 1:\n    value = 9\nprint(value)", "dedent", 0, 3)
	check("Python false body is skipped and dedent continues", result.ok and result.output[0][1] == "0", result)
	result = runner.run("python", 4, "for i in range(2):\n    for j in range(2):\n        print(i + j)", "nested", 0, 3)
	check("nested Python loops execute their bodies", result.ok and result.output.size() == 4, result)
	result = runner.run("java", 3, "if (3) { Sect.unsealBridge(); }", "type", 0, 3)
	check("Java condition must be boolean", not result.ok and result.fail.kind == "type_mismatch", result)
	result = runner.run("python", 4, "for if in range(3):\n    pulse_ward()", "keyword", 0, 3)
	check("Python keywords cannot be loop variables", not result.ok and result.fail.kind == "syntax", result)
	var out := "res://proposal_demo_living_sect/review/main-control-flow.json"
	FileAccess.open(out, FileAccess.WRITE).store_string(JSON.stringify({"checks": checks, "failures": failures}, "  "))
	print("CONTROL FLOW: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

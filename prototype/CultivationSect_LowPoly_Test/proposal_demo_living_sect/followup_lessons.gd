extends RefCounted
## The next main-story arc teaches decisions and repetition through two different world problems.
static func append_to(lesson: Dictionary, language: String) -> Dictionary:
	var data := lesson.duplicate(true)
	var py := language == "python"
	var java := language == "java"
	var charge := "Sect.sealCharge()" if java else "seal_charge()"
	var bridge := "Sect.unsealBridge()" if java else "unseal_bridge()"
	var pulse := "Sect.pulseWard()" if java else "pulse_ward()"
	var solutions := [
		"charge = "+charge+"\nif charge == 3:\n    "+bridge if py else "int charge = "+charge+";\nif (charge == 3) {\n    "+bridge+";\n}",
		"for seal in range(3):\n    "+pulse if py else "for (int seal = 0; seal < 3; seal = seal + 1) {\n    "+pulse+";\n}"
	]
	var decision := "steps = 2\nif steps == 2:\n    print(steps)" if py else ("int steps = 2;\nif (steps == 2) {\n    System.out.println(steps);\n}" if java else "int steps = 2;\nif (steps == 2) {\n    printf(\"%d\\n\", steps);\n}")
	var repetition := "for count in range(2):\n    print(count)" if py else ("for (int count = 0; count < 2; count = count + 1) {\n    System.out.println(count);\n}" if java else "for (int count = 0; count < 2; count = count + 1) {\n    printf(\"%d\\n\", count);\n}")
	data.files.append_array(["Crossing.java", "Ward.java"] if java else (["crossing.py", "ward.py"] if py else ["crossing.c", "ward.c"]))
	for i in 2:
		var header: Array = data.header[1].duplicate()
		if java: header[1] = "public class "+(["Crossing", "Ward"][i])+" {"
		data.header.append(header)
		data.footer.append(data.footer[1].duplicate())
		data.starter.append(("# " if py else "// ")+["Verify the seal before opening the crossing", "Repeat a pulse for each of the three ward stones"][i]+"\n")
	data.keywords.append_array(["if", "for", "in", "range"] if py else ["if", "for"])
	data.cards.append([
		["The Silent Crossing / a decision", "The awakened basin has sent a signal to an old shrine. Its crossing is sealed. Read the seal charge, then release the crossing only when that reading equals 3. An if statement runs its body only when its condition is true.", decision],
		["Assignment and comparison", "A single = stores a value. A double == compares values. Read the actual charge from "+charge+". A false condition skips the body and leaves the crossing closed.", "charge = "+charge if py else "int charge = "+charge+";"],
		["Put the action inside the condition", ("End the if line with a colon. Indent the action by four spaces on the next line. This makes it part of the condition." if py else "Put the condition in parentheses and its body inside { }. Statements inside the braces end with semicolons.")+" The game's release command is "+bridge+".", bridge+("" if py else ";"), "signature"]
	])
	data.cards.append([
		["The Threefold Ward / repetition", "Beyond the crossing, three dormant stones protect the sect from the night mist. A for loop repeats its body. Prepare one ward pulse per repetition, for three repetitions. Copying the command three times does not repair this repeating inscription.", repetition],
		["Know when to stop", "range(3) produces 0, 1 and 2: exactly three repetitions. The endpoint 3 is not included. Keep the pulse indented inside the loop." if py else "The counter starts at 0. Before each repetition, seal < 3 is checked. The update seal = seal + 1 happens after the body. The body runs for 0, 1 and 2, then stops at 3.", repetition],
		["The ward pulse", pulse+" is supplied by the game. It prepares the next ward stone. Too few or too many pulses leave the whole ward unchanged. After a successful run, Continue brings the stones and protective veil to life.", pulse+("" if py else ";"), "signature"]
	])
	data.hints.append(["Read the actual charge. Test it against 3 with an if condition. Put the release command inside that conditional body.", "Store "+charge+" in charge. Test charge == 3. Inside that block, call "+bridge+". "+("Use a colon and indentation." if py else "Use parentheses and braces.")])
	data.hints.append(["Repeat the pulse once for each of three ward stones. Stop the loop after exactly three repetitions.", "Use for seal in range(3): and indent "+pulse+" below it." if py else "Use for (int seal = 0; seal < 3; seal = seal + 1) and put "+pulse+"; inside its braces."])
	data.solution.append_array(solutions)
	data.reference = data.reference.get_slice("THIS LEARNING INTERPRETER", 0)
	data.reference += "MAIN QUESTS 3 / 4: GAME COMMANDS\n  "+charge+"  returns the crossing seal's charge (3)\n  "+bridge+"  release it inside a true condition based on that reading\n  "+pulse+"  prepare the next ward stone inside a for loop\n\nCONTROL FLOW (main quests 3/4)\n  if: run a block only when its condition is true\n  == compares; = assigns; < means less than\n  "+("for name in range(count): repeats for 0 up to count - 1\n  Indent every statement in a body consistently." if py else "for (int i = 0; i < count; i = i + 1) repeats a braced body\n  Use assignment for the update; ++ is outside this subset.")+"\n\nLEARNING INTERPRETER LIMITS\n  Early lessons: assignments, calls, + - * and ==.\n  Main quests add if blocks and for loops (range(count) in Python).\n  At most 16 iterations per loop, 8 nested blocks, 256 executed statements.\n  No else, while, functions, arrays, decimals, division or general libraries."
	return data

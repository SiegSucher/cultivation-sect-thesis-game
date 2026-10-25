extends SceneTree
## Table test for the sect's learning interpreter (no scene needed).
## godot --headless --path . --script res://proposal_demo_living_sect/review/test_code_runner.gd -- <out.json>
const Runner := preload("res://proposal_demo_living_sect/code_runner.gd")
const Lessons := preload("res://proposal_demo_living_sect/lessons.gd")
# [language, stage, code, reserve, expected failure kind ("" = runs cleanly), expected effect, text that must appear in the message or output]
const CASES := [
	["python", 1, "qi = 3\nawaken(qi)", 0, "", "awaken"],
	["python", 1, "# comment\nqi = 3   # store\nawaken(qi)\nprint(qi)", 0, "", "awaken"],
	["python", 1, "qi = 3; awaken(qi)", 0, "", "awaken"],
	["python", 1, "awaken(qi)\nqi = 3", 0, "name_error", ""],
	["python", 1, "int qi = 3\nawaken(qi)", 0, "python_type", ""],
	["python", 1, "qi == 3\nawaken(qi)", 0, "name_error", ""],
	["python", 1, "  qi = 3\nawaken(qi)", 0, "indent", ""],
	["python", 1, "qi = 3\nawaken qi", 0, "call_syntax", ""],
	["python", 1, "qi = 3\nawake(qi)", 0, "unknown", ""],
	["python", 1, "qi = 5\nawaken(qi)", 0, "wrong_amount", ""],
	["python", 1, "qi = 3\nawaken()", 0, "arity", ""],
	["python", 1, "qi = \"3\"\nawaken(qi)", 0, "awaken_type", ""],
	["python", 1, "qi = 3\nawaken(qi", 0, "syntax", ""],
	["python", 1, "awaken(3)", 0, "literal_arg", ""],
	["python", 2, "channel_basin(3)", 3, "literal_channel", ""],
	["java", 2, "Sect.channelBasin(3);", 3, "literal_channel", ""],
	["python", 2, "reserve = qi_reserve()\nchannel_basin(reserve)", 3, "", "channel"],
	["python", 2, "channel_basin(qi_reserve())", 3, "", "channel"],
	["python", 2, "channel_basin(5)", 3, "not_enough", ""],
	["python", 2, "reserve = qi_reserve()\nchannel_basin(reserve - 1)", 3, "too_small", ""],
	["python", 2, "channel_basin(reserve)", 3, "name_error", ""],
	["python", 1, "qi = 3\nchannel_basin(qi)", 0, "not_awake", ""],
	["c", 1, "int qi = 3;\nawaken(qi);", 0, "", "awaken"],
	["c", 1, "/* note */\nint qi = 3;   // store\nawaken(qi);\nprintf(\"%d\\n\", qi);", 0, "", "awaken"],
	["c", 1, "int qi;\nqi = 3;\nawaken(qi);", 0, "", "awaken"],
	["c", 1, "qi = 3;\nawaken(qi);", 0, "undeclared", ""],
	["c", 1, "int qi;\nawaken(qi);", 0, "uninitialized", ""],
	["c", 1, "int qi = 3\nawaken(qi);", 0, "semicolon", ""],
	["c", 1, "int qi = 3;\nawaken(qi)", 0, "semicolon", ""],
	["c", 1, "qi = 3\nawaken(qi)", 0, "semicolon", ""],
	["c", 1, "int qi = 3;\nAwaken(qi);", 0, "unknown", ""],
	["c", 1, "double qi = 3;\nawaken(qi);", 0, "type", ""],
	["c", 1, "int qi = 3;\nint qi = 3;\nawaken(qi);", 0, "redeclared", ""],
	["c", 1, "int main(void) {\nint qi = 3;", 0, "structure", ""],
	["c", 2, "int reserve = qi_reserve();\nchannel_basin(reserve);", 3, "", "channel"],
	["c", 2, "int reserve = qi_reserve();\nchannel_basin(reserve + 1);", 3, "not_enough", ""],
	["java", 1, "int qi = 3;\nSect.awaken(qi);", 0, "", "awaken"],
	["java", 1, "int qi = 3;\nSystem.out.println(\"Qi: \" + qi);\nSect.awaken(qi);", 0, "", "awaken", "Qi: 3"],
	["java", 1, "int qi;\nSect.awaken(qi);", 0, "uninitialized", ""],
	["java", 1, "qi = 3;\nSect.awaken(qi);", 0, "undeclared", ""],
	["java", 1, "int qi = 3;\nawaken(qi);", 0, "unknown", ""],
	["java", 1, "int qi = 3\nSect.awaken(qi);", 0, "semicolon", ""],
	["java", 1, "String qi = \"3\";\nSect.awaken(qi);", 0, "type", ""],
	["java", 2, "int reserve = Sect.qiReserve();\nSect.channelBasin(reserve);", 3, "", "channel"],
	["java", 2, "Sect.channelBasin(Sect.qiReserve());", 3, "", "channel"],
	["java", 2, "int reserve = Sect.qiReserve();\nSect.awaken(reserve);", 3, "already_awake", ""],
	# Equivalent arithmetic solutions.
	["python", 1, "qi = 1 + 2\nawaken(qi)", 0, "", "awaken"],
	["c", 1, "int qi = 1 + 2;\nawaken(qi);", 0, "", "awaken"],
	["java", 1, "int qi = 1 + 2;\nSect.awaken(qi);", 0, "", "awaken"],
	["python", 2, "reserve = qi_reserve()\nchannel_basin(reserve * 1)", 3, "", "channel"],
	["c", 2, "int reserve = qi_reserve();\nint amount = reserve - 0;\nchannel_basin(amount);", 3, "", "channel"],
	["java", 2, "int reserve = Sect.qiReserve() + 0;\nSect.channelBasin(reserve);", 3, "", "channel"],
	# Changed values give changed results.
	["python", 1, "qi = 2 + 2\nawaken(qi)", 0, "wrong_amount", "", "and 4 was passed"],
	["c", 1, "int qi = 7 - 3;\nawaken(qi);", 0, "wrong_amount", "", "and 4 was passed"],
	["java", 1, "int qi = 2 * 3;\nSect.awaken(qi);", 0, "wrong_amount", "", "and 6 was passed"],
	["python", 1, "qi = 3\nprint(qi * 2)\nawaken(qi)", 0, "", "awaken", "\n6\n"],
	["c", 1, "int qi = 3;\nprintf(\"%d\\n\", qi + 4);\nawaken(qi);", 0, "", "awaken", "\n7\n"],
	["java", 1, "int qi = 3;\nSystem.out.println(qi - 1);\nSect.awaken(qi);", 0, "", "awaken", "\n2\n"],
	["python", 2, "reserve = qi_reserve()\nchannel_basin(reserve - 1)", 3, "too_small", "", "2 is not enough"],
	["c", 2, "int reserve = qi_reserve();\nchannel_basin(reserve + 2);", 3, "not_enough", "", "tried to channel 5"],
	["java", 1, "System.out.print(\"Qi \");\nSystem.out.println(1 + 2);", 0, "", "", "\nQi 3\n"],
	# Valid language syntax that only breaks a lesson rule.
	["java", 1, "double qi = 3;\nSect.awaken(qi);", 0, "type", "", "Valid Java, but"],
	["c", 1, "awaken(3);", 0, "literal_arg", "", "Valid C, but"],
	["c", 2, "channel_basin(3);", 3, "literal_channel", "", "Valid C, but"],
	["python", 1, "awaken(1 + 2)", 0, "literal_arg", "", "Valid Python, but"],
	# Real language errors that the real tools would also report.
	["java", 1, "int qi = true;\nSect.awaken(qi);", 0, "type_mismatch", "", "boolean cannot be converted to int"],
	["c", 1, "int qi = 3;\nint r = awaken(qi);", 0, "type_mismatch", "", "void value not ignored"],
	["java", 1, "int qi = 3;\nint r = Sect.awaken(qi);", 0, "type_mismatch", "", "void cannot be converted to int"],
	["java", 1, "Sect.awaken(\"3\");", 0, "type_mismatch", "", "String cannot be converted to int"],
	["java", 1, "int qi = 3;\nqi == 3;\nSect.awaken(qi);", 0, "not_statement", ""],
	["java", 1, "int qi = 3;\nqi.foo();", 0, "type_mismatch", "", "int cannot be dereferenced"],
	["c", 1, "awaken qi;", 0, "unknown_type", "", "unknown type name 'awaken'"],
	["c", 1, "int qi = 3;\nprintf(qi);", 0, "type_mismatch", "", "argument 1 of 'printf'"],
	["c", 1, "int size = strlen(\"qi\");", 0, "unknown", "", "implicit declaration of function 'strlen'"],
	["python", 1, "qi = 3\nqi()", 0, "type_mismatch", "", "'int' object is not callable"],
	["python", 1, "qi = \"3\" + 3", 0, "type_mismatch", "", "can only concatenate str"],
	["python", 1, "print(True)\nqi = 3\nawaken(qi)", 0, "", "awaken", "\nTrue\n"],
	["c", 1, "int qi = 3;\nqi == 3;\nawaken(qi);", 0, "", "awaken", "warning: statement with no effect"],
	# Real syntax outside the supported subset: reported as unsupported, never as an error.
	["python", 1, "for step in range(3):\n    awaken(step)", 0, "unsupported", "", "loops"],
	["python", 1, "qi = 3\nif qi == 3:\n    awaken(qi)", 0, "unsupported", "", "decisions"],
	["python", 1, "qi = 3.5", 0, "unsupported", "", "decimal"],
	["python", 1, "qi = 6 / 2", 0, "unsupported", "", "division"],
	["python", 1, "qi = [3]", 0, "unsupported", "", "lists"],
	["python", 2, "size = len(\"qi\")", 3, "unsupported", "", "len()"],
	["python", 1, "qi = 3\nqi += 1", 0, "unsupported", "", "compound"],
	["python", 1, "print(\"a\", end=\"\")", 0, "unsupported", "", "keyword arguments"],
	["python", 1, "qi = 3\nqi.bit_length()", 0, "unsupported", "", "methods"],
	["python", 1, "text = \"ab\" * 2", 0, "unsupported", "", "repeating text"],
	["python", 1, "from sect import *", 0, "unsupported", "", "imports"],
	["python", 1, "def awaken_twice():", 0, "unsupported", "", "functions"],
	["python", 1, "print(f\"{qi}\")", 0, "unsupported", "", "string prefixes"],
	["c", 1, "int qi = 3;\nif (qi == 3) awaken(qi);", 0, "unsupported", "", "decisions"],
	["c", 1, "for (int i = 0; i < 3; i++) {}", 0, "unsupported", "", "loops"],
	["c", 1, "int qi = 3;\nqi++;", 0, "unsupported", "", "increment"],
	["c", 1, "puts(\"hi\");", 0, "unsupported", "", "<stdio.h>"],
	["c", 1, "{ int qi = 3; }", 0, "unsupported", "", "blocks"],
	["c", 1, "int qi = 6 / 2;", 0, "unsupported", "", "division"],
	["c", 1, "int c = 'a';", 0, "unsupported", "", "single-quoted"],
	["c", 1, "#include <string.h>", 0, "unsupported", "", "preprocessor"],
	["java", 2, "int size = \"qi\".length();", 3, "unsupported", "", "methods on values"],
	["java", 1, "int qi = Math.max(1, 3);", 0, "unsupported", "", "standard library"],
	["java", 1, "for (int i = 0; i < 3; i++) {}", 0, "unsupported", "", "loops"],
	["java", 1, "public static void f() {}", 0, "unsupported", "", "classes"],
	["java", 1, "int[] a = {3};", 0, "unsupported", "", "arrays"],
	["java", 1, "System.out.printf(\"%d\", 3);", 0, "unsupported", "", "standard library"],
]
# Failure kinds that are not language errors.
const CATEGORY := {"wrong_amount": "exercise", "literal_arg": "exercise", "literal_channel": "exercise", "type": "exercise",
	"unsupported": "unsupported", "limit": "limit", "not_enough": "game", "too_small": "game", "awaken_type": "game",
	"channel_type": "game", "already_awake": "game", "not_awake": "game"}

var runner := Runner.new()
var results := []
var failures := 0
var slowest_ms := 0.0

func check(ok: bool, record: Dictionary, line: String) -> void:
	record.pass = ok
	results.append(record)
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+line)

func timed_run(lang: String, stage: int, code: String, reserve: int) -> Dictionary:
	var t := Time.get_ticks_usec()
	var r: Dictionary = runner.run(lang, stage, code, "test", 0, reserve)
	slowest_ms = maxf(slowest_ms, (Time.get_ticks_usec()-t)/1000.0)
	return r

func shown(r: Dictionary) -> String:
	var text := "\n"
	for o: Array in r.output: text += o[1]+"\n"
	return text+r.fail.get("message", "")

func table(c: Array) -> void:
	var r := timed_run(c[0], c[1], c[2], c[3])
	var kind: String = r.fail.get("kind", "")
	var effect := ""
	if r.ok and r.effects.awaken > 0: effect = "awaken"
	if r.ok and r.effects.channel > 0: effect = "channel"
	var category: String = r.fail.get("category", "")
	var ok: bool = kind == c[4] and effect == c[5] and (kind == "" or category == CATEGORY.get(kind, "language"))
	if c.size() > 6: ok = ok and shown(r).contains(c[6])
	if r.phase == "compile": ok = ok and r.output.is_empty()          # nothing runs when the check fails
	check(ok, {"language": c[0], "stage": c[1], "code": c[2], "expected": c.slice(4), "got": [kind, effect, category], "message": r.fail.get("message", ""), "output": r.output},
		"%s s%d %-48s -> %s %s %s | %s" % [c[0], c[1], c[2].replace("\n", " / ").left(48), kind, effect, category, r.fail.get("message", "")])

func _initialize() -> void:
	for c: Array in CASES: table(c)
	# Every lesson example runs cleanly in its own step without solving it. A command signature is
	# labelled as a reference, and is indeed not a runnable program on its own.
	for lang: String in Lessons.ORDER:
		for stage in [1, 2]:
			for card: Array in Lessons.LESSONS[lang].cards[stage-1]:
				var r := timed_run(lang, stage, card[2], 0 if stage == 1 else 3)
				if card.size() > 3:
					check(card[3] == "signature" and not r.ok, {"language": lang, "stage": stage, "signature": card[2], "got": r},
						"%s s%d lesson signature %-32s -> labelled reference; alone it gives: %s" % [lang, stage, card[0].left(32), r.fail.get("message", "runs")])
				else:
					var solves: bool = r.effects.awaken > 0 or r.effects.channel > 0
					check(r.ok and not solves, {"language": lang, "stage": stage, "example": card[2], "got": r},
						"%s s%d lesson example %-34s -> %s" % [lang, stage, card[0].left(34), ("SOLVES THE STEP" if solves else "runs, does not solve") if r.ok else r.fail.message])
	# Every authored solution runs cleanly and completes its stage.
	for lang: String in Lessons.ORDER:
		for stage in [1, 2]:
			var r := timed_run(lang, stage, Lessons.LESSONS[lang].starter[stage-1]+Lessons.LESSONS[lang].solution[stage-1], 0 if stage == 1 else 3)
			var ok: bool = r.ok and (r.effects.awaken_from_variable if stage == 1 else r.effects.channel_from_reserve)
			check(ok, {"language": lang, "stage": stage, "code": "authored solution", "got": r}, "%s s%d authored solution" % [lang, stage])
	# Bounded execution: oversized or deeply nested input gives a readable message, quickly.
	var limits := [
		["python", "qi = 3\n".repeat(300), "characters long", "compile"],
		["c", "int qi = 3;\n".repeat(200), "characters long", "compile"],
		["python", "print("+"1, ".repeat(250)+"1)", "words, numbers and symbols", "compile"],
		["python", "qi = 3\n".repeat(41), "statements", "compile"],
		["python", "qi = "+"(".repeat(30)+"3"+")".repeat(30), "nested more than", "compile"],
		["python", "(".repeat(199)+"3"+")".repeat(199), "nested more than", "compile"],
		["python", "qi = "+"-".repeat(300)+"3", "nested more than", "compile"],
		["java", "int qi = "+"(".repeat(20)+"3"+")".repeat(20)+";", "nested more than", "compile"],
		["python", "print(1)\n".repeat(35), "more than 30 lines", "run"],
		["python", "qi = 9999999999", "too large", "compile"],
		["python", "qi = 99999 * 99999", "too large", "run"],
	]
	for c: Array in limits:
		var r := timed_run(c[0], 1, c[1], 0)
		var ok: bool = not r.ok and r.fail.category == "limit" and r.fail.message.contains(c[2]) and r.phase == c[3] and r.output.size() <= Runner.MAX_OUTPUT
		check(ok, {"language": c[0], "limit": c[2], "chars": c[1].length(), "got": [r.phase, r.fail.get("message", ""), r.output.size()]}, "%s limit %-28s (%d chars) -> %s" % [c[0], c[2], c[1].length(), r.fail.get("message", "runs")])
	# A long left-nested sum within the limits still runs (no recursion trouble), and long text is shortened.
	var r := timed_run("python", 1, "qi = "+"1 + ".repeat(190)+"1\nawaken(qi)", 0)
	check(r.fail.get("kind", "") == "wrong_amount" and r.fail.message.contains("191"), {"case": "190 additions", "got": r.fail}, "python 190 additions run -> %s" % r.fail.get("message", ""))
	r = timed_run("python", 1, "print(\""+"a".repeat(500)+"\")", 0)
	check(r.ok and r.output[0][1].length() == Runner.MAX_TEXT+4, {"case": "500-character line", "shown": r.output[0][1].length()}, "python 500-character output line shown as %d characters" % r.output[0][1].length())
	check(slowest_ms < 50.0, {"case": "slowest run", "ms": snappedf(slowest_ms, .01)}, "slowest run of all %d programs: %.2f ms" % [results.size(), slowest_ms])
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_string(JSON.stringify({"failures": failures, "checks": results.size(), "slowest_ms": snappedf(slowest_ms, .01), "results": results}, "  "))
	f.close()
	print("TOTAL %d checks, %d failures" % [results.size(), failures])
	quit(1 if failures else 0)

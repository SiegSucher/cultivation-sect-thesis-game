extends SceneTree
## Proportionate checks for the proposal demo, driven through real key events (including typing
## into the code editor) and the actual UI buttons on the inherited Phase 4D scene with the
## unchanged controller.
## godot --headless --fixed-fps 60 --path . --script res://proposal_demo/review/verify_demo.gd -- <out.json>
const Lessons := preload("res://proposal_demo/lessons.gd")
const SPAWN := Vector3(8, .12, 134)
const AT_GUIDE := Vector3(4.9, .05, 130.6)
const AT_MENTOR := Vector3(4.4, 10.05, 45.6)
const AT_BASIN := Vector3(10.4, 10.05, 42.7)
# One realistic mistake per language and stage, and the error text it must produce.
const MISTAKES := {
	"python": [["awaken(qi)\nqi = 3", "NameError: name 'qi' is not defined"], ["reserve = qi_reserve()\nchannel_basin(5)", "not enough Qi"]],
	"c": [["int qi = 3\nawaken(qi);", "expected ';' before 'awaken'"], ["int reserve = qi_reserve();\nchannel_basin(5);", "not enough Qi"]],
	"java": [["int qi;\nSect.awaken(qi);", "variable qi might not have been initialized"], ["int reserve = Sect.qiReserve();\nSect.channelBasin(5);", "not enough Qi"]],
}
# Real syntax outside the subset, and valid code that breaks a lesson rule (step 1, step 2).
const ACCURACY := {
	"python": ["for step in range(3):\n    awaken(step)", "awaken(3)", "channel_basin(3)"],
	"c": ["int qi = 3;\nif (qi == 3) awaken(qi);", "awaken(3);", "channel_basin(3);"],
	"java": ["int size = \"qi\".length();", "Sect.awaken(3);", "Sect.channelBasin(3);"],
}
var demo: Node3D
var player: CharacterBody3D
var quest: CanvasLayer
var gate: Node3D
var results := []
var failures := 0

func _initialize() -> void:
	run()

func check(name: String, ok: bool, detail = null) -> void:
	results.append({"check": name, "pass": ok, "detail": detail})
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ")+name+("" if detail == null else " | "+str(detail)))

func frames(n := 2) -> void:
	for i in n: await physics_frame

func key(code: Key, down: bool, unicode := 0, ctrl := false) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.unicode = unicode
	e.ctrl_pressed = ctrl
	e.pressed = down
	Input.parse_input_event(e)
	await process_frame

func tap(code: Key, ctrl := false) -> void:
	await key(code, true, 0, ctrl)
	await key(code, false, 0, ctrl)

func type_text(text: String) -> void:
	await tap(KEY_A, true)                 # select all; typing replaces it
	for ch in text:
		if ch == "\n": await tap(KEY_ENTER)
		else:
			await key(KEY_NONE, true, ch.unicode_at(0))
			await key(KEY_NONE, false, ch.unicode_at(0))

func press(id: String) -> bool:
	var b: Button = quest.find_child(id, true, false)
	if b == null or not b.is_visible_in_tree() or b.disabled:
		check("button available: "+id, false)
		return false
	b.pressed.emit()
	await frames(2)
	return true

func run_timed() -> float:
	"""Presses Run and returns how long the run itself took, in milliseconds."""
	var b: Button = quest.find_child("Run", true, false)
	var t := Time.get_ticks_usec()
	b.pressed.emit()
	var ms := (Time.get_ticks_usec()-t)/1000.0
	await frames(2)
	return ms

func snapshot() -> Array:
	"""Everything a reveal must leave alone: editor, console, runs, drafts, quest step, Qi, basin, panel, player."""
	return [quest.editor.text, quest.console.get_parsed_text(), quest.attempts.duplicate(), quest.drafts.duplicate(), quest.stage,
		quest.stage_solved, quest.reserve, demo.aura == null, basin_inactive(), quest.mode, player.global_position]

func solution_shown() -> bool:
	return quest.solution_view.get_parent().visible

func lesson_tab_text() -> String:
	var text := ""
	for c in quest.lesson_box.get_children():
		if c is Label: text += c.text+"\n"
	return text

func untouched(stage: int) -> bool:
	return quest.stage == stage and quest.reserve == (0 if stage == 1 else 3) and (demo.aura == null) == (stage == 1) and basin_inactive() and not quest.stage_solved

func accuracy(lang: String) -> void:
	var name: String = Lessons.LESSONS[lang].name
	await type_text(ACCURACY[lang][0])
	await run_timed()
	var console: String = quest.console.get_parsed_text()
	check(lang+": the console names the sect's learning interpreter and shows no python/gcc/javac command", console.begins_with("[sect runner]") and console.contains("learning interpreter, %s subset" % name) and not console.contains("$ ") and not console.contains("gcc") and not console.contains("javac"), console.left(120))
	check(lang+": real syntax outside the subset is reported as not supported, not as an error; world unchanged", console.contains("Not supported by this learning interpreter") and not console.contains("error:") and not console.contains("Error") and untouched(1), console.right(220))
	await type_text(ACCURACY[lang][1])
	await run_timed()
	console = quest.console.get_parsed_text()
	check(lang+": a bare number passed to the awakening is a lesson rule on valid code, not an error; world unchanged", console.contains("Valid %s, but" % name) and not console.contains("error:") and not console.contains("Error") and untouched(1), console.right(220))
	quest.editor.text = ("qi = 3\n" if lang == "python" else "int qi = 3;\n").repeat(400)       # an oversized paste
	var ms: float = await run_timed()
	console = quest.console.get_parsed_text()
	check(lang+": an oversized paste is refused with a readable message at once; world unchanged", console.contains("Not run: the program is") and ms < 100 and untouched(1), {"run_ms": snappedf(ms, .01), "chars": quest.editor.text.length(), "console": console.right(140)})
	quest.editor.text = ("qi = " if lang == "python" else "int qi = ")+"(".repeat(150)+"3"+")".repeat(150)+("" if lang == "python" else ";")
	ms = await run_timed()
	console = quest.console.get_parsed_text()
	check(lang+": deeply nested brackets are refused with a readable message at once; world unchanged", console.contains("nested more than") and ms < 100 and untouched(1), {"run_ms": snappedf(ms, .01), "console": console.right(140)})

func go(at: Vector3, third := true) -> void:
	demo.jump_to(at, player.yaw)
	player.third_person = third
	await frames(8)

func paused() -> bool:
	return quest.ui_open and not player.is_physics_processing() and not player.is_processing_unhandled_input()

func live() -> bool:
	return not quest.ui_open and player.is_physics_processing() and player.is_processing_unhandled_input() and player.camera.is_current()

func basin_inactive() -> bool:
	var b: Node3D = demo.basin
	return not b.active and not b.water.visible and not b.jet.emitting and b.glow.light_energy == 0.0

func marker_on(target: Node3D) -> bool:
	var m: Node3D = quest.marker
	return m.visible and Vector2(m.global_position.x-target.global_position.x, m.global_position.z-target.global_position.z).length() < .01

func blocked(label: String) -> void:
	var pos := player.global_position
	var third: bool = player.third_person
	var gate_state: bool = gate.preview_open
	var shown: String = quest.mode
	await key(KEY_W, true)
	await frames(20)
	await key(KEY_W, false)
	await tap(KEY_TAB)
	await tap(KEY_M)
	await tap(KEY_E)
	check(label+": movement, Tab, map and E do nothing to the world while the panel is open", player.global_position.distance_to(pos) < .01 and player.third_person == third and not demo.overview and gate.preview_open == gate_state and quest.mode == shown,
		{"moved_m": snappedf(player.global_position.distance_to(pos), .001), "mode": quest.mode})

func moves_again(label: String) -> void:
	var pos := player.global_position
	await key(KEY_S, true)
	await frames(20)
	await key(KEY_S, false)
	await frames(4)
	check(label+": movement works again after closing", player.global_position.distance_to(pos) > .5, {"moved_m": snappedf(player.global_position.distance_to(pos), .01)})

func run() -> void:
	demo = load("res://proposal_demo/proposal_demo.tscn").instantiate()
	root.add_child(demo)
	current_scene = demo
	await frames(10)
	player = demo.player
	quest = demo.quest
	gate = demo.get_node("Buildings/sect_gate")
	await startup()
	await guide_flow()
	await direct_to_mentor()
	await full_run("python")
	await reset_check("after success (Esc menu)", true)
	await reset_after_failure("c")
	await quest_to_stage1("c")
	await full_run("c", true)
	await reset_check("after success (Esc menu)", true)
	await quest_to_stage1("java")
	await full_run("java", true, true)
	await reset_check("after success (recognition panel)", false)
	await first_person()
	await menu_and_doors()
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_string(JSON.stringify({"failures": failures, "checks": results.size(), "display": DisplayServer.get_name(), "results": results}, "  "))
	f.close()
	print("TOTAL %d checks, %d failures" % [results.size(), failures])
	quit(1 if failures else 0)

# ---------------------------------------------------------------- arrival and Guide
func startup() -> void:
	check("demo scene opens on the inherited Phase 4D sect with Guide, Mentor and basin placeholders",
		demo.get_node("Buildings").get_child_count() == 12 and demo.has_node("DistrictEntranceConnections") and demo.guide != null and demo.mentor != null and demo.basin != null)
	check("starts at the spawn in third person: inactive basin, dormant Qi, nothing accepted",
		player.position.distance_to(SPAWN) < .3 and player.third_person and basin_inactive() and quest.stage == 0 and quest.reserve == 0 and quest.qi_label.text == "dormant" and quest.language == "")
	check("first objective and marker point to the Guide (with the Mentor as an alternative)", marker_on(demo.guide) and quest.objective.text.contains("Guide") and quest.objective.text.contains("Mentor") and quest.pointer_label.text.begins_with("Guide"), quest.objective.text)
	# Guide stands beside the forest path (7 m wide), not on it.
	var a := Vector2(8, 134)
	var b := Vector2(-3, 132)
	var g := Vector2(demo.guide.position.x, demo.guide.position.z)
	var t := clampf((g-a).dot(b-a)/(b-a).length_squared(), 0, 1)
	var off := g.distance_to(a+(b-a)*t)
	var m: Vector3 = demo.mentor.global_position
	check("Guide clear of the 7 m forest path; Guide and Mentor outside the door-toggle radii", off > 3.5+.4 and demo.guide.global_position.distance_to(gate.global_position) > 24 and m.distance_to(gate.global_position) > 24,
		{"guide_from_path_centre_m": snappedf(off, .01), "guide_to_gate_m": snappedf(demo.guide.global_position.distance_to(gate.global_position), .1), "mentor_to_gate_m": snappedf(m.distance_to(gate.global_position), .1)})
	await go(AT_BASIN)
	check("before step 2 the basin offers no interaction (only the nearest relevant prompt shows)", quest.nearest() == "", {"prompt": quest.prompt.text, "visible": quest.prompt.visible})

func guide_flow() -> void:
	await go(AT_GUIDE)
	check("prompt beside the Guide reads 'Talk to the Guide'", quest.prompt.visible and quest.prompt.text.contains("Guide"))
	await tap(KEY_E)
	check("E opens the Guide's introduction (page 1 of 4) and pauses controls", quest.mode == "dialogue" and quest.dialogue_text.text == Lessons.GUIDE_INTRO[0] and paused())
	await blocked("Guide dialogue")
	await press("Skip")
	check("Skip closes the introduction; objective and marker move to the Mentor", live() and quest.guide_heard and marker_on(demo.mentor) and quest.objective.text.contains("Mentor"), quest.objective.text)
	await moves_again("after the Guide")
	await go(AT_GUIDE)
	await tap(KEY_E)
	check("revisiting the Guide gives the short direction", quest.dialogue_text.text == Lessons.GUIDE_AGAIN)
	await press("Again")
	check("'Hear the introduction again' restarts at page 1", quest.dialogue_text.text == Lessons.GUIDE_INTRO[0])
	for i in Lessons.GUIDE_INTRO.size(): await press("Next")
	var words := 0
	for page: String in Lessons.GUIDE_INTRO: words += page.split(" ").size()
	check("the full introduction pages through and closes (%d words, about %d s read aloud at 150 wpm)" % [words, roundi(words/2.5)], live() and quest.guide_heard and words >= 50 and words <= 80, {"words": words})

func direct_to_mentor() -> void:
	quest.reset_demo()
	await frames(4)
	check("after reset the marker is back on the Guide", marker_on(demo.guide) and not quest.guide_heard)
	await go(AT_MENTOR)
	check("going straight to the Mentor works without the Guide", quest.nearest() == "mentor" and quest.prompt.text.contains("Mentor"))
	await tap(KEY_E)
	await frames(2)
	check("Mentor greets; objective and marker switch to the Mentor", quest.dialogue_text.text == Lessons.MENTOR_GREETING and marker_on(demo.mentor), {"text": quest.dialogue_text.text.left(40), "marker": quest.marker.global_position, "visible": quest.marker.visible, "met": quest.met})
	await press("Next")
	await press("Decline")
	check("Not yet: polite decline, quest unaccepted", quest.declined and quest.stage == 0 and quest.dialogue_text.text == Lessons.MENTOR_DECLINE)
	await press("Close")
	check("objective after declining invites a return", live() and quest.objective.text.contains("ready"), quest.objective.text)
	await tap(KEY_E)
	check("reopening goes straight to the offer", quest.dialogue_text.text == Lessons.MENTOR_OFFER)
	await press("Accept")
	check("Accept opens the language choice; objective asks for a language", quest.stage == 1 and quest.mode == "language" and quest.objective.text.contains("language"))

# ---------------------------------------------------------------- teaching and both coding steps
func quest_to_stage1(lang: String) -> void:
	await go(AT_MENTOR)
	await tap(KEY_E)
	if quest.mode == "dialogue" and quest.dialogue_text.text == Lessons.MENTOR_GREETING: await press("Next")
	await press("Accept")
	await press("Choose_"+lang)

func full_run(lang: String, from_cards := false, reset_from_recognition := false) -> void:
	var lesson: Dictionary = Lessons.LESSONS[lang]
	if not from_cards: await press("Choose_"+lang)
	var n: int = lesson.cards[0].size()
	check(lang+": choosing the language opens the Mentor's lesson at card 1 of %d" % n, quest.mode == "teach" and quest.teach_page == 0 and quest.teach_head.text.contains("1 / %d" % n) and quest.teach_back.disabled)
	var topics := ""
	for c: Array in lesson.cards[0]: topics += c[0]+" "+c[1]+" "
	check(lang+": lesson covers variables, initialization, calls, order, punctuation/declaration and the game command", topics.contains("variable") and topics.contains("first value") and topics.contains("call") and topics.contains("top to bottom") and topics.contains("game") and (topics.contains("no semicolon") if lang == "python" else topics.contains("semicolon") and topics.contains("int")))
	if lang == "python":
		var all := ""
		for stage_cards: Array in lesson.cards:
			for c: Array in stage_cards: all += c[2]+"\n"
		check("python: no C/Java declaration syntax in any Python example", not all.contains("int ") and not all.contains(";"), null)
	check(lang+": a runnable lesson example is labelled EXAMPLE", quest.teach_example_head.text.begins_with("EXAMPLE"), quest.teach_example_head.text)
	await press("TeachNext")
	await press("TeachBack")
	check(lang+": Back returns to the previous card", quest.teach_page == 0)
	for i in n:
		if i == n-1:
			var shown_code: String = quest.teach_example.get_parsed_text()
			check(lang+": the game-command card shows a signature labelled as a reference, not a solution", quest.teach_example_head.text.begins_with("REFERENCE") and quest.teach_example_head.text.contains("placeholder")
				and shown_code == lesson.cards[0][n-1][2] and not shown_code.contains(lesson.solution[0]), {"head": quest.teach_example_head.text, "code": shown_code})
		await press("TeachNext")
	check(lang+": the last card opens the code editor", quest.mode == "code" and quest.code.visible and paused())
	check(lang+": the worked solution starts hidden and is not offered before the hints; the Lesson tab labels the signature", not solution_shown() and quest.solution_button.disabled and not quest.solutions.has(lang+":1")
		and lesson_tab_text().contains("REFERENCE"))
	var header: String = "\n".join(PackedStringArray(lesson.header[0]))
	check(lang+": the program structure is supplied and the game command is labelled as the game's", quest.header_view.get_parsed_text().contains("game's Qi commands") and (header.contains("int main(void)") if lang == "c" else (header.contains("public static void main") if lang == "java" else header.contains("from sect import"))))
	check(lang+": Lesson, Commands and Hints tabs available beside the editor", quest.tabs.get_tab_count() == 3 and quest.lesson_box.get_child_count() >= n*3 and quest.reference_label.get_parsed_text().contains("not"))
	await blocked(lang+" code editor")
	await accuracy(lang)
	# Step 1: a typed mistake, run, hint, fix, run.
	await type_text(MISTAKES[lang][0][0])
	check(lang+": typed text reaches the editor", quest.editor.text == MISTAKES[lang][0][0], quest.editor.text)
	await tap(KEY_ENTER, true)
	var console: String = quest.console.get_parsed_text()
	check(lang+": Ctrl+Enter runs; the mistake gives a realistic error and a Mentor note; nothing awakens", console.contains(MISTAKES[lang][0][1]) and console.contains("Mentor:") and quest.stage == 1 and quest.reserve == 0 and basin_inactive() and not quest.stage_solved, console.right(160))
	quest.tabs.current_tab = 2          # the presenter opens the Hints tab
	await frames(1)
	await press("Hint")
	await press("Hint")
	check(lang+": two optional hints, then no more", quest.hint_label.text.contains(lesson.hints[0][1].left(12)) and quest.hint_button.disabled)
	check(lang+": after the stronger hint the worked solution is offered, still hidden", not quest.solution_button.disabled and not solution_shown())
	var before := snapshot()
	await press("ShowSolution")
	check(lang+": Show worked solution reveals this language's complete step-1 program", solution_shown() and quest.solution_view.get_parsed_text() == lesson.solution[0]
		and quest.solution_note.text.contains(lesson.name) and quest.solution_note.text.contains("step 1"), quest.solution_view.get_parsed_text())
	check(lang+": revealing it types, runs and changes nothing (editor, console, runs, Qi, basin, step)", snapshot() == before)
	await press("CodeBack")
	check(lang+": closing mid-step restores controls", live())
	await go(AT_MENTOR)
	await tap(KEY_E)
	await press("Review")
	check(lang+": the lesson can be reviewed from the Mentor at any time", quest.mode == "teach")
	await tap(KEY_ESCAPE)
	await tap(KEY_E)
	await press("Continue")
	check(lang+": reopening keeps the draft, output, hints and the revealed solution", quest.mode == "code" and quest.editor.text == MISTAKES[lang][0][0] and quest.console.get_parsed_text() == console and quest.hint_label.text != ""
		and solution_shown() and quest.solution_view.get_parsed_text() == lesson.solution[0])
	await type_text(quest.solution_view.get_parsed_text())       # the student types what was revealed
	await press("Run")
	check(lang+": the fixed code runs cleanly and completes step 1", quest.stage_solved and quest.continue_button.visible and quest.console.get_parsed_text().contains("Reserve: 3") and basin_inactive(), quest.console.get_parsed_text().right(120))
	await press("ResultContinue")
	check(lang+": awakening plays: aura on the player, Qi indicator rises to 3, controls held", quest.stage == 2 and quest.reserve == 3 and demo.aura != null and quest.mode == "flow" and paused())
	await create_timer(2.8).timeout
	check(lang+": the Mentor introduces the basin step (not the basin itself)", quest.mode == "dialogue" and quest.dialogue_text.text == Lessons.MENTOR_STAGE2_INTRO and basin_inactive())
	await press("ShowMe")
	check(lang+": channelling lesson explains reading the reserve and the basin command", quest.mode == "teach" and quest.teach_text.text.contains("return"))
	for i in lesson.cards[1].size():
		if i == lesson.cards[1].size()-1:
			check(lang+": the basin command card shows a labelled reference signature, not a solution", quest.teach_example_head.text.begins_with("REFERENCE") and not quest.teach_example.get_parsed_text().contains(lesson.solution[1]))
		await press("TeachNext")
	check(lang+": finishing the lesson does not start the basin; objective and marker move to the basin", live() and basin_inactive() and marker_on(demo.basin) and quest.objective.text.contains("basin") and quest.qi_label.text == "3 / 3", quest.objective.text)
	# Step 2 at the basin.
	await go(AT_BASIN)
	check(lang+": beside the basin the prompt offers to channel Qi", quest.nearest() == "basin" and quest.prompt.text.contains("basin"))
	await tap(KEY_E)
	check(lang+": E opens step 2 in the editor (language fixed now)", quest.mode == "code" and quest.code_title.text.contains("Step 2") and not quest.change_language.visible and quest.editor.text == lesson.starter[1], {"mode": quest.mode, "title": quest.code_title.text, "lang_button": quest.change_language.visible, "text": quest.editor.text})
	await type_text(ACCURACY[lang][2])
	await tap(KEY_ENTER, true)
	check(lang+": channelling a bare 3 is a lesson rule on valid code; reserve kept; basin inactive", quest.console.get_parsed_text().contains("Valid %s, but" % lesson.name) and untouched(2), quest.console.get_parsed_text().right(160))
	await type_text(MISTAKES[lang][1][0])
	await tap(KEY_ENTER, true)
	check(lang+": channelling too much is refused; reserve kept; basin inactive", quest.console.get_parsed_text().contains(MISTAKES[lang][1][1]) and quest.reserve == 3 and basin_inactive() and not quest.stage_solved)
	quest.tabs.current_tab = 2
	await frames(1)
	check(lang+": step 2 starts with its solution hidden (step 1's stays revealed)", not solution_shown() and quest.solution_button.disabled and quest.solutions.get(lang+":1", false))
	await press("Hint")
	await press("Hint")
	var before2 := snapshot()
	await press("ShowSolution")
	check(lang+": step 2 reveals this language's basin program; nothing typed, run or changed (reserve kept, basin dry)", solution_shown() and quest.solution_view.get_parsed_text() == lesson.solution[1]
		and quest.solution_note.text.contains("step 2") and snapshot() == before2, quest.solution_view.get_parsed_text())
	await tap(KEY_ESCAPE)
	await tap(KEY_E)
	check(lang+": step 2 draft, revealed solution and completed step 1 survive closing", quest.editor.text == MISTAKES[lang][1][0] and quest.stage == 2 and quest.drafts.get(lang+":1", "") == lesson.solution[0]
		and solution_shown() and quest.solution_view.get_parsed_text() == lesson.solution[1])
	await type_text(quest.solution_view.get_parsed_text())
	await tap(KEY_ENTER, true)
	check(lang+": the fixed code runs cleanly and completes step 2", quest.stage_solved and quest.console.get_parsed_text().contains("channelled into the basin"))
	await press("ResultContinue")
	check(lang+": channelling plays; the basin starts only now", quest.stage == 3 and quest.mode == "flow" and paused())
	await create_timer(3.8).timeout
	check(lang+": basin flowing; recognition shown once; the Mentor says the reserve is replenished as it refills", demo.basin.active and demo.basin.water.visible and demo.basin.jet.emitting and quest.mode == "recognition" and quest.recognitions_granted == 1 and quest.reserve == 3 and quest.recognition_text.text.contains(lesson.name) and quest.recognition_text.text.contains("replenishing"))
	check(lang+": objective complete, marker hidden", quest.objective.text.begins_with("Complete") and not quest.marker.visible)
	if reset_from_recognition:
		await press("RecognitionReset")
		return
	await press("ContinueExploring")
	await go(AT_MENTOR)
	await tap(KEY_E)
	check(lang+": repeat talk acknowledges completion without granting it again", quest.dialogue_text.text == Lessons.MENTOR_DONE and quest.recognitions_granted == 1)
	await press("Close")
	await go(AT_BASIN)
	check(lang+": the flowing basin no longer offers an interaction", quest.nearest() == "")

func reset_check(label: String, via_menu: bool) -> void:
	if via_menu:
		await tap(KEY_ESCAPE)
		check("Esc in exploration opens the demo menu", quest.mode == "menu" and quest.menu.visible)
		await press("MenuReset")
	await frames(6)
	var cleared: bool = not quest.guide_heard and not quest.met and not quest.declined and quest.stage == 0 and quest.language == "" and not quest.stage_solved and quest.reserve == 0 \
		and quest.drafts.is_empty() and quest.consoles.is_empty() and quest.hints.is_empty() and quest.solutions.is_empty() and quest.attempts.is_empty() and quest.taught.is_empty() \
		and not quest.recognition_earned and quest.recognitions_granted == 0
	check("Reset Demo "+label+": spawn, Guide state, objective/marker, teaching, awakening, Qi, basin, drafts, recognition all cleared",
		cleared and player.position.distance_to(SPAWN) < .4 and player.third_person and basin_inactive() and demo.aura == null and marker_on(demo.guide) and live() and gate.preview_open,
		{"player": player.position, "objective": quest.objective.text})

func reset_after_failure(lang: String) -> void:
	await quest_to_stage1(lang)
	await press("TeachSkip")
	check(lang+": Skip lesson goes straight to the editor", quest.mode == "code")
	await type_text(MISTAKES[lang][0][0])
	await press("Run")
	check(lang+": failed attempt recorded before reset", quest.attempts.get(lang+":1", 0) == 1 and not quest.stage_solved)
	quest.tabs.current_tab = 2
	await frames(1)
	await press("Hint")
	await press("Hint")
	await press("ShowSolution")
	check(lang+": worked solution revealed before this reset", solution_shown() and quest.solutions.get(lang+":1", false))
	await tap(KEY_ESCAPE)
	await reset_check("after a failed attempt", true)

func first_person() -> void:
	await go(AT_MENTOR, false)
	await tap(KEY_E)
	check("first person: E opens the Mentor and pauses controls", quest.mode == "dialogue" and paused() and not player.third_person)
	await press("Next")
	await press("Accept")
	await press("Choose_python")
	await press("TeachSkip")
	var pos := player.global_position
	await type_text("www")
	check("first person: typing W into the editor types text and does not move the player", quest.editor.text == "www" and player.global_position.distance_to(pos) < .01)
	await press("CodeBack")
	check("first person: closing the editor restores first person and controls", live() and not player.third_person)
	await moves_again("first person")
	await tap(KEY_ESCAPE)
	await press("MenuReset")
	await frames(4)

func menu_and_doors() -> void:
	await tap(KEY_ESCAPE)
	check("Esc opens the menu instead of leaving to the gallery", current_scene == demo and quest.mode == "menu" and paused())
	await press("Resume")
	check("Resume returns to exploration", live())
	await go(AT_MENTOR)
	await tap(KEY_M)
	await tap(KEY_E)
	check("no interaction from the map overview", demo.overview and not quest.ui_open)
	await tap(KEY_M)
	demo.jump_to(Vector3(0, 4.1, 94), 0.0)
	await frames(6)
	var before: bool = gate.preview_open
	await tap(KEY_E)
	var toggled: bool = gate.preview_open != before
	await tap(KEY_E)
	check("away from the Guide and Mentor, E still toggles the Sect Gate (inherited)", toggled and gate.preview_open == before and not quest.ui_open)

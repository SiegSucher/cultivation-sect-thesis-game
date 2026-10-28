extends Node3D
## Optional reading practice owns its own state. It never writes the main quest, Qi or drafts.
## UI uses the quest's existing pause/resume path so camera and input have one owner.
const LIN := Vector3(-9, 10, 38)
const MEI := Vector3(17, 10, 37.2)
const TITLES := ["Follow the current", "A value, not a tether", "Repair the inscription"]
const QUESTIONS := [
	"Trace the lines from top to bottom. What number is printed?",
	"An assignment copies the current number. What does stored contain when printed?",
	"The lantern needs 3. Choose the repair that assigns spark before using it and prints 3."
]
const EXPLANATIONS := [
	"spark begins at 2. The next assignment replaces it with 2 + 1. The printed value is 3.",
	"stored receives the number 1. Changing spark later does not change stored. The printed value is 1.",
	"Assign 3 first, then print spark. Order matters: a value must be ready before the instruction that uses it."
]
var world: Node3D
var quest: CanvasLayer
var residents := {}
var lamps: Array[MeshInstance3D] = []
var lights: Array[OmniLight3D] = []
var halos: Array[MeshInstance3D] = []
var lamp_labels: Array[Label3D] = []
var solved := 0
var wrong_attempts := 0
var visited := {}
var practice_language := "python"
var answered := false
var view := ""
var panel: PanelContainer
var heading: Label
var body: RichTextLabel
var choices: VBoxContainer
var feedback: Label
var footer: HBoxContainer
var notice: Label
var notice_time := 0.0
var last_stage := 0
var time := 0.0
var activity_camera: Camera3D
var camera_focus := Vector3(-11.5, 11.3, 35.5)
var station_label: Label3D

func setup(scene: Node3D) -> void:
	world = scene
	quest = world.quest
	name = "SectLife"
	residents.lin = world.character("Lin", "Lin / lantern apprentice", LIN, Color("ccc9b8"), Color("526b82"), "lantern")
	residents.mei = world.character("Mei", "Mei / court keeper", MEI, Color("ded0ba"), Color("85644b"), "lantern")
	for npc: Node3D in residents.values():
		npc.face(Vector3(0, 10, 44), true)
	build_station()
	build_ui()
	activity_camera = Camera3D.new()
	activity_camera.fov = 58
	activity_camera.far = 600
	add_child(activity_camera)
	activity_camera.position = Vector3(-13, 13.0, 43)
	activity_camera.look_at(Vector3(-11, 11.3, 35.5))
	var menu_content: Control = quest.menu.get_child(0).get_child(0)
	quest.button(menu_content, "Apprentice journal [J]", open_journal, "JournalMenu")
	if world.help_panel:
		var label: Label = world.help_panel.get_child(0)
		label.text = "WASD move  /  E interact  /  Tab camera  /  J journal  /  Esc menu"
	get_viewport().size_changed.connect(layout)
	toast("THE FIRST CURRENT\nFollow the marker to the Guide. J opens your journal.", 9)

func mesh_part(mesh: Mesh, at: Vector3, colour: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = .85
	part.material_override = mat
	add_child(part)
	return part

func build_station() -> void:
	# A compact practice rack off the main route; only six small new meshes per lantern.
	for i in 3:
		# Keep the east-west street at z=35 physically clear of the lantern posts.
		var at := Vector3(-14+i*2.0, 10, 33.3)
		var base := CylinderMesh.new()
		base.top_radius = .46
		base.bottom_radius = .55
		base.height = .2
		base.radial_segments = 8
		mesh_part(base, at+Vector3.UP*.1, Color("687470"))
		var post := CylinderMesh.new()
		post.top_radius = .07
		post.bottom_radius = .09
		post.height = 1.55
		post.radial_segments = 6
		mesh_part(post, at+Vector3.UP*.9, Color("594e40"))
		var glass := CylinderMesh.new()
		glass.top_radius = .26
		glass.bottom_radius = .26
		glass.height = .5
		glass.radial_segments = 6
		lamps.append(mesh_part(glass, at+Vector3.UP*1.8, Color("444c4c")))
		var solid := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = .3
		shape.height = 2.2
		collision.shape = shape
		collision.position = at+Vector3.UP*1.1
		solid.add_child(collision)
		add_child(solid)
		for y in [1.5, 2.1]:
			var cap := CylinderMesh.new()
			cap.top_radius = .15
			cap.bottom_radius = .37
			cap.height = .18
			cap.radial_segments = 6
			mesh_part(cap, at+Vector3.UP*y, Color("3b5554"))
		var light := OmniLight3D.new()
		light.position = at+Vector3.UP*1.8
		light.light_color = Color("ffcf83")
		light.omni_range = 4.5
		light.omni_attenuation = 1.2
		light.light_energy = 0
		add_child(light)
		lights.append(light)
		# A radial transparent halo works on GL Compatibility without a post-processing dependency.
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1, .65, .25, .32))
		gradient.set_color(1, Color(1, .65, .25, 0))
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.width = 128
		texture.height = 128
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(.5, .5)
		texture.fill_to = Vector2(1, .5)
		var quad := QuadMesh.new()
		quad.size = Vector2(1.8, 1.8)
		var halo := mesh_part(quad, at+Vector3.UP*1.8, Color.WHITE)
		var halo_mat: StandardMaterial3D = halo.material_override
		halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		halo_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		halo_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		halo_mat.albedo_texture = texture
		halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		halos.append(halo)
		var label := Label3D.new()
		label.position = at+Vector3.UP*2.5
		label.font_size = 30
		label.pixel_size = .009
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.outline_size = 5
		add_child(label)
		lamp_labels.append(label)
	station_label = Label3D.new()
	station_label.position = Vector3(-12, 13.25, 33.3)
	station_label.text = "LANTERN PRACTICE\nOptional / speak to Lin"
	station_label.font_size = 34
	station_label.pixel_size = .009
	station_label.outline_size = 5
	station_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(station_label)
	update_lamps()

func build_ui() -> void:
	var screen: Control = quest.get_node("Screen")
	panel = PanelContainer.new()
	panel.name = "SectLifePanel"
	screen.add_child(panel)
	var col := quest.column(panel, 12) as VBoxContainer
	heading = quest.title(col, "Apprentice journal", 23)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	body = RichTextLabel.new()
	body.bbcode_enabled = true
	body.add_theme_font_override("mono_font", quest.mono)
	body.fit_content = true
	body.scroll_active = false
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(body)
	choices = VBoxContainer.new()
	choices.add_theme_constant_override("separation", 8)
	content.add_child(choices)
	feedback = quest.label(content, "", 18)
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	col.add_child(footer)
	notice = quest.label(screen, "", 18)
	notice.theme_type_variation = "PromptLabel"
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.hide()
	layout()

func layout() -> void:
	if not panel: return
	var area: Vector2 = quest.get_node("Screen").size
	# Same readable text at both resolutions; scroll content, keep Close outside the scroll.
	panel.position = Vector2(24, 80)
	var height := area.y-120 if view == "journal" else minf(640, area.y-120)
	panel.size = Vector2(minf(650, area.x-48), maxf(330, height))
	if activity_camera and activity_camera.current:
		activity_camera.look_at(camera_focus)
		var free_middle := (panel.get_rect().end.x+area.x)/2
		var shift := atan((free_middle/area.x*2-1)*tan(deg_to_rad(activity_camera.fov)/2)*area.x/area.y)
		activity_camera.global_basis = Basis(Vector3.UP, shift)*activity_camera.global_basis
	notice.position = Vector2(maxf(20, (area.x-600)/2), area.y-158)
	notice.size = Vector2(minf(600, area.x-40), 62)

func clear_buttons(container: Control) -> void:
	for item in container.get_children():
		container.remove_child(item)
		item.queue_free()

func open_page(title_text: String, text: String, page: String) -> void:
	quest.open_ui("life")
	view = page
	clear_buttons(choices)
	clear_buttons(footer)
	heading.text = title_text
	body.text = text
	feedback.text = ""
	quest.button(footer, "Close [Esc]", quest.close_ui, "LifeClose")
	panel.show()
	layout()
	footer.get_child(0).grab_focus()

func hide_panel() -> void:
	if panel: panel.hide()
	if activity_camera and activity_camera.current:
		world.player.camera.make_current()
		world.player.update_camera()

func open_journal() -> void:
	if world.overview: world.set_walk()
	var main: String = "[b]NEXT STEP[/b]\n"+quest.objective_text()
	var notes := "\n\n[b]WHAT YOUR CODE CHANGES[/b]\n"
	notes += "Awakening: a variable holds a number; a game command turns it into Qi.\n" if quest.stage >= 2 else "Awakening lesson: not completed yet.\n"
	notes += "Channeling: read your reserve, then pass that value to the basin. Travellers now have water.\n" if quest.stage >= 3 else "Basin lesson: not completed yet.\n"
	notes += "\n[b]LIFE IN THE COURT / OPTIONAL[/b]\nLin is west (left) of the Mentor at the three lanterns. Mei keeps the east side of the court. Both are beside the teaching area.\nLanterns repaired: %d / 3.\n" % solved
	for i in solved: notes += "\n"+str(i+1)+". "+EXPLANATIONS[i]+"\n"
	if visited.has("mei"): notes += "\nMei: cultivation is useful when it helps the next person. The public basin is shared, not a private trophy.\n"
	if solved == 3: notes += "\n[b]Lantern Keeper[/b] / Lin's practice seal earned. No extra Qi or quest recognition is granted.\n"
	notes += "\n[b]NEXT MAIN QUESTS[/b]\n"
	notes += "The Silent Crossing: an if condition verified the real seal charge and released the bridge.\n" if quest.stage >= 4 else "The Silent Crossing: after the basin, follow the marker north to the sealed bridge.\n"
	notes += "The Threefold Ward: a for loop repeated exactly three pulses. The shrine protects the sect.\n" if quest.stage >= 5 else "The Threefold Ward: cross the released bridge, then restore the repeating inscription at the shrine.\n"
	if world.living:
		notes += "\n[b]PLACES & PEOPLE[/b]\nMorning forms beside the west stair. Reading court beyond Lin. Tea and maintenance on the east side. The training terrace, library and herb garden have their own residents.\n"
		if world.living.visits.size(): notes += "Spoken with: "+", ".join(world.living.visits.keys())+".\n"
		if world.living.dusk.listen_count > 0: notes += "Listening bench: the bamboo chime leaves room for the sound of water.\n"
	notes += "\n[b]CONTROLS[/b]\nWASD move / mouse look / E talk / Tab camera / J journal / Esc menu.\n\nThe main exercises use a restricted learning interpreter for Python, C and Java, not a full language runtime. Lantern practice is a reading activity; it does not execute your code.\n\nProgress and drafts last for this running session. Reset Demo clears both the main quest and optional activities."
	open_page("Apprentice journal", main+notes, "journal")
	if quest.stage in [1, 2, 3, 4] and quest.language != "": quest.button(footer, "Review lesson", quest.review_lesson, "JournalLesson")

func talk_lin() -> void:
	visited.lin = true
	residents.lin.greet()
	residents.lin.speak(5)
	residents.lin.face(world.player.global_position)
	open_page("Lin / lantern apprentice", "[b]A small service for the sect[/b]\n\nI keep these practice lanterns for late arrivals. Before I touch an inscription, I trace what each line will do. Help me check three of them?\n\nEach correct reading lights one lantern. There is no timer or penalty; leave and return whenever you like. Your own Qi stays untouched.\n\n[b]Optional[/b] / The Mentor's awakening and basin lesson remain your main task.", "lin")
	quest.button(choices, "Continue practice (%d / 3)" % solved if solved < 3 else "See your restored lanterns", open_practice, "StartPractice")
	for lang in ["python", "c", "java"]:
		quest.button(choices, "Read in "+str(quest.Lessons.LESSONS[lang].name), choose_practice_language.bind(lang), "Practice_"+lang)
	if quest.language != "": practice_language = quest.language
	frame_activity(LIN+Vector3.UP, Vector3(-13, 12.5, 41.5))

func choose_practice_language(lang: String) -> void:
	practice_language = lang
	open_practice()

func snippet(index: int) -> String:
	var py := ["spark = 2\nspark = spark + 1\nprint(spark)", "spark = 1\nstored = spark\nspark = 3\nprint(stored)", "print(spark)\nspark = 3"]
	var cc := ["int spark = 2;\nspark = spark + 1;\nprintf(\"%d\", spark);", "int spark = 1;\nint stored = spark;\nspark = 3;\nprintf(\"%d\", stored);", "int spark;\nprintf(\"%d\", spark);\nspark = 3;"]
	var java := ["int spark = 2;\nspark = spark + 1;\nSystem.out.println(spark);", "int spark = 1;\nint stored = spark;\nspark = 3;\nSystem.out.println(stored);", "int spark;\nSystem.out.println(spark);\nspark = 3;"]
	return {"python": py, "c": cc, "java": java}[practice_language][index]

func open_practice() -> void:
	if solved == 3:
		open_page("Lantern Keeper / practice complete", "[b]Three lights for the next traveller.[/b]\n\nLin: We did not need more power. We needed to understand what the instructions actually said.\n\nYou traced a changing value, kept a copied value separate, and repaired the order of two instructions. Your journal now records each idea.\n\nThe practice seal is a local keepsake. The Mentor still awards recognition only for the original quest.", "complete")
		quest.button(footer, "Open journal", open_journal, "LifeJournal")
	else:
		answered = false
		var wrapper := "C excerpts are inside main with stdio.h included." if practice_language == "c" else ("Java excerpts are inside a main method." if practice_language == "java" else "Python statements are read top to bottom.")
		open_page("Lantern %d / 3 - %s" % [solved+1, TITLES[solved]], "[b]%s / reading practice[/b]\n%s\n\n%s\n\n[code]%s[/code]" % [practice_language.capitalize(), wrapper, QUESTIONS[solved], snippet(solved)], "practice")
		var labels: Array = ["3", "2", "1"] if solved == 0 else ["3", "1", "0"]
		if solved == 2: labels = ["Print spark, then assign 3", "Assign 1, then print spark", "Assign 3, then print spark"]
		for i in labels.size(): quest.button(choices, str(labels[i]), answer.bind(i), "Answer%d" % i)
		quest.button(footer, "Hint", show_hint, "LifeHint")
	frame_activity(Vector3(-11.5, 11.3, 35.5), Vector3(-13, 13, 43))

func frame_activity(focus: Vector3, eye: Vector3) -> void:
	camera_focus = focus
	activity_camera.position = eye
	activity_camera.make_current()
	world.player.avatar.visible = true
	layout()

func show_hint() -> void:
	feedback.text = ["Write down spark after each line: first 2, then 2 + 1.", "stored takes a snapshot of spark at the moment of assignment.", "Read before write is the problem. Give spark the required value before printing it."][solved]

func answer(index: int) -> void:
	if answered or solved >= 3: return
	var correct: bool = index == [0, 1, 2][solved]
	if not correct:
		wrong_attempts += 1
		feedback.text = "Try again. "+[
			"The second line changes spark. Trace its new value before printing.",
			"stored is a separate variable. A later assignment to spark does not rewrite it.",
			"Printing first uses an unready value; assigning 1 would print 1. We need 3 before the print."
		][solved]
		quest.sfx("error")
		return
	answered = true
	feedback.text = "Lantern restored. "+EXPLANATIONS[solved]
	solved += 1
	update_lamps()
	quest.sfx("success")
	for item: Button in choices.get_children(): item.disabled = true
	clear_buttons(footer)
	quest.button(footer, "Next lantern" if solved < 3 else "Receive practice seal", open_practice, "NextLantern")
	quest.button(footer, "Leave for now", quest.close_ui, "LifeClose")
	footer.get_child(0).grab_focus()

func talk_mei() -> void:
	visited.mei = true
	residents.mei.greet()
	residents.mei.speak(5)
	residents.mei.face(world.player.global_position)
	var text := "[b]Water for the next arrival[/b]\n\nI used to carry water up these stairs. The basin is quiet today. The Mentor can teach you the two inscriptions that will wake it.\n\nCultivation is useful when it helps the next person. You will know your code worked when the water moves, not merely when the lesson says so."
	if quest.stage >= 3:
		text = "[b]The court has its water again.[/b]\n\nI heard the basin before I saw you return. Travellers can wash away the dust now. Thank you.\n\nYour inscription read a reserve and passed its value into an action. That small chain of instructions changed something everyone here can use."
	if solved == 3: text += "\n\nAnd Lin's lanterns are glowing again. The evening arrivals will find their way."
	if quest.stage == 3: text += "\n\nThe basin sent a signal to the old shrine. Follow the marker north to the Silent Crossing and verify its seal. This is your next main quest."
	if quest.stage == 4: text += "\n\nThe crossing is open. The next main quest is beyond it: restore the Threefold Ward before the night mist reaches the sect."
	if quest.stage == 5: text += "\n\nThe crossing is open and the Threefold Ward protects the sect. You have earned our trust."
	open_page("Mei / court keeper", text, "mei")
	if quest.stage in [3, 4]: quest.button(choices, "Follow the main quest marker", quest.close_ui, "MeiStory")
	quest.button(footer, "Open journal", open_journal, "LifeJournal")
	frame_activity(MEI+Vector3.UP, Vector3(19.8, 12.3, 40.5))

func update_lamps() -> void:
	for i in lamps.size():
		var mat: StandardMaterial3D = lamps[i].material_override
		mat.albedo_color = Color("ffbc66") if i < solved else Color("444c4c")
		mat.emission_enabled = i < solved
		mat.emission = Color("ff8f32")
		mat.emission_energy_multiplier = 1.7
		lights[i].light_energy = 1.8 if i < solved else 0
		halos[i].visible = i < solved
		lamp_labels[i].text = "%d / %s" % [i+1, "restored" if i < solved else "unlit"]

func toast(text: String, seconds := 6.0) -> void:
	notice.text = text
	notice_time = seconds

func reset() -> void:
	solved = 0
	wrong_attempts = 0
	visited.clear()
	answered = false
	practice_language = "python"
	last_stage = 0
	view = ""
	update_lamps()
	hide_panel()
	toast("New arrival / all quest and lantern progress reset.\nFollow the marker to the Guide.")

func _process(delta: float) -> void:
	if not quest: return
	time += delta
	if not quest.ui_open and not world.overview: notice_time = maxf(0, notice_time-delta)
	notice.visible = notice_time > 0 and not quest.ui_open and not world.overview
	# Acknowledgements only; no automatic camera switches or progress changes.
	if quest.stage != last_stage:
		last_stage = quest.stage
		if last_stage == 2: toast("Your Qi is awake. The next inscription belongs at the basin.")
		if last_stage == 3: toast("The court has water again.\nNext main quest: The Silent Crossing / follow the marker north.\nLin\'s lanterns remain optional.", 12)
	for label: Label3D in lamp_labels: label.visible = not quest.ui_open
	station_label.visible = not quest.ui_open
	for npc: Node3D in residents.values():
		for label: Label3D in npc.find_children("*", "Label3D", true, false):
			label.visible = not quest.ui_open and npc.global_position.distance_to(world.player.global_position) < 22
			label.font_size = 30
		# Residents attend to nearby people; quiet work gestures keep the court inhabited.
		if not quest.ui_open and fmod(time, 8.0) < delta: npc.speak(1.3)
	if panel.visible: layout()

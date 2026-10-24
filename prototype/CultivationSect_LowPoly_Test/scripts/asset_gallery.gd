extends Control
## A one-asset inspection stage. No town scene, map, or placement data is loaded.
const CATALOG := "res://assets/gallery/catalog.json"
var catalog: Array = []
var shown: Array[int] = []
var selected := -1
var model: Node3D
var stage: Node3D
var viewport: SubViewport
var viewer: SubViewportContainer
var camera: Camera3D
var ground: MeshInstance3D
var scale_figure: Node3D
var asset_list: ItemList
var search: LineEdit
var groups: OptionButton
var heading: Label
var status: Label
var details: Label
var source_button: Button
var doors_button: Button
var spin_button: CheckButton
var walkthrough_button: Button
var bounds := AABB()
var center := Vector3.ZERO
var target := Vector3.ZERO
var distance := 40.0
var yaw := .65
var pitch := .32
var base_distance := 40.0
var dragging := false
var panning := false
var door_nodes: Array[Node] = []
var doors_open := false

func label(words: String, size := 16) -> Label:
	var result := Label.new()
	result.text = words
	result.add_theme_font_size_override("font_size", size)
	return result

func button(words: String, action: Callable, parent: Node) -> Button:
	var result := Button.new()
	result.text = words
	result.pressed.connect(action)
	parent.add_child(result)
	return result

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var theme_resource := Theme.new()
	theme_resource.default_font_size = 16
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("182b30")
	panel.content_margin_left = 14
	panel.content_margin_right = 14
	panel.content_margin_top = 12
	panel.content_margin_bottom = 12
	theme_resource.set_stylebox("panel", "PanelContainer", panel)
	theme_resource.set_color("font_color", "Label", Color("e7e9df"))
	theme = theme_resource
	var background := ColorRect.new()
	background.color = Color("112127")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var columns := HBoxContainer.new()
	columns.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	columns.add_theme_constant_override("separation", 0)
	add_child(columns)
	var sidebar := PanelContainer.new()
	sidebar.custom_minimum_size.x = 320
	columns.add_child(sidebar)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	sidebar.add_child(left)
	left.add_child(label("ASSET GALLERY", 25))
	left.add_child(label("New prototype • original asset library", 14))
	search = LineEdit.new()
	search.placeholder_text = "Search assets..."
	search.text_changed.connect(func(_value: String): filter_assets())
	left.add_child(search)
	groups = OptionButton.new()
	for words: String in ["All new assets", "Buildings", "Nature", "Props"]:
		groups.add_item(words)
	groups.item_selected.connect(func(_index: int): filter_assets())
	left.add_child(groups)
	asset_list = ItemList.new()
	asset_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	asset_list.custom_minimum_size.y = 200
	asset_list.add_theme_constant_override("v_separation", 9)
	asset_list.item_selected.connect(func(index: int): select_asset(shown[index]))
	left.add_child(asset_list)
	left.add_child(label("Inspection stage only\nWorld placement belongs to Claude.", 13))
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 0)
	columns.add_child(right)
	var header := PanelContainer.new()
	right.add_child(header)
	var header_rows := VBoxContainer.new()
	header.add_child(header_rows)
	heading = label("Select an asset", 23)
	header_rows.add_child(heading)
	status = label("", 14)
	status.modulate = Color("c7b581")
	header_rows.add_child(status)
	var actions := HFlowContainer.new()
	header_rows.add_child(actions)
	for words: String in ["Front", "3/4", "Side", "Rear", "Top", "Interior", "Reset"]:
		button(words, preset.bind(words), actions)
	spin_button = CheckButton.new()
	spin_button.text = "Rotate"
	actions.add_child(spin_button)
	var reference := CheckButton.new()
	reference.text = "1.8 m person"
	reference.button_pressed = true
	reference.toggled.connect(func(visible_now: bool): scale_figure.visible = visible_now)
	actions.add_child(reference)
	doors_button = button("Open doors", toggle_doors, actions)
	walkthrough_button = button("Walk asset", open_walkthrough, actions)
	viewer = SubViewportContainer.new()
	viewer.stretch = true
	viewer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewer.custom_minimum_size = Vector2(500, 300)
	viewer.gui_input.connect(viewer_input)
	right.add_child(viewer)
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	viewer.add_child(viewport)
	stage = Node3D.new()
	viewport.add_child(stage)
	build_stage()
	var footer := PanelContainer.new()
	right.add_child(footer)
	var footer_rows := VBoxContainer.new()
	footer.add_child(footer_rows)
	details = label("", 14)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.text = "Loading catalog..."
	footer_rows.add_child(details)
	var bottom := HBoxContainer.new()
	footer_rows.add_child(bottom)
	var hints := label("Drag: orbit   •   Right-drag: pan   •   Wheel: zoom", 13)
	hints.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(hints)
	source_button = button("Open source", open_source, bottom)
	catalog = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
	filter_assets()
	if not catalog.is_empty():
		select_asset(0)
		asset_list.select(0)

func build_stage() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("8eaaa9")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d5e3da")
	environment.ambient_light_energy = .55
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	stage.add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -30, 0)
	sun.light_color = Color("fff0d8")
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 200
	stage.add_child(sun)
	ground = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(500, 500)
	ground.mesh = plane
	var material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = "shader_type spatial; varying vec3 at; void vertex(){ at=VERTEX; } void fragment(){ vec2 line=abs(fract(at.xz-0.5)-0.5)/max(fwidth(at.xz),vec2(0.001)); float grid=(1.0-min(min(line.x,line.y),1.0))*(1.0-smoothstep(45.0,160.0,length(at.xz))); ALBEDO=mix(vec3(0.23,0.30,0.29),vec3(0.32,0.40,0.37),grid*0.35); ROUGHNESS=1.0; }"
	material.shader = shader
	ground.material_override = material
	stage.add_child(ground)
	camera = Camera3D.new()
	camera.fov = 48
	camera.near = .02
	camera.far = 1500
	stage.add_child(camera)
	camera.make_current()
	scale_figure = Node3D.new()
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = .20
	capsule.height = 1.40
	body.mesh = capsule
	body.position.y = .70
	scale_figure.add_child(body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = .18
	sphere.height = .36
	head.mesh = sphere
	head.position.y = 1.62
	scale_figure.add_child(head)
	var figure_material := StandardMaterial3D.new()
	figure_material.albedo_color = Color("d1b177")
	body.material_override = figure_material
	head.material_override = figure_material
	var figure_label := Label3D.new()
	figure_label.text = "1.8 m"
	figure_label.position.y = 2.05
	figure_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	figure_label.pixel_size = .003
	scale_figure.add_child(figure_label)
	stage.add_child(scale_figure)

func filter_assets() -> void:
	asset_list.clear()
	shown.clear()
	var query := search.text.strip_edges().to_lower()
	var group := groups.get_item_text(groups.selected)
	for i in range(catalog.size()):
		var entry: Dictionary = catalog[i]
		if group != "All new assets" and entry.group != group:
			continue
		if not query.is_empty() and query not in (str(entry.name)+" "+str(entry.group)).to_lower():
			continue
		shown.append(i)
		asset_list.add_item(entry.name)
		asset_list.set_item_tooltip(asset_list.item_count-1, entry.name+"\n"+entry.status)
		if i == selected:
			asset_list.select(asset_list.item_count-1)

func load_entry(entry: Dictionary) -> Node3D:
	var resource: PackedScene = load(entry.resource)
	return resource.instantiate() if resource else null

func select_asset(index: int) -> void:
	if model:
		stage.remove_child(model)
		model.queue_free()
	selected = index
	var visible_index := shown.find(index)
	if visible_index >= 0:
		asset_list.deselect_all()
		asset_list.select(visible_index)
		# Programmatic selection need not move ItemList's keyboard cursor.
		# Keep the default item visible after a filter reset or batch review.
		if visible_index == 0: asset_list.get_v_scroll_bar().value = 0
	var entry: Dictionary = catalog[index]
	heading.text = entry.name
	status.text = entry.status
	model = load_entry(entry)
	door_nodes.clear()
	doors_open = false
	doors_button.text = "Open doors"
	if not model:
		details.text = "Unable to load this asset: "+str(entry)
		return
	model.name = "SelectedAsset"
	stage.add_child(model)
	var found := false
	var triangles := 0
	var surfaces := 0
	for child: Node in model.find_children("*", "Node", true, false):
		if child.has_method("request_toggle"):
			door_nodes.append(child)
		if child is MeshInstance3D and child.mesh and "DistantExterior" not in str(child.get_path()):
			var next: AABB = child.global_transform*child.get_aabb()
			bounds = bounds.merge(next) if found else next
			found = true
			for surface_index in range(child.mesh.get_surface_count()):
				var arrays: Array = child.mesh.surface_get_arrays(surface_index)
				var indices: Variant = arrays[Mesh.ARRAY_INDEX]
				triangles += (indices.size() if indices != null and indices.size() else arrays[Mesh.ARRAY_VERTEX].size())/3
				surfaces += 1
		if child is MultiMeshInstance3D and child.multimesh and child.multimesh.mesh:
			var mesh: Mesh = child.multimesh.mesh
			for surface_index in range(mesh.get_surface_count()):
				var arrays: Array = mesh.surface_get_arrays(surface_index)
				var indices: Variant = arrays[Mesh.ARRAY_INDEX]
				triangles += ((indices.size() if indices != null and indices.size() else arrays[Mesh.ARRAY_VERTEX].size())/3)*child.multimesh.instance_count
				surfaces += 1
	# A gate is one paired-door mechanism, while the hall has three mechanisms.
	if model.has_method("request_toggle"):
		door_nodes.append(model)
	if not found:
		bounds = AABB(Vector3(-1,0,-1), Vector3(2,2,2))
	center = bounds.get_center()
	ground.position.y = minf(bounds.position.y, 0)-.025
	scale_figure.position = Vector3(bounds.end.x+1,ground.position.y+.025,bounds.end.z)
	base_distance = maxf(bounds.size.length()*1.15, 3.5)
	if entry.id == "sect_gate":
		# Fit the broad gateway to the inspection panel instead of a distant
		# whole-building sphere; the hall retains its existing camera framing.
		base_distance = 31.5
	elif entry.id == "main_sect_hall":
		base_distance = 48.0
	elif entry.id == "martial_training_ground":
		base_distance = 74.0
		scale_figure.position = Vector3(-22.5,.31,9)
	elif entry.id == "scripture_pavilion":
		base_distance = 38.0
		scale_figure.position = Vector3(-3.7,1.05,8.8)
	source_button.disabled = entry.get("source", "").is_empty()
	doors_button.disabled = door_nodes.is_empty()
	walkthrough_button.disabled = entry.id not in ["main_sect_hall","sect_gate","martial_training_ground","scripture_pavilion"] and not entry.has("walkthrough")
	details.text = "%.2f W × %.2f D × %.2f H m   •   %s mesh triangles   •   %d surfaces\n%s" % [bounds.size.x,bounds.size.z,bounds.size.y,String.num_int64(triangles),surfaces,entry.get("resource",entry.get("external_model",entry.get("script","")))]
	preset("3/4")

func preset(view: String) -> void:
	target = center
	distance = base_distance
	pitch = .27
	camera.fov = 48
	camera.near = .08 if selected >= 0 and catalog[selected].id == "martial_training_ground" else .02
	match view:
		"Front": yaw = 0
		"Side": yaw = PI/2
		"Rear": yaw = PI
		"Top": yaw = 0; pitch = 1.50
		"Interior":
			if selected >= 0 and catalog[selected].id == "scripture_pavilion":
				target = Vector3(0,4.3,-2.5)
				distance = 7.5
				yaw = 0
				pitch = -.10
				camera.fov = 85
			elif selected >= 0 and catalog[selected].id == "main_sect_hall":
				# Authored local meeting-aisle camera, never a town position.
				target = Vector3(0,4.6,-5.5)
				distance = 11.8
				yaw = 0
				pitch = -.11
				camera.fov = 76
				if not doors_open: toggle_doors()
			elif selected >= 0 and catalog[selected].id == "sect_gate":
				target = Vector3(0,4.0,-3.3)
				distance = 10.4
				yaw = 0
				pitch = -.10
				camera.fov = 68
				if not doors_open: toggle_doors()
			elif selected >= 0 and catalog[selected].id == "martial_training_ground":
				target = Vector3(0,2.1,-20)
				distance = 35
				yaw = 0
				pitch = .015
				camera.fov = 74
			elif selected >= 0 and catalog[selected].has("interior_camera"):
				var view_data: Dictionary = catalog[selected].interior_camera
				var point: Array = view_data.target
				target = Vector3(point[0],point[1],point[2])
				distance = view_data.distance
				yaw = view_data.yaw
				pitch = view_data.pitch
				camera.fov = view_data.fov
			else:
				yaw = 0
				distance = maxf(bounds.size.length()*.22, 1.0)
		_: yaw = .65; pitch = .32
	if selected >= 0 and catalog[selected].id == "martial_training_ground" and view in ["3/4","Reset"]:
		pitch = .60
	update_camera()

func toggle_doors() -> void:
	for door: Node in door_nodes:
		door.request_toggle()
	doors_open = not doors_open
	doors_button.text = "Close doors" if doors_open else "Open doors"

func workspace_path(relative: String) -> String:
	if relative.begins_with("res://"): return ProjectSettings.globalize_path(relative)
	return ProjectSettings.globalize_path("res://../../"+relative).simplify_path()

func open_source() -> void:
	if selected >= 0:
		OS.shell_open(workspace_path(catalog[selected].source))

func open_walkthrough() -> void:
	# Inspection fixture only; this does not add a player to any town scene.
	if selected >= 0 and catalog[selected].id == "main_sect_hall":
		get_tree().change_scene_to_file("res://scenes/hall_experiment.tscn")
	elif selected >= 0 and catalog[selected].id == "sect_gate":
		get_tree().change_scene_to_file("res://scenes/review/gate_walkthrough.tscn")
	elif selected >= 0 and catalog[selected].id == "martial_training_ground":
		get_tree().change_scene_to_file("res://scenes/review/training_walkthrough.tscn")
	elif selected >= 0 and catalog[selected].id == "scripture_pavilion":
		get_tree().change_scene_to_file("res://scenes/review/scripture_walkthrough.tscn")
	elif selected >= 0 and catalog[selected].has("walkthrough"):
		get_tree().change_scene_to_file(catalog[selected].walkthrough)

func viewer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT: dragging = event.pressed
		if event.button_index in [MOUSE_BUTTON_RIGHT,MOUSE_BUTTON_MIDDLE]: panning = event.pressed
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP: distance *= .88
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN: distance *= 1.12
		distance = clampf(distance,.15,1000)
	if event is InputEventMouseMotion:
		if dragging:
			yaw -= event.relative.x*.008
			pitch = clampf(pitch+event.relative.y*.006,-1.45,1.50)
		if panning:
			target += (-camera.global_basis.x*event.relative.x+camera.global_basis.y*event.relative.y)*distance*.0015
	update_camera()

func _input(event: InputEvent) -> void:
	# Release even if the drag ends outside the 3D panel.
	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT: dragging = false
		if event.button_index in [MOUSE_BUTTON_RIGHT,MOUSE_BUTTON_MIDDLE]: panning = false

func _process(delta: float) -> void:
	if spin_button and spin_button.button_pressed:
		yaw += delta*.22
		update_camera()

func update_camera() -> void:
	if camera:
		camera.position = target+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance
		camera.look_at(target)

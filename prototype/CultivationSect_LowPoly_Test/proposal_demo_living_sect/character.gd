extends Node3D
## Original, metre-scale articulated low-poly figure. No imported or legacy character assets.
## Legs solve to floor-level foot targets; the walking cycle follows actual distance travelled.
var role := "apprentice"
var coat := Color("864d43")
var cloth := Color("d8ceb6")
var trim := Color("bfaa71")
var skin := Color("c79b79")
var hair_color := Color("292b2b")
var hairstyle := 0
var elder := false
var straw := false
var activity := "idle"
var moving_speed := 0.0
var speaking := 0.0
var bow := 0.0
var time := 0.0
var phase := 0.0
var stride_span := .33
var torso: Node3D
var head: Node3D
var arms: Array[Node3D] = []
var elbows: Array[Node3D] = []
var hands: Array[Node3D] = []
var hips: Array[Node3D] = []
var knees: Array[Node3D] = []
var feet: Array[Node3D] = []
var hems: Array[Node3D] = []
var props := {}
var palette := {}
var last_position := Vector3.ZERO
var travel := 0.0
var grounded := true
func material(c: Color) -> StandardMaterial3D:
	if palette.has(c): return palette[c]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = .88
	palette[c] = m
	return m
func pivot(parent: Node3D, at: Vector3, id: String) -> Node3D:
	var p := Node3D.new()
	p.name = id
	p.position = at
	parent.add_child(p)
	return p
func part(parent: Node3D, mesh: Mesh, at: Vector3, color: Color, size := Vector3.ONE, rot := Vector3.ZERO) -> MeshInstance3D:
	var p := MeshInstance3D.new()
	p.mesh = mesh
	p.material_override = material(color)
	p.position = at
	p.scale = size
	p.rotation = rot
	parent.add_child(p)
	return p
func box(parent: Node3D, at: Vector3, size: Vector3, color: Color, rot := Vector3.ZERO) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return part(parent,m,at,color,Vector3.ONE,rot)
func ellipsoid(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = .5
	m.height = 1
	m.radial_segments = 12
	m.rings = 7
	return part(parent,m,at,color,size)
func tube(parent: Node3D, at: Vector3, top: float, bottom: float, h: float, color: Color, scale := Vector3.ONE, rot := Vector3.ZERO) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = 10
	return part(parent,m,at,color,scale,rot)
func _ready() -> void:
	# About 7.5 heads tall, shoulder width .46 m, soles exactly at local y=0.
	var dark := Color("353a3c")
	var ivory := Color("e3dac5")
	for side: float in [-1.0,1.0]:
		var hip := pivot(self,Vector3(side*.112,.9,0),"Hip")
		hips.append(hip)
		tube(hip,Vector3(0,-.205,0),.10,.085,.43,cloth,Vector3(1,1,.9))
		var knee := pivot(hip,Vector3(0,-.43,0),"Knee")
		knees.append(knee)
		tube(knee,Vector3(0,-.19,0),.085,.063,.40,cloth.darkened(.10))
		var foot := pivot(knee,Vector3(0,-.39,0),"Ankle")
		feet.append(foot)
		# Rounded instep, visible toe and stitched sole; not floating blocks.
		ellipsoid(foot,Vector3(0,.015,-.06),Vector3(.18,.14,.32),dark)
		box(foot,Vector3(0,-.059,-.057),Vector3(.17,.035,.30),Color("a39981"))
		tube(knee,Vector3(0,-.27,0),.084,.073,.25,dark)
		for y in [-.20,-.27,-.33]: tube(knee,Vector3(0,y,0),.085,.085,.016,trim.darkened(.18))
	torso = pivot(self,Vector3(0,.9,0),"Body")
	# Tapered torso, two overlapping lapels and a layered sash give a hanfu silhouette.
	tube(torso,Vector3(0,.25,0),.245,.19,.50,coat,Vector3(1,1,.65))
	ellipsoid(torso,Vector3(0,.44,0),Vector3(.45,.16,.28),coat)
	box(torso,Vector3(-.052,.355,-.151),Vector3(.069,.32,.024),ivory,Vector3(0,0,-.48))
	box(torso,Vector3(.07,.32,-.158),Vector3(.058,.39,.026),ivory,Vector3(0,0,.48))
	box(torso,Vector3(.13,.105,-.154),Vector3(.035,.28,.027),coat.lightened(.14),Vector3(0,0,.48))
	tube(torso,Vector3(0,.035,0),.211,.218,.105,dark,Vector3(1,1,.72))
	tube(torso,Vector3(0,.055,0),.217,.22,.027,trim,Vector3(1,1,.73))
	box(torso,Vector3(-.03,.04,-.165),Vector3(.075,.075,.035),trim)
	for side: float in [-1.0,1.0]:
		var hem := pivot(torso,Vector3(side*.105,0,0),"SplitRobe")
		hems.append(hem)
		var length := .65 if role == "teacher" else .43
		tube(hem,Vector3(0,-length*.5,0),.119,.16,length,coat,Vector3(1,1,1.04))
		box(hem,Vector3(side*.025,-length+.045,-.139),Vector3(.17,.026,.02),trim)
		box(hem,Vector3(side*.06,-length*.5,-.13),Vector3(.018,length-.08,.016),coat.lightened(.15))
	if role == "worker":
		box(torso,Vector3(0,-.16,-.19),Vector3(.28,.40,.025),Color("b7a082"))
		box(torso,Vector3(.065,-.13,-.212),Vector3(.12,.12,.023),Color("806b51"))
	if role == "guard":
		for y in [.16,.25,.34]:
			box(torso,Vector3(0,y,-.165),Vector3(.33,.075,.05),Color("485b5b"))
		for side: float in [-1.0,1.0]: ellipsoid(torso,Vector3(side*.25,.44,0),Vector3(.24,.13,.33),Color("59696a"))
	for side: float in [-1.0,1.0]:
		var shoulder := pivot(torso,Vector3(side*.242,.43,0),"Shoulder")
		arms.append(shoulder)
		ellipsoid(shoulder,Vector3(0,-.015,0),Vector3(.18,.18,.20),coat)
		tube(shoulder,Vector3(0,-.125,0),.095,.11,.27,coat)
		var elbow := pivot(shoulder,Vector3(0,-.255,0),"Elbow")
		elbows.append(elbow)
		tube(elbow,Vector3(0,-.12,0),.105,.075,.26,coat)
		tube(elbow,Vector3(0,-.23,0),.08,.08,.055,ivory)
		var hand := pivot(elbow,Vector3(0,-.285,0),"Hand")
		hands.append(hand)
		ellipsoid(hand,Vector3(0,-.016,0),Vector3(.085,.115,.055),skin)
		ellipsoid(hand,Vector3(-side*.04,.006,-.015),Vector3(.035,.065,.035),skin)
		for finger in 3: box(hand,Vector3(-.026+finger*.025,-.064,-.002),Vector3(.018,.033,.035),skin)
	tube(torso,Vector3(0,.52,0),.07,.085,.13,skin)
	head = pivot(torso,Vector3(0,.55,0),"Head")
	ellipsoid(head,Vector3(0,.15,-.005),Vector3(.285,.365,.275),skin)
	ellipsoid(head,Vector3(0,.036,-.034),Vector3(.19,.115,.17),skin)
	for side: float in [-1.0,1.0]:
		ellipsoid(head,Vector3(side*.145,.15,0),Vector3(.055,.087,.046),skin)
		ellipsoid(head,Vector3(side*.056,.175,-.132),Vector3(.058,.027,.014),ivory)
		ellipsoid(head,Vector3(side*.057,.175,-.141),Vector3(.023,.026,.012),Color("292a25"))
		box(head,Vector3(side*.056,.211,-.132),Vector3(.067,.012,.018),hair_color,Vector3(0,0,side*.08))
		box(head,Vector3(side*.13,.198,-.022),Vector3(.025,.15,.12),hair_color)
	ellipsoid(head,Vector3(0,.145,-.146),Vector3(.037,.072,.052),skin.lightened(.05))
	box(head,Vector3(0,.083,-.132),Vector3(.063,.009,.009),Color("895f51"))
	# Hair cap is deliberately above the eyes, with temple locks and a tied rear bun.
	var cap := SphereMesh.new()
	cap.radius = .148
	cap.height = .148
	cap.is_hemisphere = true
	cap.radial_segments = 12
	part(head,cap,Vector3(0,.225,.009),hair_color,Vector3(1,1.05,1))
	ellipsoid(head,Vector3(0,.21,.103),Vector3(.24,.19,.10),hair_color)
	ellipsoid(head,Vector3(0,.386,.055),Vector3(.12,.13,.13),hair_color)
	tube(head,Vector3(0,.367,.055),.065,.065,.023,trim)
	if hairstyle == 1:
		ellipsoid(head,Vector3(0,.11,.15),Vector3(.10,.26,.10),hair_color)
		ellipsoid(head,Vector3(0,-.04,.15),Vector3(.07,.15,.08),hair_color)
	if elder:
		tube(head,Vector3(0,-.027,-.11),.06,.012,.19,Color("dedbd0"),Vector3(1,1,.55),Vector3(-.16,0,0))
		for side: float in [-1.0,1.0]: box(head,Vector3(side*.038,.102,-.142),Vector3(.07,.015,.025),Color("dedbd0"),Vector3(0,0,side*.17))
	if straw:
		tube(head,Vector3(0,.369,0),.025,.36,.16,Color("a9915f"))
		tube(head,Vector3(0,.294,0),.36,.36,.018,Color("d0bb87"))
	if role == "teacher":
		box(head,Vector3(0,.41,.055),Vector3(.08,.12,.11),trim)
		box(head,Vector3(0,.44,.055),Vector3(.24,.02,.025),ivory)
	build_props()
	bake_bones(self)
	last_position = global_position
	pose(0)
func bake_bones(parent: Node3D) -> void:
	# Merge the static pieces on each joint using vertex colours. Animation keeps its pivots,
	# but faces/fingers/trim no longer cost one draw call per tiny piece.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := 0
	for child in parent.get_children():
		if child is MeshInstance3D:
			var mesh: MeshInstance3D = child
			var arrays: Array = mesh.mesh.surface_get_arrays(0)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var color: Color = mesh.material_override.albedo_color
			for j in (indices.size() if indices.size() else verts.size()):
				var k := indices[j] if indices.size() else j
				st.set_color(color.lerp(color.srgb_to_linear(),.4))
				st.set_normal((mesh.transform.basis.inverse().transposed()*normals[k]).normalized())
				st.add_vertex(mesh.transform*verts[k])
			count += 1
			parent.remove_child(child)
			child.queue_free()
		elif child is Node3D: bake_bones(child)
	if count:
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.roughness = .9
		var result := MeshInstance3D.new()
		result.name = "BoneMesh"
		result.mesh = st.commit()
		result.material_override = m
		parent.add_child(result)
func build_props() -> void:
	var book := pivot(self,Vector3(0,1.13,-.40),"OpenBook")
	for side: float in [-1.0,1.0]:
		box(book,Vector3(side*.082,0,0),Vector3(.165,.025,.23),Color("545b55"),Vector3(-.20,0,-side*.15))
		box(book,Vector3(side*.078,.017,0),Vector3(.15,.015,.215),Color("d8c7a0"),Vector3(-.20,0,-side*.15))
		for row in 5: box(book,Vector3(side*.075,.042,-.075+row*.03),Vector3(.10,.003,.004),Color("80775f"))
	props.book = book
	var broom := pivot(self,Vector3(.30,.88,-.30),"Broom")
	tube(broom,Vector3(0,-.10,0),.017,.021,1.32,Color("826345"),Vector3.ONE,Vector3(.16,0,0))
	tube(broom,Vector3(0,-.83,-.10),.055,.17,.28,Color("ab9869"),Vector3(1,1,.45))
	tube(broom,Vector3(0,-.71,-.08),.075,.075,.05,Color("6c5e43"),Vector3(1,1,.5))
	props.broom = broom
	var staff := pivot(self,Vector3(.34,.99,-.10),"Staff")
	tube(staff,Vector3.ZERO,.024,.03,1.98,Color("664f38"))
	ellipsoid(staff,Vector3(0,1.02,0),Vector3(.10,.12,.10),trim)
	props.staff = staff
	var cup := pivot(hands[0],Vector3(0,-.03,-.05),"Cup")
	tube(cup,Vector3.ZERO,.055,.04,.085,Color("a7b7ae"))
	props.cup = cup
func set_activity(value: String) -> void: activity = value
func _process(delta: float) -> void:
	time += delta
	var distance := Vector2(global_position.x-last_position.x,global_position.z-last_position.z).length()
	last_position = global_position
	var actual_speed := distance/maxf(delta,.001) if distance < .6 else 0.0
	stride_span = lerpf(stride_span,clampf(actual_speed*.12,.27,.52),minf(1,delta*6))
	if distance < .6:
		travel += distance
		# Stance covers 60% of the cycle. Match its backwards foot travel to body travel.
		phase += distance*TAU/(2*stride_span/.60)
	var target := clampf(actual_speed/.25,0,1)
	moving_speed = move_toward(moving_speed,target,delta*7)
	pose(delta)
func pose(_delta: float) -> void:
	var walk := moving_speed
	var talk := minf(speaking,1)
	var read := activity == "read" and walk < .1
	var sweep := activity == "sweep" and walk < .1
	var train := activity == "train" and walk < .1
	var tea := activity == "tea" and walk < .1
	var sit := activity == "sit" and walk < .1
	var tend := activity == "tend" and walk < .1
	torso.rotation = Vector3(-bow+sin(time*1.7)*.009-(.22 if tend else .07 if sweep else 0),0,sin(time*1.1)*.009)
	head.rotation.x = -.20 if read or tend else -.05*sin(time*5)*talk
	head.rotation.y = .08*sin(time*.63)
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		# During the planted half-cycle a foot moves backwards relative to the body.
		var cycle := fposmod(phase/TAU+i*.5,1.0)
		var z: float
		var lift := 0.0
		if cycle < .60: z = lerpf(-stride_span,stride_span,cycle/.60)
		else:
			var k := (cycle-.60)/.40
			z = lerpf(stride_span,-stride_span,k)
			lift = sin(k*PI)*.12
		# Lower the hip inside the overlapping tunic during a stride so the leg can
		# actually reach its planted target instead of clamping and lifting the sole.
		var hip_height := .9-walk*stride_span*.4
		if train: hip_height = .87
		if sit: hip_height = .9
		hips[i].position.y = hip_height
		var target := Vector2(z*walk,-(hip_height-.08)+lift*walk)
		if train: target.x = side*.20
		# Two-bone leg solve. The ankle counter-rotates to keep the sole horizontal.
		var len := clampf(target.length(),.1,.829)
		var knee_angle := -(PI-acos(clampf((.43*.43+.40*.40-len*len)/(2*.43*.40),-1,1)))
		var hip_angle := atan2(-target.x,-target.y)+acos(clampf((.43*.43+len*len-.40*.40)/(2*.43*len),-1,1))
		hips[i].rotation.x = hip_angle
		knees[i].rotation.x = knee_angle
		feet[i].rotation.x = -hip_angle-knee_angle
		feet[i].position.y = -.39
		if sit:
			hips[i].rotation.x = PI*.5
			knees[i].rotation.x = -PI*.5
			feet[i].rotation.x = 0
			feet[i].position.y = -.45
		hems[i].rotation.x = hip_angle*.32*walk
		hems[i].position.y = .09 if sit else 0.0
		hems[i].scale.z = .4 if sit else 1.0
		if sit: hems[i].rotation.x = PI*.5
		arms[i].rotation = Vector3(sin(phase+PI*i)*.42*walk,0,side*.08)
		elbows[i].rotation.x = .10+.15*walk
		if read:
			arms[i].rotation = Vector3(.58,side*.25,-side*.04)
			elbows[i].rotation.x = 1.12
		elif sweep:
			arms[i].rotation = Vector3(.20,0,-side*.05+sin(time*1.8)*.12)
			elbows[i].rotation.x = .7 if i == 1 else .25
		elif train:
			arms[i].rotation = Vector3(.9+sin(time*1.65+PI*i)*.65,side*.18,side*.13)
			elbows[i].rotation.x = .45+.4*(.5+.5*cos(time*1.65+PI*i))
		elif tend:
			arms[i].rotation.x = .4+.12*sin(time*1.8+PI*i)
		elif tea and i == 0:
			arms[i].rotation.x = .4
			elbows[i].rotation.x = 1.25+.2*sin(time*.7)
		elif talk > .01 and i == 0:
			arms[i].rotation.x = .35+.10*sin(time*2.7)
			elbows[i].rotation.x = .85+.22*sin(time*2)
	props.book.visible = read
	props.broom.visible = sweep
	props.broom.rotation.z = sin(time*1.8)*.12
	props.staff.visible = role == "guard" or role == "teacher"
	props.cup.visible = tea
	if props.staff.visible:
		arms[1].rotation.x = .20
		arms[1].rotation.z = -.14
		elbows[1].rotation.x = -.1

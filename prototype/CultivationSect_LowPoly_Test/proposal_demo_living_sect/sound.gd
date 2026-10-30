extends Node
## Procedural sound for the proposal demo. The project and workspace contain no audio files, so
## short effects and two loops are synthesised once at startup (about 0.3 s) into AudioStreamWAV.
## Buses: "Ambience" (wind, birds, the flowing basin) and "Effects" (interface, Qi, footsteps),
## both created here at runtime and sent to Master; the Esc menu sets their volumes and mutes.
## Kept quiet so the presenter's narration stays clear.
const RATE := 22050
const BASE_DB := {"wind": -17.0, "birds": -24.0, "water": -9.0}
var streams := {}
var players := {}
var wind: AudioStreamPlayer
var birds: AudioStreamPlayer
var water: AudioStreamPlayer3D
var water_tween: Tween
var bird_wait := 6.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	for bus: String in ["Ambience", "Effects"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count-1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count-1, "Master")
	set_volume("Ambience", .5)
	set_volume("Effects", .8)
	var effects := {"click": [click(), -16.0], "success": [chime([784.0, 1174.7], .12, 1.3), -8.0], "note": [knock(330.0), -12.0],
		"error": [knock(294.0, 247.0), -10.0], "awaken": [shimmer(), -7.0], "channel": [whoosh(), -8.0], "basin": [bell(), -6.0],
		"recognition": [chime([587.3, 740.0, 880.0, 1174.7, 1480.0], .11, 1.6), -8.0], "step": [footstep(), -21.0]}
	for id: String in effects:
		var p := AudioStreamPlayer.new()
		p.stream = effects[id][0]
		p.volume_db = effects[id][1]
		p.bus = "Effects"
		p.max_polyphony = 3
		add_child(p)
		players[id] = p
	wind = AudioStreamPlayer.new()
	wind.stream = wind_loop()
	wind.bus = "Ambience"
	wind.volume_db = -60
	add_child(wind)
	wind.play()
	create_tween().tween_property(wind, "volume_db", BASE_DB.wind, 3.0)        # fade in, never restarted
	birds = AudioStreamPlayer.new()
	birds.stream = chirp()
	birds.bus = "Ambience"
	birds.volume_db = BASE_DB.birds
	add_child(birds)
	water = AudioStreamPlayer3D.new()
	water.stream = water_loop()
	water.bus = "Ambience"
	water.unit_size = 5.0
	water.max_distance = 32.0
	water.volume_db = -60

func _process(delta: float) -> void:
	bird_wait -= delta
	if bird_wait <= 0:
		bird_wait = rng.randf_range(7.0, 15.0)
		birds.pitch_scale = rng.randf_range(.85, 1.2)
		birds.play()

func play(id: String) -> void:
	var p: AudioStreamPlayer = players.get(id)
	if p == null: return
	if id == "step" or id == "click": p.pitch_scale = rng.randf_range(.88, 1.12)
	p.play()

func set_volume(bus: String, linear: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), linear_to_db(maxf(linear, .0001)))

func set_muted(on: bool) -> void:
	AudioServer.set_bus_mute(0, on)

func start_water(basin: Node3D) -> void:
	"""The basin's flowing water, positioned at the basin; fades in rather than starting abruptly."""
	if water.get_parent() != basin:
		if water.get_parent(): water.get_parent().remove_child(water)
		basin.add_child(water)
		water.position = Vector3(0, .9, 0)
	if water_tween: water_tween.kill()
	if not water.playing: water.play()
	water_tween = create_tween()
	water_tween.tween_property(water, "volume_db", BASE_DB.water, 2.5)

func reset() -> void:
	"""Reset Demo: stop the Qi and basin sounds; the wind keeps blowing."""
	for id: String in players: players[id].stop()
	if water_tween: water_tween.kill()
	water.stop()
	water.volume_db = -60

# ---------------------------------------------------------------- synthesis
func wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size()*2)
	for i in samples.size(): data.encode_s16(i*2, int(clampf(samples[i], -1, 1)*32000))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		# Not size(): Godot 4.7.2 mixes the frame at loop_end too, which reads past the buffer and
		# crashes Android (godotengine/godot#124849). Dropping one frame of a crossfaded loop is inaudible.
		w.loop_end = samples.size()-1
	return w

func seamless(s: PackedFloat32Array, fade: int) -> PackedFloat32Array:
	"""Crossfades the last `fade` samples into the start, so the loop point is inaudible."""
	var n := s.size()-fade
	var out := s.slice(0, n)
	for i in fade:
		var a := float(i)/fade
		out[i] = s[n+i]*(1.0-a)+s[i]*a
	return out

func bell_note(out: PackedFloat32Array, at: float, f: float, decay: float, gain: float) -> void:
	var start := int(at*RATE)
	for i in range(start, out.size()):
		var t := float(i-start)/RATE
		var env := exp(-t/decay)*minf(1.0, t*200.0)
		out[i] += gain*env*(sin(TAU*f*t)+.35*sin(TAU*f*2.76*t)*exp(-t*3.0)+.12*sin(TAU*f*5.4*t)*exp(-t*6.0))

func chime(notes: Array, gap: float, decay: float) -> AudioStreamWAV:
	var out := PackedFloat32Array()
	out.resize(int((gap*notes.size()+decay*2.2)*RATE))
	for i in notes.size(): bell_note(out, i*gap, notes[i], decay*.45, .32)
	return wav(out)

func knock(f1: float, f2 := 0.0) -> AudioStreamWAV:
	"""A soft wooden tone (one note for a lesson-rule note, two falling notes for an error)."""
	var out := PackedFloat32Array()
	out.resize(int(.75*RATE))
	for k in (2 if f2 > 0 else 1):
		var f := f1 if k == 0 else f2
		var start := int(k*.16*RATE)
		for i in range(start, out.size()):
			var t := float(i-start)/RATE
			out[i] += .45*exp(-t*9.0)*minf(1.0, t*300.0)*(sin(TAU*f*t)+.3*sin(TAU*f*2.0*t))
	return wav(out)

func click() -> AudioStreamWAV:
	var out := PackedFloat32Array()
	out.resize(int(.05*RATE))
	for i in out.size():
		var t := float(i)/RATE
		out[i] = .5*exp(-t*140.0)*sin(TAU*(1900.0-6000.0*t)*t)
	return wav(out)

func footstep() -> AudioStreamWAV:
	var out := PackedFloat32Array()
	out.resize(int(.12*RATE))
	var y := 0.0
	for i in out.size():
		var t := float(i)/RATE
		y += .18*(rng.randf_range(-1, 1)-y)
		out[i] = exp(-t*45.0)*(1.4*y+.5*sin(TAU*85.0*t))
	return wav(out)

func shimmer() -> AudioStreamWAV:
	"""Qi awakening: a rising arpeggio of bell tones over a soft breath of air."""
	var out := PackedFloat32Array()
	out.resize(int(2.8*RATE))
	var notes := [293.7, 440.0, 587.3, 740.0, 880.0, 1174.7]
	for i in notes.size(): bell_note(out, .1+i*.13, notes[i], .75, .2)
	var y := 0.0
	for i in out.size():
		var t := float(i)/RATE
		y += (.02+.1*minf(t, 1.0))*(rng.randf_range(-1, 1)-y)
		out[i] += .35*y*sin(PI*minf(t/1.6, 1.0))
	return wav(out)

func whoosh() -> AudioStreamWAV:
	"""Qi leaving the apprentice for the basin: an air sweep ending in a soft chime."""
	var out := PackedFloat32Array()
	out.resize(int(1.9*RATE))
	var y := 0.0
	for i in out.size():
		var t := float(i)/RATE
		y += (.03+.25*minf(t/.9, 1.0))*(rng.randf_range(-1, 1)-y)
		out[i] = .7*y*sin(PI*minf(t/.95, 1.0))
	bell_note(out, .85, 1174.7, .5, .22)
	return wav(out)

func bell() -> AudioStreamWAV:
	"""The basin wakes: a low temple bell."""
	var out := PackedFloat32Array()
	out.resize(int(3.6*RATE))
	for i in out.size():
		var t := float(i)/RATE
		var env := exp(-t/1.3)*minf(1.0, t*80.0)
		out[i] = .45*env*(sin(TAU*110.0*t)+.6*sin(TAU*220.6*t)*exp(-t)+.4*sin(TAU*303.6*t)*exp(-t*1.5)+.25*sin(TAU*418.0*t)*exp(-t*2.2))
	return wav(out)

func chirp() -> AudioStreamWAV:
	var out := PackedFloat32Array()
	out.resize(int(.6*RATE))
	for k in 3:
		var start := int((.02+k*.15)*RATE)
		for i in range(start, mini(start+int(.07*RATE), out.size())):
			var t := float(i-start)/RATE
			out[i] += .3*sin(PI*t/.07)*sin(TAU*(2900.0+9000.0*t)*t)
	return wav(out)

func wind_loop() -> AudioStreamWAV:
	"""Eight seconds of soft wind: filtered noise whose colour and level drift slowly."""
	var n := int(9.0*RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var y := 0.0
	var z := 0.0
	for i in n:
		var t := float(i)/RATE
		var swell := .55+.25*sin(TAU*t/9.0)+.2*sin(TAU*t/4.5+1.3)
		y += (.012+.02*swell)*(rng.randf_range(-1, 1)-y)
		z += .2*(y-z)
		out[i] = 2.2*z*swell
	return wav(seamless(out, RATE), true)

func water_loop() -> AudioStreamWAV:
	"""Four seconds of trickling water: bright filtered noise with small droplet blips."""
	var n := int(4.6*RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lo := 0.0
	var hi := 0.0
	for i in n:
		var x := rng.randf_range(-1, 1)
		lo += .35*(x-lo)
		hi += .06*(x-hi)
		out[i] = .32*(lo-hi)*(.8+.2*sin(TAU*float(i)/RATE*3.1))
	for k in 46:
		var start := rng.randi_range(0, n-RATE/10)
		var f := rng.randf_range(500.0, 1300.0)
		for i in range(start, start+int(.035*RATE)):
			var t := float(i-start)/RATE
			out[i] += .14*exp(-t*120.0)*sin(TAU*(f+f*6.0*t)*t)
	return wav(seamless(out, int(.6*RATE)), true)

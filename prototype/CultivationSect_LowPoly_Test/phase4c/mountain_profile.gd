extends RefCounted
## Broad, connected ridge crests. Knots carry x/z, elevation above the existing
## foothill, and separate left/right shoulder widths. No fine surface noise.
var sections: Array = []

func _init() -> void:
	# A winding horseshoe crosses the backdrop bounds at its southern ends.
	# The low northern saddle stays behind the Hall; high summits flank its axis.
	var backbone: Array = [
		[-285,400,86,122,82],[-247,306,105,136,94],[-261,222,128,112,142],
		[-231,155,103,158,106],[-279,81,116,136,88],[-238,12,138,118,162],
		[-263,-65,110,157,112],[-216,-147,156,122,168],[-247,-219,172,155,107],
		[-181,-271,131,115,146],[-116,-294,83,142,108],[-32,-323,47,110,140],
		[56,-329,53,139,103],[124,-290,87,126,165],[182,-309,145,161,106],
		[220,-247,164,117,154],[188,-184,124,152,111],[263,-111,140,126,171],
		[237,-25,101,166,108],[279,37,122,117,155],[244,111,92,156,124],
		[231,187,136,109,158],[279,265,98,170,113],[253,400,79,128,160]
	]
	add_crest(backbone)
	# Unequal lateral spurs merge into the long ridge instead of separate peaks.
	add_crest([[-247,-219,172,95,100],[-194,-201,122,88,110],[-165,-164,62,90,74]])
	add_crest([[263,-111,140,100,98],[221,-99,105,82,119],[185,-59,56,100,78]])
	add_crest([[-261,222,128,92,103],[-210,210,92,116,80],[-163,244,43,89,110]])
	add_crest([[231,187,136,90,120],[184,204,96,110,79],[145,241,49,88,117]])

func spline(a: float,b: float,c: float,d: float,t: float) -> float:
	return .5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t)

func add_crest(knots: Array) -> void:
	var previous: Array = []
	for i in range(knots.size()-1):
		for j in range(9):
			if i>0 and j==0: continue
			var t := float(j)/8.0
			var sample: Array = []
			for component in 5:
				sample.append(spline(knots[maxi(0,i-1)][component],knots[i][component],knots[i+1][component],knots[mini(knots.size()-1,i+2)][component],t))
			if not previous.is_empty():
				var a := Vector2(previous[0],previous[1])
				var b := Vector2(sample[0],sample[1])
				sections.append({"a":a,"delta":b-a,"length_squared":a.distance_squared_to(b),"from":previous,"to":sample})
			previous = sample

func height(x: float,z: float) -> float:
	var p := Vector2(x,z)
	var ridge_height := 0.0
	for s: Dictionary in sections:
		var t := clampf((p-s.a).dot(s.delta)/s.length_squared,0,1)
		var offset: Vector2 = p-(s.a+s.delta*t)
		var side := 3 if s.delta.cross(offset)>0 else 4
		var width := lerpf(s.from[side],s.to[side],t)
		# Long cross-sections form ridges, not radial cones. Different flank widths
		# and gentle crest curvature make summits offset and slopes asymmetric.
		var q := offset.length()/width
		if q>=1: continue
		var shoulder := pow(1.0-pow(q,1.25),1.15)
		var elevation := lerpf(s.from[2],s.to[2],t)*shoulder
		ridge_height = maxf(ridge_height,elevation)
	return ridge_height

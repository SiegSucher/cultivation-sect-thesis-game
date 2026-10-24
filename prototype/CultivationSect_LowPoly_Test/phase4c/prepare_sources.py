"""Create only the Phase 4C terrain derivative and measurement record."""
from pathlib import Path
import json,math
ROOT=Path(__file__).resolve().parents[1]
HERE=Path(__file__).resolve().parent
layout=json.loads((ROOT/'mountain_valley_compact/layout.json').read_text())
slopes=[]
for path in layout['paths']:
    for a,b in zip(path['points'],path['points'][1:]):
        if a[1]==b[1]:continue
        run=math.hypot(b[0]-a[0],b[2]-a[2]);rise=abs(b[1]-a[1]);angle=math.degrees(math.atan2(rise,run))
        nominal=22 if path['id'] in {'middle_stairs','cloud'} else 24 if path['id']=='grand' else None
        slopes.append(dict(route=path['id'],horizontal_run_m=run,rise_m=rise,actual_degrees=angle,
                           installed_nominal_degrees=nominal,
                           per_2m_end_difference_mm=(2000*(math.tan(math.radians(nominal))-rise/run)) if nominal else None))
(HERE/'review/stair-slopes.json').write_text(json.dumps(slopes,indent=2),encoding='utf-8')
t=(ROOT/'mountain_valley_compact/terrain_builder.gd').read_text(encoding='utf-8')
t=t.replace('res://mountain_valley_compact/resources/','res://phase4c/resources/')
t=t.replace('res://mountain_valley_compact/focused_stair_terrain.gd','res://phase4c/focused_stair_terrain.gd')
start=t.index('\tvar radius :=',t.index('func height('))
end=t.index('\tfor pad: Dictionary in pads:',start)
t=t[:start]+'''\t# Retain the reviewed foothill calculation inside the occupied valley.
\t# Outside it, the connected crest profile below replaces these radial peaks.
	var radius := Vector2(x/205.0,(z-10)/235.0).length()
	var h := 28.0*pow(clampf((radius-.62)/.9,0,1),1.3)
	var peak := 0.0
	for ridge: Array in [[-205,-225,154,110,122],[185,-250,168,115,110],[-255,-35,126,88,140],[256,25,116,90,140],[-205,240,132,110,112],[205,245,112,112,118],[-78,-305,82,100,65],[65,-326,68,115,65]]:
		var q := Vector2((x-ridge[0])/ridge[3],(z-ridge[1])/ridge[4]).length()
		peak = maxf(peak,pow(maxf(0,1-q),.82)*ridge[2])
	h += peak
	var rough := clampf((radius-.53)*1.5,0,1)
	h += (sin(x*.061+z*.026)*3.2+sin(x*.022-z*.059)*2.1)*rough
''' + t[end:]
t=t.replace('var ramp_faces := PackedVector3Array()', 'var ramp_faces := PackedVector3Array()\nvar mountain_profile = preload("res://phase4c/mountain_profile.gd").new()')
insertion=t.index('\tfor pad: Dictionary in pads:',t.index('func height('))
t=t[:insertion]+'''\t# Replace only the outer backdrop, feathering into the exact previous ground.
\t# Every occupied shelf, route, retaining cut and stair lies inside this box.
\tvar outside := Vector2(maxf(absf(x)-156.0,0.0),maxf(maxf(-170.0-z,z-190.0),0.0)).length()
\tvar backdrop_weight := smoothstep(0.0,48.0,outside)
\tif backdrop_weight>0:
\t\tvar foothill := 28.0*pow(clampf((radius-.62)/.9,0,1),1.3)
\t\th = lerpf(h,foothill+mountain_profile.height(x,z),backdrop_weight)
''' + t[insertion:]
t=t.replace('func build(root: Node3D) -> void:', 'func build(root: Node3D,terrain_only: bool = false) -> void:')
t=t.replace('\troot.add_child(body)\n', '\troot.add_child(body)\n\t# Focused backdrop rebuilds preserve existing roads, visible stairs and ramps.\n\tif terrain_only: return\n')
t=t.replace('if edge < 14:\n\t\t\tvar weight := 1.0 if inside else pow(1.0-edge/14.0,.65)',
'''var shoulder := 17.0+3.5*sin(x*.045+z*.027)
		if edge < shoulder:
			var weight := 1.0 if inside else smoothstep(0.0,1.0,1.0-edge/shoulder)''')
# Usable courts and building support stay at approved elevations. Changes are
# outside those surfaces except the faces hidden inside selected retaining walls.
t=t.replace('\treturn h\n\nfunc near_route', '''\tfor court: Dictionary in data.forecourts:
		if absf(x-court.position[0])<=court.size[0]*.5+.5 and absf(z-court.position[2])<=court.size[1]*.5+.5:
			return float(court.position[1])-.015
	return h

func near_route''')
t=t.replace('var color := Color("637552")','var color := Color("606e50")').replace('Color("626c61")','Color("5b655f")').replace('Color("879285")','Color("858c80")').replace('Color("5d6966")','Color("64716c")').replace('Color("78827a")','Color("7a8278")')
t=t.replace('Color("777d72")','Color("7e867b")').replace('Color("667b80")','Color("4f6267")')
needle='\t\t\t\tvar outward := Vector3(a.x-b.x,0,a.z-b.z).normalized()'
insert='''\t\t\t\tvar nose_dir := Vector3(q.x-p.x,0,q.z-p.z).normalized()*.045
				var nose_a := Vector3(p.x,high+.002,p.z)
				road_quad(nose_a-side,nose_a+side,nose_a+nose_dir+side,nose_a+nose_dir-side,Color("9aa394"))
'''
t=t.replace(needle,insert+needle)
# Refine only the hidden/visible edges of new retaining cuts, before the proven
# stair fitting pass. No baseline mesh or resource is edited.
t=t.replace('\t# Phase 4B keeps this focused terrain correction reproducible without',
'''\tvar cuts = load("res://phase4c/retaining_terrain.gd").new()
	var cut: Dictionary = cuts.apply(vertices,normals,colors)
	vertices = cut.vertices
	normals = cut.normals
	colors = cut.colors
	# Phase 4B keeps this focused terrain correction reproducible without''')
(HERE/'terrain_builder.gd').write_text(t,encoding='utf-8')
f=(ROOT/'mountain_valley_compact/focused_stair_terrain.gd').read_text(encoding='utf-8')
f=f.replace('f.half+1.5','f.half+1.9').replace('(side-f.half-.2)/1.3','(side-f.half-.9)/1.0')
(HERE/'focused_stair_terrain.gd').write_text(f,encoding='utf-8')
print('Prepared Phase 4C terrain derivative; approved layout data reused unchanged')

"""Reuse proven map logic as independent compact sources; never edit large map."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
HERE=Path(__file__).resolve().parent
measure=(ROOT/'mountain_valley/measure_assets.gd').read_text(encoding='utf-8').replace('res://reports/mountain-valley/','res://mountain_valley_compact/review/')
(HERE/'measure_assets.gd').write_text(measure,encoding='utf-8')
t=(ROOT/'mountain_valley/terrain_builder.gd').read_text(encoding='utf-8').replace('res://mountain_valley/','res://mountain_valley_compact/')
t=t.replace('"width":float(path.width),"kind":path.kind','"width":float(path.width),"kind":path.kind,"id":path.id')
t=t.replace('Vector2(x/315.0,(z-10.0)/365.0)','Vector2(x/float(data.mountain.radius[0]),(z-data.mountain.center_z)/float(data.mountain.radius[1]))')
t=t.replace('atan2(z-10,x)','atan2(z-data.mountain.center_z,x)').replace('180.0+36.0*sin(angle*5.0+.4)+22.0*sin(angle*9.0)','float(data.mountain.crest)+25.0*sin(angle*5.0+.4)+16.0*sin(angle*9.0)')
t=t.replace('h,18.55,','h,float(pond.floor_y),')
t=t.replace('var lo := -560\n\tvar hi := 560','var min_x := int(data.dimensions.terrain_bounds[0])\n\tvar min_z := int(data.dimensions.terrain_bounds[1])\n\tvar max_x := int(data.dimensions.terrain_bounds[2])\n\tvar max_z := int(data.dimensions.terrain_bounds[3])')
t=t.replace('range(lo,hi+step,step):','range(min_x,max_x+step,step):',1).replace('range(lo,hi+step,step):','range(min_z,max_z+step,step):',1)
t=t.replace('range(lo,hi,step):','range(min_x,max_x,step):',1).replace('range(lo,hi,step):','range(min_z,max_z,step):',1)
# Every measured footprint gets an exact flat supporting shelf. Road shaping
# may lower the nearby ground, but may not cut a different tier under a building.
t=t.replace('return lerpf(h,desired,blend)','''h = lerpf(h,desired,blend)
	for b: Dictionary in data.buildings:
		var at := vec(b.position)
		var local := Basis(Vector3.UP,-deg_to_rad(b.yaw))*Vector3(x-at.x,0,z-at.z)
		if local.x>=b.bounds.min[0]-4.1 and local.x<=b.bounds.max[0]+4.1 and local.z>=b.bounds.min[2]-4.1 and local.z<=b.bounds.max[2]+4.1:
			return at.y-.015
	return h''')
(HERE/'terrain_builder.gd').write_text(t,encoding='utf-8')
w=(ROOT/'mountain_valley/valley_walkthrough.gd').read_text(encoding='utf-8').replace('res://mountain_valley/','res://mountain_valley_compact/')
stops='''const STOPS := {
	KEY_2: [Vector3(0,4.1,94),0.0,"Sect entrance"],
	KEY_3: [Vector3(0,10.1,42),0.0,"Living court"],
	KEY_4: [Vector3(-97,14.1,17),0.0,"Training connection"],
	KEY_5: [Vector3(12,24.1,-51),0.0,"Main Hall"],
	KEY_6: [Vector3(102,10.1,18),0.0,"Healing garden"],
	KEY_7: [Vector3(-48,28.1,-110),0.0,"Scholarly ledge"],
	KEY_8: [Vector3(77,20.1,-67),0.0,"Alchemy ridge"],
}'''
w=re.sub(r'const STOPS := \{.*?\n\}',lambda _:stops,w,count=1,flags=re.S)
w=w.replace('Vector3(12,.12,320)','Vector3(8,.12,134)').replace('player.yaw = .8','player.yaw = 1.39').replace('Vector3(8,.12,134),.8','Vector3(8,.12,134),1.39')
w=w.replace('MOUNTAIN SECT / ENVIRONMENT REVIEW','COMPACT PHASE 4B / UNAPPROVED').replace('520 × 640','320 × 400').replace('environment polish review','compact layout review')
w=w.replace('review_camera.far = 1800','review_camera.far = 1000').replace('review_camera.size = 740','review_camera.size = 440')
w=w.replace('Vector3(0,850,32)','Vector3(0,500,10)').replace('Vector3(0,0,32)','Vector3(0,0,10)').replace('Vector3(285,245,365)','Vector3(202,155,230)').replace('Vector3(-5,30,-44)','Vector3(0,15,3)')
(HERE/'valley_walkthrough.gd').write_text(w,encoding='utf-8')
print('Prepared compact measurement and terrain sources')

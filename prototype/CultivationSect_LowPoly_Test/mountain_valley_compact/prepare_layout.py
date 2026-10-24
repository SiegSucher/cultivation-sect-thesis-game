"""Independent compact Phase 4B layout; original architecture stays full-size."""
from pathlib import Path
import json,math
ROOT=Path(__file__).resolve().parents[1]
HERE=Path(__file__).resolve().parent
measure=json.loads((HERE/'review/asset-measurements.json').read_text())
def pad(id,name,y,color,polygon): return dict(id=id,name=name,y=y,color=color,polygon=polygon)
pads=[
 pad('forest','Short forest reveal',0,'#758262',[[-47,163],[47,166],[49,128],[28,103],[-28,101],[-50,126]]),
 pad('arrival','Gate terrace',4,'#a19b78',[[-34,99],[35,99],[40,77],[28,59],[-30,59],[-40,78]]),
 pad('living','Living streets',10,'#9c9f79',[[-47,66],[66,68],[77,47],[71,-2],[46,-10],[-42,-8],[-52,13]]),
 pad('training','Training terrace',14,'#ae9b76',[[-145,23],[-56,24],[-48,2],[-54,-57],[-131,-63],[-149,-43]]),
 pad('landing','Cloud stair landing',16,'#929e82',[[0,-18],[35,-17],[40,-29],[26,-38],[0,-38]]),
 pad('alchemy','Alchemy ridge',20,'#a59b86',[[57,-39],[98,-39],[105,-68],[97,-107],[61,-109],[51,-77]]),
 pad('inner','Main Hall terrace',24,'#bac0a0',[[-23,-42],[48,-42],[57,-64],[52,-119],[30,-132],[-15,-128],[-28,-98]]),
 pad('scholar','Scripture / elder ledge',28,'#b6baa2',[[-73,-65],[-28,-64],[-21,-96],[-27,-145],[-53,-154],[-74,-135],[-80,-92]]),
 pad('garden','Healing gardens',10,'#759a81',[[79,33],[129,35],[149,10],[151,-40],[137,-65],[98,-65],[78,-43],[74,-5]]),
]
entries=[
 ['sect_gate',0,4,80,0,'arrival','01 Sect Gate'],
 ['mission_hall',-25,10,15,0,'living','02 Mission Hall'],
 ['exchange_hall',35,10,14,0,'living','03 Exchange Hall'],
 ['disciple_residence',-28,10,51,180,'living',"04 Disciples' Residence"],
 ['dining_hall_kitchen',40,10,52,180,'living','05 Dining / Kitchen'],
 ['martial_training_ground',-97,14,-21,0,'training','06 Martial Training'],
 ['main_sect_hall',12,24,-98,0,'inner','07 Main Sect Hall'],
 ['scripture_pavilion',-48,28,-128,0,'scholar','08 Scripture Pavilion'],
 ['elder_residence',-49,28,-88,0,'scholar','09 Elder Residence'],
 ['alchemy_pavilion',77,20,-82,0,'alchemy','10 Alchemy Pavilion'],
 ['medicine_hall',102,10,4,0,'garden','11 Medicine Hall'],
 ['spirit_herb_garden',121,10,-39,0,'garden','12 Spirit Herb Garden'],
]
buildings=[]
for aid,x,y,z,yaw,district,label in entries:
    bounds=measure['buildings'][aid]
    buildings.append(dict(id=aid,position=[x,y,z],yaw=yaw,district=district,label=label,resource=bounds['resource'],bounds=bounds))
def path(id,name,width,points,kind='stone'):return dict(id=id,name=name,width=width,points=points,kind=kind)
paths=[
 path('forest','Forest reveal',7,[[8,0,134],[-3,0,132],[-14,0,115],[0,0,105]],'earth'),
 path('entry_stairs','Gate arrival stair',12,[[0,0,105],[0,4,94]],'stairs'),
 path('arrival','Gate and arrival court',10,[[0,4,94],[0,4,80],[0,4,65]]),
 path('middle_stairs','Living terrace stair',12,[[0,4,65],[0,10,50]],'stairs'),
 path('living','Living spine',10,[[0,10,50],[0,10,35],[0,10,17],[0,10,4]]),
 path('street','Shared living street',8,[[-44,10,35],[-25,10,35],[0,10,35],[35,10,35],[65,10,35]]),
 path('mission','Mission approach',6,[[-25,10,35],[-25,10,30]]),
 path('exchange','Exchange approach',6,[[35,10,35],[35,10,26]]),
 path('residence','Residence approach',6,[[-28,10,35],[-28,10,43]]),
 path('dining','Dining approach',6,[[40,10,35],[40,10,41]]),
 path('training_link','Training connection',10,[[-44,10,35],[-47,10,35],[-58,14,19],[-97,14,18]],'stairs'),
 path('training_entry','Training forecourt',12,[[-97,14,18],[-97,14,13]]),
 path('cloud','Inner-sect stair',12,[[0,10,4],[12,10,-6],[12,16,-21],[12,16,-29]],'stairs'),
 path('grand','Hall ceremonial stair',16,[[12,16,-29],[12,24,-47]],'stairs'),
 path('hall','Hall forecourt',14,[[12,24,-47],[12,24,-65],[12,24,-79]]),
 path('scholar','Scholarly connection',8,[[12,24,-58],[-12,24,-58],[-32,28,-68]],'stairs'),
 path('library','Library lane',6,[[-32,28,-68],[-26,28,-108],[-48,28,-108],[-48,28,-112]]),
 path('elder','Elder approach',6,[[-32,28,-68],[-49,28,-70],[-49,28,-73]]),
 path('alchemy','Alchemy connection',8,[[12,16,-24],[48,16,-25],[64,20,-43],[77,20,-60],[77,20,-69]],'stairs'),
 path('garden','Healing lane',7,[[65,10,35],[83,10,25],[102,10,16],[117,10,16],[121,10,-12],[121,10,-21]],'earth'),
 path('overlook','Pond overlook',5,[[121,10,-12],[142,10,-17],[143,10,-46]],'earth'),
]
courts=[
 dict(name='Arrival court',position=[0,4,66.5],size=[34,15]),
 dict(name='Living common',position=[1,10,35],size=[24,18]),
 dict(name='Hall forecourt',position=[12,24,-64],size=[48,30]),
 dict(name='Training apron',position=[-97,14,17],size=[42,12]),
 dict(name='Scholar junction',position=[-47,28,-108],size=[22,10]),
 dict(name='Healing approach',position=[102,10,18],size=[20,12]),
 dict(name='Cliff overlook',position=[143,10,-46],size=[12,12]),
]
main_ids=['forest','entry_stairs','arrival','middle_stairs','living','cloud','grand','hall']
main=[]
for id in main_ids:
    points=next(p['points'] for p in paths if p['id']==id)
    main.extend(points if not main else points[1:])
length=sum(math.dist(a,b) for a,b in zip(main,main[1:]))
layout=dict(title='SPLIT-CLOUD VALLEY / COMPACT PHASE 4B',
 dimensions=dict(playable=[320,400],playable_bounds=[-160,-180,160,220],scenery=[640,720],terrain_bounds=[-320,-340,320,380],grid=4),
 mountain=dict(radius=[205,235],center_z=10,crest=126),player=measure['player'],
 pads=pads,buildings=buildings,paths=paths,forecourts=courts,
 pond=dict(center=[92,-36],radius=[10,9],water_y=9.35,floor_y=8.55),
 spawn=[8,.12,134],main_route_ids=main_ids,main_route=main,main_route_metres=length,walk_time_seconds=length/4)
# No scaled buildings, and no overlapping measured X/Z envelopes at a shared tier.
def corners(b):
    x,y,z=b['position'];m=b['bounds'];a=math.radians(b['yaw'])
    return [(x+xx*math.cos(a)+zz*math.sin(a),z-xx*math.sin(a)+zz*math.cos(a))
            for xx,zz in [(m['min'][0],m['min'][2]),(m['max'][0],m['min'][2]),(m['max'][0],m['max'][2]),(m['min'][0],m['max'][2])]]
for i,b in enumerate(buildings):
    c=corners(b);b['world_envelope']=[min(p[0] for p in c),min(p[1] for p in c),max(p[0] for p in c),max(p[1] for p in c)]
    for other in buildings[:i]:
        if other['position'][1]!=b['position'][1]:continue
        a=other['world_envelope'];d=b['world_envelope']
        assert min(a[2],d[2])<=max(a[0],d[0]) or min(a[3],d[3])<=max(a[1],d[1]),(b['id'],other['id'])
(HERE/'layout.json').write_text(json.dumps(layout,indent=2),encoding='utf-8')
print('Compact main route:',round(length,2),'m;',round(length/4,2),'seconds. All twelve measured envelopes separated.')

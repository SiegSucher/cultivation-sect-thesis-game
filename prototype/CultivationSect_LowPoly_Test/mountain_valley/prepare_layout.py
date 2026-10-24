"""Author the new metre-based layout and a matching SVG review plan.

Only new map resources/reports are written. Existing assets are never rebuilt.
"""
from pathlib import Path
import hashlib
import html
import json
import math

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'reports/mountain-valley'
OUT.mkdir(parents=True, exist_ok=True)

def manifest(base):
    return {p.relative_to(base).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in base.rglob('*') if p.is_file()
            and not any(x in {'.godot','.git','__pycache__'} for x in p.relative_to(base).parts)
            and not (base == ROOT and p.relative_to(base).parts[0] in {'mountain_valley'})
            and not (base == ROOT and p.relative_to(base).as_posix().startswith('reports/mountain-valley/'))}

frozen = OUT/'before-hashes.json'
if not frozen.exists():
    frozen.write_text(json.dumps({'test':manifest(ROOT),
                                 'original':manifest(ROOT.parent/'asset-workshop'),
                                 'old_map':manifest(ROOT.parents[1]/'assets/maps/prototype')},indent=2),encoding='utf-8')

measured = json.loads((OUT/'asset-measurements.json').read_text())
assert measured['player']['height'] == 1.8 or abs(measured['player']['height']-1.8)<.001
assert measured['buildings']['martial_training_ground']['size'][0] >= 67.9

pads = [
    dict(id='forest', name='Outer mountain approach', y=0, color='#758262',
         polygon=[[-105,345],[70,350],[98,275],[63,218],[36,165],[-28,166],[-94,205],[-117,283]]),
    dict(id='arrival', name='Lower entrance terrace', y=8, color='#a19b78',
         polygon=[[-56,156],[56,156],[61,117],[46,91],[-48,91],[-63,119]]),
    dict(id='living', name='Middle living terrace', y=20, color='#9c9f79',
         polygon=[[-91,87],[83,87],[98,60],[90,-19],[61,-32],[-83,-29],[-108,-4],[-106,60]]),
    dict(id='training', name='Martial training terrace', y=28, color='#ae9b76',
         polygon=[[-209,10],[-108,12],[-101,-19],[-107,-104],[-196,-111],[-219,-73]]),
    dict(id='landing', name='Cloud-stair landing', y=32, color='#929e82',
         polygon=[[-22,-71],[47,-54],[50,-81],[26,-99],[-22,-96]]),
    dict(id='alchemy', name='Alchemy ridge', y=40, color='#a59b86',
         polygon=[[71,-78],[127,-77],[136,-105],[127,-150],[77,-151],[66,-117]]),
    dict(id='inner', name='Upper inner sect', y=48, color='#bac0a0',
         polygon=[[-67,-107],[64,-107],[78,-133],[70,-218],[37,-237],[-49,-231],[-77,-191]]),
    dict(id='scholar', name='Scholarly and elder ledge', y=56, color='#b6baa2',
         polygon=[[-168,-128],[-81,-130],[-67,-166],[-75,-229],[-121,-246],[-165,-221],[-178,-166]]),
    dict(id='garden', name='Healing garden and cliff', y=20, color='#759a81',
         polygon=[[96,37],[182,34],[215,0],[224,-65],[200,-107],[146,-110],[109,-86],[94,-35]]),
]
buildings = [
    ['sect_gate',0,8,130,0,'arrival','01 Sect Gate'],
    ['mission_hall',-52,20,8,0,'living','02 Mission Hall'],
    ['exchange_hall',30,20,5,0,'living','03 Exchange Hall'],
    ['disciple_residence',-64,20,63,180,'living',"04 Disciples' Residence"],
    ['dining_hall_kitchen',48,20,62,180,'living','05 Dining / Kitchen'],
    ['martial_training_ground',-155,28,-53,0,'training','06 Martial Training'],
    ['main_sect_hall',0,48,-192,0,'inner','07 Main Sect Hall'],
    ['scripture_pavilion',-110,56,-210,0,'scholar','08 Scripture Pavilion'],
    ['elder_residence',-140,56,-164,0,'scholar','09 Elder Residence'],
    ['alchemy_pavilion',101,40,-124,0,'alchemy','10 Alchemy Pavilion'],
    ['medicine_hall',123,20,-17,0,'garden','11 Medicine Hall'],
    ['spirit_herb_garden',175,20,-74,0,'garden','12 Spirit Herb Garden'],
]
records=[]
for aid,x,y,z,yaw,pad,label in buildings:
    m=measured['buildings'][aid]
    records.append(dict(id=aid,position=[x,y,z],yaw=yaw,district=pad,label=label,
                        resource=m['resource'],bounds=m))

def path(id, name, width, points, kind='stone'):
    return dict(id=id,name=name,width=width,points=points,kind=kind)

paths=[
    path('forest','Winding forest trail',7,[[12,0,320],[-24,0,285],[-58,0,248],[-50,0,211],[-17,0,184],[0,0,164]],'earth'),
    path('entry_stairs','Arrival stair',12,[[0,0,164],[0,8,145]],'stairs'),
    path('arrival','Arrival axis',10,[[0,8,145],[0,8,130],[0,8,101]]),
    path('middle_stairs','Living stair',12,[[0,8,101],[0,20,71]],'stairs'),
    path('living','Living spine',10,[[0,20,71],[0,20,30],[0,20,-16]]),
    path('street','Market and mission street',8,[[-84,20,31],[-52,20,31],[0,20,31],[31,20,31],[76,20,31]]),
    path('mission','Mission threshold',6,[[-52,20,31],[-52,20,24]]),
    path('exchange','Exchange threshold',6,[[30,20,31],[30,20,17]]),
    path('residence','Residence lane',6,[[-64,20,31],[-64,20,49]]),
    path('dining','Dining lane',6,[[48,20,31],[48,20,45]]),
    path('training_link','Training ridge stair',10,[[0,20,-5],[-87,20,-5],[-113,28,-5],[-155,28,-5]],'stairs'),
    path('training_entry','Training approach',12,[[-155,28,-5],[-155,28,-19]]),
    path('cloud','Winding cloud stair',12,[[0,20,-16],[28,20,-33],[28,32,-65],[0,32,-80]],'stairs'),
    path('grand','Upper ceremonial stair',16,[[0,32,-80],[0,48,-116]],'stairs'),
    path('hall','Hall forecourt axis',14,[[0,48,-116],[0,48,-145],[0,48,-173]]),
    path('scholar','Scholarly stair',9,[[0,48,-139],[-48,48,-139],[-86,56,-143],[-110,56,-157]],'stairs'),
    path('library','Library approach',7,[[-110,56,-157],[-110,56,-192]]),
    path('elder','Elder lane',6,[[-110,56,-145],[-140,56,-145]]),
    path('alchemy','Alchemy ridge path',8,[[28,32,-75],[64,32,-75],[92,40,-86],[101,40,-105]],'stairs'),
    path('garden','Healing garden lane',7,[[76,20,31],[104,20,21],[123,20,3],[154,20,-33],[175,20,-48],[175,20,-57]],'earth'),
    path('overlook','Pond and cliff walk',5,[[154,20,-33],[180,20,-29],[204,20,-47],[207,20,-78]],'earth'),
]
forecourts=[
    dict(name='Arrival court',position=[0,8,109],size=[44,22]),
    dict(name='Living commons',position=[-4,20,31],size=[27,24]),
    dict(name='Hall forecourt',position=[0,48,-142],size=[58,48]),
    dict(name='Training apron',position=[-155,28,-10],size=[46,15]),
    dict(name='Library court',position=[-110,56,-181],size=[32,17]),
    dict(name='Healing court',position=[123,20,3],size=[26,17]),
    dict(name='Cliff overlook',position=[207,20,-78],size=[17,15]),
]
data=dict(title='SPLIT-CLOUD VALLEY / NEW MAP BLOCKOUT',
          dimensions=dict(playable=[520,640],playable_bounds=[-260,-280,260,360],
                          scenery=[1120,1120],terrain_bounds=[-560,-560,560,560],grid=4),
          player=measured['player'],pads=pads,buildings=records,paths=paths,forecourts=forecourts,
          pond=dict(center=[146,-71],radius=[12,12],water_y=19.35),
          spawn=[12,.12,320])
distance=0
for pid in ['forest','entry_stairs','arrival','middle_stairs','living','cloud','grand','hall']:
    route=next(p for p in paths if p['id']==pid)
    distance+=sum(math.dist(a,b) for a,b in zip(route['points'],route['points'][1:]))
# The living path ends at the cloud stair's start. The total includes the slight
# overlap in its branch definition only once; this main sequence is contiguous.
data['main_route_metres']=round(distance,1)
data['walk_time_seconds']=round(distance/measured['player']['speed'])
(ROOT/'mountain_valley/layout.json').write_text(json.dumps(data,indent=2),encoding='utf-8')

# Standalone metre-based plan. The same polygons, road lines and measured bounds
# drive the 3D build, so the diagram cannot silently use a different layout.
W,H=1500,1440
S=1.55
def xy(x,z): return (x*S+505,z*S+490)
def pts(points): return ' '.join(f'{xy(p[0],p[-1])[0]:.1f},{xy(p[0],p[-1])[1]:.1f}' for p in points)
svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">',
     '<rect width="1500" height="1440" fill="#172a2d"/>',
     '<style>text{font-family:Segoe UI,Arial,sans-serif;fill:#ecedde}.small{font-size:16px}.body{font-size:19px}.head{font-size:27px;font-weight:650}</style>',
     '<text x="48" y="55" class="head">SPLIT-CLOUD VALLEY</text>',
     '<text x="48" y="85" class="body">New mountain-sect blockout · metres · north at top · all buildings at original scale</text>',
     '<rect x="40" y="114" width="930" height="1110" rx="20" fill="#33473f"/>']
for i in range(12):
    x=80+i*76
    svg.append(f'<path d="M{x},365 l-45,-95 l55,-95 l70,110 l-20,100" fill="#465a4f" stroke="#617167"/>')
for pad in pads:
    svg.append(f'<polygon points="{pts(pad["polygon"])}" fill="{pad["color"]}" stroke="#d9dec2" stroke-width="1.3"/>')
for p in forecourts:
    x,y,z=p['position'];w,d=p['size'];xx,zz=xy(x-w/2,z-d/2)
    svg.append(f'<rect x="{xx}" y="{zz}" width="{w*S}" height="{d*S}" fill="#d1c5a3" opacity=".8"/>')
for p in paths:
    svg.append(f'<polyline points="{pts(p["points"])}" fill="none" stroke="{"#d5ba81" if p["kind"]=="earth" else "#f0e4bd"}" stroke-width="{p["width"]*S}" stroke-linejoin="round" stroke-linecap="round"/>')
cx,cz=xy(*data['pond']['center']);rx,rz=data['pond']['radius']
svg.append(f'<ellipse cx="{cx}" cy="{cz}" rx="{rx*S}" ry="{rz*S}" fill="#478c94" stroke="#b0c1ae"/>')
for n,b in enumerate(records,1):
    x,y,z=b['position'];bb=b['bounds'];a=math.radians(b['yaw'])
    corners=[]
    for xx,zz in [(bb['min'][0],bb['min'][2]),(bb['max'][0],bb['min'][2]),(bb['max'][0],bb['max'][2]),(bb['min'][0],bb['max'][2])]:
        corners.append([x+xx*math.cos(a)+zz*math.sin(a),z-xx*math.sin(a)+zz*math.cos(a)])
    svg.append(f'<polygon points="{pts(corners)}" fill="#265c57" stroke="#243e38" stroke-width="2"/>')
    xx,zz=xy(x,z)
    svg.append(f'<circle cx="{xx}" cy="{zz}" r="13" fill="#172a2d"/><text x="{xx}" y="{zz+5}" text-anchor="middle" class="small">{n:02}</text>')
    tipx,tipz=xy(x+math.sin(a)*16,z+math.cos(a)*16)
    svg.append(f'<path d="M{xx},{zz} L{tipx},{tipz}" stroke="#cda668" stroke-width="3"/>')
sx,sz=xy(12,320)
svg.append(f'<circle cx="{sx}" cy="{sz}" r="8" fill="#f4d17f"/><text x="{sx+15}" y="{sz+6}" class="body">START / 0 m</text>')
svg += ['<text x="1007" y="160" class="head">BUILDINGS</text>']
for i,b in enumerate(records):
    w,h,d=b['bounds']['size']
    y=200+i*53
    svg.append(f'<text x="1007" y="{y}" class="body">{html.escape(b["label"])}</text>')
    svg.append(f'<text x="1038" y="{y+22}" class="small">{w:.1f} × {d:.1f} m footprint · elevation +{b["position"][1]} m</text>')
svg += ['<text x="1007" y="890" class="head">TIERS AND ROUTES</text>']
for i,text in enumerate(['0 m — forest approach','8 m — gate / arrival court','20 m — living / healing gardens','28 m — martial training','32 m — cloud-stair landing','40 m — alchemy ridge','48 m — Main Hall / forecourt','56 m — scripture / elder ledge','Primary stairs: 12–16 m wide','Streets: 6–10 m · trail: 7 m']):
    svg.append(f'<text x="1007" y="{930+i*29}" class="small">{html.escape(text)}</text>')
svg += ['<text x="50" y="1270" class="head">SCALE AND COMPOSITION</text>',
        f'<text x="50" y="1306" class="body">Playable planning envelope 520 × 640 m · mountain backdrop 1,120 × 1,120 m</text>',
        f'<text x="50" y="1338" class="body">Spawn → Hall forecourt: {distance:.0f} m / about {distance/240:.1f} min at the unchanged 4 m/s walk speed</text>',
        '<text x="50" y="1370" class="body">Mountain bowl surrounds the terraces; the southern forest route is the arrival opening.</text>',
        '<text x="50" y="1402" class="small">Review blockout only. Dark teal = measured building envelopes. Gold strokes point toward entrances. Detailed district decoration is deferred.</text>',
        '<path d="M83,1186h155 M83,1178v16 M238,1178v16" stroke="#efdfb5" stroke-width="3"/>',
        '<text x="120" y="1170" class="small">100 m</text>',
        '<text x="910" y="160" class="head">N ↑</text>','</svg>']
(OUT/'layout-plan.svg').write_text('\n'.join(svg),encoding='utf-8')
print('Prepared',len(records),'measured building placements; main route',round(distance),'m')

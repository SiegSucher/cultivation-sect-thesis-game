"""Raster review diagram, drawn from the same measured layout as the 3D scene."""
from pathlib import Path
import json
import math
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'reports/mountain-valley'
data=json.loads((ROOT/'mountain_valley/layout.json').read_text())
image=Image.new('RGB',(1500,1440),'#172a2d')
draw=ImageDraw.Draw(image)
def font(size,bold=False):
    return ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf' if bold else 'C:/Windows/Fonts/segoeui.ttf',size)
def text(x,y,s,size=19,fill='#ecedde',bold=False):
    draw.text((x,y),s,font=font(size,bold),fill=fill)
def xy(x,z): return (round(x*1.55+505),round(z*1.55+490))
def pts(points): return [xy(p[0],p[-1]) for p in points]
text(48,24,'SPLIT-CLOUD VALLEY',30,bold=True)
text(48,65,'New mountain-sect blockout · metres · north at top · original building scale',20)
draw.rounded_rectangle((40,114,970,1224),radius=20,fill='#33473f')
for i in range(12):
    x=80+i*76
    draw.polygon([(x,365),(x-45,270),(x+10,175),(x+80,285),(x+60,385)],fill='#465a4f')
for p in data['pads']:
    poly=pts(p['polygon'])
    draw.polygon(poly,fill=p['color'])
    draw.line(poly+[poly[0]],fill='#d9dec2',width=2)
for p in data['forecourts']:
    x,y,z=p['position'];w,d=p['size']
    draw.rectangle((*xy(x-w/2,z-d/2),*xy(x+w/2,z+d/2)),fill='#c4bc9c')
for p in data['paths']:
    line=pts(p['points']);width=round(p['width']*1.55)
    color='#d5ba81' if p['kind']=='earth' else '#f0e4bd'
    draw.line(line,fill=color,width=width,joint='curve')
    for x,z in line:
        r=width/2
        draw.ellipse((x-r,z-r,x+r,z+r),fill=color)
cx,cz=xy(*data['pond']['center']);rx,rz=data['pond']['radius']
draw.ellipse((cx-rx*1.55,cz-rz*1.55,cx+rx*1.55,cz+rz*1.55),fill='#478c94',outline='#b0c1ae',width=2)
for i,b in enumerate(data['buildings'],1):
    x,y,z=b['position'];a=math.radians(b['yaw']);m=b['bounds']
    corners=[]
    for xx,zz in [(m['min'][0],m['min'][2]),(m['max'][0],m['min'][2]),(m['max'][0],m['max'][2]),(m['min'][0],m['max'][2])]:
        corners.append(xy(x+xx*math.cos(a)+zz*math.sin(a),z-xx*math.sin(a)+zz*math.cos(a)))
    draw.polygon(corners,fill='#265c57',outline='#213b35',width=2)
    px,pz=xy(x,z)
    draw.line([(px,pz),xy(x+math.sin(a)*17,z+math.cos(a)*17)],fill='#cda668',width=3)
    draw.ellipse((px-13,pz-13,px+13,pz+13),fill='#172a2d')
    text(px-9,pz-11,f'{i:02}',16)
for x,z,label in [(-110,320,'FOREST APPROACH / 0 m'),(41,160,'ENTRANCE / +8 m'),
                  (-93,84,'LIVING STREETS / +20 m'),(-219,-112,'TRAINING / +28 m'),
                  (17,-232,'INNER SECT / +48 m'),(-174,-250,'SCHOLARLY LEDGE / +56 m'),
                  (74,-153,'ALCHEMY / +40 m'),(189,25,'GARDEN / +20 m')]:
    px,pz=xy(x,z)
    text(px,pz,label,15,fill='#ffffff',bold=True)
sx,sz=xy(12,320)
draw.ellipse((sx-7,sz-7,sx+7,sz+7),fill='#f4d17f')
text(sx+14,sz-12,'START',18)
text(1007,130,'BUILDINGS',27,bold=True)
for i,b in enumerate(data['buildings']):
    w,h,d=b['bounds']['size'];y=180+i*53
    text(1007,y,b['label'],19)
    text(1038,y+25,f'{w:.1f} × {d:.1f} m footprint · elevation +{b["position"][1]} m',16)
text(1007,860,'TIERS AND ROUTES',26,bold=True)
for i,line in enumerate(['0 m — forest approach','8 m — gate / arrival court','20 m — living / healing gardens',
                         '28 m — martial training','32 m — cloud-stair landing','40 m — alchemy ridge',
                         '48 m — Main Hall / forecourt','56 m — scripture / elder ledge',
                         'Primary stairs: 12–16 m wide','Streets: 6–10 m · trail: 7 m']):
    text(1007,908+i*29,line,17)
text(50,1240,'SCALE AND COMPOSITION',27,bold=True)
text(50,1283,'Playable planning envelope 520 × 640 m · mountain backdrop 1,120 × 1,120 m',21)
text(50,1320,f'Start → Hall forecourt: {data["main_route_metres"]:.0f} m / about {data["walk_time_seconds"]/60:.1f} min at the unchanged 4 m/s walk speed',21)
text(50,1357,'Mountain bowl encloses the terraces; the southern forest route forms the arrival opening.',20)
text(50,1400,'Review blockout. Teal shapes = measured building envelopes. Gold strokes point toward entrances. Detailed decoration is deferred.',17)
draw.line([(83,1186),(238,1186)],fill='#efdfb5',width=3)
for x in [83,238]: draw.line([(x,1178),(x,1194)],fill='#efdfb5',width=3)
text(125,1148,'100 m',17)
text(908,137,'N',25,bold=True)
draw.polygon([(920,170),(912,188),(928,188)],fill='#efdfb5')
image.save(OUT/'layout-plan.png')
print('Saved',OUT/'layout-plan.png')

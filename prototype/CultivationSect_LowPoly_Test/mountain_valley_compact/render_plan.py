"""Labeled compact layout and demonstration route from the exact 3D data."""
from pathlib import Path
import json,math
from PIL import Image,ImageDraw,ImageFont
HERE=Path(__file__).resolve().parent
data=json.loads((HERE/'layout.json').read_text())
image=Image.new('RGB',(1500,1410),'#172a2d');draw=ImageDraw.Draw(image)
def font(n,bold=False):return ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf' if bold else 'C:/Windows/Fonts/segoeui.ttf',n)
def text(x,y,s,n=18,color='#ecedde',bold=False):draw.text((x,y),s,font=font(n,bold),fill=color)
def xy(x,z):return(round(480+x*2.4),round(552+z*2.4))
def pts(points):return[xy(p[0],p[-1]) for p in points]
text(45,22,'SPLIT-CLOUD VALLEY / COMPACT PHASE 4B',29,bold=True)
text(45,65,'320 × 400 m planning envelope · full-size buildings · unapproved layout for visual review',20)
draw.rounded_rectangle((40,114,950,1142),radius=18,fill='#33473f')
# The dashed frame is the actual planning envelope, not a conversion from 2D pixels.
for x in range(96,865,18):
    draw.line((x,120,min(x+8,864),120),fill='#8c9f91',width=1)
    draw.line((x,1080,min(x+8,864),1080),fill='#8c9f91',width=1)
for z in range(120,1081,18):
    draw.line((96,z,96,min(z+8,1080)),fill='#8c9f91',width=1)
    draw.line((864,z,864,min(z+8,1080)),fill='#8c9f91',width=1)
for p in data['pads']:
    poly=pts(p['polygon']);draw.polygon(poly,fill=p['color']);draw.line(poly+[poly[0]],fill='#c7d2bb',width=2)
for c in data['forecourts']:
    x,y,z=c['position'];w,d=c['size'];draw.rectangle((*xy(x-w/2,z-d/2),*xy(x+w/2,z+d/2)),fill='#c8c0a4')
for p in data['paths']:
    line=pts(p['points']);width=round(p['width']*2.4);color='#d3be8c' if p['kind']=='earth' else '#e3dcc0'
    draw.line(line,fill=color,width=width,joint='curve')
    for x,z in line:draw.ellipse((x-width/2,z-width/2,x+width/2,z+width/2),fill=color)
cx,cz=xy(*data['pond']['center']);rx,rz=data['pond']['radius']
draw.ellipse((cx-rx*2.4,cz-rz*2.4,cx+rx*2.4,cz+rz*2.4),fill='#478c94',outline='#bfd2c4',width=2)
main=pts(data['main_route']);draw.line(main,fill='#e5ad53',width=5,joint='curve')
for i in [0,4,7,10,14,len(main)-1]:
    x,z=main[i];draw.ellipse((x-4,z-4,x+4,z+4),fill='#f4d592')
for i,b in enumerate(data['buildings'],1):
    x,y,z=b['position'];m=b['bounds'];a=math.radians(b['yaw']);corners=[]
    for xx,zz in [(m['min'][0],m['min'][2]),(m['max'][0],m['min'][2]),(m['max'][0],m['max'][2]),(m['min'][0],m['max'][2])]:
        corners.append(xy(x+xx*math.cos(a)+zz*math.sin(a),z-xx*math.sin(a)+zz*math.cos(a)))
    draw.polygon(corners,fill='#265c57',outline='#203a34',width=2)
    px,pz=xy(x,z);draw.line([(px,pz),xy(x+math.sin(a)*15,z+math.cos(a)*15)],fill='#cda668',width=3)
    draw.ellipse((px-13,pz-13,px+13,pz+13),fill='#172a2d');text(px-9,pz-12,f'{i:02}',16)
for x,z,label in [(-148,-67,'TRAINING +14 m'),(-77,-159,'SCHOLARLY +28 m'),(-19,-135,'INNER SECT +24 m'),
                  (57,-115,'ALCHEMY +20 m'),(-48,70,'LIVING +10 m'),(123,38,'HEALING +10 m'),(16,100,'GATE +4 m'),(-44,167,'SHORT FOREST / 0 m')]:
    px,pz=xy(x,z);text(px,pz,label,15,'#ffffff',True)
sx,sz=xy(data['spawn'][0],data['spawn'][2]);text(sx+10,sz-15,'START',18,'#f5d496',True)
text(1000,130,'TWELVE EXISTING BUILDINGS',24,bold=True)
for i,b in enumerate(data['buildings']):
    w,h,d=b['bounds']['size'];y=175+i*48
    text(1000,y,b['label'],18);text(1031,y+23,f'{w:.1f} × {d:.1f} m · ground +{b["position"][1]} m',15)
text(1000,785,'DEMONSTRATION ROUTE',23,bold=True)
text(1000,825,f'{data["main_route_metres"]:.1f} m / {data["walk_time_seconds"]:.1f} s at 4 m/s',20,'#f4d592',True)
text(1000,862,'Gold line: forest → Gate → living → Hall',16)
text(1000,891,'Training and library are short visit branches.',16)
text(1000,930,'MAIN CONNECTIONS',22,bold=True)
for i,s in enumerate(['Arrival / living stairs: 12 m wide','Hall stair: 16 m wide','Living street: 8 m · side lanes: 6 m','Forest trail: 7 m · overlook: 5 m','No building or player scaling','No sprint or teleport-based route']):text(1000,968+i*27,s,16)
draw.line((120,1050,360,1050),fill='#efdfb5',width=3)
for x in [120,360]:draw.line((x,1041,x,1059),fill='#efdfb5',width=3)
text(200,1013,'100 m',17);text(896,136,'N',24,bold=True);draw.polygon([(906,170),(898,187),(914,187)],fill='#efdfb5')
text(45,1160,'COMPARISON WITH THE LARGE VERSION',25,bold=True)
for i,s in enumerate(['Planning envelope: 520 × 640 m → 320 × 400 m (62% less area)',
                       f'Forest-to-Hall route: 586 m → {data["main_route_metres"]:.0f} m (59% shorter)',
                       'Mountain backdrop: 1,120 × 1,120 m → 640 × 720 m; tier heights 0–28 m',
                       'Suggested proposal tour: main route + Training + library branches, with five short stops ≈ 4 minutes',
                       'Large scene, Phase 4A and all canonical assets are retained unchanged. This is a separate review scene.']):
    text(45,1205+i*35,s,19)
image.save(HERE/'review/layout-plan.png')
# Tour estimate is explicit and includes a measured Training out-and-back and
# a final library branch after the Hall, with presentation pauses, not sprinting.
def length(points):return sum(math.dist(a,b) for a,b in zip(points,points[1:]))
by_id={p['id']:p for p in data['paths']}
training=44+length(by_id['training_link']['points'])+length(by_id['training_entry']['points'])
library=21+length(by_id['scholar']['points'])+length(by_id['library']['points'])
walk=data['main_route_metres']+2*training+library
tour={'walk_metres':walk,'nominal_walk_seconds':walk/4,'selected_stops_seconds':{'Gate':15,'Living':20,'Training':20,'Main Hall':25,'Scripture':15},'total_seconds':walk/4+95}
(HERE/'review/proposal-tour.json').write_text(json.dumps(tour,indent=2),encoding='utf-8')
print('Labeled plan saved; selected proposal tour estimate:',round(tour['total_seconds']/60,2),'minutes')

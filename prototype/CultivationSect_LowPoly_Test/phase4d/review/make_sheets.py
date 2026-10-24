"""Label existing captures for inspection; no image retouching."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont
OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[1]
names = [b['id'] for b in json.loads((ROOT/'mountain_valley_compact/layout.json').read_text())['buildings']]
font = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',18)
for mode in ['gameplay','context']:
    for page in range(2):
        sheet = Image.new('RGB',(1280,1152),'#233239')
        draw = ImageDraw.Draw(sheet)
        for index,name in enumerate(names[page*6:page*6+6]):
            path = OUT/f'before-{name}-{mode}.png'
            im = Image.open(path).convert('RGB').resize((640,360))
            x,y = index%2*640,index//2*384
            draw.text((x+8,y+2),name,font=font,fill='white')
            sheet.paste(im,(x,y+24))
        sheet.save(OUT/f'inspection-{mode}-{page+1}.png')

# Matching before/after evidence for every ground connection that changed.
entries = json.loads((ROOT/'phase4d/entrances.json').read_text())
for row in entries:
    if row['apron'] is None:
        continue
    name = row['id']
    for mode in ['gameplay','context']:
        before = OUT/f'before-{name}-{mode}.png'
        after = OUT/f'after-{name}-{mode}.png'
        if not after.exists():
            continue
        a,b = [Image.open(p).convert('RGB') for p in [before,after]]
        assert a.size==b.size
        w,h = a.size
        pair = Image.new('RGB',(w*2,h+36),'#233239')
        pair.paste(a,(0,36)); pair.paste(b,(w,36))
        draw = ImageDraw.Draw(pair)
        draw.text((12,6),name+' | BEFORE: approved Phase 4C',font=font,fill='white')
        draw.text((w+12,6),name+' | AFTER: Phase 4D pending review',font=font,fill='white')
        pair.save(OUT/f'comparison-{name}-{mode}.png')

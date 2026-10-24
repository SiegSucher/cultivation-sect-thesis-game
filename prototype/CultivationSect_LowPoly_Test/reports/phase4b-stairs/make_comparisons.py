from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
OUT=Path(__file__).resolve().parent
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',22)
for name in ['arrival-flight-tpp','living-flight-tpp','arrival-upper-tpp','living-upper-tpp','arrival-edge','living-edge']:
    board=Image.new('RGB',(1920,580),'#19292c')
    draw=ImageDraw.Draw(board)
    for i,phase in enumerate(['before','after']):
        image=Image.open(OUT/f'{phase}-{name}.png')
        image.thumbnail((960,540))
        board.paste(image,(i*960,40))
        draw.text((i*960+16,5),f'{phase.upper()} — {name} / Phase 4B unapproved review',fill='white',font=font)
    board.save(OUT/f'comparison-{name}.png')
print('Saved six matching before/after comparisons')

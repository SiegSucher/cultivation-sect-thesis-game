from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
root=Path(__file__).resolve().parent
files=sorted(root.glob('frame-*.png'))
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',18)
board=Image.new('RGB',(1440,((len(files)+2)//3)*305),'#19292c')
draw=ImageDraw.Draw(board)
for i,p in enumerate(files):
    im=Image.open(p);im.thumbnail((480,280))
    x=(i%3)*480;y=(i//3)*305
    board.paste(im,(x,y))
    draw.text((x+8,y+280),f'{4+i*8:03d} seconds (sample)',font=font,fill='white')
board.save(root/'contact-sheet.png')
print(len(files),'recording samples')

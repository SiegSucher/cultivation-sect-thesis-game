"""Pair unaltered matching gameplay captures for human terrain review."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parent
try:
    font = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 23)
except OSError:
    font = ImageFont.load_default()
for name, title in [
    ('gate-approach', 'Gate approach'), ('living-terrace', 'Living terrace'),
    ('inner-stairs', 'Inner stairs'), ('hall-approach', 'Hall approach'),
    ('valley-overview', 'Valley overview')]:
    before = Image.open(root / f'before-{name}.png').convert('RGB')
    after = Image.open(root / f'after-{name}.png').convert('RGB')
    assert before.size == after.size
    w, h = before.size
    canvas = Image.new('RGB', (w * 2, h + 48), '#233239')
    canvas.paste(before, (0, 48))
    canvas.paste(after, (w, 48))
    draw = ImageDraw.Draw(canvas)
    draw.text((16, 8), f'{title} | BEFORE: approved Phase 4B layout', font=font, fill='white')
    draw.text((w + 16, 8), f'{title} | AFTER: Phase 4C awaiting visual review', font=font, fill='white')
    canvas.save(root / f'comparison-{name}.png')
    print(f'comparison-{name}.png')

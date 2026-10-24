"""Extract comparison resources and assemble matching, unretouched captures."""
from pathlib import Path
from zipfile import ZipFile
import json
from PIL import Image, ImageDraw, ImageFont
from snapshot import ROOT, OUT, hashes

with ZipFile(OUT / 'phase4c-before-mountain-profile.zip') as archive:
    names = ['terrain_mesh.res'] + [p.name for p in (ROOT / 'phase4c/resources').glob('Mountain_*.res')]
    for name in names:
        target = OUT / 'previous-resources' / name
        target.parent.mkdir(exist_ok=True)
        if not target.exists():
            target.write_bytes(archive.read('phase4c/resources/' + name))

font = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 23)
for name, title in [('healing-overlook', 'Healing overlook'), ('hall-approach', 'Main Hall approach'), ('valley-overview', 'Valley overview')]:
    paths = [OUT / f'{prefix}-{name}.png' for prefix in ['before', 'after']]
    if not all(p.exists() for p in paths):
        continue
    before, after = [Image.open(p).convert('RGB') for p in paths]
    assert before.size == after.size
    w, h = before.size
    pair = Image.new('RGB', (w*2, h+48), '#233239')
    pair.paste(before, (0, 48))
    pair.paste(after, (w, 48))
    draw = ImageDraw.Draw(pair)
    draw.text((16, 8), f'{title} | BEFORE: reviewed Phase 4C', font=font, fill='white')
    draw.text((w+16, 8), f'{title} | AFTER: mountain revision / review pending', font=font, fill='white')
    pair.save(OUT / f'comparison-{name}.png')

before = json.loads((OUT / 'before-hashes.json').read_text())
current = hashes(ROOT, True)
modified = [p for p in before if p in current and before[p] != current[p]]
missing = sorted(set(before)-set(current))
added = sorted(set(current)-set(before))
outside = [p for p in modified+missing+added if not p.startswith('phase4c/')]
result = {'pass': not outside and not missing, 'checked_preexisting_files': len(before),
          'modified': modified, 'added': added, 'missing': missing, 'changes_outside_phase4c': outside}
(OUT / 'preservation.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
print(json.dumps(result, indent=2))
raise SystemExit(0 if result['pass'] else 1)

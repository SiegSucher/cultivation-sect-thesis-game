"""Create a real independent copy, recovery archive and SHA-256 evidence."""
from pathlib import Path
import hashlib, json, shutil, zipfile

TEST = Path(__file__).resolve().parents[1]
ORIGINAL = TEST.parent / 'asset-workshop'
manifest = {}
for p in ORIGINAL.rglob('*'):
    if not p.is_file() or '.godot' in p.parts:
        continue
    manifest[p.relative_to(ORIGINAL).as_posix()] = hashlib.sha256(p.read_bytes()).hexdigest()
(TEST/'reports/original_manifest.json').write_text(json.dumps(manifest, indent=2))
for name in ['assets', 'scenes', 'scripts']:
    shutil.copytree(ORIGINAL/name, TEST/name)
shutil.copy2(ORIGINAL/'project.godot', TEST/'project.godot')
with zipfile.ZipFile(TEST/'original_runtime_recovery.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
    for p in TEST.rglob('*'):
        if p.is_file() and p.relative_to(TEST).parts[0] in ['assets', 'scenes', 'scripts', 'project.godot']:
            archive.write(p, p.relative_to(TEST))
baseline = TEST/'baseline'
baseline.mkdir()
shutil.copytree(TEST/'assets/architecture/tang_main_hall', baseline/'hall')
script = (TEST/'scripts/tang_main_hall.gd').read_text()
(baseline/'tang_main_hall.gd').write_text(script.replace('res://assets/architecture/tang_main_hall/', 'res://baseline/hall/'))
attachments = Path('C:/Users/pasto/AppData/Local/Temp')
names = ['dc7122d9-e820-4f94-8d68-15fba15e3b99','1ffce86a-e99d-4914-a154-8a815e5350e1','e8c443bb-86da-403a-9fb3-f13ca00ef3fe','c2524fdf-1147-4d23-a6ac-0788c24f2fe7','daa459e5-a841-4817-a71b-a8497d2f7340','5c7491b2-bfc3-4dca-b95e-9a09214adb07','321de4c1-87cf-440a-8a3a-65bc7e2efcef','caebb330-769f-47ff-b312-7e04e3acdfa3','fa6b44ca-8dc3-4fa4-a102-25e85670a21e']
for name in names:
    p = attachments/f'codex-clipboard-{name}.png'
    shutil.copy2(p, TEST/'reference_images'/p.name)
(TEST/'HANDOFF.md').write_text('''# Isolated Main Sect Hall experiment

Started 22 October 2026. Original: `../asset-workshop`. Test: this folder, a sibling of that runnable project. Original files must never be edited. `original_runtime_recovery.zip` is a full runtime copy; `reports/original_manifest.json` fingerprints all original non-cache files. All four facilities were copied; only Main Hall is eligible for conversion. Baseline hall resources are independently copied under `baseline/`.

The active source has no town or production player. Its ground origin, +Z facing, 41.684 x 30.180 x 18.310 m envelope, collision, three door mechanisms, and 1.8 m inspection controller define this test. Do not resurrect Reedwell. No external assets or plugins. No messages sent to Claude.

References: nine supplied PNGs in `reference_images/`, original filenames retained. Images 1-2: broad timber/plaster and restrained stone; 3-4: faceted shapes and economical surfaces; 5-7: cultivation grandeur and jade roof hierarchy (no copied towers/effects); 8: swept eaves and supported entry (no pagoda copy); 9: warm structural interior, repeated ceiling/rail rhythm (no library conversion).

Godot 4.7.2, GL Compatibility, 1280x720, MSAA=2 (4x), shared tool binary `../../tools/godot/`. No renderer switch. Work begins with runnable copied baseline before rebuilding. Baseline/performance/gameplay/visual evidence pending. Intended low-end hardware unavailable. Do not claim target performance or production gameplay certification.
''', encoding='utf-8')
print(f'Copied runtime; recovery archive and {len(manifest)} original hashes; nine references.')

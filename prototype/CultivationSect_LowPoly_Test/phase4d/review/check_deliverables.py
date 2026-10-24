"""Validate artifact links, canonical scene identities and required captures."""
from pathlib import Path
from urllib.parse import unquote
import json, re

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[1]
catalog = {r['id']:r['resource'] for r in json.loads((ROOT/'assets/gallery/catalog.json').read_text())}
inspection = json.loads((OUT/'after-inspection-record.json').read_text())
canonical = all(r['scene']==catalog[r['id']] for r in inspection['buildings']) and len(inspection['buildings'])==12
assert canonical
missing = []
for doc in [OUT/'REVIEW.md', ROOT/'phase4d/README.md']:
    for link in re.findall(r'\]\(([^)]+)\)',doc.read_text(encoding='utf-8')):
        if not (doc.parent/unquote(link)).exists(): missing.append(str(doc)+': '+link)
for row in json.loads((ROOT/'phase4d/entrances.json').read_text()):
    for view in ['gameplay','context']:
        for prefix in ['before','after']:
            p = OUT/f'{prefix}-{row["id"]}-{view}.png'
            if not p.exists(): missing.append(str(p))
        if row['apron']:
            p = OUT/f'comparison-{row["id"]}-{view}.png'
            if not p.exists(): missing.append(str(p))
engine = ROOT.parent/'reedwell-3d/tools/godot/Godot_v4.7.2-stable_win64.exe'
result = {'pass':canonical and not missing and engine.exists(), 'canonical_buildings':12,
          'medicine_exception_count':inspection['medicine_exception_count'], 'missing_links_or_captures':missing,
          'launcher_engine_exists':engine.exists()}
(OUT/'deliverable-check.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps(result,indent=2))
raise SystemExit(0 if result['pass'] else 1)

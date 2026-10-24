"""Checkpoint evidence without replacing the approved design checkpoint."""
from pathlib import Path
import json,shutil,hashlib
ROOT=Path(__file__).resolve().parents[1]
REPORT=ROOT/'reports/roof-collision-fix-2026-10-22'
REPORT.mkdir(parents=True,exist_ok=True)
BEFORE=REPORT/'before'
BEFORE.mkdir(exist_ok=False)
shutil.copy2(ROOT/'assets/architecture/tang_main_hall/main_sect_hall.json',BEFORE/'main_sect_hall.json')
shutil.copy2(ROOT/'tools/build_split_cloud.py',BEFORE/'build_split_cloud.py')
for name in ['baseline-results.json','optimized-results.json','geometry-audit.json','collision-data-audit.json','constraints-results.json','controls-results.json','performance_comparison.md','low_poly_test_report.md','VERIFICATION_RESULTS.md']:
    shutil.copy2(ROOT/'reports'/name,BEFORE/name)
shutil.copy2(ROOT/'HANDOFF.md',BEFORE/'HANDOFF.md')
shutil.copytree(ROOT/'reports/screenshots',BEFORE/'screenshots')
protected=[*sorted((ROOT/'assets/architecture/tang_main_hall').glob('*.glb')),ROOT/'source/split_cloud_hall.blend',ROOT/'scripts/tang_main_hall.gd',ROOT/'scripts/hall_preview_door.gd',ROOT/'scripts/training_inspection_player.gd',ROOT/'project.godot']
manifest={str(p.relative_to(ROOT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in protected}
(REPORT/'visual-and-gameplay-manifest.json').write_text(json.dumps(manifest,indent=2))
print('Pre-fix collider, authoring code, evidence and approved visual/controller hashes saved.')

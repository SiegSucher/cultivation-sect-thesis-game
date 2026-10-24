"""Preserve the approved Phase 4C payload and hash protected project files."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import hashlib, json, sys

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
def manifest():
    return {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in ROOT.rglob('*') if p.is_file()
            and not any(s in {'.godot', '.git', '__pycache__', 'phase4d'} for s in p.relative_to(ROOT).parts)}

if '--check' not in sys.argv:
    if (OUT/'before-hashes.json').exists(): raise SystemExit('Snapshot already exists; retained.')
    baseline = manifest()
    with ZipFile(OUT/'approved-phase4c-recovery.zip','w',ZIP_DEFLATED) as archive:
        for p in (ROOT/'phase4c').rglob('*'):
            if p.is_file() and 'review' not in p.relative_to(ROOT/'phase4c').parts:
                archive.write(p,p.relative_to(ROOT).as_posix())
        for name in ['REVIEW.md','mountain-profile/REVIEW.md','arrival-rails/REVIEW.md']:
            p = ROOT/'phase4c/review'/name
            archive.write(p,p.relative_to(ROOT).as_posix())
    (OUT/'before-hashes.json').write_text(json.dumps(baseline,indent=2),encoding='utf-8')
    print('Saved approved Phase 4C recovery archive and',len(baseline),'protected file hashes.')
else:
    baseline = json.loads((OUT/'before-hashes.json').read_text())
    current = manifest()
    changed = [p for p in baseline if p in current and baseline[p]!=current[p]]
    missing = sorted(set(baseline)-set(current))
    added = sorted(set(current)-set(baseline))
    result = {'pass':not changed and not missing and not added,'files_checked':len(baseline),'modified':changed,'missing':missing,'added_outside_phase4d':added}
    (OUT/'preservation.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps(result,indent=2))
    raise SystemExit(0 if result['pass'] else 1)

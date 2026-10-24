"""Preserve the approved compact map and record protected payload before Phase 4C."""
from pathlib import Path
import hashlib,json,zipfile
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent
def manifest(base):
    return {p.relative_to(base).as_posix():hashlib.sha256(p.read_bytes()).hexdigest()
            for p in base.rglob('*') if p.is_file()
            and not any(x in {'.godot','.git','__pycache__'} for x in p.relative_to(base).parts)
            and not (base==ROOT and p.relative_to(base).parts[0]=='phase4c')}
target=OUT/'before-hashes.json'
if not target.exists():
    data={'test':manifest(ROOT),'original':manifest(ROOT.parent/'asset-workshop'),
          'old_map':manifest(ROOT.parents[1]/'assets/maps/prototype')}
    target.write_text(json.dumps(data,indent=2),encoding='utf-8')
    with zipfile.ZipFile(OUT/'approved-compact-recovery.zip','w',zipfile.ZIP_DEFLATED) as archive:
        for p in (ROOT/'mountain_valley_compact').rglob('*'):
            if p.is_file() and 'review' not in p.relative_to(ROOT/'mountain_valley_compact').parts:
                archive.write(p,p.relative_to(ROOT).as_posix())
        for name in ['review/REVIEW.md','review/build-summary.json','review/walking-results.json']:
            p=ROOT/'mountain_valley_compact'/name
            if p.exists():archive.write(p,p.relative_to(ROOT).as_posix())
    print('Protected snapshot:',{k:len(v) for k,v in data.items()})
else: print('Existing snapshot retained')

"""Snapshot Phase 4C before changing the mountain profile; no Git dependency."""
from pathlib import Path
import hashlib, json, zipfile

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
PHASE = ROOT / 'phase4c'

def hashes(base, skip_revision=False):
    return {p.relative_to(base).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in base.rglob('*') if p.is_file()
            and not any(s in {'.godot', '.git', '__pycache__'} for s in p.relative_to(base).parts)
            and not (skip_revision and OUT in p.parents)}

if __name__ == '__main__':
    target = OUT / 'before-hashes.json'
    if target.exists():
        raise SystemExit('Existing snapshot retained; refusing to overwrite recovery evidence.')
    payload = hashes(ROOT, True)
    with zipfile.ZipFile(OUT / 'phase4c-before-mountain-profile.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
        for p in PHASE.rglob('*'):
            if p.is_file() and OUT not in p.parents:
                archive.write(p, p.relative_to(ROOT).as_posix())
    target.write_text(json.dumps(payload, indent=2), encoding='utf-8')
    print('Saved Phase 4C recovery ZIP and', len(payload), 'project file hashes.')

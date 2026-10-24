"""Freeze current project payload before this focused revision; write only here."""
from pathlib import Path
import hashlib,json,zipfile
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent
def manifest(base):
    return {p.relative_to(base).as_posix():hashlib.sha256(p.read_bytes()).hexdigest()
            for p in base.rglob('*') if p.is_file()
            and not any(x in {'.godot','.git','__pycache__'} for x in p.relative_to(base).parts)
            and not (base==ROOT and p.relative_to(base).as_posix().startswith('reports/phase4b-stairs/'))}
path=OUT/'before-hashes.json'
if not path.exists():
    data={'test':manifest(ROOT),'original':manifest(ROOT.parent/'asset-workshop'),
          'old_map':manifest(ROOT.parents[1]/'assets/maps/prototype')}
    path.write_text(json.dumps(data,indent=2),encoding='utf-8')
    with zipfile.ZipFile(OUT/'before-map.zip','w',zipfile.ZIP_DEFLATED) as archive:
        for p in (ROOT/'mountain_valley').rglob('*'):
            if p.is_file(): archive.write(p,p.relative_to(ROOT).as_posix())
    print('Frozen', {k:len(v) for k,v in data.items()})
else:
    print('Existing snapshot retained')

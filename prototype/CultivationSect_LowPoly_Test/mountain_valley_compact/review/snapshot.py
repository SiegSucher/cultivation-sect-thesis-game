"""Freeze the large map and protected project payload before compact assembly."""
from pathlib import Path
import hashlib,json,zipfile
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent
def manifest(base):
    return {p.relative_to(base).as_posix():hashlib.sha256(p.read_bytes()).hexdigest()
            for p in base.rglob('*') if p.is_file()
            and not any(x in {'.godot','.git','__pycache__'} for x in p.relative_to(base).parts)
            and not (base==ROOT and p.relative_to(base).parts[0]=='mountain_valley_compact')}
frozen=OUT/'before-hashes.json'
if not frozen.exists():
    workspace=ROOT.parents[1]
    launchers={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in workspace.glob('*Valley*.cmd')}
    data={'test':manifest(ROOT),'original':manifest(ROOT.parent/'asset-workshop'),
          'old_map':manifest(workspace/'assets/maps/prototype'),'workspace_launchers':launchers}
    frozen.write_text(json.dumps(data,indent=2),encoding='utf-8')
    with zipfile.ZipFile(OUT/'large-map-recovery.zip','w',zipfile.ZIP_DEFLATED) as archive:
        for p in (ROOT/'mountain_valley').rglob('*'):
            if p.is_file(): archive.write(p,p.relative_to(ROOT).as_posix())
        for name in launchers: archive.write(workspace/name,'workspace-launchers/'+name)
    print('Frozen protected files:',{k:len(v) for k,v in data.items()})
else: print('Existing snapshot retained')

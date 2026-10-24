"""Freeze original resources and the approved hall before the first gate stage."""
from pathlib import Path
import json,hashlib,shutil,zipfile
R=Path(__file__).resolve().parents[1]
E=R/'reports/environment-conversion-stage-1'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
before=E/'before'
before.mkdir(exist_ok=False)
for name in ['HANDOFF.md','reports/low_poly_test_report.md','reports/performance_comparison.md']:
    shutil.copy2(R/name,before/Path(name).name)
manifest={p.relative_to(R).as_posix():sha(p) for folder in ['assets','scripts','scenes','source'] for p in (R/folder).rglob('*') if p.is_file() and p.suffix not in ['.import','.uid']}
manifest['project.godot']=sha(R/'project.godot')
(E/'pre-stage-manifest.json').write_text(json.dumps(manifest,indent=2))
gate=R/'assets/architecture/sect_gate'
baseline=R/'baseline/stage1_gate'
baseline.mkdir(exist_ok=False)
for p in gate.iterdir():
    if p.suffix in ['.glb','.json']:shutil.copy2(p,baseline/p.name)
script=(R/'scripts/sect_gate.gd').read_text(encoding='utf-8')
(R/'baseline/stage1_gate.gd').write_text(script.replace('res://assets/architecture/sect_gate/','res://baseline/stage1_gate/'),encoding='utf-8')
with zipfile.ZipFile(R/'checkpoints/before-environment-stage1-sect-gate.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in baseline.iterdir():z.write(p,p.relative_to(R))
    z.write(R/'scripts/sect_gate.gd','scripts/sect_gate.gd')
print('First-stage baseline and checkpoint saved; all previous resource hashes recorded.')

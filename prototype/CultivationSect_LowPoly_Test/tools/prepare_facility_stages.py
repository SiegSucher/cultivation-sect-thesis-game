"""Freeze the approved state and make self-contained, in-test rollback fixtures."""
from pathlib import Path
import hashlib, json, shutil, zipfile
R = Path(__file__).resolve().parents[1]
E = R/'reports/environment-conversion-stages-2-3'
E.mkdir(exist_ok=True)
def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
manifest = {}
for folder in ['assets', 'scripts', 'scenes', 'source']:
    for p in (R/folder).rglob('*'):
        if p.is_file() and p.suffix not in ['.import', '.uid', '.blend1']:
            manifest[p.relative_to(R).as_posix()] = digest(p)
manifest['project.godot'] = digest(R/'project.godot')
assert not (E/'pre-stage-manifest.json').exists(), 'Do not overwrite stage evidence'
(E/'pre-stage-manifest.json').write_text(json.dumps(manifest, indent=2))
families = {'training':'martial_training_ground', 'pavilion':'scripture_pavilion'}
for short, family in families.items():
    dest = R/'baseline'/('stage23_'+short)
    dest.mkdir()
    for p in (R/'assets/architecture'/family).iterdir():
        if p.suffix in ['.glb', '.json']: shutil.copy2(p, dest/p.name)
    runtime = (R/'scripts'/(family+'.gd')).read_text(encoding='utf-8')
    runtime = runtime.replace('res://assets/architecture/'+family+'/', 'res://baseline/stage23_'+short+'/')
    if short == 'pavilion':
        runtime = runtime.replace('res://scripts/archive_access_gate.gd', 'res://baseline/stage23_archive_access_gate.gd')
        gate = (R/'scripts/archive_access_gate.gd').read_text(encoding='utf-8').replace('res://assets/architecture/scripture_pavilion/', 'res://baseline/stage23_pavilion/')
        (R/'baseline/stage23_archive_access_gate.gd').write_text(gate, encoding='utf-8')
    (R/'baseline'/('stage23_'+short+'.gd')).write_text(runtime, encoding='utf-8')
    (R/'baseline'/('stage23_'+short+'.tscn')).write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://baseline/stage23_'+short+'.gd" id="1"]\n[node name="BaselineFacility" type="Node3D"]\nscript = ExtResource("1")\n')
    fixture_name = 'training_walkthrough' if short == 'training' else 'scripture_walkthrough'
    fixture = (R/'scripts'/(fixture_name+'.gd')).read_text(encoding='utf-8').replace('res://scenes/buildings/'+family+'.tscn', 'res://baseline/stage23_'+short+'.tscn')
    (R/'baseline'/('stage23_'+fixture_name+'.gd')).write_text(fixture, encoding='utf-8')
with zipfile.ZipFile(R/'checkpoints/before-environment-stages-2-3.zip','x',zipfile.ZIP_DEFLATED) as z:
    for short in families:
        for p in (R/'baseline'/('stage23_'+short)).iterdir(): z.write(p,p.relative_to(R).as_posix())
    for name in ['HANDOFF.md','reports/LOW_POLY_CONVERSION_INVENTORY.md','assets/gallery/catalog.json']:
        z.write(R/name,name)
print('Frozen',len(manifest),'files; both facility baselines and checkpoint saved inside test.')

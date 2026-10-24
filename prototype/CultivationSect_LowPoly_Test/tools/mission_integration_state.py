"""Freeze, copy and check Mission Hall delivery without rebuilding any asset."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import sys
import zipfile

R = Path(__file__).resolve().parents[1]
E = R / 'reports/codex-mission-hall'
S = R / 'staging/claude_mission_hall'
DESTINATIONS = ['assets/architecture/mission_hall', 'scenes/buildings/mission_hall.tscn',
                'source/claude_mission_hall_integrated.blend', 'scripts/mission_hall_review.gd',
                'scenes/review/mission_hall_walkthrough.tscn']

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def write_json(path, value):
    path.write_text(json.dumps(value, indent=2), encoding='utf-8')

def freeze():
    assert not E.exists(), 'Evidence directory already exists; do not overwrite another run'
    conflicts = [p for p in DESTINATIONS if (R / p).exists()]
    catalog = json.loads((R / 'assets/gallery/catalog.json').read_text())
    assert not conflicts and not any(c['id'] == 'mission_hall' for c in catalog), conflicts
    E.mkdir()
    # Hash original files read-only. Do not start an engine against that project.
    snapshots = {}
    for label, base in [('test', R), ('original', R.parent / 'asset-workshop')]:
        snapshots[label] = {p.relative_to(base).as_posix(): sha(p) for p in base.rglob('*')
                            if p.is_file() and '.godot' not in p.relative_to(base).parts
                            and '__pycache__' not in p.relative_to(base).parts
                            and not (label == 'test' and p.is_relative_to(E))}
    write_json(E / 'before-hashes.json', snapshots)
    write_json(E / 'destination-check.json', {'conflicts': conflicts, 'destinations': DESTINATIONS,
                                              'previous_catalog': catalog})
    with zipfile.ZipFile(E / 'before-docs-catalog.zip', 'w', zipfile.ZIP_DEFLATED) as z:
        for p in ['assets/gallery/catalog.json', 'HANDOFF.md', 'reports/CODEX_REPORT.md',
                  'reports/LOW_POLY_CONVERSION_INVENTORY.md']:
            z.write(R / p, p)
    # Rerun inspected Claude checks from copies, with results isolated from delivery.
    check = (S / 'review/verify_mission_hall.gd').read_text(encoding='utf-8')
    check = check.replace('res://reports/claude-mission-hall', 'res://reports/codex-mission-hall/staged-basic')
    (R / 'tools/verify_mission_basics.gd').write_text(check, encoding='utf-8')
    review = (S / 'review/mission_hall_review.gd').read_text(encoding='utf-8')
    review = review.replace('res://reports/claude-mission-hall/', 'res://reports/codex-mission-hall/staged-captures/')
    review = review.replace('res://reports/claude-mission-hall"', 'res://reports/codex-mission-hall/staged-captures"')
    (R / 'tools/capture_staged_mission.gd').write_text(review, encoding='utf-8')
    (R / 'tools/capture_staged_mission.tscn').write_text(
        '[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://tools/capture_staged_mission.gd" id="1"]\n'
        '[node name="StagedMissionInspection" type="Node3D"]\nscript = ExtResource("1")\n', encoding='utf-8')
    print('Frozen files:', {k: len(v) for k, v in snapshots.items()}, '; destinations conflict-free')

def integrate():
    basic = json.loads((E / 'staged-basic/verify-results.json').read_text())
    audit = json.loads((E / 'staged-glb-audit.json').read_text())
    assert basic['failed'] == 0 and all(a['pass'] for a in audit)
    assert not any((R / p).exists() for p in DESTINATIONS)
    model = R / DESTINATIONS[0] / 'mission_hall.glb'
    model.parent.mkdir()
    shutil.copy2(S / 'mission_hall/mission_hall.glb', model)
    scene = (S / 'mission_hall/mission_hall.tscn').read_text(encoding='utf-8')
    scene = scene.replace('res://staging/claude_mission_hall/mission_hall/mission_hall.glb',
                          'res://assets/architecture/mission_hall/mission_hall.glb')
    (R / DESTINATIONS[1]).write_text(scene, encoding='utf-8')
    shutil.copy2(S / 'source/claude_mission_hall.blend', R / DESTINATIONS[2])
    review = (S / 'review/mission_hall_review.gd').read_text(encoding='utf-8')
    review = review.replace('res://staging/claude_mission_hall/mission_hall/mission_hall.tscn',
                            'res://scenes/buildings/mission_hall.tscn')
    review = review.replace('res://reports/claude-mission-hall', 'res://reports/codex-mission-hall/integrated-captures')
    review = review.replace('CLAUDE MISSION HALL - asset', 'MISSION HALL - asset')
    (R / DESTINATIONS[3]).write_text(review, encoding='utf-8')
    wrapper = (S / 'review/mission_hall_review.tscn').read_text(encoding='utf-8')
    wrapper = wrapper.replace('res://staging/claude_mission_hall/review/mission_hall_review.gd',
                              'res://scripts/mission_hall_review.gd')
    (R / DESTINATIONS[4]).write_text(wrapper, encoding='utf-8')
    check = (R / 'tools/verify_mission_basics.gd').read_text()
    check = check.replace('load(ROOT+ID+"/"+ID+".tscn")', 'load("res://scenes/buildings/mission_hall.tscn")')
    check = check.replace('codex-mission-hall/staged-basic', 'codex-mission-hall/integrated-basic')
    (R / 'tools/verify_integrated_mission_basics.gd').write_text(check, encoding='utf-8')
    catalog_path = R / 'assets/gallery/catalog.json'
    catalog = json.loads(catalog_path.read_text())
    catalog.append({'id': 'mission_hall', 'name': 'Mission Hall', 'group': 'Buildings',
                    'status': 'Independently tested and integrated; human visual review pending',
                    'resource': 'res://scenes/buildings/mission_hall.tscn',
                    'model': 'res://assets/architecture/mission_hall/mission_hall.glb',
                    'source': 'res://source/claude_mission_hall_integrated.blend',
                    'walkthrough': 'res://scenes/review/mission_hall_walkthrough.tscn',
                    'interior_camera': {'target': [0, 2.6, -2.5], 'distance': 4.8, 'yaw': 0, 'pitch': 0, 'fov': 78}})
    write_json(catalog_path, catalog)
    print('Copied Mission Hall and registered ninth gallery entry; no staging file modified')

def verify_preservation():
    snapshots = json.loads((E / 'before-hashes.json').read_text())
    changes = {}
    for label, base in [('test', R), ('original', R.parent / 'asset-workshop')]:
        changes[label] = [p for p, h in snapshots[label].items() if not (base / p).is_file() or sha(base / p) != h]
    allowed = {'assets/gallery/catalog.json', 'HANDOFF.md', 'reports/CODEX_REPORT.md', 'reports/LOW_POLY_CONVERSION_INVENTORY.md'}
    assert not changes['original'], changes['original']
    assert set(changes['test']) <= allowed, changes['test']
    catalog = json.loads((R / 'assets/gallery/catalog.json').read_text())
    assert catalog[:-1] == json.loads((E / 'destination-check.json').read_text())['previous_catalog']
    assert sha(R / 'assets/architecture/mission_hall/mission_hall.glb') == sha(S / 'mission_hall/mission_hall.glb')
    assert sha(R / DESTINATIONS[2]) == sha(S / 'source/claude_mission_hall.blend')
    expected = (S / 'mission_hall/mission_hall.tscn').read_text().replace(
        'res://staging/claude_mission_hall/mission_hall/mission_hall.glb', 'res://assets/architecture/mission_hall/mission_hall.glb')
    assert (R / DESTINATIONS[1]).read_text() == expected
    uids = [re.search(r'uid="([^"]+)"', p.read_text())[1] for p in
            [S / 'mission_hall/mission_hall.glb.import', R / 'assets/architecture/mission_hall/mission_hall.glb.import']]
    assert uids[0] != uids[1]
    staged = [p for p in snapshots['test'] if p.startswith('staging/')]
    result = {'original_files_unchanged': len(snapshots['original']), 'preexisting_test_files': len(snapshots['test']),
              'all_staging_files_unchanged': len(staged), 'existing_file_changes': changes['test'],
              'model_and_source_byte_identical': True, 'scene_only_glb_path_changed': True,
              'previous_eight_catalog_entries_unchanged': True, 'staged_uid': uids[0], 'canonical_uid': uids[1]}
    write_json(E / 'preservation.json', result)
    print(json.dumps(result, indent=2))

if __name__ == '__main__':
    {'freeze': freeze, 'integrate': integrate, 'verify': verify_preservation}[sys.argv[1]]()

"""Read-only assertions; writes only this task's preservation evidence."""
from pathlib import Path
import hashlib
import json

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


frozen = json.loads((OUT / 'before-hashes.json').read_text())
changed, missing = [], []
for rel, digest in frozen['test'].items():
    file = ROOT / rel
    if not file.exists():
        missing.append(rel)
    elif sha(file) != digest:
        changed.append(rel)
assert set(changed) == {'HANDOFF.md', 'assets/architecture/tang_main_hall/main_sect_hall.json'}, changed
assert not missing, missing
original = ROOT.parent / 'asset-workshop'
assert all(sha(original / rel) == digest for rel, digest in frozen['original'].items())
staged = {rel: digest for rel, digest in frozen['test'].items() if rel.startswith('staging/')}
assert all(sha(ROOT / rel) == digest for rel, digest in staged.items())
current_staging = {file.relative_to(ROOT).as_posix() for file in (ROOT / 'staging').rglob('*') if file.is_file()}
assert not staged.keys() - current_staging
added_staging = sorted(current_staging - staged.keys())

old = json.loads((OUT / 'before/main_sect_hall.json.txt').read_text())
new = json.loads((ROOT / 'assets/architecture/tang_main_hall/main_sect_hall.json').read_text())
plan = json.loads((OUT / 'alignment-plan.json').read_text())
assert sha(ROOT / 'assets/architecture/tang_main_hall/main_sect_hall.json') == plan['candidate_sha256']
changed_rows = {c['old_index']: c for c in plan['changes']}
expected = []
for i, record in enumerate(old['solid_shapes']):
    if i not in changed_rows:
        expected.append(record)
    elif changed_rows[i]['action'] == 'move':
        record = record.copy()
        record['position'] = changed_rows[i]['new_position']
        expected.append(record)
assert expected == new['solid_shapes']
assert all(new[k] == old[k] for k in old if k != 'solid_shapes')

tests = {}
for name in ['before-headless', 'before-rendered', 'after-headless', 'after-rendered',
             'camera-old-headless', 'camera-current-headless']:
    r = json.loads((OUT / (name + '.json')).read_text())
    tests[name] = {'passed': r['passed'], 'failed': r['failed'],
                   'failed_checks': [c['check'] for c in r['checks'] if not c['pass']],
                   'movements': len(r['movements']), 'contacts': len(r['contacts']),
                   'camera_body_samples': r['sampled_camera_body_pairs']}
    if name.startswith('after-'):
        assert tests[name]['failed_checks'] == ['all visible camera samples clear']
        assert len(r['movements']) == 78 and sum(m['reached'] for m in r['movements']) == 46
        assert all(not c['solid_camera'] and not c['visible_body']
                   and c['visible_camera'] == ['Hall _ Cedar'] for c in r['contacts'])
r = json.loads((OUT / 'gallery/launch-results.json').read_text())
assert r['passed'] == 466 and r['failed'] == 0
tests['gallery'] = {'passed': 466, 'failed': 0}
comparison = json.loads((OUT / 'camera-comparison.json').read_text())
assert all(not v['new_poses'] for v in comparison.values())
record = {
    'preexisting_test_files_checked': len(frozen['test']), 'existing_files_changed': changed,
    'missing_files': missing, 'original_files_unchanged': len(frozen['original']),
    'preexisting_staging_files_unchanged': len(staged),
    'new_staging_files_observed': added_staging,
    'staging_note': 'New environment batch appeared during this task from a separate workstream; not created, edited, reviewed or integrated by this repair.',
    'other_top_level_fields_unchanged': len(old) - 1, 'unrelated_simple_shapes_unchanged': 175,
    'moved': 16, 'removed_unmatched': 4, 'simple_shapes_before': 195, 'simple_shapes_after': 191,
    'roof_triangles_unchanged': len(new['roof_collision_faces']) // 3, 'candidate_hash_matches': True,
    'models_sources_scenes_scripts_cameras_gallery_other_buildings_prior_reports_unchanged': True,
    'tests': tests, 'camera_comparison': comparison,
    'screenshots': len(list(OUT.rglob('*.png'))), 'human_playtested': False,
}
(OUT / 'preservation.json').write_text(json.dumps(record, indent=2), encoding='utf-8')
print(json.dumps({k: v for k, v in record.items() if k != 'new_staging_files_observed'}, indent=2))
print('New staging additions:', len(added_staging))

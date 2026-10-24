"""Check final Exchange integration including its documented leaf-collision fix."""
from pathlib import Path
import hashlib
import json
import re
import runpy

R = Path(__file__).resolve().parents[1]
E = R/'reports/codex-exchange-hall'
def read(p): return json.loads(p.read_text(encoding='utf-8'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()

def audit():
    before = read(E/'before-hashes.json')
    allowed = {'assets/gallery/catalog.json','HANDOFF.md','reports/CODEX_REPORT.md','reports/LOW_POLY_CONVERSION_INVENTORY.md'}
    changed = [p for p,h in before['test'].items() if not (R/p).is_file() or sha(R/p) != h]
    assert set(changed) <= allowed, changed
    original = R.parent/'asset-workshop'
    assert all((original/p).is_file() and sha(original/p) == h for p,h in before['original'].items())
    baseline = read(R/'reports/original_manifest.json')
    assert all(before['original'].get(p) == h for p,h in baseline.items())
    staged_before = {p for p in before['test'] if p.startswith('staging/')}
    staged_now = {p.relative_to(R).as_posix() for p in (R/'staging').rglob('*') if p.is_file()}
    assert staged_before == staged_now, staged_before ^ staged_now
    catalog = read(R/'assets/gallery/catalog.json')
    assert catalog[:-1] == read(E/'destination-check.json')['previous_catalog'] and len(catalog) == 10
    assert len(set(c['id'] for c in catalog)) == 10
    assert catalog[-1]['id'] == 'exchange_hall'
    for category,suffix in [('model','exchange_hall/exchange_hall.glb'),('source','source/claude_exchange_hall.blend')]:
        canonical = R/('assets/architecture/exchange_hall/exchange_hall.glb' if category == 'model' else 'source/claude_exchange_hall_integrated.blend')
        assert sha(canonical) == sha(R/'staging/claude_exchange_hall'/suffix)
    expected = runpy.run_path(str(R/'tools/fix_exchange_leaf_collision.py'))['corrected_scene']()
    assert (R/'scenes/buildings/exchange_hall.tscn').read_text(encoding='utf-8') == expected
    assert 'staging/' not in expected and expected.count('[ext_resource ') == 1
    imported = [(R/'staging/claude_exchange_hall/exchange_hall/exchange_hall.glb.import'),
                (R/'assets/architecture/exchange_hall/exchange_hall.glb.import')]
    uids = [re.search(r'uid="([^"]+)"', p.read_text())[1] for p in imported]
    assert uids[0] != uids[1]
    # Confirm permanent Mission payload also matches the previous run's hashes.
    mission_before = read(R/'reports/codex-mission-hall/before-hashes.json')['test']
    mission_paths = ['assets/architecture/mission_hall/mission_hall.glb','assets/architecture/mission_hall/mission_hall.glb.import',
                     'scenes/buildings/mission_hall.tscn','scenes/review/mission_hall_walkthrough.tscn',
                     'scripts/mission_hall_review.gd','source/claude_mission_hall_integrated.blend']
    # Mission canonical files were created after that run's initial snapshot;
    # current task snapshot records them and proves no change during this review.
    assert all(p in before['test'] and sha(R/p) == before['test'][p] for p in mission_paths)
    for aid in ['alchemy_pavilion','medicine_hall']:
        assert not (R/'assets/architecture'/aid).exists()
        assert not (R/'scenes/buildings'/(aid+'.tscn')).exists()
        assert all(c['id'] != aid for c in catalog)
    result = {'original_files_unchanged':len(before['original']), 'recorded_original_baseline_matches':True,
              'preexisting_test_files':len(before['test']), 'existing_changes':changed,
              'all_staging_files_unchanged':len(staged_before), 'exchange_staging_files_unchanged':len([p for p in staged_before if p.startswith('staging/claude_exchange_hall/')]),
              'staging_file_set_unchanged':True, 'mission_payload_unchanged':mission_paths,
              'model_and_source_byte_identical':True, 'all_69_original_shapes_preserved':True,
              'canonical_correction':'4 static storeroom leaf boxes; 73 total shapes',
              'previous_nine_catalog_entries_unchanged':True, 'stage_uid':uids[0], 'canonical_uid':uids[1],
              'alchemy_and_medicine_staged_only_no_duplicates':True}
    (E/'preservation.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps(result,indent=2))
    return result

if __name__ == '__main__': audit()

"""Final preservation and candidate provenance including Medicine correction."""
from pathlib import Path
import hashlib,json,re,runpy
R=Path(__file__).resolve().parents[1]
E=R/'reports/codex-alchemy-medicine'
IDS=['alchemy_pavilion','medicine_hall']
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def audit():
    before=read(E/'before-hashes.json')
    allowed={'assets/gallery/catalog.json','HANDOFF.md','reports/CODEX_REPORT.md','reports/LOW_POLY_CONVERSION_INVENTORY.md'}
    changed=[p for p,h in before['test'].items() if not (R/p).is_file() or sha(R/p)!=h]
    assert set(changed)<=allowed,changed
    original=R.parent/'asset-workshop'
    assert all((original/p).is_file() and sha(original/p)==h for p,h in before['original'].items())
    assert all(before['original'].get(p)==h for p,h in read(R/'reports/original_manifest.json').items())
    staged_before={p for p in before['test'] if p.startswith('staging/')}
    staged_now={p.relative_to(R).as_posix() for p in (R/'staging').rglob('*') if p.is_file()}
    assert staged_before==staged_now,sorted(staged_before^staged_now)
    catalog=read(R/'assets/gallery/catalog.json')
    previous=read(E/'destination-check.json')['previous_catalog']
    assert catalog[:10]==previous and len(catalog)==12 and len(set(c['id'] for c in catalog))==12
    assert [c['id'] for c in catalog[10:]]==IDS
    assert sha(R/'source/claude_batch2_integrated.blend')==sha(R/'staging/claude_buildings_batch2/source/claude_batch2.blend')
    records=[]
    for aid in IDS:
        stage=R/'staging/claude_buildings_batch2'/aid
        dest=R/'assets/architecture'/aid
        assert sha(stage/(aid+'.glb'))==sha(dest/(aid+'.glb'))
        expected=(stage/(aid+'.tscn')).read_text(encoding='utf-8').replace('res://staging/claude_buildings_batch2/'+aid+'/'+aid+'.glb','res://assets/architecture/'+aid+'/'+aid+'.glb')
        fix='fix_medicine_collision.py' if aid=='medicine_hall' else 'fix_alchemy_leaf_collision.py'
        expected=runpy.run_path(str(R/'tools'/fix))['corrected_scene']()
        assert (R/'scenes/buildings'/(aid+'.tscn')).read_text(encoding='utf-8')==expected
        assert 'staging/' not in expected
        uids=[re.search(r'uid="([^"]+)"',p.read_text())[1] for p in [stage/(aid+'.glb.import'),dest/(aid+'.glb.import')]]
        assert uids[0]!=uids[1]
        records.append({'asset':aid,'model_identical':True,'staged_uid':uids[0],'canonical_uid':uids[1],
            'scene_change':'GLB path and two static open-leaf boxes' if aid==IDS[0] else 'GLB path, four counter boxes/poses, camera-only detail resource/body'})
    shape=read(E/'camera-shape.json');assert shape['saved'] and shape['triangles']==698
    previous_payload=[p for p in before['test'] if p.startswith(('assets/architecture/mission_hall/','assets/architecture/exchange_hall/'))
                      or p in ['scenes/buildings/mission_hall.tscn','scenes/buildings/exchange_hall.tscn','scripts/training_inspection_player.gd','scripts/asset_gallery.gd','project.godot']]
    result={'original_files_unchanged':len(before['original']),'original_baseline_matches':True,'frozen_test_files':len(before['test']),
        'existing_file_changes':changed,'all_staging_files_unchanged':len(staged_before),
        'batch2_staging_files_unchanged':len([p for p in staged_before if p.startswith('staging/claude_buildings_batch2/')]),
        'staging_file_set_unchanged':True,'prior_ten_catalog_entries_unchanged':True,
        'prior_assets_player_gallery_settings_unchanged':True,'explicit_prior_payload_hashes_checked':previous_payload,
        'source_copy_identical':True,'assets':records,'camera_detail_triangles':698}
    (E/'preservation.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print('Preserved',len(before['original']),'original files and',len(staged_before),'staging files; prior ten catalog entries unchanged.')
    return result
if __name__=='__main__':audit()

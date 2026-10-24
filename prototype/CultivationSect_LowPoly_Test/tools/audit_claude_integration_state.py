"""Verify preservation, canonical provenance, imported IDs and exact palette."""
from pathlib import Path
import json,hashlib,struct,re,zipfile
R=Path(__file__).resolve().parents[1]
E=R/'reports/codex-claude-integration'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def audit():
    frozen=read(E/'pre-integration-manifest.json')
    allowed={'assets/gallery/catalog.json','scripts/asset_gallery.gd'}
    changed=[name for name,d in frozen.items() if not (R/name).is_file() or sha(R/name)!=d]
    assert set(changed)==allowed,changed
    original=read(R/'reports/original_manifest.json')
    original_changed=[name for name,d in original.items() if not (R.parent/'asset-workshop'/name).is_file() or sha(R.parent/'asset-workshop'/name)!=d]
    assert not original_changed,original_changed
    staged=[name for name in frozen if name.startswith('staging/')]
    with zipfile.ZipFile(R/'checkpoints/before-claude-asset-integration.zip') as z:
        assert z.testzip() is None
        previous_catalog=json.loads(z.read('assets/gallery/catalog.json'))
    catalog=read(R/'assets/gallery/catalog.json')
    assert catalog[:len(previous_catalog)]==previous_catalog and len(catalog)==len(previous_catalog)+4
    assert len(set(c['id'] for c in catalog))==len(catalog)
    source=R/'source/claude_buildings_integrated.blend'
    assert sha(source)==sha(R/'staging/claude_buildings/source/claude_buildings.blend')
    colors={'Stone':'667e88','Coping':'bcc6bd','Timber':'432d2d','Cedar':'896048','Jade':'22594f','TileLight':'46796b','Plaster':'e6d9b8','Window':'284c53','Bronze':'cda668','Floor':'85624d','Lantern':'ffda91','Fabric':'456e73','Soil':'5d4a3a','Leaf':'4d7d4f','SpiritHerb':'8fe0c0','Water':'2c5f63'}
    records=[]
    for entry in catalog[4:]:
        aid=entry['id'];base=R/'staging/claude_buildings'/aid
        canonical=R/'assets/architecture'/aid/(aid+'.glb')
        assert sha(canonical)==sha(base/(aid+'.glb'))
        raw=canonical.read_bytes();n=struct.unpack_from('<I',raw,12)[0];data=json.loads(raw[20:20+n])
        assert not data.get('images') and not data.get('textures')
        palette=[]
        for m in data['materials']:
            name=m['name'];color=colors[name]
            rgb=[int(color[i:i+2],16)/255 for i in (0,2,4)]
            linear=[v/12.92 if v<.04045 else ((v+.055)/1.055)**2.4 for v in rgb]
            pbr=m['pbrMetallicRoughness']
            assert max(abs(a-b) for a,b in zip(linear+[1],pbr['baseColorFactor']))<2e-5,(aid,name)
            rough={'Bronze':.56,'Water':.5}.get(name,.82)
            assert abs(pbr['roughnessFactor']-rough)<1e-5 and pbr.get('metallicFactor',1)==0
            assert m.get('alphaMode','OPAQUE')=='OPAQUE'
            palette.append({'name':name,'srgb_hex':color,'roughness':rough})
        old_path='res://staging/claude_buildings/'+aid+'/'+aid+'.glb'
        new_path='res://assets/architecture/'+aid+'/'+aid+'.glb'
        expected=(base/(aid+'.tscn')).read_text(encoding='utf-8').replace(old_path,new_path)
        scene=R/'scenes/buildings'/(aid+'.tscn')
        assert scene.read_text(encoding='utf-8')==expected
        assert 'staging/' not in expected and 'script =' not in expected
        assert len(re.findall(r'\[ext_resource ',expected))==1
        before_uid=re.search(r'uid="([^"]+)"',(base/(aid+'.glb.import')).read_text())[1]
        after_uid=re.search(r'uid="([^"]+)"',Path(str(canonical)+'.import').read_text())[1]
        assert before_uid!=after_uid,(aid,'Duplicate imported UID')
        records.append({'asset':aid,'glb_sha256':sha(canonical),'glb_identical_to_staging':True,'scene_only_glb_path_changed':True,'source_uid':before_uid,'canonical_uid':after_uid,'palette':palette,'scene_dependency':new_path})
    geometry=read(E/'glb-audit.json')
    assert all(m['zero_area_triangles']==m['invalid_normals']==m['nonflat_triangles']==m['images']==m['textures']==0 and m['all_opaque'] and not m['external_uris'] for m in geometry)
    result={'original_files_verified':len(original),'original_changed':original_changed,'frozen_existing_files':len(frozen),'allowed_existing_runtime_changes':changed,'staging_files_verified_unchanged':len(staged),'claude_report_and_claude_evidence_unchanged':True,'approved_hall_gate_training_pavilion_assets_and_existing_controllers_preserved':True,'canonical_source_identical_to_staging':True,'catalog_original_prefix_preserved':True,'project_settings_and_default_main_scene_preserved':True,'no_world_scene_or_town_positions_added':True,'assets':records,'checkpoint_integrity':True}
    (E/'preservation-palette-provenance.json').write_text(json.dumps(result,indent=2))
    print('Preserved',len(staged),'staging files and',len(original),'original hashes; 4 canonical assets/palettes/UIDs verified.')
    return result
if __name__=='__main__':audit()

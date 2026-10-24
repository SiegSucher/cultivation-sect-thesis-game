from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent
before=json.loads((OUT/'before-hashes.json').read_text())
allowed={'mountain_valley/terrain_builder.gd','mountain_valley/mountain_valley.tscn',
         'mountain_valley/resources/terrain_mesh.res','mountain_valley/resources/terrain_collision.res'}
result={}
for key,base in [('test',ROOT),('original',ROOT.parent/'asset-workshop'),('old_map',ROOT.parents[1]/'assets/maps/prototype')]:
    changed=[]
    for name,digest in before[key].items():
        p=base/name
        if not p.is_file() or hashlib.sha256(p.read_bytes()).hexdigest()!=digest: changed.append(name)
    result[key]={'checked':len(before[key]),'changed_or_missing':changed}
    assert set(changed)<=allowed if key=='test' else not changed, (key,changed)
    print(key,len(before[key]),'checked;',changed)
result['only_existing_file_changes_are_authorized_terrain_files']=True
result['all_nonterrain_scene_bytes_identical']=json.loads((OUT/'apply-result.json').read_text())['all_other_scene_bytes_identical']
(OUT/'preservation.json').write_text(json.dumps(result,indent=2),encoding='utf-8')

"""Copy Claude's four delivered assets; never rebuild or write staging.

Only the GLB resource path changes in each copied scene. Import metadata is
deliberately not copied, so Godot assigns new UIDs to the canonical copies.
"""
from pathlib import Path
import json,hashlib,shutil,zipfile
R=Path(__file__).resolve().parents[1]
S=R/'staging/claude_buildings'
E=R/'reports/codex-claude-integration'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
assert not E.exists(), 'Do not overwrite integration evidence; inspect existing run first.'
E.mkdir()
summary=json.loads((S/'build_summary.json').read_text())
protected={}
for folder in ['assets','scenes','scripts','source','staging','baseline','checkpoints','reference_images']:
    for p in (R/folder).rglob('*'):
        if p.is_file() and (folder=='staging' or p.suffix not in ['.uid','.import','.blend1']):
            protected[p.relative_to(R).as_posix()]=sha(p)
for name in ['project.godot','original_runtime_recovery.zip','reports/CLAUDE_ASSET_REPORT.md']:
    protected[name]=sha(R/name)
for p in (R/'reports/claude-assets').rglob('*'):
    if p.is_file():protected[p.relative_to(R).as_posix()]=sha(p)
(E/'pre-integration-manifest.json').write_text(json.dumps(protected,indent=2))
with zipfile.ZipFile(R/'checkpoints/before-claude-asset-integration.zip','x',zipfile.ZIP_DEFLATED) as z:
    for name in ['HANDOFF.md','assets/gallery/catalog.json','scripts/asset_gallery.gd','reports/LOW_POLY_CONVERSION_INVENTORY.md']:
        z.write(R/name,name)
catalog=json.loads((R/'assets/gallery/catalog.json').read_text())
interiors={'disciple_residence':[2.2,2.15,-1.0],'elder_residence':[0,2.65,-5.2],'dining_hall_kitchen':[0,2.25,1.5],'spirit_herb_garden':[0,2.15,-8.5]}
records=[]
for asset,info in summary.items():
    assert asset not in [c['id'] for c in catalog]
    folder=R/'assets/architecture'/asset
    scene=R/'scenes/buildings'/(asset+'.tscn')
    assert not folder.exists() and not scene.exists()
    folder.mkdir()
    shutil.copy2(S/asset/(asset+'.glb'),folder/(asset+'.glb'))
    old='res://staging/claude_buildings/'+asset+'/'+asset+'.glb'
    new='res://assets/architecture/'+asset+'/'+asset+'.glb'
    staged=(S/asset/(asset+'.tscn')).read_text(encoding='utf-8')
    assert staged.count(old)==1 and '[gd_scene' in staged
    scene.write_text(staged.replace(old,new),encoding='utf-8')
    catalog.append({'id':asset,'name':info['name'],'group':'Buildings','status':'Claude asset integrated — Codex verification pending','resource':'res://scenes/buildings/'+asset+'.tscn','model':new,'source':'res://source/claude_buildings_integrated.blend','walkthrough':'res://scenes/review/'+asset+'_walkthrough.tscn','interior_camera':{'target':interiors[asset],'distance':2.3,'yaw':0,'pitch':0,'fov':78}})
    records.append({'asset':asset,'model':new,'scene':'res://scenes/buildings/'+asset+'.tscn','model_sha256':sha(folder/(asset+'.glb')),'byte_identical_glb':sha(folder/(asset+'.glb'))==sha(S/asset/(asset+'.glb')),'scene_edit':'Only ext_resource GLB path remapped; all authored transforms/colliders/plaques retained.'})
shutil.copy2(S/'source/claude_buildings.blend',R/'source/claude_buildings_integrated.blend')
(R/'assets/gallery/catalog.json').write_text(json.dumps(catalog,indent=2)+'\n',encoding='utf-8')
(E/'integration-copies.json').write_text(json.dumps({'assets':records,'source_copy_sha256':sha(R/'source/claude_buildings_integrated.blend'),'staging_written':False,'import_metadata_copied':False,'no_world_scene_or_positions_assigned':True},indent=2))
print('Four GLBs/scenes and native source copied; staging preserved; catalog appended.')

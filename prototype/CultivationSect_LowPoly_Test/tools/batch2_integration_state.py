"""Preserve existing delivery, copy candidate assets, register tested copies."""
from pathlib import Path
import hashlib,json,re,shutil,sys,zipfile

R=Path(__file__).resolve().parents[1]
E=R/'reports/codex-alchemy-medicine'
S=R/'staging/claude_buildings_batch2'
IDS=['alchemy_pavilion','medicine_hall']
SOURCE='source/claude_batch2_integrated.blend'
def read(p): return json.loads(p.read_text(encoding='utf-8'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,d): p.write_text(json.dumps(d,indent=2),encoding='utf-8')

def freeze():
    assert not E.exists(),'Use a new evidence directory; never overwrite another run'
    destinations=[SOURCE,'scripts/alchemy_medicine_review.gd']
    for aid in IDS: destinations += ['assets/architecture/'+aid,'scenes/buildings/'+aid+'.tscn','scenes/review/'+aid+'_walkthrough.tscn']
    assert not any((R/p).exists() for p in destinations),destinations
    catalog=read(R/'assets/gallery/catalog.json')
    assert len(catalog)==10 and not any(c['id'] in IDS for c in catalog)
    E.mkdir()
    snapshots={}
    for label,base in [('test',R),('original',R.parent/'asset-workshop')]:
        snapshots[label]={p.relative_to(base).as_posix():sha(p) for p in base.rglob('*')
            if p.is_file() and not any(t in p.relative_to(base).parts for t in ['.godot','__pycache__'])
            and not (label=='test' and p.is_relative_to(E))}
    save(E/'before-hashes.json',snapshots)
    save(E/'destination-check.json',{'conflicts':[],'destinations':destinations,'previous_catalog':catalog})
    with zipfile.ZipFile(E/'before-docs-catalog.zip','w',zipfile.ZIP_DEFLATED) as z:
        for p in ['HANDOFF.md','reports/CODEX_REPORT.md','reports/LOW_POLY_CONVERSION_INVENTORY.md','assets/gallery/catalog.json']: z.write(R/p,p)
    basic=(S/'review/verify_claude_batch2.gd').read_text(encoding='utf-8').replace('res://reports/claude-assets-batch2','res://reports/codex-alchemy-medicine/staged-basic')
    (R/'tools/verify_batch2_staged_basics.gd').write_text(basic,encoding='utf-8')
    review=(S/'review/claude_batch2_review.gd').read_text(encoding='utf-8').replace('reports/claude-assets-batch2/','reports/codex-alchemy-medicine/staged-captures/')
    review=review.replace('res://reports/claude-assets-batch2"','res://reports/codex-alchemy-medicine/staged-captures"')
    (R/'tools/capture_batch2_staged.gd').write_text(review,encoding='utf-8')
    (R/'tools/capture_batch2_staged.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://tools/capture_batch2_staged.gd" id="1"]\n[node name="StagedBatch2Review" type="Node3D"]\nscript = ExtResource("1")\n',encoding='utf-8')
    print('Snapshot:',{k:len(v) for k,v in snapshots.items()},'; permanent destinations unused')

def copy_candidates():
    assert read(E/'staged-basic/verify-results.json')['failed']==0
    assert all(a['pass'] for a in read(E/'staged-glb-audit.json'))
    assert not (R/SOURCE).exists()
    shutil.copy2(S/'source/claude_batch2.blend',R/SOURCE)
    for aid in IDS:
        folder=R/'assets/architecture'/aid;assert not folder.exists();folder.mkdir()
        shutil.copy2(S/aid/(aid+'.glb'),folder/(aid+'.glb'))
        scene=(S/aid/(aid+'.tscn')).read_text(encoding='utf-8').replace('res://staging/claude_buildings_batch2/'+aid+'/'+aid+'.glb','res://assets/architecture/'+aid+'/'+aid+'.glb')
        (R/'scenes/buildings'/(aid+'.tscn')).write_text(scene,encoding='utf-8')
    review=(S/'review/claude_batch2_review.gd').read_text(encoding='utf-8')
    review=review.replace('const ROOT := "res://staging/claude_buildings_batch2/"','@export var start_asset_index := 0')
    review=review.replace('load(ROOT+IDS[i]+"/"+IDS[i]+".tscn")','load("res://scenes/buildings/"+IDS[i]+".tscn")')
    review=review.replace('\n\tshow_asset(0)\n\tif player.automated','\n\tshow_asset(start_asset_index)\n\tif player.automated')
    review=review.replace('reports/claude-assets-batch2','reports/codex-alchemy-medicine/integrated-captures')
    review=review.replace('CLAUDE BATCH 2','ALCHEMY / MEDICINE REVIEW')
    review=review.replace('player.position = view[2]','player.position = view[2]\n\tplayer.velocity = Vector3.ZERO')
    (R/'scripts/alchemy_medicine_review.gd').write_text(review,encoding='utf-8')
    for i,aid in enumerate(IDS):
        (R/'scenes/review'/(aid+'_walkthrough.tscn')).write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://scripts/alchemy_medicine_review.gd" id="1"]\n[node name="AlchemyMedicineReview" type="Node3D"]\nscript = ExtResource("1")\nstart_asset_index = '+str(i)+'\n',encoding='utf-8')
    basic=(R/'tools/verify_batch2_staged_basics.gd').read_text(encoding='utf-8')
    basic=basic.replace('load(ROOT+id+"/"+id+".tscn")','load("res://scenes/buildings/"+id+".tscn")')
    basic=basic.replace('load(ROOT+walk[0]+"/"+walk[0]+".tscn")','load("res://scenes/buildings/"+walk[0]+".tscn")')
    (R/'tools/verify_batch2_canonical_basics.gd').write_text(basic.replace('codex-alchemy-medicine/staged-basic','codex-alchemy-medicine/canonical-basic'),encoding='utf-8')
    print('Copied two candidates and one shared native source; gallery not changed')

def register():
    for path in ['headless-results.json','rendered-results.json','native-source.json']:
        d=read(E/path);assert d['failed']==0 and d['passed']>0,(path,d)
    assert all(g['pass'] for g in read(E/'canonical-glb-audit.json'))
    path=R/'assets/gallery/catalog.json';catalog=read(path)
    assert catalog==read(E/'destination-check.json')['previous_catalog']
    summary=read(S/'build_summary.json')
    for aid in IDS:
        preset={'target':[0,2.55,-.4],'distance':4.8,'yaw':0,'pitch':0,'fov':78} if aid==IDS[0] else {'target':[0,2.1,-1.2],'distance':4.8,'yaw':0,'pitch':0,'fov':78}
        catalog.append({'id':aid,'name':summary[aid]['name'],'group':'Buildings',
            'status':'Independently tested and integrated; human visual review pending',
            'resource':'res://scenes/buildings/'+aid+'.tscn','model':'res://assets/architecture/'+aid+'/'+aid+'.glb',
            'source':'res://'+SOURCE,'walkthrough':'res://scenes/review/'+aid+'_walkthrough.tscn','interior_camera':preset})
    save(path,catalog);print('Registered gallery entries eleven and twelve')

if __name__=='__main__': {'freeze':freeze,'copy':copy_candidates,'register':register}[sys.argv[1]]()

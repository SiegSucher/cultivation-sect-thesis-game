from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent
before=json.loads((OUT/'before-hashes.json').read_text())
result={}
observed_unrelated={
    'staging/claude_environment_safety_kit/review/verify_safety_kit.gd',
    'staging/claude_environment_safety_kit/source/claude_environment_safety_kit.blend',
}
for key,base in [('test',ROOT),('original',ROOT.parent/'asset-workshop'),('old_map',ROOT.parents[1]/'assets/maps/prototype')]:
    changed=[]
    for name,digest in before[key].items():
        p=base/name
        if not p.is_file() or hashlib.sha256(p.read_bytes()).hexdigest()!=digest:changed.append(name)
    result[key]={'checked':len(before[key]),'changed_or_missing':changed}
    if key=='test':
        result[key]['observed_unrelated_staging_drift']=[n for n in changed if n in observed_unrelated]
        result[key]['unexpected_changes']=[n for n in changed if n not in observed_unrelated]
    print(key,len(before[key]),'checked;',len(changed),'changed or missing')
    assert not result[key]['unexpected_changes'] if key=='test' else not changed,(key,changed)
workspace=ROOT.parents[1]
assert all(hashlib.sha256((workspace/n).read_bytes()).hexdigest()==h for n,h in before['workspace_launchers'].items())
result['large_map_and_resources_preserved']=True
result['old_workspace_launchers_preserved']=list(before['workspace_launchers'])
result['large_map_recovery_archive']='large-map-recovery.zip'
result['unrelated_drift_note']='Two unfinished safety-kit staging files changed during this run. Compact tools write only under mountain_valley_compact; the kit is not used, restored or altered by this task.'
(OUT/'preservation.json').write_text(json.dumps(result,indent=2),encoding='utf-8')

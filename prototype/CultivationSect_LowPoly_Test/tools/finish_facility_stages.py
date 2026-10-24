"""Validate current evidence before refreshing the staged report and handoff."""
from pathlib import Path
import json,re,hashlib
from audit_facility_stages import audit
from report_facility_stages import write
R=Path(__file__).resolve().parents[1]
if (R/'reports/codex-claude-integration/final-summary.json').exists():
    raise SystemExit('Historical stages 2-3 finalizer: use tools/finalize_claude_integration.py for the current eight-asset project.')
E=R/'reports/environment-conversion-stages-2-3'
C=E/'independent-runtime'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def passed(path):
    d=read(path);assert d['failed']==0,(path,d)
    assert d['passed']>0,path
    return d['passed']
result=audit(['training','pavilion'])
assert len(result['changed_files'])==20,result['changed_files']
rows=[]
for short in ['training','pavilion']:
    title='Training' if short=='training' else 'Pavilion'
    rows.append([title+' rendered functional/camera/collision suite',str(passed(E/(short+'-verification/rendered-results.json')))+' PASS / 0 FAIL'])
    rows.append([title+' imported envelopes / protected ground contracts',str(passed(E/(short+'-envelope.json')))+' PASS / 0 FAIL'])
    rows.append([title+' reopened editable Blender source',str(passed(E/(short+'-native-audit.json')))+' PASS / 0 FAIL'])
    for suffix in ['', '-round2']:
        before=read(E/(short+'-before'+suffix+'-results.json'));after=read(E/(short+'-after'+suffix+'-results.json'))
        assert before['failed']==after['failed']==0
        assert before['camera_poses']==after['camera_poses'],(short,suffix,'Camera poses differ')
        assert all(before[k]==after[k] for k in ['adapter','godot','renderer','resolution','msaa','vsync','conditions'])
        assert [s['view'] for s in before['samples']]==[s['view'] for s in after['samples']]
        assert all(s['frames']==240 and s['mean_ms']>0 for d in [before,after] for s in d['samples'])
        assert before['project_root']==after['project_root']
    independent=read(C/'reports/environment-conversion-stages-2-3'/(short+'-verification/headless-results.json'))
    assert independent['failed']==0
    assert Path(independent['project_root']).resolve()==C.resolve(),independent['project_root']
    rows.append([title+' independent uncached project functional run',str(independent['passed'])+' PASS / 0 FAIL'])
rows += [
 ['Training equipment subgroup',str(passed(E/'training-props-verification/headless-results.json'))+' PASS / 0 FAIL; 7 bounds PASS'],
 ['Pavilion furniture/leaf subgroup',str(passed(E/'pavilion-props-verification/headless-results.json'))+' PASS / 0 FAIL; 8 bounds PASS'],
 ['Gallery, Tab, mouse look, E/G, Esc input',str(passed(E/'controls-results.json'))+' PASS / 0 FAIL'],
 ['Preserved Gate gameplay and camera regression',str(passed(E/'gate-regression/after-results.json'))+' PASS / 0 FAIL'],
 ['Preserved Gate input regression',str(passed(E/'gate-controls-results.json'))+' PASS / 0 FAIL'],
 ['Approved Hall dimensions/camera regression',str(passed(R/'reports/constraints-results.json'))+' PASS / 0 FAIL'],
 ['Approved Hall input regression',str(passed(R/'reports/controls-results.json'))+' PASS / 0 FAIL'],
 ['Independent rendered review inputs',str(passed(C/'reports/environment-conversion-stages-2-3/controls-results.json'))+' PASS / 0 FAIL'],
 ['Independent default Hall + Training/Pavilion scene startup','PASS; uncached import and actual rendered processes'],
 ['Original project preservation',str(result['original_files_verified'])+' recorded non-cache hashes match'],
 ['Hall/Gate and existing runtime scripts/scenes/settings/physical JSON','Pre-stage hashes match'],
 ['19 converted GLBs','Finite positions, unit/flat normals, opaque, no textures, no near-zero triangles at audit tolerance'],
]
assert passed(E/'training-props-envelope.json')==7 and passed(E/'pavilion-props-envelope.json')==8
assert all(r['pass'] for r in read(E/'catalog-captures.json'))
assert read(E/'independent-preparation.json')['no_cache_at_creation']
assert hashlib.sha256((R/'project.godot').read_bytes()).digest()==hashlib.sha256((C/'project.godot').read_bytes()).digest()
log_names=['training-import.log','pavilion-import.log','training-tests.log','pavilion-tests.log','training-envelope.log','pavilion-envelope.log','controls.log','catalog.log','gate-regression.log','gate-controls.log','hall-regression.log','hall-controls.log','restart.log']
log_names += [s+'-'+variant+suffix+'.log' for s in ['training','pavilion'] for variant in ['before','after'] for suffix in ['', '-round2']]
logs=[E/name for name in log_names]+[C/'reports'/name for name in ['import.log','training.log','pavilion.log','controls.log','default-hall.log','training-open.log','pavilion-open.log']]
diagnostics={str(p.relative_to(R)):[line for line in p.read_text(encoding='utf-8',errors='replace').splitlines() if re.search(r'\b(ERROR|WARNING|SCRIPT ERROR):',line)] for p in logs}
assert not any(diagnostics.values()),diagnostics
summary={'scope':'Stages 2–3 Training Ground and Scripture Pavilion, their existing props/leaves only','verification_rows':rows,'geometry_preservation':result,'diagnostics':diagnostics,'independent_runtime':str(C),'original_project_unchanged':True,'main_hall_and_gate_unchanged':True,'current_converted_runtime_glbs':27,'world_is_not_present':True,'remaining_known_issue':'84 inherited zero-area Training roof collider triangles unchanged; separate source investigation required','performance_conclusion':'Training is slower in most views in both rounds despite fewer triangles/draws; profiling required before expansion. Pavilion measurements improve. No representative low-end compatibility established.','unperformed':['Human keyboard/mouse rehearsal and visual acceptance','Representative low-end hardware','Sustained thermal/stutter profiling','Exported executable','Production player/rank/quest permission provider/navigation','Integrated town composition/seams/lighting','Exhaustive camera orientations/visual intersections/LOD transitions','Training roof collider root-cause repair']}
(E/'final-summary.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
write(summary)
print('Stages 2–3 complete: evidence validated, reports and handoff refreshed.')

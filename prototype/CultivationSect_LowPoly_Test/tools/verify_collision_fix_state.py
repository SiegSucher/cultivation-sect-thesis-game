"""Current collision-only verification, independent-copy preparation and reports.

Approved GLBs/.blend/controllers/settings are immutable. Only the collider JSON
and its authoring program may differ from the approved checkpoint. Keep all
prior measurements and checkpoints, rather than accepting a new visual baseline.
"""
from pathlib import Path
import argparse,json,hashlib,shutil,subprocess,sys,zipfile,re
from datetime import datetime,timezone

R=Path(__file__).resolve().parents[1]
E=R/'reports/roof-collision-fix-2026-10-22'
CLEAN=R.parent.parent/'output/split-cloud-roof-collision-independent-verification'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,value):p.write_text(json.dumps(value,indent=2),encoding='utf-8')
parser=argparse.ArgumentParser()
parser.add_argument('mode',choices=['prepare-independent','finish'])
args=parser.parse_args()
if (R/'reports/environment-conversion-stage-1/final-summary.json').exists():
    raise SystemExit('Hall collision-fix evidence is historical after the authorized Sect Gate stage. Use tools/verify_environment_stage1.py finish; it still verifies all approved hall resources unchanged.')

if args.mode=='prepare-independent':
    if CLEAN.exists():raise RuntimeError('Do not overwrite the independent verification directory')
    CLEAN.mkdir(parents=True)
    for name in ['assets','scenes','scripts','baseline','tools']:
        shutil.copytree(R/name,CLEAN/name,ignore=shutil.ignore_patterns('*.import','*.uid','__pycache__'))
    shutil.copy2(R/'project.godot',CLEAN/'project.godot')
    (CLEAN/'reports/screenshots').mkdir(parents=True)
    (CLEAN/'reports/.gdignore').write_text('')
    assert not (CLEAN/'.godot').exists()
    assert not any(p.is_symlink() for p in CLEAN.rglob('*'))
    save(E/'independent-preparation.json',{'path':str(CLEAN),'no_import_cache_at_creation':True,'no_import_metadata_copied':True,'no_symlinks':True})
    print('Independent runtime copy prepared without import cache, import metadata or symlinks.')
    raise SystemExit(0)

subprocess.run([sys.executable,str(R/'tools/finalize_reports.py'),'--audits-only'],check=True,stdout=subprocess.DEVNULL)
immutable=read(E/'visual-and-gameplay-manifest.json')
assert all(sha(R/name)==digest for name,digest in immutable.items())
approval=read(R/'reports/verification-2026-10-22/approved-design-manifest.json')
changed=[name for name,digest in approval.items() if sha(R/name)!=digest]
expected=['assets/architecture/tang_main_hall/main_sect_hall.json','tools/build_split_cloud.py']
assert sorted(changed)==sorted(expected),changed
repair=read(E/'collision-repair.json')
assert sha(R/'assets/architecture/tang_main_hall/main_sect_hall.json')==repair['sha256_after']
assert sha(E/'before/main_sect_hall.json')==repair['sha256_before']
assert repair['nondegenerate_triangle_sequence_identical'] and repair['all_other_json_fields_identical']
assert repair['coverage_area_before']==repair['coverage_area_after']
coverage=read(E/'coverage-physics-results.json')
constraints=read(R/'reports/constraints-results.json')
controls=read(R/'reports/controls-results.json')
native=read(R/'reports/native-source-audit.json')
helper=read(E/'helper-tests.json')
assert coverage['failed']==constraints['failed']==controls['failed']==native['failed']==0
assert helper['successful']
baseline=read(R/'reports/baseline-results.json')
fixed=read(R/'reports/optimized-results.json')
independent=read(CLEAN/'reports/optimized-results.json')
assert all(c['pass'] for run in [baseline,fixed,independent] for c in run['checks'])
assert baseline['geometry']['near_static_triangles']==203064 and fixed['geometry']['near_static_triangles']==71557
assert str(CLEAN).replace('\\','/').lower() in independent['project_root'].replace('\\','/').lower()
assert 'Split-Cloud Hall - Low-Poly Test' in fixed['user_data_dir']
assert all(baseline[k]==fixed[k] for k in ['godot','adapter','renderer','resolution','vsync','msaa_setting'])
assert fixed['captures']==read(E/'before/optimized-results.json')['captures']
assert baseline['captures']==read(E/'before/baseline-results.json')['captures']
assert all(s['frames']==240 for run in [baseline,fixed] for s in run['samples'])
assert read(E/'source-replay-after.json')['total_degenerate']==0
diagnostics={}
for p in [E/'baseline-rendered.log',E/'optimized-rendered.log',E/'coverage-physics.log',E/'constraints.log',E/'controls.log',E/'restart-clean.log',CLEAN/'reports/independent-clean-import.log',CLEAN/'reports/independent-rendered.log']:
    messages=[line for line in p.read_text(encoding='utf-8',errors='replace').splitlines() if re.search(r'\b(ERROR|WARNING|SCRIPT ERROR):',line)]
    diagnostics[str(p)]=messages
assert not any(diagnostics.values()),diagnostics
preserved=read(R/'reports/preservation-audit.json')
assert preserved['original_unchanged']
with zipfile.ZipFile(R/'checkpoints/approved-split-cloud-2026-10-22.zip') as z:
    assert z.testzip() is None
    assert all(hashlib.sha256(z.read(name)).hexdigest()==digest for name,digest in approval.items())
recovery=read(R/'reports/verification-2026-10-22/recovery-integrity.json')
assert sha(R/'original_runtime_recovery.zip')==recovery['archive_sha256']
for name in ['baseline-results.json','optimized-results.json','constraints-results.json','controls-results.json','native-source-audit.json','geometry-audit.json','collision-data-audit.json','preservation-audit.json']:
    shutil.copy2(R/'reports'/name,E/name)
save(E/'independent-results.json',independent)
summary={'timestamp_utc':datetime.now(timezone.utc).isoformat(),'visual_direction':'approved and unchanged','authorized_changed_checkpoint_files':changed,'immutable_visual_source_controller_settings_files_verified':len(immutable),'original_files_verified':preserved['original_files_checked'],'original_unchanged':True,'approved_checkpoint_intact':True,'original_high_detail_recovery_zip_intact':True,'roof_triangles_before':2432,'roof_triangles_after':2368,'roof_zero_area_triangles_after':0,'coverage':coverage,'collision_repair':repair,'baseline_checks':len(baseline['checks']),'fixed_model_checks':len(fixed['checks']),'independent_checks':len(independent['checks']),'constraints':constraints['passed'],'controls':controls['passed'],'native_source':native['passed'],'helper_tests':helper['run'],'independent_project':str(CLEAN),'diagnostics':diagnostics,'unperformed':['Human keyboard/mouse playtest','Target low-end hardware','Sustained thermals and long-run stutter','Exported executable','Future production player/cameras and populated town integration','Exhaustive geometry self-intersection/camera directions and pixel-level distance handover']}
save(E/'verification-summary.json',summary)
from collision_fix_reports import write_reports
write_reports(baseline,fixed,read(E/'before/baseline-results.json'),read(E/'before/optimized-results.json'),summary)
print(json.dumps(summary,indent=2))

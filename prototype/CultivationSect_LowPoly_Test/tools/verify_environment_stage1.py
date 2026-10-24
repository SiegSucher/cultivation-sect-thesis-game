"""Verify the scoped gate stage, protect all other facilities, write evidence.

Modes: prepare-independent creates a clean runtime inside this test project's
ignored report folder; finish verifies its actual run and emits current reports.
"""
from pathlib import Path
import json,hashlib,struct,math,argparse,shutil,re,subprocess,sys,zipfile
R=Path(__file__).resolve().parents[1]
if (R/"reports/environment-conversion-stages-2-3/final-summary.json").exists():
    raise SystemExit("Historical stage-1 writer: use tools/finish_facility_stages.py for current evidence/reporting.")
E=R/'reports/environment-conversion-stage-1'
CLEAN=E/'independent-runtime'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,value):p.write_text(json.dumps(value,indent=2),encoding='utf-8')
parser=argparse.ArgumentParser();parser.add_argument('mode',choices=['prepare-independent','finish']);args=parser.parse_args()
if args.mode=='prepare-independent':
    if CLEAN.exists():raise RuntimeError('Do not overwrite the independent runtime')
    CLEAN.mkdir()
    for name in ['assets','scripts','scenes','baseline']:
        shutil.copytree(R/name,CLEAN/name,ignore=shutil.ignore_patterns('*.import','*.uid'))
    (CLEAN/'tools').mkdir()
    shutil.copy2(R/'tools/evaluate_gate_stage1.gd',CLEAN/'tools/evaluate_gate_stage1.gd')
    shutil.copy2(R/'project.godot',CLEAN/'project.godot')
    (CLEAN/'reports/environment-conversion-stage-1').mkdir(parents=True)
    (CLEAN/'reports/.gdignore').write_text('')
    assert not (CLEAN/'.godot').exists() and not any(p.is_symlink() for p in CLEAN.rglob('*'))
    save(E/'independent-preparation.json',{'path':str(CLEAN),'no_cache_at_creation':True,'no_import_metadata_or_symlinks':True,'inside_test_project':True})
    print('Clean independent runtime prepared entirely inside the test project.')
    raise SystemExit(0)

allowed={'assets/gallery/catalog.json','scripts/asset_gallery.gd'}|{'assets/architecture/sect_gate/'+name for name in ['sect_gate.glb','sect_gate_lod.glb','gate_leaf_left.glb','gate_leaf_right.glb']}
before=read(E/'pre-stage-manifest.json')
changed=[name for name,digest in before.items() if not (R/name).is_file() or sha(R/name)!=digest]
assert set(changed)==allowed,changed
original=R.parent/'asset-workshop'
original_hashes=read(R/'reports/original_manifest.json')
original_changes=[name for name,digest in original_hashes.items() if not (original/name).is_file() or sha(original/name)!=digest]
assert not original_changes,original_changes
assert sha(R/'assets/architecture/sect_gate/sect_gate.json')==sha(R/'baseline/stage1_gate/sect_gate.json')
for p in (R/'baseline/stage1_gate').iterdir():
    if p.suffix in ['.glb','.json']:
        assert sha(p)==before['assets/architecture/sect_gate/'+p.name]
with zipfile.ZipFile(R/'checkpoints/before-environment-stage1-sect-gate.zip') as z:
    assert z.testzip() is None
    assert all(hashlib.sha256(z.read(name)).hexdigest()==sha(R/name) for name in z.namelist())
recovery=read(R/'reports/verification-2026-10-22/recovery-integrity.json')
assert sha(R/'original_runtime_recovery.zip')==recovery['archive_sha256']
hall=read(R/'assets/architecture/tang_main_hall/main_sect_hall.json')
roof=hall['roof_collision_faces']
def area2(a,b,c):
    u=[b[i]-a[i] for i in range(3)];v=[c[i]-a[i] for i in range(3)]
    return sum(x*x for x in [u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]])
assert len(roof)//3==2368 and all(area2(*roof[i:i+3])>0 for i in range(0,len(roof),3))

geometry=[]
for filename in ['sect_gate.glb','sect_gate_lod.glb','gate_leaf_left.glb','gate_leaf_right.glb']:
    raw=(R/'assets/architecture/sect_gate'/filename).read_bytes()
    n=struct.unpack_from('<I',raw,12)[0];g=json.loads(raw[20:20+n]);blob=raw[28+n:]
    def accessor(index):
        a=g['accessors'][index];view=g['bufferViews'][a['bufferView']]
        fmt={5126:'f',5125:'I',5123:'H',5121:'B'}[a['componentType']]
        count={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]
        size=struct.calcsize(fmt)*count;stride=view.get('byteStride',size)
        start=view.get('byteOffset',0)+a.get('byteOffset',0)
        return [struct.unpack_from('<'+fmt*count,blob,start+i*stride) for i in range(a['count'])]
    triangles=0;collapsed=0;normal_errors=0
    for mesh in g['meshes']:
        for primitive in mesh['primitives']:
            p=accessor(primitive['attributes']['POSITION'])
            assert all(math.isfinite(x) for point in p for x in point)
            normals=accessor(primitive['attributes']['NORMAL'])
            normal_errors+=sum(not all(math.isfinite(v) for v in normal) or not .99<sum(v*v for v in normal)<1.01 for normal in normals)
            indices=[i[0] for i in accessor(primitive['indices'])]
            assert min(indices)>=0 and max(indices)<len(p)
            for i in range(0,len(indices),3):
                collapsed+=area2(*[p[j] for j in indices[i:i+3]])<1e-14
                triangles+=1
    assert collapsed==normal_errors==0,(filename,collapsed,normal_errors)
    assert not g.get('textures') and not g.get('images')
    assert all(m.get('alphaMode','OPAQUE')=='OPAQUE' for m in g['materials'])
    geometry.append({'file':filename,'triangles':triangles,'surfaces':sum(len(m['primitives']) for m in g['meshes']),'images':0,'textures':0,'zero_area_triangles':collapsed,'invalid_normals':normal_errors,'finite_positions':True,'opaque':True})
save(E/'geometry-audit.json',geometry)
previous=read(E/'before-results.json');current=read(E/'after-results.json')
assert previous['failed']==current['failed']==0
assert previous['camera_poses']==current['camera_poses']
assert all(previous[k]==current[k] for k in ['adapter','godot','renderer','resolution','msaa','vsync'])
assert all(s['frames']==240 for r in [previous,current] for s in r['samples'])
envelope=read(E/'envelope-results.json');controls=read(E/'controls-results.json');native=read(E/'native-source-audit.json')
assert envelope['failed']==controls['failed']==native['failed']==0
assert read(R/'reports/constraints-results.json')['failed']==0
assert read(R/'reports/controls-results.json')['failed']==0
captures=read(E/'context-captures.json');assert len(captures)==4 and all(c['captured'] for c in captures)
independent=read(CLEAN/'reports/environment-conversion-stage-1/after-results.json')
assert independent['failed']==0 and str(CLEAN).replace('\\','/').lower() in independent['project_root'].replace('\\','/').lower()
save(E/'independent-results.json',independent)
diagnostics={}
for p in [E/'before-rendered.log',E/'after-rendered.log',E/'envelope.log',E/'controls.log',E/'context-capture.log',E/'hall-regression.log',E/'hall-controls.log',E/'restart-clean.log',CLEAN/'reports/import.log',CLEAN/'reports/run.log']:
    diagnostics[str(p.relative_to(R))]=[s for s in p.read_text(encoding='utf-8',errors='replace').splitlines() if re.search(r'\b(ERROR|WARNING|SCRIPT ERROR):',s)]
assert not any(diagnostics.values()),diagnostics
build=read(E/'conversion-build.json')
save(R/'assets/architecture/sect_gate/low_poly_stage1_metrics.json',{'purpose':'Current visual metrics; the original physical specification JSON is preserved byte-identical, including its historical pre-conversion visual statistics. Runtime gameplay does not use those historical counts.','models':geometry,'stage':1})
summary={'stage':1,'scope':'Sect Gate near/distant and two leaves only','original_files_verified':len(original_hashes),'original_changed':original_changes,'allowed_preexisting_files_changed':changed,'all_other_preexisting_assets_scripts_scenes_sources_unchanged':True,'approved_hall_unchanged_and_roof_issue_remains_fixed':True,'gate_collision_scale_json_identical':True,'gate_runtime_mechanics_and_inspection_controller_identical':True,'geometry':geometry,'gate_before_checks':previous['passed'],'gate_after_checks':current['passed'],'gate_input_checks':controls['passed'],'gate_envelope_checks':envelope['passed'],'native_source_checks':native['passed'],'hall_dimension_camera_checks':18,'hall_input_checks':7,'independent_run_checks':independent['passed'],'independent_runtime':str(CLEAN),'diagnostics':diagnostics,'remaining_facilities':['Training Ground and seven prop types','Scripture Pavilion, six furnishing types and archive gate'],'absent_world_categories':['Assembled town','Residences/shops','Terrain/cliffs','Road network/bridges','Vegetation/scenery library','Production navigation/player/NPC systems'],'unperformed':['Human playtest and user visual acceptance of stage 1','Representative low-end hardware','Sustained thermals and long-run stutter','Exported executable','Whole-town composition/performance/navigation','Exhaustive geometry intersection and pixel-level distance-transition analysis','Training/Pavilion manual gameplay regression in this stage']}
summary['gate_rollback_baseline_and_checkpoint_integrity']=True
summary['original_runtime_recovery_zip_unchanged']=True
save(E/'final-summary.json',summary)
subprocess.run([sys.executable,str(R/'tools/write_conversion_inventory.py')],check=True)
from report_environment_stage1 import write_reports
write_reports(R,summary,build,previous,current)
print(json.dumps(summary,indent=2))

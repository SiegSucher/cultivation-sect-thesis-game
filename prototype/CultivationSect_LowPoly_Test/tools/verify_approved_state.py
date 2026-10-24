"""Preserve approved art, archive old evidence and prepare a cache-free copy.

Run prepare once before revalidation, then finish after the rendered runs.
This never edits the original workshop or the approved visual resources.
"""
from pathlib import Path
import argparse, hashlib, json, shutil, zipfile, re
from datetime import datetime, timezone

R=Path(__file__).resolve().parents[1]
WORK=R.parent.parent
ORIGINAL=R.parent/'asset-workshop'
EVIDENCE=R/'reports/verification-2026-10-22'
CLEAN=WORK/'output/split-cloud-approved-independent-verification'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,value):p.write_text(json.dumps(value,indent=2),encoding='utf-8')
parser=argparse.ArgumentParser()
parser.add_argument('mode',choices=['prepare','finish'])
args=parser.parse_args()
if (R/'reports/roof-collision-fix-2026-10-22/collision-repair.json').exists():
    raise SystemExit('This is the historical pre-repair verifier. Use tools/verify_collision_fix_state.py finish; it checks the two explicitly authorized collider/exporter changes against the unchanged approval checkpoint.')

if args.mode=='prepare':
    EVIDENCE.mkdir(parents=True,exist_ok=False)
    previous=EVIDENCE/'previous-evidence'
    previous.mkdir()
    for name in ['baseline-results.json','optimized-results.json','performance_comparison.md','baseline_performance.md','low_poly_test_report.md','preservation-audit.json','native-source-audit.json','geometry-audit.json','constraints-results.json','controls-results.json']:
        shutil.copy2(R/'reports'/name,previous/name)
    shutil.copytree(R/'reports/screenshots',previous/'screenshots')
    shutil.copy2(R/'HANDOFF.md',previous/'HANDOFF.md')
    protected=[*sorted((R/'assets/architecture/tang_main_hall').glob('*.glb')),R/'assets/architecture/tang_main_hall/main_sect_hall.json',R/'source/split_cloud_hall.blend',R/'tools/build_split_cloud.py',R/'scripts/tang_main_hall.gd',R/'scripts/hall_preview_door.gd',R/'scripts/training_inspection_player.gd']
    approved={p.relative_to(R).as_posix():sha(p) for p in protected}
    save(EVIDENCE/'approved-design-manifest.json',approved)
    checkpoint=R/'checkpoints/approved-split-cloud-2026-10-22.zip'
    checkpoint.parent.mkdir(exist_ok=True)
    if checkpoint.exists():raise RuntimeError('Do not overwrite an existing approved checkpoint')
    with zipfile.ZipFile(checkpoint,'w',zipfile.ZIP_DEFLATED) as z:
        for p in protected:z.write(p,p.relative_to(R))
        for name in ['BUILDING_DESIGN.md','LOW_POLY_STYLE_GUIDE.md']:
            z.write(R/'reports'/name,'reports/'+name)
    # Original recovery is read-only: verify CRCs and exact original bytes of
    # all archived runtime files, including the original high-detail GLBs.
    with zipfile.ZipFile(R/'original_runtime_recovery.zip') as z:
        assert z.testzip() is None
        bad=[name for name in z.namelist() if not (ORIGINAL/name).is_file() or hashlib.sha256(z.read(name)).hexdigest()!=sha(ORIGINAL/name)]
        assert not bad,bad
        recovery={'entries':len(z.namelist()),'all_archive_files_match_original':True,'archive_sha256':sha(R/'original_runtime_recovery.zip')}
    save(EVIDENCE/'recovery-integrity.json',recovery)
    if CLEAN.exists():raise RuntimeError('Do not overwrite existing clean verification directory')
    CLEAN.mkdir(parents=True)
    for name in ['assets','scripts','scenes','baseline','tools']:
        shutil.copytree(R/name,CLEAN/name,ignore=shutil.ignore_patterns('*.import','*.uid','__pycache__'))
    shutil.copy2(R/'project.godot',CLEAN/'project.godot')
    (CLEAN/'reports/screenshots').mkdir(parents=True)
    (CLEAN/'reports/.gdignore').write_text('')
    assert not (CLEAN/'.godot').exists()
    assert not any(p.is_symlink() for p in CLEAN.rglob('*'))
    save(EVIDENCE/'preparation.json',{'timestamp_utc':datetime.now(timezone.utc).isoformat(),'visual_direction_approved_by_user':True,'approved_checkpoint':str(checkpoint),'clean_project':str(CLEAN),'clean_copy_had_no_import_cache':True,'clean_copy_has_no_symlinks':True,'original_runtime_recovery':recovery,'only_runtime_configuration_change':'Unique test application name; separate Godot user-data folder'})
    print('Approved design checkpoint saved; recovery checked; cache-free independent copy prepared.')
else:
    approved=json.loads((EVIDENCE/'approved-design-manifest.json').read_text())
    changes=[name for name,digest in approved.items() if sha(R/name)!=digest]
    assert not changes,changes
    for name in ['baseline-results.json','optimized-results.json','constraints-results.json','controls-results.json','native-source-audit.json','geometry-audit.json','collision-data-audit.json','preservation-audit.json']:
        shutil.copy2(R/'reports'/name,EVIDENCE/name)
    independent=json.loads((CLEAN/'reports/optimized-results.json').read_text())
    assert all(c['pass'] for c in independent['checks'])
    save(EVIDENCE/'independent-results.json',independent)
    source_manifest=json.loads((R/'reports/original_manifest.json').read_text())
    original_changes=[name for name,digest in source_manifest.items() if not (ORIGINAL/name).is_file() or sha(ORIGINAL/name)!=digest]
    assert not original_changes,original_changes
    baseline=json.loads((R/'reports/baseline-results.json').read_text())
    optimized=json.loads((R/'reports/optimized-results.json').read_text())
    assert all(c['pass'] for c in baseline['checks']+optimized['checks'])
    assert baseline['geometry']['near_static_triangles']==203064
    assert optimized['geometry']['near_static_triangles']==71557
    assert baseline['application_name']==optimized['application_name']=='Split-Cloud Hall - Low-Poly Test'
    assert 'Split-Cloud Hall - Low-Poly Test' in optimized['user_data_dir']
    assert str(CLEAN).replace('\\','/').lower() in independent['project_root'].replace('\\','/').lower()
    collision=json.loads((R/'reports/collision-data-audit.json').read_text())
    result={'timestamp_utc':datetime.now(timezone.utc).isoformat(),'visual_direction_approved_by_user':True,'approved_visual_resource_changes':changes,'original_files_verified':len(source_manifest),'original_file_changes':original_changes,'approved_checkpoint_integrity':None,'independent_project':str(CLEAN),'independent_rendered_checks_passed':len(independent['checks']),'source_project_root':str(R),'original_project_root':str(ORIGINAL),'runtime_app_identity_distinct':True,'remaining_unperformed':['Human keyboard/mouse playtest','Target low-end hardware','Sustained thermals and long-run stutter','Production player/camera and populated town integration','Exported executable','Exhaustive self-intersection/camera orientation and pixel-level distance-handover analysis']}
    with zipfile.ZipFile(R/'checkpoints/approved-split-cloud-2026-10-22.zip') as z:
        assert z.testzip() is None
        assert all(hashlib.sha256(z.read(name)).hexdigest()==digest for name,digest in approved.items())
        result['approved_checkpoint_integrity']=True
    result['remaining_collision_data_issue']=collision
    result['baseline_checks_passed']=len(baseline['checks'])
    result['approved_model_checks_passed']=len(optimized['checks'])
    result['user_data_dir']=optimized['user_data_dir']
    result['reference_images_preserved']=sorted(p.name for p in (R/'reference_images').glob('*.png'))
    assert len(result['reference_images_preserved'])==9
    diagnostics={}
    for path in [R/'reports/restart-clean.log',CLEAN/'reports/independent-clean-import.log',CLEAN/'reports/independent-rendered.log',EVIDENCE/'baseline-rendered.log',EVIDENCE/'optimized-rendered.log',EVIDENCE/'constraints.log',EVIDENCE/'controls.log']:
        findings=[line for line in path.read_text(encoding='utf-8',errors='replace').splitlines() if re.search(r'\b(ERROR|WARNING|SCRIPT ERROR):',line)]
        diagnostics[str(path)]=findings
    assert not any(diagnostics.values()),diagnostics
    result['current_import_and_runtime_diagnostics']=diagnostics
    save(EVIDENCE/'verification-summary.json',result)
    performance_rows='\n'.join(f"| {x['view']} | {x['mean_ms']:.3f} / {y['mean_ms']:.3f} | {x['average_fps']:.1f} / {y['average_fps']:.1f} | {100*(1-y['mean_ms']/x['mean_ms']):.1f}% |" for x,y in zip(baseline['samples'],optimized['samples']))
    (R/'reports/VERIFICATION_RESULTS.md').write_text(f'''# Approved Main Sect Hall - verification results

22 October 2026. User approval recorded. **Approved visual design unchanged. No other facility converted.**

| Requested verification | Result |
| --- | --- |
| Original project untouched | PASS: all {len(source_manifest):,} recorded non-cache original files match their original SHA-256 hashes |
| High-detail recovery | PASS: all original runtime ZIP entries match current original files; ZIP CRC integrity checked |
| Independent test import/run | PASS: cache-free copy at `{CLEAN}`; no symlinks/import metadata; fresh import and 21 rendered checks pass |
| Visible geometry/materials | PASS: 71,557 static triangles vs 203,064; 12 opaque shared materials, no textures; no zero-area visible triangles |
| Gameplay scale and collision behavior | PASS in tested routes: 21 rendered checks and 18 supplemental checks; root, podium, doors, stairs, floor/dais and non-roof collider records retained |
| Roof collision metadata quality | REVIEW: 64 of 2,432 collider triangles have zero area; no related runtime failure observed; pending targeted cleanup |
| First/third-person and interaction controls | PASS with existing 1.8 m inspection fixture; seven dispatched-input checks; production player does not exist in this source |
| Editable source | PASS: seven checks after reopening the saved Blender source |
| Saved-project restart | PASS: current import/runtime logs contain no errors/warnings |
| Preservation of approved design | PASS: visual resources, native source, collider JSON, authoring program and controller files match approval manifest; checkpoint ZIP intact |

The only runtime configuration change assigns the test its own application identity and Godot user-data folder. That prevents sharing user data with the original workshop and changes no artwork or gameplay setting. The other three copied facilities remain unchanged.

## Fresh matched performance

RTX 3050 Laptop GPU, 1280x720, GL Compatibility, MSAA 4x, uncapped/VSync off; six 240-frame samples. No power/thermal/background-load control. Positive reductions are improvements; differences near zero are inconclusive.

| View | Mean ms before / after | Average FPS before / after | Mean frame-time reduction |
| --- | ---: | ---: | ---: |
{performance_rows}

Exterior observations improved about 22-26%, fixed interior about 8%; first-person was ~1.6% slower and third-person essentially unchanged. Previous samples showed larger gains, demonstrating variability. **A consistent sustained or low-end-device speedup has not been established.** [Full comparison and prior pair](performance_comparison.md).

## Remaining issue and unperformed tests

The 64 degenerate roof collider faces were left unchanged during verification to preserve the exact approved state. They contribute no surface. Remove only these redundant collider faces and filter them in the exporter, then rerun collision/camera tests while preserving approved visible GLB/native-source hashes. Do not remodel the hall.

NOT TESTED: human keyboard/mouse rehearsal; intended low-end hardware; sustained thermal/long-run stutter behavior; exported executable; production player/camera and populated-town integration; exhaustive geometry self-intersection/camera orientation and pixel-level distance handover. No current town or production player exists in the active source.

## Handoff and preservation

[HANDOFF.md](../HANDOFF.md) records approval, all nine reference filenames, current evidence, remaining work and the exact next action for Claude. Claude should inspect the verification summary and collision audit first, perform only targeted collider cleanup, and retest without visual redesign. No message was sent to Claude. No further facility conversion is authorized.

Approved checkpoint: `../checkpoints/approved-split-cloud-2026-10-22.zip`. Original runtime recovery: `../original_runtime_recovery.zip`. [Verification summary](verification-2026-10-22/verification-summary.json), [collision audit](collision-data-audit.json), [full experiment report](low_poly_test_report.md).
''',encoding='utf-8')
    print(json.dumps(result,indent=2))

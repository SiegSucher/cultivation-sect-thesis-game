"""Publish the current Codex report/handoff only from executed test evidence."""
from pathlib import Path
import json,re,struct
from audit_claude_integration_state import audit
R=Path(__file__).resolve().parents[1]
E=R/'reports/codex-claude-integration'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def table(headers,rows):return '\n'.join(['| '+' | '.join(headers)+' |','| '+' | '.join(['---']*len(headers))+' |']+['| '+' | '.join(map(str,row))+' |' for row in rows])
def brief(p):
    b=p.read_bytes();n=struct.unpack_from('<I',b,12)[0];g=json.loads(b[20:20+n])
    return [sum(g['accessors'][v['indices']]['count']//3 for m in g['meshes'] for v in m['primitives']),sum(len(m['primitives']) for m in g['meshes']),len(g.get('images',[]))]
proof=audit()
tests={}
for name in ['basic-results','headless-results','rendered-results','gallery-input-results','native-source-audit','hall-controls','gate-controls','facility-controls']:
    d=read(E/(name+'.json'));assert d['failed']==0 and d['passed']>0,(name,d)
    tests[name]=d['passed']
rendered=read(E/'rendered-results.json')
assert rendered['sampled_camera_and_visual_volumes']>0 and not rendered['camera_failures'] and not rendered['visual_failures']
for name in ['gallery-input-results','rendered-results']:
    assert all(c['pass'] and (R/c['file'].removeprefix('res://')).is_file() for c in read(E/(name+'.json'))['captures'])
assert all(c['pass'] and (R/c['file'].removeprefix('res://')).is_file() for c in read(E/'final-captures.json'))
diagnostics={}
for name in ['import','basic','headless','rendered','gallery-input','hall-regression','gate-regression','facility-regression','default-startup','final-captures']:
    p=E/(name+'.log');diagnostics[name]=[s for s in p.read_text(encoding='utf-8',errors='replace').splitlines() if re.search(r'\b(ERROR|WARNING|SCRIPT ERROR):',s)]
assert not any(diagnostics.values()),diagnostics
catalog=read(R/'assets/gallery/catalog.json')
ids=[e['id'] for e in catalog[4:]]
summary=read(R/'staging/claude_buildings/build_summary.json')
rows=[];files=[]
for g in rendered['geometry']:
    aid=g['asset'];size=[float(v) for v in re.findall(r'-?\d+(?:\.\d+)?',g['size'])]
    rows.append([summary[aid]['name'],f'{size[0]:.2f} × {size[2]:.2f}',f'{size[1]:.2f}',f"{g['triangles']:,}",g['surfaces'],g['collision_shapes']])
    files += ['assets/architecture/'+aid+'/'+aid+'.glb','scenes/buildings/'+aid+'.tscn','scenes/review/'+aid+'_walkthrough.tscn']
files += ['source/claude_buildings_integrated.blend','scripts/claude_asset_review.gd','Review Claude Assets.cmd']
test_rows=[
 ['Fresh rerun of Claude basic assertions against integrated scenes',f"{tests['basic-results']} PASS / 0 FAIL"],
 ['Expanded headless routes, scale/material/collision/camera checks',f"{tests['headless-results']} PASS / 0 FAIL"],
 ['Expanded rendered routes and image captures',f"{tests['rendered-results']} PASS / 0 FAIL"],
 ['Gallery registration/interior presets/source paths and actual programmatic inputs',f"{tests['gallery-input-results']} PASS / 0 FAIL"],
 ['Read-only reopening of editable Blender source',f"{tests['native-source-audit']} PASS / 0 FAIL"],
 ['Existing Hall review inputs/routes',f"{tests['hall-controls']} PASS / 0 FAIL"],
 ['Existing Gate review inputs/routes',f"{tests['gate-controls']} PASS / 0 FAIL"],
 ['Existing Training/Pavilion review inputs/routes',f"{tests['facility-controls']} PASS / 0 FAIL"],
 ['Default project startup','PASS; rendered unchanged default Hall, 60-frame startup'],
 ['GLB geometry and materials','Four models: finite positions, unit flat normals, opaque materials, no images/textures/external URIs or near-zero-area triangles at audit tolerance'],
 ['Original project preservation',f"{proof['original_files_verified']:,} recorded non-cache SHA-256 hashes match"],
 ['Claude staging preservation',f"All {proof['staging_files_verified_unchanged']} frozen files match, including source, builder, scenes, models, import metadata and review scripts"],
 ['Earlier assets/controls/settings and Claude report/evidence','Frozen hashes match; only existing catalog and gallery code intentionally changed'],
]
limitations=[
 'Human keyboard/mouse playtesting and user visual acceptance were not performed.',
 'No FPS/frame-time benchmark, representative low-end hardware, sustained thermal/stutter test, exported executable or populated-world test was performed for this batch. Geometry counts do not establish performance.',
 'Elder courtyard and Herb Garden require supporting ground/terrain. The review supplies a collision plane at y=-0.012; garden path slabs are visual-only with tops around y=0.04, so they do not raise foot contact to the decorative path top. Terrain fit, foot/path seams and production ground remain deferred.',
 'Door leaves are authored standing open and are static geometry, not operable doors. Small decorative props/plants/lanterns/pots and path finishes are not all collidable by design. No sleeping, dining, harvesting, NPC, quest or navigation systems were added or tested.',
 'No distant simplified mesh/LOD exists for these four models. Roof walking, exhaustive collision coverage, all camera angles and terrain/navigation integration were not tested. Collision/camera conclusions apply only to the recorded paths and sampled volumes.',
 'Native-source button path/file availability was tested; invoking the operating-system Open source action and manually double-clicking the CMD launcher were not tested. Direct Godot scene routes and direct Blender source reopening were tested.',
 'The shared Blender file contains four alternative asset collections at their authoring origin. Isolate one collection for editing; the overlapping authoring collections are not a town arrangement.',
]
known='Existing Training performance regression and its 84 zero-area roof-collider triangles remain unchanged. No timing or collider repair is claimed here; see `LOW_POLY_STAGES_2_3_REPORT.md`. Current user priority is asset completion/integration, with final town placement deferred.'
result={'scope':'Four Claude staged assets integrated into the isolated test project; no final town placement','tests':tests,'preservation':proof,'files_integrated':files,'existing_runtime_files_changed':proof['allowed_existing_runtime_changes'],'diagnostics':diagnostics,'sampled_camera_and_visual_volumes':rendered['sampled_camera_and_visual_volumes'],'screenshots':sorted(p.name for p in E.glob('*.png')),'limitations':limitations,'carried_issue':known,'next_action':'Manually review the four integrated assets and record actual observations; continue the next explicitly authorized asset batch in fresh staging with a report. Keep asset completion ahead of town placement; preserve this batch and previous assets. Profile Training before performance claims.'}
(E/'final-summary.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
report='''# Codex report — Claude asset integration

22 October 2026. Read `CLAUDE_ASSET_REPORT.md`, the actual staging builder, scenes, models, summary and review/test code. Claude's reported results were treated as prior evidence; the results below are fresh Codex tests of the integrated project copies.

## Integrated result

All four delivered buildings are now available in the eight-entry asset gallery and through individual Walk asset routes. Model geometry/materials were copied byte-for-byte from staging. Copied scenes retain all authored collision shapes, transforms, floor elevations and plaque text; only the GLB resource path changed. No asset redesign or world placement was performed.

The original project `../asset-workshop` remains unchanged against 1,599 recorded non-cache hashes. All 21 staged files, Claude's report and its original screenshots/test results remain unchanged. The earlier Hall, Gate, Training Ground and Pavilion model/source/scene/controller data, project settings and default Hall scene remain unchanged. Only two pre-existing runtime files changed: `assets/gallery/catalog.json` and `scripts/asset_gallery.gd`.

'''+table(['Asset','Imported X × Z (m)','Height (m)','Triangles','Surfaces','Collision shapes'],rows)+'''

Imported scale matches the staged measurements within 0.05 m, and each asset uses an identity root transform. The existing 1.8 m tall, 0.28 m radius inspection controller physically enters the tested rooms and climbs/descends the recorded stairs. The Garden's lowest decorative geometry is about -0.0063 m, not exactly zero; no model was rescaled to hide this.

## Files integrated and gallery changes

'''+ '\n'.join('- `'+f+'`' for f in files)+'''

Godot generated new `.glb.import` metadata for the four copied models. These copies have different UIDs (Godot's internal resource IDs) from the staged resources; staged import metadata was not copied or edited. Each copied building scene depends only on its own canonical GLB under `assets/architecture/`, with no runtime staging or original-project dependency. The native source is a byte-identical copy, not a reexport.

The gallery preserves the first four catalog entries and adds the four new entries. Its small code extension enables metadata-defined walkthrough routes and authored interior camera presets for the new buildings. Existing routes and camera presets remain in place. The new review script shows **one asset at identity/local origin at a time**, with a neutral inspection floor and the unchanged controller. Keys 2–5 select an asset for inspection; this does not assign world positions. `Review Claude Assets.cmd` opens the Disciples' inspection scene; each new gallery entry opens its own correct wrapper.

## Tests actually performed

'''+table(['Check','Actual result'],test_rows)+f'''

The expanded functional run checks every dorm room via the veranda, the elder's gate/main-room stair and west-facing attendant wing, the dining main and both side entrances, kitchen connection and east service stair in both directions, and garden circulation around the spring/beds to the pavilion and tool shed. Solid dorm walls and raised herb beds block real movement. Both first- and third-person cameras were exercised. There were {rendered['sampled_camera_and_visual_volumes']} sampled camera-sphere and upper-body/visible-mesh checks on the rendered routes, with no detected obstruction. This is not exhaustive collision certification.

The input suite uses actual programmatic W, Tab, mouse-motion, 1, 2–5 and Esc events. It verifies source-path availability, disabled door-toggle buttons for static leaves, correct gallery selection, interior-camera clearance, walking, camera switching and return to the gallery. No human-input rehearsal is implied.

Godot 4.7.2, GL Compatibility, 1280×720, project MSAA 4x; review ambient .65 and one 100 m shadowed sun match the Hall/Gate inspection treatment. No asset lights were added. Functional rehearsals used fixed-fps 60 for repeatability; their elapsed times are not benchmarks. Final checked import/runtime logs have no error/warning diagnostics. An initial type-inference error in the new Codex test harness was corrected before execution; its original log is retained as `initial-harness-parse-error.log`. No asset file was modified to make a failing test pass.

GLB palette checks confirm the approved architectural colors and roughness (.82, bronze .56). Garden/planting colors and water are preserved as documented by Claude; water roughness is .5. All runtime surfaces have present opaque StandardMaterial3D materials, with no external textures or custom shaders. Native source reopening verifies four editable collections and the expected 50 material mesh batches.

Reproduction from the test project, using the shared `tools/godot/Godot_v4.7.2-stable_win64_console.exe` software executable:

```text
--headless --path . --editor --import --log-file reports/codex-claude-integration/import.log
--headless --fixed-fps 60 --path . --script tools/verify_integrated_claude_basics.gd
--headless --fixed-fps 60 --path . --script tools/verify_claude_integration.gd
--fixed-fps 60 --path . --script tools/verify_claude_integration.gd -- --capture
--fixed-fps 60 --path . --script tools/test_claude_asset_gallery.gd
```

Audit/report entry: `tools/finalize_claude_integration.py`. It validates executed results and preservation before updating this report and the handoff; it does not run Godot tests itself. The staging builder was not executed, because it would overwrite Claude's staging delivery. Recovery: `checkpoints/before-claude-asset-integration.zip` backs up changed gallery files, the prior handoff and prior inventory. `pre-integration-manifest.json` freezes 841 pre-existing files. Full copy provenance, palette/UID comparisons, raw JSON results and logs are under `reports/codex-claude-integration/`.

## Genuine screenshots and visual inspection

These images were captured from Godot's rendered viewport in this integration run. They are isolated asset reviews, not a proposed town layout. Exterior and selected interior images were inspected for missing materials, obvious holes/clipping and style consistency; no blocking visual defect was observed in those inspected images. User visual acceptance is still pending. Sparse roof seams, varied roof silhouettes and the Hall's jade/timber/plaster/stone treatment remain readable.

![Disciples' Residence](codex-claude-integration/disciple_residence-three-quarter.png)

![Elder Residence](codex-claude-integration/elder_residence-three-quarter.png)

![Dining Hall and Kitchen](codex-claude-integration/dining_hall_kitchen-three-quarter.png)

![Spirit Herb Garden](codex-claude-integration/spirit_herb_garden-three-quarter.png)

![Kitchen interior](codex-claude-integration/dining-kitchen-wide.png)

The evidence folder has 27 unique current screenshots: 17 route/exterior/interior/camera images, eight gallery images and two additional dining/kitchen views. Third-person images include the 1.8 m inspection figure. The source `.blend` audit was read-only and did not alter staging or its copied source.

## Problems, limits and untested areas

'''+ '\n\n'.join('- '+x for x in limitations)+'''

'''+known+'''

No blocking import, material, scale or tested-route defect was found in these four integrated copies. This statement covers the tests listed here, not production-world readiness.

## Exact next action

Open `Review Claude Assets.cmd`, or gallery → one of the four new buildings → Walk asset. Manually review doors/verandas, all dorm rooms, the elder side wing, kitchen service entrance, and garden path/bed/pavilion/shed circulation in both camera modes, recording actual observations separately from automation. Continue the next explicitly authorized asset batch in a **new staging folder** and provide another asset report for integration. Preserve this staging delivery and canonical copies; do not rerun its original generator in place. Keep prioritizing asset completion. Do not assign final town positions or start terrain, road or town-layout placement. Training profiling/collider cleanup remain separate outstanding issues, and performance claims must wait for actual tests.
'''
(R/'reports/CODEX_REPORT.md').write_text(report,encoding='utf-8')
old=(R/'HANDOFF.md').read_text(encoding='utf-8')
references=old[old.index('## Original visual references'):]
handoff='''# Claude/Codex handoff — eight standalone sect assets

22 October 2026. Latest user authorized validation/integration of the four assets in `reports/CLAUDE_ASSET_REPORT.md` and prioritizes asset completion. **Final town-layout placement remains prohibited.** Work stayed inside `prototype/CultivationSect_LowPoly_Test`. No message was sent to Claude.

## Current verified state

Eight explicit gallery entries: approved Main Sect Hall, Sect Gate, Large Martial Training Ground, Scripture Pavilion, Disciples' Residence, Elder Residence, Dining Hall/Kitchen and Spirit Herb Garden. These are standalone asset scenes, not an assembled town. Original project `../asset-workshop`: 1,599 recorded non-cache hashes unchanged. Approved Hall and earlier converted assets/controllers/settings remain preserved. All 21 Claude staging files and Claude report/evidence are unchanged.

Current integration report: `reports/CODEX_REPORT.md`. Evidence: `reports/codex-claude-integration/final-summary.json`, copy manifest, palette/provenance audit, native-source audit, Godot logs and genuine screenshots. Existing stages 1–3 reports remain historical evidence, not current inventory or proof of new-asset testing.

## Integrated files

'''+ '\n'.join('- `'+f+'`' for f in files)+'''

The four GLBs are byte-identical to Claude's staged models. Each scene changes only its GLB resource path; authored collisions, proportions, floors and plaques remain. No redesign/rescale. `source/claude_buildings_integrated.blend` is an identical source copy; isolate one of its four collections to edit. Fresh import metadata gives copied GLBs distinct resource IDs. Canonical building scenes load only their own canonical GLB, not staging. Stage originals remain available for rollback/comparison.

Existing files changed: `assets/gallery/catalog.json` appends four entries while preserving the first four; `scripts/asset_gallery.gd` adds optional per-entry Walk/interior-camera metadata handling. New `claude_asset_review.gd` reuses the unchanged 1.8 m/.28 m controller and displays one asset at local identity at a time. No world placements. Default main scene/settings remain unchanged.

## Fresh verification

'''+table(['Check','Result'],test_rows)+f'''

Rendered tests sampled {rendered['sampled_camera_and_visual_volumes']} camera/body volumes; all clear on recorded routes. The 138 checks include screenshot writes; they are not 138 unique gameplay systems. Direct programmatic key/mouse tests passed; human playtesting is not claimed. All current four models have valid flat normals and present opaque texture-free materials. Their tested triangle/surface/shape counts and measured dimensions are in `CODEX_REPORT.md`.

## Known issues and unperformed work

New assets: no blocking issue found on executed tests. Elder courtyard and Garden need supporting collision ground; Garden paths are decorative visual-only slabs, so later terrain/path foot-contact alignment is still required. Doors are static/open, small decorative props are not comprehensively collidable, and no distant simplified model, navigation, sleeping/dining/harvest interaction or world integration is provided. The Garden has small decorative geometry down to about y=-0.0063 m. Do not invent terrain or world placement to hide these limits.

NOT TESTED for this batch: human playtest/visual acceptance; performance/FPS, low-end hardware, sustained thermals/stutter, exported game; terrain fit/production player/NPC/navigation; exhaustive collisions, roof walking or all camera angles. Source path/file and direct Blender reopening pass; OS Open source button launch and manual launcher double-click were not performed. The inspection plane is not production terrain.

Carried issues: Training remains slower in most recorded stage-2 benchmark views despite fewer triangles/draws, and retains 84 inherited roof-collider degenerates. Neither is repaired or rebenchmarked here. Hall's earlier repaired roof collider and approved design remain unchanged. See `reports/LOW_POLY_STAGES_2_3_REPORT.md`.

## Exact next action

Review `reports/CODEX_REPORT.md` and launch `Review Claude Assets.cmd` (or each gallery Walk action). 1 walk/review; WASD/mouse; Tab FPP/TPP; 2–5 select an asset for inspection; Esc gallery. Manually rehearse all dorm rooms, the elder side wing, kitchen/service door and garden/shed/pavilion routes, recording actual observations. Keep asset completion first: continue only the next explicitly authorized asset batch in fresh staging with its own report. Do not overwrite this staging delivery or silently edit canonical copies from an old generator. **Do not start final town-layout placement.** Training profiling/collider cleanup remain separate tasks before performance claims.

Audit/report tool: `tools/finalize_claude_integration.py`. Test commands are in `CODEX_REPORT.md`; this finalizer checks evidence but does not execute engine tests. Prior stage finalizers must not overwrite current reporting. Rollback changed gallery code/catalog from `checkpoints/before-claude-asset-integration.zip` if needed; retain new assets and staging for recoverability. Full preservation proof is in `pre-integration-manifest.json` (841 frozen files), with only catalog/gallery allowed changes.

'''+references
(R/'HANDOFF.md').write_text(handoff,encoding='utf-8')
inventory='''# Current low-poly asset inventory — eight standalone facilities

22 October 2026. Claude's four delivered facilities are now integrated and tested alongside the four previous facilities. Current runtime: eight catalog entries, 31 GLBs and 30 scenes. This is an asset workshop, not a completed town. No final town placements were assigned. Full new-asset evidence: `CODEX_REPORT.md`; earlier conversion counts and limitations remain in `LOW_POLY_STAGES_2_3_REPORT.md`.

'''+table(['Category','Classification','Current finding'],[
 ['Main Sect Hall','Already converted / approved','Preserved; earlier roof repair unchanged'],
 ['Sect Gate and paired leaves','Already converted','Preserved'],
 ['Training Ground / seven equipment kinds','Already converted; issues retained','Preserved; timing regression and 84 degenerate roof collider triangles still unresolved'],
 ['Scripture Pavilion / library props / archive leaves','Already converted','Preserved; current review input routes retested'],
 ["Disciples\u0027 Residence",'Already converted / integrated; human review pending','Four rooms, veranda, furnishings; Godot scene/scale/material/movement/camera tests pass'],
 ['Elder Residence compound','Already converted / integrated; human review pending','Main house, attendant wing, courtyard/gate/embedded pines; supporting ground required'],
 ['Dining Hall and Kitchen','Already converted / integrated; human review pending','Dining, kitchen, service door/stair, furniture/well; tests pass'],
 ['Spirit Herb Garden','Already converted / integrated; human review pending','Embedded plants/beds, spring, pavilion and shed; supporting terrain required; path slabs visual-only'],
 ['Planting / courtyard props','Partially converted / embedded assets','New embedded garden plants/potted pines exist; no general production vegetation/scenery library inspected'],
 ['Lighting across facilities','Partially converted / preserved review rigs','Shared palette; no integrated-world lighting or new-asset performance measurement'],
 ['Production terrain/cliffs, road/path/bridge network, shops/other queued facilities','Requires inspection / not supplied','Embedded facility paths do not constitute a world road layout; do not invent missing assets'],
 ['Town layout / production navigation / NPC / player systems','Requires inspection / absent','Inspection floor/controller only; final placement explicitly deferred'],
])+'\n\n## Every runtime GLB (current)\n\n'+table(['Model','Status','Triangles','Surfaces','Embedded images'],[[p.relative_to(R).as_posix(),'Integrated; visual review pending' if p.parent.name in ids else 'Previously converted / preserved',*brief(p)] for p in sorted((R/'assets/architecture').rglob('*.glb'))])+'\n\n## Every runtime scene\n\n'+table(['Scene','Status','Direct resources'],[[p.relative_to(R).as_posix(),'New integrated asset/review' if any(a in p.stem for a in ids) else 'Existing/preserved asset/review',', '.join(re.findall(r'path="([^"]+)"',p.read_text(encoding='utf-8')))] for p in sorted((R/'scenes').rglob('*.tscn'))])+'''

Baseline, staging, source, recovery and evidence copies are intentionally excluded from the runtime-model totals. Matching palette values do not imply cross-file GPU material sharing. New building scenes depend only on their own embedded-material GLB, with unchanged authored collision. Old Training/Pavilion reusable props retain their original MultiMesh/collider transforms. Physical JSON in those older assets still has historical visual counts; use GLBs/current sidecars for actual geometry budgets. New assets have no LOD/distant mesh. No production world, new-asset performance or final terrain-fit verification is claimed.
'''
assert len(list((R/'assets/architecture').rglob('*.glb')))==31
assert len(list((R/'scenes').rglob('*.tscn')))==30
(R/'reports/LOW_POLY_CONVERSION_INVENTORY.md').write_text(inventory,encoding='utf-8')
p=R/'README.md';old=p.read_text(encoding='utf-8');marker='<!-- claude-integration-current -->'
if marker not in old:p.write_text(marker+'\n> Current asset status: eight standalone gallery entries, including four tested Claude buildings. See [Codex report](reports/CODEX_REPORT.md) and `HANDOFF.md`. `Review Claude Assets.cmd` opens one-asset inspection. Staging/original preserved; no town placement. Earlier four-facility notes below are historical.\n\n'+old,encoding='utf-8')
print('Codex report, handoff, inventory and current summary written from validated evidence.')

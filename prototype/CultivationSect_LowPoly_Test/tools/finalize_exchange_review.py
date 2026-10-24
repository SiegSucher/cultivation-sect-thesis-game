"""Publish Exchange results from real execution evidence, without rebuilding."""
from pathlib import Path
import json
import runpy
import zipfile

R = Path(__file__).resolve().parents[1]
E = R/'reports/codex-exchange-hall'
def read(p): return json.loads(p.read_text(encoding='utf-8'))
files = {'Staged Exchange: fresh rerun of Claude verifier':'staged-basic/verify-results.json',
         'Canonical Exchange: rerun after documented collision correction':'integrated-basic/verify-results.json',
         'Independent first/third-person routes, collision and camera':'independent-routes.json',
         'Independent rendered routes and screenshots':'rendered-routes.json',
         'Ten-entry gallery and actual programmatic inputs':'gallery-input.json',
         'Read-only Exchange Blender source reopening':'native-source.json',
         'Existing batch 2: fresh basic checks on staged assets':'batch2-check/verify-results.json'}
tests = {k:read(E/v) for k,v in files.items()}
assert all(t['passed']>0 and t['failed']==0 for t in tests.values())
assert read(E/'mission-regression/verify-results.json')['failed']==0
assert read(E/'before-door-camera-fix.json')['failed']==1
assert all(g['pass'] for g in read(E/'staged-glb-audit.json')+read(E/'canonical-glb-audit.json'))
for f in ['independent-routes.json','rendered-routes.json']:
    t=read(E/f);assert not t['camera_hits'] and not t['visual_hits'] and t['sampled_volumes']==556
uid=read(E/'uid-investigation.json')
assert all(d['after_import_exists'] and d['script_sha256_unchanged'] and not d['serialized_source_references_to_uid'] for d in uid.values())
screens=sorted(p.relative_to(E).as_posix() for p in E.rglob('*.png'))
assert len(screens)==37,len(screens)
assert len(list((R/'assets').rglob('*.glb')))==33 and len(list((R/'scenes').rglob('*.tscn')))==34
audit=runpy.run_path(str(R/'tools/audit_exchange_state.py'))['audit']
audit()
with zipfile.ZipFile(E/'before-docs-catalog.zip') as z:
    previous=z.read('reports/CODEX_REPORT.md').decode('utf-8').replace('\r\n','\n')
    old_handoff=z.read('HANDOFF.md').decode('utf-8').replace('\r\n','\n')
    inventory=z.read('reports/LOW_POLY_CONVERSION_INVENTORY.md').decode('utf-8').replace('\r\n','\n')
table='\n'.join('| '+k+' | '+str(t['passed'])+' PASS / 0 FAIL | `codex-exchange-hall/'+files[k]+'` |' for k,t in tests.items())
report='''# Codex report — Contribution / Exchange Hall integration

22 October 2026. **Exchange Hall: created, imported, independently reviewed/tested, corrected for static-door camera coverage, and integrated as gallery entry ten.** This update concerns Exchange Hall; Mission Hall's payload remains unchanged. Alchemy Pavilion and Medicine Hall already exist in staging and were checked, not duplicated or integrated. No town layout was created.

## Permanent files

All paths are relative to `prototype/CultivationSect_LowPoly_Test/`:

- `assets/architecture/exchange_hall/exchange_hall.glb`
- `assets/architecture/exchange_hall/exchange_hall.glb.import` (new Godot metadata, own UID)
- `scenes/buildings/exchange_hall.tscn` (**use this scene**, which includes collision)
- `source/claude_exchange_hall_integrated.blend`
- `scripts/exchange_hall_review.gd` and generated `.gd.uid`
- `scenes/review/exchange_hall_walkthrough.tscn`
- `assets/gallery/catalog.json`: appends the Exchange entry with Walk and interior camera metadata; previous nine entries and gallery script unchanged.

Before copying, canonical destinations were checked and absent (`codex-exchange-hall/destination-check.json`). Frozen originals remain under `staging/claude_exchange_hall/` (13 files); the builder was not run. GLB and native source are byte-identical copies. Materials are embedded in the GLB; no separate textures/material files are needed. The scene uses only its permanent GLB, not staging or the original project. Runtime review uses the unchanged `scripts/training_inspection_player.gd`, one local-origin asset and a neutral test floor.

Gallery → **Contribution / Exchange Hall → Walk asset**, or open the canonical walkthrough scene directly. 1 walk/review; WASD/mouse move/look; Tab first/third person; Esc gallery. The copied review changes resource/output paths and attribution only.

## Independent evidence and correction

Read the current handoff/Claude report, actual scene, GLB, summary, builder and review/verifier code. Claude's original evidence is retained untouched in `reports/claude-exchange-hall/`. The table below records fresh Codex executions, not inherited test claims.

| Test | Fresh result | Evidence |
| --- | --- | --- |
__TABLE__
| Staged and canonical GLB audits | PASS: 31,346 triangles; zero near-zero-area triangles, invalid normals, non-flat triangles or nonfinite positions; correct palette | `codex-exchange-hall/staged-glb-audit.json`, `canonical-glb-audit.json` |
| Preservation/provenance | PASS: 1,599 original-project files and all 61 pre-existing staging files unchanged, including all 13 Exchange files | `codex-exchange-hall/preservation.json` |

Measured imported bounds: **26.60122 W × 16.37554 D × 12.96 H m**, minimum y=0, identity root, metre units, +Z entrance. 13 surfaces/palette materials, opaque and untextured; 31,346 triangles. Source reopening confirmed 13 editable mesh batches, flat polygons, metric units and matching triangle count without saving or re-exporting.

The original scene had 69 collision shapes. Its first independent expanded run gave **65 PASS / 1 FAIL**: a .16 m third-person camera safety probe overlapped visible open-leaf geometry at two samples near the east storeroom during a turn along the staff lane. Claude's .1 m camera probe and its routes had passed; this is a larger clearance margin and an additional route, not evidence that every original view visibly clipped. The visible leaves were omitted from authored collision, so the unchanged player's .2 m camera sweep could not react to them.

**Canonical correction:** retain every original collider and add four boxes matching the static storeroom leaves, including their cedar crossbar depth. Boxes are .78 × 2.54 × .10 m at x=±5.52, y=1.9, z=−3.15/−1.65. Total **73 collision shapes**. Geometry, materials, source, floor, proportions, door poses, original 69 shapes and controller are unchanged. The corrected scene differs from staging only in its permanent model path, one added shared shape resource/load count and these four collision nodes. Root-cause code/evidence: `tools/fix_exchange_leaf_collision.py`, `codex-exchange-hall/collision-correction.json`, `before-door-camera-fix.json` and `.log`. The canonical basic verifier explicitly expects these four documented additions; it otherwise reruns Claude's checks.

Final headless/rendered expanded suites pass with the same .16 m camera probe and .24 m radius upper-body capsule. Each samples **556 camera/body pairs**, with no hits against authored solids/visible-mesh copies on the recorded routes. Tests traverse front stair/terrace/door/aisle, both counter ends, reward-rack staff lane, both storeroom doors and interiors, both verandas and the return to ground in both camera modes. Counter, reward board and veranda walls block actual movement. The rendered suite includes eight screenshot assertions; these are not eight additional gameplay systems.

Measured final clearances: main door 3.20 m at wall / 3.04 m visible between leaves; door headroom 3.60 m; canopy visible headroom 3.42 m; counter-end lane 1.34 m collision / 1.37 m visible; storeroom wall opening 1.60 m; between static leaves **1.40 m collision / 1.44 m visible**; storeroom door headroom 2.60 m. These accommodate the unchanged 1.8 m, .56 m wide inspection player. No-hit ray limits are not exact opening measurements.

Gallery tests load all ten assets, check source availability and interior-camera clearance, and exercise 1, W, Tab, mouse motion and Esc through the canonical Walk scene. Other assets' full movement suites were not rerun. No new original-project dependency was introduced.

## Three Godot ID files and Mission integrity

The three files named in Claude's handoff are **script `.gd.uid` sidecars**, not duplicate Mission models or failed GLB imports. They record script IDs. All three were absent initially and were recreated during the one editor import scan, with explicit “Missing .uid file ... re-created from cache” warnings. Exact generated values, unchanged script hashes and reference searches are in `codex-exchange-hall/uid-investigation.json`:

| File | Reproduced ID | Final treatment |
| --- | --- | --- |
| `staging/claude_mission_hall/review/mission_hall_review.gd.uid` | `uid://bkmpjk4vpsfub` | Removed only this newly generated staging-side addition to restore the frozen delivery set |
| `tools/test_mission_gallery.gd.uid` | `uid://ddnfu3h52332u` | Retained as ordinary generated test-script metadata |
| `tools/verify_mission_integration.gd.uid` | `uid://b4sj3soie52qs` | Retained as ordinary generated test-script metadata |

The corresponding `.gd` bytes did not change, and no serialized scene/script/model-import reference to these three IDs was found outside their sidecars/cache. Canonical Mission model, import metadata, source, scene, review wrapper and review script match the start-of-task hashes. Its existing basic check rerun passed (raw result: `codex-exchange-hall/mission-regression/verify-results.json`). **No new Mission asset defect was found.** Its canonical review has its own normal metadata and does not use the staged review sidecar. Future editor scans may recreate the staging-only sidecar again; record generated metadata separately from asset payload changes instead of treating it as corruption. Retain normal canonical/tool sidecars. Do not repeatedly delete IDs blindly. Historical gallery tests hard-coded for eight/nine entries need updated expectations; the current ten-entry test is `tools/test_exchange_gallery.gd`.

Godot completed import/runtime checks but logs still contain the previously observed host certificate-store error and editor-settings save errors. The import additionally logged the three reproduced missing-sidecar warnings above. No asset missing-resource or parser error was found. Blender source inspection emitted a future-API `Material.use_nodes` deprecation notice. These host/API notices were not fixed by changing assets; logs are not claimed clean.

## Alchemy Pavilion and Medicine Hall — actual existing status

Both are **created, imported and staged; basic checks independently rerun, but not fully reviewed or integrated**. This task reran their existing 21-check suite and GLB audits successfully. It did not create/rebuild/copy either asset, run their generators, open their Blender source, conduct new rendered inspections, or execute expanded camera/visible-volume suites. Earlier Claude screenshots are historical evidence, not new Codex visual acceptance.

| Asset | Existing scene | Existing GLB | Shared editable source | Current result |
| --- | --- | --- | --- | --- |
| Alchemy Pavilion | `staging/claude_buildings_batch2/alchemy_pavilion/alchemy_pavilion.tscn` | `staging/claude_buildings_batch2/alchemy_pavilion/alchemy_pavilion.glb` (+ `.import`) | `staging/claude_buildings_batch2/source/claude_batch2.blend` | 25,586 triangles; loaded materials/collision; stair/furnace-room/blocking routes pass |
| Medicine Hall | `staging/claude_buildings_batch2/medicine_hall/medicine_hall.tscn` | `staging/claude_buildings_batch2/medicine_hall/medicine_hall.glb` (+ `.import`) | Same shared file | 20,636 triangles; loaded materials/collision; shop/stair/loft/balcony routes pass |

There is no canonical asset folder, canonical building scene or gallery entry for either. Remaining work: independent rendered/scale/collision/camera review, source reopening and later integration using these existing staged files. Do not create replacements or duplicates.

## Screenshots, preservation, limitations and next action

37 genuine Godot viewport images: 13 staged, 13 corrected canonical, eight moving-route views and three gallery/input views. Selected front/rear/side, interior, counter/abacus, reward racks, ceiling and both storeroom views were inspected. No blocking hole or missing material was observed in those views. Close-up coin relief retains visibly segmented/uneven beam joins; cosmetic user review remains, and z-fighting was not exhaustively isolated. No user acceptance is implied.

![Exchange Hall in the ten-entry gallery](codex-exchange-hall/gallery-exchange-exterior.png)

![Exchange Hall interior](codex-exchange-hall/gallery-exchange-interior.png)

![Third-person east storeroom traversal](codex-exchange-hall/tpp-east-storeroom.png)

Original `../asset-workshop`: all 1,599 files match both the start snapshot and recorded baseline. All 61 original staging files, Claude report/evidence, previous nine gallery entries, previous asset/controller/settings payloads and high-detail assets remain unchanged. Model/source are identical to staging; only Exchange scene collision is corrected. Pre-existing file changes are catalog, this report, handoff and inventory; new tool/script UID metadata is separately recorded. Recovery: `codex-exchange-hall/before-docs-catalog.zip`; hashes: `before-hashes.json`. Current runtime inventory: ten catalog assets, 33 GLBs and 34 scenes.

**Not tested:** human keyboard/mouse playtest, user visual acceptance; FPS/frame-time comparisons, low-end hardware, sustained load/stutter or exported game; terrain/navigation/NPC/production-controller integration; exhaustive collision/camera/roof walking or source-button OS launch. Rendered functional tests used Godot 4.7.2 Compatibility, RTX 3050 Laptop, 1280×720, fixed-fps 60, project MSAA 4× (gallery 2×); these are not performance measurements. The .6 m podium needs suitable terrain/front-stair approach; only the review floor was used. Doors/leaves remain static/open. Goods, abacus, rewards and signs are decorative; no exchange UI, token transactions, inventory or interaction logic was implemented. No LOD. Existing Training performance/collider issues are unchanged and out of scope.

**Ready for standalone review and later placement planning, not verified for final town placement.** Exact next action: gallery → Contribution / Exchange Hall → Walk asset; manually rehearse both counter ends, both storerooms, verandas and stair in both camera modes, review coin/detail appearance and record user acceptance. For a later authorized batch, continue from the existing Alchemy/Medicine delivery; do not duplicate it. Final world layout remains deferred.

Reproduction from the test project, using `../../tools/godot/Godot_v4.7.2-stable_win64_console.exe`:

```text
--headless --fixed-fps 60 --path . --script res://tools/verify_exchange_basics.gd
--headless --fixed-fps 60 --path . --script res://tools/verify_integrated_exchange_basics.gd
--headless --fixed-fps 60 --path . --script res://tools/verify_exchange_integration.gd
--fixed-fps 60 --path . --script res://tools/verify_exchange_integration.gd -- --rendered
--fixed-fps 60 --path . --script res://tools/test_exchange_gallery.gd
--headless --fixed-fps 60 --path . --script res://tools/check_existing_batch2.gd
--path . --resolution 1280x720 res://scenes/review/exchange_hall_walkthrough.tscn -- --capture
```

Audits: `staging/claude_exchange_hall/tools/audit_glb.py` with Codex output arguments; `blender.exe --background --factory-startup --python tools/inspect_exchange_source.py`; final provenance `tools/audit_exchange_state.py`. Collision correction: `tools/fix_exchange_leaf_collision.py` (canonical scene only). `tools/exchange_integration_state.py` is the initial freeze/base-copy helper; its old path-only `verify` mode does not account for the subsequent collision correction. Use `audit_exchange_state.py` for final checks. `tools/finalize_exchange_review.py` validates executed evidence and updates docs; it does not run engine tests. Earlier finalizers must not overwrite the current catalog/report.

---

## Historical Mission/four-asset reports (prior runs; current Exchange result is above)

'''.replace('__TABLE__',table)
(R/'reports/CODEX_REPORT.md').write_text(report+previous,encoding='utf-8')
handoff='''# Current handoff — Contribution / Exchange Hall integrated

22 October 2026. Latest task: review/test/integrate Claude's Exchange Hall, investigate Mission script-ID metadata, and determine the status of existing Alchemy/Medicine staging. **Exchange Hall is now independently tested, corrected and integrated as gallery entry ten.** No layout/terrain placement; no duplicate assets or generators run.

## Exact Exchange files and status

- `assets/architecture/exchange_hall/exchange_hall.glb` and generated `.glb.import`
- `scenes/buildings/exchange_hall.tscn` (instance this scene, not the bare GLB)
- `source/claude_exchange_hall_integrated.blend`
- `scripts/exchange_hall_review.gd` (+ generated `.gd.uid`)
- `scenes/review/exchange_hall_walkthrough.tscn`
- `assets/gallery/catalog.json`: tenth entry; Walk and interior preset; previous nine entries/gallery code unchanged.

31,346 triangles, 13 opaque embedded palette materials, no textures, 26.60122 W × 16.37554 D × 12.96 H m, floor .60 m, identity root, +Z front. Model/source identical to frozen `staging/claude_exchange_hall/` (13 files). **Canonical scene has 73 colliders: all 69 originals + four static storeroom-leaf boxes.** A larger camera probe found two leaf contacts missed by the original .1 m camera test. Matching .78×2.54×.10 m boxes fix camera sweep coverage without changing visible design, source, controller, floor or original shapes. Do not overwrite this corrected scene with a raw staged copy. Reproducible patch: `tools/fix_exchange_leaf_collision.py`; provenance: `tools/audit_exchange_state.py`. The initial base-copy helper's path-only verification is obsolete after the correction.

Fresh Codex tests: staged basic 43/0; corrected canonical basic 43/0; expanded FPP/TPP headless 70/0; rendered 78/0; gallery/input 27/0; read-only source reopening 5/0; staged/canonical GLB audits PASS. Each expanded run samples 556 camera/body pairs, no final contacts. Before-fix result 65/1 retained. 37 genuine screenshots and raw results/logs: `reports/codex-exchange-hall/`. Full review: `reports/CODEX_REPORT.md`. Checks are automation, not human playtesting or benchmarks.

## Mission ID investigation and protected work

No new Mission payload issue: model/import/source/building/review/script hashes unchanged; basic regression passed. Editor import recreated the three missing script `.uid` sidecars described by Claude; warnings explicitly say restored from cache. These are normal ID metadata, not duplicate assets. `uid-investigation.json` records exact IDs and script hashes. Retained `tools/test_mission_gallery.gd.uid` and `tools/verify_mission_integration.gd.uid`; restored the frozen staging set by removing only the newly generated `staging/claude_mission_hall/review/mission_hall_review.gd.uid`. That staging-only sidecar may recur on future editor scans; record it separately. Canonical/tool sidecars should normally remain. Do not blindly remove IDs. Old eight/nine-entry gallery test assertions are historical; current ten-entry suite is `tools/test_exchange_gallery.gd`.

Original project: all 1,599 files match baseline and start snapshot. All 61 pre-existing staging files, Claude report/evidence, previous facilities, high-detail sources, controllers/settings/default scene preserved. Current runtime: ten gallery assets, 33 GLBs, 34 scenes. Existing Training timing regression / 84 roof-collider degenerates remain unchanged. Backup catalog/docs: `reports/codex-exchange-hall/before-docs-catalog.zip`.

## Existing Alchemy Pavilion / Medicine Hall

**Already created/imported/staged, partially independently checked; not integrated, not fully verified.** Fresh rerun of their existing basic Godot suite: 21/0; both GLB audits PASS. No new rendered/camera/source-opening/performance review for this batch. No duplicates created. Continue from:

- `staging/claude_buildings_batch2/alchemy_pavilion/alchemy_pavilion.tscn` and `.glb` (+ `.glb.import`)
- `staging/claude_buildings_batch2/medicine_hall/medicine_hall.tscn` and `.glb` (+ `.glb.import`)
- Shared source: `staging/claude_buildings_batch2/source/claude_batch2.blend`
- Existing builder/review/check: `staging/claude_buildings_batch2/tools/build_claude_batch2.py`, `review/claude_batch2_review.tscn`, `review/verify_claude_batch2.gd`.

Neither has a permanent asset folder, building scene or gallery entry. Native source reopening and broader independent rendered/collision/camera checks remain before future integration. Do not regenerate or duplicate assets just because they are absent from the gallery.

## Remaining limits and exact next action for Claude

Open gallery → **Contribution / Exchange Hall → Walk asset** (or its canonical walkthrough). 1 walk/review; WASD/mouse; Tab FPP/TPP; Esc gallery. Manually rehearse stair, counter ends, both storerooms and verandas; review detail/coin appearance and record user acceptance. Then, only under the next authorized integration scope, review the existing Alchemy/Medicine staging. Keep final town layout deferred.

Not performed: human playtest/acceptance, FPS/frame-time/low-end hardware/sustained-load/export tests, production character/terrain/navigation/NPC fit, exhaustive collisions/camera angles or OS source-button launch. No LOD or exchange/inventory/transaction gameplay. Static/open leaves now have canonical collision in the storerooms; other small details remain decorative. Podium/front stair needs later terrain fit. Close-up coin beam joins remain segmented/uneven; cosmetic review and exhaustive z-fighting investigation remain. Host certificate-store and editor-settings save errors persist; import's three missing-sidecar warnings are explained above. Blender emitted an API-deprecation notice. No final placement readiness claim.

Current final evidence checker: `tools/audit_exchange_state.py`; current report publisher: `tools/finalize_exchange_review.py` (does not run tests). Do not run earlier finalizers over current docs. Mission's earlier tests/limits remain historical in CODEX_REPORT, not the focus of this task.

'''
references=old_handoff[old_handoff.index('## Original visual references'):]
(R/'HANDOFF.md').write_text(handoff+references,encoding='utf-8')
inventory=inventory.replace('nine standalone facilities','ten standalone facilities')
inventory=inventory.replace('Mission Hall is now independently tested and integrated alongside the previous eight facilities. Current runtime: nine catalog entries, 32 GLBs and 32 scenes. Alchemy/Medicine remain staged (Claude tests only); Contribution / Exchange Hall is not started.',
 'Exchange Hall is now independently tested/corrected/integrated alongside the previous nine facilities. Current runtime: ten catalog entries, 33 GLBs and 34 scenes. Alchemy/Medicine already exist in staging; basic checks/audits were independently rerun, but broader review and integration remain.')
inventory=inventory.replace('| Alchemy Pavilion / Medicine Hall | Staged only; independently unverified | Claude batch 2 retained untouched; outside this task |',
 '| Alchemy Pavilion / Medicine Hall | Staged only; basic independent checks passed, broader review pending | Existing scenes/models/source retained; Godot 21/0 and GLB audits pass; no canonical copies/gallery entries |')
inventory=inventory.replace('| Contribution / Exchange Hall | Not started | No asset created in this task |',
 '| Contribution / Exchange Hall | Already created/imported; independently reviewed/tested; integrated | 31,346 triangles, 13 materials, 73 colliders (69 original + 4 static-leaf coverage boxes); Walk and interior gallery preset; no performance/terrain acceptance |')
inventory=inventory.replace('| assets/architecture/elder_residence/',
 '| assets/architecture/exchange_hall/exchange_hall.glb | Independently tested / integrated; human review pending | 31346 | 13 | 0 |\n| assets/architecture/elder_residence/')
inventory=inventory.replace('| scenes/buildings/elder_residence.tscn',
 '| scenes/buildings/exchange_hall.tscn | Independently tested / integrated; static-leaf collision corrected | res://assets/architecture/exchange_hall/exchange_hall.glb |\n| scenes/buildings/elder_residence.tscn')
inventory=inventory.replace('| scenes/review/gate_walkthrough.tscn',
 '| scenes/review/exchange_hall_walkthrough.tscn | Independently tested / integrated | res://scripts/exchange_hall_review.gd |\n| scenes/review/gate_walkthrough.tscn')
(R/'reports/LOW_POLY_CONVERSION_INVENTORY.md').write_text(inventory,encoding='utf-8')
proof=audit()
(E/'final-summary.json').write_text(json.dumps({'asset':'exchange_hall','created':True,'imported':True,
    'independently_reviewed':True,'integrated':True,'catalog_entries':10,'collision_shapes':73,
    'tests':{k:{'passed':t['passed'],'failed':t['failed']} for k,t in tests.items()},'preservation':proof,
    'uid_investigation':uid,'screenshots':screens,'human_playtested':False,'performance_tested':False,
    'town_placement_verified':False,'remaining_assets':'Existing Alchemy/Medicine staging; basic checks only, no duplicates or integration',
    'next_action':'Manual Exchange review/acceptance; then authorized broader review of existing batch 2; no final layout'},indent=2),encoding='utf-8')
print('Published Exchange report/handoff/inventory; ten assets; 37 screenshots; batch 2 remains staged.')

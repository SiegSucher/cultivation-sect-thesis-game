"""Publish Alchemy/Medicine review only from completed engine/source evidence."""
from pathlib import Path
import json,re,runpy,zipfile

R=Path(__file__).resolve().parents[1]
E=R/'reports/codex-alchemy-medicine'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
tests={name:read(E/path) for name,path in {
    'staged_basics':'staged-basic/verify-results.json','canonical_basics':'canonical-basic/verify-results.json',
    'headless':'headless-results.json','rendered':'rendered-results.json','gallery_input':'gallery-input.json','native_source':'native-source.json'}.items()}
assert all(t['passed']>0 and t['failed']==0 for t in tests.values())
assert tests['staged_basics']['passed']==21 and tests['canonical_basics']['passed']==21
assert tests['headless']['passed']==124 and tests['rendered']['passed']==136
assert tests['gallery_input']['passed']==53 and tests['native_source']['passed']==11
assert not tests['headless']['contacts'] and not tests['rendered']['contacts']
assert all(g['pass'] for g in read(E/'staged-glb-audit.json')+read(E/'canonical-glb-audit.json'))
assert read(E/'before-medicine-collision-fix.json')['failed']==1
assert read(E/'before-alchemy-leaf-fix.json')['failed']==1
screens=sorted(p.relative_to(E).as_posix() for p in E.rglob('*.png'))
assert len(screens)==50,len(screens)
assert len(list((R/'assets').rglob('*.glb')))==35 and len(list((R/'scenes').rglob('*.tscn')))==38
diagnostics={}
for name in ['import','staged-basic','canonical-basic','headless','rendered','gallery-input','integrated-captures','staged-captures','build-camera-shape']:
    lines=[line for line in (E/(name+'.log')).read_text(encoding='utf-8',errors='replace').splitlines() if re.search(r'\b(?:ERROR|WARNING|SCRIPT ERROR):',line)]
    assert all('root certificate store' in s or 'editor_settings-4.7.tres' in s or 'Missing .uid file' in s for s in lines),(name,lines)
    diagnostics[name]=lines
audit=runpy.run_path(str(R/'tools/audit_batch2_state.py'))['audit']
proof=audit()
with zipfile.ZipFile(E/'before-docs-catalog.zip') as z:
    previous=z.read('reports/CODEX_REPORT.md').decode('utf-8').replace('\r\n','\n')
    old_handoff=z.read('HANDOFF.md').decode('utf-8').replace('\r\n','\n')
    inventory=z.read('reports/LOW_POLY_CONVERSION_INVENTORY.md').decode('utf-8').replace('\r\n','\n')
(E/'previous-CODEX_REPORT.md').write_text(previous,encoding='utf-8')
(E/'previous-HANDOFF.md').write_text(old_handoff,encoding='utf-8')
report='''# Codex report — Alchemy Pavilion and Medicine Hall integration

23 October 2026, following the 22 October staged delivery. **Both existing assets are independently reviewed/tested, corrected and integrated as gallery entries eleven and twelve.** Models, materials and shared editable source remain identical to Claude's delivery. Only these candidate scenes and their new review fixture were corrected. No duplicate assets, town placement or production-project edits were made. Mission/Exchange work was preserved and not repeated.

Read the current CODEX report, handoff, Claude report, actual staging scenes/models/summary, builder, review/verifier and established gallery/player code. The earlier **21/21 is a combined suite**, comprising ten Alchemy and eleven Medicine assertions; it was not 21 checks per asset. Claude's report and original evidence remain untouched. Prior Mission/Exchange reports are archived at [previous-CODEX_REPORT.md](codex-alchemy-medicine/previous-CODEX_REPORT.md); their historical limits still apply.

## Permanent assets and measured scale

Paths below are relative to `prototype/CultivationSect_LowPoly_Test/`. Destinations were absent before copying (`codex-alchemy-medicine/destination-check.json`). Each GLB has freshly generated `.glb.import` metadata with a distinct UID from staging. Palette materials are embedded; no textures or separate material resources are required.

| Asset | Model | Building scene | Walkthrough |
| --- | --- | --- | --- |
| Alchemy Pavilion | `assets/architecture/alchemy_pavilion/alchemy_pavilion.glb` | `scenes/buildings/alchemy_pavilion.tscn` | `scenes/review/alchemy_pavilion_walkthrough.tscn` |
| Medicine Hall | `assets/architecture/medicine_hall/medicine_hall.glb` | `scenes/buildings/medicine_hall.tscn` | `scenes/review/medicine_hall_walkthrough.tscn` |

Shared Blender source: **`source/claude_batch2_integrated.blend`**, copied byte-for-byte from `staging/claude_buildings_batch2/source/claude_batch2.blend`. Two editable collections, `AlchemyPavilion` and `MedicineHall`, remain at the authoring origin; isolate the desired collection for editing. Shared standalone review: **`scripts/alchemy_medicine_review.gd`** (+ generated `.gd.uid`). Medicine additionally depends on **`assets/architecture/medicine_hall/medicine_camera_obstructions.tres`**, the collision-only resource described below. These resources have no runtime staging or original-project dependency.

Only existing runtime catalog `assets/gallery/catalog.json` changes: appends both entries with their correct Walk routes and interior presets, preserving the first ten entries and the unchanged gallery script. Select either new entry → **Walk asset**. Controls: 1 review/walk, WASD/mouse, Tab first/third person, 2 Alchemy, 3 Medicine, Esc gallery. Each asset is displayed individually at local identity on a neutral review plane; these are not world positions.

| Imported measurement | Alchemy Pavilion | Medicine Hall |
| --- | --- | --- |
| Width × depth × height | 17.0983 × 17.98391 × 12.57 m | 17.8 × 14.55696 × 11.00315 m |
| Floor elevations | .90 m | .45 m shop, 4.20 m loft/balcony |
| Mesh triangles / surfaces | 25,586 / 13 | 20,636 / 15 |
| Final collision shape count | 45 (43 originals + two leaf boxes) | 54 (53 authored, four counter boxes corrected, + one camera-only shape) |
| Main visible entrance width/headroom | 2.20 / 3.00 m at wall | 2.80 / 3.09 m at shop opening |
| Other measured clearance | Porch plaque headroom 2.67 m | Loft balcony door 1.60 m at wall, 2.40 m headroom |

Both origins sit at y=0, roots are identity, units are metres and entrances face +Z. Alchemy's new leaf boxes leave 2.0 m clear. Door/window props and thresholds were not scaled. All 13/15 palette materials are present, opaque and texture-free; exported geometry has finite positions, unit flat normals, correct palette/roughness, no external URIs and no near-zero-area triangles. Bronze roughness .56, Water .5, other palette surfaces .82.

## Tests actually executed

| Test | Actual result | Evidence under `reports/codex-alchemy-medicine/` |
| --- | --- | --- |
| Fresh combined Claude checks against staging | 21 PASS / 0 FAIL | `staged-basic/verify-results.json`, `staged-basic.log` |
| Combined checks against corrected canonical scenes | 21 PASS / 0 FAIL | `canonical-basic/verify-results.json`, `canonical-basic.log` |
| Expanded headless FPP/TPP | 124 PASS / 0 FAIL: Alchemy 61, Medicine 63 | `headless-results.json`, `headless.log` |
| Expanded rendered FPP/TPP | 136 PASS / 0 FAIL: Alchemy 66, Medicine 70 | `rendered-results.json`, `rendered.log` |
| Gallery / actual programmatic key and mouse events | 53 PASS / 0 FAIL | `gallery-input.json`, `gallery-input.log` |
| Read-only reopening of copied Blender source | 11 PASS / 0 FAIL (five per collection + shared metre convention) | `native-source.json` |
| Staged and copied GLB geometry/material audits | Both PASS | `staged-glb-audit.json`, `canonical-glb-audit.json` |
| Import/render compatibility | Both canonical models imported and rendered in Godot 4.7.2 | `import.log`, capture/runtime logs; host diagnostics below |
| Preservation/provenance | PASS: original project, staging, earlier ten assets/player/settings unchanged | `preservation.json`, `before-hashes.json` |

The unchanged 1.8 m tall, .28 m radius inspection controller traversed Alchemy's front stair/porch/door, front/east/rear/west furnace-room aisles and full outer colonnade circuit, with furnace/front-wall blocking. Medicine traversed front stair/central shop, west stair approach, interior stair up and down, loft landing/aisles, balcony door/three balcony positions, return to ground, counter and balcony-rail blocking. Each route set was exercised in both camera modes. The rendered suite includes twelve image-write assertions; counts are not numbers of distinct gameplay systems.

Each final expanded run sampled **416 Alchemy and 398 Medicine camera/body pairs** against authored solids and visible-mesh copies. Final sampled .16 m camera spheres and .24 m radius upper-body capsules have no intersections. Gallery tests loaded all twelve entries, checked both source paths/interior cameras/Walk wrappers, and exercised 1, W, Tab, mouse look, 2/3 review switching, velocity reset, live collision-exception lifecycle and Esc. Old Mission/Exchange movement suites were not rerun; no regression was found by gallery loads or preservation hashes.

## Failures found and corrections

1. **Medicine collision coverage:** initial expanded headless run was **123 PASS / 1 FAIL** (one aggregate clearance assertion, with counter body contacts and camera contacts on stair detail/hanging herbs). The serving counter collision was shallower than its overhanging timber top. Four existing boxes now match the top's width/depth and elevation, without changing visible geometry. Code/data: `tools/fix_medicine_collision.py`, `collision-corrections.json`, `before-medicine-collision-fix.*`.
2. **Medicine camera detail versus walking ramp:** adding hard-step collision to the walking body would interfere with the working ramp. A separate static body instead carries **one concave shape with 698 actual model triangles**: 538 stair-detail triangles and 160 hanging-herb triangles. This protects camera sweeps while preserving smooth walking. Build tool: `tools/build_medicine_camera_shape.gd`; output `medicine_camera_obstructions.tres`; evidence `camera-shape.json`. No rendered mesh was added or changed.
3. **Alchemy static door leaves:** the first rendered run after the Medicine correction was **135 PASS / 1 FAIL**, detecting an additional third-person camera safety-sphere contact with an uncollidable open leaf. Two boxes now match the static leaves and their crossbars. Source/model/poses are unchanged; all 43 original shapes retained. Code/evidence: `tools/fix_alchemy_leaf_collision.py`, `alchemy-leaf-correction.json`, `before-alchemy-leaf-fix.*`. The same camera probe passes the final reruns; its tolerance was not relaxed.
4. **New review-fixture lifecycle:** initial gallery assertions returned 51/0 but the log exposed `Parameter "body" is null` while inspecting exceptions after an asset switch. This was not accepted as clean success. The new fixture now removes exceptions before freeing old camera bodies, and the stronger test asserts zero stale exceptions for Alchemy and exactly one live exception for Medicine. Final **53/0**, with no body-null diagnostic. Retained evidence: `before-review-lifecycle-fix.*`.

### Medicine camera integration contract

`CameraDetailObstruction` is a layer-1 body in group **`camera_only_obstruction`**, with collision mask 0. The supplied review explicitly makes the character body ignore it using `add_collision_exception_with()`, while the unchanged camera's separate space query can still see it. It removes the exception before switching/freeing the asset. **A future production player must implement that body-exception setup or an equivalent separate camera collision layer.** Simply instancing this scene with a different character is not verified production integration. Keep the camera resource and fixture setup together; do not replace the corrected scene with its raw staged copy. Shared player/camera source was not edited or replaced.

## Screenshots, preserved work and limits

**50 genuine Godot viewport captures**: sixteen staged, sixteen canonical review, twelve moving-route and six gallery/input views. Exterior, furnace, shop, stair/loft/balcony, first/third-person and gallery views were inspected. No blocking missing material or visible hole was observed in those inspected views. User visual acceptance and exhaustive seam/z-fighting checks remain unperformed.

![Alchemy Pavilion in the gallery](codex-alchemy-medicine/alchemy_pavilion-gallery-exterior.png)

![Medicine Hall in the gallery](codex-alchemy-medicine/medicine_hall-gallery-exterior.png)

![Medicine Hall shop interior](codex-alchemy-medicine/medicine_hall-gallery-interior.png)

All **1,599 original-project files** match the current-task snapshot and recorded original manifest. All **61 existing staging files** (including the fifteen batch-2 files), Claude report/evidence and previous assets/high-detail sources/controllers/settings are unchanged. Original staged file set is restored: the known editor-regenerated Mission review `.gd.uid`, absent from the frozen delivery, was recorded and removed; no original sidecar was deleted. Normal canonical/tool metadata remains. Only pre-existing catalog, current report, handoff and inventory change. The two GLBs and shared source are byte-identical to staging. Current runtime: **12 explicit assets, 35 GLBs, 38 scenes**. Recovery of prior docs/catalog: `before-docs-catalog.zip`; readable prior reports/handoff also archived here.

Godot logs are **not clean**: the known host root-certificate-store error remains; editor import also could not save the user's editor settings and restored the known missing staged-script UID. Final runtime logs have no new asset, parser, missing-resource or body-null error. These host errors were not fixed through asset changes. Final diagnostic lines are recorded in `final-summary.json`.

**Not performed:** human keyboard/mouse playtesting or user acceptance; FPS/frame-time/performance comparisons, low-end hardware, thermals/stutter, exported game; terrain placement, navigation/NPC or production-player integration; exhaustive collision/camera/roof walking, OS source-button launch. Rendered functional runs used Compatibility/OpenGL, RTX 3050 Laptop, 1280×720, fixed-fps 60, project MSAA 4× (gallery 2×); they are not performance benchmarks. No terrain/world arrangement was authored. Basins and yard racks need later supporting ground. Medicine's stair remains about 39° with this controller's 50° limit. Hanging herbs descend to about 1.97 m above the loft floor, so do not claim all loft headroom exceeds 2.1 m. Decorative floor finishes sit slightly above collision floors; exhaustive foot alignment is not certified. Doors remain static/open, small detail collision is not exhaustive, no LOD or crafting/medicine/shop gameplay was added. Existing Training timing regression/84 roof-collider degenerates and Exchange cosmetic review remain unchanged/out of scope.

**Ready for standalone gallery review; not certified ready for final town placement.** Exact next action: gallery → Alchemy Pavilion / Medicine Hall → Walk asset; manually review front doors, furnace/colonnade routes, shop, stair/loft/balcony in both modes and record user acceptance. Preserve the Medicine camera contract for future integration. Do not start another asset or final layout automatically.

Reproduction from this test project with `../../tools/godot/Godot_v4.7.2-stable_win64_console.exe`:

```text
--headless --fixed-fps 60 --path . --script res://tools/verify_batch2_staged_basics.gd
--headless --fixed-fps 60 --path . --script res://tools/verify_batch2_canonical_basics.gd
--headless --fixed-fps 60 --path . --script res://tools/verify_batch2_integration.gd
--fixed-fps 60 --path . --script res://tools/verify_batch2_integration.gd -- --rendered
--fixed-fps 60 --path . --script res://tools/test_batch2_gallery.gd
--path . --resolution 1280x720 res://scenes/review/alchemy_pavilion_walkthrough.tscn -- --capture
```

Source: `blender.exe --background --factory-startup --python tools/inspect_batch2_source.py`. GLB audit: existing frozen `staging/claude_exchange_hall/tools/audit_glb.py`, with this evidence folder as output. Final preservation: `tools/audit_batch2_state.py`; docs publisher: `tools/finalize_batch2_review.py` (validates evidence, does not execute engine tests). Initial freeze/candidate-copy/gallery registration: `tools/batch2_integration_state.py`. Never rerun staging generators or earlier finalizers over this verified state.
'''
(R/'reports/CODEX_REPORT.md').write_text(report,encoding='utf-8')
handoff='''# Current handoff — Alchemy Pavilion and Medicine Hall integrated

23 October 2026. **Both existing batch-2 assets are independently reviewed/tested, corrected and integrated as gallery entries eleven/twelve.** There are now twelve explicit standalone gallery assets, 35 runtime GLBs and 38 scenes. No duplicate modeling, original-project changes or town-layout placement. Previous ten assets, including Mission and Exchange, remain unchanged.

## Permanent files and current results

| Asset | Model | Building scene | Walkthrough |
| --- | --- | --- | --- |
| Alchemy Pavilion | `assets/architecture/alchemy_pavilion/alchemy_pavilion.glb` (+ `.import`) | `scenes/buildings/alchemy_pavilion.tscn` | `scenes/review/alchemy_pavilion_walkthrough.tscn` |
| Medicine Hall | `assets/architecture/medicine_hall/medicine_hall.glb` (+ `.import`) | `scenes/buildings/medicine_hall.tscn` | `scenes/review/medicine_hall_walkthrough.tscn` |

Shared editable source: `source/claude_batch2_integrated.blend` (byte-identical to the existing staged source; two collections at the authoring origin). Shared review: `scripts/alchemy_medicine_review.gd` (+ `.gd.uid`). Medicine's required extra resource: `assets/architecture/medicine_hall/medicine_camera_obstructions.tres`. Gallery catalog appends both entries; earlier ten entries and gallery script unchanged.

Alchemy: 25,586 triangles, 13 materials, 17.0983 W × 17.98391 D × 12.57 H m, floor .90 m, **45 colliders**. Medicine: 20,636 triangles, 15 materials, 17.8 W × 14.55696 D × 11.00315 H m, floors .45/4.20 m, **54 colliders**. Roots identity, metres, +Z entrance; geometry/materials/source unchanged from staging.

Fresh basic tests are **21 combined**, not 21 each: ten Alchemy + eleven Medicine, on staging and corrected canonical scenes. Expanded headless: Alchemy61/0 + Medicine63/0 =124/0. Rendered:66/0 +70/0 =136/0. Gallery/input53/0; read-only shared source11/0; GLB audits both PASS. Each expanded run sampled416/398 camera/body pairs; no final contacts. **50 genuine screenshots** plus JSON/logs: `reports/codex-alchemy-medicine/`. Full current report: `reports/CODEX_REPORT.md`; prior Exchange/Mission report archived as `reports/codex-alchemy-medicine/previous-CODEX_REPORT.md`.

## Fixes and required Medicine camera setup

Initial headless123/1 found Medicine counter overhang/body contacts and stair/herb camera contacts. Four existing counter boxes now match the timber tops. One separate camera-only concave shape copies698 real model triangles (538 stair detail,160 herbs), preserving the smooth walking ramp. First rendered135/1 then caught an Alchemy open-leaf camera contact; two matching static-leaf boxes fix it, retaining the43 original colliders. Initial gallery51/0 still logged a freed-body error; exception removal before freeing old assets fixes this, with final stronger53/0. All failing evidence retained; no probe tolerance relaxation or visible redesign.

**Important integration contract:** Medicine's `CameraDetailObstruction` belongs to group `camera_only_obstruction`, collision layer1/mask0. The review uses `player.add_collision_exception_with(body)` so the walker ignores these detail triangles while the unchanged camera's independent query sees them. It removes old exceptions before switching assets. A future production controller must reproduce that setup or provide separate camera collision layers. Bare scene placement with another character is not verified. Keep the `.tres` resource and fixture logic; do not overwrite corrected scenes from raw staging. Shared inspection-controller source is unchanged.

Reproducible correction tools: `tools/build_medicine_camera_shape.gd`, `tools/fix_medicine_collision.py`, `tools/fix_alchemy_leaf_collision.py`. These operate only on canonical copies; do not run frozen staging builders. Final evidence checker: `tools/audit_batch2_state.py`. Current publisher: `tools/finalize_batch2_review.py` (does not run tests). Earlier finalizers/catalog-count fixtures are historical and must not overwrite current reporting.

## Protected work and limits

Original project: all1599 files match baseline and task-start snapshot. All61 staged files, including15 batch-2 files, Claude report/evidence, earlier assets/high-detail sources/player/cameras/gallery/settings remain unchanged. Known editor-regenerated staged Mission `.gd.uid` was recorded/removed only because it was absent from the frozen set; normal canonical/tool sidecars retained. Recovery: `reports/codex-alchemy-medicine/before-docs-catalog.zip`; previous handoff archived alongside it.

Host certificate-store/editor-settings errors and known missing-UID import warning remain documented. No final asset/parser/missing-resource/freed-body diagnostic. No human playtesting/acceptance, performance/FPS/low-end/export/sustained-load, terrain placement/navigation/NPC/production-player verification, exhaustive collisions/camera/foot seams or OS source-button launch. No LOD or crafting/shop gameplay. Basins/yard racks need supporting ground; Medicine stair remains steep and hanging herbs leave about1.97m loft clearance. Current status is standalone gallery review readiness, not final placement certification. Training timing regression/84 roof-collider degenerates and Exchange close-up cosmetic review remain separate issues.

## Exact next action for Claude

Open gallery → **Alchemy Pavilion** or **Medicine Hall** → **Walk asset** (or the canonical walkthrough above). 1 walk/review; WASD/mouse; Tab FPP/TPP; 2 Alchemy/3 Medicine; Esc gallery. Manually rehearse furnace/colonnade, counter fronts, interior stair both ways, loft/balcony, review images and record user acceptance. Preserve the Medicine camera setup when any future production-player integration is authorized. **Do not begin final town layout or another asset automatically.**

'''
refs=old_handoff[old_handoff.index('## Original visual references'):]
for old,new in {
 'Alchemy61/0':'Alchemy 61/0','Medicine63/0':'Medicine 63/0','=124/0':'= 124/0',
 'Rendered:66/0 +70/0 =136/0':'Rendered: 66/0 + 70/0 = 136/0',
 'Gallery/input53/0':'Gallery/input 53/0','source11/0':'source 11/0',
 'sampled416/398':'sampled 416/398','headless123/1':'headless 123/1',
 'copies698':'copies 698','detail,160':'detail, 160','rendered135/1':'rendered 135/1',
 'the43':'the 43','gallery51/0':'gallery 51/0','stronger53/0':'stronger 53/0',
 'layer1/mask0':'layer 1/mask 0','all1599':'all 1,599','All61':'All 61',
 'including15':'including 15','about1.97m':'about 1.97 m'
}.items(): handoff=handoff.replace(old,new)
(R/'HANDOFF.md').write_text(handoff+refs,encoding='utf-8')
inventory=inventory.replace('ten standalone facilities','twelve standalone facilities')
inventory=inventory.replace('22 October 2026.','23 October 2026.',1)
old='Exchange Hall is now independently tested/corrected/integrated alongside the previous nine facilities. Current runtime: ten catalog entries, 33 GLBs and 34 scenes. Alchemy/Medicine already exist in staging; basic checks/audits were independently rerun, but broader review and integration remain.'
new='Alchemy Pavilion and Medicine Hall are now independently reviewed/tested/corrected/integrated alongside the earlier ten facilities. Current runtime: twelve catalog entries, 35 GLBs and 38 scenes. Their staged models/shared source remain frozen; final human/production-world acceptance is pending.'
assert old in inventory
inventory=inventory.replace(old,new)
inventory=inventory.replace('| Alchemy Pavilion / Medicine Hall | Staged only; basic independent checks passed, broader review pending | Existing scenes/models/source retained; Godot 21/0 and GLB audits pass; no canonical copies/gallery entries |',
 '| Alchemy Pavilion | Independently reviewed/tested / integrated; human review pending | 25,586 triangles, 13 materials, 45 colliders; leaf camera coverage fixed; Walk available |\n| Medicine Hall | Independently reviewed/tested / integrated; human review pending | 20,636 triangles, 15 materials, 54 colliders; counter/camera detail coverage fixed; production character must honor camera-only body exception |')
inventory=inventory.replace('| assets/architecture/dining_hall_kitchen/',
 '| assets/architecture/alchemy_pavilion/alchemy_pavilion.glb | Independently tested / integrated; human review pending | 25586 | 13 | 0 |\n| assets/architecture/medicine_hall/medicine_hall.glb | Independently tested / integrated; human review pending | 20636 | 15 | 0 |\n| assets/architecture/dining_hall_kitchen/')
inventory=inventory.replace('| scenes/buildings/dining_hall_kitchen.tscn',
 '| scenes/buildings/alchemy_pavilion.tscn | Independently tested / integrated; leaf collision corrected | res://assets/architecture/alchemy_pavilion/alchemy_pavilion.glb |\n| scenes/buildings/medicine_hall.tscn | Independently tested / integrated; counter/camera collision corrected | res://assets/architecture/medicine_hall/medicine_hall.glb; res://assets/architecture/medicine_hall/medicine_camera_obstructions.tres |\n| scenes/buildings/dining_hall_kitchen.tscn')
inventory=inventory.replace('| scenes/review/gate_walkthrough.tscn',
 '| scenes/review/alchemy_pavilion_walkthrough.tscn | Independently tested / integrated | res://scripts/alchemy_medicine_review.gd |\n| scenes/review/medicine_hall_walkthrough.tscn | Independently tested / integrated | res://scripts/alchemy_medicine_review.gd |\n| scenes/review/gate_walkthrough.tscn')
inventory+='\nLatest integration: Alchemy/Medicine details, source/collision contract, executed tests, 50 screenshots and limitations are in `CODEX_REPORT.md`. No world placement or performance measurement is implied.\n'
(R/'reports/LOW_POLY_CONVERSION_INVENTORY.md').write_text(inventory,encoding='utf-8')
proof=audit()
(E/'final-summary.json').write_text(json.dumps({'assets':['alchemy_pavilion','medicine_hall'],'created':True,'imported':True,
 'independently_reviewed':True,'integrated':True,'gallery_entries':[11,12],'tests':{k:{'passed':t['passed'],'failed':t['failed'],'per_asset':t.get('per_asset')} for k,t in tests.items()},
 'preservation':proof,'diagnostics':diagnostics,'screenshots':screens,'camera_contract':'Production character must ignore camera_only_obstruction bodies while camera queries detect them; supplied review tested',
 'human_playtesting':False,'performance_testing':False,'terrain_placement':False,'navigation':False,'production_player_verified':False,
 'next_action':'Manual Alchemy/Medicine review and user acceptance; preserve camera contract; no layout or new asset automatically'},indent=2),encoding='utf-8')
print('Published final Alchemy/Medicine report and handoff; twelve entries, 50 screenshots.')

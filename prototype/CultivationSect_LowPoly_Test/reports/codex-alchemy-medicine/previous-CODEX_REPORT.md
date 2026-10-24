# Codex report — Contribution / Exchange Hall integration

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
| Staged Exchange: fresh rerun of Claude verifier | 43 PASS / 0 FAIL | `codex-exchange-hall/staged-basic/verify-results.json` |
| Canonical Exchange: rerun after documented collision correction | 43 PASS / 0 FAIL | `codex-exchange-hall/integrated-basic/verify-results.json` |
| Independent first/third-person routes, collision and camera | 70 PASS / 0 FAIL | `codex-exchange-hall/independent-routes.json` |
| Independent rendered routes and screenshots | 78 PASS / 0 FAIL | `codex-exchange-hall/rendered-routes.json` |
| Ten-entry gallery and actual programmatic inputs | 27 PASS / 0 FAIL | `codex-exchange-hall/gallery-input.json` |
| Read-only Exchange Blender source reopening | 5 PASS / 0 FAIL | `codex-exchange-hall/native-source.json` |
| Existing batch 2: fresh basic checks on staged assets | 21 PASS / 0 FAIL | `codex-exchange-hall/batch2-check/verify-results.json` |
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

# Codex report — Mission Hall independent review and integration

22 October 2026. **Mission Hall: created, imported, independently verified on the recorded checks, and integrated as gallery entry nine.** Human visual acceptance and production-world readiness remain pending. This update concerns Mission Hall only. Alchemy/Medicine remain staged and independently unverified; Contribution / Exchange Hall was not started. The previous four-asset report is retained below as historical evidence.

Read the complete current Claude report and handoff, inspected the scene, model, summary, authoring code and review/test scripts. The requested `review/mission_hall_review.ts` does not exist: the actual delivery has `staging/claude_mission_hall/review/mission_hall_review.tscn` and `.gd`. Claude's original report records 25 passing checks and ten screenshots; those are Claude's results, not the independent results below. Its “not integrated” status describes the pre-review delivery and remains frozen for provenance.

## Permanent files and integration

All paths below are relative to `prototype/CultivationSect_LowPoly_Test/`:

- `assets/architecture/mission_hall/mission_hall.glb` and Godot-generated `.glb.import`
- `scenes/buildings/mission_hall.tscn`
- `source/claude_mission_hall_integrated.blend`
- `scripts/mission_hall_review.gd`
- `scenes/review/mission_hall_walkthrough.tscn`
- Existing `assets/gallery/catalog.json` appends Mission Hall with Walk and interior-camera metadata. The gallery script and previous eight entries are unchanged.

Destinations were checked before copying; no conflict existed (`codex-mission-hall/destination-check.json`). GLB and native source are byte-identical to staged originals. The building scene changes only its GLB path, retaining all collision shapes/transforms and plaque. New import metadata has its own UID, distinct from staging. The building depends only on its permanent GLB, whose materials are embedded; it has no textures, lights, scripts or runtime staging/original-project dependency. The review uses the unchanged `scripts/training_inspection_player.gd` and a neutral ground plane. Review fixture changes are resource/output paths, HUD attribution and an output-path comment; no architecture changed.

Launch the project's asset gallery, select **Mission Hall → Walk asset**, or open `scenes/review/mission_hall_walkthrough.tscn` directly. 1 toggles review/walk; WASD/mouse move/look; Tab selects first/third person; Esc returns to the gallery. This is one asset at local identity, not a town placement.

## Actual independent results

| Check | Result | Raw evidence |
| --- | --- | --- |
| Claude checks rerun on staged scene | 25 PASS / 0 FAIL | `codex-mission-hall/staged-basic/verify-results.json` |
| Claude checks rerun on canonical scene | 25 PASS / 0 FAIL | `codex-mission-hall/integrated-basic/verify-results.json` |
| Independent headless traversal/collision/camera suite | 50 PASS / 0 FAIL | `codex-mission-hall/independent-routes.json` |
| Independent rendered traversal/collision/camera suite | 56 PASS / 0 FAIL | `codex-mission-hall/rendered-routes.json` |
| Gallery loading and programmatic key/mouse inputs | 26 PASS / 0 FAIL | `codex-mission-hall/gallery-input.json` |
| Read-only Blender source reopening | 5 PASS / 0 FAIL | `codex-mission-hall/native-source.json` |
| Inspected GLB audit, rerun separately on staged and permanent models | PASS: 17,790 triangles; zero degenerate triangles, non-flat triangles, invalid normals or nonfinite positions | `codex-mission-hall/staged-glb-audit.json`, `canonical-glb-audit.json` |
| Import and render compatibility | Canonical GLB imported; gallery and walkthrough rendered in Godot 4.7.2 | `codex-mission-hall/import.log`, capture/runtime logs; host errors below |
| Preservation and copy provenance | PASS | `codex-mission-hall/preservation.json`, `before-hashes.json` |

Measured imported bounds: **19.060 × 21.32061 m footprint, 9.805352 m high**, minimum y=0; identity root, +Z entrance, metre units. 12 surfaces, 12 opaque palette materials, roughness .82 (bronze .56), no image textures/external URIs. Source reopening confirmed 12 editable material batches, 17,790 triangles, flat polygons and metric units; it was not saved/re-exported.

Independent ray measurements reproduce door width 3.00 m at the wall / 2.84 m between visible open leaves, door height 3.40 m, porch central bay 2.42 m, visible plaque headroom 2.95 m, side passage 2.25 m collision / 2.38 m visible, and aisle height 5.00 m collision / 8.42 m visible. The no-hit ray limits (e.g. 8 m across the uncollidable leaves) mean open space within the probe range, not a measured opening.

The existing 1.8 m, .28 m radius controller ascended/descended the front stair, crossed the forecourt/porch/door/aisle, approached the counter, used both side passages, traversed the officials' area, and approached both mission boards in **both camera modes**. Counter, wall/noticeboard and both forecourt boards block tested movement. Each final independent route run sampled **444 pairs of camera/body volumes**, against authored collision and visible-mesh copies; no sampled intersections. The rendered suite's 56 checks include six screenshot writes; they are not 56 unique gameplay systems. The separate gallery suite loaded all nine entries and exercised 1, W, Tab, mouse look and Esc for Mission Hall. Other assets' complete movement suites were not rerun in this task.

## Failures, corrections and diagnostic limits

The initial independent route run was **42 PASS / 6 FAIL**. Its straight waypoint crossed the returns chest at x=4, z=-2.1; the following two waypoints then failed in each camera mode. The authored chest correctly blocked the controller. The test route was corrected to step back to z=0 before entering the east passage. The initial JSON/log are retained as `initial-route-failures.*`; final reruns passed. No staged or permanent asset geometry/collision/material correction was needed. Claude's two earlier authoring fixes are reported in its own report and were not repeated here.

The engine logs are **not clean**: they report `Failed to read the root certificate store`; the headless editor import also could not save the user's `editor_settings-4.7.tres`. Import completed and runtime suites exited successfully; no asset/parser/missing-resource diagnostic was found. These host access problems were not fixed or investigated further. Blender also emitted a future-API `Material.use_nodes` deprecation notice; its read-only checks passed. The shell's `python` alias was unavailable; the installed Codex runtime Python was used directly.

One new `.gd.uid` for the staged review script was generated by the editor scan; after confirming it was absent from the frozen delivery, it was removed to restore the original staging file set. All **48 pre-existing staging files** now match and there are no additions. Claude's report and evidence are unchanged. All **1,599 original-project files** match both the start-of-task snapshot and the recorded original manifest. Approved Hall, other assets/high-detail sources, existing controllers, gallery code, project settings and default main scene are unchanged. Only catalog, this report, handoff and inventory are permitted pre-existing-file changes. Recovery of those files: `codex-mission-hall/before-docs-catalog.zip`. Builders were never executed.

## Genuine screenshots and remaining work

29 Godot viewport captures were produced: ten staged review images, ten canonical review images, six moving-route images, and three gallery/input images. Selected exterior, board, interior, first/third-person, rear and side views were inspected; no blocking visible hole, missing material or clipping defect was observed in those views. User acceptance is pending; no exhaustive seam/z-fighting guarantee is implied.

![Mission Hall in the nine-asset gallery](codex-mission-hall/gallery-mission-exterior.png)

![Integrated interior preset](codex-mission-hall/gallery-mission-interior.png)

![Third-person officials-area traversal](codex-mission-hall/tpp-officials-east.png)

**Not performed:** human keyboard/mouse playtesting or user acceptance; FPS/frame-time/performance comparison; representative low-end hardware, exported build or sustained-load tests; town/terrain fit, production character, navigation/NPC integration; exhaustive collision/camera/roof-walking checks; OS Open source-button launch. Rendered conditions were Compatibility/OpenGL on RTX 3050 Laptop, 1280×720, project MSAA 4× (gallery viewport 2×), fixed-fps 60 for functional testing; these timings are not benchmarks.

Boards/counter/tablets are static decorative architecture, with no mission/quest interaction or readable task UI. Door leaves are static/open; small details have no separate collision. No LOD/distant mesh. Front stair is the intended access to the .75 m podium; the solid balustrade restricts side approaches. The invisible ceiling clearance slab at y=5.75–5.85 is retained. Existing Training timing regression / 84 inherited roof-collider degenerates remain unrelated, unchanged issues.

**Readiness:** ready for standalone visual review and later placement planning, **not verified ready for final town-layout placement**. Exact next action: gallery → Mission Hall → Walk asset; manually rehearse stair, boards, doorway, counter and side passages in both modes and record observations/user acceptance. Keep final placement deferred until terrain, production traversal/navigation and performance checks are authorized and performed. Do not start Contribution / Exchange Hall or Alchemy Pavilion from this handoff.

Reproduce from the test project with `../../tools/godot/Godot_v4.7.2-stable_win64_console.exe`:

```text
--headless --path . --editor --import --log-file reports/codex-mission-hall/import.log
--headless --fixed-fps 60 --path . --script res://tools/verify_integrated_mission_basics.gd
--headless --fixed-fps 60 --path . --script res://tools/verify_mission_integration.gd
--fixed-fps 60 --path . --script res://tools/verify_mission_integration.gd -- --rendered
--fixed-fps 60 --path . --script res://tools/test_mission_gallery.gd
--path . --resolution 1280x720 res://scenes/review/mission_hall_walkthrough.tscn -- --capture
```

The staged-check rerun uses `tools/verify_mission_basics.gd` (output redirected to Codex evidence). The GLB auditor is `staging/claude_mission_hall/tools/audit_glb.py`; only its output argument is changed. Blender command: `blender.exe --background --factory-startup --python tools/inspect_mission_source.py`. State/provenance: `tools/mission_integration_state.py verify`. `tools/finalize_mission_review.py` validates existing evidence and publishes docs; it does not execute engine tests. Earlier four-asset finalizers assume eight entries and must not overwrite these current docs.

---

## Historical four-asset integration report (previous run; counts below are not the current catalog)

# Codex report — Claude asset integration

22 October 2026. Read `CLAUDE_ASSET_REPORT.md`, the actual staging builder, scenes, models, summary and review/test code. Claude's reported results were treated as prior evidence; the results below are fresh Codex tests of the integrated project copies.

## Integrated result

All four delivered buildings are now available in the eight-entry asset gallery and through individual Walk asset routes. Model geometry/materials were copied byte-for-byte from staging. Copied scenes retain all authored collision shapes, transforms, floor elevations and plaque text; only the GLB resource path changed. No asset redesign or world placement was performed.

The original project `../asset-workshop` remains unchanged against 1,599 recorded non-cache hashes. All 21 staged files, Claude's report and its original screenshots/test results remain unchanged. The earlier Hall, Gate, Training Ground and Pavilion model/source/scene/controller data, project settings and default Hall scene remain unchanged. Only two pre-existing runtime files changed: `assets/gallery/catalog.json` and `scripts/asset_gallery.gd`.

| Asset | Imported X × Z (m) | Height (m) | Triangles | Surfaces | Collision shapes |
| --- | --- | --- | --- | --- | --- |
| Disciples' Residence | 21.40 × 10.89 | 6.96 | 9,518 | 12 | 36 |
| Elder Residence | 22.64 × 22.30 | 8.05 | 16,338 | 13 | 49 |
| Dining Hall and Kitchen | 23.15 × 21.12 | 9.26 | 23,328 | 12 | 53 |
| Spirit Herb Garden | 24.46 × 25.14 | 6.51 | 12,474 | 13 | 37 |

Imported scale matches the staged measurements within 0.05 m, and each asset uses an identity root transform. The existing 1.8 m tall, 0.28 m radius inspection controller physically enters the tested rooms and climbs/descends the recorded stairs. The Garden's lowest decorative geometry is about -0.0063 m, not exactly zero; no model was rescaled to hide this.

## Files integrated and gallery changes

- `assets/architecture/disciple_residence/disciple_residence.glb`
- `scenes/buildings/disciple_residence.tscn`
- `scenes/review/disciple_residence_walkthrough.tscn`
- `assets/architecture/elder_residence/elder_residence.glb`
- `scenes/buildings/elder_residence.tscn`
- `scenes/review/elder_residence_walkthrough.tscn`
- `assets/architecture/dining_hall_kitchen/dining_hall_kitchen.glb`
- `scenes/buildings/dining_hall_kitchen.tscn`
- `scenes/review/dining_hall_kitchen_walkthrough.tscn`
- `assets/architecture/spirit_herb_garden/spirit_herb_garden.glb`
- `scenes/buildings/spirit_herb_garden.tscn`
- `scenes/review/spirit_herb_garden_walkthrough.tscn`
- `source/claude_buildings_integrated.blend`
- `scripts/claude_asset_review.gd`
- `Review Claude Assets.cmd`

Godot generated new `.glb.import` metadata for the four copied models. These copies have different UIDs (Godot's internal resource IDs) from the staged resources; staged import metadata was not copied or edited. Each copied building scene depends only on its own canonical GLB under `assets/architecture/`, with no runtime staging or original-project dependency. The native source is a byte-identical copy, not a reexport.

The gallery preserves the first four catalog entries and adds the four new entries. Its small code extension enables metadata-defined walkthrough routes and authored interior camera presets for the new buildings. Existing routes and camera presets remain in place. The new review script shows **one asset at identity/local origin at a time**, with a neutral inspection floor and the unchanged controller. Keys 2–5 select an asset for inspection; this does not assign world positions. `Review Claude Assets.cmd` opens the Disciples' inspection scene; each new gallery entry opens its own correct wrapper.

## Tests actually performed

| Check | Actual result |
| --- | --- |
| Fresh rerun of Claude basic assertions against integrated scenes | 22 PASS / 0 FAIL |
| Expanded headless routes, scale/material/collision/camera checks | 121 PASS / 0 FAIL |
| Expanded rendered routes and image captures | 138 PASS / 0 FAIL |
| Gallery registration/interior presets/source paths and actual programmatic inputs | 81 PASS / 0 FAIL |
| Read-only reopening of editable Blender source | 9 PASS / 0 FAIL |
| Existing Hall review inputs/routes | 7 PASS / 0 FAIL |
| Existing Gate review inputs/routes | 7 PASS / 0 FAIL |
| Existing Training/Pavilion review inputs/routes | 17 PASS / 0 FAIL |
| Default project startup | PASS; rendered unchanged default Hall, 60-frame startup |
| GLB geometry and materials | Four models: finite positions, unit flat normals, opaque materials, no images/textures/external URIs or near-zero-area triangles at audit tolerance |
| Original project preservation | 1,599 recorded non-cache SHA-256 hashes match |
| Claude staging preservation | All 21 frozen files match, including source, builder, scenes, models, import metadata and review scripts |
| Earlier assets/controls/settings and Claude report/evidence | Frozen hashes match; only existing catalog and gallery code intentionally changed |

The expanded functional run checks every dorm room via the veranda, the elder's gate/main-room stair and west-facing attendant wing, the dining main and both side entrances, kitchen connection and east service stair in both directions, and garden circulation around the spring/beds to the pavilion and tool shed. Solid dorm walls and raised herb beds block real movement. Both first- and third-person cameras were exercised. There were 561 sampled camera-sphere and upper-body/visible-mesh checks on the rendered routes, with no detected obstruction. This is not exhaustive collision certification.

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

- Human keyboard/mouse playtesting and user visual acceptance were not performed.

- No FPS/frame-time benchmark, representative low-end hardware, sustained thermal/stutter test, exported executable or populated-world test was performed for this batch. Geometry counts do not establish performance.

- Elder courtyard and Herb Garden require supporting ground/terrain. The review supplies a collision plane at y=-0.012; garden path slabs are visual-only with tops around y=0.04, so they do not raise foot contact to the decorative path top. Terrain fit, foot/path seams and production ground remain deferred.

- Door leaves are authored standing open and are static geometry, not operable doors. Small decorative props/plants/lanterns/pots and path finishes are not all collidable by design. No sleeping, dining, harvesting, NPC, quest or navigation systems were added or tested.

- No distant simplified mesh/LOD exists for these four models. Roof walking, exhaustive collision coverage, all camera angles and terrain/navigation integration were not tested. Collision/camera conclusions apply only to the recorded paths and sampled volumes.

- Native-source button path/file availability was tested; invoking the operating-system Open source action and manually double-clicking the CMD launcher were not tested. Direct Godot scene routes and direct Blender source reopening were tested.

- The shared Blender file contains four alternative asset collections at their authoring origin. Isolate one collection for editing; the overlapping authoring collections are not a town arrangement.

Existing Training performance regression and its 84 zero-area roof-collider triangles remain unchanged. No timing or collider repair is claimed here; see `LOW_POLY_STAGES_2_3_REPORT.md`. Current user priority is asset completion/integration, with final town placement deferred.

No blocking import, material, scale or tested-route defect was found in these four integrated copies. This statement covers the tests listed here, not production-world readiness.

## Exact next action

Open `Review Claude Assets.cmd`, or gallery → one of the four new buildings → Walk asset. Manually review doors/verandas, all dorm rooms, the elder side wing, kitchen service entrance, and garden path/bed/pavilion/shed circulation in both camera modes, recording actual observations separately from automation. Continue the next explicitly authorized asset batch in a **new staging folder** and provide another asset report for integration. Preserve this staging delivery and canonical copies; do not rerun its original generator in place. Keep prioritizing asset completion. Do not assign final town positions or start terrain, road or town-layout placement. Training profiling/collider cleanup remain separate outstanding issues, and performance claims must wait for actual tests.

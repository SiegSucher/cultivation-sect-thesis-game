# Current handoff — Main Hall rear-column/drum collision aligned

23 October 2026. Corrected only the Main Hall's permanent `assets/architecture/tang_main_hall/main_sect_hall.json` rear column/drum records: eight visible pairs now match their collision (X shifts .20 m inward, Z -10.0 -> -9.6); two independently confirmed invisible central pairs at X=±3.65 were removed from collision. **16 shapes moved, 4 unmatched shapes removed; 195 -> 191 simple shapes.** All 175 unrelated simple shapes, all other JSON fields/roof faces, scene, model/material/source, scale/placement, player/camera, front colonnade, other buildings, staging and original project preserved.

Report: `reports/CODEX_MAIN_HALL_COLLISION_FIX.md`; measurements/backups/logs/screenshots: `reports/main-hall-collision-fix/`; guarded tool: `tools/fix_main_hall_veranda_collision.py` (default diagnosis/candidate; --apply requires frozen bytes and before-probes). Maximum sampled visible/physical surface gap **.469817 -> .0004654 m**. Pre-edit probes **41/0**. Final full tests **154 PASS / 1 FAIL headless, 158 PASS / 1 FAIL rendered**; all **78 movement cases pass in each**, with 3,038 camera/body samples and no authored-camera/body overlaps. All-twelve gallery launch/control regression **466 PASS / 0 FAIL**. No human playtest/acceptance.

**Retained failure:** broad visible-camera clearance still reports 27 Cedar trim overlap poses. Matched frozen-old/current 1,296-pose sweeps give Timber overlaps **24 -> 0**, Cedar **31 -> 27**, zero new overlap poses. The remaining trim contacts pre-exist; no unrelated camera/trim repair was made. Certificate-store diagnostics remain; diagnostic outline captures also logged host shader-cache save failures. No cache/system permission changes.

The specific rear-column placement blocker in `reports/FINAL_BUILDING_READINESS_AUDIT.md` is resolved; current Hall classification is **ready with known limitations for controlled placement testing**, not production certification. That audit and older handoff records are preserved as historical evidence. Furniture/rings/front collision, final character/navigation/terrain/export/low-end performance and human acceptance remain unverified/out of scope. No town placement begun.

Preservation: 5,590 pre-existing test files checked; only Hall JSON and this handoff changed. All 1,599 recorded original files and 62 pre-existing staged files match. A separate workstream added `staging/claude_environment_batch1/` during verification (28 files observed); it was left untouched and is not reviewed/integrated by this Hall task. See the preservation record for its observed paths; do not overwrite or duplicate that staging work.

**Exact next action:** human Hall gallery walkthrough along the rear platform: immediate TPP, Tab FPP/TPP, WASD/mouse; verify all eight columns/drums, both cleared central locations and camera turns near rear window trim. Preserve the corrected permanent JSON and never replace it from raw staging or the uncorrected historical visual generator. Rollback, if explicitly needed, uses `reports/main-hall-collision-fix/before/main_sect_hall.json.txt` only. Do not start town placement or unrelated collision work automatically.

# Previous Training roof collision handoff

23 October 2026. Confirmed 84 exact degenerate roof faces in Training's permanent JSON and identical historical baseline. Origin: original collision exporter's fan of collapsed hip-end quads, **3 roofs x 2 ends x 14**; not the current Blender mesh or GLB. New collision-only generator normalizes repeated polygon corners before triangulation. **4,560 -> 4,476 faces; zero degenerates**, all valid face coordinates/order/winding and all other JSON fields preserved. Existing runtime change is only `assets/architecture/martial_training_ground/martial_training_ground.json`; scene, GLBs/materials/source, equipment, player/camera, Hall startup, six door repairs, staging and original project unchanged.

Full report: `reports/CODEX_TRAINING_GROUND_FIX.md`; evidence/backups: `reports/training-ground-fix/`; tool: `tools/rebuild_training_roof_collision.py` (default diagnoses/candidates only; --apply is guarded against task-start bytes). Roof coverage: **5/0**, **11,046 ray + 789 sphere-sweep comparisons**, no hit/position differences. Native source and all Training GLBs have zero degenerate render triangles. Functional regressions **66/0 headless, 87/0 rendered**; all-twelve gallery **466/0**. No human playtest/acceptance or production-player/navigation certification.

Historical rendering regression was **not reproduced in fresh matched baseline/current runs** (court mean 7.505 -> 6.342 ms, lower converted draws). Both used identical old collision, so the 84 triangles cannot explain that historical difference. Physics/shadow controls and same-process old/clean tests were recorded. **No consistent FPS effect of collider cleanup established**: timing variation remains large even with identical rendering. No persistent rendering/shadow optimization applied; historical slowdown cause remains unconfirmed. Shader-cache save errors occurred in shadow diagnostics before marked timing windows; known host certificate error remains. No system permissions/cache settings changed.

**Exact next action:** human Training gallery walkthrough (FPP immediately, Tab TPP, WASD/mouse, Esc gallery; 1 unbound), focusing on all three shelters/dais and equipment routes. If a stable rendering slowdown recurs, capture controlled foreground power/clock/load and GPU/CPU scheduling evidence before further optimization. Preserve approved visuals and the fixed collision generator. Do not begin unrelated assets, collisions or town layout automatically. Older handoff sections below retain stage-specific "84 unresolved" notes as history; this report supersedes those collision notes, not as proof of a universal performance gain.

## Previous door-collision handoff

23 October 2026. Added **26 confirmed missing static-leaf boxes across 13 openings** in six corrected permanent scenes, preserving every original resource/node/property, Exchange's four earlier storeroom boxes, Medicine's counter and camera-only corrections. Current shape totals: Mission **39**, Exchange **75**, Dining/Kitchen **61**, Disciples **44**, Elder **53**, Medicine **56**. Visible models/materials/source, staging, all player/camera code, Hall startup and original project unchanged. These leaves remain static/open; no E interaction added.

Full report/paths/rollback: `reports/CODEX_DOOR_COLLISION_FIX.md`; evidence: `reports/door-collision-fix/`; additive tool: `tools/fix_static_door_leaves.py`. Do not overwrite canonical scenes from staging or run old stage-based scene generators over these additions. Current counts supersede older stage-specific asset reports/inventory.

Independent before-probes confirmed 390/390 visible leaf hits with no matching collision, plus 60/60 already-corrected storeroom hits. After: **181/0 headless, 191/0 rendered**, 15 openings / 450 leaf rays, two-way FPP/TPP traversal and side blocking; **808 camera/body pairs per run, zero contacts**. Four dorm doorway sweeps/turns: **1,008 poses, zero overlaps**, including the previously reported camera-overlap poses. Existing regressions: batch1 **121/0 + 138/0**, Mission **50/0 + 56/0**, Exchange **70/0 + 78/0**, batch2 **124/0 + 136/0** (headless/rendered); all-twelve gallery/control audit **466/0**. Minimum clear opening is Elder wing **1.0 m**. Headless/rendered automation and selected capture inspection are not human playtesting.

Known host certificate-store error remains; no final asset/parser/resource error. Production player/NPC/navigation, exhaustive approaches, human acceptance, performance and final terrain placement remain unverified. Medicine's threshold gap/camera exception contract and all unrelated scale-audit/Training issues remain. The earlier dorm camera overlap samples are now clear after leaf correction; general near-wall compression still applies.

**Exact next action:** human gallery review of Mission/Exchange main doors, Dining main/side/service doors, all four dorm rooms, Elder main/wing and Medicine balcony. For these six assets: Walk asset -> 1 -> Tab, approach each leaf and traverse the clear centre in FPP/TPP. Hall still starts immediately in TPP. Do not begin unrelated collision repair, new assets or final layout automatically.

## Previous Hall startup and launch-audit handoff

23 October 2026. Approved manual startup fix applied **only to `scripts/hall_experiment.gd`**. Hall Walk asset and direct F5 now start in walking third person with the figure visible, movement/input enabled and mouse captured. **1** overview/walk, **Tab** FPP/TPP, **E** doors, **Esc** gallery and **2/3/4** presets work. Automated Hall startup is unchanged. No controller/camera setting, catalog, building resource, staging file, layout or original project change.

Post-fix rendered audit: **466 PASS / 0 FAIL across all twelve canonical entries**, 46 captures. The other eleven startup states match prior evidence: nine intentionally begin in review (1 then Tab), while Training/Scripture begin in FPP walking (Tab shows figure; 1 is unbound, overview via Esc/gallery). All twelve movement/mouse/Tab/Esc paths passed; ten available overview cycles recover input. Documented extra keys, utility camera-exception lifecycle and automated Hall startup also passed. Full table/evidence: `reports/CODEX_GALLERY_LAUNCH_AUDIT.md`, `reports/gallery-launch-audit/`.

Known host certificate-store error remains; no relevant final asset/parser/input/resource error. These were rendered **programmatic** GUI/input tests, not human playtesting. OS focus, user's live editor/debugger and manual acceptance remain unverified. Indoor-camera doorway-timber/near-wall limitations and other unrelated asset issues remain unchanged. Earlier investigation's Hall overview-start workaround is historical, superseded by this approved fix.

**Exact next action:** user opens this test project and presses **F5**, or gallery **F6 -> Hall -> Walk asset**. Confirm immediate visible walking, 1 overview/resume, Tab and Esc with physical keyboard/mouse and game focus. Review remaining entries using their documented modes. Do not normalize all startup modes, change assets or begin final town layout automatically.

## Previous indoor-camera handoff

23 October 2026. Camera-only follow-up implemented in `scripts/training_inspection_player.gd`: configurable covered-space offset `(0, .12, 2.2)`, .65 m lower indoor aim, smooth profile/outward recovery, original wall/ceiling sphere cast and outdoor settings retained. No building/model/material/scene/asset collision/staging/catalog/layout changes. The original project remains untouched. Full results, rollback and exact manual steps: `reports/CODEX_INDOOR_CAMERA_FIX.md`; evidence: `reports/indoor-camera-fix/`.

Final representative tests: **46/0 headless, 58/0 rendered**; redirected existing Alchemy/Medicine regressions **124/0 headless, 136/0 rendered**; twelve-entry gallery/input **53/0**. Three outdoor screenshot pairs are pixel-identical. Dormitory measured doorway boom jump .7323 -> .0468 m/frame. No sampled authored-solid camera overlaps. Known visible doorway-timber overlaps remain: continuous-turn dorm camera probes 20 -> 25; this is explicitly not full visible-clearance success. Near-wall sub-metre compression remains physically necessary with this boom. No human acceptance, performance or production-player verification claimed. Do not repair doorway/other audit collision findings under this camera task.

**Exact next action:** human A/B review in the existing Hall, Disciples' Residence and Alchemy Walk routes (1 walk, Tab camera; E Hall doors). Use the running player's exported `indoor_camera_enabled` switch to compare the original camera. Record preference/remaining doorway clipping before deciding whether any separate camera-avoidance or collision work is authorized. Do not begin final layout or another asset automatically.

## Previous verified asset-integration handoff

The record below describes the preceding integration stage; its statements that the shared controller was unchanged apply to that stage, before this camera-only follow-up.

23 October 2026. **Both existing batch-2 assets are independently reviewed/tested, corrected and integrated as gallery entries eleven/twelve.** There are now twelve explicit standalone gallery assets, 35 runtime GLBs and 38 scenes. No duplicate modeling, original-project changes or town-layout placement. Previous ten assets, including Mission and Exchange, remain unchanged.

## Permanent files and current results

| Asset | Model | Building scene | Walkthrough |
| --- | --- | --- | --- |
| Alchemy Pavilion | `assets/architecture/alchemy_pavilion/alchemy_pavilion.glb` (+ `.import`) | `scenes/buildings/alchemy_pavilion.tscn` | `scenes/review/alchemy_pavilion_walkthrough.tscn` |
| Medicine Hall | `assets/architecture/medicine_hall/medicine_hall.glb` (+ `.import`) | `scenes/buildings/medicine_hall.tscn` | `scenes/review/medicine_hall_walkthrough.tscn` |

Shared editable source: `source/claude_batch2_integrated.blend` (byte-identical to the existing staged source; two collections at the authoring origin). Shared review: `scripts/alchemy_medicine_review.gd` (+ `.gd.uid`). Medicine's required extra resource: `assets/architecture/medicine_hall/medicine_camera_obstructions.tres`. Gallery catalog appends both entries; earlier ten entries and gallery script unchanged.

Alchemy: 25,586 triangles, 13 materials, 17.0983 W × 17.98391 D × 12.57 H m, floor .90 m, **45 colliders**. Medicine: 20,636 triangles, 15 materials, 17.8 W × 14.55696 D × 11.00315 H m, floors .45/4.20 m, **54 colliders**. Roots identity, metres, +Z entrance; geometry/materials/source unchanged from staging.

Fresh basic tests are **21 combined**, not 21 each: ten Alchemy + eleven Medicine, on staging and corrected canonical scenes. Expanded headless: Alchemy 61/0 + Medicine 63/0 = 124/0. Rendered: 66/0 + 70/0 = 136/0. Gallery/input 53/0; read-only shared source 11/0; GLB audits both PASS. Each expanded run sampled 416/398 camera/body pairs; no final contacts. **50 genuine screenshots** plus JSON/logs: `reports/codex-alchemy-medicine/`. Full current report: `reports/CODEX_REPORT.md`; prior Exchange/Mission report archived as `reports/codex-alchemy-medicine/previous-CODEX_REPORT.md`.

## Fixes and required Medicine camera setup

Initial headless 123/1 found Medicine counter overhang/body contacts and stair/herb camera contacts. Four existing counter boxes now match the timber tops. One separate camera-only concave shape copies 698 real model triangles (538 stair detail, 160 herbs), preserving the smooth walking ramp. First rendered 135/1 then caught an Alchemy open-leaf camera contact; two matching static-leaf boxes fix it, retaining the 43 original colliders. Initial gallery 51/0 still logged a freed-body error; exception removal before freeing old assets fixes this, with final stronger 53/0. All failing evidence retained; no probe tolerance relaxation or visible redesign.

**Important integration contract:** Medicine's `CameraDetailObstruction` belongs to group `camera_only_obstruction`, collision layer 1/mask 0. The review uses `player.add_collision_exception_with(body)` so the walker ignores these detail triangles while the unchanged camera's independent query sees them. It removes old exceptions before switching assets. A future production controller must reproduce that setup or provide separate camera collision layers. Bare scene placement with another character is not verified. Keep the `.tres` resource and fixture logic; do not overwrite corrected scenes from raw staging. Shared inspection-controller source is unchanged.

Reproducible correction tools: `tools/build_medicine_camera_shape.gd`, `tools/fix_medicine_collision.py`, `tools/fix_alchemy_leaf_collision.py`. These operate only on canonical copies; do not run frozen staging builders. Final evidence checker: `tools/audit_batch2_state.py`. Current publisher: `tools/finalize_batch2_review.py` (does not run tests). Earlier finalizers/catalog-count fixtures are historical and must not overwrite current reporting.

## Protected work and limits

Original project: all 1,599 files match baseline and task-start snapshot. All 61 staged files, including 15 batch-2 files, Claude report/evidence, earlier assets/high-detail sources/player/cameras/gallery/settings remain unchanged. Known editor-regenerated staged Mission `.gd.uid` was recorded/removed only because it was absent from the frozen set; normal canonical/tool sidecars retained. Recovery: `reports/codex-alchemy-medicine/before-docs-catalog.zip`; previous handoff archived alongside it.

Host certificate-store/editor-settings errors and known missing-UID import warning remain documented. No final asset/parser/missing-resource/freed-body diagnostic. No human playtesting/acceptance, performance/FPS/low-end/export/sustained-load, terrain placement/navigation/NPC/production-player verification, exhaustive collisions/camera/foot seams or OS source-button launch. No LOD or crafting/shop gameplay. Basins/yard racks need supporting ground; Medicine stair remains steep and hanging herbs leave about 1.97 m loft clearance. Current status is standalone gallery review readiness, not final placement certification. Training timing regression/84 roof-collider degenerates and Exchange close-up cosmetic review remain separate issues.

## Exact next action for Claude

Open gallery → **Alchemy Pavilion** or **Medicine Hall** → **Walk asset** (or the canonical walkthrough above). 1 walk/review; WASD/mouse; Tab FPP/TPP; 2 Alchemy/3 Medicine; Esc gallery. Manually rehearse furnace/colonnade, counter fronts, interior stair both ways, loft/balcony, review images and record user acceptance. Preserve the Medicine camera setup when any future production-player integration is authorized. **Do not begin final town layout or another asset automatically.**

## Original visual references (unchanged)

| Filename in reference_images | Use |
| --- | --- |
| codex-clipboard-dc7122d9-e820-4f94-8d68-15fba15e3b99.png | Timber/plaster/stone hierarchy |
| codex-clipboard-1ffce86a-e99d-4914-a154-8a815e5350e1.png | Supported eaves and warm framing |
| codex-clipboard-e8c443bb-86da-403a-9fb3-f13ca00ef3fe.png | Faceted low-poly economy |
| codex-clipboard-c2524fdf-1147-4d23-a6ac-0788c24f2fe7.png | Restrained stone and readable forms |
| codex-clipboard-daa459e5-a841-4817-a71b-a8497d2f7340.png | Jade/bronze cultivation grandeur; no copied towers |
| codex-clipboard-5c7491b2-bfc3-4dca-b95e-9a09214adb07.png | Roof hierarchy and distant silhouettes |
| codex-clipboard-321de4c1-87cf-440a-8a3a-65bc7e2efcef.png | Sect atmosphere; no landscape/effect copying |
| codex-clipboard-caebb330-769f-47ff-b312-7e04e3acdfa3.png | Swept roof and supported entrance, original wide composition |
| codex-clipboard-fa6b44ca-8dc3-4fa4-a102-25e85670a21e.png | Warm interior timber rhythm, no copied library |

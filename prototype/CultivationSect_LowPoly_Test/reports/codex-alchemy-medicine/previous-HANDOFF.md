# Current handoff — Contribution / Exchange Hall integrated

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

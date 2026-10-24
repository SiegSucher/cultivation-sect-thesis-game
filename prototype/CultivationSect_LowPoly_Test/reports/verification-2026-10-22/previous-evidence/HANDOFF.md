# Claude handoff - Split-Cloud Main Sect Hall

Final saved state: 22 October 2026. **Built, rendered, audited and runnable; awaiting user visual review. Decision: Do not expand yet.** Read this file, the current project and linked evidence before editing. Do not restart completed work. No message has been sent to Claude.

## Purpose and paths

Controlled low-poly Main Hall experiment, preserving the source project. Original Godot root: `C:\Users\pasto\OneDrive\Documents\ChatGPT\Character Sprite Image for Thesis game\prototype\asset-workshop`. Test root: `C:\Users\pasto\OneDrive\Documents\ChatGPT\Character Sprite Image for Thesis game\prototype\CultivationSect_LowPoly_Test`. These are sibling runnable projects. The active source is the fresh asset workshop; there is no town, map/road connection or production player here. Retired Reedwell is not a valid source for this experiment.

Original runtime recovery: `C:\Users\pasto\OneDrive\Documents\ChatGPT\Character Sprite Image for Thesis game\prototype\CultivationSect_LowPoly_Test\original_runtime_recovery.zip`. Independent baseline hall: `C:\Users\pasto\OneDrive\Documents\ChatGPT\Character Sprite Image for Thesis game\prototype\CultivationSect_LowPoly_Test\baseline\hall`. Original fingerprints: `C:\Users\pasto\OneDrive\Documents\ChatGPT\Character Sprite Image for Thesis game\prototype\CultivationSect_LowPoly_Test\reports\original_manifest.json`; final preservation verification: `C:\Users\pasto\OneDrive\Documents\ChatGPT\Character Sprite Image for Thesis game\prototype\CultivationSect_LowPoly_Test\reports\preservation-audit.json`. All 1,599 recorded original non-cache files match. Other facilities' non-import model/resources match. Both original inspection-controller and door-mechanism scripts match byte-for-byte.

Reports: `C:\Users\pasto\OneDrive\Documents\ChatGPT\Character Sprite Image for Thesis game\prototype\CultivationSect_LowPoly_Test\reports`. Genuine screenshots: `C:\Users\pasto\OneDrive\Documents\ChatGPT\Character Sprite Image for Thesis game\prototype\CultivationSect_LowPoly_Test\reports\screenshots` (six matched before/after pairs). References: `C:\Users\pasto\OneDrive\Documents\ChatGPT\Character Sprite Image for Thesis game\prototype\CultivationSect_LowPoly_Test\reference_images`. Native source: `C:\Users\pasto\OneDrive\Documents\ChatGPT\Character Sprite Image for Thesis game\prototype\CultivationSect_LowPoly_Test\source\split_cloud_hall.blend`. Authoring program: `C:\Users\pasto\OneDrive\Documents\ChatGPT\Character Sprite Image for Thesis game\prototype\CultivationSect_LowPoly_Test\tools\build_split_cloud.py`. New exports: `C:\Users\pasto\OneDrive\Documents\ChatGPT\Character Sprite Image for Thesis game\prototype\CultivationSect_LowPoly_Test\assets\architecture\tang_main_hall`.

## Launch and environment

Run `Launch Low Poly Test.cmd` or open `project.godot` with Godot 4.7.2. `Launch Original Baseline.cmd` selects the unchanged baseline in the same room. Engine executable is shared software at `../../tools/godot/`; no resource is loaded from the original workshop. Controls: 1 walk/review, WASD/mouse walk, Tab first/third person, E doors, 2 front, 3 three-quarter, 4 interior, Esc copied gallery. The Hall Walk button returns to the test. The new wrapper pauses the fixture while using fixed review cameras; the fixture/controller source itself is unchanged.

Godot 4.7.2-stable (official); GL Compatibility; 1280x720; MSAA 4x (enum 2). No renderer switch. Matched benchmark disables VSync/frame cap at runtime only. Existing lantern lights retained, no added lights or shadows. Both variants share the same sun (100 m shadow distance) and environment. GPU NVIDIA GeForce RTX 3050 Laptop GPU; physical RAM 15.63 GiB; CPU identifier Intel64 Family 6 Model 154 Stepping 3, GenuineIntel. CPU marketing name unavailable (CIM access denied); power/thermal/background conditions not controlled.

## Architectural decisions

Original Split-Cloud design: broad ceremonial nave, low jade shoulders, open annular eave belt, swept entrance and folded front-facing gable with bronze mountain tympanum. Mountain motif repeats on ridge and leader screen; diamond motif on screens, doors and podium. Muted jade, oxblood timber, pale plaster/coping, blue-grey stone, restrained bronze. Referenced buildings were not reproduced. [Concept](reports/BUILDING_DESIGN.md), [style rules](reports/LOW_POLY_STYLE_GUIDE.md).

Root stays identity at local (0,0,0), +Z front, 1 unit = 1 m. Podium remains 40.4 x 24 m. Final bounds [P: (-20.82926, 0.0, -12.0), S: (41.65852, 18.22064, 30.18)] stay inside the original [P: (-20.84177, 0.0, -12.0), S: (41.68354, 18.31, 30.18)]. Preserve 1.52 m landing, ~1.53-1.55 m interior, 2.15 m dais, ten 0.15 m main stair rises, 11.2 m stair width, 6.4 x 5.4 m grand opening, 2 x 2.8 m private openings and room layout. Original non-roof collision records remain exact; roof collision follows the rebuilt soffits/canopy. No significant footprint/height change, world placement or scenery movement.

Near static mesh 71,557 triangles (baseline 203,064, 64.8% reduction), 12 shared material batches. Standard opaque flat-shaded materials, zero texture images/custom shaders/plugins/external assets. Same inexpensive mesh at the existing 95 m distance handover, not a separate reduced LOD. Current source has Hall, Grand and Private collections; Grand/Private leaves are hinge-local sources, not assembled doors. Edit component islands in Edit Mode. Godot supplies plaque text. Do not count doors or distance representation as separate facilities.

## Completed evidence and known limitations

- Baseline before rebuild: 21 PASS / 0 FAIL. Final rebuilt rendered suite: 21 PASS / 0 FAIL (`reports/*-results.json`). Real unchanged inspection-controller movement covers stair/door/aisle, leader dais and both administration rooms. First/third cameras, floor stability and closed-door blocking passed.
- Supplemental gameplay/camera checks: 18 PASS / 0 FAIL. Follow camera retracts before rear screen and clears geometry from a valid standing position; side wall blocks motion. Distance checks confirm resources loaded, not exhaustive pixel-level LOD QA.
- Actual dispatched input-event/launch/gallery checks: 7 PASS / 0 FAIL (`reports/controls-results.json`). Human rehearsal remains NOT TESTED.
- Blender source reopened: 7 PASS / 0 FAIL. Four GLBs: finite positions, valid indices, zero zero-area triangles, opaque self-contained materials. [Audits](reports/geometry-audit.json).
- Original SHA-256 and unconverted-facility audits passed. Latest final import and clean restart logs contain no errors/warnings. Source/native outputs and all 12 screenshots exist.
- Six matched 240-frame local samples show improved measured means. [Baseline](reports/baseline_performance.md), [comparison](reports/performance_comparison.md), [full report](reports/low_poly_test_report.md). Statistics are short local frame-interval observations, not low-end guarantees. No target device, populated-world, future production-player, exported executable or human playtest was performed.

Initial UID duplication in copied baseline import files was corrected using `tools/fix_copy_uids.gd`. An intermediate old-texture MD5 read error did not recur on clean restart. Optional Blender external-thumbnail write failed in sandbox; saved source/export/reopen succeeded. First visual pass was refined; draft evidence remains under `reports/iterations/first-pass`. Geometry audit found 128 collapsed ridge-tip triangles; removed them and remeasured/recaptured final geometry. An initial camera probe was inside leader furniture; corrected the probe position, without changing the controller. These resolved checks do not imply exhaustive intersection/camera QA.

## Supplied reference filenames and intended use

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

## Remaining work and recommended first action

1. Show the user `reports/screenshots/optimized-front.png`, `optimized-three-quarter.png` and `optimized-interior.png`, then launch the fixture for a human review. User visual acceptance remains pending; do not assume it.
2. Test on intended low-end hardware using the same settings/sequence. Establish sustained thermal and frame-time behavior and repeat samples before deciding whether to expand.
3. Later, in a separately authorized integration task, test with the actual production player/cameras, town footprint/neighbors, road connection and populated-world budget. None exists in this active source today.

Protect the original and recovery ZIP. Do not convert other buildings, revive legacy assets, change controls/renderer, copy pictured buildings, or fabricate tests. All work is saved. The first recommended action is user visual/human walkthrough review of this exact final model; do not rebuild it from scratch.

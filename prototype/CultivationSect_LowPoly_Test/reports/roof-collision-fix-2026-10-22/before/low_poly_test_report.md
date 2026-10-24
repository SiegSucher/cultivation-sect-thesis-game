# Main Sect Hall low-poly experiment

22 October 2026. The user approved the current **Split-Cloud Hall** as the visual direction and requested verification only. The approved geometry, materials, collision, editable source and controllers remain byte-identical to the approval checkpoint. The Main Hall alone was rebuilt in the earlier experiment. No further building conversion or redesign was performed during verification. The only runtime configuration correction gives the test a distinct application name and Godot user-data directory.

Original project: `C:\Users\pasto\OneDrive\Documents\ChatGPT\Character Sprite Image for Thesis game\prototype\asset-workshop`. Test project: `C:\Users\pasto\OneDrive\Documents\ChatGPT\Character Sprite Image for Thesis game\prototype\CultivationSect_LowPoly_Test`. **Original unchanged:** SHA-256 hashes match for all 1,599 recorded original non-cache files. [Preservation audit](preservation-audit.json). Recovery: `../original_runtime_recovery.zip`; baseline resources: `../baseline/hall`. Other three facilities' non-import resources match the original; copied inspection-controller and door-mechanism scripts are byte-identical. No original town exists in this active workshop; no Reedwell assets, town placement, map or future player was imported.

## Design and implementation

The nine supplied reference images informed jade roofs, warm timber, pale stone/plaster, economical facets and ceremonial scale. Geometry was newly authored without importing the old visual meshes or copying a pictured building. [Original concept](BUILDING_DESIGN.md), [style guide](LOW_POLY_STYLE_GUIDE.md). Refinement after first rendered review muted the roof, introduced the folded front-facing cloud canopy/mountain tympanum and improved blank partition walls.

The model has articulated podium/stairs/rails, six roof masses, faceted columns with interlocked brackets, real window screens, exposed nave ties/trusses, warm lanterns, six elders' seats, leader throne/dais/mountain screen and two accessible furnished rooms. Editable Blender source: `../source/split_cloud_hall.blend`; complete authoring program: `../tools/build_split_cloud.py`. Native reopen audit: 7 PASS / 0 FAIL. [Export geometry audit](geometry-audit.json) checks finite positions, valid indices, opaque embedded materials and zero-area triangles for all four GLBs.

Root/podium/facing/door clearances and all original non-roof collision shapes are preserved. Roof collision was rebuilt from actual new soffit triangles to follow the simplified roof and folded canopy. New bounds [P: (-20.82926, 0.0, -12.0), S: (41.65852, 18.22064, 30.18)] remain inside the old envelope [P: (-20.84177, 0.0, -12.0), S: (41.68354, 18.31, 30.18)]. Differences in tiny eave/crest extrema reduce the bounds slightly; there is no footprint expansion or height increase. No new floor, balcony, world position or inaccessible room was introduced.

Standard shared opaque materials, no image textures/custom shaders/plugins/downloaded assets, no added real-time lights, no renderer switch. 12 near static surfaces; same cheap mesh in the existing distance range. [Settings and measured comparison](performance_comparison.md). Static geometry 64.8% fewer triangles. Fresh matched local observations show about 22-26% exterior improvement and 8% fixed-interior improvement, with first/third-person interior effectively flat or slightly slower. Earlier samples showed larger gains, so sustained speedup is not established. Low-end hardware remains unverified. Texture-only and geometry-only contributions were not separately measured.

## Genuine matching screenshots

| View | Baseline | Final |
| --- | --- | --- |
| front | [Before](screenshots/baseline-front.png) | [After](screenshots/optimized-front.png) |
| three-quarter | [Before](screenshots/baseline-three-quarter.png) | [After](screenshots/optimized-three-quarter.png) |
| roof-detail | [Before](screenshots/baseline-roof-detail.png) | [After](screenshots/optimized-roof-detail.png) |
| interior | [Before](screenshots/baseline-interior.png) | [After](screenshots/optimized-interior.png) |
| first-person | [Before](screenshots/baseline-first-person.png) | [After](screenshots/optimized-first-person.png) |
| third-person | [Before](screenshots/baseline-third-person.png) | [After](screenshots/optimized-third-person.png) |

Screenshots come from real Godot rendered viewports at 1280x720. Camera positions/FOVs are in raw result files. No AI render or conceptual image is presented as game evidence. Reference images are stored with their original filenames in `../reference_images/`; individual filenames/intended use are in [HANDOFF](../HANDOFF.md).

## Functional evidence and limits

| Check | Result |
| --- | --- |
| Copied baseline before construction | PASS, 21 automated checks |
| Final rendered movement/camera suite | PASS, 21 automated checks |
| Main stair, entrance, aisle, four-step dais and both private rooms | PASS, actual unchanged inspection controller |
| Closed entrance blocks player | PASS |
| First/third-person camera switch and avatar visibility | PASS |
| Camera retracts at screen and clears geometry from a traversable probe | PASS |
| Side wall blocks movement and floor stays stable | PASS |
| Visible GLB mesh geometry | PASS, finite data and zero zero-area triangles |
| Roof collision metadata | REVIEW: 64 zero-area faces of 2432; no observed failure in tested routes |
| Supplemental gameplay contract/camera checks | 18 PASS / 0 FAIL |
| Dispatched keyboard events / launch scene / gallery return | 7 PASS / 0 FAIL |
| Native source saved and reopened | 7 PASS / 0 FAIL |
| Final restart/import | PASS, clean `restart-clean.log` |
| Cache-free independent copy import and rendered run | PASS, 21 checks; separate output folder; no original assets/cache/symlinks used |
| Human keyboard/mouse rehearsal | NOT TESTED |
| Target low-end hardware, populated world, future player and exported executable | NOT TESTED |
| Town fit/road/neighbor compatibility | Not applicable to current source; no active town exists |

Earlier construction-stage issues were resolved before visual approval: a camera probe inside furniture was moved to a clear standing position; collapsed visual triangles were removed; native audit counted used mesh materials; duplicate baseline import IDs and transient import warnings were resolved. Current verification did not rebuild or alter the approved visual assets.

**Current remaining issue:** a separate audit of the approved roof collision metadata found 64 zero-area triangles among 2432 roof collider triangles. All positions are finite, and the 195 authored simple collision shapes and traversal/camera checks pass. Degenerate faces contribute no surface; no associated runtime failure was observed. They were left unchanged to preserve the exact approved state during this verification. Before integration, remove only those redundant collider faces (and make the authoring exporter filter them), then retest movement/cameras and assert visible GLB/native-source hashes are unchanged. This is collision-data cleanup, not a roof redesign. [Collision-data audit](collision-data-audit.json).

No major gap or unintended primary beam/roof intersection was found in inspected screenshots; exhaustive self-intersection analysis was not performed. Human playtesting, target-device performance, sustained thermal/stutter behavior, exported executable and production-player/populated-world integration remain unperformed. Clean-copy import and rendered test evidence live under `verification-2026-10-22/`.

**Decision: Do not expand yet. Visual direction is approved.** Preserve the approved model and original high-detail assets. The next useful work is a human walkthrough and measurements on intended low-end hardware, followed later by separately authorized production-player/populated-world integration. [Claude handoff](../HANDOFF.md) records the exact next action and remaining unperformed tests. No additional facility conversion is authorized by this result. Current independent-copy verification and approval-resource hashes are under `verification-2026-10-22/`.

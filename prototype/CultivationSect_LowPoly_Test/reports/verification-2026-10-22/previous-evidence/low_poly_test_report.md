# Main Sect Hall low-poly experiment

22 October 2026. Built the original **Split-Cloud Hall** in a separate independently runnable Godot project. The Main Hall alone was rebuilt; this is a controlled asset experiment.

Original project: `C:\Users\pasto\OneDrive\Documents\ChatGPT\Character Sprite Image for Thesis game\prototype\asset-workshop`. Test project: `C:\Users\pasto\OneDrive\Documents\ChatGPT\Character Sprite Image for Thesis game\prototype\CultivationSect_LowPoly_Test`. **Original unchanged:** SHA-256 hashes match for all 1,599 recorded original non-cache files. [Preservation audit](preservation-audit.json). Recovery: `../original_runtime_recovery.zip`; baseline resources: `../baseline/hall`. Other three facilities' non-import resources match the original; copied inspection-controller and door-mechanism scripts are byte-identical. No original town exists in this active workshop; no Reedwell assets, town placement, map or future player was imported.

## Design and implementation

The nine supplied reference images informed jade roofs, warm timber, pale stone/plaster, economical facets and ceremonial scale. Geometry was newly authored without importing the old visual meshes or copying a pictured building. [Original concept](BUILDING_DESIGN.md), [style guide](LOW_POLY_STYLE_GUIDE.md). Refinement after first rendered review muted the roof, introduced the folded front-facing cloud canopy/mountain tympanum and improved blank partition walls.

The model has articulated podium/stairs/rails, six roof masses, faceted columns with interlocked brackets, real window screens, exposed nave ties/trusses, warm lanterns, six elders' seats, leader throne/dais/mountain screen and two accessible furnished rooms. Editable Blender source: `../source/split_cloud_hall.blend`; complete authoring program: `../tools/build_split_cloud.py`. Native reopen audit: 7 PASS / 0 FAIL. [Export geometry audit](geometry-audit.json) checks finite positions, valid indices, opaque embedded materials and zero-area triangles for all four GLBs.

Root/podium/facing/door clearances and all original non-roof collision shapes are preserved. Roof collision was rebuilt from actual new soffit triangles to follow the simplified roof and folded canopy. New bounds [P: (-20.82926, 0.0, -12.0), S: (41.65852, 18.22064, 30.18)] remain inside the old envelope [P: (-20.84177, 0.0, -12.0), S: (41.68354, 18.31, 30.18)]. Differences in tiny eave/crest extrema reduce the bounds slightly; there is no footprint expansion or height increase. No new floor, balcony, world position or inaccessible room was introduced.

Standard shared opaque materials, no image textures/custom shaders/plugins/downloaded assets, no added real-time lights, no renderer switch. 12 near static surfaces; same cheap mesh in the existing distance range. [Settings and measured comparison](performance_comparison.md). Static geometry 64.8% fewer triangles; final matched local mean frame times improve across all six tested views. Low-end hardware remains unverified. Texture-only and geometry-only contributions were not separately measured.

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
| Supplemental gameplay contract/camera checks | 18 PASS / 0 FAIL |
| Dispatched keyboard events / launch scene / gallery return | 7 PASS / 0 FAIL |
| Native source saved and reopened | 7 PASS / 0 FAIL |
| Final restart/import | PASS, clean `restart-clean.log` |
| Human keyboard/mouse rehearsal | NOT TESTED |
| Target low-end hardware, populated world, future player and exported executable | NOT TESTED |
| Town fit/road/neighbor compatibility | Not applicable to current source; no active town exists |

The supplemental probe initially teleported the capsule into the leader furniture and its camera-overlap query failed. The probe was corrected to a clear standing position beside the chair; camera code was unchanged. This is not a claim that every possible camera orientation was tested. Geometry auditing found 128 collapsed triangles at hip-roof ridge tips; they were removed after triangulation, and the final mesh was reimported, measured and captured again. Native auditing now counts the 12 mesh materials actually used rather than an unused startup material datablock. Earlier duplicate baseline UIDs were corrected; an intermediate import MD5 read warning did not recur on clean restart. Blender could not write its optional external thumbnail in the sandbox; the saved source reopened and exports validated successfully. No major gap or unintended primary beam/roof intersection was found in the inspected final screenshots; exhaustive self-intersection testing was not performed.

**Decision: Do not expand yet.** This isolated local result is promising. First have the user review the design, then measure on intended low-end hardware and later in the actual integrated world with its production player. Preserve this test and baseline for comparison. [Claude handoff](../HANDOFF.md) records the exact state and remaining work. No additional facility conversion is authorized by this result.

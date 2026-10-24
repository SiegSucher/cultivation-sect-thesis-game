# Phase 4C focused mountain-profile revision

Ready for visual review. **Phase 4C remains unapproved; Phase 4D has not begun.** This revision changes only the mountain profile, its outer ground blend, and the height of existing distant pines affected by that terrain.

## Launch and compare

Double-click [Launch Phase 4C.cmd](../../Launch%20Phase%204C.cmd), or run `res://phase4c/phase4c_valley.tscn` with F6 in the working test project. WASD moves, mouse looks, Tab switches first/third person, V opens the valley overview and R returns to the forest start. Key 5 reaches the Hall review stop; the healing overlook is at world `(143, 10, -46)` via the garden's east branch.

Matching 1280 × 720 captures use the same camera placement, orientation, inherited lighting and scene settings before/after. Gameplay views were the primary composition checks:

| View | Comparison | Revised capture |
|---|---|---|
| Healing overlook, third person | [Before/after](comparison-healing-overlook.png) | [After](after-healing-overlook.png) |
| Main Hall approach, third person | [Before/after](comparison-hall-approach.png) | [After](after-hall-approach.png) |
| Valley overview | [Before/after](comparison-valley-overview.png) | [After](after-valley-overview.png) |

The healing camera starts at `(143, 10.12, -46)`, yaw 90°; the Hall camera at `(12, 24.12, -49)`, yaw 0°. Both settle onto the same unchanged ground. The overview uses the existing valley camera. Raw `before-*.png` and `after-*.png` remain beside these comparisons; images were only paired and labeled, without retouching.

## Shape change and preserved ground

The previous mountain formula combined separate radial peaks, producing repeated cone footprints. A winding crest now connects the western and eastern ranges through a lower northern saddle. Unequal flank widths, offset summits, varying crest heights and four lateral spurs produce broad shoulders and irregular slopes. The lower opening behind the Hall remains, with the higher summits off its principal roof axis. The existing faceted mesh, materials and grid resolution are retained; no fine noise or new rock assets were added.

The reviewed terrain remains exactly unchanged inside `x = -156…156 m`, `z = -170…190 m`, which contains the occupied shelves, courts, stairs, routes and support assemblies. Outside this envelope, a smooth 48 m transition blends the new profile into the existing ground. No building foundation terrain was reached, so foundation ray checks were not repeated.

Planning remains **320 × 400 m**, terrain extent **640 × 720 m**, and the designed main route **242.97 m**. Layout data, building transforms, court dimensions, occupied terrace elevations, stairs, corrected fitting helper, retaining walls, guardrails, walking ramps, scene, launcher and player/camera settings are unchanged. All changes are within `phase4c/`; the compact baseline, large map, Phase 4A and canonical/staged assets remain intact.

## Checks actually performed

- Rendered launch plus all three requested captures: **4 pass / 0 fail** before, **4 pass / 0 fail** after. The three revised views were visually inspected by the agent.
- Continuous forest → Gate → living → Hall physical walking, separately in third and first person: **19 focused checks passed**. Measured distance **242.80 m TPP / 242.82 m FPP**, each **62.78 s active walking** at the existing 4 m/s; 64.78 s including waypoint settling. No jumps or teleports were used between main-route landmarks.
- **5 data checks passed:** unchanged terrain topology/extent; all **218,571 occupied-envelope vertex entries identical** to the snapshot; only vertical terrain coordinates changed; visible/physical ground agrees; all **1,440 existing mountain pine instances** retain count, horizontal position, rotation and scale. **1,416** were seated vertically on the revised backdrop; none were added.
- [Fresh preservation comparison](preservation.json): **6,176 pre-existing project files checked**, no changes outside `phase4c/`, none missing. This includes unchanged stairs, fitting helper, safety assembly, paths and protected baseline files. Evidence: [walking](walking.json), [geometry comparison](unchanged-geometry.json), [after captures](after-captures.json).

These are automated traversal checks and agent screenshot inspection, **not human playtesting or visual approval**. No full gallery, stair/rail suite, branch-route suite, export or performance assessment was repeated. The headless engine's host certificate-store warning did not prevent traversal.

## Changed files and recovery

- Added `phase4c/mountain_profile.gd` and `rebuild_mountain_profile.gd`; updated `terrain_builder.gd` and its reproducible preparation recipe, `prepare_sources.py`.
- Updated only `resources/terrain_mesh.res`, `terrain_collision.res` and six `resources/Mountain_pine_*.res` batches. Roads, ramps and safety resources were not rebuilt.
- Added this review folder's snapshot, focused checks, results and captures; linked this review from the Phase 4C README and original review report.

[phase4c-before-mountain-profile.zip](phase4c-before-mountain-profile.zip) preserves the entire prior Phase 4C payload using project-relative `phase4c/` paths; [before-hashes.json](before-hashes.json) records the pre-edit files. For recovery, close Godot and extract the required archived files into the working project root. The archive contains the previous source, generated terrain, tree batches and scene; recovery does not depend on Git. Existing earlier review evidence is retained.

Remaining limits: the backdrop is a low-poly heightfield with deliberately broad faces and some steep joins between ridge shoulders. Composition has been checked from the requested views, not every possible viewpoint. Existing selective-guard coverage and missing arrival railing variants remain as previously documented; no railing variants or decoration were added.

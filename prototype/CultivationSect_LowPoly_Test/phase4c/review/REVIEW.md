# Phase 4C — Compact valley terrain refinement

Ready for human visual review. The compact Phase 4B scale and arrangement are approved; **Phase 4C visuals remain unapproved**. No Phase 4D work was started.

**Latest integration:** [Exact-pitch arrival-stair rails, focused checks and captures](arrival-rails/REVIEW.md). This completes the missing arrival-rail request recorded below. The revised mountain profile is retained. Earlier counts/results below describe the initial Phase 4C assembly.

**Latest revision:** [Focused mountain-profile report and matching gameplay comparisons](mountain-profile/REVIEW.md). The original Phase 4C evidence below is retained as history; its cone-like backdrop has been revised.

## Launch

Double-click [Launch Phase 4C.cmd](../Launch%20Phase%204C.cmd), or run `res://phase4c/phase4c_valley.tscn` with F6 in this test project. WASD moves, mouse looks, Tab switches first/third person, M opens the map, V shows the valley, and R returns to the forest start. Review jump keys remain inherited, but traversal checks used continuous walking between landmarks.

## Preserved baseline and dimensions

The new scene inherits `mountain_valley_compact/compact_valley.tscn` and reads its unchanged layout data. Planning remains **320 × 400 m**, within the same **640 × 720 m** terrain/backdrop extent. All twelve building transforms, district locations, court dimensions and terrace elevations remain unchanged. Player/controller/camera sources and settings were not edited. The approved smooth walking-ramp collision is inherited exactly.

The designed main route remains **242.97 m**. Automated physical traversal measured **242.80 m / 62.78 seconds of active walking** in each camera mode, at the existing **4 m/s** speed. The fixture elapsed time was 64.78 seconds, including waypoint settling. No sprint, speed increase or travel shortcut was introduced.

## Terrain and route changes

- Replaced the rounded backdrop profile with unequal flanking peaks, shoulders and a lower northern saddle. The Hall remains readable from the principal approaches; its roof axis has no central peak directly behind it.
- Broadened and varied exterior terrace shoulders, retaining exposed natural rock faces. Protected foundation envelopes and usable courts remain level. Selected retaining cuts blend back into natural terrain rather than wrapping entire districts in walls.
- Added four 16 m retaining runs at selected Hall/living terrace edges and two connected 12 m overlook edges. Existing staged end/corner pieces and coping-mounted rails follow the kit's connection conventions.
- Gave visible treads contrasting risers and thin pale nosings. Widened the existing stair-to-terrain fitting clearance to accommodate solid stone side supports. Added matching sloped rails on the living, cloud and grand stairs, plus selected landing guards. No overlapping endpoint slabs were added; inherited walking ramps remain unchanged.
- Reseated existing provisional props and mountain-tree batches vertically on the changed terrain. Their horizontal placements, numbers and scales were retained; no planting or furniture pass was performed.

The safety-kit GLBs lacked ready engine imports in this working project. Phase-local Godot imports and scene adapters preserve their models and staged collision definitions; only the model resource references change. Canonical staging files were not edited, regenerated or stretched. All **146 kit instances** retain unit scale and upright posts.

## Measured pitches and missing pieces

| Connection | Rise / horizontal run | Actual slope | Treatment |
|---|---:|---:|---|
| Arrival | 4 / 11 m | 19.983107° | Stone cheeks and level upper landing rails; no mismatched sloped rails |
| Living | 6 / 15 m | 21.801409° | Stock 22° modules |
| Cloud | 6 / 15 m | 21.801409° | Stock 22° modules |
| Grand/Hall | 8 / 18 m | 23.962489° | Stock 24° modules |
| Training branch | 4 / 19.416488 m | 11.640676° | Existing route retained; no sloped rail installed |
| Scholar branch | 4 / 22.360680 m | 10.142106° | Existing route retained; no sloped rail installed |
| Alchemy branch | 4 / 24.083189 m | 9.430225° | Existing route retained; no sloped rail installed |

Each installed sloped section is anchored independently to the actual grade. Nominal end-height differences are at most **8.05 mm per 2 m** for 22° and **1.57 mm per 2 m** for 24°, within the kit's stated slope tolerance; they do not accumulate along flights. No posts were tilted.

**Focused Claude follow-up:** arrival needs 1 m and 2 m horizontal-span railing variants at **19.983106522°** (rise/run **4/11**). Required local +X endpoint rises are **0.363636364 m** and **0.727272727 m**, with vertical posts and the existing leading-post/terminal-post convention. Five 2 m sections plus one 1 m section per side would cover the 11 m flight. A nominal 20° pair differs by only 0.667 mm per 2 m, but exact pitch is specified here. These pieces have not been generated. Other branch slopes above would require their own variants and measured terminal lengths if later selected for guards.

## Checks actually performed

- **61 automated headless checks passed:** continuous forest → Gate → living → Hall walking in both camera modes; representative scholar/library, alchemy, garden and training connections; downhill arrival/living/grand stairs at representative side positions; 48 terrain-only foundation samples across all twelve measured building envelopes; five outward movement probes at new guarded assemblies.
- **16 rendered checks passed:** launch, Tab switching, living stair uphill in third person/downhill in first person, map/resume, and six screenshots. The approved baseline was separately captured with 13 successful checks.
- **9 focused support checks passed:** twelve building transforms match baseline, walking-ramp faces match exactly, visible/physical terrain agree within 0.054 mm of mesh storage precision, unit-scale/yaw-only kit placement, and five waist-height ray checks hitting actual rail collision. Movement probes can also contact supporting stone or retaining collision; the separate rays distinguish rail collision from those lower supports.
- Fresh SHA-256 comparison: **6,050 pre-existing test-project files, 1,599 original-project files and 196 historical 2D-map files unchanged**, with none added or missing outside `phase4c/` (engine caches excluded). Eleven phase-local import adapters differ from their staged scenes only in the model reference. See [preservation-results.json](preservation-results.json).

These are automated traversal and agent screenshot inspections, **not human playtesting or visual approval**. No exhaustive gallery suite was run. The headless engine reports a host certificate-store warning; scene/traversal checks complete successfully.

## Matching captures

Same camera positions, orientation, resolution and inherited lighting were used on both versions:

- [Gate approach](comparison-gate-approach.png)
- [Living terrace](comparison-living-terrace.png)
- [Inner stairs](comparison-inner-stairs.png)
- [Hall approach](comparison-hall-approach.png)
- [Valley overview](comparison-valley-overview.png)
- Additional [guarded overlook gameplay view](after-guarded-overlook.png)

Original captures remain alongside the comparisons as `before-*.png` and `after-*.png`. The baseline's old “UNAPPROVED” HUD text was left intact; the user's subsequent approval governs its layout status.

## Changed files and recovery

All additions are under `phase4c/`: `phase4c_valley.tscn`, launcher/README, `walkthrough.gd` (inherited HUD text), `terrain_builder.gd`, `focused_stair_terrain.gd`, `retaining_terrain.gd`, `terrain_sampler.gd`, `safety_assembly.gd`, `import_kit.gd`, build/preparation scripts, generated `resources/`, and review checks/evidence. `resources/path_collision.res` is a builder byproduct; the scene continues using the approved inherited ramp collision.

[approved-compact-recovery.zip](approved-compact-recovery.zip) preserves the compact source/resources/launcher and key review records without relying on Git. [before-hashes.json](before-hashes.json) records the protected payload. The existing compact, large-map and Phase 4A launchers/resources remain intact.

## Remaining limits

The arrival flight awaits its matching railing; guards are selective, so other cliff edges and branch stairs remain unguarded. Terrain remains intentionally faceted prototype geometry, with broad natural faces and sparse existing dressing. No production safety certification, exhaustive edge testing, export/device or performance assessment was performed. No new scenery assets, boundary walls, signs, gameplay systems or general decoration were added. Human review of terrain composition, wall placement and railing joins is the next step.

# Mountain-valley video review and polish

24 October 2026. Applied to the separate `CultivationSect_LowPoly_Test/mountain_valley` map. Launch **View Polished Mountain Valley.cmd** beside this report, or use the existing **View Mountain Valley Blockout.cmd** in the thesis workspace. Close any older running instance first so it loads the updated scene.

## Stair problem

The recording shows dark, floating slabs across the upper portions of the arrival and living-district stairs. The map builder capped route endpoints with horizontal circular surfaces. At the top of a stair these extended backwards over the rising flight, creating the apparent obstruction. Flat adjoining routes also created the same overlap.

The builder now omits endpoint caps wherever a sloped segment joins, including caps belonging to adjacent flat paths. The steps and existing smooth walking ramps remain. Matching before/after game screenshots show the dark slabs removed.

The obstruction was confirmed visually. A physical movement blockage was **not reproduced**: the original scene already passed 30 crossings at five lateral positions across three principal flights, in both directions. The final scene also passed those rendered crossings. This does not certify every possible approach or off-route location.

## Environment changes

- Added narrow stone route borders, paving joints and courtyard perimeter inlays.
- Added lanterns alongside stair routes, outside the walking lanes.
- Added irregular planted islands with existing pines, bamboo, shrubs, grasses and rock clusters, plus small bench pockets. The new dressing comprises 514 scene children including batched paving groups.
- Changed paving to a more muted stone palette and updated the scene's review label.
- Preserved the twelve canonical building placements and scales, 520 × 640 m planning envelope, existing architecture, Phase 4A, player/controller and normal walking settings.

Repeated paving is batched to reduce drawing overhead. The narrow border stones are visual accents without separate collision. Existing environmental props retain their supplied collision. No new gameplay or production-player integration was added.

## Verification

- Final district-route check: **59 PASS / 0 FAIL**, approximately **3,007.5 m** traversed, all twelve exterior building approaches reached, plus return routes and overlook.
- Rendered launch, camera switching, map/resume/reset and captures: **18 PASS / 0 FAIL**.
- Stair-width check: **30 PASS / 0 FAIL** in the rendered game; baseline also **30 PASS / 0 FAIL**.
- Preservation against the prior map's recorded baseline: **5,772 test-project files, 1,599 original-project files and 196 old-map files unchanged**. These counts cover the pre-map baseline, not every file added by later unrelated work. See `preservation.json`.

The first accelerated route run passed traversal but failed two input checks (Tab restore and map open). Its evidence is retained as `initial-accelerated-results.json`. Moving input checks back to normal timing resolved both; the final run passed all 59 checks. Runtime player/camera code was not changed for this.

## Review images and controls

- `arrival-stairs-comparison.png`: matching before/after view of the stair obstruction.
- `hall-court-comparison.png`: matching before/after courtyard and planting.
- `after-living-court.png`, `after-living-stairs.png`, `after-garden.png`: additional game captures.
- WASD/mouse movement; Tab first/third person; M map; V valley overview; R forest start; 2 Gate; 3 Living; 4 Training; 5 Hall; 6 Garden; 7 Library; 8 Alchemy; E nearby doors.

## Limits and recovery

This is an initial environment polish pass. Broad distant slopes and cliffs still use the coarse blockout terrain, the pond remains simple, and the inspection avatar is unchanged. Full interiors, every off-route edge, target-device performance and human acceptance remain unverified. Unguarded cliff areas still exist.

The map folder before edits is preserved at `C:\Users\pasto\Documents\Codex\2026-10-24\i-want-you-to-conti\work\before-valley\mountain_valley`. Restore that folder only for an intentional rollback. Canonical building assets were not rebuilt or replaced.

Main edited sources: `mountain_valley/terrain_builder.gd`, `build_map.gd`, `valley_walkthrough.gd`; added `environment_polish.gd`, `review_stairs.gd`, `smoke_polish.gd`. The map scene and baked map resources were regenerated. The new report is mirrored under `reports/mountain-valley-polish/`.

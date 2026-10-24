# Compact mountain-valley proposal layout — Phase 4B

24 October 2026. **Ready for human visual review, not approved.** All new work is under `mountain_valley_compact/`. The existing large map, its corrected stairs/resources and launcher remain intact. A [large-map recovery archive](large-map-recovery.zip) and [before-file manifest](before-hashes.json) provide recovery independently of Git.

## Launch

Double-click **`mountain_valley_compact/Launch Compact Valley.cmd`**, or open the test project's `project.godot`, select **`res://mountain_valley_compact/compact_valley.tscn`**, and press **F6**. F5 and the old launchers retain their previous targets.

WASD/mouse move/look; Tab first/third person; M map/resume; V valley overview; R forest start; Esc gallery. Keys 2–8 remain inspection shortcuts. **The timed route was walked continuously without teleportation or changing the 4 m/s controller.**

## Actual size and travel comparison

| Measure | Large map | Compact revision |
| --- | --- | --- |
| Playable planning envelope | 520 × 640 m | **320 × 400 m**, X −160…160 / Z −180…220 |
| Mountain backdrop | 1,120 × 1,120 m | **640 × 720 m** |
| Forest → Gate → living → Hall route | 586 m | **242.97 m planned; approximately 242.8 m measured** |
| Ideal walking time at 4 m/s | 147 sec | **60.7 sec** |
| Actual automated active walking | Earlier large run not timed this way | **62.85 sec first person / 62.80 sec third person** |
| Highest occupied shelf | +56 m | **+28 m**, with Main Hall at +24 m |

The planning area is approximately **62% smaller** and the main route **59% shorter**. A suggested tour visits Gate, living court, Training, Main Hall and Scripture: approximately **599 m of walking plus 95 seconds of selected presentation stops**, or **about 4.1 minutes**. This is a route-based estimate, not a human rehearsal. [Tour calculation](proposal-tour.json).

## Recomposition and building scale

The twelve live building scenes were remeasured before placement. No architecture was resized: Training remains **68 × 57.2 m**, Hall **41.66 × 30.18 m**, and every building root stays scale 1. [Live measurements](asset-measurements.json).

- A short winding forest trail reveals the Gate on a +4 m arrival terrace.
- Mission, Exchange, Disciples' Residence and Dining share a +10 m living court and an 8 m street, with 6 m entry lanes.
- Training occupies a separate +14 m western shelf reached by a short branch from that street. Its full existing equipment court fits without overlap.
- The central approach climbs through +16 m to the Main Hall at +24 m. Its **48 × 30 m forecourt** is generous relative to the full-size Hall without the previous long empty approach.
- Scripture and Elder Residence share a +28 m scholarly ledge; Alchemy occupies its own +20 m ridge. Medicine, Herb Garden, pond and overlook form the +10 m eastern healing district.

Principal stairs retain 12–16 m widths; main routes are 10 m, the forest trail 7 m and the overlook path 5 m. Rise lengths and heights were recomposed instead of scaling the old world. The corrected terrain fitting now handles rotated sloped connections, locally refines ground under the stairs, and omits overlapping endpoint caps.

This was not a decoration pass. **67 existing provisional props and 480 existing mountain pines** were retained/repositioned at scale 1. Obsolete long-route paving/border batches were not carried into the compact copy. No new prop type, asset, wall/guardrail kit or decorating recipe was introduced. The large version keeps all its dressing. [Retained-instance record](build-summary.json).

## Focused checks and fixes

The final focused walking run passed **71 checks / 0 failures**: continuous main route in first and third person, district connections and clear exterior approaches to all twelve buildings, representative downhill stair lanes, map/resume and 48 terrain-only ground samples under measured building envelopes. [Walking results](walking-results.json).

Initial checks found uneven foundation support at four envelope edges and a garden lane cutting the Medicine Hall's front corner. Flat support margins were widened to cover the coarse grid, and the lane now wraps around that corner. The final samples sit approximately **1.5 cm below building ground origins**, with no sampled unsupported or buried corner. Initial failing evidence is retained.

The rendered check passed **18 / 0**, covering launch, camera switching, ordinary arrival-stair traversal and screenshots. [Rendered results](rendered-results.json). No exhaustive gallery/interior audit, gameplay system, asset regeneration, LOD, wind, sprint or production optimization was added. These are automated checks and inspected captures; **human visual approval remains pending**.

## Review deliverables

- [Labeled top-down plan and gold demonstration route](layout-plan.png); [top-down game capture](06-top-down.png).
- Gameplay: [Gate arrival](01-gate-arrival.png), [living district](02-living-district.png), [Training connection](03-training-connection.png), [Main Hall approach](04-main-hall-approach.png).
- [Compact valley overview](07-valley-overview.png), [inner stairs](05-inner-stairs.png), [healing overlook](08-healing-overlook.png).

Independent files: `layout.json`, `compact_valley.tscn`, `resources/`, `valley_walkthrough.gd`, `terrain_builder.gd`, `focused_stair_terrain.gd`, `build_map.gd`, the launcher and review/support scripts, all inside this compact folder. [Preservation check](preservation.json) covers existing test files, the original project, historical 2D map and old launcher. Two unfinished safety-kit staging files changed during the run: its verifier script and Blender source. This task does not use or write that kit; the observed unrelated drift was recorded and left untouched. All other protected pre-existing files match. [Runtime dependency check](runtime-dependencies.json) confirms the compact scene/resources have no large-map dependency.

## Remaining limits

Terrain is still a coarse proposal blockout with unguarded cliff edges and a simple opaque pond. Some stairs show broad riser faces from low viewpoints. Only representative routes/exterior approaches and foundation samples were checked; full interiors, every off-route slope, export and target-device performance remain unverified. The headless host certificate diagnostic persists. Tour stop durations are estimates. **Stop at compact Phase 4B visual review; no approval or Phase 4C is implied.**

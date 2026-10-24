# Phase 4B — focused stair and terrain revision

24 October 2026. **Ready for visual review; Phase 4B is not approved.** No Phase 4C work or additional decoration was started. The previous paving, borders, lanterns and planting were inspected and retained without treating them as approved.

## Confirmed findings and changes

| Issue | Finding and action |
| --- | --- |
| Dark slabs in the recording | The earlier horizontal endpoint caps extended backwards across the upper flights. Their removal was already present in the current scene. Fresh views and checks against the actual path mesh confirm no overhanging cap on the arrival or living stair. This revision did not repeat or undo that change. |
| Possible movement blockage | **Not reproduced.** Before and after, the existing controller traversed both flights uphill/downhill in first and third person at centre and X = ±4.5 m. No side-wall/prop contacts were recorded. No stair ramp, controller, camera or prop collision was changed. |
| Terrain hiding outer steps | **Reproduced visually and measured:** the 4 m terrain triangles rose through the outer treads by up to **0.62 m arrival / 0.83 m living** at X = ±5.5 m. Only the narrow adjoining ground strips were refined to 1 m and lowered beneath the existing stairs, with a short blend into the landings/shoulders. The five sampled lanes now have no terrain above their treads. |
| Previously added props | No confirmed route interference. All props, paving batches, lanterns, borders and planting retain their exact scene bytes and placements. |

The local correction splits **152 original terrain triangles**; total terrain becomes 159,080 triangles from 156,800. The existing terrain collider follows the corrected ground. This keeps visible/physical terrain aligned; it is not a new collision system or a repair of an unproven blocker. Existing smooth stair-ramp collision is unchanged. Outside the two local strips, original terrain triangles are copied unchanged and subdivided boundary edges follow the original surface.

## Changed files

- `mountain_valley/focused_stair_terrain.gd` — new reusable local fitting helper.
- `mountain_valley/terrain_builder.gd` — applies that helper during a future authorized terrain build.
- `mountain_valley/mountain_valley.tscn` — **only its terrain mesh and terrain-collision resource blocks** changed; all other scene bytes are identical.
- `mountain_valley/resources/terrain_mesh.res` and `terrain_collision.res` — matching corrected terrain resources.
- New review scripts, snapshots, logs, measurements and screenshots are contained in `reports/phase4b-stairs/`.

The full map/decorating builder was **not run**. World dimensions, terrace levels, layout data, buildings, canonical assets, Phase 4A, player/camera, original project and historical 2D map were preserved. [Preservation evidence](preservation.json), [exact scene edit check](apply-result.json), and [pre-edit map recovery archive](before-map.zip).

## Checks actually performed

- Reviewed timed samples spanning the supplied **101.7-second recording**, including arrival, stair-side and living-flight views. The contact sheet is [here](video/contact-sheet.png).
- Before editing: **24 automated crossings** covering two stairs × three lanes × two directions × two camera modes; all passed. Eight centre crossings were also exercised in the rendered game before editing.
- After editing: the same **24 automated crossings** pass at normal 60 Hz; centre crossings in the rendered game pass in both directions and both modes. Matching captures show each flight, upper transition and an oblique view of its terrain edge.
- Actual path-mesh checks confirm the old endpoint-cap slabs are absent. Terrain/tread measurements use centre, ±4.5 m and ±5.5 m samples. No full gallery suite, unrelated building/camera audit or extensive collision suite was run.

Automated movement and inspection of screenshots **are not human playtesting or visual approval**. Machine-readable results: [after traversal](after-traversal.json), [rendered run](after-rendered.json), [arrival measurements](after-arrival-geometry.json), [living measurements](after-living-geometry.json). Baseline measurements and logs are retained alongside them.

## Matching review views

- Arrival: [flight comparison](comparison-arrival-flight-tpp.png), [upper transition](comparison-arrival-upper-tpp.png), [terrain edge](comparison-arrival-edge.png).
- Living district: [flight comparison](comparison-living-flight-tpp.png), [upper transition](comparison-living-upper-tpp.png), [terrain edge](comparison-living-edge.png).
- First-person final views: [arrival flight](after-arrival-flight-fpp.png), [arrival upper](after-arrival-upper-fpp.png), [living flight](after-living-flight-fpp.png), [living upper](after-living-upper-fpp.png).

## Launch and remaining limits

Open this test project's `project.godot`, open **`res://mountain_valley/mountain_valley.tscn`**, and press **F6**. Close an older running instance first. WASD/mouse move/look; Tab switches views; **2** visits the Gate terrace, **3** the living terrace. Turn south to descend from those terraces. **R** returns to the forest start; **M** opens/resumes the map. Existing launchers still load this scene; none was edited.

Terrain outside the focused strips remains coarse, cliff edges remain unguarded, and side approaches beyond the sampled lanes are not certified. Perspective can hide upper tread tops when viewed from below; the remaining blue-grey riser faces are staircase geometry, not a floating cap. The headless engine retains its known host certificate-store diagnostic. Existing decoration and the overall map still await human approval. **Stop at Phase 4B review.**

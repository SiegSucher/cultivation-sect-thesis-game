# Split-Cloud Valley — new map and terrain blockout

24 October 2026. **Ready for scale/layout review only.** This is a separate new metre-based layout; the old 1536 × 960 pixel map is not its size or placement contract.

## Launch

Double-click **View Mountain Valley Blockout.cmd** at the workspace root. Alternatively, open `prototype/CultivationSect_LowPoly_Test/project.godot`, open **`res://mountain_valley/mountain_valley.tscn`**, then press **F6**. F5 and the existing galleries retain their current startup scenes.

Starts walking on the outer forest trail. **WASD / mouse** move/look, **Tab** first/third person, **M** map/resume, **V** valley overview, **R** return to forest start, **Esc** existing gallery. Review-only jumps: **2** Gate, **3** living district, **4** Training, **5** Hall, **6** gardens, **7** Scripture, **8** Alchemy. **E** toggles nearby Gate/Hall doors. These two entrances start open in this map instance.

## Scale and layout

Live scene inspection confirmed the existing **1.8 m × 0.56 m** player, **4 m/s** speed, 1.65 m eye and 50° maximum floor angle. All twelve canonical building scenes and all eleven staged environmental scenes were instanced for bounds inspection. The largest footprint is Training at **68 × 57.2 m**; the Hall is **41.66 × 30.18 m**, and the remaining buildings range from roughly 17–31 m wide. Full actual bounds: [asset-measurements.json](mountain-valley/asset-measurements.json).

The playable planning envelope is **520 × 640 m** (X −260…260, Z −280…360), framed by **1,120 × 1,120 m** of continuous mountain terrain. Dimensions were chosen from those footprints, broad courts, road clearance and walking distance. The connected forest-start → Hall forecourt route is **586 m**, approximately **2 min 27 sec** at the unchanged speed, before sightseeing or building exploration.

| Ground tier | District and placement |
| --- | --- |
| 0 m | Winding outer pine-forest approach |
| +8 m | Sect Gate and arrival court |
| +20 m | Mission, Exchange, Disciples' Residence, Dining/Kitchen; east branch to Medicine and Spirit Herb Garden |
| +28 m | Separate western Training terrace, with its complete existing training complex |
| +32 m | Cloud-stair landing and branching routes |
| +40 m | Alchemy ridge, separated from living streets |
| +48 m | Main Hall on the northern axis, with a 58 × 48 m forecourt |
| +56 m | Western scholarly/elder ledge: Scripture Pavilion and Elder Residence |

The 7 m forest trail leads into 10 m primary routes and 12–16 m major stairs. Local streets are 6–8 m; the cliff walk is 5 m. A continuous 4 m terrain grid joins the shelves and mountain bowl. Visible steps use smooth ramp collision, matching the existing building convention. Cliffs define district edges; routes cut broad connected corridors through them. The garden shelf includes a shallow 24 m pond and an overlook.

## Review images and resources

- **[Labeled plan](mountain-valley/layout-plan.png)** / [SVG version](mountain-valley/layout-plan.svg): districts, numbered building footprints, paths, elevations, north and metre scale.
- **[Top-down scene screenshot](mountain-valley/02-top-down-layout.png)**; **[valley composition](mountain-valley/03-valley-composition.png)**.
- **[Normal third-person Hall approach](mountain-valley/04-main-hall-third-person.png)**; [forest](mountain-valley/01-forest-third-person.png), [living street](mountain-valley/06-living-third-person.png), [garden](mountain-valley/07-garden-overlook.png), [Gate](mountain-valley/08-gate-third-person.png), [first person](mountain-valley/05-main-hall-first-person.png).

Authoritative placement data: `mountain_valley/layout.json`. Scene: `mountain_valley/mountain_valley.tscn`. Baked terrain/path/forest resources: `mountain_valley/resources/`. Scene-local controls: `mountain_valley/valley_walkthrough.gd`. All twelve canonical buildings are explicit scene instances at scale 1. All eleven approved environmental assets are reused at scale 1; modest route framing and batched mountain pines establish context without a district decoration pass.

## Verification and preservation

Focused automated route checking: **59 PASS / 0 FAIL**, reaching all twelve exterior building approaches and the overlook, including return routes and both camera modes. Final rendered launch/control/capture check: **18 PASS / 0 FAIL**, eight screenshots. After the pond adjustment, **13 garden/overlook checks passed**, including the Herb Garden's supporting ground corners: [garden-follow-up.json](mountain-valley/garden-follow-up.json). No full gallery regression, exhaustive collision suite or human playtest was performed.

Visible fixes were limited to path/stair face orientation and lighting, terrain self-shadow striping, preserving baked pine transforms with the rendered resource builder, and moving the pond clear of the Herb Garden footprint. Main routes and building placements remained stable. [Hash comparisons](mountain-valley/preservation.json) confirmed **5,772 existing test-project files, 1,599 original-project files and 196 old-map files unchanged**, including Phase 4A, approved assets, staging, settings, gallery and controller. Generated engine caches are excluded.

## Limits and stop point

This is a terrain/layout blockout: broad low-detail ground and cliff forms, sparse district dressing, unguarded cliff edges, a static opaque pond and the existing inspection avatar. Mountain pine batches are visual backdrop; nearby route trees retain supplied collision. Foliage retains its existing camera limitations. Terrain and path meshes receive building/tree shadows but do not cast shadows, to avoid distracting blockout self-shadow artefacts. Existing asset distant meshes are retained; only their map-instance visibility range extends to 600 m, and overview mode temporarily disables distance culling. Player/camera source and normal walking settings are unchanged; Medicine's camera-only collision exception is retained.

Building interiors, every off-route slope/edge, export, sustained performance and target-device operation are not certified. The headless run recorded the known host certificate-store diagnostic. No NPCs, cultivation systems, new LODs, wind or final polish were added. **Stop here until the map's scale and layout are approved.**

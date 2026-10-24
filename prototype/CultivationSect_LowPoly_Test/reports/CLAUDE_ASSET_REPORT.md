# Claude asset report

| Batch | Assets | Created | Imported into Godot | Claude's tests | Integrated by Codex |
| --- | --- | --- | --- | --- | --- |
| Exchange Hall (this update) | Contribution / Exchange Hall | Yes | Yes, in `staging/claude_exchange_hall/` | GLB audit PASS; Godot check 43 PASS / 0 FAIL; 13 rendered captures | **Not yet.** Not in the gallery and not independently verified |
| Mission Hall | Mission Hall | Yes | Yes | GLB audit PASS; 25 PASS / 0 FAIL | **Yes.** Codex reviewed it independently and made it gallery entry nine (see `reports/CODEX_REPORT.md`) |
| 2 | Alchemy Pavilion, Medicine Hall | Yes | Yes, in `staging/claude_buildings_batch2/` | 21 PASS / 0 FAIL; GLB audit PASS | **Not yet.** Not in the gallery and not independently verified |
| 1 | Disciples' Residence, Elder Residence, Dining Hall and Kitchen, Spirit Herb Garden | Yes | Yes | 22 PASS / 0 FAIL | Yes. See `reports/CODEX_REPORT.md` (canonical copies under `assets/architecture/` and `scenes/buildings/`) |

# Contribution / Exchange Hall

22 October 2026, project `prototype/CultivationSect_LowPoly_Test` (root confirmed by path and `project.godot`).
- **Read first:** the current `CODEX_REPORT.md` and `HANDOFF.md` (Mission Hall integrated), the style guide, the gallery catalog (the asset tracker), and the staging folders.
- **No duplication:** no Exchange Hall exists anywhere.
- **What was written:** everything is in a new folder, `staging/claude_exchange_hall/`, with evidence in `reports/claude-exchange-hall/`. Outside those, only this report and `HANDOFF.md` changed.
- **Not touched:** the original `../asset-workshop`, any integrated or canonical asset, the gallery files, and earlier staging (see the stray-file note below for the one temporary exception).

## What it is and how it differs from the Mission Hall

A sect treasury where disciples trade contribution tokens for supplies, cultivation resources, manuals and rewards.

The silhouette is **tripartite**:
- A tall square **exchange pavilion** under a steep four-sided pyramid roof with a bronze treasure-pearl finial (tipped with a jade spirit stone).
- Two lower **storeroom wings** under gable roofs, with verandas, either side.
- No other building in the set has this stepped low–high–low form.

By contrast, the Mission Hall is a single block whose gable end faces the front, with a forecourt of notice boards. The Exchange Hall's emblem is a bronze **square-holed coin** (the contribution token) instead of the Mission Hall's mountain. The coin repeats on the facade, the rear, both wing gables, the counter front, the reward list and the coffered ceiling.

- **Approach:** a terrace with two stone lanterns and a 5 m stair up to the main door. The door has a small tiled canopy, a `CONTRIBUTION HALL` plaque and the coin above it. Four tall **reward-list boards** of tiered exchange tablets flank the door, and there are high windows above.
- **Pavilion interior:** the hall is double-height, 7.0 m, under a **coffered ceiling** with a coin at its centre.
  - **Customer side:** a blue-grey aisle runs between two treasure plinths (a reward sword on a stand, and a cluster of spirit stones) to the **exchange counter**. The counter carries coin panels, an abacus, token stacks, a ledger and a balance. Display cabinets flank the door on the inside.
  - **Staff side:** behind the counter are two stools and three bays of **reward racks** holding manuals, glazed pill jars, spirit stones and scrolls, with a ladder. A large **reward list** above has rank-coloured tablet columns.
- **East storeroom (supplies):** crate stacks, grain sacks, barrels and a spear rack.
- **West storeroom (manuals and treasures):** two stocked bookcases, two bronze-banded treasure chests and a jade display cabinet.
- **Storeroom access:** both storerooms open off the staff side of the counter through side doors. Their door leaves swing into the storerooms, so the staff lane stays clear.
- **Verandas:** each wing has a veranda; the east one has supplies waiting and the west one has a bench.

## Files

All files are in `staging/claude_exchange_hall/`:

| Path | Purpose |
| --- | --- |
| `exchange_hall/exchange_hall.tscn` | **Scene to place.** Model, 69 collision shapes and one Label3D plaque |
| `exchange_hall/exchange_hall.glb` (and `.glb.import`) | Model: 31,346 triangles, 13 surfaces and 13 embedded palette materials (the 12 architectural colours plus SpiritHerb for spirit stones), no textures |
| `source/claude_exchange_hall.blend` (folder has a `.gdignore`) | Editable Blender source: one collection, batched by material |
| `tools/build_exchange_hall.py` | Generator: verbatim copy of the Mission Hall helpers with one change (below), plus the Exchange Hall code; writes only this folder |
| `tools/audit_glb.py` | Same standalone GLB audit used for the Mission Hall |
| `build_summary.json` | Exact bounds, counts and materials |
| `review/exchange_hall_review.tscn`, `.gd` and `.gd.uid` | Inspection scene: 1 walk/review, Tab camera, Esc gallery; `-- --capture` writes screenshots |
| `review/verify_exchange_hall.gd` and `.gd.uid` | Headless Godot check |

Both `.gd` scripts were written before the import, so the delivered file set already includes their `.uid` files and is stable (13 files).

Evidence is in `reports/claude-exchange-hall/`:
- `glb-audit.json` and `verify-results.json` (with the measured clearances)
- `import.log` and `capture.log`
- 13 screenshots

The one helper change: `window()` now also adds a collision box covering the window frame and sill depth. In earlier assets that trim sat a few centimetres outside the wall collision.

## Dimensions and scale

- **Overall:** 26.6 m (X) × 16.4 m (Z) × 13.0 m high (finial top).
  - Bounds: x −13.30…13.30, z −6.56…9.82 (stair toe at the front).
  - Origin is on the ground at the centre; +Z is the entrance.
  - Taller than the Mission Hall (9.8 m) and lower than the Hall (18.3 m) and Scripture Pavilion (18.0 m).
- **Podium:** 26.2 × 14.7 m, floor y = 0.60.
- **Front stair:** 5.0 m wide, 4 risers of 0.15 m, 0.30 m treads, toe at z = 9.8.
- **Pavilion:** walls 10 × 10 m and 7.0 m high (plate y = 7.6). The pyramid eave is at 7.75 and the apex at 11.55.
- **Wings:** walls 7 × 6.6 m and 4.0 m high, roofs to y ≈ 7.2.
- **Veranda columns:** 3.75 m high.

**Measured clearances:** ray-cast against the authored collision and against the visible meshes, at 1 m above the floor unless stated.

| Clearance | Collision | Visible geometry |
| --- | ---: | ---: |
| Main door width at the wall line | 3.20 m | 3.20 m |
| Main door width between the open leaves | open (leaves have no collision) | 3.04 m |
| Main door headroom | 3.60 m | 3.60 m |
| Headroom under the door canopy | open | 3.42 m |
| Aisle width between the treasure plinths | open to the walls | 3.53 m |
| Staff lane past the counter end | 1.34 m | 1.37 m |
| Storeroom door width | 1.60 m | 1.60 m |
| Storeroom door width between its open leaves | open | 1.44 m |
| Storeroom door headroom | 2.60 m | 2.60 m |
| Storeroom lane (front stock to back rack) | 4.98 m | 5.09 m |
| Wing veranda headroom | open | 4.34 m |
| Pavilion clear height | 6.92 m | 6.92 m |

The tightest opening is the staff lane at 1.34 m. The player is 0.56 m wide, which leaves 0.78 m to spare. The lowest headroom, 2.60 m at the storeroom doors, leaves 0.80 m above the 1.8 m player.

## Tests run and results

1. **Godot import:** `Godot_v4.7.2-stable_win64_console.exe --headless --path . --editor --import --log-file reports/claude-exchange-hall/import.log`.
   - No errors.
   - **One warning**, about a side effect: the editor scan re-created `staging/claude_mission_hall/review/mission_hall_review.gd.uid`, which Codex had deliberately removed from the frozen Mission Hall delivery.
   - A file-set comparison against my pre-task snapshot showed this scan had also created `tools/test_mission_gallery.gd.uid` and `tools/verify_mission_integration.gd.uid`. Neither existed before and all three are timestamped 22:16:15, the moment of my import.
   - I deleted exactly those three. The project file set then matched the snapshot exactly, apart from my two new folders.
   - **Codex should expect this:** any `--editor --import` run regenerates `.uid` files for scripts that lack one.
2. **GLB audit:** `python -I staging/claude_exchange_hall/tools/audit_glb.py reports/claude-exchange-hall/glb-audit.json staging/claude_exchange_hall/exchange_hall/exchange_hall.glb` gave **PASS**.
   - Exact palette colour, roughness, metallic 0 and opaque for all 13 materials.
   - No images, textures or external URIs. All positions finite.
   - 0 invalid normals, 0 non-flat triangles (exported normals) and 0 zero-area triangles across 31,346 triangles.
3. **Godot check:** `--headless --fixed-fps 60 --path . --script res://staging/claude_exchange_hall/review/verify_exchange_hall.gd` gave **43 PASS / 0 FAIL on the first run**.
   - The imported triangle count and size match the build (within 0.05 m) and it sits on the ground.
   - Every surface has an opaque, untextured material; all 13 materials are present; there are 69 collision shapes and one plaque.
   - All 12 clearances in the table pass (headroom of at least 2.1 m, width of at least 0.9 m).
   - **Eight traversal routes** with the unchanged 1.8 m, radius 0.28 m controller (`scripts/training_inspection_player.gd`), driven in **third person**:
     1. Stair → terrace → door → aisle → stops at the counter (y = 0.60).
     2. Staff lane past the counter end → reward racks.
     3. Through the side door into the east storeroom → far wall.
     4. Through the side door into the west storeroom → far wall.
     5. A front-wall reward board blocks the player.
     6. East veranda → stops at the storeroom wall.
     7. West veranda → stops at the storeroom wall.
     8. Back out through the door and down the stair to the ground.
   - On every route, every 5 frames (460 samples in all):
     - An upper-body probe (0.5–1.85 m above the feet, radius 0.24 m) was checked against trimesh copies of the visible meshes. **No hits.** First person uses the eye inside this probe.
     - The **third-person camera position** (radius 0.1 m sphere) was checked the same way. **No hits.**
4. **Rendered captures** at 1280×720 with the Compatibility renderer (`--path . --resolution 1280x720 res://staging/claude_exchange_hall/review/exchange_hall_review.tscn -- --capture`; `capture.log` has no errors).
   - Views: three-quarter, front, rear, side, third-person approach, first-person interior, third-person interior, counter and abacus, reward racks and list, coffered ceiling, east storeroom, west storeroom and east veranda.
   - I inspected all 13. I found no holes, missing materials or clipping.

## Known limitations (not claimed)

- **Not performed:**
  - Codex review or integration (not in the gallery).
  - Human playtesting or user visual acceptance.
  - FPS, frame-time or performance measurement; the triangle count is not a performance result.
  - Terrain compatibility, a navigation mesh, NPCs or a production controller.
  - Exhaustive collision or camera coverage. The routes above are samples.
- **Interaction:** decorative only. There is no exchange UI, token logic or interaction areas. Doors and storeroom leaves are static and open.
- **Collision on small details:** small items (goods, abacus, tokens, lanterns) have no separate collision. They are covered by their shelf, counter, plinth or rack volumes.
- **No LOD or distant mesh.** At 31,346 triangles this is the heaviest of my assets, but it is well under half the Hall's 71,557.
- **Access:** the 0.6 m podium is reached by the front stair only. The wing verandas sit on the same podium, and layout-time terrain decides any other approach.
- **Camera:** the pavilion's coffered ceiling is also its camera-clearance collision, at y = 7.52–7.60. The wing ceilings are at y = 4.6.

## Exact steps for Codex to review and integrate

1. **Freeze the delivery:** read this section and `staging/claude_exchange_hall/build_summary.json`, then hash the 13 files in `staging/claude_exchange_hall/`. Do not rerun any generator in place.
2. **Re-run the checks independently:**
   - The GLB audit, or your own `glb-audit` criteria.
   - `res://staging/claude_exchange_hall/review/verify_exchange_hall.gd` headless, which should give 43 / 43.
   - Your expanded route, camera and visible-mesh suites. Suggested routes: stair → door → aisle → counter; around both counter ends to the racks; both storerooms via the side doors (z = −2.4); both verandas; back out.
   - If you use `--editor --import`, expect the stray `.uid` regeneration described above and restore your frozen sets afterwards.
3. **Walk it in both camera modes:** open `res://staging/claude_exchange_hall/review/exchange_hall_review.tscn`.
4. **Copy to canonical paths:**
   - `staging/claude_exchange_hall/exchange_hall/exchange_hall.glb` → `assets/architecture/exchange_hall/exchange_hall.glb` (byte-identical).
   - `staging/claude_exchange_hall/exchange_hall/exchange_hall.tscn` → `scenes/buildings/exchange_hall.tscn`, changing **only** the `ext_resource` path to `res://assets/architecture/exchange_hall/exchange_hall.glb`.
   - `source/claude_exchange_hall.blend` → `source/claude_exchange_hall_integrated.blend`.
   - Let Godot import the copy so it gets its own UID.
5. **Add the gallery entry:**
   ```json
   {"id":"exchange_hall","name":"Contribution / Exchange Hall","group":"Buildings","status":"Claude Exchange Hall - low-poly, review pending","resource":"res://scenes/buildings/exchange_hall.tscn","model":"res://assets/architecture/exchange_hall/exchange_hall.glb","source":"res://source/claude_exchange_hall_integrated.blend"}
   ```
   Add a Walk route and an interior preset if you want them. A suggested interior camera stands at about (0, 2.4, 4.0) and looks toward (0, 2.0, −3).
6. **Record results:** re-run your regression and record the results in `CODEX_REPORT.md`. No town placement.

# Mission Hall

22 October 2026, project `prototype/CultivationSect_LowPoly_Test`. I confirmed the root by its path and `project.godot`, and found no existing Mission Hall anywhere in the project. Before starting I read `CODEX_REPORT.md`, `HANDOFF.md` and `LOW_POLY_STYLE_GUIDE.md` (including its new exported-normals rule), Codex's audit tool and the gallery code. The only asset tracker is the gallery catalog plus the reports. Nothing outside `staging/claude_mission_hall/` and `reports/claude-mission-hall/` was written, apart from this report and `HANDOFF.md`. All 6,513 files present beforehand still match their hashes (`.godot/` cache and the recovery ZIP excluded). The original `../asset-workshop` was not opened.

## What it is

A public hall where disciples receive missions, read assignments and report completed tasks. It looks unlike the other nine buildings because it is the only one whose **gable end faces the front**.
- **Roof and porch:** a plastered pediment carries the bronze Split-Cloud mountain-in-ring emblem (repeated on the rear gable) above a swept lean-to porch on six columns with brackets. A `MISSION HALL` plaque hangs between the central columns, with a mission drum on the porch.
- **Forecourt:** a balustraded terrace with an avenue of two roofed **mission boards** facing the axis. Each holds hanging tablets in four rank colours (jade, bronze, teal, pale stone) and posted notices. Two more notice boards are mounted on the front wall beside the door.
- **Interior:** open to the roof, with exposed king-post trusses.
  - A blue-grey aisle leads to a long **reporting counter** with ledgers, an official seal and token trays.
  - Behind it are two officials' desks with chairs and a returns chest.
  - A large **mission ranking board** on the back wall has columns of tablets by rank colour, a bronze header and the emblem.
  - Also: a gong, two mission-scroll racks, waiting benches by the entrance, and hanging lanterns.

## Files

All files are in `staging/claude_mission_hall/`:

| Path | Purpose |
| --- | --- |
| `mission_hall/mission_hall.tscn` | **Scene to place.** Model, collision (37 shapes) and Label3D plaque |
| `mission_hall/mission_hall.glb` (and `.glb.import`) | Model: 17,790 triangles, 12 surfaces, 12 embedded palette materials, no textures |
| `source/claude_mission_hall.blend` (folder has a `.gdignore`) | Editable Blender source: one collection, batched by material |
| `tools/build_mission_hall.py` | Generator. Batch 2's helpers copied verbatim plus Mission Hall code; writes only this folder |
| `tools/audit_glb.py` | Standalone GLB audit to Codex's criteria |
| `build_summary.json` | Exact bounds, counts and materials |
| `review/mission_hall_review.tscn` and `.gd` | Inspection scene: 1 walk/review, Tab camera, Esc gallery; `-- --capture` writes screenshots |
| `review/verify_mission_hall.gd` | Headless Godot check |

Evidence is in `reports/claude-mission-hall/`:
- `glb-audit.json`
- `glb-audit-crosscheck.json`
- `verify-results.json`, which holds the measured clearances
- `import.log`
- 10 screenshots

## Dimensions and scale

- **Overall:** 19.1 m (X) × 21.3 m (Z) × 9.8 m high.
  - Bounds: x −9.53…9.53, z −9.70…11.62 (stair toe at the front).
  - Origin is on the ground at the centre and +Z is the entrance.
  - The building is smaller than the Hall (18.3 m high) and Scripture Pavilion (18.0 m), and in scale with the 6.5–12.6 m buildings from batches 1 and 2.
- **Podium:** 19.0 × 19.8 m, floor y = 0.75.
- **Front stair:** 6.0 m wide, 5 risers of 0.15 m, 0.30 m treads, toe at z = 11.6.
- **Forecourt terrace:** about 4 m deep in front of the porch.
- **Hall walls:** 14 × 12 m on plan, 5.0 m high (wall plate y = 5.75). Ridge at y = 9.35.
- **Measured clearances:** ray-cast against the authored collision and against the visible meshes, at 1.0 m above the floor unless stated.

| Clearance | Collision | Visible geometry |
| --- | ---: | ---: |
| Main door width at the wall line | 3.00 m | 3.00 m |
| Main door width between the open leaves | open (leaves have no collision) | 2.84 m |
| Main door headroom | 3.40 m | 3.40 m |
| Porch central bay (between columns) | 2.42 m | 2.42 m |
| Porch headroom under the hanging plaque | open | 2.95 m |
| Forecourt width between the mission boards | 12.30 m | 12.64 m |
| Side passage past the counter end | 2.25 m | 2.38 m |
| Interior clear height on the aisle | 5.00 m (camera slab) | 8.42 m (to the ridge soffit) |

The player is 1.8 m tall with a 0.28 m radius (0.56 m wide), so every measured entrance and passage leaves at least 1.15 m of headroom to spare (under the porch plaque) and at least 1.69 m of spare width (the side passage).

## Tests run and results

1. **Godot import:** `Godot_v4.7.2-stable_win64_console.exe --headless --path . --editor --import --log-file reports/claude-mission-hall/import.log` gave 0 error or warning lines.
2. **GLB audit:** `python -I staging/claude_mission_hall/tools/audit_glb.py reports/claude-mission-hall/glb-audit.json staging/claude_mission_hall/mission_hall/mission_hall.glb` gave **PASS**.
   - Exact palette colour, roughness, metallic 0 and opaque for all 12 materials.
   - No images, textures or external URIs. All positions finite.
   - 0 invalid normals, 0 non-flat triangles (the *exported* normals, as the style guide now requires) and 0 zero-area triangles across 17,790 triangles.
   - Cross-check with the same tool (`glb-audit-crosscheck.json`):
     - Codex's canonical `disciple_residence.glb` passes, which agrees with Codex's own audit.
     - The batch 2 Alchemy Pavilion and Medicine Hall also pass.
3. **Godot check:** `--headless --fixed-fps 60 --path . --script res://staging/claude_mission_hall/review/verify_mission_hall.gd` gave **25 PASS / 0 FAIL**.
   - The imported triangle count and size match the build (within 0.05 m) and the building sits on the ground.
   - Every surface has an opaque, untextured material; all 12 palette materials are present; there are 37 collision shapes and one plaque.
   - All 8 clearances in the table pass (headroom of at least 2.1 m, width of at least 0.9 m).
   - Five walk routes with the unchanged 1.8 m controller (`scripts/training_inspection_player.gd`):
     1. Stair → forecourt → porch → door → aisle → stops at the reporting counter (y = 0.75).
     2. Side passage past the counter into the officials' area, reaching the back wall.
     3. The front wall and its notice board block the player.
     4. A forecourt mission board blocks the player.
     5. Back out through the door and down the stair to the ground.
   - On every route, an upper-body probe (0.5–1.85 m above the feet, radius 0.24 m) was sampled every 5 frames against trimesh copies of the visible meshes. It found **no visible geometry inside the body**.
4. **Rendered captures** at 1280×720 with the Compatibility renderer (`--path . --resolution 1280x720 res://staging/claude_mission_hall/review/mission_hall_review.tscn -- --capture`).
   - Views: three-quarter, front, rear, side, third-person approach with the 1.8 m figure, forecourt board, first-person interior, third-person interior, ranking board and officials' area.
   - I inspected them all. I found no holes, missing materials or clipping. The two-tone pediment in the front views is the roof's shadow line.

**Failures found and fixed before delivery:** the first Godot run gave 23 PASS / 2 FAIL. The upper-body probe hit two places where visible detail stuck out past its collision:
- The counter top's 10 cm overhang and its bronze front rings, at chest height.
- The rails, tablets and papers on the wall notice boards, by about 5 cm.

Both collision volumes were enlarged to cover the visible detail. No visible geometry changed. The rerun gave 25 / 25.

## Remaining issues and limits

- **Not done:**
  - Not reviewed or integrated by Codex, not in the gallery, and no independent verification.
  - No human playtest or user visual acceptance.
  - No FPS or frame-time measurement; the triangle count is not a performance result.
  - No terrain or town fit, and no navigation mesh (clearance was checked with the controller and rays only).
- **By design:**
  - The door leaves are static and stand open.
  - Small details (tablets, ledgers, lanterns, trays) have no separate collision; they are covered by their parent board or counter volumes.
  - No LOD or distant mesh exists.
  - No mission or quest gameplay, and no interaction areas for the boards or counter.
- **The terrace sits 0.75 m above the ground** and is reached only by the front stair. The forecourt balustrade is solid, so a side approach would need terrain or ramps decided at layout time.
- **The interior is open to the trusses.** An invisible clearance slab at y = 5.75–5.85 keeps the third-person camera below the tie beams.
- **The generator is self-contained.** It copies helpers rather than importing them from earlier batches, so batches 1 and 2 are never rerun.

## Exact steps for Codex to review and integrate

1. Read this section and `staging/claude_mission_hall/build_summary.json`. Do not rerun earlier generators.
2. Freeze the delivery: hash the files in `staging/claude_mission_hall/`, then work only on copies.
3. Re-run the checks independently:
   - The GLB audit, or your own `glb-audit` criteria.
   - `res://staging/claude_mission_hall/review/verify_mission_hall.gd` headless, which should give 25 / 25.
   - Open `res://staging/claude_mission_hall/review/mission_hall_review.tscn` and walk it in both camera modes. Key routes: the forecourt, the door to the counter, the side passage to the officials' area, and back out.
4. Copy to canonical paths as you did for batch 1:
   - `staging/claude_mission_hall/mission_hall/mission_hall.glb` → `assets/architecture/mission_hall/mission_hall.glb` (byte-identical).
   - `staging/claude_mission_hall/mission_hall/mission_hall.tscn` → `scenes/buildings/mission_hall.tscn`, changing **only** the `ext_resource` path to `res://assets/architecture/mission_hall/mission_hall.glb`.
   - Optionally copy `source/claude_mission_hall.blend` alongside your other integrated sources.
   - Let Godot import the copy so it gets its own UID.
5. Add a gallery entry pointing at the canonical copies:
   ```json
   {"id":"mission_hall","name":"Mission Hall","group":"Buildings","status":"Claude Mission Hall - low-poly, review pending","resource":"res://scenes/buildings/mission_hall.tscn","model":"res://assets/architecture/mission_hall/mission_hall.glb","source":"res://source/claude_mission_hall_integrated.blend"}
   ```
   Add a Walk route and an interior camera preset if you want them. A suggested interior camera target is (0, 2.6, −2.5), looking toward −Z from about z = 2.5.
6. Re-run your integrated-asset regression and record results in `CODEX_REPORT.md`. Do not place the building in a town layout.

# Batch 2: Alchemy Pavilion and Medicine Hall

22 October 2026, project `prototype/CultivationSect_LowPoly_Test` (root confirmed by path and `project.godot`). The original `../asset-workshop` was not opened.

Batch 1's staging folder and Codex's canonical copies were left untouched. Batch 1's generator was not run. Batch 2 lives in its own folder with its own builder, `.blend`, review scene and test.

## Deliverables

| Asset | Scene to place | Footprint X × Z (m) | Height (m) | Triangles | Surfaces | Collision shapes |
| --- | --- | --- | --- | ---: | ---: | ---: |
| Alchemy Pavilion | `res://staging/claude_buildings_batch2/alchemy_pavilion/alchemy_pavilion.tscn` | 17.1 × 18.0 | 12.57 | 25,586 | 13 | 43 |
| Medicine Hall | `res://staging/claude_buildings_batch2/medicine_hall/medicine_hall.tscn` | 17.8 × 14.6 | 11.00 | 20,636 | 15 | 53 |

Footprints include roof eaves and the front basins or drying racks; they are measured from the imported meshes. For comparison, the Hall is 71,557 triangles and the Scripture Pavilion is 179,436.

### Files

All files are in `staging/claude_buildings_batch2/`:
- `alchemy_pavilion/alchemy_pavilion.glb`, `.glb.import`, `.tscn`
- `medicine_hall/medicine_hall.glb`, `.glb.import`, `.tscn`
- `tools/build_claude_batch2.py`: Blender generator for both assets
- `source/claude_batch2.blend` (with a `.gdignore`): one collection per asset, batched by material
- `build_summary.json`: exact bounds, counts and materials
- `review/claude_batch2_review.tscn` and `.gd`: inspection scene
- `review/verify_claude_batch2.gd`: headless test

Evidence is in `reports/claude-assets-batch2/`: 16 screenshots, `verify-results.json` and `import.log`.

### Alchemy Pavilion
- **Silhouette:** an octagonal, double-eave pavilion.
  - A lower octagonal skirt roof on an outer ring of eight columns.
  - A main octagonal roof over tall plastered walls.
  - On top, a louvred octagonal smoke lantern with its own small roof and a bronze gourd finial (the traditional alchemy emblem).
  - This is a round, tiered, vented form. It differs from the Hall's broad rectangular hips and the Pavilion's square three-storey block.
- **Alchemy details:**
  - A three-legged bronze pill cauldron with a dark lid on an octagonal stone dais, with glowing fire mouths underneath and a bronze floor ring around the dais.
  - A smoke hood and flue rising into the louvred lantern.
  - A louvred vent band high on all eight walls.
  - Three walls of shelves holding glazed jars, plus four large storage urns.
  - Bellows, a grinding table with mortar and pestle, and the alchemist's cushion.
  - Four hanging lanterns, two bronze fire-safety water basins flanking the stair, and an `ALCHEMY PAVILION` plaque under the front beam.
- **Scale and entrance clearance:**
  - Podium octagon is 14.3 m across flats; floor y = 0.90.
  - Front stair: 3.4 m wide, 5 risers of 0.18 m, 0.32 m treads.
  - Colonnade opening: 5.1 m clear, 3.4 m under the beam. Veranda about 1.5 m deep.
  - Door: 2.2 × 3.0 m (about 2.0 m clear between the open leaves).
  - Interior: about 10 m across, 5.5 m to the wall plate. About 2.6–3.0 m of floor between the furnace dais and the shelves. The hood is 3.4 m above the floor.

### Medicine Hall
- **Silhouette:** a two-storey shopfront between stepped white fire walls (four steps each, with jade caps and upturned tips) that rise above the gable roof. It looks nothing like the Alchemy Pavilion.
- **Storing:** a back wall of five apothecary drawer cabinets (bronze knobs on a 6 × 6 drawer grid each) with jars on top, plus a three-tier jar shelf on the east wall.
- **Preparing:** a central table with a mortar, an herb cutter and a bronze balance scale.
- **Distributing:** four street-facing serving counters with propped-open shutter boards and paper herb packets, either side of the central entrance. A `MEDICINE HALL` plaque hangs under the balcony.
- **Drying:**
  - An upper loft reached by an interior stair, with three racks of round herb sieves and two lines of hanging herb bundles.
  - A front balcony with a railing and more hanging bundles.
  - Two drying racks in the front yard flanking the stair.
- **Scale and entrance clearance:**
  - Floor y = 0.45. Front stair: 6.0 m wide, 3 risers of 0.15 m, 0.30 m treads.
  - Central entrance: 2.8 m clear between columns, 3.3 m high. Covered front walkway 1.6 m deep. Counter top 1.0 m above the floor.
  - Ground-floor height: 3.35 m to the joists.
  - Interior stair: 1.2 m wide, 21 risers of 0.20 m, 0.25 m treads (about 39°), with a railed stairwell.
  - Loft: floor y = 4.2, 3.0 m to the wall plate.
  - Balcony door: 1.6 × 2.4 m (about 1.4 m clear). Balcony 1.3 m deep with a 1.0 m rail.

## Conventions, materials, dependencies
- **Same contract as batch 1:**
  - 1 unit = 1 m, +Y up, **+Z is the front/entrance**, and the origin is on the ground at the asset centre.
  - The root is an identity transform. Do not scale it.
  - Each scene contains the GLB as `Model`, a `Collision` `StaticBody3D` (layer 1, mask 2, group `solid_world`), and one `Label3D` plaque.
  - Collision shapes are boxes and cylinders, plus convex shapes for stair ramps, octagonal parts and angled walls.
  - There are no scripts, no real-time lights and no runtime staging dependencies outside each scene's own GLB.
- **Materials:** the Split-Cloud palette only, embedded in each GLB.
  - Flat-shaded and opaque, with no textures (checked in Godot: no surface lacks a material, none is textured or transparent).
  - Roughness 0.82, bronze 0.56. Emission is limited to the lantern and fire mouths, plus the spirit-herb sieves.
  - Alchemy Pavilion uses 13 materials. Medicine Hall uses 15; its Leaf, Soil and SpiritHerb (the batch 1 garden colours) are used only for dried herbs.
- **Builder:** `tools/build_claude_batch2.py` is self-contained. It carries a copy of batch 1's helper functions, extended for angled walls (`basis`/`wsolid`), `lathe()` ceramics, `prism()` and `poly_roof()`. It does not import or run batch 1's generator.

## Import / integration instructions for Codex
1. Both GLBs are already imported. Their `.glb.import` metadata is current, and the import log has no errors or warnings.
2. Integrate the same way as batch 1:
   - Copy each GLB to `assets/architecture/<id>/`.
   - Copy each `.tscn` to `scenes/buildings/<id>.tscn`, changing only the `ext_resource` path.
   - Add gallery entries.
   - Instance the `.tscn`, not the bare GLB, which has no collision.
3. Gallery entries, with staging paths. Repoint them to your canonical copies:
   ```json
   {"id":"alchemy_pavilion","name":"Alchemy Pavilion","group":"Buildings","status":"Claude batch 2 - low-poly, review pending","resource":"res://staging/claude_buildings_batch2/alchemy_pavilion/alchemy_pavilion.tscn","model":"res://staging/claude_buildings_batch2/alchemy_pavilion/alchemy_pavilion.glb","source":"res://staging/claude_buildings_batch2/source/claude_batch2.blend"},
   {"id":"medicine_hall","name":"Medicine Hall","group":"Buildings","status":"Claude batch 2 - low-poly, review pending","resource":"res://staging/claude_buildings_batch2/medicine_hall/medicine_hall.tscn","model":"res://staging/claude_buildings_batch2/medicine_hall/medicine_hall.glb","source":"res://staging/claude_buildings_batch2/source/claude_batch2.blend"}
   ```
4. Suggested walk routes for your expanded tests:
   - **Alchemy Pavilion:** front stair → veranda → door → around the furnace dais.
   - **Medicine Hall:** front stair → central entrance → shop floor; the west interior stair to the loft; the loft balcony door.
5. Rebuild command: `"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" --background --factory-startup --python staging/claude_buildings_batch2/tools/build_claude_batch2.py`.
   - It rewrites only batch 2 staging files.
   - Once you have copied batch 2, treat it as frozen like batch 1. Change the Python and re-deliver rather than rerunning it over integrated copies.

## Tests actually run (by Claude, on the staged files)
- **Import:** `Godot_v4.7.2-stable_win64_console.exe --headless --path . --editor --import --log-file reports/claude-assets-batch2/import.log` gave 0 error or warning lines. The `.godot/imported` cache matches the final GLBs.
- **Automated test:** `--headless --fixed-fps 60 --path . --script res://staging/claude_buildings_batch2/review/verify_claude_batch2.gd` gave **21 PASS / 0 FAIL** (`reports/claude-assets-batch2/verify-results.json`).
  - For each asset, the imported triangle count and size (within 0.05 m) match the build, and it sits on the ground.
  - Every surface has an opaque, untextured material; all expected palette materials are present; the collision shape count matches; the plaque is present.
  - Walks with the unchanged 1.8 m, radius 0.28 m controller:
    - Alchemy Pavilion: up the stair, through the door, into the furnace room (y = 0.90).
    - Alchemy Pavilion: the solid front wall beside the door blocks the player.
    - Alchemy Pavilion: the furnace dais blocks walking into the cauldron.
    - Medicine Hall: up the stair, through the entrance, onto the shop floor (y = 0.45).
    - Medicine Hall: a serving counter blocks entry.
    - Medicine Hall: the interior stair climbs to the loft (y = 4.20).
    - Medicine Hall: the loft door leads onto the balcony and the railing holds.
- **Rendered captures** at 1280×720 with the Compatibility renderer:
  - For each asset: three-quarter, front, rear, third-person with the 1.8 m figure, and first-person interior.
  - Plus: the furnace, the smoke-lantern ceiling, the drawer wall, the drying loft, the interior stair and the fire wall.
  - I inspected these images myself.
- **Defects found and fixed during authoring** (both before delivery):
  - The Medicine Hall podium cap stood 3 cm above the stair top and stopped the player on the front stair. The automated walk test failed and now passes.
  - Jars glazed in the Plaster colour disappeared against the plaster walls; they now use the brown Floor colour.
- **Preservation:** all 6,473 files present before this batch (excluding `.godot/` and the recovery ZIP) still match their hashes. Nothing outside `staging/claude_buildings_batch2/` and `reports/claude-assets-batch2/` was written, apart from this report and `HANDOFF.md`.

## Not done / limitations
- **Not tested:**
  - Not integrated into the gallery or canonical paths, and not independently verified by Codex.
  - No human playtest or visual acceptance.
  - No FPS or frame-time measurement; triangle counts are not a performance result.
  - No terrain, navigation or town fit. Collision coverage is not exhaustive.
- **By design:**
  - Doors are static and stand open.
  - Small props (jars, sieves, bundles, lanterns, the cushion) have no collision.
  - Neither building has an LOD or distant mesh.
  - No crafting, alchemy or shop gameplay was added.
- **Alchemy Pavilion:**
  - The front water basins sit on the ground outside the podium, so they need flat ground there.
  - The interior is open up to the roof soffit and the louvred lantern. An invisible clearance slab at y = 6.6–6.7 keeps the third-person camera inside.
- **Medicine Hall:**
  - The interior stair is steep (about 39°); it works with this controller, whose maximum floor angle is 50°.
  - The fire walls extend about 1.7 m behind the back wall to the eave line, and the front-yard drying racks stand on the ground.

# Batch 1: four staged sect buildings (integrated by Codex)

22 October 2026. Project: `CultivationSect_LowPoly_Test` (the isolated test project, confirmed by path and by `HANDOFF.md`; the original `../asset-workshop` was not opened or modified). All four assigned assets were **created, imported into Godot 4.7.2 and tested**. No world positions were chosen. Codex has since copied them to canonical paths. Use those copies, and keep `staging/claude_buildings/` frozen.

## Deliverables at a glance

| Asset | Scene to place | Footprint X × Z (m) | Height (m) | Triangles | Surfaces | Collision shapes | Status |
| --- | --- | --- | --- | ---: | ---: | ---: | --- |
| Disciples' Residence | `res://staging/claude_buildings/disciple_residence/disciple_residence.tscn` | 21.4 × 10.9 | 6.96 | 9,518 | 12 | 36 | Created, tested |
| Elder Residence (walled compound) | `res://staging/claude_buildings/elder_residence/elder_residence.tscn` | 22.6 × 22.3 | 8.05 | 16,338 | 13 | 49 | Created, tested |
| Dining Hall and Kitchen | `res://staging/claude_buildings/dining_hall_kitchen/dining_hall_kitchen.tscn` | 23.2 × 21.1 | 9.26 | 23,328 | 12 | 53 | Created, tested |
| Spirit Herb Garden | `res://staging/claude_buildings/spirit_herb_garden/spirit_herb_garden.tscn` | 24.5 × 25.1 | 6.51 | 12,474 | 13 | 37 | Created, tested |

For comparison, the approved Main Hall is 71,557 triangles across 12 surfaces. Footprints include roof overhangs and are measured from the imported meshes. Exact bounds are in `staging/claude_buildings/build_summary.json`.

## Shared conventions (all four)

- **Axes and origin:** same contract as the Hall: 1 unit = 1 m, +Y up, **+Z is the front/entrance**, and the origin is on the ground under the asset centre. The root transform is identity. Rotate and translate the root node only. Do not scale it.
- **Scale:** sized for the existing 1.8 m inspection controller (`scripts/training_inspection_player.gd`, capsule radius 0.28). Doorways are 1.2–3.0 m wide and 2.3–3.3 m high. Walls are 2.4–4.2 m tall. All stairs have ramp collision, the same method the Hall uses.
- **Style:** the approved Split-Cloud palette and treatment (`reports/LOW_POLY_STYLE_GUIDE.md`):
  - Flat-shaded, opaque, texture-free materials, roughness 0.82 (bronze 0.56). Mild emission on the lantern material only.
  - Faceted swept jade roofs with sparse 0.8 m TileLight seams, Cedar fascia and dark Timber soffits.
  - Eight-sided Timber columns on Coping pedestals, the Hall's three-course bracket sets, plaster walls on a stone dado, and window recesses with the Hall's bronze diamond motif.
  - The hip-roof function is copied from `tools/build_split_cloud.py`.
  - Each building gets its own roof type so the silhouettes stay distinct: gable (Disciples'), full hip (Elder), hip-and-gable crown plus a T-plan kitchen gable (Dining), and a near-pyramid pavilion (Garden).
- **Garden-only colours:** four colours added for planting, not used on architecture: Soil `#5d4a3a`, Leaf `#4d7d4f`, SpiritHerb `#8fe0c0` (emission 0.35), Water `#2c5f63` (roughness 0.5). The Elder Residence courtyard pines also use Leaf. Water is also used in the kitchen vats and the well.
- **Scene structure:** each `.tscn` is self-contained and visible in the editor. No script is needed.
  - `Model`: an instance of the `.glb`.
  - `Collision`: a `StaticBody3D` on layer 1 with mask 2 and group `solid_world`, the same values as the Hall. It holds authored box, cylinder and convex-ramp shapes.
  - `Plaque`: an editable `Label3D` (Hall plaque colour and settings) where the asset has signage.
- **Dependencies:** each scene depends only on its own GLB, and every material is embedded in that GLB. There are no textures, no shaders, no real-time lights and no runtime scripts. The review fixture reuses the existing `scripts/training_inspection_player.gd` without changing it.
- **Rendering:** all four use the Compatibility renderer. Lanterns are emissive meshes only; no `OmniLight3D` was added. The sun used for testing matches `scripts/gate_walkthrough.gd`.

## Per-asset detail

### 1. Disciples' Residence: `disciple_residence`
- Files: `staging/claude_buildings/disciple_residence/disciple_residence.glb`, `.glb.import`, `.tscn`.
- Form: a long single-storey dormitory under a swept gable roof that overhangs the gable ends.
  - Plastered, timber-framed gable ends carry a bronze roundel.
  - A front veranda has five columns with brackets.
  - Four rooms, each 4.4 m wide, have their own 1.3 × 2.45 m doorway with door leaves standing open.
- Levels: floor y = 0.50 on a stone podium; 3-step stair 5.8 m wide; ceiling at y = 3.9.
- Interior (each room): two sleeping platforms with mattresses and pillows, a low study table, two cushions, and front and back lattice windows. Hanging veranda lanterns.
- Materials: Stone, Coping, Timber, Cedar, Jade, TileLight, Plaster, Window, Bronze, Floor, Lantern, Fabric.
- Placement: the asset is intended to be repeated in rows. One instance houses eight disciples.

### 2. Elder Residence: `elder_residence`
- Files: `staging/claude_buildings/elder_residence/elder_residence.glb`, `.glb.import`, `.tscn`.
- Form: a walled courtyard compound.
  - A 2.2 m plastered wall with jade-tiled coping and a hip-roofed gate (2.8 m opening, `ELDER RESIDENCE` plaque).
  - A main hall on a 1.0 m podium: 6-step stair with stone cheeks, podium rail, four-column veranda, and a full hip roof with upswept corners and the Hall's bronze ridge crest.
  - A gable-roofed attendant wing on the east side, facing the courtyard.
- Main hall interior: a meditation dais and cushion in front of a jade screen with the bronze mountain-in-circle emblem; an incense table and burner; a canopy bed; a scroll shelf; a tea table with stools.
- Courtyard: a paved path, two potted pines, and a stone table with four stools.
- Levels: main floor y = 1.0, entrance 2.2 × 2.9 m; wing floor y = 0.31, entrance 1.2 × 2.3 m.

### 3. Dining Hall and Kitchen: `dining_hall_kitchen`
- Files: `staging/claude_buildings/dining_hall_kitchen/dining_hall_kitchen.glb`, `.glb.import`, `.tscn`.
- Dining hall: 20 × 9.2 m inside walls.
  - Hip-and-gable roof (hip skirt plus raised gable crown with plastered gables).
  - Six-column veranda, a 3.0 × 3.3 m main entrance and two 1.5 m side entrances, all with leaves standing open.
  - `DINING HALL` plaque hung under the veranda beam.
  - Inside: four 6 m tables with eight benches, two serving counters with rice tubs and bowl stacks, and hanging lanterns.
- Kitchen annex: 11.2 × 6.8 m, behind the hall in a T-plan.
  - Reached from the hall through a 1.6 m pass door, plus a 1.4 m east service door with its own stair.
  - Gable roof, a stone chimney rising about 4 m above the roof, and a taller stone dado.
  - Inside: a whitewashed three-wok stove range with glowing fire mouths, two water vats, a prep table with a chopping block, and a jar shelf.
  - Outside: a firewood stack and a covered well.
- Levels: floor y = 0.60; dining ceiling y = 4.8; kitchen ceiling y = 4.0.

### 4. Spirit Herb Garden: `spirit_herb_garden`
- Files: `staging/claude_buildings/spirit_herb_garden/spirit_herb_garden.glb`, `.glb.import`, `.tscn`.
- Enclosure and entrance: a 24 × 24 m garden with a stone-based timber fence and a roofed timber gateway (3.2 m opening, `SPIRIT HERB GARDEN` plaque).
- Paths and centre:
  - Cross paths meet a paved plaza ringed by a bronze formation array.
  - At the centre is a raised spirit spring holding a jade crystal (emissive).
- Seven raised beds, four planting types: ordinary herbs, jade-budded spirit herbs, golden-budded herbs and spirit grass. One bed sits under a vine trellis.
- Buildings: a near-pyramid herb-tending pavilion on a 0.5 m podium (stair, rails, bench, mortar table, jade finial) and a gable-roofed tool shed with pots, tools and a bucket. Four stone lanterns line the paths.
- Ground: the garden has no ground slab, so it sits on whatever terrain is placed later. Path slabs are 4 cm thick and visual only.

## Import / integration instructions for Codex

1. All files are already imported. A fresh checkout only needs the project opened in Godot 4.7.2, which imports the GLBs with default settings. The `.glb.import` files are included.
2. To place an asset, instance its `.tscn` (not the bare `.glb`, which has no collision) and set only the root transform. The entrance faces local +Z.
3. To add them to the gallery, append these entries to `assets/gallery/catalog.json`. That file is yours, so I did not edit it.
   ```json
   {"id":"disciple_residence","name":"Disciples' Residence","group":"Buildings","status":"Claude staging - low-poly, review pending","resource":"res://staging/claude_buildings/disciple_residence/disciple_residence.tscn","model":"res://staging/claude_buildings/disciple_residence/disciple_residence.glb","source":"res://staging/claude_buildings/source/claude_buildings.blend"},
   {"id":"elder_residence","name":"Elder Residence","group":"Buildings","status":"Claude staging - low-poly, review pending","resource":"res://staging/claude_buildings/elder_residence/elder_residence.tscn","model":"res://staging/claude_buildings/elder_residence/elder_residence.glb","source":"res://staging/claude_buildings/source/claude_buildings.blend"},
   {"id":"dining_hall_kitchen","name":"Dining Hall and Kitchen","group":"Buildings","status":"Claude staging - low-poly, review pending","resource":"res://staging/claude_buildings/dining_hall_kitchen/dining_hall_kitchen.tscn","model":"res://staging/claude_buildings/dining_hall_kitchen/dining_hall_kitchen.glb","source":"res://staging/claude_buildings/source/claude_buildings.blend"},
   {"id":"spirit_herb_garden","name":"Spirit Herb Garden","group":"Buildings","status":"Claude staging - low-poly, review pending","resource":"res://staging/claude_buildings/spirit_herb_garden/spirit_herb_garden.tscn","model":"res://staging/claude_buildings/spirit_herb_garden/spirit_herb_garden.glb","source":"res://staging/claude_buildings/source/claude_buildings.blend"}
   ```
   The gallery's `source` field and "Open source" button have not been tested with a path inside `staging/`.
4. If the assets later move out of `staging/`, move each folder in the Godot FileSystem dock so the UIDs and `ext_resource` paths update. Alternatively, change `RES` and the output folder in the build script and rebuild.
5. To edit or rebuild:
   - Change the Python, not the GLB. Source: `staging/claude_buildings/tools/build_claude_buildings.py`.
   - Run: `"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" --background --factory-startup --python staging/claude_buildings/tools/build_claude_buildings.py`
   - A rebuild regenerates all four GLBs, `.tscn` files, `build_summary.json` and `staging/claude_buildings/source/claude_buildings.blend` (one collection per asset, batched by material). The `source/` folder carries a `.gdignore`.
   - Then reimport in Godot and rerun the test.

## Tests actually run

- `staging/claude_buildings/review/verify_claude_buildings.gd` (headless; run from the project folder): `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://staging/claude_buildings/review/verify_claude_buildings.gd`. Final run: **22 PASS / 0 FAIL**. Results are in `reports/claude-assets/verify-results.json`.
  - For each asset, the imported triangle count equals the build count, the imported size matches the build size within 0.05 m, the minimum Y is 0 (sits on the ground), and the collision shape count matches the build.
  - Walk-in tests used the unchanged 1.8 m controller, driven automatically:
    - Disciples' room 2: reached at floor y = 0.50.
    - Disciples' solid wall between doors blocks the player (stopped at z = 2.43).
    - Elder Residence: through the gate, up the 6-step stair, into the main room (y = 1.0).
    - Dining: up the stair, through the hall and the pass door, into the kitchen (z = −9.9).
    - Garden: the gate is passable; the pavilion stair is climbable (y = 0.50).
- Godot `--import` of all four GLBs: no errors or warnings in the import output.
- Rendered captures at 1280×720, Compatibility renderer: `reports/claude-assets/*.png` (lineup; for each asset three-quarter, front, rear, third-person with the 1.8 m figure, and first-person interior; plus the kitchen). I inspected these myself. Two problems were found and fixed: the dining plaque was hidden behind the veranda beam, and the stove blended into the kitchen floor.
- Interactive review: `res://staging/claude_buildings/review/claude_buildings_review.tscn`. Controls: 1 walk/review; Tab first/third person; WASD/mouse to walk; 2–5 to switch asset; Esc to the gallery. Its side-by-side spacing is for inspection only and is not a layout.

**Not tested:**
- Human keyboard/mouse playtesting.
- User visual acceptance.
- Performance measurement on any hardware (only triangle and surface counts are reported).
- Placement in a town, on terrain, or with navigation.
- Exhaustive collision coverage. Small props such as lanterns, door leaves, plants and pots have no collision by design.
- The gallery entry, which was not added.
- No LOD or distant mesh exists. The Hall's "LOD" is the same mesh, and these assets are already under a third of the Hall's triangle count.

## Inspection scope and protection

- **Inspected:**
  - Docs: `HANDOFF.md`, `README.md`, `reports/LOW_POLY_STYLE_GUIDE.md`, `reports/BUILDING_DESIGN.md`, `reports/LOW_POLY_CONVERSION_INVENTORY.md`.
  - Code: `tools/build_split_cloud.py`, `tools/convert_gate_stage1.py` (palette mapping), `scripts/tang_main_hall.gd`, `scripts/gate_walkthrough.gd`, `scripts/training_inspection_player.gd`, `scripts/training_collision.gd`, `scripts/hall_experiment.gd`.
  - Data and scenes: the Hall GLB materials and `main_sect_hall.json` collision records, `assets/gallery/catalog.json`, and the building scenes.
  - Screenshots: Hall three-quarter and third-person, and the converted gate.
- **Not inspected:** I did not open Codex's `.blend` files. I did not open the Training Ground or Scripture Pavilion scenes in Godot. At inspection time both were recorded as unconverted, so they were not used as style references.
- **Missing references:** none needed for this work. The project has no town, terrain or road source, as `HANDOFF.md` notes. That blocks placement decisions only, not asset creation.
- **Files I created:**
  - `staging/claude_buildings/` (tools, source, four asset folders, review fixture, `build_summary.json`)
  - `reports/claude-assets/` (screenshots and test results)
  - `reports/CLAUDE_ASSET_REPORT.md` (this file)
  - A short status section in `HANDOFF.md`
  - Godot's own `.godot/` import cache and `uid_cache.bin` entries for the new resources.
- **Protection check:** I hashed all 3,826 pre-existing files (excluding `.godot/` and the recovery ZIP) before starting and rechecked them at the end.
  - 3,816 are unchanged.
  - The 10 that differ are the nine `assets/architecture/martial_training_ground/*.glb` files (rewritten 19:46:34–19:46:39) and `assets/gallery/catalog.json` (19:47:24, now reads "Stage 2 low-poly Training Ground"). Their `.import` files were re-saved at 19:46:54 with identical content.
  - Those timestamps match **Codex's concurrent Stage 2 work**. My scripts write only inside `staging/claude_buildings/` and `reports/claude-assets/`, and my two Godot import runs (19:44 and 19:47:18) only produced import files under `staging/`.

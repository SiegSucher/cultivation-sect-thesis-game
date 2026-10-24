# Building Scale and Visual Consistency Audit

23 October 2026 · Claude · read-only audit of the 12 integrated gallery buildings in `prototype/CultivationSect_LowPoly_Test`

This audit checks whether the buildings will read as one believable sect when walked in first and third person, before the town layout is fixed. No model, scene, script, material, collision, gallery entry or staging file was changed. This report is the only file written.

## Summary

**Verdict on scale: no building needs to be resized.** Entrances, floor heights and interior heights form a consistent rank order. Every opening is at least 1.0 m wide visibly and at least 2.30 m high, against a 0.56 m wide, 1.8 m tall player. The problems that would make buildings *feel* wrong in play are about the camera and about collision not matching the visible models, not about dimensions.

The three most important findings:

1. **The third-person camera, not the buildings, makes interiors feel cramped.** The controller's boom is 4.36 m. Inside every building, the camera is pulled in to under 1.0 m in at least one facing direction over 25–65% of the covered floor. Halls of very different size give the same result: the Main Hall shows 40% and the Elder Residence 65%. Lintels at or below about 2.6 m (dormitory doors, Elder wing door, Medicine balcony door, gate beams) also collapse the boom as the camera follows the player through. The production camera needs an interior behaviour. Enlarging rooms would not fix this.
2. **The open door leaves at main entrances have no collision in six buildings.** In Mission, Exchange (main door), Dining, Disciples', Elder and the Medicine balcony, the player's body passes through the visible leaves on the most-walked path: visible timber comes within 0.02–0.07 m of the body's centre line. Codex already gave Alchemy's and the Exchange storerooms' leaves matching boxes, so the set is inconsistent.
3. **The approved Main Hall has two collision/visual mismatches.** The visible rear-veranda columns sit about 0.4–0.5 m inboard of their preserved collision cylinders. The two administration rooms each have a desk and cushion with no collision. Fixing either is collision-only, but it touches the Hall's "preserve non-roof collision" contract, so it needs your approval.

## 1. Method and evidence labels

Every measurement was taken in Godot 4.7.2, headless, on a **scratch copy** of the project (`project.godot`, `.godot` import cache, `assets`, `scenes`, `scripts`, `addons`). Godot never opened the real project, so no import files were regenerated. Buildings were instanced from their `scenes/buildings/*.tscn` exactly as the gallery loads them, on the same ground plane the walkthroughs use. The Main Hall and Sect Gate doors default to closed, so they were opened in memory. Every other building keeps its authored static leaves. The Scripture archive gate stayed closed, because it is restricted by design.

| Label | Meaning |
| --- | --- |
| **M** | Measured by me in this audit, from the real assets |
| **S** | Authored value from the building's JSON specification (not re-measured) |
| **R** | Value from an earlier report (`CODEX_REPORT.md`, `CLAUDE_ASSET_REPORT.md`, `HANDOFF.md`); not re-measured unless stated |
| **E** | Estimate or derived ratio |

Probes used:

- **Mesh arrays:** visible bounds and triangle counts read from every mesh surface and MultiMesh instance. I cross-checked them against triangle counts parsed straight from the GLB files; all match.
- **Standing grid, 0.25 m spacing:**
  - Stacked down-rays find every collision top surface. Tops buried inside another solid are rejected.
  - At each surface, the controller's own capsule (1.8 m tall, radius 0.28 m) is tested to see whether it fits.
  - A flood fill from the surrounding ground keeps only surfaces a player can actually reach, which removes roofs and furniture tops.
  - At each reachable cell the probe records headroom against collision and against a copy of the visible meshes.
  - A visible-clip test checks an upper-body capsule (radius 0.26 m, 0.9–1.8 m above the floor) against the visible meshes.
  - It also runs the controller's own third-person camera cast in four facing directions.
- **Approach walk:** the unchanged controller walked each building's entrance axis (x = 0; for the Disciples' Residence also x = 2.2) with lateral and overhead rays.
- **Scan lines** through nine narrow passages.
- **Attribution:** each visible mesh gets its own named body, so every flagged spot can be traced to a mesh and a contact height.

I corrected two probe artifacts before trusting any number:

- Podium tops buried under 6 cm floor slabs had been read as phantom floors.
- Headless Godot does not keep MultiMesh instance transforms, which put every Scripture/Training prop at the origin. I rebuilt the transforms from each building's JSON, the same way the building scripts do.

## 2. Player reference (verified, M)

The only player in either project is the **inspection controller** `scripts/training_inspection_player.gd`. Its own header says it is "NOT the production game's player". It is byte-identical in the test project and in the original `../asset-workshop`, and all eight gallery walkthrough/review scripts load it. The gallery's "1.8 m" scale figure matches it. So the 1.8 m reference is correct for the current configuration. No production character exists yet.

| Property | Value | Note |
| --- | --- | --- |
| Collision capsule | 1.80 m tall, radius 0.28 m (0.56 m wide) | Godot 4 `CapsuleShape3D.height` is the total height |
| Visible avatar | 0.40 m wide body (radius 0.20), head radius 0.18, top at 1.80 m | 8 cm narrower than the collision on each side |
| First-person eye | 1.65 m | |
| Third-person boom | offset (0, 0.72, 4.30), so 4.36 m; 0.20 m camera sphere; 4.25 m effective maximum | At full boom the camera centre is 2.37 m above the floor and its sphere top 2.57 m |
| Movement | 4.0 m/s, floor snap 0.32 m, maximum floor angle 50° | Every stair uses ramp collision, so step height never matters |
| Camera | FOV 75°, near plane 0.05 m | |

## 3. Comparison tables

### 3.1 Size, triangle budget and collision

Width is X, depth is Z (including stairs) and height is the visible top. All values are **M** except the density column (**E**).

| Building | W × D × H (m) | Near triangles | Distant LOD | Materials | Solid colliders | Triangles per footprint m² (E) |
| --- | --- | --- | --- | --- | --- | --- |
| Main Sect Hall | 41.66 × 30.18 × 18.22 | 73,141 (hall 71,557 + six door leaves) | same 71,557 mesh (no reduction) | 12 | 202 | 58 |
| Sect Gate | 31.00 × 12.56 × 16.23 | 84,115 | 14,666 | 11 | 99 | 216 |
| Martial Training Ground | 68.00 × 57.20 × 6.73 | 107,392 (with props) | 12,913 | 13 | 188 | 28 |
| Scripture Pavilion | 23.94 × 22.62 × 18.02 | 179,436 (with furniture) | 22,248 | 12 | 243 | 331 |
| Mission Hall | 19.06 × 21.32 × 9.81 | 17,790 | none | 12 | 37 | 44 |
| Contribution / Exchange Hall | 26.60 × 16.38 × 12.96 | 31,346 | none | 13 | 73 | 72 |
| Alchemy Pavilion | 17.10 × 17.98 × 12.57 | 25,586 | none | 13 | 45 | 83 |
| Medicine Hall | 17.80 × 14.56 × 11.00 | 20,636 | none | 15 | 53 + 1 camera-only | 80 |
| Disciples' Residence | 21.40 × 10.89 × 6.96 | 9,518 | none | 12 | 36 | 41 |
| Elder Residence (compound) | 22.64 × 22.30 × 8.05 | 16,338 | none | 13 | 49 | 32 |
| Dining Hall and Kitchen | 23.15 × 21.12 × 9.26 | 23,328 | none | 12 | 53 | 48 |
| Spirit Herb Garden | 24.46 × 25.14 × 6.50 | 12,474 | none | 13 | 37 | 20 |

All twelve near models together come to about 601,000 triangles. The Main Hall JSON still lists 203,064 triangles, which is the historical pre-conversion figure; the real model is 71,557.

### 3.2 Entrances, stairs and platforms

Openings are measured at the wall line, 1.0 m above the floor, on the entrance axis. Where the two differ, I give the collision value and then the visible one. "Lintel over eye" is visible headroom minus the 1.65 m eye height.

| Building | Floor y | Front stair: risers × rise / tread, slope | Platform before door | Main opening, clear W × H | Between open leaves | Lintel over eye |
| --- | --- | --- | --- | --- | --- | --- |
| Main Sect Hall | 1.52 (dais 2.15) | 10 × 0.15 / 0.40 (M), 20.6°, 11.2 m wide (S) | terrace ≈ 6.4 m deep (M) | 6.40 × 5.39 coll / 5.33 vis (M; S 6.4 × 5.4) | 5.76 (M) | 3.68 |
| Sect Gate | 0.60 | 4 × 0.15 / 0.42 each face (M), 19.7°, 9.2 m wide (S) | passage 6.6 deep (S) | 8.40 × 7.68 / 7.62 at centre (M; S minimum 6.7 at sides) | 7.42 (M) | 5.97 |
| Training Ground | 0.31 (shelter 0.61, instructor 0.91) | 2 × 0.15 (M); instructor 4 × 0.15 / 0.40 (M) | open court | front entry 12.40 (M; S 12.0) | — | open |
| Scripture Pavilion | 1.05 porch / 1.09 hall; 5.35; archive 9.90 | 7 × 0.15 / 0.39 (M), 21°, 4.8 m wide (S) | porch ≈ 3.2 m (M) | 3.26 × 3.31 / 3.25 (M; S 3.3 × 3.35) | — | 1.60 |
| Mission Hall | 0.75 | 5 × 0.15 / 0.30 (M), 26.6°, 6.0 m wide (R) | forecourt ≈ 6.6 m, 12.30 between boards; porch pinch 2.42 (M) | 3.00 × 3.38 / 3.32 (M) | 2.84 visible only (M) | 1.67 |
| Exchange Hall | 0.60 | 4 × 0.15 / 0.30 (M), 26.6°, 5.0 m wide (R) | terrace ≈ 3.6 m, 8.65 between lanterns (M) | 3.20 × 3.58 / 3.52 (M) | 3.04 visible only (M) | 1.87 |
| Alchemy Pavilion | 0.90 | 5 × 0.18 / 0.32 (M), 29.4°, 3.4 m wide (R) | colonnade 5.12–5.15 wide under a 2.59 visible beam (M); veranda ≈ 1.5 (R) | 2.20 × 2.98 / 2.92 (M) | 2.00 / 2.04 (M, leaf boxes) | 1.27 |
| Medicine Hall | 0.45; loft 4.20 | 3 × 0.15 / 0.30 (M), 26.6°, 6.0 m wide (R) | walkway ≈ 1.6–1.8 m, beam at 2.90 visible (M) | 2.84 × 3.57 / 2.87 × 3.01 (M) | — | 1.36 |
| Disciples' Residence | 0.50 | 3 × 0.167 / 0.30 (M), 29°, 5.8 m wide (R) | veranda ≈ 2.8 m, beam 2.70 visible (M) | room doors 1.30 × 2.43 / 2.37 (M) | 1.14 visible only (M) | 0.72 |
| Elder Residence | yard 0; main 1.00; wing 0.31 | gate on grade; main 6 × 0.167 / 0.29 (M), 30° | terrace ≈ 1.9 m (M) | gate 2.58 / 2.80 × 2.54 visible; main door 2.20 × 2.88 / 2.82 (M) | 2.04 visible only (M) | 0.89 (gate) / 1.17 |
| Dining Hall and Kitchen | 0.60 | 4 × 0.15 / 0.30 (M), 26.6°; service stair 33.7° (M) | veranda ≈ 2.5 m, 3.40 visible headroom (M) | 3.00 × 3.28 / 3.22 (M) | 2.84 visible only (M) | 1.57 |
| Spirit Herb Garden | 0; pavilion 0.50 | pavilion stair (M slope 29.1°) | — | gateway 2.90 collision; visible 2.90 at 0.3 m, 3.06–3.51 at 1.0–1.7 m; beam 2.60 (M; R "3.2 m opening") | — | 0.95 |

### 3.3 Narrow interior passages

The narrowest are the Elder wing door and the Hall's side-room doors (1.01–1.20 m), still about 1.8 times the player's width.

| Passage | Clear width coll / vis (m) | Headroom coll / vis (m) | Source |
| --- | --- | --- | --- |
| Elder Residence east wing entrance | 1.20 / 1.04 between visible leaves | 2.30 / — | M (R 1.2 × 2.3) |
| Main Hall administration-room doors | 1.36 between colliding open leaves / 1.01 visible (leaf with ring pull) | 2.87 / 2.87 | M (S 2.0 × 2.8 opening) |
| Disciples' room doors | 1.30 / 1.14 between visible leaves | 2.43 / 2.37 | M |
| Medicine interior stair | 1.25 / 1.21, 21 × 0.20 / 0.25, 38.6° | ≥ 3.20 collision | M width and slope; R/S rise and tread |
| Exchange staff lane | 1.34 / 1.32 | 6.92 / 6.73 | M (R 1.34) |
| Exchange storeroom doors | 1.36–1.40 / 1.38–1.44 | 2.60 / 2.60 | M |
| Dining kitchen service door | 1.40 / 1.24 | 2.50 / — | M |
| Dining side entrances | 1.50 / 1.34 | 2.60 / 2.60 | M |
| Medicine balcony door | 1.60 / about 1.4 between leaves | 2.40 / — | M collision; R visible |
| Scripture library stair / archive stair | 2.6 / 2.2 wide; 27 / 29 steps; about 30° | — | S (slope M 30.2°) |
| Medicine loft under hanging herbs | — | about 1.97 visible | R (not contradicted; my grid can miss thin bundles) |

### 3.4 Interior clearance and third-person camera (all M)

"Covered" means reachable floor with visible geometry overhead.
- **Headroom:** visible headroom over the reachable covered floor. Low values caused by uncollided objects are excluded here and covered in section 4.
- **Typical boom:** the median of the boom length averaged over four facing directions.
- **Worst-direction share:** the part of the covered floor where the boom is under 1.0 m in at least one direction.
- **Camera in mesh:** the share of camera samples whose final position overlaps visible geometry.
- **Occluded:** the share of camera samples where visible geometry hides the player's head.

| Building | Covered reachable floor | Visible headroom p10 / median | Typical boom | Boom < 1.0 m in some direction | Camera in mesh / occluded | Camera collision notes |
| --- | --- | --- | --- | --- | --- | --- |
| Main Sect Hall | 746 m² | 6.28 / 6.90 (dais 8.36 / 12.34) | 3.41 | 40% | 2.1% / 0.2% | roof collision follows the soffits (S) |
| Sect Gate | 106 m² | 7.45 / 8.59 | 3.54 | 43% | 1.5% / 0.0% | |
| Training Ground | 242 m² (shelters) | 3.22 / 3.65 | 4.25 | 25% | 0.1% / 0.4% | 84 degenerate roof-collider triangles (R) |
| Scripture Pavilion | 371 m² (ground 301, second floor 70) | 3.94 / 4.86; second floor 4.23 | 3.40 | 44% | 2.6% / 0.0% | roof-underside collision (S) |
| Mission Hall | 175 m² | 3.94 / 5.90 | 3.27 | 52% | 0.9% / 2.5% | camera slab 5.0 m above the floor (M) |
| Exchange Hall | 186 m² | 3.99 / 4.54 | 3.00 | 59% | 1.1% / 1.7% | coffered-ceiling collision 6.9 m above the floor (M) |
| Alchemy Pavilion | 158 m² | 3.53 / 4.28 | 3.21 | 42% | 0.0% / 0.0% | camera slab about 5.7 m above the floor (M) |
| Medicine Hall | 228 m² (shop 116, loft 102) | shop 3.59 / 3.59; loft 3.54 / 4.26 | 3.25 | 43% | 0.5% / 1.1% | camera-only concave shape plus a collision-exception contract (R) |
| Disciples' Residence | 130 m² | 3.39 / 3.57 | 3.23 | 61% | 1.1% / 1.6% | ceiling slab at 3.95 (M) |
| Elder Residence | 101 m² | 3.38 / 3.59 | 3.22 | 65% | 4.3% / 3.7% | |
| Dining Hall and Kitchen | 228 m² | 3.39 / 4.19 | 3.31 | 47% | 1.4% / 2.4% | |
| Spirit Herb Garden | 39 m² | 2.67 / 3.60 | 4.25 | 38% | 1.5% / 0.1% | |

Visible floor finishes sit 0–3 cm above the collision floors in all twelve buildings (95th percentile ≤ 0.02 m, M). Feet do not visibly sink anywhere except at known spots: ramp bottoms, Alchemy's 0.14 m furnace-rug step, and Medicine's first interior step.

## 4. Confirmed issues, ranked

Observations only; recommendations follow in section 5. "Distance from body centre" means the closest visible geometry to the player's vertical axis between 1.0 and 1.6 m above the floor, at a spot the collision lets the player stand. The visible avatar is 0.20 m in radius, so anything under 0.20 m visibly enters the character.

1. **Third-person camera collapses indoors (all 12 buildings, M).** The figures are in table 3.4. Even the 21.8 m-wide Main Hall nave gives 40%, because columns and walls are always within 4 m in some direction. The full-boom camera sphere reaches 2.57 m above the floor. Seven openings are at or below that: Elder wing door 2.30, Disciples' doors 2.37 visible, Medicine balcony door 2.40, Dining service door 2.50, Elder gate beam 2.54, Alchemy colonnade beam 2.59 and Garden gate beam 2.60. Following the player through them, the camera snaps in. This is a camera specification issue. Headroom elsewhere (median 3.6–8.6 m) is generous for first person.
2. **Visual-only static door leaves on main routes (6 buildings, M).** Distance from body centre is 0.02–0.07 m at:
   - Mission main door (x ±1.25–1.5, z 1.75–3.0)
   - Exchange main door (x ±1.5–1.75, z 3.5–4.5)
   - Dining main door, both side entrances and the kitchen service door
   - Disciples' four room doors
   - Elder main door and wing door
   - Medicine loft balcony door

   Contrast: Alchemy's front leaves and the Exchange storeroom leaves were given matching boxes by Codex. The Main Hall's administration-room leaves do collide, but the visible leaf and ring pull reach 0.17 m further into the opening on each side (1.36 m collision vs 1.01 m visible clear).
3. **Main Hall rear-veranda columns are offset from their collision (M).** At x = 7.4, 11.0 and 14.6, seen from outside, the collision cylinder face is at z = −10.32 and its drum at −10.43. The visible column face is at −9.84 and the visible drum at −10.03. On the veranda side the body reaches within 0.03–0.07 m of the visible columns' centre line. The same pattern is flagged at all eight rear columns (x ±7.25 to ±18.2). Players walk into the visible rear columns and are stopped by invisible collision about 0.4–0.5 m outside them. The front colonnade does not show this.
4. **Other visible objects with no collision in walkable space (M).**
   - **Main Hall administration rooms:** desk tops 0.53–0.72 m and cushions 0.42–0.52 m, at x ≈ ±13.5–15.75, z ≈ 3.3–5.8. The player walks through them; distance from body centre 0.01 m.
   - **Training Ground instructor platform:** the bronze bell has no collision. Its frame does. Distance 0.00 m.
   - **Elder courtyard trees:** foliage hangs 1.36–1.46 m above the ground, so the head and shoulders pass through the canopy. Distance 0.15 m; nearest collision 1.5–3.0 m away.
   - **Medicine Hall:** beside and under the west interior stair, visible stair timber sits 1.0–1.6 m above the floor with the nearest collision 1.0 m away. Distance 0.05 m.
   - **Stair-cheek stonework at stair feet:** at Scripture (x ±2.75–3.0, z 10.0–10.5) and Elder (x ±2.5, z 0–0.25), distance 0.06–0.08 m.
5. **Two stair "families" (M).** The Codex-converted Hall, Gate, Training and Scripture use 0.15 m risers on 0.39–0.42 m treads, about 20–21°. The Claude-authored halls use 0.15 / 0.30 (26.6°), and the Disciples', Elder and Alchemy stairs use 0.167–0.18 m risers at 29–30°. Movement is unaffected because every stair uses ramp collision. The visible step rhythm differs between neighbouring buildings, which is most noticeable in first person.
6. **Gate and post collision narrower than the visible opening (M).** The Garden gateway collision is 2.90 m wide, while the visible posts are 3.06–3.51 m apart at chest height. The Elder gate is 2.58 m collision against 2.80 m visible. Players stop 0.1–0.3 m short of the visible jamb.
7. **Chest-height trims protrude slightly past collision (M).** They come 0.14–0.25 m from the body centre at:
   - the Main Hall dais bronze (0.14)
   - the Scripture front-wall interior cedar (0.17–0.18)
   - the Hall side-room wall panelling (0.22)
   - Mission window sills (0.24)
   - the four Alchemy interior posts (0.21)
   - the Gate passage pilasters (0.25)

   None touches the current 0.20 m avatar. They would touch a broader production character.
8. **Small collision gap under the Medicine balcony threshold (M).** At z ≈ 4.5 there is no collision floor for about 0.25 m. The 0.28 m capsule crosses it, which is why Codex's walk passes. A navigation-mesh bake or a slimmer agent may split the loft from the balcony there.
9. **Documentation drift (M against S/R), all within 0.1 m:**
   - Main Hall JSON triangle count (203,064 against the real 71,557)
   - Scripture spec entrance 3.3 × 3.35, measured 3.26 × 3.25–3.31
   - Garden "3.2 m opening", measured clear width 2.90
   - Mission porch plaque headroom 2.95 (R), measured 2.87 visible on the axis
   - Exchange canopy 3.42 (R), measured 3.32
   - Alchemy porch plaque 2.67 (R), measured 2.59

## 5. Suggested adjustments (recommendations)

Every suggestion keeps the visible architecture and footprint. None resizes a building.

| # | Suggestion | Reason and evidence | Who and when |
| --- | --- | --- | --- |
| A | Give the production third-person camera an interior mode instead of enlarging rooms. Options: an interior boom of about 1.8–2.5 m with a slight downward pitch, an automatic first-person switch below a boom threshold, or a fade for occluding meshes. Also lower the camera height offset under low lintels. | Issue 1. Rooms already have 3.6–8.6 m median headroom. Widening them enough for a 4.36 m boom would roughly double several footprints and break the rank order. | Production camera work, before the layout pass |
| B | Add thin static-leaf collision boxes to the leaves listed in issue 2, using the method Codex used for Alchemy (`tools/fix_alchemy_leaf_collision.py`). Alternatively, remove the leaves or show them closed against the jamb. | These are the most-walked spots. The visible leaves come within 0.02–0.07 m of the body centre line. Applying one leaf policy makes the set consistent. | Codex, collision-only. Re-run each building's movement suites afterwards, since the leaves narrow clear widths to the values in tables 3.2 and 3.3 |
| C | Main Hall: move the rear-veranda column cylinders and drums about 0.35–0.45 m toward the hall to sit on the visible columns, and add boxes for the two administration-room desks and cushions. | Issues 3 and 4, measured offsets above. Visible geometry would not change. | Only with your approval, because it changes the Hall's preserved collision contract |
| D | Add collision for the Training bell; consider raising or thinning the Elder courtyard tree canopies above about 2.0 m, or accept them as brush-through foliage; add collision under the Medicine stair stringers or block the under-stair space; extend the stair-cheek collision at the Scripture and Elder stair feet. | Issue 4. | Codex, collision-only. The tree change is visual, so it needs your call |
| E | Decide on stair proportions. Options: keep the two families (a ceremonial 0.40 m tread for top-rank buildings, 0.30 m for working halls), or move the Mission, Exchange and Alchemy fronts toward 0.35–0.40 m treads. | Issue 5. Longer treads add about 0.4–0.5 m of stair run per building, which affects footprint and layout. | Your visual judgment first (section 7) |
| F | Widen the Garden and Elder gate collision to the visible posts, less a few centimetres. | Issue 6. | Codex, collision-only, low priority |
| G | Correct the stale figures in the JSON or reports when those files are next edited. | Issue 9. | Codex; not urgent, and not while it is auditing them |
| H | Check the Medicine loft-to-balcony connection during the first navigation-mesh bake. | Issue 8. | At layout time |

## 6. What should not be changed

- **All twelve buildings' overall scale.** Footprints, heights and floor levels form a sensible rank order. The Hall and Gate are monumental, the Scripture Pavilion is tall, the working halls sit at 9.8–13 m, the residences and garden at 6.5–8 m, and the Training Ground is low and open. Facade door widths fall within 12–16% of building width throughout, so no entrance is out of proportion with its own building (E).
- **The Main Sect Hall's architecture, silhouette, door (6.40 × 5.3–5.4 m), 11.2 m stair and floor levels.** It is the approved benchmark. Any change there should be collision-only and approved first (C).
- **Sect Gate passage dimensions** (8.40 m clear, 7.6–7.7 m headroom). They suit a gate and give the widest margins in the set.
- **Disciples' 1.3 × 2.4 m and Elder wing 1.2 × 2.3 m doors.** They are humble by intent and still about twice the player's width with 0.5 m headroom to spare. Fix the camera (A), not the doors.
- **Medicine Hall interior stair.** At 38.6° it is the steepest walkable surface, but it is within the controller's 50° limit and suits a cramped shop loft. Keep it unless playtesting says otherwise.
- **Floor-finish heights.** They are consistent (0–3 cm) everywhere.
- **The Scripture archive gate staying closed.** Its measurements are by design.

## 7. Questions that need human visual judgment

1. **Hall versus Pavilion height.** The Scripture Pavilion (18.02 m) is within 0.2 m of the Main Hall (18.22 m). If the Pavilion stands on higher ground, it will out-rank the Hall on the skyline. Is that acceptable, or should the layout keep the Pavilion lower or farther away?
2. **Exchange prominence.** The Exchange Hall (12.96 m) is 3.2 m taller than the Mission Hall (9.81 m), its functional partner, and taller than Alchemy (12.57 m) and Medicine (11.00 m). Is it right for the commerce hall to be the tallest secondary building?
3. **Alchemy entrance.** Alchemy's 2.2 m door is the smallest main door among the major halls, set behind a 5.1 m colonnade. Does it read as intentional when seen from the approach?
4. **Stairs.** Should stairs follow one standard or two rank-based families (issue 5)? Compare the Hall's and Mission's stairs side by side in first person.
5. **Detail density.** The Gate (about 216 triangles per footprint m²) and Scripture (about 331) are three to six times denser than the approved Hall (58), while the Claude halls sit in the Hall's range (32–83). Do the Gate and Pavilion look busier than the Hall beside them?
6. **Elder courtyard trees.** Is foliage at head height acceptable as brush-through vegetation?
7. **Main Hall collision.** May the Hall's collision be corrected (recommendation C) despite the preserved-collision contract?
8. **Production character.** Will it be 1.8 m tall and about 0.56 m wide? If not, decide before layout, because headroom and lintel margins scale with it.
9. **Interior camera.** Shorter boom, automatic first-person switch, or fading occluders?

## 8. Checklist for testing scale in Godot

Use the existing tools: gallery, then the building, then **Walk asset** (1 walk, Tab for first/third person, Esc back). Any lineup scene should be a throwaway, not the town.

- [ ] **Reference check.** In each building, stand in the doorway in first person and confirm the lintel sits above the view centre (it is 0.72–3.68 m above the eye; table 3.2). In third person, confirm the 1.8 m figure is clearly shorter than every door.
- [ ] **Doorway pass, third person.** Walk through the seven low openings in issue 1 and watch whether the camera snaps. Record which ones feel bad.
- [ ] **Leaf contact.** Walk tight against each open door leaf listed in issue 2, in both modes. Confirm the clipping and judge how visible it is.
- [ ] **Main Hall rear veranda.** Walk the rear veranda next to the columns, then walk outside them. Confirm the 0.4–0.5 m offset.
- [ ] **Interior camera.** In each building, rotate a full 360° in third person at the room centre and against a wall. Note where the camera sits on the avatar's shoulder.
- [ ] **Stair rhythm.** Climb the Hall, Mission, Alchemy and Elder stairs in first person. Compare the step rhythm against your preference.
- [ ] **Distance silhouettes.** In a scratch lineup scene, place the buildings in a row on the review plane with the 1.8 m figure. View from 30, 60 and 100 m at eye height (1.65 m) and from an elevated view. Compare roof heights (section 7, questions 1–2) and watch the LOD switches at 90 m (Gate), 95 m (Hall), 100 m (Scripture) and 140 m (Training).
- [ ] **Narrow passages.** Walk the passages in table 3.3 in both modes: Exchange staff lane, storerooms, Medicine stair up and down, loft-to-balcony, Elder wing door.
- [ ] **Hanging and low objects.** Medicine loft herbs (about 1.97 m), the Training bell, the Elder trees, the Hall administration desks.
- [ ] **Frame rate.** In the lineup scene, check the frame rate with all twelve near models visible (about 601,000 triangles; not measured in this audit).
- [ ] **After any collision fix,** re-run that building's existing movement and camera suites listed in `CODEX_REPORT.md`, and re-check its clear widths against table 3.2.

## 9. Limitations

- **No rendering, no human playtest.** This audit is geometric and physics-based, run headless. It produced no screenshots. Visual impressions are left to section 7, and Codex's existing screenshots remain the visual evidence.
- **Sampling limits:**
  - The 0.25 m grid can miss thin objects such as herb bundles, cords and thin rails.
  - Visible headroom cannot be measured on stairs, because the visible nosings sit above the ramp collision.
  - The camera was sampled at level pitch and four facing directions only.
  - The Medicine balcony (about 10–13 m²) is missing from the reachable-area figures because of the threshold gap in issue 8.
  - The approach walks follow one axis per building, plus the nine scan lines. They are not exhaustive routes.
- **Not measured:**
  - performance, frame rate and memory
  - fit to terrain and slopes
  - navigation mesh
  - lighting and shadow scale cues
  - eave heights other than headroom under porches
  - the Main Hall side-room doors at their spec position only, not other administration-room routes
  - the Scripture library stair (spec values only)
- **Moving target.** Codex is auditing the inventory concurrently. Values reflect the files read at the start of this audit (12 catalog entries).
- **Probe scripts not kept.** They lived only in my session scratch folder and were not saved to the project, following the read-only instruction. I can provide them if you want the measurements reproducible.

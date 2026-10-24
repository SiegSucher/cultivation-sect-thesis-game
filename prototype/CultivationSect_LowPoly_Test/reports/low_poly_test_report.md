<!-- stages-2-3-current -->
> Current continuation: Training Ground and Scripture Pavilion and their props/leaves are now converted and verified. [Stages 2–3 report](LOW_POLY_STAGES_2_3_REPORT.md) contains actual results, two benchmark rounds, screenshots and limitations. The earlier Hall/stage-1 measurements below are historical, not a whole-town claim. Training retains 84 inherited roof collider degenerates.

> Current environment continuation: the user authorized controlled stages on 22 October 2026. Stage 1 Sect Gate conversion is complete; the approved Hall below is unchanged. See [conversion inventory](LOW_POLY_CONVERSION_INVENTORY.md) and [stage 1 report](LOW_POLY_STAGE_1_REPORT.md). Training/Pavilion remain unconverted and no town scene exists. Stop for gate review before further expansion.

# Main Sect Hall low-poly test - collision repair completion

22 October 2026. The approved **Split-Cloud Main Sect Hall** is preserved. The root cause of 64 zero-area roof collision faces is repaired; no architectural redesign or other building conversion was performed.

Original: `C:\Users\pasto\OneDrive\Documents\ChatGPT\Character Sprite Image for Thesis game\prototype\asset-workshop`. Test: `C:\Users\pasto\OneDrive\Documents\ChatGPT\Character Sprite Image for Thesis game\prototype\CultivationSect_LowPoly_Test`. All 1,599 recorded original non-cache file hashes match. High-detail assets, original runtime recovery ZIP and approved design checkpoint remain intact. [Preservation audit](preservation-audit.json), [current summary](roof-collision-fix-2026-10-22/verification-summary.json).

## Actual changes

The closed-hip roof exporter treated repeated ridge corners as a quad and emitted an extra collapsed triangle per strip. The source was reproduced exactly before editing. The corrected collision triangulator handles coincident corners before forming a fan, and rejects unexpected invalid input. Replayed only the collision emitter to update `assets/architecture/tang_main_hall/main_sect_hall.json`. All valid roof triangles and all other JSON fields remain exact. [Root cause, implementation and coverage proof](ROOF_COLLISION_FIX.md).

The two authorized differences from the unchanged approval checkpoint are the collider JSON and authoring program; a new shared collision helper is added. No approved GLB/native source, material, proportion, roof silhouette, footprint, player/camera controller, door script or project setting changed. Visible static geometry stays 71,557 triangles / 12 opaque shared materials, with no textures or custom shaders. Roof collider is now 2,368 triangles with zero zero-area triangles. All 195 non-roof simple shapes remain. Root identity, +Z front, metre convention, 1.8 m inspection player, 40.4 x 24 m podium, 1.52 m landing, ~1.53-1.55 m interior, 2.15 m dais, 6.4 x 5.4 m main opening and 2 x 2.8 m private openings are retained.

The approved jade/oxblood/plaster/stone/bronze style, original mountain motif, lighting and shared rendering settings remain. [Approved design](BUILDING_DESIGN.md), [style guide](LOW_POLY_STYLE_GUIDE.md). All nine original reference PNGs are preserved; filenames and intended use remain in [HANDOFF](../HANDOFF.md). No pictured building was copied, and no legacy environment was imported.

## Actual verification

| Verification | Result |
| --- | --- |
| Triangulator regression tests | 7 PASS; ordinary quad, both ridge windings, closing duplicate, nearby valid corners, invalid collinear/nonfinite/collapsed input |
| Authoring source replay | PASS: original source reproduced all 64; repaired source reproduces zero |
| Exact collision coverage | PASS: every nonzero-area triangle and its winding/coordinates retained exactly |
| Godot roof coverage | 4 PASS / 0 FAIL; 10,266 before/after ray comparisons, zero mismatches |
| Fresh high-detail baseline | 21 PASS / 0 FAIL |
| Repaired rendered hall | 21 PASS / 0 FAIL; actual inspection-controller movement, door access, FPP/TPP |
| Supplemental dimensions/collision | 18 PASS / 0 FAIL; walls/floor, retained scale, camera retraction/clearance |
| Dispatched input controls | 7 PASS / 0 FAIL; walking/review, Tab, E, Esc and gallery return |
| Blender source reopen | 7 PASS / 0 FAIL; source itself unchanged |
| Fresh independent runtime copy | 21 PASS / 0 FAIL; clean import with no copied cache/metadata/symlinks |
| Original preservation | 1,599 recorded original non-cache files match original hashes |
| Approved visuals/source/controllers/settings | 9 immutable files match; four GLBs/.blend unchanged |
| Current import/runtime diagnostics | No errors or warnings in checked logs |


Movement tests exercise the main stair, entrance, aisle, leader dais and both side rooms; closed-door blocking, floor stability, actual camera switching, avatar visibility and follow-camera collision retraction are covered. The source has no production player or town; these results certify the tested inspection fixture only. The independent project at `C:\Users\pasto\OneDrive\Documents\ChatGPT\Character Sprite Image for Thesis game\output\split-cloud-roof-collision-independent-verification` was created without `.godot`, import metadata or symlinks, freshly imported, then passed its own rendered suite. Shared engine software is the only external tool requirement.

## Performance comparison

Repeated the same outdoor front/three-quarter/360-degree sweep and indoor fixed/FPP/TPP samples, 1280x720, GL Compatibility, MSAA 4x, VSync off, no cap, same adapter, poses, lights and controller. [Full new and prior comparison](performance_comparison.md) reports mean/p95/max frame times, FPS, draw calls and monitor memory. Approved visible geometry still has 64.8% fewer static triangles than the original high-detail baseline; this reduction predates the collision fix. Removing empty collider faces is a correctness/data cleanup, and this uncontrolled short benchmark does not isolate a causal speedup from it.

## Genuine current screenshots

| View | Preserved high-detail baseline | Repaired approved hall |
| --- | --- | --- |
| front | [Baseline](screenshots/baseline-front.png) | [Approved repaired hall](screenshots/optimized-front.png) |
| three-quarter | [Baseline](screenshots/baseline-three-quarter.png) | [Approved repaired hall](screenshots/optimized-three-quarter.png) |
| roof-detail | [Baseline](screenshots/baseline-roof-detail.png) | [Approved repaired hall](screenshots/optimized-roof-detail.png) |
| interior | [Baseline](screenshots/baseline-interior.png) | [Approved repaired hall](screenshots/optimized-interior.png) |
| first-person | [Baseline](screenshots/baseline-first-person.png) | [Approved repaired hall](screenshots/optimized-first-person.png) |
| third-person | [Baseline](screenshots/baseline-third-person.png) | [Approved repaired hall](screenshots/optimized-third-person.png) |

All 12 images are genuine Godot captures; poses and FOVs match the earlier sequence. Pre-fix results/screenshots remain in `roof-collision-fix-2026-10-22/before/`; earlier evidence is retained under `verification-2026-10-22/`. The visible-file hash proof is stronger than screenshot appearance alone.

## Remaining limitations and decision

No remaining zero-area roof collider faces or failures occurred in the executed suites. NOT TESTED: human keyboard/mouse rehearsal; intended low-end hardware; sustained thermal behavior/long-run stutter; exported executable; future production-player/camera or populated-town integration; exhaustive geometry self-intersection/all camera orientations and pixel-level distance-handover analysis. Current source has no town or production player. Automated movement results apply to the existing 1.8 m inspection fixture. A full visual-model rebuild/export was deliberately not performed; the actual roof emitter was replayed in isolation, and the saved source/GLBs were audited without overwriting them.

**Do not expand to other buildings.** Current next action is a human walkthrough of this unchanged approved hall, then intended-device/sustained testing. Later production integration requires separate instruction. [HANDOFF](../HANDOFF.md) records exact evidence, file changes, safeguards and next action; no message was sent to Claude.

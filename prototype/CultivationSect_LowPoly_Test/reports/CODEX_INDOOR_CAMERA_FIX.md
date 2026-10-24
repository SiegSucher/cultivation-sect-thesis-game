# Indoor third-person camera follow-up

23 October 2026. Implemented and tested in `prototype/CultivationSect_LowPoly_Test` only. This is an inspection-controller improvement, not a final production-camera approval. No building, material, model, asset collision, scene, gallery catalog, staging file or town placement was changed.

## Root cause

`scripts/training_inspection_player.gd` always requested `(0, .72, 4.3)` behind the 1.65 m eye: a 4.36 m boom, with its camera sphere reaching approximately 2.55 m above the floor after the existing margin. That is too high for several low lintels and unnecessarily long for narrow rooms. Every physics frame immediately replaced the distance with a sphere-cast result, without an indoor profile, transition state or outward recovery. Turning past an obstruction or following the player through a doorway could therefore change the distance abruptly.

The original safety subtraction was `.025` of the requested boom. Simply shortening that boom also shortened the clearance margin. The first candidate exposed this in additional visible-timber overlaps; the final implementation preserves the original margin in metres. Captures also showed that retaining the original head-height aim cropped the feet with a shorter boom, so the indoor aim point is lowered slightly.

## Files changed

- **Runtime change:** `scripts/training_inspection_player.gd` — additive camera settings, overhead detection and camera-only state/math. The physics caller now passes delta time. Body dimensions, movement, gravity, floor snap, input, yaw/pitch limits and first-person eye remain unchanged.
- **New reproducible test:** `tools/verify_indoor_camera.gd`.
- **New report:** `reports/CODEX_INDOOR_CAMERA_FIX.md`.
- **Handoff:** a current camera-follow-up section in `HANDOFF.md`; previous asset-integration record retained as historical evidence.
- **Evidence/rollback:** `reports/indoor-camera-fix/`, including `before-hashes.json`, `before/training_inspection_player.gd.txt`, `before/HANDOFF.md.txt`, before/after JSON/logs/captures, `comparison.json` and `preservation.json`.
- **Regression copies:** `reports/indoor-camera-fix/batch2-regression/verify_batch2_integration.gd` and `test_batch2_gallery.gd`. These are copies of the existing tests with only their output directory changed, so old evidence is not overwritten.

The gallery catalog and existing walkthrough scenes need no change: they already instantiate this shared inspection controller. Do not rerun old documentation finalizers over this state.

Final SHA-256 preservation check: all **1,599 original-project files** match both the task-start snapshot and the recorded original manifest. Of **5,016 pre-existing test-project files**, only the controller and handoff changed; none is missing. All **61 staged files**, building assets/sources/scenes/collision, gallery catalog and previous reports remain unchanged. The original `_ready` and input functions are identical; the movement function differs only in passing delta to the camera call. Evidence: `indoor-camera-fix/preservation.json`.

## Settings before and after

| Setting | Before | After |
| --- | --- | --- |
| Open-sky requested offset | `(0, .72, 4.3)` m | Identical |
| Open-sky effective distance | 4.2509 m | Identical; three outdoor screenshot pairs are pixel-identical |
| Covered-space requested offset | Same outdoor offset | `(0, .12, 2.2)` m |
| Unobstructed covered-space effective distance | 4.2509 m | 2.0943 m |
| Indoor aim | Eye-height target, 4 m ahead | Same target lowered .65 m, blended with the profile |
| Profile transition | None | Exponential interpolation, rate 8/s |
| Outward recovery | Immediate | Exponential interpolation, rate 5/s |
| Inward obstacle response | Immediate | Immediate safety clamp retained |
| Camera sphere / collision mask | .20 m / layer 1 | Identical |
| Clearance margin | .025 of boom length | Original outdoor margin retained: approximately .109 m |
| FOV / near plane / first-person eye | 75 degrees / .05 m / 1.65 m | Identical |

Cover is detected using upward collision rays up to 16 m, at the eye and .65 m ahead along horizontal movement. A .25 s exit hold avoids rapid profile toggling at roof edges. This is a collision-based heuristic: porches and tall halls count as covered; it is not a production interior-zone system. No ray or sphere query ignores walls or ceilings. Explicit `update_camera()` calls still initialize immediately for existing walkthrough resets; normal physics updates interpolate using delta time.

Editable exported settings: `indoor_camera_enabled`, `indoor_camera_distance`, `indoor_camera_rise`, `indoor_camera_look_down`, `indoor_camera_transition_speed`, `camera_recovery_speed`. Setting `indoor_camera_enabled = false` restores the original fixed-boom path. All 216 original static boom distances matched with this switch off (tolerance .002 m). The untouched original script is also backed up as non-imported text.

## Tests actually performed

Godot 4.7.2, Compatibility/OpenGL, RTX 3050 Laptop, rendered viewport 1280 x 720, fixed simulation delta 1/60 s. These are functional tests, not FPS benchmarks. Every suite below passed with the final controller.

| Test | Result |
| --- | --- |
| Original controller: matched headless experiment | 40 PASS / 0 FAIL |
| Original controller: matched rendered experiment | 52 PASS / 0 FAIL |
| Final controller: expanded headless experiment | 46 PASS / 0 FAIL |
| Final controller: expanded rendered experiment | 58 PASS / 0 FAIL |
| Existing Alchemy/Medicine expanded headless regression, redirected output | 124 PASS / 0 FAIL: 61 Alchemy, 63 Medicine |
| Existing Alchemy/Medicine rendered regression, redirected output | 136 PASS / 0 FAIL: 66 Alchemy, 70 Medicine |
| Existing twelve-entry gallery/programmatic input regression, redirected output | 53 PASS / 0 FAIL |

Representative existing fixtures: `scenes/hall_experiment.tscn`, `scenes/review/disciple_residence_walkthrough.tscn`, and `scenes/review/alchemy_pavilion_walkthrough.tscn`. Hall doors were opened in memory only. Each fixture remains a single building at its existing local origin on its existing review floor.

The matched experiment used 24 yaw directions at three pitches (-.35, 0, +.35 radians), 72 static poses per building / 216 total. It additionally exercised a continuous 180-frame turn per building, real movement through entrances and exits, the dormitory's approximately 2.4 m doorway and interior aisle around the study table, and Alchemy's furnace aisles. Final runs sampled **2,132 headless / 2,138 rendered moving/turning camera positions**, with zero .18 m camera-sphere overlaps against authored layer-1 solids. Static sweeps also had zero authored-solid overlaps. First-person eye position, Tab switching, outdoor recovery, feature-off baseline equivalence, normal level-view head/feet framing and absence of newly overlapping static visible-mesh poses were checked.

The existing Alchemy/Medicine regression additionally retained both camera modes, stairs/loft/balcony routes, blocking checks and Medicine's existing camera-only collision exception: 416 Alchemy + 398 Medicine camera/body sample pairs per run, no contacts on those routes. Gallery testing loaded all twelve entries and exercised real programmatic key/mouse events. These are not human input sessions.

## Measurements and captures

Measurements below come from the matched headless runs, not Claude's broader scale-grid audit. They cover three positions and sampled routes, not whole buildings.

| Measurement | Before | After |
| --- | ---: | ---: |
| Hall static sweep median / minimum boom | 4.251 / 2.599 m | 2.094 / 2.094 m |
| Dormitory static sweep median / minimum boom | 2.131 / .598 m | 2.071 / .605 m |
| Alchemy static sweep median / minimum boom | 3.659 / .802 m | 2.094 / .812 m |
| Dormitory measured low-door segment: largest successive boom change | .7323 m/frame | .0468 m/frame |
| Dormitory moving/turning minimum boom | .3934 m | .4040 m |
| Static visible-mesh camera overlaps: Hall / Dormitory / Alchemy | 0 / 15 / 6 of 72 poses each | 0 / 12 / 0 |

The shorter median is intentional: it replaces a long boom that frequently reaches through the doorway with a lower, closer indoor view. This is not evidence that near-wall compression has disappeared. The specific doorway segment's boom jump fell approximately 94%; hard collision clamps can still be abrupt elsewhere.

There are **24 final matched before/after screenshots** directly under `indoor-camera-fix/` (12 per phase), plus 18 additional regression/gallery screenshots under `batch2-regression/`. Initial candidate evidence remains in `candidate-v1/` and `candidate-v2/`; those images are not the final result. Selected final captures were inspected by Codex, including the corrected head/feet framing. No human visual acceptance is claimed.

| View | Before | After |
| --- | --- | --- |
| Main Hall | [Before](indoor-camera-fix/before-hall-interior.png) | [After](indoor-camera-fix/after-hall-interior.png) |
| Dormitory doorway/interior view | [Before](indoor-camera-fix/before-disciple-interior.png) | [After](indoor-camera-fix/after-disciple-interior.png) |
| Alchemy furnace-room view | [Before](indoor-camera-fix/before-alchemy-interior.png) | [After](indoor-camera-fix/after-alchemy-interior.png) |

## Remaining limitations and diagnostics

- **Near-wall compression remains.** A forward/back boom cannot keep a long distance when a wall is immediately behind the character. No automatic first-person switch, occluder fading, shoulder avoidance or avatar fading was added. At very short distances the character can still fill the view.
- **Visible doorway timber can still overlap the dorm camera.** In the continuous-turn probe the visible-mesh overlap count was **20 before / 25 after out of 180 samples**. These are camera-sphere overlaps, not a count of visually judged bad frames. Contacts occur around the existing doorway timber/visual-only leaves; authored-solid clearance remains clean. The static sweep improves 15 to 12 and adds no newly overlapping sampled static poses, but the continuous-turn result is a remaining limitation/regression, not a passed visual-clearance claim. Door/trim collision changes were explicitly out of scope and were not made. Complete visible-geometry clearance would require a separately authorized approach; no broad repair was attempted.
- Upward rays can classify any nearby overhead collider as cover. Only the representative paths and angles above were deeply tested; the other gallery entries were loaded, not exhaustively walked. Larger halls now use the same default shorter profile; user preference may justify tuning the exported distance.
- Smoothing does not delay a required inward collision response. No claim of perfectly smooth transitions for every turn, roof edge, lintel or pitch is made.
- Known Main Hall collision discrepancies, other scale-audit findings, Training roof degenerates/performance regression, static leaves, steps, props and navigation gaps remain untouched.
- Final logs retain the pre-existing host `Failed to read the root certificate store` error. Final runs have no parser, missing-resource or freed-body errors. An initial logging command incorrectly supplied `res://` to Godot's `--log-file`; it was corrected to an absolute path and the baseline rerun. This did not alter assets.
- No human playtest/user acceptance, final production character, terrain/layout/navigation, export, low-end hardware or performance benchmark was performed. The 1.8 m character remains an inspection fixture.

## Verify in Godot

1. Open this test project's `project.godot` in Godot 4.7.2; run `scenes/asset_gallery.tscn`. Do not open the original workshop for this experiment.
2. Select Main Sect Hall -> **Walk asset** -> press **1** to walk and **Tab** for third person. Use **E** near the doors; enter, turn through 360 degrees, approach a wall and exit to open sky. Compare the close covered profile and gradual outdoor recovery.
3. Repeat with **Disciples' Residence**. Enter a room, walk around the study table into the aisle between beds, then turn and exit through the low doorway. Explicitly inspect the remaining visible-leaf camera overlap while turning close to the door.
4. Repeat with **Alchemy Pavilion**: front stair, porch/door, furnace aisles, turns and return outside. Medicine's shop/stair/loft/balcony can be checked through its existing Walk route without changing its collision setup.
5. In the running scene's **Remote** tree, find `InspectionCamera` and select its parent CharacterBody3D. Toggle **Indoor Camera Enabled** in its Inspector for a same-position comparison with the original camera. Restore it to enabled. The other exported settings can be tuned there temporarily; do not scale or move buildings.
6. Verify Tab still gives the original first-person eye and WASD/mouse controls. Record human observations separately from the automated results.

Re-run final automated checks from the test-project directory (PowerShell):

```powershell
& ../../tools/godot/Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . --script res://tools/verify_indoor_camera.gd
& ../../tools/godot/Godot_v4.7.2-stable_win64_console.exe --fixed-fps 60 --path . --resolution 1280x720 --script res://tools/verify_indoor_camera.gd -- --rendered
```

Do **not** use `--before` with the changed controller: the retained before JSON/captures came from the actual original script. To roll back permanently, restore `scripts/training_inspection_player.gd` from `reports/indoor-camera-fix/before/training_inspection_player.gd.txt`; no asset rollback is needed. Keep the original baseline evidence.

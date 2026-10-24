# Static open-door collision corrections

23 October 2026. Scope: the six reported assets in `prototype/CultivationSect_LowPoly_Test`, using `reports/CLAUDE_SCALE_AUDIT.md` as the issue list and `assets/gallery/catalog.json` as the inventory. **26 confirmed missing leaf colliders added across 13 openings.** Four already-corrected Exchange storeroom leaves inspected and preserved. No visible geometry, materials, models, sources, layout, unrelated collisions, player/camera code or original-project files changed.

## Root cause and confirmation before editing

The four frozen Claude builders contain the same `leaves()` implementation: a .06 m timber slab and three .03 m cedar crossbars shifted .035 m inward, placed in the open pose. The helper calls `wbox()` without a collision name and never appends collision. The resulting GLB contains visible leaves, while the delivered scene lacks matching physical shapes. This is not an import failure or a door-animation failure.

Source inspected read-only: `staging/claude_buildings/tools/build_claude_buildings.py:152`, `staging/claude_mission_hall/tools/build_mission_hall.py:189`, `staging/claude_exchange_hall/tools/build_exchange_hall.py:191`, and `staging/claude_buildings_batch2/tools/build_claude_batch2.py:190`. Their leaf-helper syntax trees match. No generator was executed or modified.

Before editing, actual permanent scenes were instanced in Godot and their imported visible meshes copied to a separate test-only physics layer. Each leaf was probed at five heights and three depth positions: **30 visual/solid ray pairs per opening**. All 390 visual probes across the 26 reported leaves hit geometry; all 390 corresponding authored-collision probes missed. The four pre-corrected Exchange storeroom leaves passed all 60 probes. This confirmed each issue independently rather than assuming every authored doorway needs a collider.

## Every leaf-bearing opening inspected

All leaf poses remain static and open. Clear widths below are measured after correction at the crossbars, not merely taken from wall-cut dimensions.

| Asset / door | Initial condition | Exact correction | Measured minimum leaf clearance |
| --- | --- | --- | ---: |
| Mission Hall main | Both visible leaves missing collision | `DoorLeaf_MainEntrance_Left/Right` | 2.80 m |
| Exchange Hall main | Both visible leaves missing collision | `DoorLeaf_MainEntrance_Left/Right` | 3.00 m |
| Exchange east storeroom | Two matching boxes already present | Preserved `EastStaticLeaf0/1` | 1.40 m |
| Exchange west storeroom | Two matching boxes already present | Preserved `WestStaticLeaf0/1` | 1.40 m |
| Dining main | Both visible leaves missing collision | `DoorLeaf_MainEntrance_Left/Right` | 2.80 m |
| Dining west side, u=-6 | Both visible leaves missing collision | `DoorLeaf_WestEntrance_Left/Right` | 1.30 m |
| Dining east side, u=+6 | Both visible leaves missing collision | `DoorLeaf_EastEntrance_Left/Right` | 1.30 m |
| Kitchen east service door | Both visible leaves missing collision | `DoorLeaf_KitchenService_Left/Right` | 1.20 m |
| Disciples' room 1, x=-6.6 | Both visible leaves missing collision | `DoorLeaf_Room1_Left/Right` | 1.10 m |
| Disciples' room 2, x=-2.2 | Both visible leaves missing collision | `DoorLeaf_Room2_Left/Right` | 1.10 m |
| Disciples' room 3, x=+2.2 | Both visible leaves missing collision | `DoorLeaf_Room3_Left/Right` | 1.10 m |
| Disciples' room 4, x=+6.6 | Both visible leaves missing collision | `DoorLeaf_Room4_Left/Right` | 1.10 m |
| Elder main room | Both visible leaves missing collision | `DoorLeaf_MainEntrance_Left/Right` | 2.00 m |
| Elder attendant wing, west-facing | Both visible leaves missing collision | `DoorLeaf_AttendantWing_Left/Right` | 1.00 m |
| Medicine loft/balcony door | Both visible leaves missing collision | `DoorLeaf_BalconyEntrance_Left/Right` | 1.40 m |

The Dining-to-Kitchen internal pass-through has no authored leaf; it was left open. No collision was invented to fill that passage. Gate-post, stair, furniture, threshold and other scale-audit findings were not repaired here.

## Small reversible correction and exact files

Each new node is a `CollisionShape3D` under the scene's existing `Collision` StaticBody3D (layer 1, mask 2). One shared BoxShape3D per door serves its two leaves: **13 box resources / 26 shape nodes**. No additional runtime scripts or physics bodies were needed.

The box is the leaf/crossbar envelope: .08 m thick, height `h-.06`, depth `w/2-.02`. Its centre shifts .01 m inward from the timber slab centre to cover the asymmetrical cedar strips. This avoids the overly thin .06 m slab-only collider while keeping the actual open gap. Between crossbars the single box can conservatively cover up to .02 m of empty space; measured visible/collision surface differences stay below .025 m. The already-corrected storeroom boxes retain their preceding .10 m thickness and exact values.

| Permanent scene changed | Shapes before -> after |
| --- | ---: |
| `scenes/buildings/mission_hall.tscn` | 37 -> **39** |
| `scenes/buildings/exchange_hall.tscn` | 73 -> **75** |
| `scenes/buildings/dining_hall_kitchen.tscn` | 53 -> **61** |
| `scenes/buildings/disciple_residence.tscn` | 36 -> **44** |
| `scenes/buildings/elder_residence.tscn` | 49 -> **53** |
| `scenes/buildings/medicine_hall.tscn` | 54 -> **56** |

**Every pre-existing external resource, subresource, node transform and property block is preserved**, including Exchange's four storeroom boxes, Medicine's four counter corrections and `CameraDetailObstruction`/`medicine_camera_obstructions.tres`. Definitions/nodes were appended to task-start copies of the corrected permanent scenes; no raw staged scene was substituted. Scene `load_steps` values were increased only for the new resources. Evidence: `door-collision-fix/existing-scene-blocks-preserved.json`.

New reproducible correction tool: `tools/fix_static_door_leaves.py`. Its manifest-only default writes `door-collision-fix/door-manifest.json`, containing exact positions, sizes, orientation and source dimensions for every leaf. `--apply` requires successful pre-edit physics probes and task-start permanent-scene hashes, then applies only the declared additions; rerunning is idempotent. The repair was not made by running frozen builders or previous stage-based correction tools.

Other changes: this report, `HANDOFF.md`, and new evidence/diagnostic copies under `reports/door-collision-fix/`. Full original permanent scenes and handoff are backed up under `door-collision-fix/before/`. The catalog, GLBs, native sources, source builders, camera/controller, Hall startup fix and original project remain unchanged.

## Tests performed and actual results

Godot 4.7.2. Rendered runs used Compatibility/OpenGL, RTX 3050 Laptop and 1280 x 720. Fixed simulation delta 1/60 s was used for reproducibility; no FPS/performance benchmark or human playtest is claimed.

| Test | Actual result | Evidence under `reports/door-collision-fix/` |
| --- | --- | --- |
| Before: imported visible leaves vs authored collision, 15 openings | **30 PASS / 0 FAIL**, confirming missing versus already-corrected coverage | `before-probes.json` |
| After: leaf coverage, bounds, clear widths, real blocking and two-way FPP/TPP passage | **181 PASS / 0 FAIL** headless | `after-headless.json` |
| Same dedicated suite, rendered plus captures | **191 PASS / 0 FAIL** | `after-rendered.json` |
| Four-room focused camera sweeps/turns | **4 PASS / 0 FAIL; 1,008 poses; zero overlaps** | `dorm-camera.json` |
| Existing four-asset residence/dining/garden regression | **121/0 headless; 138/0 rendered** | `batch1/` |
| Existing Mission expanded routes | **50/0 headless; 56/0 rendered** | `mission/` |
| Existing Exchange expanded routes | **70/0 headless; 78/0 rendered** | `exchange/` |
| Existing Alchemy/Medicine expanded routes | **124/0 headless; 136/0 rendered** | `batch2/` |
| Existing all-twelve gallery launch/input audit | **466 PASS / 0 FAIL** | `gallery/launch-results.json` |

The 15 inspected leaf-bearing openings now pass **450/450 collision rays**, with all matching visual rays present. Measured collision-to-visible-surface differences are at most approximately .0203 m. Every opening permits the existing 1.8 m / radius .28 m controller to enter and exit in both camera modes. Each leaf also blocks that real controller when approached from its side in both modes. The dedicated headless and rendered runs each sample **808 camera/body pairs** with zero authored-camera, visible-camera or visible-upper-body contacts on the tested passages/blocking paths. No probe tolerance was relaxed after a failure.

The focused dorm test repeats 72 pitch/yaw poses plus 180 continuous-turn samples at each of the four room doorways: 288 static + 720 turning samples. At the previously measured room x=2.2, the preceding indoor-camera stage recorded **12 static / 25 turning visible overlaps**; the current targeted test records **0 / 0**, and all four rooms are clear on the sampled poses. The camera/controller script is byte-identical: the improvement comes from matching the missing physical leaves. Near-wall compression remains necessary and no all-angle clipping guarantee is claimed.

Existing regression scripts were copied into the new evidence folders so previous results remain intact. Only output paths and the two intentionally obsolete Mission/Exchange shape-count assertions were updated in those copies (37->39, 73->75). Route coordinates, controller, probe radii and pass tolerances were not changed. The utility regression retains full stair/loft/balcony routes and Medicine's body-exception contract. Gallery tests retain all twelve entries, Hall's immediate TPP launch, mode switches, mouse look, documented keys, Esc and utility exception lifecycle.

The new door-test harness initially had type-inference parse errors in diagnostic-only vector variables; explicit Vector3 annotations corrected them before any scene repair. The failed log is retained as `harness-initial-parse-error.log`. All final suites above passed. Final logs still contain the existing host `Failed to read the root certificate store` error, plus informational addon registration; no final asset/parser/missing-resource/freed-body error was found. No separate editor reimport was needed or performed: only native `.tscn` collision data changed, and fresh processes successfully loaded/rendered the existing model imports.

## Screenshots and verification limits

**99 genuine Godot screenshots** are retained throughout this evidence directory. Selected dedicated Mission and Medicine TPP captures were inspected by Codex:

- [Mission entrance TPP](door-collision-fix/mission_hall-MainEntrance-TPP.png)
- [Medicine balcony door TPP](door-collision-fix/medicine_hall-BalconyEntrance-TPP.png)
- Existing-regression captures under `batch1/`, `mission/`, `exchange/`, `batch2/`, and all-entry initial/FPP/TPP/overview captures under `gallery/`.

These are rendered programmatic checks, not human playtesting or visual acceptance. Still unverified: all possible approach angles/pitches, production character dimensions, NPC/navigation fit, exported builds, performance/low-end hardware and final terrain placement. No new door-opening animation or E interaction was added; these authored leaves remain static/open. Medicine's existing balcony threshold support gap and camera-only-body integration contract remain, as do unrelated Main Hall side-leaf/ring/column issues and other scale-audit findings. They were not silently repaired.

To verify manually, open this test project, run the gallery (`scenes/asset_gallery.tscn`, F6), select one of the six affected assets -> Walk asset -> **1** walking -> **Tab** TPP. Walk through each opening and deliberately approach the side of the visible open leaf; it should block without closing the centre passage. Repeat in FPP. For Medicine, use the existing interior stair and loft/balcony route. No E toggle exists for these static doors. The Hall's separate immediate-TPP startup remains unchanged.

## Preservation, rollback and next action

Final preservation details and exact hashes are in `door-collision-fix/preservation.json`. Earlier asset reports retain their stage-specific shape counts; use this report's six updated counts for current collision state. **Do not overwrite corrected canonical scenes with staging or rerun old stage-based scene generators over them.**

Final SHA-256 audit: **5,189 pre-existing test-project files checked**; only the six declared permanent scenes and `HANDOFF.md` changed, none is missing. All **62 staged files** are unchanged, including the Mission UID sidecar already present at task start. All **1,599 original-project files** match both the task-start snapshot and recorded original manifest. Existing scene property blocks, controller/camera, Hall startup script, Medicine camera resource, all GLBs/native sources and prior reports are preserved.

To roll back this isolated correction, restore only the six matching `.tscn` files from `door-collision-fix/before/` to `scenes/buildings/`. This restores the task-start permanent corrections rather than raw staging. No GLB, source, camera or controller rollback is necessary.

Next action: human review of the six doorway sets, particularly the 1.0 m Elder wing opening, four dorm doors and Medicine balcony. Record real keyboard/mouse observations separately. No remaining confirmed leaf mismatch from this six-asset issue list is unresolved on the tested openings; broader collision/character acceptance remains outside this evidence.

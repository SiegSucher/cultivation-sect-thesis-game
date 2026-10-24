# Main Sect Hall rear-veranda collision alignment

23 October 2026. Project: `prototype/CultivationSect_LowPoly_Test/`.

**The confirmed rear-column/drum mismatch is corrected.** Eight physical column/drum pairs now sit on the eight visible pairs. Two additional, invisible central pairs were independently confirmed and removed from collision only. The approved model, materials, dimensions, placement, camera/controller and permanent scene are unchanged. This resolves the specific column-alignment hold in `FINAL_BUILDING_READINESS_AUDIT.md`; the Hall is now ready for controlled placement testing **with known limitations**, not certified for production or human acceptance. No town placement occurred.

## Actual resources and root cause

- Permanent scene: `scenes/buildings/tang_main_hall.tscn`.
- Runtime builder: `scripts/tang_main_hall.gd`, creates `AuthoredSimpleCollision` from JSON.
- **Only runtime data changed:** `assets/architecture/tang_main_hall/main_sect_hall.json`, selected records in `solid_shapes`.
- Approved visual model: `assets/architecture/tang_main_hall/main_sect_hall.glb`; editable source `source/split_cloud_hall.blend`.
- Original state, plan and evidence: `reports/main-hall-collision-fix/`.

The visible design and collision were generated from different layouts. The existing `tools/build_split_cloud.py` authors **eight** rear columns at z=-9.6, x=±7.2/10.8/14.4/18.0, with matching stone drums. It then reads the historical baseline specification and deliberately retains its **ten** rear pairs at z=-10.0, including x=±3.65. The current runtime faithfully uses that old data; this is not an import or transform failure. The generator was read, not run or modified.

The readiness audit explicitly included the drums in the same alignment issue. Both each drum and its matching column were measured. No desk, cushion, ring pull, front-colonnade, other prop, roof or unrelated collision was changed.

## Measurement and exact correction

The new `tools/fix_main_hall_veranda_collision.py` reads the permanent GLB directly. It groups indexed triangles by connected positions, including vertices split for flat normals, and measures the actual Timber column and Coping drum components. It finds eight of each with the expected dimensions. No Blender save/export is performed.

- Visible column bounds: y=2.05..7.36 m, centre y=4.705, x/z extent .64 m; existing collision radius **.32 m**, height **5.31 m**, unchanged.
- Visible drum bounds: y=1.52..2.12 m, centre y=1.82, size **(.85, .60, .85) m**, unchanged collision size.
- Matching pair centres move **.20 m toward the centre in X, +.40 m in Z**; approximately .4472 m total horizontal displacement. Y is unchanged.

The table gives original `solid_shapes` indices. For every row, the drum centre is `(X, 1.82, Z)` and the column centre `(X, 4.705, Z)`, before and after. Full measured bounds and positions are in `main-hall-collision-fix/alignment-plan.json`.

| Before indices: drum / column | Before X | Before Z | After X | After Z | Action |
| --- | ---: | ---: | ---: | ---: | --- |
| 91 / 92 | -18.2 | -10.0 | -18.0 | -9.6 | Align both |
| 95 / 96 | -14.6 | -10.0 | -14.4 | -9.6 | Align both |
| 99 / 100 | -11.0 | -10.0 | -10.8 | -9.6 | Align both |
| 103 / 104 | -7.4 | -10.0 | -7.2 | -9.6 | Align both |
| 107 / 108 | -3.65 | -10.0 | — | — | Remove confirmed invisible pair |
| 111 / 112 | +3.65 | -10.0 | — | — | Remove confirmed invisible pair |
| 115 / 116 | +7.4 | -10.0 | +7.2 | -9.6 | Align both |
| 119 / 120 | +11.0 | -10.0 | +10.8 | -9.6 | Align both |
| 123 / 124 | +14.6 | -10.0 | +14.4 | -9.6 | Align both |
| 127 / 128 | +18.2 | -10.0 | +18.0 | -9.6 | Align both |

**16 existing records moved; 4 unmatched records removed; 195 -> 191 simple shapes.** Every other 175 simple-shape record retains its values/order. All 33 other top-level JSON fields, including all **2,368 roof faces**, doors, stairs, floor levels, lights and metadata, are identical. Non-target text is preserved; the tool patches only position number tokens or removes the four confirmed obsolete object records. Runtime-generated shape-name index suffixes naturally shift after removal; no scene/controller resource was replaced.

Before applying, actual Godot ray probes confirmed the GLB diagnosis: at each unmatched old pair, collision existed with **no visible counterpart** at three sampled heights. At all eight matching pairs, rays from both sides hit offset visual/physical surfaces. The probe endpoints stop before the inner wall to avoid attributing wall hits to columns.

There are **108 visible/authored ray pairs per phase**: 96 matching-pair samples plus 12 ghost samples. Maximum matching-surface separation was **.469817 m before**, **.0004654 m after**. Matching axial ray separation after correction is under .5 mm; this is not a claim that the retained round cylinder exactly reproduces every face of the octagonal visible mesh. Its dimensions/approximation are unchanged.

The tool defaults to diagnosis/candidate generation. `--apply` requires exact frozen permanent JSON bytes and successful before-probes. It was applied once. A rerun on already changed permanent data intentionally stops; do not force it over unknown work. Do not run the historical visual generator/raw staging over the repaired permanent data without retaining this measured collision correction.

## Tests actually performed

Godot **4.7.2**, headless and Compatibility/OpenGL rendered tests; RTX 3050 Laptop, 1280×720, fixed simulation delta 1/60 s. These are automated functional checks, **not performance benchmarks or human playtesting**. Diagnostic scripts and output paths are confined to this task's evidence directory.

| Test | Actual result | Evidence under `reports/main-hall-collision-fix/` |
| --- | --- | --- |
| Permanent pre-edit collision/visible probes | **41 PASS / 0 FAIL** | `before-headless.json` |
| Frozen-old collision reconstruction, rendered probes and three captures | **44 PASS / 0 FAIL** | `before-rendered.json` |
| Final full headless movement, surface and camera suite | **154 PASS / 1 FAIL** | `after-headless.json` |
| Final full rendered suite plus four captures | **158 PASS / 1 FAIL** | `after-rendered.json` |
| Matched old/current camera-only sweep | Old **3/2**, current **4/1**; residual failure detailed below | `camera-old-headless.json`, `camera-current-headless.json`, `camera-comparison.json` |
| All twelve rendered gallery launch/control regression | **466 PASS / 0 FAIL** | `gallery/launch-results.json`, `gallery/rendered.log` |
| Scoped-data and preservation checks | Exact allowed changes only; see preservation record | `preservation.json` |

Each final full run executes **78 movement cases**: 46 reachable routes and 32 deliberate blocking approaches across FPP/TPP. All pass their expected outcome. Coverage includes:

- Every one of the eight columns approached from the outer and inboard sides in each mode. Inboard contacts identify the intended column/drum collision owner.
- Outer-veranda traversal in both directions; all seven gaps between visible pairs traversed inward and outward; both former ghost locations traversed in both directions.
- Unchanged front stairs and main doorway, entry/exit in both modes, with the existing doors opened in memory only.
- Outer contact ends at z≈**-10.3103..-10.3090**, beside the real drum edge, rather than at the old invisible offset.
- **3,038 camera/body samples per full run**, including **1,296** veranda camera sweep poses (18 locations × 24 yaws × 3 pitches). Zero sampled authored-camera or visible player-upper-body overlaps. The real player uses its unchanged 1.8 m capsule and .28 m radius; the supplemental visible upper-body probe is smaller and does not replace actual movement/blocking checks.

The copied gallery suite changes only its output directory and explanatory output text. It retains the twelve canonical entries, immediate Hall TPP startup, walking/overview recovery, Tab, mouse look, E door dispatch, supported presets, Esc and Medicine's exception lifecycle. The other eleven assets/controllers and all existing door/Training fixes remain untouched.

## Remaining failed camera check: retained and investigated

**The final suite is not an all-pass result.** Its sole failed assertion is `all visible camera samples clear`: **27 Cedar trim overlaps** in the broad sweep. The authored collision query itself stays clear; the camera does not intersect the newly aligned visible columns/drums on these samples. Movement/body checks pass.

To distinguish a regression from an older limitation, the same 1,296 poses were run with the frozen old simple shapes restored **in memory only**, using the same current model, controller, roof and fixture. The original permanent file was not reverted for this experiment. Pose keys include player position, yaw and pitch:

| Visible mesh overlap category | Old collision | Corrected collision | New overlap poses |
| --- | ---: | ---: | ---: |
| Timber, including affected rear columns | 24 | **0** | **0** |
| Coping / drums | 0 | 0 | 0 |
| Cedar decorative trim | 31 | **27** | **0** |
| Total sampled overlapping camera poses | 55 | **27** | **0** |

Every residual Cedar overlap pose also overlaps with the old collision. Four old trim poses clear after the alignment; none is newly introduced. These are sphere-probe contacts, not a human judgment of 27 bad frames. No camera setting, visible trim or unrelated collision was changed to make this broader assertion pass. Near-wall compression remains possible. A separate camera/trim task would be needed for exhaustive visible-clearance acceptance.

Initial diagnostic evidence is preserved: the first probe used an inboard ray endpoint inside the inner wall and produced eight false column-gap failures (`harness-initial-probe.json`); its endpoints were corrected before application. An initial relative log path was rejected; subsequent logs use absolute paths. The first full suite already found the residual trim contacts; later diagnostics identify mesh names/poses and add inboard/entry coverage without removing the failing broad assertion or relaxing its probe radii.

Known host diagnostics: certificate-store errors remain; rendered diagnostic-outline runs also logged shader-cache save failures (`_save_to_cache`). Screenshots were written and models loaded, but these logs are not described as error-free. The gallery regression has the certificate diagnostic and no parser/missing-resource/input/freed-body failure. No system permission or cache setting was changed.

## Screenshots

**54 genuine Godot viewport captures** are present: 46 gallery captures and eight task-specific images. Before/after close-ups and final TPP were inspected by Codex. Orange lines below are diagnostic-only overlays of rear collision, created in memory for capture; they are not additions to the permanent model. The useful before outlines reconstruct the frozen old collision after application; the original pre-edit screenshot is separately retained as `before-TPP-rear-column.png`.

| View | Frozen old collision | Corrected permanent collision |
| --- | --- | --- |
| Rear close-up, collision outline | [Before](main-hall-collision-fix/before-rear-closeup-collision-outline.png) | [After](main-hall-collision-fix/after-rear-closeup-collision-outline.png) |
| Rear overview, collision outline | [Before](main-hall-collision-fix/before-rear-overview-collision-outline.png) | [After](main-hall-collision-fix/after-rear-overview-collision-outline.png) |

Normal gameplay views: [FPP facing the rear column](main-hall-collision-fix/after-FPP-rear-column.png), [TPP facing the rear column](main-hall-collision-fix/after-TPP-rear-column.png). These are automated captures, not human acceptance evidence.

## Changed files, rollback and next action

Existing files changed:

1. `assets/architecture/tang_main_hall/main_sect_hall.json` — only the specified rear column/drum records.
2. `HANDOFF.md` — current outcome, remaining limitations and next action.

New files: `tools/fix_main_hall_veranda_collision.py`, this report, and `reports/main-hall-collision-fix/` diagnostics, frozen backups, JSON results/logs, captures and redirected gallery harness. No permanent scene, model/source, material, controller/camera, other building, catalog, staging file, prior report, high-detail asset or original-project file was modified. Hash evidence and exact allowed-data comparison are in `main-hall-collision-fix/preservation.json`.

Final preservation checked **5,590 pre-existing test-project files**: only the two declared files changed, none is missing. All **1,599 recorded original-project files** and **62 pre-existing staged files** remain byte-identical. During this task, a separate workstream added **28 files under `staging/claude_environment_batch1/`**. They are listed separately in the preservation record, were left untouched, and were neither created nor reviewed/integrated by this Hall repair. Their presence is not a new asset-readiness claim. `main-hall-collision-fix/audit_state.py` reproduces the scoped-data and preservation assertions without modifying assets.

Rollback: restore **only** `assets/architecture/tang_main_hall/main_sect_hall.json` from `reports/main-hall-collision-fix/before/main_sect_hall.json.txt`. That is the complete task-start permanent JSON, including the earlier roof correction; do not restore raw staging or the historical baseline. No scene/model/controller rollback is needed.

Manual next action: open this test project's `project.godot`, run `scenes/asset_gallery.tscn` with F6, select Split-Cloud Main Sect Hall → Walk asset. It starts in TPP; WASD/mouse move/look, Tab switches FPP/TPP, E operates existing doors, 1 switches overview, Esc returns to gallery. Climb the front stairs, use the exterior side of the raised platform to reach the rear veranda, and walk past all eight columns. Approach each drum from both sides and walk through the two now-clear central locations. Turn near the rear windows to judge the recorded Cedar trim/camera limitation. Record human observations separately from these automated tests.

Not tested: final production character, NPC/navigation, final terrain/town placement, exported build, exhaustive contacts/roof walking, performance/low-end hardware and human keyboard/mouse acceptance. Unrelated Hall furniture/ring/front-collision observations remain outside this task. The readiness audit's column blocker is superseded by this targeted correction; its shared production/integration conditions still apply.

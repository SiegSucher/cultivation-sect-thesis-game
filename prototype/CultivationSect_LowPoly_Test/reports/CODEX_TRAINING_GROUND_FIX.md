# Martial Training Ground: collision repair and performance investigation

23 October 2026. Work confined to `prototype/CultivationSect_LowPoly_Test/`. `reports/CLAUDE_TRAINING_GROUND_AUDIT.md` was not present. Read the current handoff, canonical catalog, permanent scene/runtime data, source-generation references and stage-2 performance evidence instead.

**Outcome:** repaired the confirmed collision-data defect, **4,560 -> 4,476 roof triangles; 84 -> 0 degenerate triangles**. Every valid triangle remains exactly the same. The historical slower-converted rendering result was **not reproduced in the fresh matched baseline/current comparisons**. Separate-process and same-process timing variation remains large; no reliable FPS gain or loss can be attributed to this collision cleanup. No persistent rendering/shadow/material/geometry optimization was applied.

## Current asset and exact source of the defect

Canonical catalog entry: `martial_training_ground`.

- Permanent scene: `scenes/buildings/martial_training_ground.tscn`.
- Runtime: `scripts/martial_training_ground.gd`; shared shape helper `scripts/training_collision.gd`.
- Permanent physics data: `assets/architecture/martial_training_ground/martial_training_ground.json`, field **`roof_collision_faces`**.
- Visible model: `assets/architecture/martial_training_ground/martial_training_ground.glb`, with its existing distant model and seven reusable equipment GLBs in the same folder.
- Editable source: `source/martial_training_ground_low_poly.blend`.

The scene's runtime script explicitly constructs `StaticRoofUndersides` as a `ConcavePolygonShape3D` from the JSON array. Godot import does not generate this roof collision. Before repair the Godot shape retained all 4,560 input triangles, including the same 84 exact repeated-corner triangles.

| Layer inspected | Fresh finding |
| --- | --- |
| Current native Blender source, reopened read-only | 49 mesh objects, **0 exact / 0 near-zero triangles** at the recorded threshold |
| Nine current Training GLBs, parsed directly | **0 zero-area triangles**; nine historical baseline GLBs also have zero |
| Permanent Training JSON before repair | **84 exact zero-area triangles of 4,560** |
| Historical baseline JSON | Exactly equal to the complete pre-repair permanent JSON |
| Godot collision resource | Loads the JSON's same 84 degenerate faces; candidate loads 4,476 faces with zero degenerates |

The root cause is the **authoring tool's separate collision exporter**, not corruption of the current visible Blender mesh or GLB. Read-only reference files were copied into this evidence folder from the workspace's `assets/settlements/prototype/martial-training-ground/source/`:

- `build_training_ground.py`, `roof()` around lines 223-257: constructs a swept hip roof, accepts a valid quad based on its first triangle, then manually fans every quad into collision triangles.
- `training_design.py`, `pavilion()` and three calls around lines 135-182: Instructor pavilion, West rest shelter, East weapons shelter.

At the closed ridge, two consecutive corners of each final hip-end quad coincide. The quad contains one real triangle, so its face check passes. The later fan emits that valid triangle **and a second triangle with repeated corners and zero area**. Each roof has 14 collapsed quads on each of two end faces: **3 roofs x 2 ends x 14 = 84**. Source replay reproduces the frozen JSON coordinates exactly; this is not an inferred cleanup based only on an area threshold.

## Small reversible correction

New tool: **`tools/rebuild_training_roof_collision.py`**. It executes only an extracted copy of the original pure roof mathematics, with mesh/export hooks replaced by no-ops. It normalizes consecutive identical polygon corners **before** collision fan triangulation. It neither executes the original Blender export program nor saves visible meshes.

The repaired emitter generates a triangle at each collapsed ridge quad rather than a quad containing a duplicate corner. Assertions prove:

- The unmodified emitter reproduces every pre-repair JSON coordinate exactly.
- The repaired list is exactly the old nonzero triangle sequence: same coordinates, order and winding, with no new or changed valid face.
- All other JSON fields are identical, including simple solids, stairs, prop definitions/placements, scale, floor and origin.
- Collision surface area is identical: **351.7784256593428 m²** before/after.

**Only existing runtime file changed:** `assets/architecture/martial_training_ground/martial_training_ground.json`. The permanent `.tscn`, runtime scripts, all GLBs/materials/textures, Blender source, Hall startup, door repairs, gallery catalog and original project remain unchanged. This is a guarded migration from the frozen permanent JSON, not substitution of a raw staged asset.

Other files: new tool, this report, `HANDOFF.md`, and new evidence/diagnostics under `reports/training-ground-fix/`. The tool's default writes diagnosis/candidate evidence only; `--apply` requires exact task-start JSON bytes. Reapplying to an already changed resource intentionally stops rather than overwriting unknown work. Future collision regeneration should retain this corner-normalization rule; do not overwrite the repaired permanent JSON from the uncorrected historical exporter.

## Collision behavior and physics cost

`roof-physics.json` compares isolated old/candidate physics shapes on separate query layers. **5 PASS / 0 FAIL**:

- **11,046** bidirectional quarter-metre-grid ray comparisons: hit coverage and positions unchanged, zero mismatches.
- **789** .20 m camera-sphere sweep comparisons: safe travel fractions unchanged, zero mismatches.
- Original ray hits returned valid normals on those samples; no incorrect contact caused by the degenerate faces was reproduced.
- Live candidate shape contains 4,476 nondegenerate faces; the post-repair permanent shape is separately checked by the full facility regression.

Exact valid-face identity is the stronger coverage proof; finite ray/sphere samples supplement it. This does not claim every possible production-physics interaction was tested.

Eight alternating-order batches also timed 10,000 roof rays and 4,000 sphere casts per variant per batch. These include GDScript/query setup and are **query microbenchmarks**, not total game-physics or frame costs:

| Query time, microseconds | Old 4,560 faces: median [batch range] | Clean 4,476 faces: median [batch range] |
| --- | ---: | ---: |
| Ray | 6.105 [4.808-7.856] | 5.278 [4.792-8.562] |
| Sphere cast | 96.123 [80.600-119.097] | 94.831 [79.492-118.779] |

The ranges overlap substantially. A lower median in this small microbenchmark is not evidence of a gameplay FPS gain. Some unnecessary collision input existed, but no incorrect player collision or material frame-time overhead from these 84 faces was established. **They cannot explain the historical baseline-versus-converted regression because both variants had identical collision data.** Backend-internal treatment of every degenerate face was not inspected; no universal zero-overhead claim is made.

## Reproducing the historical rendering comparison

Historical evidence: `reports/LOW_POLY_STAGES_2_3_REPORT.md` and its original JSON/logs remain intact. New adapter: `training-ground-fix/bench.gd`, copied from `tools/benchmark_facility_stages.gd` without changing its poses, fields of view, sweep path or sample counts.

Conditions: Godot 4.7.2, Compatibility/OpenGL, RTX 3050 Laptop, 1280 x 720, project MSAA enum 2 (4x), VSync off, uncapped, 45-frame view warmup and 240 measured frame intervals. Existing ambient .55 and 180 m shadowed sun retained. Benchmark processes run sequentially with no concurrent conversion/hash/test workloads. FPP/TPP benchmarks disable the new indoor profile **in memory only**, equally for both variants, to retain the historical camera policy. Functional/gallery tests use the actual current controller settings.

Fresh full-rig order: historical baseline A1, converted B1, converted B2, baseline A2. The following fresh values average each variant's two runs. FPS is 1000 divided by mean frame interval; P95 is the mean of the two run-level P95 values. These are local observations, not hardware certification.

| View | Historical round-2 mean ms, baseline -> converted | Fresh mean ms, baseline -> converted | Fresh P95 ms, baseline -> converted | Fresh FPS, baseline -> converted | Draw calls, baseline -> converted |
| --- | ---: | ---: | ---: | ---: | ---: |
| Overview | 5.42 -> 7.77 | 6.361 -> 6.172 | 7.866 -> 6.793 | 157.2 -> 162.0 | 120 -> 108 |
| Court | 6.11 -> 9.94 | 7.505 -> 6.342 | 9.268 -> 7.004 | 133.2 -> 157.7 | 164 -> 146 |
| Shelter | 6.14 -> 10.80 | 7.514 -> 6.826 | 9.316 -> 8.112 | 133.1 -> 146.5 | 88 -> 77 |
| 360 sweep | 5.49 -> 8.49 | 6.237 -> 5.826 | 7.851 -> 6.520 | 160.3 -> 171.6 | 117.6 -> 105.9 |
| First person | 5.84 -> 10.00 | 7.529 -> 5.870 | 8.558 -> 7.206 | 132.8 -> 170.4 | 115 -> 103 |
| Third person | 6.53 -> 11.92 | 8.512 -> 6.624 | 9.561 -> 7.730 | 117.5 -> 151.0 | 121 -> 107 |

The earlier slower-converted result was not reproduced in this matched set. This is not proof it can never recur, nor evidence that the collision cleanup caused these improvements: **both variants still used the old identical roof data in the full comparison.** Host/load/cache/power conditions from the historical session are not recoverable from its records.

Fresh GLB audit confirms static render triangles **94,776 -> 88,020**, material surfaces **16 -> 13**, but vertex records **170,012 -> 216,685** after flat shading. The higher vertex count is real, but the new measurements do not establish it as a rendering defect. No speculative vertex welding, shading change or geometry rebuild was applied.

### Separating rendering, physics and shadows

Engine GPU viewport timestamps were added alongside wall-clock frame intervals. They measure work for this rendered view, not an external hardware trace. Coarse `Performance.TIME_PROCESS`/physics counters were also logged, but can include stale/startup/capture samples; they are not treated as precise isolated CPU costs.

Four further baseline/current runs disabled physics/player processing in memory, with identical old roof faces in both variants. The court remained faster in converted form: **7.750 -> 6.599 ms**, GPU **7.691 -> 6.532 ms**. Thus the converted/baseline difference there persists without active game physics. Other views drifted enough that subtracting total frame times would not yield a reliable physics-cost estimate.

Shadows-off experiments also retained identical old collision and changed only the sun's shadow flag **in the diagnostic process**. Initial runs exposed shader-cache save failures; they were retained as preliminary evidence. Four marked repeats show those errors occur before, not inside, measured windows. Their court GPU time was **2.343 -> 2.416 ms** and draw calls **44 -> 40**, versus the full-rig **7.450 -> 6.284 ms** and **164 -> 146**. This indicates substantial shadow-related rendering cost; it does not justify permanently disabling approved shadows. Cache failures and remaining timing variation limit precise attribution.

A shader cache stores compiled GPU programs on disk; the engine's [OpenGL cache writer reference](https://github.com/godotengine/godot/blob/4.5/drivers/gles3/shader_gles3.cpp#L581-L595) illustrates that disk-write path. That is a 4.5 source reference, not a claim to have inspected the exact 4.7.2 backend. The current diagnosis comes from actual 4.7.2 logs and explicit timing-window markers. No system permission, global cache or persistent project-render setting was changed.

## Before/after roof repair frame times: no reliable gain established

Separate current-model runs alternated old/clean/clean/old collision, leaving geometry and lighting identical. They were highly variable: for example, court means ranged **2.621-3.257 ms old** versus **8.960-10.824 ms clean**. Those unfavorable clean results are retained, not discarded. Identical old-roof runs themselves differed greatly, so this series cannot establish the repair as the cause of a slowdown.

A final single-process experiment kept one live scene/material set and alternated only the roof faces outside each warmup. Eight blocks per view used old/clean/clean/old/clean/old/old/clean, each with the same 45/240-frame procedure:

| View | Old roof mean ms [block range] | Clean roof mean ms [block range] | Paired difference interval, clean minus old |
| --- | ---: | ---: | ---: |
| Overview | 6.970 [6.391-8.692] | 6.206 [5.792-6.401] | -3.033 to +1.505 ms |
| Court | 4.053 [2.553-6.739] | 4.798 [2.549-7.573] | -1.870 to +3.359 ms |
| Shelter | 4.603 [2.648-5.809] | 4.466 [2.699-6.150] | -1.027 to +.753 ms |

Intervals are descriptive t-based 95% intervals from only four adjacent old/clean paired differences per view, not a robust causal performance estimate. All span zero; direction varies by view and pair. Draw/primitive counts are identical in every same-process block. Five corresponding old/clean screenshots (overview, court, shelter, FPP, TPP) are **pixel-identical**. No consistent frame-time benefit or penalty from the cleanup was isolated.

Overall evidence: **20 separate benchmark processes / 96 view samples, plus 24 same-process blocks: 28,800 measured frame intervals**. All raw results, preliminary runs and logs remain under `training-ground-fix/benchmarks/`. Summaries: `performance-analysis.json`, `paired-analysis.json`. GPU clocks, OS/DWM/other-app scheduling, foreground focus, power/thermals and representative hardware were not controlled. **The historical regression's cause remains unconfirmed; further rendering optimization is deferred.**

## Functional, collision and gallery verification

| Check | Actual result |
| --- | --- |
| Collision-only authoring replay and exact valid-face/other-field identity | PASS; `source-replay.json` |
| Read-only native source and 18 baseline/current GLB audits | No zero-area triangles; `native-source.json`, `glb-inspection.json` |
| Isolated old/new physics coverage and sphere sweeps | **5 PASS / 0 FAIL**, 11,046 rays + 789 sweeps |
| Existing Training functional suite, redirected | **66 PASS / 0 FAIL headless** |
| Same suite, rendered movement/camera/equipment captures | **87 PASS / 0 FAIL** |
| Existing all-twelve gallery launch/control audit, redirected | **466 PASS / 0 FAIL** |

The copied Training suite updates only the obsolete four-entry catalog expectation to twelve and adds a permanent-shape assertion for 4,476 valid faces. Existing tolerances/routes are unchanged. It covers the central court, side/entrance routes, shelter/dais access, seven equipment kinds, real movement and blocking, FPP/TPP camera boundaries, and reusable props. The gallery suite retains Hall's immediate TPP startup, other eleven intended modes, documented controls, overview recovery, Esc and Medicine's exception lifecycle. Previous test evidence is not overwritten.

There are **178 genuine viewport captures** across benchmarks and regressions. Selected repaired-roof images were inspected by Codex. [Repaired shelter view](training-ground-fix/benchmarks/training-after-roofClean-1-shelter.png); [functional overview](training-ground-fix/functional/01-elevated-overview.png). Captures and automated inputs do not constitute human playtesting or user acceptance.

## Exact changes, remaining risks and next action

Existing files changed: the Training JSON roof array and `HANDOFF.md` only. New files: `tools/rebuild_training_roof_collision.py`, this report and `reports/training-ground-fix/` evidence/scripts/backups. Final hashes and file comparisons: `training-ground-fix/preservation.json`. No scene replacement, raw staged copy, visual export, material edit, scale/placement change or unrelated collision repair occurred.

Remaining limitations:

- No incorrect roof collision reproduced on tested routes, but future production-player dimensions, roof walking, NPC/navigation and every possible edge contact remain unverified.
- No human playtest, exported executable, final terrain/town placement, sustained-load or representative low-end hardware certification.
- Known host certificate-store error remains. The shadow-diagnostic cache-write errors are recorded; marked repeats have no errors inside timed windows. A settings-inspection attempt also encountered default user-log write failures; functional tests use explicit report-local logs. Final functional/gallery logs have no asset/parser/missing-resource failure.
- Rendering frame-time variability and the original historical slowdown are unresolved as causal questions. No FPS claim is attached to removing the 84 invalid faces.

Next diagnostic if a stable slowdown recurs: repeat baseline/current comparison in a controlled foreground session with writable normal shader cache, fixed power/thermal conditions and a GPU/CPU scheduling trace; record clocks/load and distinguish shadow submission, vertex processing and host stalls. Do not change approved meshes/materials/shadows on the basis of the old isolated timings alone.

Manual verification: gallery -> Large Martial Training Ground -> Walk asset. It intentionally starts walking in FPP; WASD/mouse move/look, Tab shows the TPP figure, Esc returns to gallery. Walk the instructor and both side shelters, stairs/dais, court and equipment aisles. 1 is not an overview binding in this walk-only fixture. Record physical-input and camera observations separately from automation.

Rollback: restore `assets/architecture/martial_training_ground/martial_training_ground.json` from `reports/training-ground-fix/before/martial_training_ground.json.txt`. No model/source/scene/controller rollback is needed. The original source-generation references are read-only copies; the original production project and all high-detail recovery assets remain available.

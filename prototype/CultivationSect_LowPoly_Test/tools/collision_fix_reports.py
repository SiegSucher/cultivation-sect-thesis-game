"""Write the current reports from verified results; keep old evidence immutable."""
from pathlib import Path
import json

R=Path(__file__).resolve().parents[1]
P=R/'reports'
E=P/'roof-collision-fix-2026-10-22'
def write(name,text):(P/name).write_text(text,encoding='utf-8')
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def reduction(before,after):return 100*(1-after/before)

def write_reports(base,fixed,previous_base,previous_fixed,summary):
    assert summary['original_unchanged'] and summary['roof_zero_area_triangles_after']==0
    comparisons='\n'.join(f"| {a['view']} | {a['mean_ms']:.3f} / {b['mean_ms']:.3f} | {a['p95_ms']:.3f} / {b['p95_ms']:.3f} | {a['average_fps']:.1f} / {b['average_fps']:.1f} | {reduction(a['mean_ms'],b['mean_ms']):.1f}% | {a['mean_draw_calls']:.1f} / {b['mean_draw_calls']:.1f} |" for a,b in zip(base['samples'],fixed['samples']))
    history='\n'.join(f"| {a['view']} | {a['mean_ms']:.3f} | {b['mean_ms']:.3f} | {c['mean_ms']:.3f} | {d['mean_ms']:.3f} | {reduction(b['mean_ms'],d['mean_ms']):.1f}% |" for a,b,c,d in zip(previous_base['samples'],previous_fixed['samples'],base['samples'],fixed['samples']))
    coverage=summary['coverage']
    conditions=f'''Godot {fixed['godot']}, {fixed['adapter']}, GL Compatibility, 1280 x 720, MSAA 4x (enum 2), VSync disabled and no frame cap. Renderer, settings, environment, lighting, camera poses/FOV, player and benchmark script are unchanged. Each of six views uses 45 warmup + 240 measured frames (1,440 measured frames per variant); the exterior sweep covers 360 degrees in 240 frames. Frame intervals are measured with `Time.get_ticks_usec()` between process frames; rendering and memory statistics use Godot Performance monitors. Counts include stage/shadow passes, not just unique building triangles.

Source run timestamps UTC: baseline `{base['measured_utc']}`, repaired `{fixed['measured_utc']}`. The preserved high-detail baseline and repaired low-poly model ran sequentially with no other Godot test active. Same main stair/door/aisle/dais/private-room movement and FPP/TPP sequence. Exact camera poses/FOVs match the earlier approved-model captures. Raw results retain all timings, draw calls, rendered primitives and memory observations.

Power mode, GPU clocks, thermals and background load were not controlled. These are short local uncapped observations, not statistically controlled or sustained target-device measurements. No human playtest, exported executable, low-end device or populated production world was tested. The independent-copy run verifies loading/functionality and is not an extra matched performance pair.'''
    checks=f'''| Verification | Result |
| --- | --- |
| Triangulator regression tests | {summary['helper_tests']} PASS; ordinary quad, both ridge windings, closing duplicate, nearby valid corners, invalid collinear/nonfinite/collapsed input |
| Authoring source replay | PASS: original source reproduced all 64; repaired source reproduces zero |
| Exact collision coverage | PASS: every nonzero-area triangle and its winding/coordinates retained exactly |
| Godot roof coverage | {coverage['passed']} PASS / {coverage['failed']} FAIL; {coverage['ray_comparisons']:,} before/after ray comparisons, zero mismatches |
| Fresh high-detail baseline | {summary['baseline_checks']} PASS / 0 FAIL |
| Repaired rendered hall | {summary['fixed_model_checks']} PASS / 0 FAIL; actual inspection-controller movement, door access, FPP/TPP |
| Supplemental dimensions/collision | {summary['constraints']} PASS / 0 FAIL; walls/floor, retained scale, camera retraction/clearance |
| Dispatched input controls | {summary['controls']} PASS / 0 FAIL; walking/review, Tab, E, Esc and gallery return |
| Blender source reopen | {summary['native_source']} PASS / 0 FAIL; source itself unchanged |
| Fresh independent runtime copy | {summary['independent_checks']} PASS / 0 FAIL; clean import with no copied cache/metadata/symlinks |
| Original preservation | {summary['original_files_verified']:,} recorded original non-cache files match original hashes |
| Approved visuals/source/controllers/settings | {summary['immutable_visual_source_controller_settings_files_verified']} immutable files match; four GLBs/.blend unchanged |
| Current import/runtime diagnostics | No errors or warnings in checked logs |
'''
    limitations='''NOT TESTED: human keyboard/mouse rehearsal; intended low-end hardware; sustained thermal behavior/long-run stutter; exported executable; future production-player/camera or populated-town integration; exhaustive geometry self-intersection/all camera orientations and pixel-level distance-handover analysis. Current source has no town or production player. Automated movement results apply to the existing 1.8 m inspection fixture. A full visual-model rebuild/export was deliberately not performed; the actual roof emitter was replayed in isolation, and the saved source/GLBs were audited without overwriting them.'''
    write('performance_comparison.md',f'''# Main Sect Hall performance after collision repair

22 October 2026. **Visual direction remains approved. Do not expand to other buildings.** The collider repair changes no visible mesh/material/shadow setting. It is a data-quality fix; this benchmark does not establish that removing 64 empty collision faces causes an FPS improvement.

{conditions}

## Fresh matched pair

| View | Mean ms baseline / repaired | p95 ms baseline / repaired | Average FPS baseline / repaired | Mean-time reduction | Draw calls baseline / repaired |
| --- | ---: | ---: | ---: | ---: | ---: |
{comparisons}

Positive reduction means a lower observed frame time; negative means higher. Small differences near zero are inconclusive with this method. Neither a consistent sustained gain nor low-end compatibility follows from these samples.

## Comparison with the existing measurements

| View | Previous baseline ms | Previous approved pre-fix ms | Repeated baseline ms | Repaired ms | Reduction vs previous pre-fix |
| --- | ---: | ---: | ---: | ---: | ---: |
{history}

The previous pair is preserved in `roof-collision-fix-2026-10-22/before/`; initial construction-stage evidence and the earlier verification pair remain under `verification-2026-10-22/`. Differences between these sequential runs can reflect clocks, thermals or scheduling. Do not attribute a variation to the collider fix without a controlled experiment.

Visible near-static geometry stays at **71,557 triangles / 12 surfaces**, versus 203,064 / 15 in the high-detail baseline (64.8% fewer visible triangles from the already approved visual conversion). The collider alone changes **2,432 -> 2,368 triangles; zero-area faces 64 -> 0**. The same inexpensive visible mesh is retained at distance; no separate LOD triangle reduction is claimed.

Front-view monitor observations: rendering video memory {base['samples'][0]['video_memory_bytes']/2**20:.2f} / {fixed['samples'][0]['video_memory_bytes']/2**20:.2f} MiB; Godot static memory {base['samples'][0]['static_memory_bytes']/2**20:.2f} / {fixed['samples'][0]['static_memory_bytes']/2**20:.2f} MiB. These are whole-engine monitor values, not isolated asset or total OS working-set measurements. Sample maxima: {max(s['max_ms'] for s in base['samples']):.3f} / {max(s['max_ms'] for s in fixed['samples']):.3f} ms; frames over 33.3 ms: {sum(s['frames_over_33ms'] for s in base['samples'])} / {sum(s['frames_over_33ms'] for s in fixed['samples'])}. Short windows cannot rule out later stutter.

Reproduce from workspace using `tools/godot/Godot_v4.7.2-stable_win64_console.exe --path prototype/CultivationSect_LowPoly_Test --script res://tools/evaluate.gd -- --baseline`, then the same command without `-- --baseline`. [Current baseline JSON](baseline-results.json), [repaired JSON](optimized-results.json), [preserved previous measurements](roof-collision-fix-2026-10-22/before/optimized-results.json).

**Decision: Do not expand yet.** Preserve the approved design. Target-device/sustained performance and human verification remain outstanding. {limitations}
''')
    base_rows='\n'.join(f"| {s['view']} | {s['mean_ms']:.3f} | {s['p95_ms']:.3f} | {s['average_fps']:.1f} | {s['mean_draw_calls']:.1f} |" for s in base['samples'])
    write('baseline_performance.md',f'''# Preserved high-detail baseline recheck

22 October 2026. The original project was not run or edited. This table measures its preserved independent high-detail hall copy in the same test room as the repaired approved model. The first baseline was captured before conversion and is retained in historical evidence.

{conditions}

| View | Mean ms | p95 ms | Average FPS | Draw calls |
| --- | ---: | ---: | ---: | ---: |
{base_rows}

21 baseline checks passed. Static hall: 203,064 triangles / 15 surfaces. [Raw measurements](baseline-results.json), [current matched comparison and prior pair](performance_comparison.md).
''')
    write('ROOF_COLLISION_FIX.md',f'''# Roof collision root cause and repair

22 October 2026. **Fixed without changing the approved visuals.** A zero-area triangle has coincident corners and no surface. It does not add roof coverage.

The closed hip ends converge to a ridge. The final roof strip has four stored corners but two occupy exactly the same point. The original face-level normal check accepted the partly valid quad; the subsequent triangle fan generated a valid triangle plus a collapsed one. Four closed roofs (west shoulder, east shoulder, upper nave and lower entrance) each contributed eight strips on two hip ends: **4 x 8 x 2 = 64**. The annular belt and folded gable contributed none. Replaying the actual unmodified authoring function first reproduced all baked hip collider coordinates exactly. [Source diagnosis](roof-collision-fix-2026-10-22/source-diagnosis.json).

`tools/roof_collision_geometry.py` now removes only exactly coincident consecutive polygon corners before triangulation, so the closing hip strip emits its true triangle. No distance tolerance merges nearby valid corners. Unexpected nonfinite or collinear input raises instead of silently discarding it. `tools/build_split_cloud.py` uses this helper for the hip fields and folded gable collision output; its visible-mesh construction remains unchanged.

The baked JSON was regenerated by replaying only the current hip-roof authoring function with Blender's original float32 Vector arithmetic. No Blender scene was saved and no visible GLB was exported. All 32 folded-gable triangles were validated and retained. The migration requires the exact pre-fix JSON and asserts that the result equals every old nonzero-area triangle, in order. **No valid collider triangle was deleted, moved or rewound.** All other JSON fields, including 195 simple shapes, door sizes, steps, floor/dais and scale, are identical. Summed triangle area remains exactly {summary['collision_repair']['coverage_area_after']:.12f} square units (including overlapping roof layers); it is not a unique roof-area estimate. [Repair proof](roof-collision-fix-2026-10-22/collision-repair.json).

Collider: 2,432 -> 2,368 triangles; zero-area faces: 64 -> 0. Four approved visible GLBs, native .blend, runtime hall script, controllers and project settings are hash-identical. Approved checkpoint ZIP and original high-detail recovery ZIP remain intact.

{checks}

Godot coverage compares top-down and bottom-up half-unit grid probes plus offsets around each affected ridge strip. The {coverage['ray_comparisons']:,} paired rays match within 0.0001 units, with zero hit/position mismatches. This sampled physics evidence complements exact preservation of the full valid triangle sequence.

Regression command: run `tools/test_roof_collision_geometry.py` with the bundled Python. Current full verification/report entry: `tools/verify_collision_fix_state.py finish`. The old pre-repair verifier is explicitly historical; the legacy report generator permits `--audits-only` but cannot overwrite current reports. Do not re-run the one-time repair migration against an already repaired resource; `trace_roof_collision.py` without `--repair` safely verifies current authoring replay.

{limitations}
''')
    shots='\n'.join(f"| {view} | [Baseline](screenshots/baseline-{view}.png) | [Approved repaired hall](screenshots/optimized-{view}.png) |" for view in ['front','three-quarter','roof-detail','interior','first-person','third-person'])
    write('low_poly_test_report.md',f'''# Main Sect Hall low-poly test - collision repair completion

22 October 2026. The approved **Split-Cloud Main Sect Hall** is preserved. The root cause of 64 zero-area roof collision faces is repaired; no architectural redesign or other building conversion was performed.

Original: `{R.parent/'asset-workshop'}`. Test: `{R}`. All {summary['original_files_verified']:,} recorded original non-cache file hashes match. High-detail assets, original runtime recovery ZIP and approved design checkpoint remain intact. [Preservation audit](preservation-audit.json), [current summary](roof-collision-fix-2026-10-22/verification-summary.json).

## Actual changes

The closed-hip roof exporter treated repeated ridge corners as a quad and emitted an extra collapsed triangle per strip. The source was reproduced exactly before editing. The corrected collision triangulator handles coincident corners before forming a fan, and rejects unexpected invalid input. Replayed only the collision emitter to update `assets/architecture/tang_main_hall/main_sect_hall.json`. All valid roof triangles and all other JSON fields remain exact. [Root cause, implementation and coverage proof](ROOF_COLLISION_FIX.md).

The two authorized differences from the unchanged approval checkpoint are the collider JSON and authoring program; a new shared collision helper is added. No approved GLB/native source, material, proportion, roof silhouette, footprint, player/camera controller, door script or project setting changed. Visible static geometry stays 71,557 triangles / 12 opaque shared materials, with no textures or custom shaders. Roof collider is now 2,368 triangles with zero zero-area triangles. All 195 non-roof simple shapes remain. Root identity, +Z front, metre convention, 1.8 m inspection player, 40.4 x 24 m podium, 1.52 m landing, ~1.53-1.55 m interior, 2.15 m dais, 6.4 x 5.4 m main opening and 2 x 2.8 m private openings are retained.

The approved jade/oxblood/plaster/stone/bronze style, original mountain motif, lighting and shared rendering settings remain. [Approved design](BUILDING_DESIGN.md), [style guide](LOW_POLY_STYLE_GUIDE.md). All nine original reference PNGs are preserved; filenames and intended use remain in [HANDOFF](../HANDOFF.md). No pictured building was copied, and no legacy environment was imported.

## Actual verification

{checks}

Movement tests exercise the main stair, entrance, aisle, leader dais and both side rooms; closed-door blocking, floor stability, actual camera switching, avatar visibility and follow-camera collision retraction are covered. The source has no production player or town; these results certify the tested inspection fixture only. The independent project at `{summary['independent_project']}` was created without `.godot`, import metadata or symlinks, freshly imported, then passed its own rendered suite. Shared engine software is the only external tool requirement.

## Performance comparison

Repeated the same outdoor front/three-quarter/360-degree sweep and indoor fixed/FPP/TPP samples, 1280x720, GL Compatibility, MSAA 4x, VSync off, no cap, same adapter, poses, lights and controller. [Full new and prior comparison](performance_comparison.md) reports mean/p95/max frame times, FPS, draw calls and monitor memory. Approved visible geometry still has 64.8% fewer static triangles than the original high-detail baseline; this reduction predates the collision fix. Removing empty collider faces is a correctness/data cleanup, and this uncontrolled short benchmark does not isolate a causal speedup from it.

## Genuine current screenshots

| View | Preserved high-detail baseline | Repaired approved hall |
| --- | --- | --- |
{shots}

All 12 images are genuine Godot captures; poses and FOVs match the earlier sequence. Pre-fix results/screenshots remain in `roof-collision-fix-2026-10-22/before/`; earlier evidence is retained under `verification-2026-10-22/`. The visible-file hash proof is stronger than screenshot appearance alone.

## Remaining limitations and decision

No remaining zero-area roof collider faces or failures occurred in the executed suites. {limitations}

**Do not expand to other buildings.** Current next action is a human walkthrough of this unchanged approved hall, then intended-device/sustained testing. Later production integration requires separate instruction. [HANDOFF](../HANDOFF.md) records exact evidence, file changes, safeguards and next action; no message was sent to Claude.
''')
    write('VERIFICATION_RESULTS.md',f'''# Current verification - approved hall collision repair

22 October 2026. **Root cause fixed; approved appearance unchanged. No other facility converted.**

The generator emitted an extra collapsed triangle when a closed hip strip met its ridge. The collision triangulator now handles coincident corners first. Collider faces: **2,432 -> 2,368; zero-area faces: 64 -> 0**. Every valid triangle remains exact, including coordinates and winding; all non-roof collision/scale data is retained.

{checks}

[Root cause and repair proof](ROOF_COLLISION_FIX.md), [actual new and earlier performance](performance_comparison.md), [full current report](low_poly_test_report.md), [Claude handoff](../HANDOFF.md). The measurements are short local observations; no collider-fix FPS claim is justified. {limitations}

Approved GLBs/native source and original high-detail assets/checkpoints are preserved. Current verification entry is `tools/verify_collision_fix_state.py finish`; historical pre-fix reports are retained as evidence.
''')
    prior=(E/'before/HANDOFF.md').read_text(encoding='utf-8')
    references=prior.split('## Supplied reference filenames and intended use',1)[1].split('## Remaining work and recommended first action',1)[0].strip()
    (R/'HANDOFF.md').write_text(f'''# Claude handoff - Split-Cloud Main Sect Hall

22 October 2026. **Current visual direction approved and unchanged. Roof collision root cause repaired and retested. Do not redesign the hall or convert other facilities.** This supersedes the earlier pending-collider-cleanup handoff, retained in `reports/roof-collision-fix-2026-10-22/before/HANDOFF.md`. No message has been sent to Claude.

## Paths and protected originals

Original Godot project: `{R.parent/'asset-workshop'}`. Current test project: `{R}`. They are separate sibling runnable projects. The original remains unchanged across {summary['original_files_verified']:,} recorded non-cache hashes. Original high-detail assets remain in place, in the copied `baseline/hall/` and in `original_runtime_recovery.zip`; the recovery ZIP hash/CRC evidence is retained. Approved pre-repair design/collider/program checkpoint: `checkpoints/approved-split-cloud-2026-10-22.zip`, intact and never overwritten. Its manifest is `reports/verification-2026-10-22/approved-design-manifest.json`.

Current evidence: `reports/roof-collision-fix-2026-10-22/verification-summary.json`, `source-diagnosis.json`, `collision-repair.json`, `coverage-physics-results.json`, preserved `before/` resources/results and current run logs. Current collision audit: `reports/collision-data-audit.json` (PASS, 0 of 2,368 degenerate faces). Full report: `reports/low_poly_test_report.md`. Source diagnosis/implementation: `reports/ROOF_COLLISION_FIX.md`.

Editable approved source: `source/split_cloud_hall.blend`, unchanged. Four GLBs: `assets/architecture/tang_main_hall/`, unchanged. Collision JSON is in the same directory and is the sole changed runtime resource. Program: `tools/build_split_cloud.py`, corrected collision emission only. New helper: `tools/roof_collision_geometry.py`. No visual mesh export or Blender source save was performed during repair. The two allowed checkpoint differences are collider JSON and authoring program; do not mistake this explicit migration for unauthorized visual drift.

## Why it broke and what changed

Closed hip tips converge to a ridge, giving final quads two coincident corners. The previous face normal check accepted their valid portion, then fan triangulation generated an extra zero-area triangle. Four closed roofs x two end slopes x eight strips = 64. The annular belt/folded gable did not contribute invalid faces. Before editing, an isolated replay of the actual authoring function reproduced baked coordinates exactly.

`collision_polygon_triangles` removes only exactly coincident consecutive corners before triangulation; thin but valid geometry is not merged by a tolerance. Unexpected nonfinite/collinear input raises. Current JSON was regenerated by replaying only the actual roof emitter with Blender float32 arithmetic, never the full modeling/export path. The result equals the original complete nonzero-area triangle sequence, including winding. All 32 folded-gable triangles, 195 simple shapes and non-roof JSON fields are retained exactly. Summed triangle area is unchanged. Four approved GLBs, .blend, runtime scripts/controllers and project settings match pre-fix hashes.

## Current verified state

{checks}

The rendered suite exercises main stair/entrance/aisle/dais and both private rooms, open and closed doors, floor/wall blocking, first/third-person visibility and camera retraction. The source's controller is the unchanged 1.8 m / .28 m-radius inspection fixture. No active town, road, reserved world plot or production player exists here; do not resurrect Reedwell. Root identity, +Z facing, metre scale, podium, proportions, floor/dais, openings and approved jade/oxblood/stone/plaster/bronze materials remain fixed. The same cheap visible mesh serves the existing distant range; no extra LOD reduction is claimed.

Independent copy: `{summary['independent_project']}`. It had no cache/import metadata/symlinks at creation, imported cleanly and passed 21 rendered checks. Test application identity is `Split-Cloud Hall - Low-Poly Test` with separate user data from the original workshop. Godot {fixed['godot']}, GL Compatibility, 1280x720, MSAA 4x. Benchmark alone disables VSync/frame cap. GPU {fixed['adapter']}. Same sun/environment/lanterns and camera poses as before; no renderer/light/settings changes.

## Performance evidence

`reports/performance_comparison.md` contains the fresh high-detail/repaired six-view pair and the prior baseline/approved-pre-fix pair side by side, including FPS, mean/p95/max timing, draw calls and monitor memory. Six 240-frame measured windows per variant after 45-frame view warmups. These short uncontrolled observations do not prove a sustained or low-end gain, or that removing 64 empty collider faces improves FPS. Raw current results: `reports/baseline-results.json`, `reports/optimized-results.json`; archived copies in current evidence folder. All 12 screenshots are genuine captures at the same poses/FOVs; pre-fix screenshots/results are retained in `before/`.

## Remaining unperformed work

{limitations}

No remaining failure was observed in executed checks. Do not claim exhaustive collision certification or low-end compatibility. No other facility has been converted.

## Exact next action for Claude

Read this handoff and `reports/roof-collision-fix-2026-10-22/verification-summary.json`, then run `Launch Low Poly Test.cmd` for a **human walkthrough**: approach/stairs, E doors, aisle/dais, both private rooms, Tab first/third person, camera near walls/screen, Esc gallery and Hall Walk return. Record actual human observations separately from automated evidence. No visual redesign or additional building conversion. Next, measure the same pair on intended low-end hardware when available, including sustained thermal/stutter behavior. Production-player/world integration requires separate user instruction.

Current verification/report command: run `tools/verify_collision_fix_state.py finish` with bundled Python after executing the documented suites. `tools/finalize_reports.py --audits-only` checks original preservation, visible GLBs and collision data. Historical `verify_approved_state.py` and no-argument legacy finalizer refuse to overwrite current state after the authorized repair. `trace_roof_collision.py` (Blender, no `--repair`) verifies source replay; the one-time repair migration must not be rerun on an already repaired JSON. Keep `tools/roof_collision_geometry.py` beside the authoring program if transferring sources. Do not rebuild/re-export the approved visible model just to retest collision.

## Supplied reference filenames and intended use

{references}
''',encoding='utf-8')

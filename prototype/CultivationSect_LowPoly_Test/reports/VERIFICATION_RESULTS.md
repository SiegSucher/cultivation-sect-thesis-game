<!-- stages-2-3-current -->
> Current continuation: Training Ground and Scripture Pavilion and their props/leaves are now converted and verified. [Stages 2–3 report](LOW_POLY_STAGES_2_3_REPORT.md) contains actual results, two benchmark rounds, screenshots and limitations. The earlier Hall/stage-1 measurements below are historical, not a whole-town claim. Training retains 84 inherited roof collider degenerates.

> Current scope: Hall verification below is historical evidence. The authorized environment continuation has completed stage 1 (Sect Gate). See [inventory](LOW_POLY_CONVERSION_INVENTORY.md), [stage report](LOW_POLY_STAGE_1_REPORT.md) and [current handoff](../HANDOFF.md). Other facilities remain unconverted.

# Current verification - approved hall collision repair

22 October 2026. **Root cause fixed; approved appearance unchanged. No other facility converted.**

The generator emitted an extra collapsed triangle when a closed hip strip met its ridge. The collision triangulator now handles coincident corners first. Collider faces: **2,432 -> 2,368; zero-area faces: 64 -> 0**. Every valid triangle remains exact, including coordinates and winding; all non-roof collision/scale data is retained.

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


[Root cause and repair proof](ROOF_COLLISION_FIX.md), [actual new and earlier performance](performance_comparison.md), [full current report](low_poly_test_report.md), [Claude handoff](../HANDOFF.md). The measurements are short local observations; no collider-fix FPS claim is justified. NOT TESTED: human keyboard/mouse rehearsal; intended low-end hardware; sustained thermal behavior/long-run stutter; exported executable; future production-player/camera or populated-town integration; exhaustive geometry self-intersection/all camera orientations and pixel-level distance-handover analysis. Current source has no town or production player. Automated movement results apply to the existing 1.8 m inspection fixture. A full visual-model rebuild/export was deliberately not performed; the actual roof emitter was replayed in isolation, and the saved source/GLBs were audited without overwriting them.

Approved GLBs/native source and original high-detail assets/checkpoints are preserved. Current verification entry is `tools/verify_collision_fix_state.py finish`; historical pre-fix reports are retained as evidence.

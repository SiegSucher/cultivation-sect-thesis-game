# Main Sect Hall performance after collision repair

22 October 2026. **Visual direction remains approved. Do not expand to other buildings.** The collider repair changes no visible mesh/material/shadow setting. It is a data-quality fix; this benchmark does not establish that removing 64 empty collision faces causes an FPS improvement.

Godot 4.7.2-stable (official), NVIDIA GeForce RTX 3050 Laptop GPU, GL Compatibility, 1280 x 720, MSAA 4x (enum 2), VSync disabled and no frame cap. Renderer, settings, environment, lighting, camera poses/FOV, player and benchmark script are unchanged. Each of six views uses 45 warmup + 240 measured frames (1,440 measured frames per variant); the exterior sweep covers 360 degrees in 240 frames. Frame intervals are measured with `Time.get_ticks_usec()` between process frames; rendering and memory statistics use Godot Performance monitors. Counts include stage/shadow passes, not just unique building triangles.

Source run timestamps UTC: baseline `2026-10-22T05:54:16`, repaired `2026-10-22T05:55:25`. The preserved high-detail baseline and repaired low-poly model ran sequentially with no other Godot test active. Same main stair/door/aisle/dais/private-room movement and FPP/TPP sequence. Exact camera poses/FOVs match the earlier approved-model captures. Raw results retain all timings, draw calls, rendered primitives and memory observations.

Power mode, GPU clocks, thermals and background load were not controlled. These are short local uncapped observations, not statistically controlled or sustained target-device measurements. No human playtest, exported executable, low-end device or populated production world was tested. The independent-copy run verifies loading/functionality and is not an extra matched performance pair.

## Fresh matched pair

| View | Mean ms baseline / repaired | p95 ms baseline / repaired | Average FPS baseline / repaired | Mean-time reduction | Draw calls baseline / repaired |
| --- | ---: | ---: | ---: | ---: | ---: |
| front | 3.408 / 2.475 | 4.027 / 3.004 | 293.4 / 404.1 | 27.4% | 125.0 / 98.0 |
| three-quarter | 3.366 / 2.362 | 3.968 / 2.978 | 297.1 / 423.4 | 29.8% | 116.0 / 92.0 |
| 360-degree exterior sweep | 3.429 / 2.409 | 3.981 / 2.903 | 291.6 / 415.1 | 29.8% | 114.4 / 90.4 |
| interior | 5.295 / 3.936 | 6.129 / 5.017 | 188.8 / 254.0 | 25.7% | 123.0 / 100.0 |
| first-person interior | 3.866 / 3.702 | 4.964 / 4.692 | 258.7 / 270.1 | 4.2% | 104.0 / 87.0 |
| third-person interior | 3.904 / 3.783 | 5.052 / 5.034 | 256.1 / 264.4 | 3.1% | 164.0 / 135.0 |

Positive reduction means a lower observed frame time; negative means higher. Small differences near zero are inconclusive with this method. Neither a consistent sustained gain nor low-end compatibility follows from these samples.

## Comparison with the existing measurements

| View | Previous baseline ms | Previous approved pre-fix ms | Repeated baseline ms | Repaired ms | Reduction vs previous pre-fix |
| --- | ---: | ---: | ---: | ---: | ---: |
| front | 3.352 | 2.474 | 3.408 | 2.475 | -0.0% |
| three-quarter | 3.201 | 2.387 | 3.366 | 2.362 | 1.0% |
| 360-degree exterior sweep | 3.113 | 2.441 | 3.429 | 2.409 | 1.3% |
| interior | 4.326 | 3.963 | 5.295 | 3.936 | 0.7% |
| first-person interior | 3.738 | 3.797 | 3.866 | 3.702 | 2.5% |
| third-person interior | 3.820 | 3.821 | 3.904 | 3.783 | 1.0% |

The previous pair is preserved in `roof-collision-fix-2026-10-22/before/`; initial construction-stage evidence and the earlier verification pair remain under `verification-2026-10-22/`. Differences between these sequential runs can reflect clocks, thermals or scheduling. Do not attribute a variation to the collider fix without a controlled experiment.

Visible near-static geometry stays at **71,557 triangles / 12 surfaces**, versus 203,064 / 15 in the high-detail baseline (64.8% fewer visible triangles from the already approved visual conversion). The collider alone changes **2,432 -> 2,368 triangles; zero-area faces 64 -> 0**. The same inexpensive visible mesh is retained at distance; no separate LOD triangle reduction is claimed.

Front-view monitor observations: rendering video memory 114.53 / 53.86 MiB; Godot static memory 46.57 / 41.09 MiB. These are whole-engine monitor values, not isolated asset or total OS working-set measurements. Sample maxima: 6.681 / 5.358 ms; frames over 33.3 ms: 0 / 0. Short windows cannot rule out later stutter.

Reproduce from workspace using `tools/godot/Godot_v4.7.2-stable_win64_console.exe --path prototype/CultivationSect_LowPoly_Test --script res://tools/evaluate.gd -- --baseline`, then the same command without `-- --baseline`. [Current baseline JSON](baseline-results.json), [repaired JSON](optimized-results.json), [preserved previous measurements](roof-collision-fix-2026-10-22/before/optimized-results.json).

**Decision: Do not expand yet.** Preserve the approved design. Target-device/sustained performance and human verification remain outstanding. NOT TESTED: human keyboard/mouse rehearsal; intended low-end hardware; sustained thermal behavior/long-run stutter; exported executable; future production-player/camera or populated-town integration; exhaustive geometry self-intersection/all camera orientations and pixel-level distance-handover analysis. Current source has no town or production player. Automated movement results apply to the existing 1.8 m inspection fixture. A full visual-model rebuild/export was deliberately not performed; the actual roof emitter was replayed in isolation, and the saved source/GLBs were audited without overwriting them.

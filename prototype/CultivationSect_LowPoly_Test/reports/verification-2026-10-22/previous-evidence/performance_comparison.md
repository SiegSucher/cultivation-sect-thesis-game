# Matched before/after comparison

22 October 2026. **Decision: Do not expand yet.** Local measurements support the approach, but user visual approval and appropriate low-end/populated-world evidence are missing. No other facility was converted.

Godot 4.7.2-stable (official); GL Compatibility; 1280 x 720; MSAA 4x (enum value 2); VSync disabled and no frame cap for both measurement runs. GPU: NVIDIA GeForce RTX 3050 Laptop GPU; RAM: 15.63 GiB; CPU identifier: Intel64 Family 6 Model 154 Stepping 3, GenuineIntel. CPU marketing name unavailable. Same isolated hall stage, sun, environment, lantern lights, camera positions/FOVs and controller. The initial screen and final screenshot poses were identical between versions. No town or future production player exists in the active source.

Each of six views: 45 warmup frames + 240 measured rendered frames. The exterior sweep rotates 360 degrees over 240 frames. Movement uses the real unchanged 60 Hz inspection controller: approach from z=24 through stairs/door/aisle, four-step dais, both side rooms. Capture first/third person and verify closed-door blocking. Idle screenshot warmup: 24 frames. Raw frame intervals use Time.get_ticks_usec between process frames; rendering counts and memory are Godot Performance monitors, not hardware profiler timings. Reported primitives include shadow passes and stage; they are not unique building triangles. Memory is whole engine process/render memory, not hall-only. Absolute FPS is uncapped test throughput, not expected low-end gameplay FPS.

Run commands from the workspace: `tools/godot/Godot_v4.7.2-stable_win64_console.exe --path prototype/CultivationSect_LowPoly_Test --script res://tools/evaluate.gd -- --baseline` and the same command without `-- --baseline`. No simultaneous Godot test runs. Short, sequential runs; no thermal/power/background-load control, multiple-run statistical confidence, exported-game, human playtest or target-device certification.

| View | Baseline mean ms | New mean ms | Mean reduction | p95 ms before / after | Draw calls before / after |
| --- | ---: | ---: | ---: | ---: | ---: |
| front | 3.403 | 2.437 | 28.4% | 3.767 / 2.857 | 125.0 / 98.0 |
| three-quarter | 3.346 | 2.284 | 31.7% | 3.729 / 2.781 | 116.0 / 92.0 |
| 360-degree exterior sweep | 3.408 | 2.455 | 27.9% | 3.833 / 2.847 | 114.4 / 90.4 |
| interior | 5.328 | 3.999 | 24.9% | 5.858 / 4.604 | 123.0 / 100.0 |
| first-person interior | 5.224 | 2.367 | 54.7% | 5.763 / 2.787 | 104.0 / 87.0 |
| third-person interior | 5.290 | 2.373 | 55.1% | 5.977 / 2.848 | 164.0 / 135.0 |

Static near mesh: **203,064 -> 71,557 triangles (64.8% fewer)**; material surfaces 15 -> 12. All 12 new palette materials use standard opaque rendering; no texture sampling or custom shader. The same cheap geometry supplies the existing 95 m distant representation. Avoid claiming a separate LOD reduction.

Whole-render video-memory monitor at front: 114.53 -> 53.86 MiB. Godot static-memory monitor: 46.55 -> 41.12 MiB. These are reported monitor values, not total OS process working set. Neither recorded sample set had a frame above 33.3 ms. Short windows cannot establish absence of stutter. Large geometry/texture reduction coincides with faster measured frames, but the contribution of each change was not isolated experimentally.

[Baseline raw results](baseline-results.json), [final raw results](optimized-results.json), [hardware](hardware.json), [baseline procedure](baseline_performance.md). The final design was measured after refinement; first-pass draft results are not substituted for the final measurements.

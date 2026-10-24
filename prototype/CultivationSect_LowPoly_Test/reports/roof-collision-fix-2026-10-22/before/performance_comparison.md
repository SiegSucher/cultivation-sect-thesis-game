# Matched before/after comparison

22 October 2026. **Visual direction approved by the user. Decision: Do not expand yet.** The user explicitly requested verification before any further building conversion. Local measurements support the approved design; low-end/populated-world evidence remains missing. No other facility was converted or redesigned. Current matched reruns use the preserved high-detail baseline and the byte-identical approved low-poly assets; initial evidence remains under `verification-2026-10-22/previous-evidence/`.

Godot 4.7.2-stable (official); GL Compatibility; 1280 x 720; MSAA 4x (enum value 2); VSync disabled and no frame cap for both measurement runs. GPU: NVIDIA GeForce RTX 3050 Laptop GPU; RAM: 15.63 GiB; CPU identifier: Intel64 Family 6 Model 154 Stepping 3, GenuineIntel. CPU marketing name unavailable. Same isolated hall stage, sun, environment, lantern lights, camera positions/FOVs and controller. The initial screen and final screenshot poses were identical between versions. No town or future production player exists in the active source.

Each of six views: 45 warmup frames + 240 measured rendered frames. The exterior sweep rotates 360 degrees over 240 frames. Movement uses the real unchanged 60 Hz inspection controller: approach from z=24 through stairs/door/aisle, four-step dais, both side rooms. Capture first/third person and verify closed-door blocking. Idle screenshot warmup: 24 frames. Raw frame intervals use Time.get_ticks_usec between process frames; rendering counts and memory are Godot Performance monitors, not hardware profiler timings. Reported primitives include shadow passes and stage; they are not unique building triangles. Memory is whole engine process/render memory, not hall-only. Absolute FPS is uncapped test throughput, not expected low-end gameplay FPS.

Run commands from the workspace: `tools/godot/Godot_v4.7.2-stable_win64_console.exe --path prototype/CultivationSect_LowPoly_Test --script res://tools/evaluate.gd -- --baseline` and the same command without `-- --baseline`. No simultaneous Godot test runs. Short, sequential runs; no thermal/power/background-load control, multiple-run statistical confidence, exported-game, human playtest or target-device certification.

| View | Baseline mean ms | New mean ms | Mean reduction | p95 ms before / after | Draw calls before / after |
| --- | ---: | ---: | ---: | ---: | ---: |
| front | 3.352 | 2.474 | 26.2% | 3.927 / 2.879 | 125.0 / 98.0 |
| three-quarter | 3.201 | 2.387 | 25.4% | 3.959 / 2.926 | 116.0 / 92.0 |
| 360-degree exterior sweep | 3.113 | 2.441 | 21.6% | 3.903 / 2.876 | 114.4 / 90.4 |
| interior | 4.326 | 3.963 | 8.4% | 4.951 / 5.006 | 123.0 / 100.0 |
| first-person interior | 3.738 | 3.797 | -1.6% | 4.824 / 4.981 | 104.0 / 87.0 |
| third-person interior | 3.820 | 3.821 | -0.0% | 4.959 / 5.062 | 164.0 / 135.0 |

Positive reductions mean faster in this run; negative values mean slower. **Current result is mixed:** exterior views/sweep improve about 22-26%; the fixed interior view improves about 8%; first-person interior is about 1.6% slower and third-person is essentially unchanged. Those small interior differences cannot establish a reliable speedup or regression with this short uncontrolled sample. Preserve the approved appearance; do not redesign or expand on the strength of these figures.

## Repeatability and prior evidence

The original construction-stage pair and this fresh verification pair used the same approved visual assets and six-view procedure. Observed improvements vary substantially, especially indoors. They were sequential samples without controlled GPU clocks, power, thermals or background load; do not treat them as a statistically controlled benchmark. The independent-copy run is a loading/functional check, not an additional matched baseline/after pair.

| View | Earlier observed mean reduction | Fresh verification reduction |
| --- | ---: | ---: |
| front | 28.4% | 26.2% |
| three-quarter | 31.7% | 25.4% |
| 360-degree exterior sweep | 27.9% | 21.6% |
| interior | 24.9% | 8.4% |
| first-person interior | 54.7% | -1.6% |
| third-person interior | 55.1% | -0.0% |

Static near mesh: **203,064 -> 71,557 triangles (64.8% fewer)**; material surfaces 15 -> 12. All 12 new palette materials use standard opaque rendering; no texture sampling or custom shader. The same cheap geometry supplies the existing 95 m distant representation. Avoid claiming a separate LOD reduction.

Whole-render video-memory monitor at front: 112.50 -> 53.86 MiB. Godot static-memory monitor: 46.57 -> 41.13 MiB. These are reported monitor values, not total OS process working set. Neither recorded sample set had a frame above 33.3 ms. Short windows cannot establish absence of stutter. Large geometry/texture reduction coincides with faster measured frames, but the contribution of each change was not isolated experimentally.

[Baseline raw results](baseline-results.json), [final raw results](optimized-results.json), [hardware](hardware.json), [baseline procedure](baseline_performance.md). The final design was measured after refinement; first-pass draft results are not substituted for the final measurements.

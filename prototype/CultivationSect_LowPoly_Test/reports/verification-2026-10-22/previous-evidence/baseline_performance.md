# Baseline performance

Measured 22 October 2026, before the hall was rebuilt. All 21 baseline checks passed. Independent copied hall assets remain in `../baseline/hall/`; original runtime is additionally recoverable from `../original_runtime_recovery.zip`.

Godot 4.7.2-stable (official); GL Compatibility; 1280 x 720; MSAA 4x (enum value 2); VSync disabled and no frame cap for both measurement runs. GPU: NVIDIA GeForce RTX 3050 Laptop GPU; RAM: 15.63 GiB; CPU identifier: Intel64 Family 6 Model 154 Stepping 3, GenuineIntel. CPU marketing name unavailable. Same isolated hall stage, sun, environment, lantern lights, camera positions/FOVs and controller. The initial screen and final screenshot poses were identical between versions. No town or future production player exists in the active source.

Each of six views: 45 warmup frames + 240 measured rendered frames. The exterior sweep rotates 360 degrees over 240 frames. Movement uses the real unchanged 60 Hz inspection controller: approach from z=24 through stairs/door/aisle, four-step dais, both side rooms. Capture first/third person and verify closed-door blocking. Idle screenshot warmup: 24 frames. Raw frame intervals use Time.get_ticks_usec between process frames; rendering counts and memory are Godot Performance monitors, not hardware profiler timings. Reported primitives include shadow passes and stage; they are not unique building triangles. Memory is whole engine process/render memory, not hall-only. Absolute FPS is uncapped test throughput, not expected low-end gameplay FPS.

Run commands from the workspace: `tools/godot/Godot_v4.7.2-stable_win64_console.exe --path prototype/CultivationSect_LowPoly_Test --script res://tools/evaluate.gd -- --baseline` and the same command without `-- --baseline`. No simultaneous Godot test runs. Short, sequential runs; no thermal/power/background-load control, multiple-run statistical confidence, exported-game, human playtest or target-device certification.

| View | Mean ms | p95 ms | Average FPS | Draw calls | Rendered primitives |
| --- | ---: | ---: | ---: | ---: | ---: |
| front | 3.403 | 3.767 | 293.8 | 125.0 | 605074 |
| three-quarter | 3.346 | 3.729 | 298.9 | 116.0 | 603994 |
| 360-degree exterior sweep | 3.408 | 3.833 | 293.5 | 114.4 | 635044 |
| interior | 5.328 | 5.858 | 187.7 | 123.0 | 991590 |
| first-person interior | 5.224 | 5.763 | 191.4 | 104.0 | 988558 |
| third-person interior | 5.290 | 5.977 | 189.0 | 164.0 | 1027146 |

Near static building: 203,064 triangles / 15 surfaces. Original roof shimmer/moire is visible in exterior captures; the source is otherwise traversable by the test fixture. Raw evidence: [baseline-results.json](baseline-results.json). No measured baseline frame exceeded 33.3 ms. This does not rule out later gameplay stutter.

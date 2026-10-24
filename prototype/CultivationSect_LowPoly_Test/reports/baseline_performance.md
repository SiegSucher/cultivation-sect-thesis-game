# Preserved high-detail baseline recheck

22 October 2026. The original project was not run or edited. This table measures its preserved independent high-detail hall copy in the same test room as the repaired approved model. The first baseline was captured before conversion and is retained in historical evidence.

Godot 4.7.2-stable (official), NVIDIA GeForce RTX 3050 Laptop GPU, GL Compatibility, 1280 x 720, MSAA 4x (enum 2), VSync disabled and no frame cap. Renderer, settings, environment, lighting, camera poses/FOV, player and benchmark script are unchanged. Each of six views uses 45 warmup + 240 measured frames (1,440 measured frames per variant); the exterior sweep covers 360 degrees in 240 frames. Frame intervals are measured with `Time.get_ticks_usec()` between process frames; rendering and memory statistics use Godot Performance monitors. Counts include stage/shadow passes, not just unique building triangles.

Source run timestamps UTC: baseline `2026-10-22T05:54:16`, repaired `2026-10-22T05:55:25`. The preserved high-detail baseline and repaired low-poly model ran sequentially with no other Godot test active. Same main stair/door/aisle/dais/private-room movement and FPP/TPP sequence. Exact camera poses/FOVs match the earlier approved-model captures. Raw results retain all timings, draw calls, rendered primitives and memory observations.

Power mode, GPU clocks, thermals and background load were not controlled. These are short local uncapped observations, not statistically controlled or sustained target-device measurements. No human playtest, exported executable, low-end device or populated production world was tested. The independent-copy run verifies loading/functionality and is not an extra matched performance pair.

| View | Mean ms | p95 ms | Average FPS | Draw calls |
| --- | ---: | ---: | ---: | ---: |
| front | 3.408 | 4.027 | 293.4 | 125.0 |
| three-quarter | 3.366 | 3.968 | 297.1 | 116.0 |
| 360-degree exterior sweep | 3.429 | 3.981 | 291.6 | 114.4 |
| interior | 5.295 | 6.129 | 188.8 | 123.0 |
| first-person interior | 3.866 | 4.964 | 258.7 | 104.0 |
| third-person interior | 3.904 | 5.052 | 256.1 | 164.0 |

21 baseline checks passed. Static hall: 203,064 triangles / 15 surfaces. [Raw measurements](baseline-results.json), [current matched comparison and prior pair](performance_comparison.md).

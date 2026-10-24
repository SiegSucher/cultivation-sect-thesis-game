# Approved Main Sect Hall - verification results

22 October 2026. User approval recorded. **Approved visual design unchanged. No other facility converted.**

| Requested verification | Result |
| --- | --- |
| Original project untouched | PASS: all 1,599 recorded non-cache original files match their original SHA-256 hashes |
| High-detail recovery | PASS: all original runtime ZIP entries match current original files; ZIP CRC integrity checked |
| Independent test import/run | PASS: cache-free copy at `C:\Users\pasto\OneDrive\Documents\ChatGPT\Character Sprite Image for Thesis game\output\split-cloud-approved-independent-verification`; no symlinks/import metadata; fresh import and 21 rendered checks pass |
| Visible geometry/materials | PASS: 71,557 static triangles vs 203,064; 12 opaque shared materials, no textures; no zero-area visible triangles |
| Gameplay scale and collision behavior | PASS in tested routes: 21 rendered checks and 18 supplemental checks; root, podium, doors, stairs, floor/dais and non-roof collider records retained |
| Roof collision metadata quality | REVIEW: 64 of 2,432 collider triangles have zero area; no related runtime failure observed; pending targeted cleanup |
| First/third-person and interaction controls | PASS with existing 1.8 m inspection fixture; seven dispatched-input checks; production player does not exist in this source |
| Editable source | PASS: seven checks after reopening the saved Blender source |
| Saved-project restart | PASS: current import/runtime logs contain no errors/warnings |
| Preservation of approved design | PASS: visual resources, native source, collider JSON, authoring program and controller files match approval manifest; checkpoint ZIP intact |

The only runtime configuration change assigns the test its own application identity and Godot user-data folder. That prevents sharing user data with the original workshop and changes no artwork or gameplay setting. The other three copied facilities remain unchanged.

## Fresh matched performance

RTX 3050 Laptop GPU, 1280x720, GL Compatibility, MSAA 4x, uncapped/VSync off; six 240-frame samples. No power/thermal/background-load control. Positive reductions are improvements; differences near zero are inconclusive.

| View | Mean ms before / after | Average FPS before / after | Mean frame-time reduction |
| --- | ---: | ---: | ---: |
| front | 3.352 / 2.474 | 298.3 / 404.2 | 26.2% |
| three-quarter | 3.201 / 2.387 | 312.4 / 419.0 | 25.4% |
| 360-degree exterior sweep | 3.113 / 2.441 | 321.2 / 409.6 | 21.6% |
| interior | 4.326 / 3.963 | 231.2 / 252.3 | 8.4% |
| first-person interior | 3.738 / 3.797 | 267.5 / 263.4 | -1.6% |
| third-person interior | 3.820 / 3.821 | 261.8 / 261.7 | -0.0% |

Exterior observations improved about 22-26%, fixed interior about 8%; first-person was ~1.6% slower and third-person essentially unchanged. Previous samples showed larger gains, demonstrating variability. **A consistent sustained or low-end-device speedup has not been established.** [Full comparison and prior pair](performance_comparison.md).

## Remaining issue and unperformed tests

The 64 degenerate roof collider faces were left unchanged during verification to preserve the exact approved state. They contribute no surface. Remove only these redundant collider faces and filter them in the exporter, then rerun collision/camera tests while preserving approved visible GLB/native-source hashes. Do not remodel the hall.

NOT TESTED: human keyboard/mouse rehearsal; intended low-end hardware; sustained thermal/long-run stutter behavior; exported executable; production player/camera and populated-town integration; exhaustive geometry self-intersection/camera orientation and pixel-level distance handover. No current town or production player exists in the active source.

## Handoff and preservation

[HANDOFF.md](../HANDOFF.md) records approval, all nine reference filenames, current evidence, remaining work and the exact next action for Claude. Claude should inspect the verification summary and collision audit first, perform only targeted collider cleanup, and retest without visual redesign. No message was sent to Claude. No further facility conversion is authorized.

Approved checkpoint: `../checkpoints/approved-split-cloud-2026-10-22.zip`. Original runtime recovery: `../original_runtime_recovery.zip`. [Verification summary](verification-2026-10-22/verification-summary.json), [collision audit](collision-data-audit.json), [full experiment report](low_poly_test_report.md).

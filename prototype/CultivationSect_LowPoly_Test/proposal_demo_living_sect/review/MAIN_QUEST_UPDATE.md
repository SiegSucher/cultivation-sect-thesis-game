# Replacement main quests / 2026-10-26

The herb-watering and jar-filling quests, their props and their game commands have been removed from the playable demo. Night lighting and the optional lantern challenge remain.

The basin now starts a new main-story arc:

1. **The Silent Crossing:** the awakened current signals an old shrine. Follow the main-quest marker north to its sealed crossing. Read the actual seal charge and use an `if` condition to release the crossing when the reading equals 3. The visible seal disappears, its collision clears, and the crossing rune changes colour. Short ramps make the wooden crossing walkable with the existing controller. It sits clear of the courier's route and central street.
2. **The Threefold Ward:** cross to the shrine and repair its repeating inscription with a `for` loop. Exactly three pulses prepare the three dormant ward stones. On Continue, the stones rise and glow and a protective veil surrounds the shrine. Completing this step finishes the main-quest arc.

Both quests have Python, C and Java versions, teaching cards, command references, two hints, worked solutions, persistent session drafts and feedback. The Mentor, Mei, journal, objectives, marker and Reset Demo follow the new story. The original basin welcome recognition is still granted once; the final story result grants the sect's trust in dialogue.

The existing learning interpreter now supports `if` blocks and bounded `for` loops in the new quests. Python uses indentation and `range(count)`; C/Java use braces and a counter updated by assignment. It does not claim full language support. Blocks, iterations, source size, output and total execution are bounded, so an incorrect counter cannot freeze the game. A seal reading is distinguished from the player's Qi reserve, and every world change waits for a wholly successful run plus Continue. False conditions, too few or too many pulses, and later errors leave the world unchanged.

Fresh verification:

| Suite | Passed | Failed |
| --- | ---: | ---: |
| Original interpreter and lesson cases | 146 | 0 |
| Conditions, loops, language rules, bounds and removed command | 66 | 0 |
| Full progression in all three languages, rendered 1280×720 | 118 | 0 |
| Full progression in all three languages, rendered 1920×1080 | 118 | 0 |
| Existing input, walking, lanterns, cameras, journal and reset, rendered 1280×720 | 125 | 0 |

The full progression suites also verify physical blocking before the seal opens, walking across it afterward, drafts, hints, error rollback, journal entries, night lighting and reset. PNG evidence is in `main-quests-1280x720/` and `main-quests-1920x1080/`. Results are in the corresponding `result.json` files, `main-control-flow.json`, `main-interpreter-baseline.json` and `main-regression/result.json`.

The Windows executable and ZIP use their original workspace filenames. Export/startup and ZIP integrity results are recorded in `main-quest-artifacts.json`. The previous source state is recoverable from `before-main-quest-replacement-2026-10-26.zip`. Older night reports/screenshots describe the removed water-service build and remain historical evidence.

**Standalone startup BLOCKED:** Windows rejected `Start-Process` with “An Application Control policy has blocked this file.” The release export succeeded, but standalone startup was not verified. No security policy was changed. The source edition was tested through the included Godot engine; the existing workspace `Launch Proposal Demo.cmd` opens that edition.

Limits: the scene is a compact prototype; the crossing channel and ward are illustrative local geometry. Automated input and screenshot inspection do not replace a human playthrough or establish audible sound acceptance. This host reports certificate-store and shader-cache-write diagnostics, plus texture cleanup diagnostics on exit; those are retained in the logs. No game-script errors occurred in the successful checks.

# Night and basin continuation / 2026-10-26

Historical report: the two water-service quests described below were removed in the subsequent main-quest replacement. Night lighting is retained. See `MAIN_QUEST_UPDATE.md` and `main-quests-*` for the current game and checks.

The court stays at night with a dark blue sky and cool moonlight. Solving Lin's existing readings turns on warm lantern light, luminous glass and a soft radial halo. The halo uses ordinary transparent materials supported by GL Compatibility.

After the original awakening and basin inscriptions, two typed programming quests continue in the same chosen language:

1. **Share the current:** the herb trough beside the basin. Read 6 water units, subtract the 2 retained in the public bowl, and water the herbs with the remaining 4. The trough fills and the herbs grow greener.
2. **Travellers' reserve:** the three jars beside the basin. Multiply 3 jars by 2 water units, store the result and fill the jars with 6. Their water surfaces become visible.

Python, C and Java each have teaching cards, reference commands, two hints, a worked solution and separate drafts for these steps. The quest marker, Mentor and Mei dialogue, apprentice journal and Reset Demo include both services. New commands run through the existing restricted learning interpreter. Effects commit only after the complete program succeeds and the learner chooses Continue. The original welcome recognition is awarded once after the basin; all four steps must finish before the objective shows complete.

Fresh source checks:

| Check | Result |
| --- | --- |
| Existing interpreter cases | 146 passed, 0 failed |
| New full sequence, rendered 1280×720 | 110 passed, 0 failed |
| New full sequence, rendered 1920×1080 | 110 passed, 0 failed |
| Existing lanterns, walking, real key events, camera, journal and reset, rendered 1280×720 | 125 passed, 0 failed |

Results are in `night-interpreter.json`, `night-quests-1280x720/result.json`, `night-quests-1920x1080/result.json`, and `night-regression/result.json`. The rendered folders include screenshots, inspected for lantern contrast, readable controls and unobstructed service views.

Windows release export completed successfully. The rebuilt standalone executable passed a bounded 120-frame headless startup check with exit code 0 and no game-script errors (`night-export-smoke.log`). The release template does not accept the editor's `--script` test option; the full progression checks above were performed against the source edition. ZIP integrity and the archived executable's SHA-256 are checked separately in `night-artifacts.json`.

An earlier headless run of the optional-content suite reported one camera-projection assertion failure; the same assertion passes with rendering. Its result remains in `night-regression.json`; use the rendered result above for visual acceptance. Godot also reports host certificate-store, shader-cache-write and shutdown texture diagnostics in this environment. These runs produced the expected images and no game-script errors. Automated input and visual checks do not constitute a human playthrough or audible sound verification.

Recovery: `before-night-quests-2026-10-26.zip` preserves the source immediately before these changes. At the workspace root, `The First Current - Before Night.exe` and `The First Current - Before Night.zip` preserve the previous Windows artifacts. The current Windows executable and ZIP retain their original names.

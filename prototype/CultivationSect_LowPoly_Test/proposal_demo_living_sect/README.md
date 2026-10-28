# The First Current — Living Sect

Launch **[Launch Living Sect.cmd](Launch%20Living%20Sect.cmd)**. Close another Godot game/editor first; the launcher enforces one running instance. Alternatively, open the existing project, select `res://proposal_demo_living_sect/proposal_demo.tscn`, and press F6. The launcher accepts `--fullscreen`.

The workspace's **The First Current.exe** is the standalone Windows build. **Launch Proposal Demo.cmd** runs this source edition using the included Godot engine. Both use the same night setting and four programming steps. The source edition keeps the shared architecture and terrain; no Reedwell art was imported.

## Explore

1. Follow the Guide through the Gate. The taller wall wings now have deeper masonry foundations, tiled caps, substantial piers and stepped connections to the Gate and slope.
2. Complete the Mentor's typed-code awakening and public-basin quest in Python, C or Java. The restricted learning interpreter, honest diagnostics, hints, worked solutions and drafts are retained.
3. Continue the main story at **The Silent Crossing**: the restored basin awakens a distant shrine. Follow the marker north to the sealed bridge. Read its spirit-seal charge and use an **if condition** to release it only when the charge equals 3. Walk across the newly opened bridge to **The Threefold Ward**. Repair its repeating inscription with a **for loop** that pulses three ward stones; the stones rise and a protective veil surrounds the shrine. Both main quests use typed Python, C or Java, with lessons, hints, drafts and worked solutions.
4. Help Lin with his three optional lantern readings. The court stays at night: cool moonlight keeps the route readable, while each repaired lantern gains an amber glow, a soft halo and a warm pool of light. Mei responds to your main-quest progress. Watch Lian add the basin to her water round when it starts flowing.
5. Speak to other residents or pause at the listening bench west of the Mentor. **J** records all four programming steps, lantern practice and people you have met.

The main street and central demonstration route stay open. Quest and lantern interactions take priority over optional resident conversations. Two residents walk short physical routes and yield to the player; other inhabitants practise, read, sweep, tend plants, drink tea or rest. This is a deliberately small population of **22 NPCs plus the player**, not a general daily-life simulation.

## Controls

| Input | Action |
| --- | --- |
| WASD / mouse | Move / look |
| Shift | Sprint |
| E | Relevant nearby interaction |
| Tab | First/third-person camera |
| J | Apprentice journal; types normally inside the code editor |
| Ctrl+Enter | Run typed code |
| Esc | Close a panel or open the menu |
| M / V | Inherited map / overview |
| 2 / 3 / 4 / 5 / 6 / 7 / 8 | Existing district review jumps while exploring |

Use Esc for Reset Demo, sound levels/mute, interface scale and fullscreen. The code window remains movable and resizable. Progress and drafts last for this running session; they are not disk saves.

## Review and recover

- Open **[rendered before/after comparisons](review/COMPARE.html)** for matching camera views and a captured walking animation.
- Read **[decisions, fresh checks and limitations](review/REVIEW.md)**.
- **Reset this run:** Esc → Reset Demo clears all four programming steps, closes the crossing seal, resets the three ward stones and veil, clears lantern practice, resident visits/routes, water response, listening count and presentation effects, then returns to the forest entrance.
- **Night update recovery:** `review/before-night-quests-2026-10-26.zip` preserves the source before the night update. The `review/night-quests-*` folders describe the earlier water-service build; use the main-quest evidence below for this version.
- **Main quest replacement:** the herb-watering and jar-filling quests have been removed. `review/before-main-quest-replacement-2026-10-26.zip` preserves that previous source build. Current main-story evidence is under `review/main-quests-1280x720/` and `review/main-quests-1920x1080/`. The main quests teach conditions and bounded loops; the interpreter still supports only a small documented language subset.
- **Older versions:** the earlier editions (`proposal_demo`, `proposal_demo_creative`, `proposal_demo_sectlife`) and other retired project folders were removed on 2026-10-25. They are kept in `../../_proposal_archive/2026-10-25-living-sect-cleanup/retired-files.zip`; see `KEEP-DELETE.md` beside it.
- **Recover Living Sect:** with Godot closed, extract `review/living-sect-source.zip` at the `CultivationSect_LowPoly_Test` root. It contains the `proposal_demo_living_sect/` source folder and review tools. Keep the project's shared assets and terrain; this archive is not a portable export.
- **Set this edition aside:** with Godot closed, move only `proposal_demo_living_sect/` outside the project. Do not move or replace shared `assets/`, `staging/`, `phase4d/` or `project.godot`.

Before the cleanup, the original three versions and shared project files were checked against the task-start SHA-256 manifest in `review/baseline-hashes.json`; final preservation results are in `review/preservation.json`.

# Twelve-building gallery launch and controls audit

23 October 2026. Canonical inventory: `assets/gallery/catalog.json` (12 entries). **Approved Hall-only manual startup fix implemented; all twelve launches tested afterward.** No other runtime file, scene, model, collision, material, camera setting, staging asset or layout was changed. Original production/workshop project preserved.

## Implemented change

Only `scripts/hall_experiment.gd` changes at runtime: after the existing scene initializes, manual sessions enable third person, update/activate the existing player camera, enable player physics/input and capture the mouse. The existing 1 overview/walk toggle, Tab, E, Esc and 2/3/4 presets remain. Automated Hall startup retains its preceding behavior and was checked separately. No controller/camera algorithm was edited.

This fixes the approved startup mismatch: **Hall Walk asset now immediately shows a controllable third-person figure. F5 also starts walking third person**, because `project.godot` still points to the same Hall scene. Press 1 for overview; press 1 again to resume walking. Nothing automatically normalizes the other eleven entries.

Rollback copy: `gallery-launch-audit/before-hall_experiment.gd.txt`. Previous handoff: `gallery-launch-audit/before-HANDOFF.md.txt`. The earlier investigation and its 187-check results are historical pre-fix evidence; its overview-start expectation for the Hall is superseded by this audit.

## Intended versus actual startup and results

Intent was established from the existing walkthrough scripts/HUD controls and prior startup evidence, with only the Hall changed by the current approval. Review mode is an intentional demonstration view. Hidden first-person avatars do not indicate missing character resources.

In the table, **review** means player movement/input intentionally paused until 1; **FPP/TPP** mean first/third person. Movement/mouse results refer to the active walking mode. **0 asset errors** excludes the shared host certificate-store error detailed below. Every PASS is scoped to rendered programmatic checks, not human acceptance.

| Asset | Intended startup | Actual startup | Third-person avatar | Movement / mouse-look | Overview / 1 | Tab / other controls | Asset errors | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Split-Cloud Main Sect Hall | Walking TPP, approved change | Walking TPP; immediately visible | PASS | PASS, immediately active | PASS, both ways | PASS; E and 2/3/4 | 0 | **40 PASS / 0 FAIL** |
| Sect Gate / Gatehouse | Review | Review; avatar hidden until walk/Tab | PASS | PASS after 1 | PASS, both ways | PASS; E and 2/3/4 | 0 | **41 PASS / 0 FAIL** |
| Large Martial Training Ground | Walking FPP | Walking FPP; avatar hidden by design | PASS after Tab | PASS, immediately active | **N/A**, walk-only; 1 stays unbound | PASS; Esc gallery | 0 | **24 PASS / 0 FAIL** |
| Scripture Pavilion | Walking FPP | Walking FPP; avatar hidden by design | PASS after Tab | PASS, immediately active | **N/A**, walk-only; 1 stays unbound | PASS; G and remote E denial | 0 | **27 PASS / 0 FAIL** |
| Disciples' Residence | Review | Review | PASS | PASS after 1 | PASS, both ways | PASS; 2/3/4/5 switches | 0 | **46 PASS / 0 FAIL** |
| Elder Residence | Review | Review | PASS | PASS after 1 | PASS, both ways | PASS; 2/3/4/5 switches | 0 | **46 PASS / 0 FAIL** |
| Dining Hall and Kitchen | Review | Review | PASS | PASS after 1 | PASS, both ways | PASS; 2/3/4/5 switches | 0 | **46 PASS / 0 FAIL** |
| Spirit Herb Garden | Review | Review | PASS | PASS after 1 | PASS, both ways | PASS; 2/3/4/5 switches | 0 | **46 PASS / 0 FAIL** |
| Mission Hall | Review | Review | PASS | PASS after 1 | PASS, both ways | PASS; Esc gallery | 0 | **34 PASS / 0 FAIL** |
| Contribution / Exchange Hall | Review | Review | PASS | PASS after 1 | PASS, both ways | PASS; Esc gallery | 0 | **34 PASS / 0 FAIL** |
| Alchemy Pavilion | Review | Review | PASS | PASS after 1 | PASS, both ways | PASS; 2/3 utility switches | 0 | **40 PASS / 0 FAIL** |
| Medicine Hall | Review | Review | PASS | PASS after 1 | PASS, both ways | PASS; 2/3, camera exception lifecycle | 0 | **40 PASS / 0 FAIL** |

Asset rows total 464 passes. One canonical-catalog check and one separate automated-Hall-startup check bring the complete result to **466 PASS / 0 FAIL**. Training and Scripture have no internal overview camera or documented 1 mode binding; their overview is available by Esc back to the gallery. They were not modified to add a mode they do not have.

## Exact resources launched

These are the actual scene paths reached through GUI mouse events on the existing Walk asset button. The catalog's building `resource` is distinct from its player walkthrough.

| Entry | Walk scene |
| --- | --- |
| Main Sect Hall | `res://scenes/hall_experiment.tscn` |
| Sect Gate | `res://scenes/review/gate_walkthrough.tscn` |
| Training Ground | `res://scenes/review/training_walkthrough.tscn` |
| Scripture Pavilion | `res://scenes/review/scripture_walkthrough.tscn` |
| Disciples' Residence | `res://scenes/review/disciple_residence_walkthrough.tscn` |
| Elder Residence | `res://scenes/review/elder_residence_walkthrough.tscn` |
| Dining Hall / Kitchen | `res://scenes/review/dining_hall_kitchen_walkthrough.tscn` |
| Spirit Herb Garden | `res://scenes/review/spirit_herb_garden_walkthrough.tscn` |
| Mission Hall | `res://scenes/review/mission_hall_walkthrough.tscn` |
| Exchange Hall | `res://scenes/review/exchange_hall_walkthrough.tscn` |
| Alchemy Pavilion | `res://scenes/review/alchemy_pavilion_walkthrough.tscn` |
| Medicine Hall | `res://scenes/review/medicine_hall_walkthrough.tscn` |

All use the existing `scripts/training_inspection_player.gd`. Each instantiates its CharacterBody3D, two procedural avatar meshes, collision capsule and player camera successfully; no imported production character is required or claimed.

## Tests actually performed

Fresh Godot 4.7.2 rendered run, Compatibility/OpenGL, RTX 3050 Laptop, 1280 x 720, fixed simulation delta 1/60 s. **This is not a performance benchmark or a human playtest.**

- The harness reads the canonical catalog, checks 12 entries, selects each asset and sends GUI mouse-down/up events to the real Walk asset button. It verifies the actual launched scene, player/controller initialization and startup flags.
- On all twelve: real physical-key events test W movement and Tab in both directions; real mouse-motion events test yaw/pitch. First-person camera tracking, visible TPP avatar and follow-camera frustum inclusion pass. Initial review-mode movement is deliberately zero; walking-mode movement is nonzero. The Hall's initial state is now TPP with movement enabled.
- On all ten scenes that implement overview: 1 enters overview, releases the mouse and disables player movement/input; W and mouse motion do not move/turn the paused player; Tab does not leave it trapped. Another 1 restores TPP, input, movement, follow camera and mouse capture. Training/Scripture instead verify that 1 does not disable or trap their walking state.
- Hall/Gate: E toggles the existing door target; 2/3/4 enter their documented overview presets and 1 restores walking. This checks key dispatch and state recovery, not a fresh full door-traversal/collision suite.
- Scripture: G enables/revokes inspection authorization; E correctly refuses an archive request from the distant entry position. Full archive traversal/authorization/security suites were not repeated.
- Each four-asset review launch exercises 2/3/4/5, confirming intentional reset to review and successful 1/Tab recovery after each switch.
- Both utility launches exercise 2/3, review reset, walking/TPP recovery, removal of stale Medicine exceptions and exactly one live Medicine camera-only collision exception.
- All twelve return with Esc to a usable twelve-entry gallery and released mouse. No scene remained trapped with player input disabled after the documented walk action.
- Automated Hall startup remains first-person with its existing automated flags and overview camera; the new manual-start branch is skipped.

**Other eleven unchanged:** `gallery-launch-audit/startup-comparison.json` compares their actual post-fix initial state against the preceding rendered investigation across 11 scene/controller/input/visibility/camera fields. All eleven match. Preservation hashes independently show their resources/scripts were not modified. No extra control bug was reproduced.

## Evidence and errors

- Harness: `gallery-launch-audit/verify_gallery_launches.gd`.
- Full check records, mode states and movement measurements: `gallery-launch-audit/launch-results.json`.
- Final console output: `gallery-launch-audit/rendered.log`.
- **46 genuine viewport captures**, covering initial, FPP, TPP and the ten available overview modes. The Hall's initial screenshot was inspected by Codex and shows the visible figure at the original spawn.
- [Hall immediately after launch](gallery-launch-audit/main_sect_hall-initial.png), [Hall overview](gallery-launch-audit/main_sect_hall-overview.png), [Disciples initial review](gallery-launch-audit/disciple_residence-initial.png), [Disciples TPP](gallery-launch-audit/disciple_residence-walking-third-person.png).

Final runtime logs contain the pre-existing host **`Failed to read the root certificate store`** error and the addon's informational `debugger active=false` registration. They contain no parser, missing-resource, failed-import, camera, movement or freed-body diagnostic. The final log is therefore not described as completely error-free. Existing imported resources loaded/rendered; a separate clean-cache editor reimport was not run because no assets changed.

The new audit harness's first attempt had a type-inference parse error at its temporary `scene` variable. This was corrected with an explicit Node3D type before the successful audit; the failed log is retained as `harness-initial-parse-error.log`. It was a test-harness error, not a gallery/runtime-asset failure, and required no additional runtime changes.

## Bug / intended mode / focus / unverified distinctions

- **Fixed startup bug:** Hall Walk asset previously meant review-only despite the approved expectation of an immediately visible, movable player. Its manual startup now meets that expectation, while 1 still provides review.
- **Intentional demo/review modes:** nine other entries still start in review, with their existing HUD documenting 1 walk/review and Tab FPP/TPP. Their disabled movement is intentional and recovery is verified. The shared button label can still be confusing; a future label/help-text clarification is a recommendation only, not an applied change.
- **Intentional walk-only modes:** Training/Scripture start in FPP, so the avatar is hidden until Tab. No internal 1 overview mode exists or is promised by their HUD.
- **Click-to-focus:** physical keyboard/mouse controls require the running game window/embedded game to have focus. Click inside it if needed. Programmatic Input events bypass OS focus, so physical focus behavior in the user's Godot/editor configuration was **not tested** and is not blamed as an observed code bug.
- **Not completed/claimed:** human keyboard/mouse playtesting or acceptance, live inspection of the user's editor debugger/pause/focus state, production-character integration, exhaustive building/door/stair/camera traversal, clean-cache reimport, exported executable, performance/low-end hardware, navigation or final town placement. Existing indoor-camera near-wall/doorway-timber limitations and other asset-audit issues remain unchanged.

## Changed files and next action

Existing runtime file changed: **`scripts/hall_experiment.gd` only**. Documentation changed: `HANDOFF.md`. New files: this report and `reports/gallery-launch-audit/` evidence, diagnostic script and backups. The previous investigation, controller/camera settings, catalog, all other scripts/scenes/assets, staging and original project are preserved. Exact final hashes: `gallery-launch-audit/preservation.json`.

Final SHA-256 audit checked **5,133 pre-existing test-project files**: only the Hall walkthrough script and handoff changed, none is missing. All **62 staged files present at task start** match, with no staging additions/deletions. This count includes `staging/claude_mission_hall/review/mission_hall_review.gd.uid`, already present before this task; unlike earlier historical 61-file snapshots, it was preserved rather than removed. All **1,599 original-project files** match both the task-start snapshot and recorded original manifest. Removing the one added manual-startup block reproduces the previous Hall script exactly; all other runtime code is byte-identical.

Manual verification: open this test project's `project.godot`. **F5** now starts the Hall with a visible third-person figure; move with WASD/mouse, use 1 twice to verify overview/resume, Tab for FPP/TPP, E for doors and Esc for gallery. Or open `scenes/asset_gallery.tscn` and press **F6**, select the Hall and click Walk asset. For the nine review entries use 1 then Tab; for Training/Scripture use Tab immediately. Record actual physical-input/focus observations separately from these automated results. Do not change the remaining startup modes or begin layout work automatically.

Reproduce the audit from the test-project directory:

```powershell
& ../../tools/godot/Godot_v4.7.2-stable_win64_console.exe --fixed-fps 60 --path . --script res://reports/gallery-launch-audit/verify_gallery_launches.gd
```

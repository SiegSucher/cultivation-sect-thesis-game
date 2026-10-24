# Walk Asset launch investigation

23 October 2026. Investigation only; no fix applied. The user identified **Split-Cloud Main Sect Hall** as the affected entry.

## Root cause documented before any fix

Source-confirmed: the Hall's gallery Walk Asset button launches `res://scenes/hall_experiment.tscn`, whose `_ready()` creates the inspection player but explicitly disables its physics and unhandled-input callbacks for manual sessions. The scene then activates the overview camera and releases the mouse. The controller defaults to first person and hides its avatar. Therefore clicking Walk Asset alone produces both reported symptoms: no visible character and no WASD movement. Existing **1** starts walking; **Tab** then makes the character visible in third person. The button's name implies immediate walking, but it only opens the two-mode inspection scene.

**Runtime confirmed:** the actual gallery button plus programmatic mouse/key events reproduced this state and successfully enabled walking with 1, movement with W and the visible character with Tab. The recent indoor camera change is not the cause. No fix was applied; the proposed change below requires user approval.

## Exact launch flow and affected resource

Project file: `C:/Users/pasto/OneDrive/Documents/ChatGPT/Character Sprite Image for Thesis game/prototype/CultivationSect_LowPoly_Test/project.godot`.

1. Run `res://scenes/asset_gallery.tscn`, select **Split-Cloud Main Sect Hall**.
2. `scripts/asset_gallery.gd:120` creates **Walk asset**; its `pressed` signal is connected by the button helper at line 45.
3. `open_walkthrough()` at lines 379-390 handles this asset by ID. For `main_sect_hall`, it loads **`res://scenes/hall_experiment.tscn`**.
4. The launched scene runs **`res://scripts/hall_experiment.gd`**. This creates the building from `scripts/tang_main_hall.gd` and creates the player from **`res://scripts/training_inspection_player.gd`**.
5. The catalog's `resource` value, **`res://scenes/buildings/tang_main_hall.tscn`**, is the building resource used by the gallery; it is not the Hall's Walk Asset destination and does not itself supply the inspection player.
6. `project.godot:14` also sets `res://scenes/hall_experiment.tscn` as the F5 main scene, so F5 starts in this same overview mode.

## Why the player appears missing and cannot move

| Observed state immediately after Walk asset | Actual value / cause |
| --- | --- |
| Player exists | CharacterBody3D at `(0, .05, 24)` under `HallExperiment` |
| Character geometry exists | Two procedural MeshInstance3D children (body and head), plus the collision capsule; no imported character model is needed |
| Player node visible | Yes; the avatar child is deliberately hidden |
| Avatar visible / third-person mode | Both false: `third_person := false` (`training_inspection_player.gd:6`), then `avatar.visible = third_person` (line 106) |
| Player outside overview frustum | No: its centre is inside the active camera's frustum, but its avatar is hidden |
| Movement enabled | No: `hall_experiment.gd:54` calls `player.set_physics_process(false)` in manual mode |
| Player input enabled | No: line 55 calls `player.set_process_unhandled_input(false)` |
| Active camera | Overview camera at `(33, 23, 41)`, made current at line 61; the player camera exists but is not current |
| Mouse | Released, not captured |
| Automated mode accidentally enabled | No: `automated == false` |

The visible body is hidden intentionally for first person, while the separate overview camera is active. That combination creates the impression that no player was spawned. Disabling the physics callback also stops the code that polls WASD, so holding W cannot move the player even though keyboard input itself works.

There is no missing InputMap action to configure: this controller directly polls physical W/A/S/D keys with `Input.is_physical_key_pressed()`. The test confirmed W's pressed state and real movement after walking was enabled.

The existing Hall **1** handler (lines 83-93) selects the player camera, enables physics and unhandled input, and captures the mouse. It begins in first person, so the body is still intentionally hidden until **Tab** toggles third person. The follow camera then tracks the moving player normally.

## Runtime reproduction and evidence

Fresh rendered Godot 4.7.2 process, Compatibility/OpenGL on RTX 3050 Laptop, 1280 x 720, fixed simulation delta 1/60 s. The diagnostic sent GUI mouse-down/up events to the real Walk asset button, then physical-key events through Godot's input system. It did not directly call the walkthrough launcher or bypass the scene's mode switch.

**187 PASS / 0 FAIL across all twelve gallery launches.** Exact state records: `walk-asset-investigation/launch-results.json`. Diagnostic source: `walk-asset-investigation/trace_walk_launch.gd`. Nine genuine viewport captures cover Hall, Disciples' Residence and Alchemy in initial, walking-first-person and walking-third-person states. Selected Hall captures were inspected by Codex. This is programmatic reproduction, not human playtesting.

For the reported Main Hall specifically:

- Clicking Walk asset selected the exact expected scene and instantiated its player, avatar meshes, collision and cameras without resource errors.
- Holding W before changing mode moved the player **0.000 m**.
- Pressing **1** enabled physics/input, captured the mouse and activated `InspectionCamera`.
- The next W hold moved the real controller **1.733 m**. The camera followed at the first-person eye offset of 1.65 m.
- Pressing **Tab** made the avatar visible, inside the follow-camera frustum. The outdoor boom measured **4.2509 m**.
- Temporarily disabling the indoor-camera feature in memory did not change launch, physics, input or visibility flags.

| Entry | Exact scene launched by Walk asset | Initial mode / movement |
| --- | --- | --- |
| Split-Cloud Main Sect Hall | `res://scenes/hall_experiment.tscn` | Overview; disabled |
| Sect Gate | `res://scenes/review/gate_walkthrough.tscn` | Overview; disabled |
| Large Martial Training Ground | `res://scenes/review/training_walkthrough.tscn` | First-person walking; enabled |
| Scripture Pavilion | `res://scenes/review/scripture_walkthrough.tscn` | First-person walking; enabled |
| Disciples' Residence | `res://scenes/review/disciple_residence_walkthrough.tscn` | Overview; disabled |
| Elder Residence | `res://scenes/review/elder_residence_walkthrough.tscn` | Overview; disabled |
| Dining Hall / Kitchen | `res://scenes/review/dining_hall_kitchen_walkthrough.tscn` | Overview; disabled |
| Spirit Herb Garden | `res://scenes/review/spirit_herb_garden_walkthrough.tscn` | Overview; disabled |
| Mission Hall | `res://scenes/review/mission_hall_walkthrough.tscn` | Overview; disabled |
| Contribution / Exchange Hall | `res://scenes/review/exchange_hall_walkthrough.tscn` | Overview; disabled |
| Alchemy Pavilion | `res://scenes/review/alchemy_pavilion_walkthrough.tscn` | Overview; disabled |
| Medicine Hall | `res://scenes/review/medicine_hall_walkthrough.tscn` | Overview; disabled |

All twelve start with `third_person == false`, so even the two immediately walkable scenes initially hide the avatar. The ten overview scenes accepted 1, then W and Tab successfully. The other two accepted W and Tab immediately. This inconsistent launch convention explains why the same button can feel broken in one building and work differently in another.

Hall screenshots:

- [Immediately after Walk asset: overview, hidden avatar](walk-asset-investigation/main_sect_hall-initial.png)
- [After 1: first-person walking](walk-asset-investigation/main_sect_hall-walking-first-person.png)
- [After W and Tab: visible third-person character](walk-asset-investigation/main_sect_hall-walking-third-person.png)

## Recent camera changes and diagnostics

The Hall startup script matches its saved **pre-indoor-camera-fix** hash. The controller's `_ready()` and `_unhandled_input()` functions are also unchanged from the pre-fix script. The new camera profile does not enable/disable movement, select the overview camera, alter the first-person default or create/remove the character. Its feature-off comparison left the launch state identical. This startup behavior predates that work.

Fresh output: `walk-asset-investigation/launch-rendered.log`.

- The known host error `Failed to read the root certificate store` remains. It occurs at process startup and did not prevent any of the twelve launches or input checks; it is not evidence of a failed player import.
- No parser, missing-resource, import-failure, camera or movement error/warning was emitted in this reproduction.
- The addon reported `debugger active=false` in this standalone process; that is informational. The user's already-open Godot editor/debugger pane was **not** directly inspected. Keyboard focus, editor pause or an unreported different local state would need separate evidence if 1/Tab still fail in that session.

## Smallest safe fix proposed for approval — not implemented

For the reported Hall, change **only the manual startup path in `scripts/hall_experiment.gd`** so that, once the existing scene is initialized, it starts with:

1. `third_person` enabled and the existing avatar shown through `update_camera()`;
2. player physics and unhandled-input callbacks enabled;
3. the existing player camera current and the mouse captured.

Keep the existing **1** overview/walk toggle, **Tab** camera toggle, **E** doors, **Esc** gallery, overview presets and automated-test startup behavior. Do not change camera collision/math, player dimensions, building resources or scene files. This is a reversible Hall-startup change, not a replacement controller.

**Visible consequence:** clicking Hall Walk asset would immediately show a controllable character; starting the Hall directly with F5 would also start in walking third person. The overview would remain available with 1. This direct-F5 behavior change is part of the proposal, not an unmentioned side effect. Other gallery entries would stay unchanged; normalizing their startup can be a separate approval if desired.

No fix or runtime-source modification has been made. User approval is required because this task explicitly requested a proposal before implementation.

## Current workaround and preservation

Click inside the running game, then **1 -> Tab -> WASD/mouse**. For the Hall, walk up the front stairs and press **E** if the doors are closed. If these keys still do nothing, capture that session's Output/Debugger and whether the game is focused/paused; that would be additional evidence beyond the reproduced startup mismatch.

Preservation audit: **all 5,118 pre-existing test-project files unchanged**, including the indoor-camera fix, gallery, building scenes, staging, materials and handoff; **all 1,599 original-project files unchanged**. New files are limited to this report and `reports/walk-asset-investigation/` diagnostic/evidence files. Details: `walk-asset-investigation/preservation.json`. No building assets or layout were modified, and no fix was applied.

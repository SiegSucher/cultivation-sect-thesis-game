<!-- claude-integration-current -->
> Current asset status: eight standalone gallery entries, including four tested Claude buildings. See [Codex report](reports/CODEX_REPORT.md) and `HANDOFF.md`. `Review Claude Assets.cmd` opens one-asset inspection. Staging/original preserved; no town placement. Earlier four-facility notes below are historical.

<!-- stages-2-3-current -->
> Current continuation: Training Ground and Scripture Pavilion and their props/leaves are now converted and verified. [Stages 2–3 report](reports/LOW_POLY_STAGES_2_3_REPORT.md) contains actual results, two benchmark rounds, screenshots and limitations. The earlier Hall/stage-1 measurements below are historical, not a whole-town claim. Training retains 84 inherited roof collider degenerates.

# Split-Cloud Main Sect Hall

**Environment continuation, 22 October 2026:** the audit and first conversion stage (Sect Gate plus leaves) are complete. [Inventory](reports/LOW_POLY_CONVERSION_INVENTORY.md) · [Stage 1 report and genuine comparisons](reports/LOW_POLY_STAGE_1_REPORT.md). Run `Review Stage 1 Sect Gate.cmd` or select Sect Gate → Walk asset in the gallery. Training Ground and Scripture Pavilion remain unconverted. No assembled town/terrain/roads/vegetation exists in this project. Stop for stage-1 review before further expansion.

**Visual direction approved on 22 October 2026; roof collider repaired and retested.** The design is preserved. Read [verification results](reports/VERIFICATION_RESULTS.md), [root cause and coverage proof](reports/ROOF_COLLISION_FIX.md), and [performance comparison](reports/performance_comparison.md). No other building conversion is authorized.

Open `Launch Low Poly Test.cmd`, or import `project.godot` with Godot 4.7.2 and press Run. The launcher uses the existing shared Godot software binary; the project itself uses no resources from the original workshop. `Launch Original Baseline.cmd` runs the preserved baseline in the same room.

Controls:

- **1:** enter walking view / return to the fixed exterior view.
- **WASD / mouse:** move and look while walking.
- **Tab:** first-person / third-person while walking.
- **E:** open / close the three door mechanisms.
- **2 / 3 / 4:** front / three-quarter / interior inspection views.
- **Esc:** copied asset gallery; Main Hall's **Walk asset** returns here.

The original project is `../asset-workshop/`. This is a sibling project, not a town replacement. Other copied facilities are unchanged. The player is the existing 1.8 m inspection fixture; a production game player and town do not exist in the active source.

Inspect [the final report](reports/low_poly_test_report.md), [design](reports/BUILDING_DESIGN.md), [performance comparison](reports/performance_comparison.md) and [Claude handoff](HANDOFF.md). Genuine matching before/after images are in `reports/screenshots/`. Low-end device performance, human playtesting, future production-player integration and a populated town remain unverified.

Editable source: `source/split_cloud_hall.blend`. Authoring program: `tools/build_split_cloud.py`, run with Blender 5.2.2 LTS. Building geometry is organized into material batches; enter Blender Edit Mode to edit its component islands. Grand and Private collections contain hinge-local door sources, separate from the Hall batch collection. Godot supplies the editable plaque text. No texture downloads or additional plugins are needed.

Recovery is `original_runtime_recovery.zip`; original-file fingerprints and final audits are under `reports/`. Do not expand this experiment to other buildings without review and further instruction.

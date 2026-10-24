# Phase 4D — Building and district integration

**Ready for human visual review; Phase 4D is not approved. No Phase 4E work started.** The user's approval of compact Phase 4B and Phase 4C governs this baseline; their older review-status text is retained as history.

## Launch

Double-click [Launch Phase 4D.cmd](../Launch%20Phase%204D.cmd), or select `res://phase4d/phase4d_valley.tscn` in the working test project and press F6. WASD/mouse move/look; Tab switches first/third person; M map, V valley overview, R forest start. Existing door behavior and review shortcuts remain. F5 and prior launchers are unchanged.

## What changed

Inspected all twelve canonical buildings in the assembled approved scene, using gameplay-height entrance views and wider context views. No visible floating/buried foundations in those views justified a foundation rebuild. Baseline walking reached every intended entrance and seven selected interiors. Medicine's visible threshold coping was continuous and traversable, so its canonical stairs/collision were left alone.

The confirmed visual problem was short grass wedges between rounded route caps and square stair feet/gate openings. Added **ten small ground connections, totaling 177.18 m²**, joining existing routes/courts to those feet. Stone surfaces reuse the approved paving material and color; the Herb Garden continues the existing earth treatment. These are short rectangles/tapers, not new plazas. The Gate and Main Hall already read clearly and were left unchanged.

The scene inherits approved Phase 4C, including its latest mountains and arrival railings. **320 × 400 m planning, 640 × 720 m terrain, all twelve building transforms/scales, terrace heights, routes, stairs, rails, retaining walls and props remain unchanged.** No terrain builder ran. The thin visual surfaces follow the existing paving convention and have buried side edges fitted to the actual ground; walking continues on the inherited collision. No collision shapes, assets, decoration, systems or controller/camera changes were added.

## Twelve-building inspection

All rows had supported visible bases in the inspected front/side views and clear exterior access. Links pair matching before/after views for every correction.

| Building | Inspected condition | Correction or no change | Remaining limit |
|---|---|---|---|
| Sect Gate | Arrival paving already meets its steps; open passage works | **No change** | Gatehouse interiors not retested |
| Mission Hall | Rounded lane cap leaves grass at stair corners | [3.40 m × 6 m stone connection](comparison-mission_hall-gameplay.png) | Representative interior route only |
| Exchange Hall | Cap narrows before the square stair foot | [2.20 m × 6 m stone connection](comparison-exchange_hall-gameplay.png) | Storerooms not retested |
| Disciples' Residence | Short rounded connection to shared front steps | [2.24 m connection, 6 → 5.8 m wide](comparison-disciple_residence-gameplay.png) | One room sampled; use its doorway, not a diagonal through the open leaf |
| Dining / Kitchen | Grass wedges between lane and stairs | [2.90 m × 6 m connection](comparison-dining_hall_kitchen-gameplay.png) | Dining entry sampled; service/kitchen routes not retested |
| Training Ground | Existing apron stops before the full-width court entrance | [2.80 m × 12 m connection](comparison-martial_training_ground-gameplay.png) | Equipment/dais/interior shelters unchanged |
| Main Sect Hall | Broad forecourt and existing stairs already connect clearly | **No change** | Foyer route sampled; rear/furniture routes not audited |
| Scripture Pavilion | Short grass gap after the shared ledge court | [2.70 m connection, 5 → 4.8 m wide](comparison-scripture_pavilion-gameplay.png) | Upper galleries/restricted archive not tested |
| Elder Residence | Route cap tapers before the estate gate | [3.42 m connection, 6 → 3 m wide](comparison-elder_residence-gameplay.png) | Gate/courtyard entrance checked, inner residence not tested |
| Alchemy Pavilion | Short grass approach beside the existing basins | [4.24 m taper, 4.8 → 3.4 m wide](comparison-alchemy_pavilion-context.png) | Representative interior route only |
| Medicine Hall | Shared court ends 1 m before the stair foot | [1 m × 6 m connection](comparison-medicine_hall-gameplay.png) | Canonical threshold gap/steep loft stairs retained; camera-only exception preserved |
| Spirit Herb Garden | Earth lane stops short of its gate walk | [5.70 m earth taper, 7 → 2.6 m wide](comparison-spirit_herb_garden-gameplay.png) | Garden entry sampled; every bed aisle not tested |

## Screenshots and district composition

Third-person gameplay: [living street](district-living-street.png), [Training connection](district-training-connection.png), [Scripture/Elder ledge](district-scholarly-ledge.png), [Medicine/Herb district](district-healing-district.png), [Hall forecourt](district-hall-forecourt.png). Also [Gate arrival](after-sect_gate-gameplay.png) and [Alchemy entrance](after-alchemy_pavilion-gameplay.png).

Raw `before-<building>-gameplay/context.png` and matching `after-*` captures cover all twelve buildings. Every corrected building also has both `comparison-<building>-gameplay.png` and `comparison-<building>-context.png`. Same positions, yaw, resolution and lighting were used; pairs are only labeled, not retouched. Before inspection sheets: [buildings 1–6](inspection-gameplay-1.png), [7–12](inspection-gameplay-2.png).

## Checks actually performed

- **38 entrance checks passed:** all twelve route-to-foot approaches and existing entrance/stair routes; entry into Mission, Exchange, one residence room, Dining, Hall, Alchemy and Medicine in third person, with first-person exits. [Results](after-entries.json). The initial approved-scene entry baseline separately passed 31 checks.
- **44 route/support checks passed:** launch, Tab switching, Medicine camera exception; continuous forest → Gate → living → Hall walking; scholarly/Elder/library, Alchemy, Training and healing branches; **50 ground samples** under the changed surfaces; unchanged building transforms and inherited terrain/path/collision resources. Main route measured **242.80 m / 62.78 s active walking**, at unchanged 4 m/s. [Results](route-results.json).
- **31 rendered checks passed:** launch/Tab, Mission and Medicine entry in both views, and 24 saved matching building captures. Five further district gameplay captures were inspected. [Results](rendered-results.json).
- [Preservation](preservation.json): **6,277 pre-existing project files unchanged**, none missing or added outside `phase4d/`. Canonical scenes match `assets/gallery/catalog.json`; Phase 4C, compact baseline, large map, Phase 4A and staging remain intact.

One first-pass Alchemy taper corner reached a 0.43 m ground dip; its outer width was reduced from 8 to 4.8 m, with no terrain change. Final support samples are within 5.9 cm below the approved tier. One initial residence exit probe cut diagonally into an open leaf; its route was corrected to pass through the existing doorway. No building collision was altered. Initial evidence is retained.

These are **automated checks and agent screenshot inspections, not human playtesting or approval**. No full gallery suite, exhaustive interiors, performance/export or new gameplay testing was performed. Existing outer arrival-shoulder snags were left alone; the ordinary demonstration route did not reproduce a blocker. Headless logs retain the host certificate-store warning. Ground treatments remain prototype visual paving over inherited terrain collision.

## Files and recovery

All additions are under `phase4d/`: inherited scene, launcher/README, `walkthrough.gd` HUD wrapper, `entrances.json`, `build_connections.gd`, `resources/entrance_surfaces.res`, `resources/entrance_connections.tscn`, and review fixtures/evidence. No pre-existing project file was edited.

[approved-phase4c-recovery.zip](approved-phase4c-recovery.zip) preserves Phase 4C sources, scene, generated resources and key review records, including the latest mountains and arrival rails. [before-hashes.json](before-hashes.json) records protected files. No recovery depends on Git. Phase 4D can be ignored by launching the untouched Phase 4C scene; archived Phase 4C files use project-relative paths if ever needed for recovery.

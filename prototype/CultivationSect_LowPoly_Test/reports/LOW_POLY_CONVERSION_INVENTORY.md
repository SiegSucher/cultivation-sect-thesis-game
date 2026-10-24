# Current low-poly asset inventory — twelve standalone facilities

23 October 2026. Alchemy Pavilion and Medicine Hall are now independently reviewed/tested/corrected/integrated alongside the earlier ten facilities. Current runtime: twelve catalog entries, 35 GLBs and 38 scenes. Their staged models/shared source remain frozen; final human/production-world acceptance is pending. This is an asset workshop, not a completed town. No final town placements were assigned. Full new-asset evidence: `CODEX_REPORT.md`; earlier conversion counts and limitations remain in `LOW_POLY_STAGES_2_3_REPORT.md`.

| Category | Classification | Current finding |
| --- | --- | --- |
| Main Sect Hall | Already converted / approved | Preserved; earlier roof repair unchanged |
| Sect Gate and paired leaves | Already converted | Preserved |
| Training Ground / seven equipment kinds | Already converted; issues retained | Preserved; timing regression and 84 degenerate roof collider triangles still unresolved |
| Scripture Pavilion / library props / archive leaves | Already converted | Preserved; current review input routes retested |
| Disciples' Residence | Already converted / integrated; human review pending | Four rooms, veranda, furnishings; Godot scene/scale/material/movement/camera tests pass |
| Elder Residence compound | Already converted / integrated; human review pending | Main house, attendant wing, courtyard/gate/embedded pines; supporting ground required |
| Dining Hall and Kitchen | Already converted / integrated; human review pending | Dining, kitchen, service door/stair, furniture/well; tests pass |
| Spirit Herb Garden | Already converted / integrated; human review pending | Embedded plants/beds, spring, pavilion and shed; supporting terrain required; path slabs visual-only |
| Mission Hall | Already converted / independently tested / integrated; human review pending | Canonical scene and gallery Walk; 17,790 triangles, 12 materials, 37 colliders; no terrain/performance verification |
| Alchemy Pavilion | Independently reviewed/tested / integrated; human review pending | 25,586 triangles, 13 materials, 45 colliders; leaf camera coverage fixed; Walk available |
| Medicine Hall | Independently reviewed/tested / integrated; human review pending | 20,636 triangles, 15 materials, 54 colliders; counter/camera detail coverage fixed; production character must honor camera-only body exception |
| Contribution / Exchange Hall | Already created/imported; independently reviewed/tested; integrated | 31,346 triangles, 13 materials, 73 colliders (69 original + 4 static-leaf coverage boxes); Walk and interior gallery preset; no performance/terrain acceptance |
| Planting / courtyard props | Partially converted / embedded assets | New embedded garden plants/potted pines exist; no general production vegetation/scenery library inspected |
| Lighting across facilities | Partially converted / preserved review rigs | Shared palette; no integrated-world lighting or new-asset performance measurement |
| Production terrain/cliffs, road/path/bridge network, shops/other queued facilities | Requires inspection / not supplied | Embedded facility paths do not constitute a world road layout; do not invent missing assets |
| Town layout / production navigation / NPC / player systems | Requires inspection / absent | Inspection floor/controller only; final placement explicitly deferred |

## Every runtime GLB (current)

| Model | Status | Triangles | Surfaces | Embedded images |
| --- | --- | --- | --- | --- |
| assets/architecture/alchemy_pavilion/alchemy_pavilion.glb | Independently tested / integrated; human review pending | 25586 | 13 | 0 |
| assets/architecture/medicine_hall/medicine_hall.glb | Independently tested / integrated; human review pending | 20636 | 15 | 0 |
| assets/architecture/dining_hall_kitchen/dining_hall_kitchen.glb | Integrated; visual review pending | 23328 | 12 | 0 |
| assets/architecture/disciple_residence/disciple_residence.glb | Integrated; visual review pending | 9518 | 12 | 0 |
| assets/architecture/exchange_hall/exchange_hall.glb | Independently tested / integrated; human review pending | 31346 | 13 | 0 |
| assets/architecture/elder_residence/elder_residence.glb | Integrated; visual review pending | 16338 | 13 | 0 |
| assets/architecture/martial_training_ground/arm_dummy.glb | Previously converted / preserved | 544 | 3 | 0 |
| assets/architecture/martial_training_ground/martial_training_ground.glb | Previously converted / preserved | 88020 | 13 | 0 |
| assets/architecture/martial_training_ground/martial_training_ground_lod.glb | Previously converted / preserved | 12913 | 13 | 0 |
| assets/architecture/martial_training_ground/rest_bench.glb | Previously converted / preserved | 264 | 3 | 0 |
| assets/architecture/martial_training_ground/staff_rack.glb | Previously converted / preserved | 868 | 4 | 0 |
| assets/architecture/martial_training_ground/stone_weight.glb | Previously converted / preserved | 100 | 2 | 0 |
| assets/architecture/martial_training_ground/striking_post.glb | Previously converted / preserved | 2820 | 4 | 0 |
| assets/architecture/martial_training_ground/sword_rack.glb | Previously converted / preserved | 916 | 3 | 0 |
| assets/architecture/martial_training_ground/thrust_target.glb | Previously converted / preserved | 504 | 4 | 0 |
| assets/architecture/scripture_pavilion/archive_gate_left.glb | Previously converted / preserved | 124 | 4 | 0 |
| assets/architecture/scripture_pavilion/archive_gate_right.glb | Previously converted / preserved | 124 | 4 | 0 |
| assets/architecture/scripture_pavilion/library_lantern.glb | Previously converted / preserved | 168 | 3 | 0 |
| assets/architecture/scripture_pavilion/reading_stool.glb | Previously converted / preserved | 220 | 2 | 0 |
| assets/architecture/scripture_pavilion/reading_table.glb | Previously converted / preserved | 468 | 4 | 0 |
| assets/architecture/scripture_pavilion/scripture_pavilion.glb | Previously converted / preserved | 110960 | 11 | 0 |
| assets/architecture/scripture_pavilion/scripture_pavilion_lod.glb | Previously converted / preserved | 22248 | 11 | 0 |
| assets/architecture/scripture_pavilion/scripture_shelf.glb | Previously converted / preserved | 2984 | 5 | 0 |
| assets/architecture/scripture_pavilion/scroll_cabinet.glb | Previously converted / preserved | 2600 | 4 | 0 |
| assets/architecture/scripture_pavilion/sealed_cabinet.glb | Previously converted / preserved | 272 | 5 | 0 |
| assets/architecture/sect_gate/gate_leaf_left.glb | Previously converted / preserved | 2724 | 3 | 0 |
| assets/architecture/sect_gate/gate_leaf_right.glb | Previously converted / preserved | 2724 | 3 | 0 |
| assets/architecture/sect_gate/sect_gate.glb | Previously converted / preserved | 78667 | 11 | 0 |
| assets/architecture/sect_gate/sect_gate_lod.glb | Previously converted / preserved | 14666 | 11 | 0 |
| assets/architecture/mission_hall/mission_hall.glb | Independently tested / integrated; human review pending | 17790 | 12 | 0 |
| assets/architecture/spirit_herb_garden/spirit_herb_garden.glb | Integrated; visual review pending | 12474 | 13 | 0 |
| assets/architecture/tang_main_hall/grand_door_leaf.glb | Previously converted / preserved | 264 | 3 | 0 |
| assets/architecture/tang_main_hall/main_sect_hall.glb | Previously converted / preserved | 71557 | 12 | 0 |
| assets/architecture/tang_main_hall/main_sect_hall_lod.glb | Previously converted / preserved | 71557 | 12 | 0 |
| assets/architecture/tang_main_hall/room_door_leaf.glb | Previously converted / preserved | 264 | 3 | 0 |

## Every runtime scene

| Scene | Status | Direct resources |
| --- | --- | --- |
| scenes/asset_gallery.tscn | Existing/preserved asset/review | res://scripts/asset_gallery.gd |
| scenes/buildings/alchemy_pavilion.tscn | Independently tested / integrated; leaf collision corrected | res://assets/architecture/alchemy_pavilion/alchemy_pavilion.glb |
| scenes/buildings/medicine_hall.tscn | Independently tested / integrated; counter/camera collision corrected | res://assets/architecture/medicine_hall/medicine_hall.glb; res://assets/architecture/medicine_hall/medicine_camera_obstructions.tres |
| scenes/buildings/dining_hall_kitchen.tscn | New integrated asset/review | res://assets/architecture/dining_hall_kitchen/dining_hall_kitchen.glb |
| scenes/buildings/disciple_residence.tscn | New integrated asset/review | res://assets/architecture/disciple_residence/disciple_residence.glb |
| scenes/buildings/exchange_hall.tscn | Independently tested / integrated; static-leaf collision corrected | res://assets/architecture/exchange_hall/exchange_hall.glb |
| scenes/buildings/elder_residence.tscn | New integrated asset/review | res://assets/architecture/elder_residence/elder_residence.glb |
| scenes/buildings/martial_training_ground.tscn | Existing/preserved asset/review | res://scripts/martial_training_ground.gd |
| scenes/buildings/scripture_pavilion.tscn | Existing/preserved asset/review | res://scripts/scripture_pavilion.gd |
| scenes/buildings/sect_gate.tscn | Existing/preserved asset/review | res://scripts/sect_gate.gd |
| scenes/buildings/mission_hall.tscn | Independently tested / integrated | res://assets/architecture/mission_hall/mission_hall.glb |
| scenes/buildings/spirit_herb_garden.tscn | New integrated asset/review | res://assets/architecture/spirit_herb_garden/spirit_herb_garden.glb |
| scenes/buildings/tang_main_hall.tscn | Existing/preserved asset/review | res://scripts/tang_main_hall.gd |
| scenes/hall_experiment.tscn | Existing/preserved asset/review | res://scripts/hall_experiment.gd |
| scenes/props/scripture/library_lantern.tscn | Existing/preserved asset/review | res://scripts/scripture_prop.gd |
| scenes/props/scripture/reading_stool.tscn | Existing/preserved asset/review | res://scripts/scripture_prop.gd |
| scenes/props/scripture/reading_table.tscn | Existing/preserved asset/review | res://scripts/scripture_prop.gd |
| scenes/props/scripture/scripture_shelf.tscn | Existing/preserved asset/review | res://scripts/scripture_prop.gd |
| scenes/props/scripture/scroll_cabinet.tscn | Existing/preserved asset/review | res://scripts/scripture_prop.gd |
| scenes/props/scripture/sealed_cabinet.tscn | Existing/preserved asset/review | res://scripts/scripture_prop.gd |
| scenes/props/training/arm_dummy.tscn | Existing/preserved asset/review | res://scripts/training_prop.gd |
| scenes/props/training/rest_bench.tscn | Existing/preserved asset/review | res://scripts/training_prop.gd |
| scenes/props/training/staff_rack.tscn | Existing/preserved asset/review | res://scripts/training_prop.gd |
| scenes/props/training/stone_weight.tscn | Existing/preserved asset/review | res://scripts/training_prop.gd |
| scenes/props/training/striking_post.tscn | Existing/preserved asset/review | res://scripts/training_prop.gd |
| scenes/props/training/sword_rack.tscn | Existing/preserved asset/review | res://scripts/training_prop.gd |
| scenes/props/training/thrust_target.tscn | Existing/preserved asset/review | res://scripts/training_prop.gd |
| scenes/review/dining_hall_kitchen_walkthrough.tscn | New integrated asset/review | res://scripts/claude_asset_review.gd |
| scenes/review/disciple_residence_walkthrough.tscn | New integrated asset/review | res://scripts/claude_asset_review.gd |
| scenes/review/elder_residence_walkthrough.tscn | New integrated asset/review | res://scripts/claude_asset_review.gd |
| scenes/review/mission_hall_walkthrough.tscn | Independently tested / integrated | res://scripts/mission_hall_review.gd |
| scenes/review/exchange_hall_walkthrough.tscn | Independently tested / integrated | res://scripts/exchange_hall_review.gd |
| scenes/review/alchemy_pavilion_walkthrough.tscn | Independently tested / integrated | res://scripts/alchemy_medicine_review.gd |
| scenes/review/medicine_hall_walkthrough.tscn | Independently tested / integrated | res://scripts/alchemy_medicine_review.gd |
| scenes/review/gate_walkthrough.tscn | Existing/preserved asset/review | res://scripts/gate_walkthrough.gd |
| scenes/review/scripture_walkthrough.tscn | Existing/preserved asset/review | res://scripts/scripture_walkthrough.gd |
| scenes/review/spirit_herb_garden_walkthrough.tscn | New integrated asset/review | res://scripts/claude_asset_review.gd |
| scenes/review/training_walkthrough.tscn | Existing/preserved asset/review | res://scripts/training_walkthrough.gd |

Baseline, staging, source, recovery and evidence copies are intentionally excluded from the runtime-model totals. Matching palette values do not imply cross-file GPU material sharing. New building scenes depend only on their own embedded-material GLB, with unchanged authored collision. Old Training/Pavilion reusable props retain their original MultiMesh/collider transforms. Physical JSON in those older assets still has historical visual counts; use GLBs/current sidecars for actual geometry budgets. New assets have no LOD/distant mesh. No production world, new-asset performance or final terrain-fit verification is claimed.

Latest integration: Alchemy/Medicine details, source/collision contract, executed tests, 50 screenshots and limitations are in `CODEX_REPORT.md`. No world placement or performance measurement is implied.

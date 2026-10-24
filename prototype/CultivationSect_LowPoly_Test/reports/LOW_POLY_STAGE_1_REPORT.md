# Environment conversion - stage 1: Sect Gate

22 October 2026. **Audit and first representative group completed; stop here for review before expanding.** The approved Main Sect Hall remains unchanged. Only the Gate's near/distant visual meshes and two leaves were converted. Training Ground/Pavilion remain in the previous textured style. There is no assembled town in this project, so no whole-town conversion claim is made.

[Full conversion inventory and proposed order](LOW_POLY_CONVERSION_INVENTORY.md). Inspection covered all 27 runtime GLBs and 21 pre-existing scenes, with per-file material/texture counts and dependencies. One new gate inspection scene was added. Residences, shops, terrain/cliffs, roads, vegetation, production navigation and a populated-world scene are absent and classified Requires inspection; no substitutes or retired assets were imported.

## First-stage design and actual changes

Retained the existing fortified gate and its independent architectural identity: high central watch gallery, lower guard-tower roofs, broad arched passage, slit windows, timber leaves, standards, lanterns and front/rear threshold stairs. Did not duplicate the Main Hall's architecture. Converted the four GLBs using exact hall palette values, opaque standard materials, flat shading and no texture nodes. Stone roles share the blue-grey stone palette; coping/paving use pale stone, timber/iron use dark oxblood, brackets cedar, roof/seams muted jade, recesses deep blue-green and hardware restrained bronze. No custom shader or extra lights.

Limited dissolve consolidated shallow surface subdivisions: 2 degrees generally, 10 degrees for tile-edge candidates, keeping boundaries. No collapse-ratio decimation, root scaling or new silhouette was used. Actual import bounds match originals. Tile-edge ribs themselves remain at 40,520 triangles; the measured savings came from redundant roof-field and timber subdivisions, not a claim of rib removal. Further aggressive rib simplification was intentionally deferred to avoid unnecessary silhouette changes.

| Runtime model | Before triangles | After triangles | Surfaces before / after |
| --- | ---: | ---: | ---: |
| sect_gate.glb | 87,426 | 78,667 | 15 / 11 |
| sect_gate_lod.glb | 14,902 | 14,666 | 15 / 11 |
| gate_leaf_left.glb | 2,724 | 2,724 | 4 / 3 |
| gate_leaf_right.glb | 2,724 | 2,724 | 4 / 3 |

Near gate reduction: **10.0%**. Near/distant used materials: 11 each; leaf materials: 3 each. Embedded images/textures: zero after (24 images near/distant and 5 per leaf before). Material values and in-source objects are shared; separately exported GLBs embed their materials, so cross-file GPU-resource sharing is not claimed.

Editable new source: `../source/sect_gate_low_poly.blend`. Reproducible conversion: `../tools/convert_gate_stage1.py`. Original gate GLBs and physical specification are retained in `../baseline/stage1_gate/` and `../checkpoints/before-environment-stage1-sect-gate.zip`, in addition to the untouched original workshop/recovery archive. Imported unused native-material datablocks were removed from the new source without re-exporting runtime meshes. Blender's optional external thumbnail write failed in the sandbox; .blend save/reopen and all source checks succeeded.

Gate collision/scale JSON and gate mechanics are byte-identical, including hinge coordinates, 8.4 m opening, 0.60 m platform, four 0.15 m risers on both sides and 31 m overall width. The JSON's historical visual counts remain as authored; actual current counts are in `assets/architecture/sect_gate/low_poly_stage1_metrics.json` and this report. No world position exists here to move, and no layout was created. Existing player/camera code, renderer and settings remain untouched.

## Actual functional and preservation evidence

| Check | Result |
| --- | --- |
| Gate before conversion | 16 PASS / 0 FAIL |
| Gate after conversion | 16 PASS / 0 FAIL |
| Existing front/rear stairs and passage | PASS with unchanged 1.8 m inspection controller |
| Closed/open doors and existing animation | PASS; original gate script and JSON untouched |
| First/third person | PASS, both captured and measured |
| Review input/gallery Gate Walk | 7 PASS / 0 FAIL, programmatic key events |
| Actual imported near/LOD/leaf bounds | 4 PASS / 0 FAIL, within 0.0001 units |
| Reopened new Blender source | 5 PASS / 0 FAIL; 28 editable batches, 11 used texture-free materials |
| Approved Hall dimensions/camera checks | 18 PASS / 0 FAIL |
| Existing Hall input/gallery regression | 7 PASS / 0 FAIL |
| Independent gate runtime, no copied cache/metadata/symlinks | 16 PASS / 0 FAIL |
| Current Godot import/restart/runtime logs | No errors/warnings in checked final logs |
| Original project preservation | 1,599 recorded original non-cache hashes unchanged |
| Approved Hall, other facilities, existing controls and settings | Pre-stage hashes unchanged outside the six explicitly allowed gate/catalog/gallery files |


Stage changed only four pre-existing gate GLBs, gallery registry status/source metadata, and the gallery's Gate Walk route. New files are the gate review scene/script/launcher, conversion and verification tools, editable gate source, sidecar metrics, snapshots and reports. Unconverted asset resources were not silently recolored. [Final summary](environment-conversion-stage-1/final-summary.json), [runtime bounds](environment-conversion-stage-1/envelope-results.json), [geometry audit](environment-conversion-stage-1/geometry-audit.json).

## Same-scene before/after performance

Godot 4.7.2-stable (official), NVIDIA GeForce RTX 3050 Laptop GPU, GL Compatibility, 1280x720, MSAA 4x, VSync off, uncapped; six 240-frame samples after 45 warmup frames each. Same camera poses/FOVs, controller, floor, hall-matched environment, one 100 m shadowed sun and two unchanged unshadowed lanterns. Lighting/shadow costs were held constant, not separately profiled; rendering monitor counts include shadows/stage. No simultaneous Godot benchmark ran. GPU clocks, power, thermals and background load were not controlled.

| View | Mean ms before / after | p95 ms before / after | FPS before / after | Draw calls before / after | Objects before / after |
| --- | ---: | ---: | ---: | ---: | ---: |
| front | 2.067 / 2.028 | 2.910 / 2.433 | 483.8 / 493.2 | 78.0 / 60.0 | 187.0 / 171.0 |
| three-quarter | 2.043 / 1.969 | 2.869 / 2.505 | 489.4 / 507.8 | 78.0 / 60.0 | 187.0 / 171.0 |
| 360 sweep | 2.122 / 2.070 | 2.825 / 2.435 | 471.3 / 483.1 | 73.3 / 57.3 | 182.3 / 168.3 |
| passage | 2.351 / 2.193 | 2.945 / 2.688 | 425.3 / 455.9 | 93.0 / 71.0 | 202.0 / 182.0 |
| first-person | 1.982 / 1.752 | 2.883 / 2.146 | 504.4 / 570.7 | 92.0 / 71.0 | 201.0 / 182.0 |
| third-person | 2.363 / 2.141 | 3.018 / 2.531 | 423.1 / 467.1 | 124.0 / 95.0 | 233.0 / 206.0 |

Video-memory monitor at front: 110.09 / 50.67 MiB. These are whole-render monitor observations, not asset-only allocation or OS working set. All local mean timings stayed within or improved on the same-scene baseline, but small differences can be noise and do not establish sustained gains. Raw [before](environment-conversion-stage-1/before-results.json) / [after](environment-conversion-stage-1/after-results.json). The earlier Hall baseline remains documented separately; gate/hall frame times are different scenes and are not interchangeable controls.

## Genuine before/after and mixed-state screenshots

| Gate view | High-detail baseline | Converted stage 1 |
| --- | --- | --- |
| front | [Before](environment-conversion-stage-1/before-front.png) | [After](environment-conversion-stage-1/after-front.png) |
| three-quarter | [Before](environment-conversion-stage-1/before-three-quarter.png) | [After](environment-conversion-stage-1/after-three-quarter.png) |
| roof | [Before](environment-conversion-stage-1/before-roof.png) | [After](environment-conversion-stage-1/after-roof.png) |
| passage | [Before](environment-conversion-stage-1/before-passage.png) | [After](environment-conversion-stage-1/after-passage.png) |
| first-person | [Before](environment-conversion-stage-1/before-first-person.png) | [After](environment-conversion-stage-1/after-first-person.png) |
| third-person | [Before](environment-conversion-stage-1/before-third-person.png) | [After](environment-conversion-stage-1/after-third-person.png) |

Mixed-state gallery: [approved Hall](environment-conversion-stage-1/approved-hall.png), [converted Gate](environment-conversion-stage-1/converted-gate.png), [unconverted Training Ground](environment-conversion-stage-1/unconverted-training.png), [unconverted Pavilion](environment-conversion-stage-1/unconverted-pavilion.png). These show the actual assets in separate neutral review stages; they do not pretend to be a town layout. Exterior, roof and passage images were inspected for major holes/missing materials/clipping; no obvious new major issue was found in these views. This is not exhaustive geometric seam or z-fighting certification.

## Gate for further expansion

**Local style/performance candidate passes automated checks; user visual review pending. Stop after stage 1.** The next proposed group is the Training bench/stone weight/staff rack/sword rack, which already have economical silhouettes and may only need material harmonization. Review the gate first. Do not touch Training/Pavilion or create a town automatically.

NOT TESTED: human keyboard/mouse playtesting; user visual acceptance of this first gate stage; representative low-end hardware; sustained thermal/long-run stutter; exported executable; whole-town composition, performance, navigation or production-player compatibility; exhaustive geometry-intersection/camera orientations/pixel-level distance transitions. Training/Pavilion loaded for context captures, but their movement/archive-permission regression suites were not rerun in this stage. Their resources/scripts remain unchanged.

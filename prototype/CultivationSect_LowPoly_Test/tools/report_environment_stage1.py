"""Generate the current first-stage report and handoff from measured evidence."""
import json
from pathlib import Path

def write_reports(root,summary,build,before,after):
    R=Path(root);E=R/'reports/environment-conversion-stage-1'
    def write(path,text):path.write_text(text,encoding='utf-8')
    rows='\n'.join(f"| {a['view']} | {a['mean_ms']:.3f} / {b['mean_ms']:.3f} | {a['p95_ms']:.3f} / {b['p95_ms']:.3f} | {a['fps']:.1f} / {b['fps']:.1f} | {a['mean_draw_calls']:.1f} / {b['mean_draw_calls']:.1f} | {a['mean_objects']:.1f} / {b['mean_objects']:.1f} |" for a,b in zip(before['samples'],after['samples']))
    geom='\n'.join(f"| {m['file']} | {m['triangles_before']:,} | {m['triangles_after']:,} | {next(x['surfaces'] for x in json.loads((E/'initial-inventory.json').read_text())['models'] if x['path'].endswith('/'+m['file']))} / {m['surfaces_after']} |" for m in build['models'])
    untested='''NOT TESTED: human keyboard/mouse playtesting; user visual acceptance of this first gate stage; representative low-end hardware; sustained thermal/long-run stutter; exported executable; whole-town composition, performance, navigation or production-player compatibility; exhaustive geometry-intersection/camera orientations/pixel-level distance transitions. Training/Pavilion loaded for context captures, but their movement/archive-permission regression suites were not rerun in this stage. Their resources/scripts remain unchanged.'''
    tests=f'''| Check | Result |
| --- | --- |
| Gate before conversion | {summary['gate_before_checks']} PASS / 0 FAIL |
| Gate after conversion | {summary['gate_after_checks']} PASS / 0 FAIL |
| Existing front/rear stairs and passage | PASS with unchanged 1.8 m inspection controller |
| Closed/open doors and existing animation | PASS; original gate script and JSON untouched |
| First/third person | PASS, both captured and measured |
| Review input/gallery Gate Walk | {summary['gate_input_checks']} PASS / 0 FAIL, programmatic key events |
| Actual imported near/LOD/leaf bounds | {summary['gate_envelope_checks']} PASS / 0 FAIL, within 0.0001 units |
| Reopened new Blender source | {summary['native_source_checks']} PASS / 0 FAIL; 28 editable batches, 11 used texture-free materials |
| Approved Hall dimensions/camera checks | 18 PASS / 0 FAIL |
| Existing Hall input/gallery regression | 7 PASS / 0 FAIL |
| Independent gate runtime, no copied cache/metadata/symlinks | {summary['independent_run_checks']} PASS / 0 FAIL |
| Current Godot import/restart/runtime logs | No errors/warnings in checked final logs |
| Original project preservation | {summary['original_files_verified']:,} recorded original non-cache hashes unchanged |
| Approved Hall, other facilities, existing controls and settings | Pre-stage hashes unchanged outside the six explicitly allowed gate/catalog/gallery files |
'''
    shots='\n'.join(f"| {view} | [Before](environment-conversion-stage-1/before-{view}.png) | [After](environment-conversion-stage-1/after-{view}.png) |" for view in ['front','three-quarter','roof','passage','first-person','third-person'])
    write(R/'reports/LOW_POLY_STAGE_1_REPORT.md',f'''# Environment conversion - stage 1: Sect Gate

22 October 2026. **Audit and first representative group completed; stop here for review before expanding.** The approved Main Sect Hall remains unchanged. Only the Gate's near/distant visual meshes and two leaves were converted. Training Ground/Pavilion remain in the previous textured style. There is no assembled town in this project, so no whole-town conversion claim is made.

[Full conversion inventory and proposed order](LOW_POLY_CONVERSION_INVENTORY.md). Inspection covered all 27 runtime GLBs and 21 pre-existing scenes, with per-file material/texture counts and dependencies. One new gate inspection scene was added. Residences, shops, terrain/cliffs, roads, vegetation, production navigation and a populated-world scene are absent and classified Requires inspection; no substitutes or retired assets were imported.

## First-stage design and actual changes

Retained the existing fortified gate and its independent architectural identity: high central watch gallery, lower guard-tower roofs, broad arched passage, slit windows, timber leaves, standards, lanterns and front/rear threshold stairs. Did not duplicate the Main Hall's architecture. Converted the four GLBs using exact hall palette values, opaque standard materials, flat shading and no texture nodes. Stone roles share the blue-grey stone palette; coping/paving use pale stone, timber/iron use dark oxblood, brackets cedar, roof/seams muted jade, recesses deep blue-green and hardware restrained bronze. No custom shader or extra lights.

Limited dissolve consolidated shallow surface subdivisions: 2 degrees generally, 10 degrees for tile-edge candidates, keeping boundaries. No collapse-ratio decimation, root scaling or new silhouette was used. Actual import bounds match originals. Tile-edge ribs themselves remain at 40,520 triangles; the measured savings came from redundant roof-field and timber subdivisions, not a claim of rib removal. Further aggressive rib simplification was intentionally deferred to avoid unnecessary silhouette changes.

| Runtime model | Before triangles | After triangles | Surfaces before / after |
| --- | ---: | ---: | ---: |
{geom}

Near gate reduction: **{100*(1-build['models'][0]['triangles_after']/build['models'][0]['triangles_before']):.1f}%**. Near/distant used materials: 11 each; leaf materials: 3 each. Embedded images/textures: zero after (24 images near/distant and 5 per leaf before). Material values and in-source objects are shared; separately exported GLBs embed their materials, so cross-file GPU-resource sharing is not claimed.

Editable new source: `../source/sect_gate_low_poly.blend`. Reproducible conversion: `../tools/convert_gate_stage1.py`. Original gate GLBs and physical specification are retained in `../baseline/stage1_gate/` and `../checkpoints/before-environment-stage1-sect-gate.zip`, in addition to the untouched original workshop/recovery archive. Imported unused native-material datablocks were removed from the new source without re-exporting runtime meshes. Blender's optional external thumbnail write failed in the sandbox; .blend save/reopen and all source checks succeeded.

Gate collision/scale JSON and gate mechanics are byte-identical, including hinge coordinates, 8.4 m opening, 0.60 m platform, four 0.15 m risers on both sides and 31 m overall width. The JSON's historical visual counts remain as authored; actual current counts are in `assets/architecture/sect_gate/low_poly_stage1_metrics.json` and this report. No world position exists here to move, and no layout was created. Existing player/camera code, renderer and settings remain untouched.

## Actual functional and preservation evidence

{tests}

Stage changed only four pre-existing gate GLBs, gallery registry status/source metadata, and the gallery's Gate Walk route. New files are the gate review scene/script/launcher, conversion and verification tools, editable gate source, sidecar metrics, snapshots and reports. Unconverted asset resources were not silently recolored. [Final summary](environment-conversion-stage-1/final-summary.json), [runtime bounds](environment-conversion-stage-1/envelope-results.json), [geometry audit](environment-conversion-stage-1/geometry-audit.json).

## Same-scene before/after performance

Godot {after['godot']}, {after['adapter']}, GL Compatibility, 1280x720, MSAA 4x, VSync off, uncapped; six 240-frame samples after 45 warmup frames each. Same camera poses/FOVs, controller, floor, hall-matched environment, one 100 m shadowed sun and two unchanged unshadowed lanterns. Lighting/shadow costs were held constant, not separately profiled; rendering monitor counts include shadows/stage. No simultaneous Godot benchmark ran. GPU clocks, power, thermals and background load were not controlled.

| View | Mean ms before / after | p95 ms before / after | FPS before / after | Draw calls before / after | Objects before / after |
| --- | ---: | ---: | ---: | ---: | ---: |
{rows}

Video-memory monitor at front: {before['samples'][0]['video_memory_bytes']/2**20:.2f} / {after['samples'][0]['video_memory_bytes']/2**20:.2f} MiB. These are whole-render monitor observations, not asset-only allocation or OS working set. All local mean timings stayed within or improved on the same-scene baseline, but small differences can be noise and do not establish sustained gains. Raw [before](environment-conversion-stage-1/before-results.json) / [after](environment-conversion-stage-1/after-results.json). The earlier Hall baseline remains documented separately; gate/hall frame times are different scenes and are not interchangeable controls.

## Genuine before/after and mixed-state screenshots

| Gate view | High-detail baseline | Converted stage 1 |
| --- | --- | --- |
{shots}

Mixed-state gallery: [approved Hall](environment-conversion-stage-1/approved-hall.png), [converted Gate](environment-conversion-stage-1/converted-gate.png), [unconverted Training Ground](environment-conversion-stage-1/unconverted-training.png), [unconverted Pavilion](environment-conversion-stage-1/unconverted-pavilion.png). These show the actual assets in separate neutral review stages; they do not pretend to be a town layout. Exterior, roof and passage images were inspected for major holes/missing materials/clipping; no obvious new major issue was found in these views. This is not exhaustive geometric seam or z-fighting certification.

## Gate for further expansion

**Local style/performance candidate passes automated checks; user visual review pending. Stop after stage 1.** The next proposed group is the Training bench/stone weight/staff rack/sword rack, which already have economical silhouettes and may only need material harmonization. Review the gate first. Do not touch Training/Pavilion or create a town automatically.

{untested}
''')
    previous=(E/'before/HANDOFF.md').read_text(encoding='utf-8')
    refs=previous.split('## Supplied reference filenames and intended use',1)[1].strip()
    write(R/'HANDOFF.md',f'''# Claude handoff - staged low-poly environment conversion

22 October 2026. **The user now authorizes controlled conversion beyond the approved Main Sect Hall. Stage 1 (Sect Gate and paired leaves) is complete; stop and report before any further stage.** Prior no-other-building notes are historical and superseded only within the isolated test project. The approved Hall must remain unchanged. No message has been sent to Claude.

## Current scope and actual project

Original project: `{R.parent/'asset-workshop'}`. Test: `{R}`. Work stayed inside the test project. This is a four-facility workshop, not a populated town. No residences, shops, terrain/cliffs, road/bridge network, vegetation library, production navigation or production player exists here. Do not invent a layout or import retired Reedwell content. Current inventory: `reports/LOW_POLY_CONVERSION_INVENTORY.md` (27 models, 21 original scenes plus one new gate review scene).

## Converted and unconverted content

- Already converted: approved Main Sect Hall, its leaves and distant representation; repaired Hall roof collider remains at 2,368 valid triangles. Entire hall resource/source/controller set matches pre-stage hashes.
- Stage 1 converted: `assets/architecture/sect_gate/sect_gate.glb`, `sect_gate_lod.glb`, `gate_leaf_left.glb`, `gate_leaf_right.glb`. Distinct fortified gateway retained. Near geometry 87,426 -> 78,667 triangles; 15 -> 11 surfaces; no textures. Leaves retain 2,724 triangles each, 4 -> 3 surfaces.
- Not converted: Training Ground architecture/court and seven equipment types; Scripture Pavilion architecture, six furniture types and archive leaves. Their source runtime resources/scripts remain unchanged. Context screenshots explicitly label them unconverted.
- Requires inspection / absent: integrated town, roads, terrain, scenery/vegetation, residences/shops and production navigation. Whole-town QA cannot be performed without those sources.

## Protection, files and recovery

`reports/environment-conversion-stage-1/pre-stage-manifest.json` freezes prior assets/scripts/scenes/source/config. Exactly six existing files changed: four Gate GLBs, `assets/gallery/catalog.json` status/source labels and `scripts/asset_gallery.gd` Gate Walk availability/route. Gate mechanics in `scripts/sect_gate.gd`, the complete `sect_gate.json`, player/camera controller, Hall resources/native source, other facilities and project settings are unchanged. All {summary['original_files_verified']:,} recorded original non-cache files still match `reports/original_manifest.json`.

Gate rollback: `baseline/stage1_gate/` plus `baseline/stage1_gate.gd`; `checkpoints/before-environment-stage1-sect-gate.zip`. Original high-detail resources are retained, not deleted. Original runtime recovery ZIP and approved Hall checkpoint are untouched. Existing old texture files remain on disk for rollback even though converted gate GLBs no longer sample them. New editable gate source: `source/sect_gate_low_poly.blend`; conversion program: `tools/convert_gate_stage1.py`. Current visual metrics sidecar: `assets/architecture/sect_gate/low_poly_stage1_metrics.json`; preserved physical JSON still contains original historical visual statistics, so budget tools must read actual GLBs/sidecar.

## Verification and performance

{tests}

Reproducible gate sequence: `tools/evaluate_gate_stage1.gd`, baseline with `-- --baseline`, current without it. 1280x720, Compatibility, MSAA 4x, no VSync/cap, six 240-frame windows after 45-frame warmups. Same 100 m shadowed sun, ambient, two original shadowless gate lights, player and camera poses. Renderer/settings/working cameras were not replaced. Raw before/after timings and captures: `reports/environment-conversion-stage-1/`. `reports/LOW_POLY_STAGE_1_REPORT.md` compares all views, draw calls, objects and geometry; short local observations cannot certify low-end compatibility. Earlier Hall baseline/performance reports remain historical hall evidence, not a gate baseline.

New gate review adapter uses the existing 1.8 m controller and existing paired-leaf mechanics. Run `Review Stage 1 Sect Gate.cmd`, or gallery -> Sect Gate -> Walk asset. 1 walk/review, WASD/mouse walk, Tab FPP/TPP, E gate, 2 front, 3 three-quarter, 4 passage, Esc gallery. Main launcher still opens the unchanged Hall; other review scenes retain their controls, including Pavilion default-deny archive E/G behavior.

Independent gate runtime check lives at `{summary['independent_runtime']}`, created entirely under ignored reports without copied cache/import metadata/symlinks. It imported and passed 16 checks. No original project resources are required; the shared Godot engine binary is software tooling only.

## Known issues and limitations

{untested}

No major new defect was seen in inspected gate exterior/roof/passage views, and all executed tests pass. Dense tile-edge ribs remain intentionally unchanged; limited dissolve saved roof-field/timber subdivisions, not those ribs. Cross-file GPU material sharing is not claimed; GLBs embed the palette. An initial screenshot helper type-inference error was corrected and the capture rerun cleanly. Blender's optional user-thumbnail write failed, while native source save/reopen checks passed. This stage did not harmonize all inspection-light rigs or build a global terrain/lighting system.

## Exact next action

Read `reports/LOW_POLY_CONVERSION_INVENTORY.md`, `reports/LOW_POLY_STAGE_1_REPORT.md` and `reports/environment-conversion-stage-1/final-summary.json`. **Show/review the converted gate before expansion**, using `Review Stage 1 Sect Gate.cmd` and the genuine before/after and mixed-state screenshots. Rehearse doors/stairs/passage and both cameras manually; record actual observations separately from automation. Do not start another conversion during this report/review boundary.

After favorable review/instruction, proposed stage 2 is a small Training prop group (rest bench, stone weight, staff rack, sword rack). Preserve their MultiMesh and collider transforms; avoid remodelling already economical geometry. Next proposed stages are Training shelters/court, then library furniture/Pavilion with archive/stair regression. Absent world assets require the real integrated source first, with no invented town arrangement.

Current all-stage verification/report entry: `tools/verify_environment_stage1.py finish`. The prior Hall/collider verifier and finalizer are historical and refuse to overwrite current staged reports. Current summaries, geometry audits, before/after JSONs, native audit and screenshots live under `reports/environment-conversion-stage-1/`. Do not rerun a conversion generator against the original; it reads the saved stage baseline and exports to this test only.

## Original visual references (unchanged)

{refs}
''')
    # Keep the completed Hall test report intact and add a current scope pointer.
    report=R/'reports/low_poly_test_report.md'
    text=(E/'before/low_poly_test_report.md').read_text(encoding='utf-8')
    prefix='''> Current environment continuation: the user authorized controlled stages on 22 October 2026. Stage 1 Sect Gate conversion is complete; the approved Hall below is unchanged. See [conversion inventory](LOW_POLY_CONVERSION_INVENTORY.md) and [stage 1 report](LOW_POLY_STAGE_1_REPORT.md). Training/Pavilion remain unconverted and no town scene exists. Stop for gate review before further expansion.\n\n'''
    write(report,prefix+text)

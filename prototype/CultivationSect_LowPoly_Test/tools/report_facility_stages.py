"""Write current inventory, stage report, and Claude handoff from executed evidence."""
from pathlib import Path
import json,struct,re
R=Path(__file__).resolve().parents[1]
E=R/'reports/environment-conversion-stages-2-3'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def table(headers,rows):return '\n'.join(['| '+' | '.join(headers)+' |','| '+' | '.join(['---']*len(headers))+' |']+['| '+' | '.join(map(str,row))+' |' for row in rows])
def brief(p):
    raw=p.read_bytes();n=struct.unpack_from('<I',raw,12)[0];d=json.loads(raw[20:20+n])
    return {'triangles':sum(d['accessors'][v['indices']]['count']//3 for m in d['meshes'] for v in m['primitives']),'surfaces':sum(len(m['primitives']) for m in d['meshes']),'images':len(d.get('images',[]))}
def write(summary):
    audit=read(E/'geometry-preservation-audit.json')
    rows=[];counts={}
    for short,family in [('training','martial_training_ground'),('pavilion','scripture_pavilion')]:
        models=audit['geometry'][short]
        byname={m['after']['file']:m for m in models}
        for m in models:
            a,b=m['before'],m['after']
            rows.append([short+'/'+a['file'],f"{a['triangles']:,} → {b['triangles']:,}",f"{a['surfaces']} → {b['surfaces']}",f"{a['images']} → {b['images']}"])
        spec=read(R/'assets/architecture'/family/(family+'.json'))
        extra=[spec['prop_definitions'][p['kind']]['file'] if 'file' in spec['prop_definitions'][p['kind']] else p['kind']+'.glb' for p in spec['prop_instances']]
        if short=='pavilion':extra+=['archive_gate_left.glb','archive_gate_right.glb']
        counts[short]={}
        for variant in ['before','after']:
            counts[short][variant]=byname[family+'.glb'][variant]['triangles']+sum(byname[f][variant]['triangles'] for f in extra)
        (R/'assets/architecture'/family/'low_poly_stage_metrics.json').write_text(json.dumps({'stage':2 if short=='training' else 3,'assembled_near_triangles_including_instanced_props_and_archive_leaves':counts[short]['after'],'models':[m['after'] for m in models],'note':'Physical specification stays byte-identical, including historical visual counts. Use current GLBs or this sidecar for budgets.'},indent=2))
    performance=[]
    for short in ['training','pavilion']:
        for suffix in ['', '-round2']:
            before=read(E/(short+'-before'+suffix+'-results.json'));after=read(E/(short+'-after'+suffix+'-results.json'))
            for a,b in zip(before['samples'],after['samples']):
                performance.append([short,'1' if not suffix else '2',a['view'],f"{a['mean_ms']:.2f} → {b['mean_ms']:.2f}",f"{a['p95_ms']:.2f} → {b['p95_ms']:.2f}",f"{a['fps']:.1f} → {b['fps']:.1f}",f"{a['mean_draw_calls']:.1f} → {b['mean_draw_calls']:.1f}",f"{a['mean_primitives']:,.0f} → {b['mean_primitives']:,.0f}"])
    report='''# Stages 2–3: Training Ground and Scripture Pavilion

22 October 2026. Latest user instruction authorizes these two existing facilities and associated assets. The approved Main Sect Hall and stage-1 Gate are preserved. This is a four-facility workshop, not an assembled town.

## Completed conversion and preservation

Stage 2: seven Training equipment types first, then near/LOD shelters and court. Stage 3: six library furnishing types and both archive leaves first, then near/LOD Pavilion architecture. Original silhouettes and architectural identities remain: open martial court with three low shelters versus tall three-storey library. No Hall architecture was copied across buildings. All 19 GLBs now use opaque texture-free palette materials and verified flat exported normals. Existing low-count equipment/furniture geometry was retained; shallow roof/frame subdivision was dissolved without collapse decimation. Building/prop imported bounds match baseline within 0.0001 m. Feet and hinge origins retain their original coordinates.

All existing runtime scripts, scenes, controllers/cameras, physical JSONs, light rigs and project settings remain byte-identical to the pre-stage manifest. Training's four recognized paving node names, shadow-off behavior, LOD bias and repaired thin ground geometry remain. MultiMesh placement remains governed by the unchanged JSON and scripts. No extra lights, shader effects, textures or production gameplay systems were introduced.

Palette follows the approved Hall. Two restrained ground roles extend it: Earth #806b50 and CourtStone #81938d; small coping/nosings retain the pale Hall color. Library bindings use the existing teal fabric, cedar and bronze hues; paper uses plaster. Material values repeat across GLBs, but cross-file GPU resource sharing is not claimed.

The first Training iteration exposed inherited custom split normals and an overly pale court. Clearing the stored custom normals fixed exported flat shading; a muted court material corrected the large white field. That discarded benchmark/captures remain in `environment-conversion-stages-2-3/training-initial-iteration/`; only the final iteration appears below. A separate Pavilion audit traced near-zero visual triangles to near-coincident endpoints already present in its original Timber batch (104 near-zero, 16 exactly zero). A targeted 2 micrometre seam weld at input, before triangulation, removed those redundant endpoints without changing the visible envelope or collider; output was re-audited and gameplay/benchmarks rerun. Diagnosis JSONs and the discarded Pavilion iteration are retained in the evidence folder. A type-inference error in a new envelope test was corrected and the test rerun. No asset runtime code was changed to make tests pass.

## Actual model counts

The preserved JSON contains historical counts. Current statistics are in per-facility `low_poly_stage_metrics.json`, actual GLBs, and the following audit; original textures remain unused on disk for recovery.

'''+table(['Model','Triangles before → after','Surfaces before → after','Embedded images before → after'],rows)+f'''

Assembled near geometry including repeated props: Training {counts['training']['before']:,} → {counts['training']['after']:,}; Pavilion {counts['pavilion']['before']:,} → {counts['pavilion']['after']:,}. These are isolated facilities, not a whole-world render budget. The dense roof ribs remain; not every visual triangle has been aggressively reduced.

## Executed verification

'''+table(['Check','Result'],summary['verification_rows'])+'''

Functional suites use the unchanged 1.8 m/.28 m inspection capsule, 4 m/s movement, and real `move_and_slide`. Fixed-fps 60 is used only to advance reproducible functional rehearsals; their timings are not benchmarks. Training checks formation-court support, side lanes, entrances, instructor dais, shelters, equipment obstruction, standalone props and camera retraction. Pavilion checks 486 visual-mesh stair-headroom volumes, both stairways, ordinary and archive routes, gate collision, remote rejection, no-provider/default denial, authorization, revocation while open, safe closing, denied follow-through, egress after revocation and sensor mask restoration. Cameras are sampled along those tested paths. Input tests send real programmatic Tab/mouse/E/G/Esc events and use existing gallery Walk routes. This is not a human playtest or production controller test.

Important retained limitation: the Training roof collider already contains 84 zero-area triangles among 4,560 entries. They exist in the frozen baseline and remain unchanged; no root-cause collision repair or benefit is claimed for them. Solid collision coverage and motion pass on tested routes. Pavilion has 4,504 roof triangles with no zero-area entries. The approved Hall's earlier repair remains at 2,368 valid triangles; it was not regenerated. Future Training collider work must diagnose the source and prove valid-face/coverage equivalence before editing.

## Matched local rendered benchmarks

Godot 4.7.2, NVIDIA GeForce RTX 3050 Laptop GPU, GL Compatibility, 1280×720, MSAA 4x, uncapped and VSync disabled. Existing per-facility environment/light rigs are identical before/after: ambient .55; sun shadow range 180 m Training and 100 m Pavilion; Pavilion's six original unshadowed lights retained. Both modes use the unchanged inspection cameras. Each view warms 45 frames and measures 240. Separate rendered processes run sequentially, without concurrent import/conversion/audit workloads. First round runs baseline then converted; second round reverses that order. Exact poses, frame samples, draw/primitive/object counters and VRAM values are in the four before/after JSON pairs. Frame times are wall-clock application frame intervals, not isolated GPU timer queries.

'''+table(['Facility','Round','View','Mean ms before → after','P95 ms before → after','FPS before → after','Draw calls before → after','Primitives before → after'],performance)+'''

Training is slower in most views in both rounds despite lower draw/triangle counts; treat this as a measured performance regression requiring profiling before further expansion. Pavilion timings improve in the recorded comparisons. A separate accessor audit (`environment-conversion-stages-2-3/vertex-cost-comparison.json`) finds static near vertex counts increasing from 170,012 to 216,685 for Training and 223,016 to 264,629 for Pavilion after explicit flat shading. This is a candidate cost, not a proven explanation of the timing difference. No consistent cross-facility FPS improvement is claimed. No lighting/shadow setting was changed, and isolated shadow cost was not profiled; total scene timings include it. No representative low-end, sustained thermal, exported executable or populated-world test was performed. Historical Hall and stage-1 Gate measurements remain in their own reports; they are different scenes, not numerical baselines for these facilities.

## Genuine screenshots and review

Training original versus converted (same camera/lighting):

![Training before](environment-conversion-stages-2-3/training-before-overview.png)

![Training after](environment-conversion-stages-2-3/training-after-overview.png)

Pavilion original versus converted:

![Pavilion before](environment-conversion-stages-2-3/pavilion-before-overview.png)

![Pavilion after](environment-conversion-stages-2-3/pavilion-after-overview.png)

Converted Pavilion interior:

![Archive interior](environment-conversion-stages-2-3/pavilion-after-archive.png)

Every benchmark has additional exterior/interior/FPP/TPP images. Rendered regression folders show close equipment, stairs, gate denial/entry and camera boundaries. Current gallery captures show the preserved Hall/Gate and both converted facilities; previous stage-1 captures retain the genuine unconverted state. Visual inspection found the intended palette/flat treatment, intact silhouettes, readable equipment/book bindings and preserved walkable openings in inspected views. No exhaustive pixel-level intersection, every camera orientation or distance-transition examination was performed. Dense roof ribs can alias at distance; they were retained to protect existing silhouettes rather than silently rebuilding roofs.

## Recovery and exact next action

Baseline originals: `baseline/stage23_training/` and `baseline/stage23_pavilion/` plus local baseline scripts/scene adapters. Checkpoint: `checkpoints/before-environment-stages-2-3.zip`. New editable sources: `source/martial_training_ground_low_poly.blend` and `source/scripture_pavilion_low_poly.blend`. Original runtime recovery and all earlier checkpoints remain intact. No original high-detail asset was deleted.

Launch `Review Training Ground.cmd` / `Review Scripture Pavilion.cmd`, or gallery → facility → Walk asset. WASD/mouse, Tab FPP/TPP, Esc gallery; Pavilion E requests archive access, G toggles only the inspection permission provider. Main project still opens the approved Hall by default. Current final audit is `tools/finish_facility_stages.py`, not a historical Hall/gate report writer.

Claude's next action: profile the Training frame-time regression under the same matched conditions before starting another conversion; separate vertex/shader/shadow cost from host timing variation. Preserve the current converted design and rollback before experiments. Manually review these two converted facilities using the launchers and record actual observations separately from automation. Rehearse the Training front/dais/side lanes and Pavilion entrance, east ordinary stair, west archive stair, denied/authorized/revoked/egress flow in both cameras. Investigate the 84 inherited Training roof degenerates in a separate reversible collider stage with valid-face/coverage proof. Do not invent/integrate a town: terrain, paths, vegetation, residences/shops and production-world QA require the real supplied world source first. Do not claim whole-town or low-end completion.
'''
    (R/'reports/LOW_POLY_STAGES_2_3_REPORT.md').write_text(report,encoding='utf-8')
    inventory='''# Low-poly conversion inventory — current after stages 2–3

22 October 2026. All four facilities actually present in this isolated workshop have now been inspected and converted. This is not a completed low-poly town. No populated world, terrain/vegetation/roads, residences/shops or production navigation/player exists here. Do not invent placement or import retired Reedwell assets. Baseline/high-detail copies, source/tooling/evidence/cache are excluded from the runtime environment inventory.

## Major asset categories

'''+table(['Category','Classification','Evidence / dependency'],[
['Main Sect Hall, paired doors and distant form','Already converted / approved','Preserved byte-identical; repaired collider remains 2,368 valid triangles'],
['Sect Gate, gatehouse, terraces and paired leaves','Already converted, stage 1','Preserved byte-identical in stages 2–3; own fortified silhouette'],
['Training shelters, formation court, paving, drains, earth lanes and fences','Already converted, stage 2','Near/LOD visual conversion; protected ground names/layers retained; measured timing regression needs profiling; 84 inherited roof-collider degenerates remain'],
['Arm dummy, striking post, sword/staff rack, stone weight, bench, thrust target','Already converted, stage 2','All seven GLBs; 27 instances use existing MultiMesh/collider transforms'],
['Scripture Pavilion structure, roofs, stairs, three floors and porch','Already converted, stage 3','Near/LOD converted; three-storey movement/headroom regression passed'],
['Scripture shelf, scroll/sealed cabinets, reading table/stool, library lantern','Already converted, stage 3','Six GLBs; repeated furnishings retain JSON transforms and standalone scenes'],
['Archive gate paired leaves','Already converted, stage 3','Both hinge-local GLBs; unchanged permission/egress runtime'],
['Inspection ground/background','Already suitable / preserved','Flat low-cost review fixture; not production terrain'],
['Lighting/shading across facilities','Partially converted / preserved rigs','Palette matches Hall; per-facility light rigs intentionally unchanged; no integrated-world lighting QA'],
['Town scene / neighboring buildings / world transforms','Requires inspection — absent','Only local-origin facility scenes; no invented layout'],
['Terrain/cliffs, paths/roads/bridges, vegetation/scenery, residences/shops','Requires inspection — absent','No relevant runtime scene/library found; reference PNGs are not game assets'],
['Production navigation/NPC/interactions/player','Requires inspection — absent','Only existing isolated inspection controller and local door/permission fixtures'],
])+'\n\n## Every runtime GLB — current measured counts\n\n'+table(['Model','Status','Triangles','Surfaces','Embedded images'],[[str(p.relative_to(R)).replace('\\','/'),'Already converted',f"{(m:=brief(p))['triangles']:,}",m['surfaces'],m['images']] for p in sorted((R/'assets/architecture').rglob('*.glb'))])+'\n\n## Every scene\n\n'+table(['Scene','Status','Direct dependencies'],[[p.relative_to(R).as_posix(),'Converted assets / preserved inspection fixture',', '.join(re.findall(r'path="([^"]+)"',p.read_text(encoding='utf-8')))] for p in sorted((R/'scenes').rglob('*.tscn'))])+'''

## Reuse and compatibility contracts

Training and Pavilion reuse their standalone prop GLBs with MultiMesh transforms derived from the preserved physical JSON. Embedded materials share palette values, not a guaranteed cross-file GPU material object. Training recognizes four exact node names for shadow/LOD behavior; tests verify all four. Pavilion shares `training_collision.gd` and uses the unchanged `archive_access_gate.gd`. Near/distant visibility ranges, floor elevations, entrance/stair widths, colliders, permission checks, local origins and world-independent review scenes are unchanged. Physical JSON still records historical visual statistics; use actual current GLBs or metrics sidecars for budgets.

No existing environment asset in this four-facility runtime remains deliberately in the former textured style. Original textures/high-detail models are preserved for rollback. Missing world categories remain unconverted/unassessed, not silently counted as done. Current evidence, limitations, genuine before/after images and measurements: `LOW_POLY_STAGES_2_3_REPORT.md`; preserved initial audit: `environment-conversion-stage-1/initial-inventory.json`. Review existing facilities, profile the Training performance regression, and resolve inherited Training collider cleanup before new world expansion.
'''
    (R/'reports/LOW_POLY_CONVERSION_INVENTORY.md').write_text(inventory,encoding='utf-8')
    old=(R/'HANDOFF.md').read_text(encoding='utf-8')
    references=old[old.index('## Original visual references'):]
    handoff='''# Claude handoff — Training Ground and Scripture Pavilion converted

22 October 2026. Latest user explicitly authorized continuing with these two facilities. Stages 2–3 are complete and reported; preserve their current result and the approved Hall. No message was sent to Claude.

## Current scope and verified result

Work stays in `prototype/CultivationSect_LowPoly_Test`; original is `prototype/asset-workshop`. The original's 1,599 recorded non-cache hashes match. Approved Hall and converted Gate resources/native sources are unchanged. All previous runtime scripts, scene files, controller/camera systems, physical JSON and project settings match the pre-stage manifest. Within that protected runtime scope, exactly 19 existing GLBs plus catalog status/source metadata changed. New sources, tools, metrics sidecars, reports and launchers are local additions. Full file list/hashes: `reports/environment-conversion-stages-2-3/geometry-preservation-audit.json` and `pre-stage-manifest.json`.

This is a four-facility workshop, not a populated town. Hall, Gate, Training Ground and Scripture Pavilion and all their existing reusable props/leaves are converted. No available facility GLB remains in the previous textured treatment. Absent terrain, paths, vegetation, residences/shops, world layout and production navigation/player are still unassessed. Read `reports/LOW_POLY_CONVERSION_INVENTORY.md` before claiming broader completion.

## Completed work and design

Training: seven equipment types first, then existing near/LOD shelters, court, earth lanes, drains, fences and paving. Pavilion: six furnishing types and paired archive leaves first, then near/LOD structure. Own silhouettes, all floor levels, footprints, feet/hinge origins and collision coverage remain. Limited dissolve removes shallow subdivision; no collapse decimation/rescale. Materials follow Hall opaque texture-free palette, with muted Earth/CourtStone ground extensions. Old custom normals were explicitly cleared and exported flat normals audited. Protected Training paving names/shadows/LOD behavior remain. No lights or controller replacements.

Training near 94,776 → 88,020 triangles, LOD 13,998 → 12,913; Pavilion near 118,720 → 110,960, LOD 30,016 → 22,248. Small prop triangle counts retained; surfaces reduced where roles merge. See current per-family `low_poly_stage_metrics.json`, not historical counts in unchanged physical JSON.

New editable sources: `source/martial_training_ground_low_poly.blend`, `source/scripture_pavilion_low_poly.blend`. Converter: `tools/convert_facility_stages.py`; local read-only baselines: `baseline/stage23_training/`, `baseline/stage23_pavilion/` and baseline script/scene adapters. Recovery checkpoint `checkpoints/before-environment-stages-2-3.zip`; original runtime recovery, original assets/textures and earlier checkpoints retained.

## Executed tests and measurements

'''+table(['Check','Actual result'],summary['verification_rows'])+'''

Training first prop subgroup: 65 functional checks, 7 bound checks passed; Pavilion furnishing/leaf subgroup: 102 functional checks, 8 bound checks passed. Final rendered suites cover the whole converted groups. Automated movement uses the unchanged 1.8 m capsule and actual collision; input checks use programmatic events. No human playtest is implied.

Performance: `reports/LOW_POLY_STAGES_2_3_REPORT.md` contains both rounds, all views, frame time/FPS, draw/primitive counts and before/after screenshots. Raw JSONs/logs are under `reports/environment-conversion-stages-2-3/`. Same existing per-facility light rigs, 1280×720 Compatibility/MSAA4x, no VSync/cap, 45 warmup/240 measured frames. Round 2 reverses before/after order. Training runs slower in most views in both rounds; this is an unresolved performance regression, not a passed optimization gate. Pavilion timings improve. Flat-shaded static vertex counts rise 170,012 → 216,685 (Training), 223,016 → 264,629 (Pavilion); see `vertex-cost-comparison.json`. The cause is not proven; profile before further conversion. No low-end certification or isolated shadow-cost claim.

Independent copy: `reports/environment-conversion-stages-2-3/independent-runtime`, created uncached without import metadata/symlinks or original/baseline dependencies. Actual import, both functional suites and rendered opening/input tests recorded. Tooling engine executable is external software, not a project asset dependency.

## Known issues and unperformed work

Training roof JSON retains 84 inherited zero-area triangles (4,560 total); exact baseline bytes remain. Do not say its collision data is fully cleaned. Pavilion's 4,504 roof entries have no degenerates; Hall's earlier fix remains 2,368 valid entries. Existing tested routes pass. Dense roof rib aliasing at distance remains; no aggressive roof redesign. Pale small coping/nosings and neutral review lighting remain.

NOT TESTED: human keyboard/mouse rehearsal and visual acceptance of these stages; representative low-end hardware; sustained thermal/stutter profiling; exported executable; production player, rank/quest provider or navigation; integrated town composition, seams or lighting; exhaustive camera orientations, visual intersections and LOD transitions. G is inspection-only permission, not a shipped gameplay authorization system.

## Exact next action for Claude

Open `Review Training Ground.cmd` and `Review Scripture Pavilion.cmd` (or gallery → facility → Walk asset). Manually rehearse front/side/dais lanes, both Pavilion stairs, ordinary/archive aisles and denied/authorized/revoked/egress cases in FPP and TPP. Record actual observations separately from automation. Current default launcher still opens the approved Hall. Controls: WASD/mouse, Tab camera, Esc gallery; Pavilion E gate, G inspection permission.

First profile the measured Training performance regression under the documented conditions; preserve this converted source and rollback before shading/batching experiments. Do not expand conversion until performance is understood. Then make a separate reversible investigation of Training's 84 degenerate roof collider entries: identify their generator source, then prove valid-face and collision-coverage equivalence before changes. Do not redesign roofs to solve it. Do not start another construction/conversion stage without actual remaining world sources; no invented town or retired asset imports. Final audit/report tool: `tools/finish_facility_stages.py`; old Hall/gate finalizers are historical and must not overwrite current reporting. Read current stage report and `final-summary.json` first.

'''+references
    (R/'HANDOFF.md').write_text(handoff,encoding='utf-8')
    for name in ['reports/low_poly_test_report.md','reports/VERIFICATION_RESULTS.md','reports/performance_comparison.md','README.md']:
        p=R/name;old=p.read_text(encoding='utf-8')
        marker='<!-- stages-2-3-current -->'
        if marker not in old:
            target='LOW_POLY_STAGES_2_3_REPORT.md' if name.startswith('reports/') else 'reports/LOW_POLY_STAGES_2_3_REPORT.md'
            p.write_text(marker+'\n> Current continuation: Training Ground and Scripture Pavilion and their props/leaves are now converted and verified. [Stages 2–3 report]('+target+') contains actual results, two benchmark rounds, screenshots and limitations. The earlier Hall/stage-1 measurements below are historical, not a whole-town claim. Training retains 84 inherited roof collider degenerates.\n\n'+old,encoding='utf-8')
    p=R/'reports/LOW_POLY_STYLE_GUIDE.md';old=p.read_text(encoding='utf-8')
    old=old.replace('Stage 1 (Sect Gate) is complete and reported separately; stop for review before another group.','Stages 1–3 (Sect Gate, Training Ground, Scripture Pavilion) are complete and reported separately. The latest user instruction authorized the latter two; review their current results before any new group.')
    old=old.replace('Stage-1 Gate mapping and actual geometry/material counts are documented','Stage-1 Gate mapping and actual geometry/material counts are documented')
    if 'CourtStone #81938d' not in old:old+='\nStages 2–3 retain each existing facility silhouette and use palette extensions Earth #806b50 and CourtStone #81938d for broad Training ground fields. Clear imported custom corner normals before glTF export; polygon flat flags alone may retain the previous smooth normals. Verify exported normal vectors, not just Blender flags. Protected paving node names and archive behavior must remain. Current evidence: `LOW_POLY_STAGES_2_3_REPORT.md`.\n'
    p.write_text(old,encoding='utf-8')
    print('Current report, inventory, handoff and historical-report pointers written.')

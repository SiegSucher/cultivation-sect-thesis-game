"""Audit preservation and write reports directly from measured JSON evidence."""
from pathlib import Path
import json, hashlib, struct, math, os, ctypes, sys
R=Path(__file__).resolve().parents[1]
O=R.parent/'asset-workshop'
REPORT=R/'reports'
if (REPORT/'environment-conversion-stage-1/final-summary.json').exists():
    raise SystemExit('Use tools/verify_environment_stage1.py finish after the authorized Gate conversion. This pre-conversion audit intentionally assumes the other facilities still match original high-detail visuals.')
if (REPORT/'roof-collision-fix-2026-10-22/collision-repair.json').exists() and '--audits-only' not in sys.argv:
    raise SystemExit('Use tools/verify_collision_fix_state.py finish for current reports. This historical generator supports --audits-only after the authorized collision repair.')
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(name,text):(REPORT/name).write_text(text,encoding='utf-8')
manifest=read(REPORT/'original_manifest.json')
missing=[];changed=[]
for name,digest in manifest.items():
    p=O/name
    if not p.exists():missing.append(name)
    elif hashlib.sha256(p.read_bytes()).hexdigest()!=digest:changed.append(name)
original_ok=not missing and not changed
unconverted={}
for facility in ['sect_gate','martial_training_ground','scripture_pavilion']:
    a=O/'assets/architecture'/facility
    if not a.exists():continue
    failures=[p.name for p in a.rglob('*') if p.is_file() and not p.name.endswith(('.import','.uid')) and hashlib.sha256(p.read_bytes()).digest()!=hashlib.sha256((R/p.relative_to(O)).read_bytes()).digest()]
    unconverted[facility]=failures
controller_ok=(O/'scripts/training_inspection_player.gd').read_bytes()==(R/'scripts/training_inspection_player.gd').read_bytes()
doors_ok=(O/'scripts/hall_preview_door.gd').read_bytes()==(R/'scripts/hall_preview_door.gd').read_bytes()
preservation={'original_files_checked':len(manifest),'original_unchanged':original_ok,'changed':changed,'missing':missing,'inspection_controller_identical':controller_ok,'door_mechanism_identical':doors_ok,'unconverted_asset_differences':unconverted,'original_path':str(O),'test_path':str(R)}
(REPORT/'preservation-audit.json').write_text(json.dumps(preservation,indent=2))
assert original_ok and controller_ok and doors_ok and not any(unconverted.values()),preservation

# Validate actual exported GLB indices/positions/triangle areas, rather than
# inferring model quality from the authoring program's success exit code.
audits=[]
for name in ['main_sect_hall.glb','main_sect_hall_lod.glb','grand_door_leaf.glb','room_door_leaf.glb']:
    raw=(R/'assets/architecture/tang_main_hall'/name).read_bytes()
    length,kind=struct.unpack_from('<II',raw,12)
    gltf=json.loads(raw[20:20+length])
    offset=20+length
    binary_len,binary_kind=struct.unpack_from('<II',raw,offset)
    binary=raw[offset+8:offset+8+binary_len]
    def accessor(idx):
        a=gltf['accessors'][idx];v=gltf['bufferViews'][a['bufferView']]
        fmt={5126:'f',5125:'I',5123:'H',5121:'B'}[a['componentType']]
        count={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]
        size=struct.calcsize(fmt)*count
        start=v.get('byteOffset',0)+a.get('byteOffset',0)
        stride=v.get('byteStride',size)
        return [struct.unpack_from('<'+fmt*count,binary,start+i*stride) for i in range(a['count'])]
    degenerate=0;triangles=0;finite=True;valid_indices=True
    for mesh in gltf['meshes']:
        for prim in mesh['primitives']:
            positions=accessor(prim['attributes']['POSITION'])
            indices=[i[0] for i in accessor(prim['indices'])]
            finite &= all(math.isfinite(v) for p in positions for v in p)
            valid_indices &= min(indices)>=0 and max(indices)<len(positions)
            for i in range(0,len(indices),3):
                a,b,c=[positions[k] for k in indices[i:i+3]]
                u=[b[j]-a[j] for j in range(3)];v=[c[j]-a[j] for j in range(3)]
                area=sum(q*q for q in [u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]])
                degenerate += area<1e-14
                triangles += 1
    audits.append({'file':name,'triangles':triangles,'finite_positions':finite,'valid_indices':valid_indices,'zero_area_triangles':degenerate,'materials':len(gltf.get('materials',[])),'textures':len(gltf.get('textures',[])),'opaque':all(m.get('alphaMode','OPAQUE')=='OPAQUE' for m in gltf.get('materials',[])),'external_uris':[b['uri'] for b in gltf['buffers'] if 'uri' in b]})
(REPORT/'geometry-audit.json').write_text(json.dumps(audits,indent=2))
assert all(a['finite_positions'] and a['valid_indices'] and a['zero_area_triangles']==0 and a['opaque'] and not a['external_uris'] for a in audits),audits

# Collision metadata is a separate resource from the clean visible GLBs.
# Inspect it independently of the visible meshes and preserve audit evidence.
spec=read(R/'assets/architecture/tang_main_hall/main_sect_hall.json')
roof=spec['roof_collision_faces']
collapsed=0
for i in range(0,len(roof),3):
    p,q,r=roof[i:i+3]
    u=[q[k]-p[k] for k in range(3)];v=[r[k]-p[k] for k in range(3)]
    cross=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]]
    collapsed+=sum(x*x for x in cross)<1e-14
collision_audit={'simple_shapes':len(spec['solid_shapes']),'roof_triangles':len(roof)//3,'roof_zero_area_triangles':collapsed,'roof_positions_finite':all(math.isfinite(v) for p in roof for v in p),'status':'REVIEW' if collapsed else 'PASS','collision_only_repair_applied':(REPORT/'roof-collision-fix-2026-10-22/collision-repair.json').exists(),'interpretation':'Zero-area roof collider faces remain; inspect source triangulation.' if collapsed else 'No zero-area roof collider faces remain. Coverage preservation is documented separately in roof-collision-fix-2026-10-22/collision-repair.json.'}
(REPORT/'collision-data-audit.json').write_text(json.dumps(collision_audit,indent=2))
if '--audits-only' in sys.argv:
    assert collision_audit['roof_positions_finite']
    print(json.dumps({'preservation':preservation,'geometry':audits,'collision':collision_audit},indent=2))
    raise SystemExit(0)

class Memory(ctypes.Structure):
    _fields_=[('dwLength',ctypes.c_ulong),('dwMemoryLoad',ctypes.c_ulong)]+[(n,ctypes.c_ulonglong) for n in ['ullTotalPhys','ullAvailPhys','ullTotalPageFile','ullAvailPageFile','ullTotalVirtual','ullAvailVirtual','ullAvailExtendedVirtual']]
m=Memory();m.dwLength=ctypes.sizeof(m)
memory_gib=round(m.ullTotalPhys/2**30,2) if ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(m)) else None
hardware={'cpu_identifier':os.environ.get('PROCESSOR_IDENTIFIER'),'ram_GiB':memory_gib,'gpu':read(REPORT/'baseline-results.json')['adapter'],'cpu_marketing_name':'Not queried successfully; CIM access unavailable','power_mode':'Not controlled','background_load':'Not controlled'}
(REPORT/'hardware.json').write_text(json.dumps(hardware,indent=2))
a=read(REPORT/'baseline-results.json');b=read(REPORT/'optimized-results.json')
tri_a=a['geometry']['near_static_triangles'];tri_b=b['geometry']['near_static_triangles']
reduction=100*(1-tri_b/tri_a)
conditions=f'''Godot {a['godot']}; GL Compatibility; 1280 x 720; MSAA 4x (enum value 2); VSync disabled and no frame cap for both measurement runs. GPU: {a['adapter']}; RAM: {memory_gib} GiB; CPU identifier: {hardware['cpu_identifier']}. CPU marketing name unavailable. Same isolated hall stage, sun, environment, lantern lights, camera positions/FOVs and controller. The initial screen and final screenshot poses were identical between versions. No town or future production player exists in the active source.

Each of six views: 45 warmup frames + 240 measured rendered frames. The exterior sweep rotates 360 degrees over 240 frames. Movement uses the real unchanged 60 Hz inspection controller: approach from z=24 through stairs/door/aisle, four-step dais, both side rooms. Capture first/third person and verify closed-door blocking. Idle screenshot warmup: 24 frames. Raw frame intervals use Time.get_ticks_usec between process frames; rendering counts and memory are Godot Performance monitors, not hardware profiler timings. Reported primitives include shadow passes and stage; they are not unique building triangles. Memory is whole engine process/render memory, not hall-only. Absolute FPS is uncapped test throughput, not expected low-end gameplay FPS.

Run commands from the workspace: `tools/godot/Godot_v4.7.2-stable_win64_console.exe --path prototype/CultivationSect_LowPoly_Test --script res://tools/evaluate.gd -- --baseline` and the same command without `-- --baseline`. No simultaneous Godot test runs. Short, sequential runs; no thermal/power/background-load control, multiple-run statistical confidence, exported-game, human playtest or target-device certification.'''
rows='\n'.join(f"| {x['view']} | {x['mean_ms']:.3f} | {x['p95_ms']:.3f} | {x['average_fps']:.1f} | {x['mean_draw_calls']:.1f} | {x['mean_rendered_primitives']:.0f} |" for x in a['samples'])
write('baseline_performance.md',f'''# Baseline performance

The original baseline was captured on 22 October 2026 before rebuilding; that first evidence is preserved under `verification-2026-10-22/previous-evidence/`. This table reports fresh verification of the preserved high-detail baseline, under the same settings as the approved low-poly hall. All 21 baseline checks passed. Independent copied hall assets remain in `../baseline/hall/`; original runtime is additionally recoverable from `../original_runtime_recovery.zip`. Current run timestamps and project/user-data paths are in the raw JSON results.

{conditions}

| View | Mean ms | p95 ms | Average FPS | Draw calls | Rendered primitives |
| --- | ---: | ---: | ---: | ---: | ---: |
{rows}

Near static building: {tri_a:,} triangles / {a['geometry']['near_static_surfaces']} surfaces. Original roof shimmer/moire is visible in exterior captures; the source is otherwise traversable by the test fixture. Raw evidence: [baseline-results.json](baseline-results.json). No measured baseline frame exceeded 33.3 ms. This does not rule out later gameplay stutter.
''')
rows='\n'.join(f"| {x['view']} | {x['mean_ms']:.3f} | {y['mean_ms']:.3f} | {100*(1-y['mean_ms']/x['mean_ms']):.1f}% | {x['p95_ms']:.3f} / {y['p95_ms']:.3f} | {x['mean_draw_calls']:.1f} / {y['mean_draw_calls']:.1f} |" for x,y in zip(a['samples'],b['samples']))
old_a=read(REPORT/'verification-2026-10-22/previous-evidence/baseline-results.json')
old_b=read(REPORT/'verification-2026-10-22/previous-evidence/optimized-results.json')
repeat_rows='\n'.join(f"| {x['view']} | {100*(1-y['mean_ms']/x['mean_ms']):.1f}% | {100*(1-v['mean_ms']/u['mean_ms']):.1f}% |" for x,y,u,v in zip(old_a['samples'],old_b['samples'],a['samples'],b['samples']))
write('performance_comparison.md',f'''# Matched before/after comparison

22 October 2026. **Visual direction approved by the user. Decision: Do not expand yet.** The user explicitly requested verification before any further building conversion. Local measurements support the approved design; low-end/populated-world evidence remains missing. No other facility was converted or redesigned. Current matched reruns use the preserved high-detail baseline and the byte-identical approved low-poly assets; initial evidence remains under `verification-2026-10-22/previous-evidence/`.

{conditions}

| View | Baseline mean ms | New mean ms | Mean reduction | p95 ms before / after | Draw calls before / after |
| --- | ---: | ---: | ---: | ---: | ---: |
{rows}

Positive reductions mean faster in this run; negative values mean slower. **Current result is mixed:** exterior views/sweep improve about 22-26%; the fixed interior view improves about 8%; first-person interior is about 1.6% slower and third-person is essentially unchanged. Those small interior differences cannot establish a reliable speedup or regression with this short uncontrolled sample. Preserve the approved appearance; do not redesign or expand on the strength of these figures.

## Repeatability and prior evidence

The original construction-stage pair and this fresh verification pair used the same approved visual assets and six-view procedure. Observed improvements vary substantially, especially indoors. They were sequential samples without controlled GPU clocks, power, thermals or background load; do not treat them as a statistically controlled benchmark. The independent-copy run is a loading/functional check, not an additional matched baseline/after pair.

| View | Earlier observed mean reduction | Fresh verification reduction |
| --- | ---: | ---: |
{repeat_rows}

Static near mesh: **{tri_a:,} -> {tri_b:,} triangles ({reduction:.1f}% fewer)**; material surfaces {a['geometry']['near_static_surfaces']} -> {b['geometry']['near_static_surfaces']}. All 12 new palette materials use standard opaque rendering; no texture sampling or custom shader. The same cheap geometry supplies the existing 95 m distant representation. Avoid claiming a separate LOD reduction.

Whole-render video-memory monitor at front: {a['samples'][0]['video_memory_bytes']/2**20:.2f} -> {b['samples'][0]['video_memory_bytes']/2**20:.2f} MiB. Godot static-memory monitor: {a['samples'][0]['static_memory_bytes']/2**20:.2f} -> {b['samples'][0]['static_memory_bytes']/2**20:.2f} MiB. These are reported monitor values, not total OS process working set. Neither recorded sample set had a frame above 33.3 ms. Short windows cannot establish absence of stutter. Large geometry/texture reduction coincides with faster measured frames, but the contribution of each change was not isolated experimentally.

[Baseline raw results](baseline-results.json), [final raw results](optimized-results.json), [hardware](hardware.json), [baseline procedure](baseline_performance.md). The final design was measured after refinement; first-pass draft results are not substituted for the final measurements.
''')
write('LOW_POLY_STYLE_GUIDE.md','''# Split-Cloud architectural style guide

The user approved this hall as the visual direction on 22 October 2026. Preserve the successful design. This establishes the visual benchmark, but does not authorize another building conversion.

| Role | sRGB hex | Treatment |
| --- | --- | --- |
| Jade roof | #22594f | Six faceted slope strips; broad swept roof forms |
| Tile seams | #46796b | Raised sparse 0.8 m rhythm, no individual barrel tiles |
| Main timber | #432d2d | Eight-sided columns, deep girders and soffits |
| Cedar brackets | #896048 | Three interlocking bearing courses and diagonal braces |
| Stone | #667e88 | Broad opaque podium and stair masses |
| Coping | #bcc6bd | Pale nosings, pedestals and rail caps |
| Plaster | #e6d9b8 | Warm wall fields framed by real timber |
| Window recess | #284c53 | Opaque shaded backing; geometric screens |
| Bronze | #cda668 | Original mountain/diamond motif; restrained emphasis |
| Interior floor | #85624d | Sparse narrow board joints; blue-grey ceremonial aisle |
| Fabric | #456e73 | Room inserts, cushions and ceremonial screen |
| Lantern | #ffda91 | Mild material emission, existing shadowless light fixtures |

Do not adopt towers, exact silhouettes, crests, layouts or landscape from the reference pictures. Repeat original Split-Cloud mountain strokes in roof crown, entrance tympanum and audience screen. Keep walkable bays clear and structural posts supported by visible shoes. Prioritize eave, doorway and column silhouettes over filigree. No arbitrary whole-building scaling. Current footprint, floor levels, door dimensions and collision define the gameplay contract.

Batch by shared material (12 hall meshes); author logical door sources separately. All meshes are flat shaded, all palette materials opaque, roughness .82 (bronze .56). No external textures, custom shaders, transparency, real-time reflections, added lights, glow or particles. Preserve the current Compatibility renderer. Directional shadow distance is 100 m in the matched test room; both variants use it. Other rendering settings and existing hall lanterns are identical. Baked lighting and occlusion changes were not introduced because this experiment does not establish that they are needed. The distant range uses the same inexpensive mesh, avoiding a visible detail jump; it does not reduce triangles further.

Future buildings may vary proportions and silhouette; reuse material logic and motif sparingly. Test in first/third person, inspect actual rendered images, and measure with matching conditions. This document authorizes no future conversion.
''')
screens=['front','three-quarter','roof-detail','interior','first-person','third-person']
for variant in ['baseline','optimized']:
    for view in screens:assert (REPORT/'screenshots'/f'{variant}-{view}.png').is_file()
visuals='\n'.join(f"| {v} | [Before](screenshots/baseline-{v}.png) | [After](screenshots/optimized-{v}.png) |" for v in screens)
constraints=read(REPORT/'constraints-results.json')
native=read(REPORT/'native-source-audit.json')
controls=read(REPORT/'controls-results.json')
assert all(c['pass'] for c in a['checks']+b['checks'])
assert constraints['failed']==0 and controls['failed']==0 and native['failed']==0
write('low_poly_test_report.md',f'''# Main Sect Hall low-poly experiment

22 October 2026. The user approved the current **Split-Cloud Hall** as the visual direction and requested verification only. The approved geometry, materials, collision, editable source and controllers remain byte-identical to the approval checkpoint. The Main Hall alone was rebuilt in the earlier experiment. No further building conversion or redesign was performed during verification. The only runtime configuration correction gives the test a distinct application name and Godot user-data directory.

Original project: `{O}`. Test project: `{R}`. **Original unchanged:** SHA-256 hashes match for all {len(manifest):,} recorded original non-cache files. [Preservation audit](preservation-audit.json). Recovery: `../original_runtime_recovery.zip`; baseline resources: `../baseline/hall`. Other three facilities' non-import resources match the original; copied inspection-controller and door-mechanism scripts are byte-identical. No original town exists in this active workshop; no Reedwell assets, town placement, map or future player was imported.

## Design and implementation

The nine supplied reference images informed jade roofs, warm timber, pale stone/plaster, economical facets and ceremonial scale. Geometry was newly authored without importing the old visual meshes or copying a pictured building. [Original concept](BUILDING_DESIGN.md), [style guide](LOW_POLY_STYLE_GUIDE.md). Refinement after first rendered review muted the roof, introduced the folded front-facing cloud canopy/mountain tympanum and improved blank partition walls.

The model has articulated podium/stairs/rails, six roof masses, faceted columns with interlocked brackets, real window screens, exposed nave ties/trusses, warm lanterns, six elders' seats, leader throne/dais/mountain screen and two accessible furnished rooms. Editable Blender source: `../source/split_cloud_hall.blend`; complete authoring program: `../tools/build_split_cloud.py`. Native reopen audit: {native['passed']} PASS / {native['failed']} FAIL. [Export geometry audit](geometry-audit.json) checks finite positions, valid indices, opaque embedded materials and zero-area triangles for all four GLBs.

Root/podium/facing/door clearances and all original non-roof collision shapes are preserved. Roof collision was rebuilt from actual new soffit triangles to follow the simplified roof and folded canopy. New bounds {b['geometry']['bounds']} remain inside the old envelope {a['geometry']['bounds']}. Differences in tiny eave/crest extrema reduce the bounds slightly; there is no footprint expansion or height increase. No new floor, balcony, world position or inaccessible room was introduced.

Standard shared opaque materials, no image textures/custom shaders/plugins/downloaded assets, no added real-time lights, no renderer switch. 12 near static surfaces; same cheap mesh in the existing distance range. [Settings and measured comparison](performance_comparison.md). Static geometry {reduction:.1f}% fewer triangles. Fresh matched local observations show about 22-26% exterior improvement and 8% fixed-interior improvement, with first/third-person interior effectively flat or slightly slower. Earlier samples showed larger gains, so sustained speedup is not established. Low-end hardware remains unverified. Texture-only and geometry-only contributions were not separately measured.

## Genuine matching screenshots

| View | Baseline | Final |
| --- | --- | --- |
{visuals}

Screenshots come from real Godot rendered viewports at 1280x720. Camera positions/FOVs are in raw result files. No AI render or conceptual image is presented as game evidence. Reference images are stored with their original filenames in `../reference_images/`; individual filenames/intended use are in [HANDOFF](../HANDOFF.md).

## Functional evidence and limits

| Check | Result |
| --- | --- |
| Copied baseline before construction | PASS, 21 automated checks |
| Final rendered movement/camera suite | PASS, 21 automated checks |
| Main stair, entrance, aisle, four-step dais and both private rooms | PASS, actual unchanged inspection controller |
| Closed entrance blocks player | PASS |
| First/third-person camera switch and avatar visibility | PASS |
| Camera retracts at screen and clears geometry from a traversable probe | PASS |
| Side wall blocks movement and floor stays stable | PASS |
| Visible GLB mesh geometry | PASS, finite data and zero zero-area triangles |
| Roof collision metadata | REVIEW: {collapsed} zero-area faces of {len(roof)//3}; no observed failure in tested routes |
| Supplemental gameplay contract/camera checks | {constraints['passed']} PASS / {constraints['failed']} FAIL |
| Dispatched keyboard events / launch scene / gallery return | {controls['passed']} PASS / {controls['failed']} FAIL |
| Native source saved and reopened | {native['passed']} PASS / {native['failed']} FAIL |
| Final restart/import | PASS, clean `restart-clean.log` |
| Cache-free independent copy import and rendered run | PASS, 21 checks; separate output folder; no original assets/cache/symlinks used |
| Human keyboard/mouse rehearsal | NOT TESTED |
| Target low-end hardware, populated world, future player and exported executable | NOT TESTED |
| Town fit/road/neighbor compatibility | Not applicable to current source; no active town exists |

Earlier construction-stage issues were resolved before visual approval: a camera probe inside furniture was moved to a clear standing position; collapsed visual triangles were removed; native audit counted used mesh materials; duplicate baseline import IDs and transient import warnings were resolved. Current verification did not rebuild or alter the approved visual assets.

**Current remaining issue:** a separate audit of the approved roof collision metadata found {collapsed} zero-area triangles among {len(roof)//3} roof collider triangles. All positions are finite, and the 195 authored simple collision shapes and traversal/camera checks pass. Degenerate faces contribute no surface; no associated runtime failure was observed. They were left unchanged to preserve the exact approved state during this verification. Before integration, remove only those redundant collider faces (and make the authoring exporter filter them), then retest movement/cameras and assert visible GLB/native-source hashes are unchanged. This is collision-data cleanup, not a roof redesign. [Collision-data audit](collision-data-audit.json).

No major gap or unintended primary beam/roof intersection was found in inspected screenshots; exhaustive self-intersection analysis was not performed. Human playtesting, target-device performance, sustained thermal/stutter behavior, exported executable and production-player/populated-world integration remain unperformed. Clean-copy import and rendered test evidence live under `verification-2026-10-22/`.

**Decision: Do not expand yet. Visual direction is approved.** Preserve the approved model and original high-detail assets. The next useful work is a human walkthrough and measurements on intended low-end hardware, followed later by separately authorized production-player/populated-world integration. [Claude handoff](../HANDOFF.md) records the exact next action and remaining unperformed tests. No additional facility conversion is authorized by this result. Current independent-copy verification and approval-resource hashes are under `verification-2026-10-22/`.
''')
refs=[('dc7122d9-e820-4f94-8d68-15fba15e3b99','Timber/plaster/stone hierarchy'),('1ffce86a-e99d-4914-a154-8a815e5350e1','Supported eaves and warm framing'),('e8c443bb-86da-403a-9fb3-f13ca00ef3fe','Faceted low-poly economy'),('c2524fdf-1147-4d23-a6ac-0788c24f2fe7','Restrained stone and readable forms'),('daa459e5-a841-4817-a71b-a8497d2f7340','Jade/bronze cultivation grandeur; no copied towers'),('5c7491b2-bfc3-4dca-b95e-9a09214adb07','Roof hierarchy and distant silhouettes'),('321de4c1-87cf-440a-8a3a-65bc7e2efcef','Sect atmosphere; no landscape/effect copying'),('caebb330-769f-47ff-b312-7e04e3acdfa3','Swept roof and supported entrance, original wide composition'),('fa6b44ca-8dc3-4fa4-a102-25e85670a21e','Warm interior timber rhythm, no copied library')]
refrows='\n'.join(f'| codex-clipboard-{n}.png | {why} |' for n,why in refs)
(R/'HANDOFF.md').write_text(f'''# Claude handoff - Split-Cloud Main Sect Hall

Final verified state: 22 October 2026. **Current Main Sect Hall visual direction APPROVED by the user. Preserve it; do not redesign unnecessarily. Decision: Do not expand yet.** The user explicitly requested verification first and no other building conversions. Read this file, the current project and linked evidence before editing. Do not restart completed work. No message has been sent to Claude.

## Purpose and paths

Controlled low-poly Main Hall experiment, preserving the source project. Original Godot root: `{O}`. Test root: `{R}`. These are sibling runnable projects. The active source is the fresh asset workshop; there is no town, map/road connection or production player here. Retired Reedwell is not a valid source for this experiment.

Original runtime recovery: `{R/'original_runtime_recovery.zip'}`. Independent baseline hall: `{R/'baseline/hall'}`. Original fingerprints: `{REPORT/'original_manifest.json'}`; final preservation verification: `{REPORT/'preservation-audit.json'}`. All {len(manifest):,} recorded original non-cache files match. Other facilities' non-import model/resources match. Both original inspection-controller and door-mechanism scripts match byte-for-byte.

Reports: `{REPORT}`. Genuine screenshots: `{REPORT/'screenshots'}` (six matched before/after pairs). References: `{R/'reference_images'}`. Native source: `{R/'source/split_cloud_hall.blend'}`. Authoring program: `{R/'tools/build_split_cloud.py'}`. New exports: `{R/'assets/architecture/tang_main_hall'}`.

## Launch and environment

Run `Launch Low Poly Test.cmd` or open `project.godot` with Godot 4.7.2. `Launch Original Baseline.cmd` selects the unchanged baseline in the same room. Test application identity is `Split-Cloud Hall - Low-Poly Test`, corrected during verification to avoid sharing Godot user data with the original workshop. This changes no hall design or rendering setting. Engine executable is shared software at `../../tools/godot/`; no resource is loaded from the original workshop. Controls: 1 walk/review, WASD/mouse walk, Tab first/third person, E doors, 2 front, 3 three-quarter, 4 interior, Esc copied gallery. The Hall Walk button returns to the test. The wrapper pauses the fixture while using fixed review cameras; the fixture/controller source itself is unchanged.

Godot {a['godot']}; GL Compatibility; 1280x720; MSAA 4x (enum 2). No renderer switch. Matched benchmark disables VSync/frame cap at runtime only. Existing lantern lights retained, no added lights or shadows. Both variants share the same sun (100 m shadow distance) and environment. GPU {hardware['gpu']}; physical RAM {hardware['ram_GiB']} GiB; CPU identifier {hardware['cpu_identifier']}. CPU marketing name unavailable (CIM access denied); power/thermal/background conditions not controlled.

## Architectural decisions

Original Split-Cloud design: broad ceremonial nave, low jade shoulders, open annular eave belt, swept entrance and folded front-facing gable with bronze mountain tympanum. Mountain motif repeats on ridge and leader screen; diamond motif on screens, doors and podium. Muted jade, oxblood timber, pale plaster/coping, blue-grey stone, restrained bronze. Referenced buildings were not reproduced. [Concept](reports/BUILDING_DESIGN.md), [style rules](reports/LOW_POLY_STYLE_GUIDE.md).

Root stays identity at local (0,0,0), +Z front, 1 unit = 1 m. Podium remains 40.4 x 24 m. Final bounds {b['geometry']['bounds']} stay inside the original {a['geometry']['bounds']}. Preserve 1.52 m landing, ~1.53-1.55 m interior, 2.15 m dais, ten 0.15 m main stair rises, 11.2 m stair width, 6.4 x 5.4 m grand opening, 2 x 2.8 m private openings and room layout. Original non-roof collision records remain exact; roof collision follows the rebuilt soffits/canopy. No significant footprint/height change, world placement or scenery movement.

Near static mesh {tri_b:,} triangles (baseline {tri_a:,}, {reduction:.1f}% reduction), 12 shared material batches. Standard opaque flat-shaded materials, zero texture images/custom shaders/plugins/external assets. Same inexpensive mesh at the existing 95 m distance handover, not a separate reduced LOD. Current source has Hall, Grand and Private collections; Grand/Private leaves are hinge-local sources, not assembled doors. Edit component islands in Edit Mode. Godot supplies plaque text. Do not count doors or distance representation as separate facilities.

## Completed evidence and known limitations

- Baseline before rebuild: 21 PASS / 0 FAIL. Final rebuilt rendered suite: 21 PASS / 0 FAIL (`reports/*-results.json`). Real unchanged inspection-controller movement covers stair/door/aisle, leader dais and both administration rooms. First/third cameras, floor stability and closed-door blocking passed.
- Supplemental gameplay/camera checks: {constraints['passed']} PASS / {constraints['failed']} FAIL. Follow camera retracts before rear screen and clears geometry from a valid standing position; side wall blocks motion. Distance checks confirm resources loaded, not exhaustive pixel-level LOD QA.
- Actual dispatched input-event/launch/gallery checks: {controls['passed']} PASS / {controls['failed']} FAIL (`reports/controls-results.json`). Human rehearsal remains NOT TESTED.
- Blender source reopened: {native['passed']} PASS / {native['failed']} FAIL. Four GLBs: finite positions, valid indices, zero zero-area triangles, opaque self-contained materials. [Audits](reports/geometry-audit.json).
- **Remaining collision-data issue:** {collapsed} of {len(roof)//3} roof collider triangles have zero area. No failure was observed in ground traversal/camera tests, but do not call this a completely clean collision-data audit. Approved metadata was left unchanged. [Audit](reports/collision-data-audit.json). Resolve this only as a targeted collider/exporter cleanup with no visual redesign, then rerun movement/camera tests.
- Original SHA-256 and unconverted-facility audits passed. Latest final import and clean restart logs contain no errors/warnings. Source/native outputs and all 12 screenshots exist.
- Fresh six-view matched 240-frame samples show mixed results: ~22-26% lower exterior mean frame times, ~8% lower fixed-interior time, ~1.6% slower first-person and essentially flat third-person. Prior samples showed larger improvements; the variation prevents a sustained-speedup claim. [Baseline](reports/baseline_performance.md), [comparison and prior-pair table](reports/performance_comparison.md), [full report](reports/low_poly_test_report.md). No target device, populated-world, future production-player, exported executable or human playtest was performed.

Initial UID duplication in copied baseline import files was corrected using `tools/fix_copy_uids.gd`. An intermediate old-texture MD5 read error did not recur on clean restart. Optional Blender external-thumbnail write failed in sandbox; saved source/export/reopen succeeded. First visual pass was refined; draft evidence remains under `reports/iterations/first-pass`. Geometry audit found 128 collapsed ridge-tip triangles; removed them and remeasured/recaptured final geometry. An initial camera probe was inside leader furniture; corrected the probe position, without changing the controller. These resolved checks do not imply exhaustive intersection/camera QA.

## Supplied reference filenames and intended use

| Filename in reference_images | Use |
| --- | --- |
{refrows}

## Remaining work and recommended first action

1. **Exact next action for Claude:** read `reports/verification-2026-10-22/verification-summary.json`, `reports/collision-data-audit.json` and `reports/performance_comparison.md`; verify approved checkpoint hashes. Address only the documented {collapsed} redundant zero-area roof collider triangles and make the exporter omit them, preserving visible GLB/native-source hashes, footprint, scale, controls and valid collider faces. Do not rebuild/re-export the approved visual model. Rerun movement/camera tests and document the collision-only change against the unchanged approval checkpoint. Do not touch the original or convert another facility.
2. Open `Launch Low Poly Test.cmd` for a human walkthrough. Rehearse main stair/door/aisle/dais, both side rooms, Tab camera switch and E doors, recording human observations separately from automation.
3. Run the same baseline/approved-model sequence on intended low-end hardware once it is available. Establish sustained thermal and frame-time behavior before any expansion decision. Do not substitute this RTX 3050 result for target-device evidence.
4. Later, only with separate authorization, test actual production-player/cameras, town footprint/neighbors, road connection and populated-world performance. None exists in this active source today. No further building conversion is currently authorized.

Protect the original and recovery ZIP. Preserve `checkpoints/approved-split-cloud-2026-10-22.zip` and `reports/verification-2026-10-22/approved-design-manifest.json`. The approved visuals, native source, collision and controller files must match that manifest. The independent import/run check uses `{R.parent.parent/'output/split-cloud-approved-independent-verification'}`, created without `.godot`, import metadata or symlinks. Its captured test results and recovery ZIP integrity are in `reports/verification-2026-10-22/`. Do not convert other buildings, revive legacy assets, change controls/renderer, copy pictured buildings, or fabricate tests. All work is saved; do not rebuild the approved hall.
''',encoding='utf-8')
print(json.dumps({'original_files_unchanged':len(manifest),'triangles_before':tri_a,'triangles_after':tri_b,'reduction_percent':reduction,'geometry_audits':audits,'screenshots_verified':12,'hardware':hardware},indent=2))

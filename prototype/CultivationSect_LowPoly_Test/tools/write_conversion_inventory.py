"""Write an evidence-backed inventory, including absent world categories."""
from pathlib import Path
import json
R=Path(__file__).resolve().parents[1]
if (R/"reports/environment-conversion-stages-2-3/final-summary.json").exists():
    raise SystemExit("Historical stage-1 writer: use tools/finish_facility_stages.py for current evidence/reporting.")
E=R/'reports/environment-conversion-stage-1'
data=json.loads((E/'initial-inventory.json').read_text())
finished=(E/'final-summary.json').exists()
gate_status='Already converted (stage 1; user visual review pending)' if finished else 'Not yet converted (stage 1 selected)'
model_rows=[]
for m in data['models']:
    family=m['path'].split('/')[2]
    status='Already converted' if family=='tang_main_hall' else (gate_status if family=='sect_gate' else 'Not yet converted')
    model_rows.append(f"| `{m['path']}` | {status} | {m['triangles']:,} | {m['surfaces']} | {m['images']} |")
scene_rows=[]
for s in data['scenes']:
    name=s['path']
    if 'tang_main_hall' in name:state='Already converted'
    elif 'sect_gate' in name:state=gate_status
    elif 'hall_experiment' in name:state='Already converted (hall fixture only)'
    elif 'asset_gallery' in name:state='Partially converted (mixed catalog)'
    elif '/review/' in name:state='Not yet converted (other-facility fixtures)'
    else:state='Not yet converted'
    deps=', '.join('`'+v+'`' for v in s['direct_resources'])
    scene_rows.append(f'| `{name}` | {state} | {deps} |')
if finished:
    scene_rows.append('| `scenes/review/gate_walkthrough.tscn` (added stage 1) | Already converted gate inspection fixture | `res://scripts/gate_walkthrough.gd`; unchanged `sect_gate.gd` and inspection controller |')
text=f'''# Low-poly conversion inventory

22 October 2026. Approved benchmark: Split-Cloud Main Sect Hall. The new user request authorizes controlled conversion stages within this test project, superseding earlier no-other-building instructions for this workstream. It does not authorize editing the original or inventing a town layout. **This project is a four-facility workshop, not an assembled sect/town. Do not report a completed low-poly town.**

Audit source: all {len(data['models'])} runtime GLBs and {len(data['scenes'])} existing scenes plus all runtime scripts. Full per-model materials, nodes and dependencies: [initial-inventory.json](environment-conversion-stage-1/initial-inventory.json). Existence alone did not count as conversion. Baseline/recovery/cache/source/tooling copies are evidence, not additional environment assets.

## Major categories and current status

| Category | Classification | Finding / dependency |
| --- | --- | --- |
| Main Sect Hall architecture, floor, podium, roof and furniture | Already converted | Approved 71,557-triangle static mesh; 12 opaque texture-free materials; do not redesign |
| Hall doors, distant representation and repaired collider | Already converted | Components of Hall, not separate facilities; 2,368 valid roof collider triangles; no known failing automated check |
| Sect Gate/gatehouse, front/rear terraces, lamps and standards | {gate_status} | Broad fortified gateway with two guard-tower shells; retain its own identity, 31 m width, 8.4 m passage and local identity transform |
| Gate paired leaves | {gate_status} | Two hinge-local GLBs; shared gate runtime controls and collider dimensions; convert with gate, not separately |
| Training Ground shelter structures and court | Not yet converted | 94,776 static triangles, old textured palette; includes instructor/rest/weapon shelters and embedded paving/packed-earth categories |
| Training props: arm dummy, post, target, staff/sword racks, weights, bench | Not yet converted | Seven reusable GLBs, repeated using MultiMesh in full facility and standalone prop scenes; some geometry is already economical, retain it where suitable |
| Scripture Pavilion, three floors/stairs and roof | Not yet converted | 118,720 static triangles, previous textured materials; preserve existing three storeys, stairs and archive access |
| Library furniture/lantern props | Not yet converted | Six reusable GLBs, instanced in pavilion and standalone scenes; furniture reuse must stay aligned with collider transforms |
| Restricted Archive gate | Not yet converted | Two distinct leaves; default-deny authorization callback and existing E/G inspection flow must remain |
| Embedded stairs, thresholds, terrace paving and courtyard borders | Partially converted | Hall complete; gate stage 1; Training/Pavilion still old treatment; no global road network |
| Stage ground planes and plain background | Partially converted | Already low-cost flat-color inspection fixtures; not authored production terrain; do not rebuild solely for appearance |
| Lighting/shading | Partially converted | Compatibility/MSAA shared; hall benchmark uses 100 m sun shadows; training inspection uses 180 m and other ambient values; no global lighting conversion performed |
| Residences, shops, mission/exchange halls | Requires inspection | No such runtime scene/model exists in this test project; do not import retired assets or create substitutes |
| Terrain/cliffs/landscape mesh | Requires inspection | Absent; only neutral inspection planes. Integrated-world source/location unavailable |
| Roads/path network/bridges | Requires inspection | Absent; embedded facility paving is not a world road layout |
| Vegetation/trees/grass/rocks/scenery props | Requires inspection | No runtime vegetation/scenery library found; supplied reference PNGs do not count as usable game assets |
| Assembled sect/town world and neighbors | Requires inspection | No world scene or established world transforms; cannot assess whole-town composition, streaming or seams |
| Navigation/NPC route system | Requires inspection | No production navigation mesh/regions, NPC or quest system identified; preserve local authored collision |
| Player/cameras | Already converted / preserved fixture | Existing 1.8 m inspection controller reused unchanged; no production player exists |

## Every existing runtime model (audit-time counts)

These are measurements before stage 1. Final converted-gate counts are reported in the stage report; original counts remain here for rollback comparison. Materials are embedded in each GLB; matching names do not imply GPU-resource sharing across files.

| Model | Current classification | Original triangles | Original surfaces | Original embedded images |
| --- | --- | ---: | ---: | ---: |
{chr(10).join(model_rows)}

## Every existing scene

| Scene | Classification | Direct resources |
| --- | --- | --- |
{chr(10).join(scene_rows)}

Stage-1 additions are listed in the stage report after testing. They are inspection/benchmark fixtures and do not create a new town or move existing facilities.

## Reuse, materials, dependencies and compatibility risks

- `assets/gallery/catalog.json` is the explicit four-facility registry. Existing building roots are local identity transforms; a production town cannot be inferred from gallery placement. All GLBs use embedded resources, with no external URIs found.
- Runtime JSON specifies collision, doors, stairs/floor levels, prop instances and bounds. Runtime scripts build collider bodies and interactions separately from visuals. Preserve these JSONs and scripts byte-for-byte during stage 1; visual simplification must not obstruct or remove walkable geometry.
- Training uses `training_collision.gd` and `training_prop.gd`; full-facility props use MultiMesh. Its script recognizes paving mesh names for shadow settings and sets `lod_bias=128` to prevent broken thin slabs. Do not rename/reduce those batches blindly.
- Pavilion uses the same collision helper, `scripture_prop.gd`, and `archive_access_gate.gd`. Preserve archive authorization/default-deny behavior and the separate `scripture_walkthrough.gd` E/G fixture controls. Retain all three floors, stair clearances and existing material/mesh instance links when later converting.
- Gate uses `sect_gate.gd`, authored roof/structure collider JSON, and hinge-local paired leaves; 90/300 m visibility ranges. No gate mesh-name condition is used by its runtime script. Preserve its distinct roof/tower architecture; use the hall's material treatment rather than duplicating its hall silhouette.
- The gate's physical JSON stays byte-identical, including historical authoring mesh counts. Current post-conversion visual statistics live in `assets/architecture/sect_gate/low_poly_stage1_metrics.json` and the stage report. Its runtime does not use the old statistics; downstream budget tools must use current GLB counts or this sidecar, not the preserved historical counts.
- Hall has independent palette GLBs and `.blend`; protect the whole hall resource set and current repaired collider. Its old textures remain on disk for rollback but are not sampled by converted GLBs. Unused/copied textures must not be deleted as part of this conversion.
- Current meshes with 100-900 triangles (weights, bench, stools, gates) may only need material harmonization. Avoid destructive decimation or needless remodeling. Gate's 40,520-triangle tile-edge batch is the first obvious repetitive-detail cost; simplify only within supported roof profiles, verify resulting silhouette and retained passage surfaces.
- Renderer/back-end, global project settings, original controller and other existing walk scenes remain unchanged. Default archive/training lighting is not evidence of matched global lighting. Real-time lamp/shadow costs are measured per stage and must not be attributed to geometry alone.

## Controlled conversion order and stage boundary

1. Reconfirm Hall repair/preservation and outstanding limits. Existing roof issue is fixed; fresh 18 dimension/camera checks pass. Human, low-end, sustained-performance and production-world tests remain unperformed; none is claimed complete.
2. **Stage 1 now:** Sect Gate static near/distant geometry and its two existing door leaves (four GLBs). Save rollback, measure before, match approved palette with opaque flat surfaces and simplify redundant geometry without moving vertices or changing architecture/collision/control data. Capture gate front/three-quarter/passage/FPP/TPP plus unchanged Hall/Training/Pavilion views.
3. Stage 2 proposal: small shared Training prop group (bench, weight, staff/sword rack), preserving silhouettes and MultiMesh/collider contracts. Review stage 1 first; not converted automatically.
4. Stage 3 proposal: Training shelters and embedded courtyard/paving, then remaining equipment; preserve ground seams/name-dependent shadows.
5. Stage 4 proposal: library shared furniture and lanterns, then Pavilion architecture/floors/stairs/archive gate, with dedicated permission and stair tests.
6. Production terrain, paths, vegetation, residences/shops and whole-town composition require their actual source scene/assets. Inspect those first when supplied/integrated; no invented layout or silent legacy import.

**Stop after the first converted group and report.** Further stages depend on review of visual quality, local performance evidence and any unresolved gameplay issues. Do not claim representative low-end or whole-town results from these isolated fixtures.
'''
(R/'reports/LOW_POLY_CONVERSION_INVENTORY.md').write_text(text,encoding='utf-8')
print('Inventory written for',len(data['models']),'runtime models and',len(data['scenes']),'scenes; stage complete:',finished)

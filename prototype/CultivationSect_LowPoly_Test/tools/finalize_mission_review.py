"""Publish Mission Hall review from executed evidence; never run asset builders."""
from pathlib import Path
import json
import re
import runpy
import zipfile

R = Path(__file__).resolve().parents[1]
E = R / 'reports/codex-mission-hall'
def read(path): return json.loads(path.read_text(encoding='utf-8'))
test_files = {'Claude checks rerun on staged scene': 'staged-basic/verify-results.json',
              'Claude checks rerun on canonical scene': 'integrated-basic/verify-results.json',
              'Independent headless traversal/collision/camera suite': 'independent-routes.json',
              'Independent rendered traversal/collision/camera suite': 'rendered-routes.json',
              'Gallery loading and programmatic key/mouse inputs': 'gallery-input.json',
              'Read-only Blender source reopening': 'native-source.json'}
tests = {label: read(E/name) for label, name in test_files.items()}
assert all(t['failed'] == 0 and t['passed'] > 0 for t in tests.values())
assert all(t['pass'] for t in read(E/'staged-glb-audit.json'))
assert all(t['pass'] for t in read(E/'canonical-glb-audit.json'))
preserve = runpy.run_path(str(R/'tools/mission_integration_state.py'))['verify_preservation']
preserve()
proof = read(E/'preservation.json')
before = read(E/'before-hashes.json')
original_manifest = read(R/'reports/original_manifest.json')
assert all(before['original'].get(p) == h for p,h in original_manifest.items())
staging_before = {p for p in before['test'] if p.startswith('staging/')}
staging_after = {p.relative_to(R).as_posix() for p in (R/'staging').rglob('*') if p.is_file()}
assert staging_before == staging_after, sorted(staging_after ^ staging_before)
screens = sorted(p.relative_to(E).as_posix() for p in E.rglob('*.png'))
assert len(screens) == 29, screens
assert len(list((R/'assets').rglob('*.glb'))) == 32
assert len(list((R/'scenes').rglob('*.tscn'))) == 32
diagnostics = {p.name: [line for line in p.read_text(encoding='utf-8',errors='replace').splitlines()
                       if re.search(r'\b(?:ERROR|WARNING|SCRIPT ERROR):', line)] for p in E.glob('*.log')}
for name, lines in diagnostics.items():
    assert all('root certificate store' in s or 'editor_settings-4.7.tres' in s or 'Error saving editor settings' in s
               for s in lines), (name, lines)
table = '\n'.join('| '+label+' | '+str(t['passed'])+' PASS / 0 FAIL | `codex-mission-hall/'+test_files[label]+'` |'
                  for label,t in tests.items())
with zipfile.ZipFile(E/'before-docs-catalog.zip') as z:
    # ZIP reads preserve CRLF bytes; normalize before Windows text-mode writes
    # so retained historical paragraphs do not acquire doubled CR characters.
    previous_report = z.read('reports/CODEX_REPORT.md').decode('utf-8').replace('\r\n', '\n')
    previous_handoff = z.read('HANDOFF.md').decode('utf-8').replace('\r\n', '\n')
    inventory = z.read('reports/LOW_POLY_CONVERSION_INVENTORY.md').decode('utf-8').replace('\r\n', '\n')
current = '''# Codex report — Mission Hall independent review and integration

22 October 2026. **Mission Hall: created, imported, independently verified on the recorded checks, and integrated as gallery entry nine.** Human visual acceptance and production-world readiness remain pending. This update concerns Mission Hall only. Alchemy/Medicine remain staged and independently unverified; Contribution / Exchange Hall was not started. The previous four-asset report is retained below as historical evidence.

Read the complete current Claude report and handoff, inspected the scene, model, summary, authoring code and review/test scripts. The requested `review/mission_hall_review.ts` does not exist: the actual delivery has `staging/claude_mission_hall/review/mission_hall_review.tscn` and `.gd`. Claude's original report records 25 passing checks and ten screenshots; those are Claude's results, not the independent results below. Its “not integrated” status describes the pre-review delivery and remains frozen for provenance.

## Permanent files and integration

All paths below are relative to `prototype/CultivationSect_LowPoly_Test/`:

- `assets/architecture/mission_hall/mission_hall.glb` and Godot-generated `.glb.import`
- `scenes/buildings/mission_hall.tscn`
- `source/claude_mission_hall_integrated.blend`
- `scripts/mission_hall_review.gd`
- `scenes/review/mission_hall_walkthrough.tscn`
- Existing `assets/gallery/catalog.json` appends Mission Hall with Walk and interior-camera metadata. The gallery script and previous eight entries are unchanged.

Destinations were checked before copying; no conflict existed (`codex-mission-hall/destination-check.json`). GLB and native source are byte-identical to staged originals. The building scene changes only its GLB path, retaining all collision shapes/transforms and plaque. New import metadata has its own UID, distinct from staging. The building depends only on its permanent GLB, whose materials are embedded; it has no textures, lights, scripts or runtime staging/original-project dependency. The review uses the unchanged `scripts/training_inspection_player.gd` and a neutral ground plane. Review fixture changes are resource/output paths, HUD attribution and an output-path comment; no architecture changed.

Launch the project's asset gallery, select **Mission Hall → Walk asset**, or open `scenes/review/mission_hall_walkthrough.tscn` directly. 1 toggles review/walk; WASD/mouse move/look; Tab selects first/third person; Esc returns to the gallery. This is one asset at local identity, not a town placement.

## Actual independent results

| Check | Result | Raw evidence |
| --- | --- | --- |
__TABLE__
| Inspected GLB audit, rerun separately on staged and permanent models | PASS: 17,790 triangles; zero degenerate triangles, non-flat triangles, invalid normals or nonfinite positions | `codex-mission-hall/staged-glb-audit.json`, `canonical-glb-audit.json` |
| Import and render compatibility | Canonical GLB imported; gallery and walkthrough rendered in Godot 4.7.2 | `codex-mission-hall/import.log`, capture/runtime logs; host errors below |
| Preservation and copy provenance | PASS | `codex-mission-hall/preservation.json`, `before-hashes.json` |

Measured imported bounds: **19.060 × 21.32061 m footprint, 9.805352 m high**, minimum y=0; identity root, +Z entrance, metre units. 12 surfaces, 12 opaque palette materials, roughness .82 (bronze .56), no image textures/external URIs. Source reopening confirmed 12 editable material batches, 17,790 triangles, flat polygons and metric units; it was not saved/re-exported.

Independent ray measurements reproduce door width 3.00 m at the wall / 2.84 m between visible open leaves, door height 3.40 m, porch central bay 2.42 m, visible plaque headroom 2.95 m, side passage 2.25 m collision / 2.38 m visible, and aisle height 5.00 m collision / 8.42 m visible. The no-hit ray limits (e.g. 8 m across the uncollidable leaves) mean open space within the probe range, not a measured opening.

The existing 1.8 m, .28 m radius controller ascended/descended the front stair, crossed the forecourt/porch/door/aisle, approached the counter, used both side passages, traversed the officials' area, and approached both mission boards in **both camera modes**. Counter, wall/noticeboard and both forecourt boards block tested movement. Each final independent route run sampled **444 pairs of camera/body volumes**, against authored collision and visible-mesh copies; no sampled intersections. The rendered suite's 56 checks include six screenshot writes; they are not 56 unique gameplay systems. The separate gallery suite loaded all nine entries and exercised 1, W, Tab, mouse look and Esc for Mission Hall. Other assets' complete movement suites were not rerun in this task.

## Failures, corrections and diagnostic limits

The initial independent route run was **42 PASS / 6 FAIL**. Its straight waypoint crossed the returns chest at x=4, z=-2.1; the following two waypoints then failed in each camera mode. The authored chest correctly blocked the controller. The test route was corrected to step back to z=0 before entering the east passage. The initial JSON/log are retained as `initial-route-failures.*`; final reruns passed. No staged or permanent asset geometry/collision/material correction was needed. Claude's two earlier authoring fixes are reported in its own report and were not repeated here.

The engine logs are **not clean**: they report `Failed to read the root certificate store`; the headless editor import also could not save the user's `editor_settings-4.7.tres`. Import completed and runtime suites exited successfully; no asset/parser/missing-resource diagnostic was found. These host access problems were not fixed or investigated further. Blender also emitted a future-API `Material.use_nodes` deprecation notice; its read-only checks passed. The shell's `python` alias was unavailable; the installed Codex runtime Python was used directly.

One new `.gd.uid` for the staged review script was generated by the editor scan; after confirming it was absent from the frozen delivery, it was removed to restore the original staging file set. All **48 pre-existing staging files** now match and there are no additions. Claude's report and evidence are unchanged. All **1,599 original-project files** match both the start-of-task snapshot and the recorded original manifest. Approved Hall, other assets/high-detail sources, existing controllers, gallery code, project settings and default main scene are unchanged. Only catalog, this report, handoff and inventory are permitted pre-existing-file changes. Recovery of those files: `codex-mission-hall/before-docs-catalog.zip`. Builders were never executed.

## Genuine screenshots and remaining work

29 Godot viewport captures were produced: ten staged review images, ten canonical review images, six moving-route images, and three gallery/input images. Selected exterior, board, interior, first/third-person, rear and side views were inspected; no blocking visible hole, missing material or clipping defect was observed in those views. User acceptance is pending; no exhaustive seam/z-fighting guarantee is implied.

![Mission Hall in the nine-asset gallery](codex-mission-hall/gallery-mission-exterior.png)

![Integrated interior preset](codex-mission-hall/gallery-mission-interior.png)

![Third-person officials-area traversal](codex-mission-hall/tpp-officials-east.png)

**Not performed:** human keyboard/mouse playtesting or user acceptance; FPS/frame-time/performance comparison; representative low-end hardware, exported build or sustained-load tests; town/terrain fit, production character, navigation/NPC integration; exhaustive collision/camera/roof-walking checks; OS Open source-button launch. Rendered conditions were Compatibility/OpenGL on RTX 3050 Laptop, 1280×720, project MSAA 4× (gallery viewport 2×), fixed-fps 60 for functional testing; these timings are not benchmarks.

Boards/counter/tablets are static decorative architecture, with no mission/quest interaction or readable task UI. Door leaves are static/open; small details have no separate collision. No LOD/distant mesh. Front stair is the intended access to the .75 m podium; the solid balustrade restricts side approaches. The invisible ceiling clearance slab at y=5.75–5.85 is retained. Existing Training timing regression / 84 inherited roof-collider degenerates remain unrelated, unchanged issues.

**Readiness:** ready for standalone visual review and later placement planning, **not verified ready for final town-layout placement**. Exact next action: gallery → Mission Hall → Walk asset; manually rehearse stair, boards, doorway, counter and side passages in both modes and record observations/user acceptance. Keep final placement deferred until terrain, production traversal/navigation and performance checks are authorized and performed. Do not start Contribution / Exchange Hall or Alchemy Pavilion from this handoff.

Reproduce from the test project with `../../tools/godot/Godot_v4.7.2-stable_win64_console.exe`:

```text
--headless --path . --editor --import --log-file reports/codex-mission-hall/import.log
--headless --fixed-fps 60 --path . --script res://tools/verify_integrated_mission_basics.gd
--headless --fixed-fps 60 --path . --script res://tools/verify_mission_integration.gd
--fixed-fps 60 --path . --script res://tools/verify_mission_integration.gd -- --rendered
--fixed-fps 60 --path . --script res://tools/test_mission_gallery.gd
--path . --resolution 1280x720 res://scenes/review/mission_hall_walkthrough.tscn -- --capture
```

The staged-check rerun uses `tools/verify_mission_basics.gd` (output redirected to Codex evidence). The GLB auditor is `staging/claude_mission_hall/tools/audit_glb.py`; only its output argument is changed. Blender command: `blender.exe --background --factory-startup --python tools/inspect_mission_source.py`. State/provenance: `tools/mission_integration_state.py verify`. `tools/finalize_mission_review.py` validates existing evidence and publishes docs; it does not execute engine tests. Earlier four-asset finalizers assume eight entries and must not overwrite these current docs.

---

## Historical four-asset integration report (previous run; counts below are not the current catalog)

'''.replace('__TABLE__', table)
(R/'reports/CODEX_REPORT.md').write_text(current + previous_report, encoding='utf-8')
handoff = '''# Current handoff — Mission Hall integrated, nine standalone facilities

22 October 2026. User authorized **Mission Hall review/integration only**, inside `prototype/CultivationSect_LowPoly_Test`. It is now created, imported, independently verified for recorded checks and integrated. No world position was assigned. Do not start Contribution / Exchange Hall, Alchemy Pavilion, or final town placement from this task.

## Permanent files and current tests

- `assets/architecture/mission_hall/mission_hall.glb` (+ generated `.import`)
- `scenes/buildings/mission_hall.tscn` (place the scene, not the collision-free bare GLB)
- `source/claude_mission_hall_integrated.blend`
- `scripts/mission_hall_review.gd`
- `scenes/review/mission_hall_walkthrough.tscn`
- `assets/gallery/catalog.json`: ninth entry, Walk route and interior camera; previous eight entries/gallery script unchanged.

GLB/source byte-identical to frozen staging. Scene changes only model resource path; 37 colliders, materials/proportions/floors preserved. Root identity, +Z front, metres; floor .75 m, overall 19.060 W × 21.32061 D × 9.805352 H m. 17,790 triangles, 12 surfaces/materials; no textures.

Codex reran Claude's 25 checks on staging and canonical copies (25/0 each), then independent headless routes 50/0, rendered routes 56/0, gallery/input 26/0, source reopening 5/0 and both GLB audits PASS. Both camera modes and 444 camera/body sample pairs per expanded run pass. Gallery loads all nine assets. Full other-asset movement regressions were not rerun. 29 genuine screenshots: `reports/codex-mission-hall/`. Full methods/failures/limitations: `reports/CODEX_REPORT.md`; raw JSON/logs preserved separately from Claude's evidence.

Initial independent route 42/6 was caused by a waypoint crossing the returns chest; rerouted around it, no asset edit. Original failed-run evidence retained. Host Godot certificate-store error and editor-settings save errors remain; no asset/parser/missing-resource diagnostic found. Blender's source audit emitted a future-API deprecation notice.

Preservation: all 1,599 original-project hashes match both snapshot and recorded baseline; all 48 existing staging files match, with identical final file set. Claude report/evidence, other staging, approved Hall, previous assets/high-detail sources, controllers/settings/default scene unchanged. Only pre-existing catalog/report/handoff/inventory files change. `reports/codex-mission-hall/before-docs-catalog.zip` backs up these files. Never rerun the frozen builder over staging. Evidence/publication tools: `tools/mission_integration_state.py verify`, `tools/finalize_mission_review.py`; earlier finalizers have obsolete eight-entry assumptions.

## Remaining limits and exact next action for Claude

Open gallery → **Mission Hall → Walk asset** (or its canonical walkthrough scene). 1 walk/review, WASD/mouse, Tab first/third person, Esc gallery. Manually rehearse front stair/forecourt, both boards, porch/door, counter, both side passages and officials' area; record observations and obtain user visual acceptance. This manual review is the next action, not town placement or another asset batch.

NOT TESTED: human playtesting/acceptance, FPS/frame-time/performance, low-end hardware, exported build, sustained load, production controller/terrain/navigation/NPC fit, exhaustive collision/camera angles or OS source-button launch. Static open doors and decorative boards/counter have no mission/quest gameplay. No LOD. Front-only stair access to .75 m podium; solid balustrade and invisible ceiling camera slab retained. Town placement remains deferred; asset is ready for standalone review, not certified final placement.

Other work: Alchemy Pavilion and Medicine Hall remain in `staging/claude_buildings_batch2/`, with Claude-reported tests only; not independently tested/integrated here. Contribution / Exchange Hall is not started. Prior eight facilities remain available. Training timing regression and 84 inherited roof-collider degenerates remain unchanged. Do not expand this task to repair or integrate those assets.

Original reference images and previous facility evidence are retained below. Historical eight-entry counts/results below describe the previous batch and are superseded by the current nine-entry state above.

---

'''
history = previous_handoff[previous_handoff.index('# Claude/Codex handoff — eight'):]
(R/'HANDOFF.md').write_text(handoff + history, encoding='utf-8')
inventory = inventory.replace('eight standalone facilities', 'nine standalone facilities')
inventory = inventory.replace("Claude's four delivered facilities are now integrated and tested alongside the four previous facilities. Current runtime: eight catalog entries, 31 GLBs and 30 scenes.",
    "Mission Hall is now independently tested and integrated alongside the previous eight facilities. Current runtime: nine catalog entries, 32 GLBs and 32 scenes. Alchemy/Medicine remain staged (Claude tests only); Contribution / Exchange Hall is not started.")
inventory = inventory.replace('| Planting / courtyard props', '| Mission Hall | Already converted / independently tested / integrated; human review pending | Canonical scene and gallery Walk; 17,790 triangles, 12 materials, 37 colliders; no terrain/performance verification |\n| Alchemy Pavilion / Medicine Hall | Staged only; independently unverified | Claude batch 2 retained untouched; outside this task |\n| Contribution / Exchange Hall | Not started | No asset created in this task |\n| Planting / courtyard props')
inventory = inventory.replace('| assets/architecture/spirit_herb_garden/', '| assets/architecture/mission_hall/mission_hall.glb | Independently tested / integrated; human review pending | 17790 | 12 | 0 |\n| assets/architecture/spirit_herb_garden/')
inventory = inventory.replace('| scenes/buildings/spirit_herb_garden.tscn', '| scenes/buildings/mission_hall.tscn | Independently tested / integrated | res://assets/architecture/mission_hall/mission_hall.glb |\n| scenes/buildings/spirit_herb_garden.tscn')
inventory = inventory.replace('| scenes/review/gate_walkthrough.tscn', '| scenes/review/mission_hall_walkthrough.tscn | Independently tested / integrated | res://scripts/mission_hall_review.gd |\n| scenes/review/gate_walkthrough.tscn')
(R/'reports/LOW_POLY_CONVERSION_INVENTORY.md').write_text(inventory, encoding='utf-8')
preserve()
summary = {'asset': 'mission_hall', 'created': True, 'imported': True, 'independently_tested': True,
           'integrated': True, 'human_playtested': False, 'performance_tested': False, 'final_terrain_placement_verified': False,
           'tests': {k:{'passed': t['passed'], 'failed': t['failed']} for k,t in tests.items()},
           'preservation': read(E/'preservation.json'), 'diagnostics': diagnostics, 'screenshots': screens,
           'next_action': 'Manual Mission Hall visual/traversal review; defer town placement and other assets'}
(E/'final-summary.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
print('Published Mission Hall report/handoff/inventory from executed evidence; 29 screenshots, nine gallery entries.')

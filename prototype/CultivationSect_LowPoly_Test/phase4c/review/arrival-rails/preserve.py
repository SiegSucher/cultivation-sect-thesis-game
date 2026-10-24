"""Snapshot the latest Phase 4C before targeted arrival-rail integration."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import hashlib, json, sys

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent

def manifest():
    return {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in ROOT.rglob('*') if p.is_file()
            and not any(s in {'.godot', '.git', '__pycache__'} for s in p.relative_to(ROOT).parts)
            and OUT not in p.parents}

if '--check' not in sys.argv:
    if (OUT / 'before-hashes.json').exists():
        raise SystemExit('Existing recovery snapshot retained; refusing to overwrite.')
    payload = manifest()
    with ZipFile(OUT / 'phase4c-before-arrival-rails.zip', 'w', ZIP_DEFLATED) as archive:
        for p in (ROOT / 'phase4c').rglob('*'):
            rel = p.relative_to(ROOT / 'phase4c')
            if p.is_file() and rel.parts[0] != 'review':
                archive.write(p, p.relative_to(ROOT).as_posix())
        for name in ['REVIEW.md', 'mountain-profile/REVIEW.md']:
            p = ROOT / 'phase4c/review' / name
            archive.write(p, p.relative_to(ROOT).as_posix())
    (OUT / 'before-hashes.json').write_text(json.dumps(payload, indent=2), encoding='utf-8')
    print('Saved latest Phase 4C sources/resources and', len(payload), 'project hashes.')
else:
    before = json.loads((OUT / 'before-hashes.json').read_text())
    after = manifest()
    modified = [p for p in before if p in after and before[p] != after[p]]
    missing = sorted(set(before)-set(after))
    added = sorted(set(after)-set(before))
    allowed = {'phase4c/import_kit.gd', 'phase4c/safety_assembly.gd',
               'phase4c/resources/safety_assembly.tscn', 'phase4c/README.md',
               'phase4c/review/REVIEW.md'}
    unexpected = [p for p in modified if p not in allowed]
    unexpected += [p for p in added if not p.startswith('phase4c/')]
    adapters = []
    for length in [1, 2]:
        name = f'rail_stair_4in11_{length}m'
        source_path = f'res://staging/claude_environment_safety_kit/railings/{name}.glb'
        model_path = f'res://phase4c/resources/kit/railings/{name}_model.scn'
        source = (ROOT / f'staging/claude_environment_safety_kit/railings/{name}.tscn').read_text()
        adapter = ROOT / f'phase4c/resources/kit/railings/{name}.tscn'
        adapters.append({'module': name, 'only_model_path_changed': adapter.exists() and adapter.read_text() == source.replace(source_path, model_path)})
    with ZipFile(OUT / 'phase4c-before-arrival-rails.zip') as archive:
        original_assembly = archive.read('phase4c/resources/safety_assembly.tscn').decode('utf-8')
    declarations = ''.join(f'[ext_resource type="PackedScene" path="res://phase4c/resources/kit/railings/rail_stair_4in11_{n}m.tscn" id="arrival_exact_{n}m"]\n' for n in [1, 2]) + '\n'
    current_assembly = (ROOT / 'phase4c/resources/safety_assembly.tscn').read_text()
    stripped = current_assembly.replace(declarations, '', 1)
    old_payload_same = stripped.startswith(original_assembly)
    tail = stripped[len(original_assembly):] if old_payload_same else ''
    twelve_new_nodes_only = tail.count('[node ')==12 and all('rail_stair_4in11_' in line for line in tail.splitlines() if line.startswith('[node '))
    result = {'pass': not unexpected and not missing and all(a['only_model_path_changed'] for a in adapters) and old_payload_same and twelve_new_nodes_only,
              'preexisting_files_checked': len(before), 'modified': modified, 'added': added,
              'missing': missing, 'unexpected_changes': unexpected, 'adapters': adapters,
              'existing_support_payload_preserved_verbatim': old_payload_same,
              'only_twelve_arrival_sections_appended': twelve_new_nodes_only}
    (OUT / 'preservation.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(json.dumps(result, indent=2))
    raise SystemExit(0 if result['pass'] else 1)

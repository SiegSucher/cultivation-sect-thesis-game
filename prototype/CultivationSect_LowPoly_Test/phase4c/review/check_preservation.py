"""Compare fresh disk contents against the pre-edit manifest; never restore files."""
from pathlib import Path
import hashlib
import json
import re
from snapshot import ROOT, OUT, manifest

before = json.loads((OUT / 'before-hashes.json').read_text(encoding='utf-8'))
bases = {'test': ROOT, 'original': ROOT.parent / 'asset-workshop',
         'old_map': ROOT.parents[1] / 'assets/maps/prototype'}
results = {}
for label, base in bases.items():
    current = manifest(base)
    saved = before[label]
    results[label] = {
        'checked_original_files': len(saved),
        'modified': [p for p in saved if p in current and saved[p] != current[p]],
        'missing': sorted(set(saved) - set(current)),
        'added': sorted(set(current) - set(saved)),
    }

kit_checks = []
kit_root = ROOT / 'staging/claude_environment_safety_kit'
for adapter in (ROOT / 'phase4c/resources/kit').rglob('*.tscn'):
    relative = adapter.relative_to(ROOT / 'phase4c/resources/kit')
    original = kit_root / relative
    # Import adapters change only the GLB model reference, retaining the staged
    # scene's exact nodes, transforms, collision shapes and material settings.
    def normalize(text):
        return re.sub(r'path="[^"]+\.(?:glb|scn)"', 'path="MODEL_IMPORT"', text)
    same = normalize(original.read_text(encoding='utf-8')) == normalize(adapter.read_text(encoding='utf-8'))
    kit_checks.append({'module': relative.as_posix(), 'only_model_reference_changed': same})

passed = all(not v[key] for v in results.values() for key in ['modified', 'missing', 'added'])
passed = passed and all(x['only_model_reference_changed'] for x in kit_checks)
report = {'pass': passed, 'protected_manifests': results, 'kit_import_adapters': kit_checks}
(OUT / 'preservation-results.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps(report, indent=2))
raise SystemExit(0 if passed else 1)

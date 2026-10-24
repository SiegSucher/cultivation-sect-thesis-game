"""Verify protected files against the pre-assembly snapshot; no project mutation."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'reports' / 'phase4a'
before = json.loads((OUT / 'before-hashes.json').read_text(encoding='utf-8'))
result = {}
for label, base in [('test', ROOT), ('original', ROOT.parent/'asset-workshop'),
                    ('map', ROOT.parents[1]/'assets/maps/prototype')]:
    frozen = before[label]
    if label == 'test':
        frozen = {p: h for p, h in frozen.items()
                  if not p.startswith(('phase4a/', 'reports/phase4a/'))}
    changed = []
    for name, digest in frozen.items():
        path = base / name
        if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != digest:
            changed.append(name)
    result[label] = {'checked': len(frozen), 'changed_or_missing': changed}
    print(label, len(frozen), 'checked;', len(changed), 'changed or missing')
(OUT/'preservation.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
assert not any(row['changed_or_missing'] for row in result.values()), result

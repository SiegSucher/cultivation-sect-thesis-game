"""Read-only comparisons for all protected source files captured before assembly."""
from pathlib import Path
import hashlib
import json

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'reports/mountain-valley'
before=json.loads((OUT/'before-hashes.json').read_text(encoding='utf-8'))
result={}
for label,base in [('test',ROOT),('original',ROOT.parent/'asset-workshop'),('old_map',ROOT.parents[1]/'assets/maps/prototype')]:
    changed=[]
    for name,digest in before[label].items():
        p=base/name
        if not p.is_file() or hashlib.sha256(p.read_bytes()).hexdigest()!=digest: changed.append(name)
    result[label]={'checked':len(before[label]),'changed_or_missing':changed}
    print(label,len(before[label]),'checked;',len(changed),'changed or missing')
(OUT/'preservation.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
assert not any(r['changed_or_missing'] for r in result.values()),result

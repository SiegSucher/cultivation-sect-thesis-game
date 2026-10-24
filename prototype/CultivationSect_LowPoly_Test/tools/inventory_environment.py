"""Inventory every local scene and runtime GLB before selecting a small stage."""
from pathlib import Path
import json,struct,re,collections
R=Path(__file__).resolve().parents[1]
OUT=R/'reports/environment-conversion-stage-1'
OUT.mkdir(exist_ok=True)
models=[]
for p in sorted((R/'assets').rglob('*.glb')):
    raw=p.read_bytes();n=struct.unpack_from('<I',raw,12)[0]
    g=json.loads(raw[20:20+n])
    primitives=[s for m in g.get('meshes',[]) for s in m['primitives']]
    tris=sum((g['accessors'][s['indices']]['count'] if 'indices' in s else g['accessors'][s['attributes']['POSITION']]['count'])//3 for s in primitives)
    models.append({'path':p.relative_to(R).as_posix(),'triangles':tris,'meshes':len(g.get('meshes',[])),'surfaces':len(primitives),'textures':len(g.get('textures',[])),'images':len(g.get('images',[])),'materials':[{'name':m.get('name'),'base':m.get('pbrMetallicRoughness',{}).get('baseColorFactor'),'roughness':m.get('pbrMetallicRoughness',{}).get('roughnessFactor'),'metallic':m.get('pbrMetallicRoughness',{}).get('metallicFactor'),'textured':bool(m.get('pbrMetallicRoughness',{}).get('baseColorTexture'))} for m in g.get('materials',[])],'nodes':[node.get('name','') for node in g.get('nodes',[])],'external_uris':[item['uri'] for group in ['buffers','images'] for item in g.get(group,[]) if 'uri' in item]})
scenes=[]
for p in sorted((R/'scenes').rglob('*.tscn')):
    text=p.read_text(encoding='utf-8')
    scripts=re.findall(r'path="(res://[^"]+)"',text)
    deps=[]
    for script in scripts:
        target=R/script.removeprefix('res://')
        if target.suffix=='.gd':
            deps.extend(re.findall(r'(?:preload|load)\("(res://[^"]+)"\)',target.read_text(encoding='utf-8')))
    scenes.append({'path':p.relative_to(R).as_posix(),'direct_resources':scripts,'script_resource_dependencies':deps,'node_types':dict(collections.Counter(re.findall(r'\[node[^\]]*type="([^"]+)"',text)))})
report={'models':models,'scenes':scenes,'all_scripts':[p.relative_to(R).as_posix() for p in sorted((R/'scripts').glob('*.gd'))],'scope':'Four isolated facilities and prop review scenes, not an assembled town. Baseline/recovery/cache/tooling files are not additional environment content.'}
(OUT/'initial-inventory.json').write_text(json.dumps(report,indent=2))
for m in models:
    print(f"{m['path']}: {m['triangles']} triangles, {m['surfaces']} surfaces, {m['images']} images")
print('Gate mesh nodes:',next(m['nodes'] for m in models if m['path'].endswith('/sect_gate.glb')))

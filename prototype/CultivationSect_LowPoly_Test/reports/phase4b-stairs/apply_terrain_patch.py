"""Replace exactly two scene resource blocks, preserving every other byte.

The previous polish, all instances/transforms, and MultiMesh buffers are left
untouched. Corrected resources are mirrored to the map's existing resource paths.
"""
from pathlib import Path
import hashlib,json,re,shutil

ROOT=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent
scene=ROOT/'mountain_valley/mountain_valley.tscn'
before=json.loads((OUT/'before-hashes.json').read_text())['test']
raw=scene.read_bytes()
assert hashlib.sha256(raw).hexdigest()==before['mountain_valley/mountain_valley.tscn'], 'Scene changed since snapshot'
source=raw.decode('utf-8')

def resource_id(node,property):
    match=re.search(r'\[node name="'+re.escape(node)+r'"[^\]]*\]\n(.*?)(?=\n\[|\Z)',source,re.S)
    assert match,node
    ref=re.search(re.escape(property)+r' = SubResource\("([^"]+)"\)',match[1])
    assert ref,node
    return ref[1]

mesh_id=resource_id('ContinuousValleyTerrain','mesh')
shape_node=re.search(r'\[node name="([^"]+)" type="CollisionShape3D" parent="ValleyGroundCollision"',source)[1]
shape_id=resource_id(shape_node,'shape')
changes=[]
candidate=source
for kind,rid,filename in [('ArrayMesh',mesh_id,'patched-terrain.tres'),('ConcavePolygonShape3D',shape_id,'patched-collision.tres')]:
    pattern=r'(\[sub_resource type="'+kind+r'" id="'+re.escape(rid)+r'"\]\n)(.*?)(?=\n\[|\Z)'
    old=re.search(pattern,candidate,re.S)
    assert old
    saved=(OUT/filename).read_text(encoding='utf-8')
    payload=saved.split('[resource]\n',1)[1].rstrip()+'\n'
    if kind=='ArrayMesh':
        old_mat=re.search(r'"material": (SubResource\("[^"]+"\))',old[2])[1]
        payload,n=re.subn(r'"material": SubResource\("[^"]+"\)',lambda _: '"material": '+old_mat,payload)
        assert n==1
    candidate=candidate[:old.start(2)]+payload+candidate[old.end(2):]
    changes.append({'type':kind,'resource_id':rid})

def protected_text(text):
    for kind,rid in [('ArrayMesh',mesh_id),('ConcavePolygonShape3D',shape_id)]:
        text=re.sub(r'(\[sub_resource type="'+kind+r'" id="'+re.escape(rid)+r'"\]\n).*?(?=\n\[|\Z)',r'\1<FOCUSED TERRAIN PAYLOAD>\n',text,flags=re.S)
    return text
assert protected_text(source)==protected_text(candidate),'Unrelated scene content changed'
scene.write_bytes(candidate.encode('utf-8'))
for name in ['terrain_mesh.res','terrain_collision.res']:
    shutil.copyfile(OUT/name,ROOT/'mountain_valley/resources'/name)
result={'scene_resource_blocks_replaced':changes,'all_other_scene_bytes_identical':True,
        'layout_unchanged':hashlib.sha256((ROOT/'mountain_valley/layout.json').read_bytes()).hexdigest()==before['mountain_valley/layout.json']}
(OUT/'apply-result.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps(result))

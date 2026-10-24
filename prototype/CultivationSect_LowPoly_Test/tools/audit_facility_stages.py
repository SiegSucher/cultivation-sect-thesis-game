"""Current stage manifest/GLB/collider audit. No original-project writes."""
from pathlib import Path
import json,struct,math,hashlib,sys,zipfile
R=Path(__file__).resolve().parents[1]
E=R/'reports/environment-conversion-stages-2-3'
FAMILIES={'training':'martial_training_ground','pavilion':'scripture_pavilion'}
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def area2(a,b,c):
    u=[b[i]-a[i] for i in range(3)];v=[c[i]-a[i] for i in range(3)]
    return sum(x*x for x in [u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]])
def glb(path):
    raw=path.read_bytes();length=struct.unpack_from('<I',raw,12)[0]
    data=json.loads(raw[20:20+length]);blob=raw[28+length:]
    def access(index):
        a=data['accessors'][index];v=data['bufferViews'][a['bufferView']]
        fmt={5126:'f',5125:'I',5123:'H',5121:'B'}[a['componentType']]
        n={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]
        size=struct.calcsize(fmt)*n;stride=v.get('byteStride',size)
        start=v.get('byteOffset',0)+a.get('byteOffset',0)
        return [struct.unpack_from('<'+fmt*n,blob,start+i*stride) for i in range(a['count'])]
    tris=zero=badnorm=nonflat=0
    for mesh in data['meshes']:
        for p in mesh['primitives']:
            positions=access(p['attributes']['POSITION']);normals=access(p['attributes']['NORMAL'])
            assert all(math.isfinite(x) for point in positions for x in point)
            badnorm+=sum(not all(math.isfinite(x) for x in n) or not .99<sum(x*x for x in n)<1.01 for n in normals)
            indices=[i[0] for i in access(p['indices'])]
            assert min(indices)>=0 and max(indices)<len(positions)
            for i in range(0,len(indices),3):
                ix=indices[i:i+3];tris+=1
                zero+=area2(*[positions[j] for j in ix])<1e-14
                nonflat+=any(sum((normals[ix[0]][k]-normals[j][k])**2 for k in range(3))>1e-8 for j in ix[1:])
    return {'file':path.name,'triangles':tris,'surfaces':sum(len(m['primitives']) for m in data['meshes']),'images':len(data.get('images',[])),'textures':len(data.get('textures',[])),'bytes':len(raw),'zero_area_triangles':zero,'invalid_normals':badnorm,'nonflat_triangles':nonflat,'all_opaque':all(m.get('alphaMode','OPAQUE')=='OPAQUE' for m in data['materials']),'external_uris':[b['uri'] for b in data.get('buffers',[]) if 'uri' in b],'nodes':[n.get('name','') for n in data['nodes']]}
def audit(shorts):
    manifest=read(E/'pre-stage-manifest.json')
    allowed={'assets/gallery/catalog.json'}|{f'assets/architecture/{FAMILIES[s]}/{p.name}' for s in shorts for p in (R/'baseline'/('stage23_'+s)).glob('*.glb')}
    changed=[name for name,d in manifest.items() if not (R/name).is_file() or sha(R/name)!=d]
    assert set(changed)<=allowed,changed
    original=read(R/'reports/original_manifest.json')
    differences=[name for name,d in original.items() if not (R.parent/'asset-workshop'/name).is_file() or sha(R.parent/'asset-workshop'/name)!=d]
    assert not differences,differences
    assert sha(R/'original_runtime_recovery.zip')==read(R/'reports/verification-2026-10-22/recovery-integrity.json')['archive_sha256']
    geometry={};colliders={}
    for short in shorts:
        family=FAMILIES[short];base=R/'baseline'/('stage23_'+short)
        assert sha(R/'assets/architecture'/family/(family+'.json'))==sha(base/(family+'.json'))
        models=[]
        for p in sorted(base.glob('*.glb')):
            assert sha(p)==manifest[f'assets/architecture/{family}/{p.name}']
            before=glb(p);after=glb(R/'assets/architecture'/family/p.name)
            assert after['zero_area_triangles']==after['invalid_normals']==after['nonflat_triangles']==after['images']==after['textures']==0,(short,after)
            assert after['all_opaque'] and not after['external_uris']
            models.append({'before':before,'after':after})
        geometry[short]=models
        d=read(base/(family+'.json'));faces=d['roof_collision_faces']
        colliders[short]={'specification_byte_identical':True,'static_solid_shapes':len(d['solid_shapes']),'roof_triangles':len(faces)//3,'inherited_zero_area_roof_triangles':sum(area2(*faces[i:i+3])<1e-14 for i in range(0,len(faces),3)),'prop_instances':len(d['prop_instances']),'prop_kinds':len(d['prop_definitions'])}
    hall=read(R/'assets/architecture/tang_main_hall/main_sect_hall.json')['roof_collision_faces']
    assert len(hall)//3==2368 and all(area2(*hall[i:i+3])>0 for i in range(0,len(hall),3))
    with zipfile.ZipFile(R/'checkpoints/before-environment-stages-2-3.zip') as z:assert z.testzip() is None
    result={'original_files_verified':len(original),'original_changed':differences,'protected_preexisting_files':len(manifest),'changed_files':changed,'approved_hall_and_gate_unchanged':True,'all_preexisting_runtime_scripts_scenes_controller_settings_unchanged':True,'hall_roof_valid_triangles':2368,'rollback_and_original_recovery_intact':True,'geometry':geometry,'colliders':colliders}
    (E/('training-audit.json' if len(shorts)==1 else 'geometry-preservation-audit.json')).write_text(json.dumps(result,indent=2))
    print('Verified',len(original),'original hashes;',len(changed),'authorized existing file changes; converted meshes healthy.')
    return result
if __name__=='__main__':audit(['training'] if '--training' in sys.argv else list(FAMILIES))

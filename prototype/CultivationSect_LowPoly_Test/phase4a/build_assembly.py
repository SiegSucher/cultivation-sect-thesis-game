"""Create the additive, editor-inspectable Hall assembly; never rebuild its assets."""
from pathlib import Path
import hashlib
import json
import math
import random

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'reports' / 'phase4a'
OUT.mkdir(parents=True, exist_ok=True)

def manifest(base):
    return {p.relative_to(base).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in base.rglob('*') if p.is_file()
            and not any(x in {'.godot', '.git', '__pycache__'} for x in p.relative_to(base).parts)}

before = OUT / 'before-hashes.json'
if not before.exists():
    before.write_text(json.dumps({
        'test': manifest(ROOT),
        'original': manifest(ROOT.parent / 'asset-workshop'),
        'map': manifest(ROOT.parents[1] / 'assets' / 'maps' / 'prototype'),
    }, indent=2), encoding='utf-8')

IDS = ['pine_windswept', 'pine_tiered', 'bamboo_cluster', 'flowering_shrub',
       'grass_tuft', 'rock_cluster', 'rock_outcrop', 'stone_lantern',
       'sect_banner', 'training_dummy_rack', 'stone_bench']
lines = ['[gd_scene load_steps=14 format=3]', '',
         '[ext_resource type="Script" path="res://phase4a/main_sect_hall_environment.gd" id="1"]',
         '[ext_resource type="PackedScene" path="res://scenes/buildings/tang_main_hall.tscn" id="2"]']
for i, aid in enumerate(IDS, 3):
    lines.append(f'[ext_resource type="PackedScene" path="res://staging/claude_environment_batch1/{aid}/{aid}.tscn" id="{i}"]')
lines += ['', '[node name="Phase4A_MainSectHall" type="Node3D"]', 'script = ExtResource("1")',
          '', '[node name="MainSectHall" parent="." instance=ExtResource("2")]',
          '', '[node name="EnvironmentAssembly" type="Node3D" parent="."]']
counts = {aid: 0 for aid in IDS}
placements = []

def place(aid, x, z, yaw=0, scale=1):
    counts[aid] += 1
    name = f'{aid}_{counts[aid]:03d}'
    lines.extend(['', f'[node name="{name}" parent="EnvironmentAssembly" instance=ExtResource("{IDS.index(aid)+3}")]',
                  f'position = Vector3({x:.4f}, 0, {z:.4f})',
                  f'rotation = Vector3(0, {math.radians(yaw):.5f}, 0)',
                  f'scale = Vector3({scale:.4f}, {scale:.4f}, {scale:.4f})'])
    placements.append(dict(asset=aid, x=x, z=z, yaw=yaw, scale=scale))

# Deliberate asymmetric masses outside the roof envelope and the walking court.
for aid, x, z, yaw, size in [
    ('pine_windswept',-25,17,215,1.1), ('pine_tiered',-28,8,30,1.13),
    ('pine_tiered',-27,-6,115,1), ('pine_windswept',-23,-18,145,.95),
    ('pine_tiered',-14,-23,35,1.12), ('pine_tiered',-4,-25,120,1.05),
    ('pine_windswept',8,-24,270,1.12), ('pine_tiered',18,-22,65,1.1),
    ('pine_tiered',28,-13,25,1.08), ('pine_windswept',28,2,320,1.06),
    ('pine_tiered',30,13,10,1), ('pine_windswept',-24,34,195,.96),
    ('pine_tiered',-31,30,85,1.05), ('pine_tiered',29,35,255,1.12),
    ('pine_windswept',20,46,300,1), ('pine_tiered',-18,52,30,1.12),
    ('pine_windswept',-27,58,180,1.1), ('pine_tiered',31,52,65,1.15),
    ('pine_tiered',-37,-19,12,1.1), ('pine_tiered',37,-16,200,1.15),
    ('pine_tiered',-38,43,35,1.1), ('pine_tiered',39,26,40,1.1),
]: place(aid,x,z,yaw,size)

rng = random.Random(41023)
# Bamboo comes in unequal groves, leaving gaps around both sides of the Hall.
for cx, cz, n in [(-28,-17,5),(28,-20,5),(-30,25,4),(29,25,4),(22,51,3)]:
    for i in range(n):
        a = i*2.4
        place('bamboo_cluster',cx+math.cos(a)*rng.uniform(.8,3.1),cz+math.sin(a)*rng.uniform(1,3.5),rng.uniform(0,360),rng.uniform(.86,1.13))

for aid,x,z,yaw,size in [
    ('rock_outcrop',-29,19,35,1.05), ('rock_outcrop',27,-7,210,1.12),
    ('rock_outcrop',-20,-24,110,.9), ('rock_outcrop',25,43,265,.88),
    ('rock_cluster',-21,30,15,1.03), ('rock_cluster',-24,23,160,.9),
    ('rock_cluster',23,34,230,.95), ('rock_cluster',-12,47,125,.86),
    ('rock_cluster',14,53,45,1.08), ('rock_cluster',30,6,50,1.12),
    ('rock_cluster',-27,-3,270,1.05), ('rock_cluster',18,-23,10,1.1),
]: place(aid,x,z,yaw,size)

# Formal accents only at thresholds; other furnishings follow pocket uses.
for x,z,yaw in [(-7.7,19.5,0),(7.7,19.5,0),(-5.6,42,12),(5.6,43,-8),(-5.5,59,0),(5.5,59,0),(-19,30,20),(20.8,32,0)]:
    place('stone_lantern',x,z,yaw)
place('sect_banner',-9.5,23.2,0)
place('sect_banner',9.5,23.2,180)
place('stone_bench',-17.8,27.5,90)
place('stone_bench',-17.8,32.3,90)
place('stone_bench',18,35.4,-90)
place('training_dummy_rack',14.5,25.0,-10)
place('training_dummy_rack',18.2,26.3,-24)

# Patch-based scatter has varied density and keeps the full paved apron clear.
patches = [(-24,18,4,4),(-24,30,4,5),(-14,45,5,4),(-13,56,5,5),
           (14,53,5,5),(25,44,5,5),(26,29,3,7),(28,11,4,5),
           (-28,0,3,7),(-22,-20,6,4),(20,-22,7,3)]
for cx,cz,rx,rz in patches:
    for i in range(3):
        place('flowering_shrub',cx+rng.uniform(-rx*.6,rx*.6),cz+rng.uniform(-rz*.6,rz*.6),rng.uniform(0,360),rng.uniform(.85,1.12))
    for i in range(rng.randrange(15,25)):
        x,z=cx+rng.uniform(-rx,rx),cz+rng.uniform(-rz,rz)
        if 18 <= z <= 39 and abs(x)<21: continue
        place('grass_tuft',x,z,rng.uniform(0,360),rng.uniform(.85,1.15))

(ROOT/'phase4a/main_sect_hall_environment.tscn').write_text('\n'.join(lines)+'\n',encoding='utf-8')
(OUT/'placements.json').write_text(json.dumps({'counts':counts,'total':sum(counts.values()),'placements':placements},indent=2),encoding='utf-8')
print(json.dumps(counts), 'total:',sum(counts.values()))

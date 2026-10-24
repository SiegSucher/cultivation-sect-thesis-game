"""Create an uncached second runtime entirely inside ignored test evidence."""
from pathlib import Path
import shutil,json
R=Path(__file__).resolve().parents[1]
E=R/'reports/environment-conversion-stages-2-3'
C=E/'independent-runtime'
assert not C.exists(), 'Do not overwrite independent evidence'
C.mkdir()
for folder in ['assets','scripts','scenes','addons','source']:
    shutil.copytree(R/folder,C/folder,ignore=shutil.ignore_patterns('*.import','*.uid','*.blend1','__pycache__'))
shutil.copy2(R/'project.godot',C/'project.godot')
(C/'tools').mkdir()
for name in ['verify_training_stage2.gd','verify_pavilion_stage3.gd','test_facility_stage_controls.gd']:
    shutil.copy2(R/'tools'/name,C/'tools'/name)
(C/'reports/environment-conversion-stages-2-3').mkdir(parents=True)
(C/'reports/.gdignore').write_text('')
assert not (C/'.godot').exists() and not any(p.is_symlink() for p in C.rglob('*'))
(E/'independent-preparation.json').write_text(json.dumps({'path':str(C),'no_cache_at_creation':True,'no_import_metadata_or_symlinks':True,'no_baseline_or_original_project_resources_copied':True,'project_settings_identical':True,'runtime_assets_scripts_scenes_and_optional_editor_addon_copied':True},indent=2))
print('Uncached independent runtime prepared:',C)

const fs=require('fs'),path=require('path');
const project=path.resolve(__dirname,'../..');
const workspace=path.resolve(project,'../..');
const archive=path.join(workspace,'prototype/_proposal_archive/2026-10-25-living-sect-cleanup');
fs.mkdirSync(archive,{recursive:true});
fs.writeFileSync(path.join(archive,'.gdignore'),'');
const directories=['checkpoints','export_templates','feature_profiles','mountain_valley','phase4a','proposal_demo','proposal_demo_creative','proposal_demo_sectlife','reference_images','reports','script_templates','text_editor_themes'];
const projectFiles=['HANDOFF.md','original_runtime_recovery.zip','Launch Low Poly Test.cmd','Launch Original Baseline.cmd','Review Claude Assets.cmd','Review Scripture Pavilion.cmd','Review Stage 1 Sect Gate.cmd','Review Training Ground.cmd','phase4c/Launch Phase 4C.cmd','phase4d/Launch Phase 4D.cmd','mountain_valley_compact/Launch Compact Valley.cmd'];
const workspaceFiles=['View Mountain Valley Blockout.cmd','View Phase 4A Main Sect Hall.cmd'];
const preservedBefore=['project.godot','README.md','proposal_demo_living_sect/README.md','proposal_demo_living_sect/review/REVIEW.md','proposal_demo_living_sect/review/capture_views.gd','proposal_demo_living_sect/review/finalize.cjs','proposal_demo_living_sect/review/write_report.cjs'];
const keep=['.godot','addons','assets','baseline','mountain_valley_compact','phase4c','phase4d','proposal_demo_living_sect','scenes','scripts','source','staging','tools'];
const walk=dir=>fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(path.join(dir,e.name)):[path.join(dir,e.name)]);
const roots=[...directories,...projectFiles].map(relative=>({root:'project',relative})).concat(workspaceFiles.map(relative=>({root:'workspace',relative})));
const files=[];
for(const item of roots){
 const root=item.root==='project'?project:workspace;
 const target=path.resolve(root,item.relative);
 if(!target.startsWith(root+path.sep)||!fs.existsSync(target))throw Error('Unsafe/missing target '+target);
 for(const p of fs.statSync(target).isDirectory()?walk(target):[target])files.push({action:'DELETE_AFTER_BACKUP',absolute:p,entry:item.root+'/'+path.relative(root,p).replaceAll('\\','/'),bytes:fs.statSync(p).size});
}
for(const relative of preservedBefore){const p=path.join(project,relative);files.push({action:'BACKUP_BEFORE_EDIT',absolute:p,entry:'project/'+relative,bytes:fs.statSync(p).size});}
const audit=JSON.parse(fs.readFileSync(path.join(__dirname,'cleanup-audit.json'),'utf8'));
for(const relative of audit.literal_dependency_files)if(files.some(f=>f.action==='DELETE_AFTER_BACKUP'&&f.absolute===path.join(project,relative)))throw Error('Deletion intersects dependency '+relative);
const manifest={project,workspace,archive,keep,delete_roots:roots,files,authorization:'User explicitly selected Living Sect for the proposal and requested deletion of unrelated files/folders. Cleanup is limited to this project and its two obsolete workspace launchers.',notes:['Shared gallery/baseline code is kept conservatively because the inherited controller contains a gallery fallback.','Source Blender files and asset-maintenance tools are kept as related authoring resources.','reports/ is old review output, not a resource loaded by the Living Sect runtime.'],total_backup_bytes:files.reduce((n,f)=>n+f.bytes,0)};
fs.writeFileSync(path.join(archive,'cleanup-manifest.json'),JSON.stringify(manifest,null,2));
const plan='# Living Sect cleanup — KEEP / DELETE\n\nSelected proposal version: proposal_demo_living_sect.\n\n## KEEP\n\n'+keep.map(p=>'- '+p+'/ — active demo, shared runtime/editor dependency, or related authoring support.').join('\n')+'\n- project.godot and README.md — update to the selected proposal.\n- Other workspace projects, thesis documents and the shared engine installation.\n\n## DELETE FROM THE ACTIVE WORKSPACE AFTER VERIFIED BACKUP\n\n'+roots.map(p=>'- '+p.root+': '+p.relative).join('\n')+'\n\nAll removed files are stored in retired-files.zip beside this plan. The manifest lists exact source paths and archive entries. The two workspace launchers belong specifically to the retired terrain demos; other workspace launchers are outside cleanup.\n';
fs.writeFileSync(path.join(archive,'KEEP-DELETE.md'),plan);
console.log(JSON.stringify({archive,deleteRoots:roots.length,files:files.length,backupGiB:manifest.total_backup_bytes/1073741824,kept:keep},null,2));

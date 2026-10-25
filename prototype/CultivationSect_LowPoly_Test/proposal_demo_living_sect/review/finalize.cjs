const fs=require('fs'),path=require('path'),crypto=require('crypto');
const project=path.resolve(__dirname,'../..');
const edition=path.resolve(__dirname,'..');
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const baseline=JSON.parse(fs.readFileSync(path.join(__dirname,'baseline-hashes.json'),'utf8'));
const changed=[],missing=[];
for(const [relative,expected] of Object.entries(baseline)) {
 const file=path.join(project,relative);
 if(!fs.existsSync(file)) missing.push(relative);
 else if(hash(file)!==expected) changed.push(relative);
}
const walk=dir=>fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.name==='.godot'?[]:e.isDirectory()?walk(path.join(dir,e.name)):[path.join(dir,e.name)]);
const addedOutside=walk(project).filter(p=>!p.startsWith(edition+path.sep)).map(p=>path.relative(project,p).replaceAll('\\','/')).filter(p=>!Object.hasOwn(baseline,p));
const educational={};
for(const name of ['code_runner.gd','lessons.gd','terminal_window.gd']) {
 const before=fs.readFileSync(path.join(project,'proposal_demo_sectlife',name),'utf8');
 const after=fs.readFileSync(path.join(edition,name),'utf8').replaceAll('proposal_demo_living_sect','proposal_demo_sectlife');
 educational[name]=before===after;
}
const preservation={checked_at:new Date().toISOString(),protected_files:Object.keys(baseline).length,changed,missing,added_outside_edition:addedOutside,educational_sources_unchanged_after_local_path_normalization:educational};
fs.writeFileSync(path.join(__dirname,'preservation.json'),JSON.stringify(preservation,null,2));
const suites=['Runner','Quest','Life720','Life1080','Layout720','Layout1080','Routes','LivingRendered','Extras'];
let total=0,failed=0;
const results=suites.map(name=>{const r=JSON.parse(fs.readFileSync(path.join(__dirname,name+'.json'),'utf8'));total+=r.checks;failed+=r.failures;return {suite:name,checks:r.checks,failures:r.failures,resolution:r.resolution||null};});
fs.writeFileSync(path.join(__dirname,'verification-summary.json'),JSON.stringify({generated_at:new Date().toISOString(),total_assertions:total,failed_assertions:failed,suites:results},null,2));
const sourceHashes={};
for(const p of walk(edition)) if(/\.(gd|tscn|cmd|ps1|cjs|md|html)$/.test(p))sourceHashes[path.relative(edition,p).replaceAll('\\','/')]=hash(p);
fs.writeFileSync(path.join(__dirname,'source-manifest.json'),JSON.stringify(sourceHashes,null,2));
console.log(JSON.stringify({protected:Object.keys(baseline).length,changed:changed.length,missing:missing.length,addedOutside:addedOutside.length,educational,total,failed},null,2));
if(changed.length||missing.length||addedOutside.length||failed||Object.values(educational).includes(false))process.exitCode=1;

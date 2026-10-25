const fs=require('fs'),path=require('path');
const project=path.resolve(__dirname,'../..');
const edition='proposal_demo_living_sect';
function walk(dir){return fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(path.join(dir,e.name)):[path.join(dir,e.name)]);}
const roots=new Map(),seen=new Set(),queue=[edition+'/proposal_demo.tscn','addons/godot_ai/runtime/game_helper.gd'];
const unresolved=[];
while(queue.length){
 const rel=queue.shift();if(seen.has(rel))continue;seen.add(rel);
 const file=path.resolve(project,rel);
 if(!file.startsWith(project+path.sep)||!fs.existsSync(file)){unresolved.push(rel);continue;}
 if(fs.statSync(file).isDirectory())continue;
 roots.set(rel.split('/')[0],true);
 const content=fs.readFileSync(file).toString('latin1');
 for(const match of content.matchAll(/res:\/\/([A-Za-z0-9_./ -]+)/g)){
  const dep=match[1].trim();
  if(dep.startsWith('.godot/'))continue;
  if(!fs.existsSync(path.join(project,dep))){unresolved.push({from:rel,path:dep});continue;}
  roots.set(dep.split('/')[0],true);
  if(!fs.statSync(path.join(project,dep)).isDirectory())queue.push(dep);
 }
}
const inventory=fs.readdirSync(project,{withFileTypes:true}).map(e=>{
 const files=e.isDirectory()?walk(path.join(project,e.name)):[path.join(project,e.name)];
 return {name:e.name,directory:e.isDirectory(),files:files.length,bytes:files.reduce((n,p)=>n+fs.statSync(p).size,0),runtime_root:roots.has(e.name)};
});
const audit={project,scope:'This Godot project only; sibling thesis projects and workspace-level sources are outside cleanup.',runtime_roots:[...roots.keys()].sort(),literal_dependency_files:[...seen].sort(),unresolved,inventory};
fs.writeFileSync(path.join(__dirname,'cleanup-audit.json'),JSON.stringify(audit,null,2));
console.log(JSON.stringify({runtimeRoots:audit.runtime_roots,dependencyFiles:seen.size,unresolved,inventory:inventory.map(r=>({...r,MiB:Math.round(r.bytes/1048576*10)/10,bytes:undefined}))},null,2));

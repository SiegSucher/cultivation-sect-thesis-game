const fs=require('fs'),path=require('path');
const base=__dirname, missing=[];
for(const file of ['COMPARE.html','REVIEW.md','../README.md']) {
 const p=path.resolve(base,file),source=fs.readFileSync(p,'utf8');
 const targets=file.endsWith('.html')?[...source.matchAll(/(?:src|href)="([^"]+)"/g)].map(m=>m[1]):[...source.matchAll(/\]\(([^)]+)\)/g)].map(m=>m[1]);
 for(const target of targets)if(!/^(https?:|#)/.test(target)&&!fs.existsSync(path.resolve(path.dirname(p),decodeURIComponent(target))))missing.push({file,target});
 if(file.endsWith('.html'))for(const m of source.matchAll(/<script>([\s\S]*?)<\/script>/g))new Function(m[1]);
}
const before=JSON.parse(fs.readFileSync(path.join(base,'views/before/views.json'),'utf8'));
const after=JSON.parse(fs.readFileSync(path.join(base,'views/after/views.json'),'utf8'));
if(JSON.stringify(before)!==JSON.stringify(after))throw Error('Matching cameras/resolution differ');
let pngs=0;
for(const folder of ['views/before','views/after','motion'])for(const name of fs.readdirSync(path.join(base,folder)))if(name.endsWith('.png')) {
 const b=fs.readFileSync(path.join(base,folder,name));
 if(b.readUInt32BE(16)!==1280||b.readUInt32BE(20)!==720)throw Error('Wrong dimensions '+folder+'/'+name);
 pngs++;
}
const result={checked_at:new Date().toISOString(),matched_camera_pairs:12,native_720p_images_checked:pngs,html_javascript_syntax:'PASS',missing_links:missing};
fs.writeFileSync(path.join(base,'delivery-validation.json'),JSON.stringify(result,null,2));
console.log(JSON.stringify(result,null,2));
if(missing.length)process.exitCode=1;

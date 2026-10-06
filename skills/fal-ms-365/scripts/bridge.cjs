'use strict';
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const {execFileSync} = require('node:child_process');
const digest = b => crypto.createHash('sha256').update(b).digest('hex');
const read = p => JSON.parse(fs.readFileSync(p, 'utf8').replace(/^\uFEFF/, ''));
function prepare(source, target) {
  const r = read(source);
  if (!r || typeof r !== 'object' || Array.isArray(r)) throw Error('Request must be an object');
  for (const key of ['operation','action']) if (typeof r[key] !== 'string') throw Error(`Missing ${key}`);
  if (r.outputDir && !path.isAbsolute(r.outputDir)) throw Error('outputDir must be an absolute Linux path');
  if (r.attachments) r.attachments = r.attachments.map(p => {
    if (!path.isAbsolute(p) || !fs.statSync(p).isFile()) throw Error('Attachment must be an existing absolute file path');
    return execFileSync('wslpath', ['-w', p], {encoding:'utf8'}).trim();
  });
  fs.writeFileSync(target, '\uFEFF' + JSON.stringify(r), {mode:0o600});
}
function finish(source, resultFile) {
  const request = read(source), result = read(resultFile);
  if (!result.stagingWindowsDirectory || result.status !== 'ok') return result;
  const staging = execFileSync('wslpath', ['-u', result.stagingWindowsDirectory], {encoding:'utf8'}).trim();
  const out = request.outputDir || '/tmp';
  fs.mkdirSync(out, {recursive:true, mode:0o700});
  const artifacts = result.artifacts || [];
  // Preflight every destination before copying anything. Source names are adapter-generated.
  for (const a of artifacts) {
    if (typeof a.name !== 'string' || !a.name || a.name !== path.basename(a.name) || ['.','..'].includes(a.name)) throw Error('Unsafe artifact name');
    if (fs.existsSync(path.join(out,a.name))) throw Error(`Refusing overwrite: ${path.join(out,a.name)}`);
  }
  function copyTree(src, dst) {
    const st = fs.lstatSync(src);
    if (st.isSymbolicLink()) throw Error('Symlink artifact rejected');
    if (st.isDirectory()) {
      fs.mkdirSync(dst, {mode:0o700});
      for (const name of fs.readdirSync(src)) copyTree(path.join(src,name),path.join(dst,name));
    } else if (st.isFile()) {
      fs.copyFileSync(src,dst,fs.constants.COPYFILE_EXCL);fs.chmodSync(dst,0o600);
      if (digest(fs.readFileSync(src)) !== digest(fs.readFileSync(dst))) throw Error('Artifact integrity failure');
    } else throw Error('Unsupported artifact type');
  }
  for (const a of artifacts) {
    const src=path.join(staging,a.name), dst=path.join(out,a.name);
    copyTree(src,dst);a.path=dst;a.verified=true;
    if(fs.statSync(dst).isFile()){a.bytes=fs.statSync(dst).size;a.sha256=digest(fs.readFileSync(dst));}
  }
  // Only remove the unique staging tree after all copies verify. No message is deleted.
  fs.rmSync(staging,{recursive:true});delete result.stagingWindowsDirectory;
  return result;
}
module.exports={prepare,finish};
if(require.main===module){
  try {
    const [mode,a,b]=process.argv.slice(2);
    if(mode==='prepare')prepare(a,b);
    else if(mode==='finish')process.stdout.write(JSON.stringify(finish(a,b),null,2)+'\n');
    else throw Error('Expected prepare or finish');
  } catch(e){process.stdout.write(JSON.stringify({status:'error',error:e.message,warnings:['Inspect partial artifacts or mutation state before retrying.']})+'\n');process.exitCode=1;}
}

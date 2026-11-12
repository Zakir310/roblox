// Rendu final : chaque image est calculée à un instant exact, capturée, puis assemblée par ffmpeg.
// Usage : node tools/rendu.mjs            → tout (3 versions × 3 formats, avec et sans son)
//         node tools/rendu.mjs A 9x16     → une version, un format
//         node tools/rendu.mjs --planche  → seulement les planches de contrôle (une image toutes les 0,5 s)
import { spawn, execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { DUREE, IPS } from '../src/shared/config.js';
import { serveur } from './serveur.mjs';

const require = createRequire(import.meta.url);
let chromium;
try { ({ chromium } = require('playwright')); }
catch { ({ chromium } = require(path.join(execFileSync('npm', ['root', '-g']).toString().trim(), 'playwright'))); }

const RACINE = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const FORMATS = { '9x16': [1080, 1920], '1x1': [1080, 1080], '16x9': [1920, 1080] };
const NOMS = { A: 'A-choc', B: 'B-curiosite', C: 'C-probleme-solution' };
const args = process.argv.slice(2), planche = args.includes('--planche'), choix = args.filter(a => !a.startsWith('--'));
const versions = choix.filter(a => NOMS[a.toUpperCase()]).map(a => a.toUpperCase()), formats = choix.filter(a => FORMATS[a]);

const s = await serveur(), port = s.address().port;
const navigateur = await chromium.launch({ args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });

for (const v of versions.length ? versions : Object.keys(NOMS)) for (const f of formats.length ? formats : Object.keys(FORMATS)) {
  const [w, h] = FORMATS[f], page = await navigateur.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: 1 });
  page.on('pageerror', e => { console.error(`[${v} ${f}]`, e.message); process.exitCode = 1; });
  await page.goto(`http://localhost:${port}/src/scene.html?v=${v}&w=${w}&h=${h}&capture=1`);
  await page.waitForFunction('window.pret === true', null, { timeout: 30000 });
  const cliche = async t => { await page.evaluate(x => window.image(x), t); return page.screenshot({ type: 'png' }); };

  if (planche) {
    const dossier = path.join(RACINE, 'storyboards', 'images'); fs.mkdirSync(dossier, { recursive: true });
    const tmp = fs.mkdtempSync(path.join(dossier, 'tmp-'));
    for (let i = 0; i <= 12; i++) fs.writeFileSync(path.join(tmp, `${String(i).padStart(2, '0')}.png`), await cliche(Math.min(i * 0.5, DUREE - 1 / IPS)));
    execFileSync('ffmpeg', ['-v', 'error', '-y', '-framerate', '1', '-i', path.join(tmp, '%02d.png'), '-vf', `scale=${Math.round(w / 4)}:-1,tile=${w > h ? 4 : 7}x${w > h ? 4 : 2}:padding=6:color=0x222222`, '-frames:v', '1', path.join(dossier, `${NOMS[v]}_${f}.png`)]);
    fs.rmSync(tmp, { recursive: true });
    console.log(`planche ${NOMS[v]}_${f}.png`);
  } else {
    const sortie = path.join(RACINE, 'exports', f); fs.mkdirSync(sortie, { recursive: true });
    const avecSon = path.join(sortie, `${NOMS[v]}_${f}.mp4`), muet = path.join(sortie, `${NOMS[v]}_${f}_sans-son.mp4`);
    const ff = spawn('ffmpeg', ['-v', 'error', '-y', '-f', 'image2pipe', '-framerate', String(IPS), '-c:v', 'png', '-i', '-', '-i', path.join(RACINE, 'audio', `${v}.wav`),
      '-c:v', 'libx264', '-preset', 'slow', '-crf', '15', '-pix_fmt', 'yuv420p', '-r', String(IPS), '-c:a', 'aac', '-b:a', '192k', '-t', String(DUREE), '-movflags', '+faststart', avecSon], { stdio: ['pipe', 'inherit', 'inherit'] });
    const fini = new Promise((ok, ko) => ff.on('close', c => c ? ko(new Error(`ffmpeg a échoué (${c})`)) : ok()));
    for (let i = 0; i < DUREE * IPS; i++) { const png = await cliche(i / IPS); if (!ff.stdin.write(png)) await new Promise(r => ff.stdin.once('drain', r)); }
    ff.stdin.end(); await fini;
    execFileSync('ffmpeg', ['-v', 'error', '-y', '-i', avecSon, '-an', '-c:v', 'copy', '-movflags', '+faststart', muet]);
    console.log(`vidéo ${path.relative(RACINE, avecSon)}`);
  }
  await page.close();
}
await navigateur.close(); s.close();

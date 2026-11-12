// Petit serveur local pour l'aperçu : node tools/serveur.mjs puis ouvrir l'adresse affichée.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const RACINE = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const TYPES = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.png': 'image/png', '.wav': 'audio/wav', '.woff2': 'font/woff2', '.ttf': 'font/ttf', '.mp4': 'video/mp4' };

export function serveur(port = 0) {
  return new Promise(resolve => {
    const s = http.createServer((req, res) => {
      const fichier = path.join(RACINE, path.normalize(decodeURIComponent(req.url.split('?')[0])));
      if (!fichier.startsWith(RACINE) || !fs.existsSync(fichier) || fs.statSync(fichier).isDirectory()) { res.writeHead(404); return res.end('Introuvable'); }
      res.writeHead(200, { 'Content-Type': TYPES[path.extname(fichier)] || 'application/octet-stream' });
      fs.createReadStream(fichier).pipe(res);
    });
    s.listen(port, () => resolve(s));
  });
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const s = await serveur(5173);
  const base = `http://localhost:${s.address().port}/src/scene.html`;
  console.log(`Aperçu (cliquer dans la page pour le son) :\n  A  ${base}?v=A\n  B  ${base}?v=B\n  C  ${base}?v=C\nFormats : ajouter &w=1080&h=1080 ou &w=1920&h=1080`);
}

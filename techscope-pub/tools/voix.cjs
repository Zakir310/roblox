// Régénère les répliques de la voix Pierre avec le moteur de TechScope lui-même.
// Usage : node tools/voix.cjs <dossier extension TechScope> <dossier contenant piper.onnx>
// Les fichiers produits (audio/voix/*.wav) sont déjà livrés : ce script ne sert qu'à changer le texte dit.
const http = require('http'), fs = require('fs'), path = require('path');
const { chromium } = require('playwright');
const EXT = path.resolve(process.argv[2]), MODELS = path.resolve(process.argv[3]);
const OUT = path.join(__dirname, '..', 'audio', 'voix');
const REPLIQUES = {
  complet: 'Bonjour. Voici ta minute tech.',
  bonjour: 'Bonjour.',
  minute: 'Voici ta minute tech.',
  ia: 'I A.', // « IA » collé est lu « ya » par espeak-ng
  cyber: 'Cybersécurité.',
  mobile: 'Mobile.'
};
const TYPES = { '.js': 'text/javascript', '.mjs': 'text/javascript', '.json': 'application/json', '.wasm': 'application/wasm' };
const server = http.createServer((req, res) => {
  const url = decodeURIComponent(req.url.split('?')[0]);
  if (url === '/t.html') { res.writeHead(200, { 'Content-Type': 'text/html' }); return res.end('<!doctype html><meta charset=utf-8>'); }
  const file = url.startsWith('/models/') ? path.join(MODELS, path.basename(url)) : path.join(EXT, path.normalize(url));
  if ((!file.startsWith(EXT) && !file.startsWith(MODELS)) || !fs.existsSync(file)) { res.writeHead(404); return res.end(); }
  res.writeHead(200, { 'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream' });
  fs.createReadStream(file).pipe(res);
});
server.listen(0, async () => {
  const browser = await chromium.launch(), page = await browser.newPage();
  await page.goto(`http://localhost:${server.address().port}/t.html`);
  const results = await page.evaluate(async repliques => {
    const pierre = await import('/piper.js');
    await (await caches.open('techscope-pierre-1')).put(pierre.PIERRE_URL, await fetch('/models/piper.onnx'));
    const { createPiperPhonemize } = await import('/vendor/piper/piper_phonemize.mjs');
    const map = (await (await fetch('/voices/fr_FR-upmc-medium.onnx.json')).json()).phoneme_id_map;
    const byId = Object.fromEntries(Object.entries(map).map(([k, v]) => [v[0], k]));
    const ipa = text => new Promise(resolve => createPiperPhonemize({ print: l => resolve(JSON.parse(l).phoneme_ids.map(i => byId[i] ?? '?').join('').replace(/[_^$]/g, '')), printErr() {}, locateFile: f => `/vendor/piper/${f.split('/').pop()}` })
      .then(m => m.callMain(['-l', 'fr', '--input', JSON.stringify([{ text }]), '--espeak_data', '/espeak-ng-data'])));
    const out = {};
    for (const [name, text] of Object.entries(repliques)) {
      const bytes = new Uint8Array(await (await pierre.pierreSpeak(text, 'fr', 1, 'naturel')).arrayBuffer());
      let bin = ''; for (let i = 0; i < bytes.length; i += 8192) bin += String.fromCharCode(...bytes.subarray(i, i + 8192));
      out[name] = { wav: btoa(bin), ipa: await ipa(text) };
    }
    return out;
  }, REPLIQUES);
  for (const [name, r] of Object.entries(results)) {
    fs.writeFileSync(path.join(OUT, `${name}.wav`), Buffer.from(r.wav, 'base64'));
    console.log(name.padEnd(8), JSON.stringify(REPLIQUES[name]), '→', r.ipa);
  }
  await browser.close(); server.close();
});

// Outils communs : temps, courbes, hasard reproductible, démarrage d'une scène.
import { DUREE, IPS } from './config.js';
import { ENV } from './env.js';

export const borne = (v, a = 0, b = 1) => Math.min(b, Math.max(a, v));
export const mix = (a, b, k) => a + (b - a) * k;
// Avancement de 0 à 1 entre deux instants.
export const seg = (t, a, b) => borne((t - a) / (b - a));
export const courbe = {
  sortie: k => 1 - (1 - k) ** 3,
  entree: k => k ** 3,
  double: k => k < 0.5 ? 4 * k ** 3 : 1 - (-2 * k + 2) ** 3 / 2,
  sortieVive: k => k >= 1 ? 1 : 1 - 2 ** (-10 * k),
  entreeVive: k => k <= 0 ? 0 : 2 ** (10 * k - 10),
  ressort: k => { const c = 1.70158; return 1 + (c + 1) * (k - 1) ** 3 + c * (k - 1) ** 2; }
};
export const hasard = graine => () => { graine |= 0; graine = graine + 0x6D2B79F5 | 0; let t = Math.imul(graine ^ graine >>> 15, 1 | graine); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; };

export function rectRond(ctx, x, y, w, h, r) {
  r = Math.max(0, Math.min(r, w / 2, h / 2));
  ctx.beginPath(); ctx.moveTo(x + r, y); ctx.arcTo(x + w, y, x + w, y + h, r); ctx.arcTo(x + w, y + h, x, y + h, r); ctx.arcTo(x, y + h, x, y, r); ctx.arcTo(x, y, x + w, y, r); ctx.closePath();
}

const POLICES = [['Instrument Serif', 'fonts/InstrumentSerif-Italic.ttf', { style: 'italic' }], ['Anton', 'fonts/Anton.woff2', {}],
  ['Inter', 'fonts/Inter-400.woff2', { weight: '400' }], ['Inter', 'fonts/Inter-500.woff2', { weight: '500' }],
  ['Inter', 'fonts/Inter-600.woff2', { weight: '600' }], ['Inter', 'fonts/Inter-700.woff2', { weight: '700' }]];

// Prépare la page puis donne la main à la scène. Avec ?capture=1, rien ne bouge tout seul :
// l'outil de rendu appelle window.image(t) pour chaque image, ce qui rend le résultat reproductible.
export async function demarre(version, cree) {
  const q = new URLSearchParams(location.search);
  const W = +q.get('w') || 1080, H = +q.get('h') || 1920, capture = q.has('capture');
  for (const [nom, url, desc] of POLICES) { const f = new FontFace(nom, `url(${url})`, desc); document.fonts.add(await f.load()); }
  const icone = new Image(); icone.src = 'img/icon.png'; await icone.decode();

  const scene = document.getElementById('scene');
  scene.style.width = `${W}px`; scene.style.height = `${H}px`;
  const toile = (gl = false) => { const c = document.createElement('canvas'); c.width = W; c.height = H; scene.appendChild(c); return gl ? c : c.getContext('2d'); };
  const niveaux = ENV[version];
  const S = {
    W, H, u: Math.min(W, H) / 1080, cx: W / 2, cy: H / 2, portrait: H / W > 1.4, icone, toile,
    // Niveau de la voix à l'instant t (0 à 1).
    voix: t => { const x = borne(t, 0, DUREE) * IPS, i = Math.floor(x); return mix(niveaux[i] || 0, niveaux[i + 1] || 0, x - i); }
  };
  const dessine = cree(S);
  window.image = t => dessine(borne(t, 0, DUREE));
  dessine(0);

  if (capture) { window.pret = true; return; }
  // Aperçu : la scène est réduite à la fenêtre, un clic lance la lecture en boucle avec le son.
  const cale = () => { const k = Math.min(innerWidth / W, innerHeight / H); scene.style.transform = `translate(-50%,-50%) scale(${k})`; };
  scene.style.position = 'absolute'; scene.style.left = '50%'; scene.style.top = '50%'; cale(); addEventListener('resize', cale);
  const son = new Audio(`../audio/${version}.wav`); son.loop = true;
  let t0 = performance.now(), sonore = false;
  addEventListener('click', () => { sonore = true; son.currentTime = 0; son.play(); });
  const boucle = () => { dessine(sonore ? son.currentTime % DUREE : ((performance.now() - t0) / 1000) % DUREE); requestAnimationFrame(boucle); };
  boucle();
}

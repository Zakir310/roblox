// Ce que les trois accroches ont en commun : le fond vert, l'onde de la voix, le bouton, la promesse, le logo.
// À partir de 4,00 s, les trois versions n'appellent plus que dessineFin() : l'image finale est donc la même.
import { TEXTES, COULEURS as C, TEMPS } from './config.js';
import { seg, mix, courbe, rectRond, hasard } from './core.js';

const BARRES = 45;
const r = hasard(7), relief = Array.from({ length: BARRES }, () => 0.55 + 0.45 * r());

// Positions de l'image finale, selon le format.
export function plan(S) {
  const { W, H, u, cx, portrait } = S;
  const y = portrait ? { logo: 0.15, promesse: 0.36, onde: 0.565, bouton: 0.735 } : { logo: 0.115, promesse: 0.335, onde: 0.59, bouton: 0.81 };
  const bw = 700 * u, bh = 148 * u, by = H * y.bouton;
  return {
    logoY: H * y.logo, promesseY: H * y.promesse, ondeY: H * y.onde, ondeL: (BARRES * 2 - 1) * 10 * u, ondeH: 230 * u,
    bouton: { x: cx - bw / 2, y: by - bh / 2, w: bw, h: bh, r: bh / 2 },
    lecture: { x: cx - bw / 2 + 74 * u, y: by, r: 46 * u }
  };
}

export function fond(ctx, S, alpha = 1) {
  if (alpha <= 0) return;
  const { W, H } = S;
  ctx.save(); ctx.globalAlpha = alpha;
  const g = ctx.createLinearGradient(0, 0, 0, H);
  [0, 0.32, 0.68, 1].forEach((p, i) => g.addColorStop(p, C.fond[i]));
  ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  const lueur = (px, py, rx, ry, teinte, a) => {
    ctx.save(); ctx.translate(px, py); ctx.scale(rx, ry);
    const rg = ctx.createRadialGradient(0, 0, 0, 0, 0, 1); rg.addColorStop(0, `${teinte}${a})`); rg.addColorStop(1, `${teinte}0)`);
    ctx.fillStyle = rg; ctx.fillRect(-1, -1, 2, 2); ctx.restore();
  };
  lueur(W, H, W * 0.85, H * 0.5, C.lueurVerte, 0.34);
  lueur(0, 0, W * 0.7, H * 0.4, C.lueurChaude, 0.16);
  ctx.restore();
}

// L'onde : des barres qui partent du centre et suivent le niveau de la voix.
// plat = 1 : toutes les barres sont réduites à un trait. blanc = 1 : barres blanches (version A).
export function onde(ctx, S, P, t, { alpha = 1, plat = 0, blanc = 0 } = {}) {
  if (alpha <= 0) return;
  const { u, cx } = S, pas = 20 * u, l = 10 * u, milieu = (BARRES - 1) / 2;
  ctx.save(); ctx.globalAlpha = alpha;
  // Halo doux derrière l'onde.
  const halo = ctx.createRadialGradient(cx, P.ondeY, 0, cx, P.ondeY, P.ondeL * 0.55);
  halo.addColorStop(0, `rgba(80,230,150,${0.16 * (1 - plat) * (1 - blanc)})`); halo.addColorStop(1, 'rgba(80,230,150,0)');
  ctx.fillStyle = halo; ctx.fillRect(cx - P.ondeL, P.ondeY - P.ondeL * 0.6, P.ondeL * 2, P.ondeL * 1.2);
  const g = ctx.createLinearGradient(0, P.ondeY - P.ondeH / 2, 0, P.ondeY + P.ondeH / 2);
  g.addColorStop(0, C.ondeBas); g.addColorStop(0.5, C.ondeHaut); g.addColorStop(1, C.ondeBas);
  for (let i = 0; i < BARRES; i++) {
    const d = Math.abs(i - milieu), cloche = Math.cos(d / (milieu + 3) * Math.PI / 2) ** 1.4;
    // La voix, plus une houle lente pour que l'onde reste vivante entre deux mots.
    const niveau = 1.35 * S.voix(t - d * 0.011) * relief[i] * cloche + (0.07 + 0.17 * (0.5 + 0.5 * Math.sin(t * 4.2 - d * 0.42)) * relief[i]) * cloche;
    const h = mix(Math.max(l, P.ondeH * Math.min(1, niveau)), 5 * u, plat);
    const x = cx + (i - milieu) * pas - l / 2;
    rectRond(ctx, x, P.ondeY - h / 2, l, h, l / 2);
    ctx.fillStyle = g; ctx.fill();
    if (blanc > 0) { ctx.globalAlpha = alpha * blanc; ctx.fillStyle = '#fff'; ctx.fill(); ctx.globalAlpha = alpha; }
  }
  ctx.restore();
}

// Le bouton « Écouter mon briefing », en verre vert comme dans l'extension.
export function bouton(ctx, S, P, { alpha = 1, dy = 0, pastille = 1 } = {}) {
  if (alpha <= 0) return;
  const { u } = S, b = P.bouton;
  ctx.save(); ctx.globalAlpha = alpha; ctx.translate(0, dy);
  rectRond(ctx, b.x, b.y, b.w, b.h, b.r);
  ctx.fillStyle = 'rgba(8,30,20,.55)'; ctx.fill();
  const g = ctx.createLinearGradient(0, b.y, 0, b.y + b.h); g.addColorStop(0, C.boutonHaut); g.addColorStop(1, C.boutonBas);
  ctx.fillStyle = g; ctx.fill();
  ctx.lineWidth = 2 * u; ctx.strokeStyle = C.boutonBord; ctx.stroke();
  if (pastille > 0) {
    ctx.globalAlpha = alpha * pastille;
    ctx.beginPath(); ctx.arc(P.lecture.x, P.lecture.y, P.lecture.r, 0, Math.PI * 2); ctx.fillStyle = C.boutonTexte; ctx.fill();
    const k = P.lecture.r * 0.42;
    ctx.beginPath(); ctx.moveTo(P.lecture.x - k * 0.6, P.lecture.y - k); ctx.lineTo(P.lecture.x + k, P.lecture.y); ctx.lineTo(P.lecture.x - k * 0.6, P.lecture.y + k); ctx.closePath();
    ctx.fillStyle = '#0b3a26'; ctx.fill();
    ctx.globalAlpha = alpha;
  }
  ctx.font = `600 ${48 * u}px Inter`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillStyle = C.boutonTexte;
  ctx.fillText(TEXTES.bouton, b.x + b.w / 2 + 54 * u, b.y + b.h / 2 + 2 * u);
  ctx.restore();
}

function promesse(ctx, S, P, t) {
  const { W, u, cx } = S;
  let taille = 128 * u;
  ctx.save(); ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
  ctx.font = `italic ${taille}px "Instrument Serif"`;
  const large = Math.max(...TEXTES.promesse.map(l => ctx.measureText(l).width));
  if (large > W * 0.88) taille *= W * 0.88 / large;
  ctx.font = `italic ${taille}px "Instrument Serif"`;
  TEXTES.promesse.forEach((ligne, i) => {
    const k = courbe.sortie(seg(t, TEMPS.impact + 0.04 + i * 0.26, TEMPS.impact + 0.5 + i * 0.26));
    ctx.globalAlpha = k; ctx.fillStyle = i ? C.accent : C.texte;
    ctx.fillText(ligne, cx, P.promesseY + (i - 0.5) * taille * 1.08 + (1 - k) * 36 * u);
  });
  ctx.restore();
}

function logo(ctx, S, P, t) {
  const k = courbe.sortie(seg(t, TEMPS.transition, TEMPS.transition + 0.5));
  if (k <= 0) return;
  const { u, cx } = S, c = 68 * u;
  ctx.save(); ctx.globalAlpha = k; ctx.font = `italic ${72 * u}px "Instrument Serif"`; ctx.textBaseline = 'middle'; ctx.textAlign = 'left';
  const l = ctx.measureText(TEXTES.marque).width, total = c + 20 * u + l, x = cx - total / 2, y = P.logoY - (1 - k) * 16 * u;
  ctx.drawImage(S.icone, x, y - c / 2, c, c);
  ctx.fillStyle = C.texte; ctx.fillText(TEXTES.marque, x + c + 20 * u, y + 2 * u);
  ctx.restore();
}

// De 4,00 à 6,00 s : impact puis transition. Identique pour A, B et C.
export function dessineFin(ctx, S, P, t) {
  const { W, H, cx, cy } = S;
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.clearRect(0, 0, W, H);
  fond(ctx, S);
  const z = 1 + 0.035 * courbe.double(seg(t, TEMPS.impact + 0.6, TEMPS.fin));   // lente avancée vers la suite de la pub
  ctx.translate(cx, cy); ctx.scale(z, z); ctx.translate(-cx, -cy);
  onde(ctx, S, P, t); bouton(ctx, S, P); promesse(ctx, S, P, t); logo(ctx, S, P, t);
  ctx.setTransform(1, 0, 0, 1, 0, 0);
}

// VERSION C — PROBLÈME / SOLUTION : « Dix onglets ». Interface claire dessinée à plat, guidée par le curseur.
// Les onglets se multiplient, le compteur grimpe ; un clic sur TechScope replie tout dans un seul bouton.
import { TEXTES, SOURCES, TEMPS, C as R, COULEURS as C } from './shared/config.js';
import { seg, mix, courbe, rectRond, hasard } from './shared/core.js';
import { plan, fond, onde, bouton, dessineFin } from './shared/commun.js';

export default function cree(S) {
  const { W, H, cx } = S, P = plan(S), ctx = S.toile(), r = hasard(303);
  // L'interface est grossie en portrait : sur un téléphone, les onglets doivent rester lisibles.
  const u = S.u * (S.portrait ? 1.5 : 1.2);
  // La fenêtre du navigateur.
  const F = { w: Math.min(W * 0.92, 1560 * S.u), h: Math.min(H * (S.portrait ? 0.6 : 0.74), 1150 * S.u) };
  F.x = cx - F.w / 2; F.y = H * (S.portrait ? 0.47 : 0.5) - F.h / 2;
  const bande = 96 * u, barre = 92 * u, hOnglet = 72 * u, marge = 22 * u;
  const zone = { x: F.x + marge, w: F.w - marge * 2 - 70 * u };   // place réservée aux onglets
  const teintes = Array.from({ length: R.onglets }, () => `hsl(${Math.floor(r() * 360)} 62% 52%)`);
  const squelettes = Array.from({ length: R.onglets }, () => Array.from({ length: 5 }, () => 0.45 + 0.5 * r()));
  const icone = { x: F.x + F.w - 76 * u, y: F.y + bande + barre / 2, c: 56 * u };

  // Largeur de chaque onglet à l'instant t : il naît avec un petit rebond, puis se replie après le clic.
  function onglets(t) {
    const poids = [];
    for (let i = 0; i < R.onglets; i++) {
      const ne = R.apparition(i), a = ne < 0 ? 1 : courbe.ressort(seg(t, ne, ne + 0.14)) * (t >= ne ? 1 : 0);
      const pli = 1 - courbe.entree(seg(t, R.clic + 0.03 + i * 0.011, R.clic + 0.2 + i * 0.011));
      poids.push(Math.max(0, a) * pli);
    }
    const ouverts = poids.reduce((s, p, i) => s + Math.min(1, R.apparition(i) < 0 ? 1 : seg(t, R.apparition(i), R.apparition(i) + 0.14)), 0);
    const large = Math.min(320 * u, zone.w / Math.max(1, ouverts));
    // Après le clic, les onglets restants se serrent vers la droite, du côté de l'icône.
    const total = poids.reduce((s, p) => s + p * large, 0), decale = t > R.clic ? Math.max(0, zone.w - total) * seg(t, R.clic, R.clic + 0.25) : 0;
    let x = zone.x + decale; const out = [];
    for (let i = 0; i < R.onglets; i++) { out.push({ x, w: poids[i] * large, plein: large }); x += poids[i] * large; }
    return out;
  }

  // Où est le curseur, et quel onglet est actif.
  function curseur(t, o) {
    const centre = i => ({ x: o[i].x + o[i].w / 2, y: F.y + bande - hOnglet / 2 + 8 * u });
    const fin = () => { const d = o.filter(z => z.w > 0.5).at(-1); return { x: Math.min(d.x + d.w + 34 * u, F.x + F.w - 40 * u), y: F.y + bande - hOnglet / 2 }; };
    if (t < R.sauts[0][0]) return { ...fin(), actif: Math.max(2, o.filter(z => z.w > 0.5).length - 1), appui: (t * 12) % 1 < 0.35 };
    let de = fin(), actif = R.onglets - 1;
    for (let k = 0; k < R.sauts.length; k++) {
      const [t0, i] = R.sauts[k], suivant = R.sauts[k + 1]?.[0] ?? 2.2;
      if (t < suivant || k === R.sauts.length - 1) {
        const m = courbe.double(seg(t, t0, t0 + 0.15)), vers = centre(i);
        if (k === R.sauts.length - 1 && t >= 2.2) {   // dernier trajet : vers l'icône TechScope
          const g = courbe.double(seg(t, 2.2, R.clic - 0.04));
          return { x: mix(vers.x, icone.x + 6 * u, g), y: mix(vers.y, icone.y + 8 * u, g), actif: i, appui: t >= R.clic - 0.02 && t < R.clic + 0.1 };
        }
        return { x: mix(de.x, vers.x, m), y: mix(de.y, vers.y, m) - Math.sin(m * Math.PI) * 30 * u, actif: m > 0.6 ? i : actif, appui: m > 0.85 && t < t0 + 0.24 };
      }
      de = centre(i); actif = i;
    }
  }

  function fleche(x, y, alpha, appui) {
    const k = (appui ? 0.88 : 1) * 3.1 * u;
    ctx.save(); ctx.globalAlpha = alpha; ctx.translate(x, y); ctx.scale(k, k);
    ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(0, 17); ctx.lineTo(4.4, 13.2); ctx.lineTo(7.4, 20); ctx.lineTo(10.2, 18.8); ctx.lineTo(7.3, 12.2); ctx.lineTo(12.6, 12.2); ctx.closePath();
    ctx.shadowColor = 'rgba(0,0,0,.3)'; ctx.shadowBlur = 8 * u; ctx.shadowOffsetY = 3 * u;
    ctx.fillStyle = '#111'; ctx.fill(); ctx.shadowColor = 'transparent'; ctx.lineWidth = 1.5; ctx.lineJoin = 'round'; ctx.strokeStyle = '#fff'; ctx.stroke();
    ctx.restore();
  }

  function fondClair() {
    const g = ctx.createLinearGradient(0, 0, 0, H); [0, 0.5, 1].forEach((p, i) => g.addColorStop(p, C.clairFond[i]));
    ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  }

  return function dessine(t) {
    if (t >= TEMPS.impact) return dessineFin(ctx, S, P, t);
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    fondClair();
    fond(ctx, S, courbe.double(seg(t, 2.62, 3.25)));

    // La fenêtre se transforme en bouton : même rectangle, qui glisse et rétrécit.
    const m = courbe.double(seg(t, 2.68, 3.35)), b = P.bouton;
    const x = mix(F.x, b.x, m), y = mix(F.y, b.y, m), w = mix(F.w, b.w, m), h = mix(F.h, b.h, m), rayon = mix(30 * u, b.r, m);
    const contenu = 1 - seg(t, R.clic + 0.1, R.clic + 0.3);
    // Petite secousse de la fenêtre à chaque onglet qui s'ajoute, de plus en plus forte.
    const secousse = t < 1 ? Math.sin(t * 90) * 5 * u * t : 0;

    if (m < 1) {
      ctx.save(); ctx.translate(secousse, 0);
      ctx.globalAlpha = 1 - m ** 1.5;
      ctx.shadowColor = 'rgba(18,60,40,.22)'; ctx.shadowBlur = 60 * u; ctx.shadowOffsetY = 24 * u;
      rectRond(ctx, x, y, w, h, rayon); ctx.fillStyle = '#fff'; ctx.fill(); ctx.shadowColor = 'transparent';
      if (contenu > 0) {
        const o = onglets(t), cur = curseur(t, o);
        ctx.save(); rectRond(ctx, x, y, w, h, rayon); ctx.clip(); ctx.globalAlpha = contenu * (1 - m);
        ctx.fillStyle = '#dde9e1'; ctx.fillRect(F.x, F.y, F.w, bande);
        // Les onglets.
        o.forEach((z, i) => {
          if (z.w < 1) return;
          const yy = F.y + bande - hOnglet, actif = i === cur.actif;
          if (actif) { rectRond(ctx, z.x + 2 * u, yy, z.w - 4 * u, hOnglet + 20 * u, 16 * u); ctx.fillStyle = '#fff'; ctx.fill(); }
          else { ctx.fillStyle = 'rgba(18,36,27,.16)'; ctx.fillRect(z.x + z.w - 1 * u, yy + 18 * u, 2 * u, hOnglet - 36 * u); }
          const pastille = Math.min(13 * u, z.w * 0.3);
          ctx.beginPath(); ctx.arc(z.x + Math.min(30 * u, z.w / 2), yy + hOnglet / 2, pastille, 0, Math.PI * 2); ctx.fillStyle = teintes[i]; ctx.fill();
          if (z.w > 96 * u) {
            ctx.save(); ctx.beginPath(); ctx.rect(z.x, yy, z.w - 14 * u, hOnglet); ctx.clip();
            ctx.font = `500 ${29 * u}px Inter`; ctx.textAlign = 'left'; ctx.textBaseline = 'middle'; ctx.fillStyle = C.clairTexte;
            ctx.fillText(SOURCES[i % SOURCES.length], z.x + 56 * u, yy + hOnglet / 2 + 1 * u); ctx.restore();
          }
        });
        // La barre d'adresse et l'icône TechScope.
        const by = F.y + bande;
        rectRond(ctx, F.x + marge, by + 18 * u, F.w - marge * 2 - 96 * u, barre - 36 * u, 28 * u); ctx.fillStyle = '#eef4f0'; ctx.fill();
        ctx.font = `400 ${27 * u}px Inter`; ctx.textAlign = 'left'; ctx.textBaseline = 'middle'; ctx.fillStyle = '#6b8074';
        ctx.fillText(`${SOURCES[cur.actif % SOURCES.length].toLowerCase().replace(/[^a-z0-9]/g, '')}.com`, F.x + marge + 30 * u, by + barre / 2 + 1 * u);
        const pouls = 1 + 0.22 * Math.sin(seg(t, R.clic, R.clic + 0.3) * Math.PI);
        ctx.drawImage(S.icone, icone.x - icone.c * pouls / 2, icone.y - icone.c * pouls / 2, icone.c * pouls, icone.c * pouls);
        // La page : un squelette d'article différent pour chaque onglet.
        const py = by + barre + 44 * u, sq = squelettes[cur.actif], pl = F.w - 120 * u;
        ctx.fillStyle = '#e4ece7';
        rectRond(ctx, F.x + 60 * u, py, pl * sq[0], 54 * u, 12 * u); ctx.fill();
        for (let k = 1; k < (t < TEMPS.intrigue ? 5 : 2); k++) { rectRond(ctx, F.x + 60 * u, py + 54 * u + k * 56 * u, pl * sq[k], 26 * u, 10 * u); ctx.fill(); }
        // Le compteur de non lus.
        if (t >= TEMPS.intrigue) {
          const n = Math.round(mix(R.nonLus[0], R.nonLus[1], courbe.double(seg(t, TEMPS.intrigue, 2.35))));
          const e = mix(1.3, 1, courbe.sortieVive(seg(t, TEMPS.intrigue, TEMPS.intrigue + 0.2))), haut = by + barre + 190 * u, yc = (haut + F.y + F.h) / 2;
          ctx.save(); ctx.translate(cx, yc); ctx.scale(e, e); ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
          const tn = Math.min(330 * S.u, (F.y + F.h - haut) * 0.56);
          ctx.font = `700 ${tn}px Inter`; ctx.fillStyle = C.alerte; ctx.fillText(String(n), 0, -tn * 0.18);
          ctx.font = `600 ${tn * 0.27}px Inter`; ctx.fillStyle = C.clairTexte; ctx.fillText(TEXTES.c_non_lus, 0, tn * 0.48);
          ctx.restore();
        }
        ctx.restore();
        // L'onde du clic, puis le curseur.
        const clic = seg(t, R.clic, R.clic + 0.4);
        if (clic > 0 && clic < 1) { ctx.globalAlpha = (1 - clic) * 0.8; ctx.beginPath(); ctx.arc(icone.x, icone.y, mix(30, 150, courbe.sortie(clic)) * u, 0, Math.PI * 2); ctx.lineWidth = 6 * u; ctx.strokeStyle = '#2f9a62'; ctx.stroke(); }
        fleche(cur.x, cur.y, contenu, cur.appui);
      }
      ctx.restore();
    }
    bouton(ctx, S, P, { alpha: courbe.sortie(seg(t, 3.05, 3.5)), pastille: seg(t, 3.3, 3.55) });
    onde(ctx, S, P, t, { alpha: courbe.sortie(seg(t, 3.2, 3.8)) });
    // L'icône TechScope quitte la barre d'outils et vient se poser sur la pastille du bouton : c'est elle qui fait le lien.
    const vol = courbe.double(seg(t, R.clic + 0.12, 3.3)), reste = 1 - seg(t, 3.3, 3.55);
    if (t > R.clic + 0.1 && reste > 0) {
      const c = mix(icone.c, P.lecture.r * 2, vol) * (1 + 0.5 * Math.sin(vol * Math.PI));
      ctx.save(); ctx.globalAlpha = reste;
      ctx.drawImage(S.icone, mix(icone.x, P.lecture.x, vol) - c / 2, mix(icone.y, P.lecture.y, vol) - Math.sin(vol * Math.PI) * 120 * S.u - c / 2, c, c);
      ctx.restore();
    }
  };
}

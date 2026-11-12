// VERSION A — CHOC : « Le mur ». Typographie cinétique, noir et blanc, Canvas 2D.
// L'actu tech est un mur de bruit ; il s'écrase en un seul trait, et ce trait devient la voix.
import { TEXTES, SOURCES, TEMPS, A } from './shared/config.js';
import { seg, mix, courbe, hasard } from './shared/core.js';
import { plan, fond, onde, bouton, dessineFin } from './shared/commun.js';

export default function cree(S) {
  const { W, H, u, cx } = S, P = plan(S), ctx = S.toile(), r = hasard(101);
  const hLigne = 104 * u, police = `${92 * u}px Anton`;

  // Les rangées du mur : titres pleins et noms de sources en contour, en alternance, dans les deux sens.
  ctx.font = police;
  const nb = Math.ceil(H / hLigne) + 2, rangees = [];
  for (let i = 0; i < nb; i++) {
    const sources = i % 2 === 1, mots = (sources ? SOURCES.map(s => s.toUpperCase()) : TEXTES.a_titres).slice();
    for (let k = mots.length - 1; k > 0; k--) { const j = Math.floor(r() * (k + 1)); [mots[k], mots[j]] = [mots[j], mots[k]]; }
    const texte = mots.join('   ·   ') + '   ·   ';
    rangees.push({ texte, large: ctx.measureText(texte).width, sens: i % 2 ? 1 : -1, vitesse: (520 + 620 * r()) * u, depart: r() * 3000 * u, contour: sources });
  }
  // Les rangées sont réparties autour de la ligne où naîtra l'onde, pour que l'écrasement vise ce point.
  const premiere = P.ondeY - Math.ceil(P.ondeY / hLigne) * hLigne;

  function mur(t) {
    // Distance parcourue : vitesse constante puis forte accélération pendant l'intrigue.
    const avance = t + 1.5 * Math.max(0, t - TEMPS.intrigue) ** 2.4;
    ctx.font = police; ctx.textBaseline = 'middle'; ctx.textAlign = 'left'; ctx.lineWidth = 2.5 * u;
    rangees.forEach((g, i) => {
      const y = premiere + (i + 0.5) * hLigne;
      let x = -(((g.depart + avance * g.vitesse) % g.large) + g.large) % g.large;
      if (g.sens > 0) x = -g.large - x;
      for (; x < W; x += g.large) {
        if (x + g.large < 0) continue;
        if (g.contour) { ctx.strokeStyle = 'rgba(255,255,255,.62)'; ctx.strokeText(g.texte, x, y); }
        else { ctx.fillStyle = '#fff'; ctx.fillText(g.texte, x, y); }
      }
    });
  }

  // Un pavé noir avec un texte blanc énorme, qui claque à l'écran.
  function pave(lignes, taille, echelle, y) {
    ctx.save(); ctx.font = `${taille}px Anton`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    const large = Math.max(...lignes.map(l => ctx.measureText(l).width)), haut = lignes.length * taille * 1.08;
    ctx.translate(cx, y); ctx.scale(echelle, echelle);
    ctx.fillStyle = '#000'; ctx.fillRect(-large / 2 - 46 * u, -haut / 2 - 30 * u, large + 92 * u, haut + 60 * u);
    ctx.fillStyle = '#fff';
    lignes.forEach((l, i) => ctx.fillText(l, 0, (i - (lignes.length - 1) / 2) * taille * 1.08 + taille * 0.04));
    ctx.restore();
  }
  const ajuste = (lignes, voulu) => { ctx.font = `${voulu}px Anton`; const l = Math.max(...lignes.map(x => ctx.measureText(x).width)); return Math.min(voulu, voulu * (W * 0.8) / l); };
  const tSources = ajuste([TEXTES.a_sources], 250 * u), tArticles = ajuste(TEXTES.a_articles, 210 * u), tMinute = ajuste([TEXTES.a_minute], 300 * u);

  return function dessine(t) {
    if (t >= TEMPS.impact) return dessineFin(ctx, S, P, t);
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.fillStyle = '#000'; ctx.fillRect(0, 0, W, H);

    if (t < TEMPS.revelation) {
      // CAPTATION puis INTRIGUE : le mur, puis son écrasement vers la ligne de l'onde.
      const k = courbe.entree(seg(t, A.ecrasementDebut, A.ecrasementFin)), sy = mix(1, 0.0022, k);
      ctx.save(); ctx.translate(0, P.ondeY); ctx.scale(1, sy); ctx.translate(0, -P.ondeY);
      mur(t);
      if (t >= A.claque && t < A.coupe) pave([TEXTES.a_sources], tSources, mix(1.35, 1, courbe.sortieVive(seg(t, A.claque, A.claque + 0.2))), S.cy);
      else if (t >= A.coupe) pave(TEXTES.a_articles, tArticles, mix(1.12, 1, courbe.sortieVive(seg(t, A.coupe, A.coupe + 0.16))), S.cy);
      ctx.restore();
      // Le trait blanc qui reste quand tout est écrasé.
      const trait = seg(t, A.ecrasementFin - 0.2, A.ecrasementFin);
      if (trait > 0) { ctx.globalAlpha = trait; ctx.fillStyle = '#fff'; ctx.fillRect(0, P.ondeY - 2.5 * u, W, 5 * u); ctx.globalAlpha = 1; }
      return;
    }

    // RÉVÉLATION : le trait se resserre, verdit, se découpe en barres ; le fond vert et le bouton arrivent.
    fond(ctx, S, courbe.double(seg(t, 2.9, 3.7)));
    const serre = courbe.double(seg(t, TEMPS.revelation, 2.95)), barres = courbe.double(seg(t, 2.9, 3.3));
    if (barres < 1) {
      const l = mix(W, P.ondeL, serre);
      ctx.globalAlpha = 1 - barres; ctx.fillStyle = '#fff'; ctx.fillRect(cx - l / 2, P.ondeY - 2.5 * u, l, 5 * u); ctx.globalAlpha = 1;
    }
    onde(ctx, S, P, t, { alpha: barres, plat: 1 - courbe.sortie(seg(t, 3.0, 3.4)), blanc: 1 - seg(t, 3.0, 3.5) });
    const m = seg(t, A.note, A.note + 0.18), sortie = courbe.entree(seg(t, 3.5, 3.95));
    if (m > 0 && sortie < 1) {
      ctx.save(); ctx.globalAlpha = 1 - sortie; ctx.font = `${tMinute}px Anton`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillStyle = '#fff';
      const e = mix(1.3, 1, courbe.sortieVive(m));
      ctx.translate(cx, P.promesseY - sortie * 60 * u); ctx.scale(e, e); ctx.fillText(TEXTES.a_minute, 0, 0); ctx.restore();
    }
    const b = courbe.sortie(seg(t, 3.35, 3.9));
    bouton(ctx, S, P, { alpha: b, dy: (1 - b) * 40 * u });
  };
}

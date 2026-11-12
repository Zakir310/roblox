// VERSION B — CURIOSITÉ : « 07:00 ». Une forme lumineuse parle dans le noir ; on découvre que c'est le bouton.
// La forme est un shader WebGL piloté par le niveau réel de la voix ; les textes sont sur une toile 2D au-dessus.
import { TEXTES, TEMPS, VOIX, COULEURS as C } from './shared/config.js';
import { seg, mix, courbe } from './shared/core.js';
import { plan, fond, onde, bouton, dessineFin } from './shared/commun.js';

const SOMMET = 'attribute vec2 p; void main(){ gl_Position = vec4(p, 0., 1.); }';
const FRAGMENT = `
precision highp float;
uniform vec2 uCentre; uniform float uRayon, uTemps, uVoix, uAlpha;
// Bruit de valeur en 3D, lissé : il fait onduler le bord de la forme.
float h(vec3 p){ p = fract(p * .3183099 + .1); p *= 17.; return fract(p.x * p.y * p.z * (p.x + p.y + p.z)); }
float bruit(vec3 x){ vec3 i = floor(x), f = fract(x); f = f * f * (3. - 2. * f);
  return mix(mix(mix(h(i), h(i + vec3(1,0,0)), f.x), mix(h(i + vec3(0,1,0)), h(i + vec3(1,1,0)), f.x), f.y),
             mix(mix(h(i + vec3(0,0,1)), h(i + vec3(1,0,1)), f.x), mix(h(i + vec3(0,1,1)), h(i + vec3(1,1,1)), f.x), f.y), f.z); }
void main(){
  vec2 d = gl_FragCoord.xy - uCentre; float r = length(d); vec2 dir = d / max(r, 1e-3);
  float n = bruit(vec3(dir * 1.6, uTemps * .55)) * .65 + bruit(vec3(dir * 3.4 + 7., uTemps * .9)) * .35;
  float R = uRayon * (1. + .05 * sin(uTemps * 1.6) + (.10 + .42 * uVoix) * (n - .45));
  float x = r / R;
  float coeur = smoothstep(1., .82, x);                       // disque plein
  float bord = exp(-pow(abs(x - 1.) * 9., 2.));               // liseré lumineux
  float halo = exp(-max(x - 1., 0.) * 2.6) * (.45 + .55 * uVoix);
  float relief = bruit(vec3(d / uRayon * 2.2, uTemps * .4));  // matière à l'intérieur
  vec3 col = mix(vec3(.02, .30, .17), vec3(.50, 1., .68), pow(x, 2.2)) * coeur * (.75 + .5 * relief);
  col += vec3(.84, 1., .88) * bord * (.8 + .6 * uVoix);
  col += vec3(.10, .78, .42) * halo * (1. - coeur) * .55;
  float a = clamp(max(coeur, max(bord, halo * .55)), 0., 1.) * uAlpha;
  gl_FragColor = vec4(col * uAlpha, a);
}`;

export default function cree(S) {
  const { W, H, u, cx } = S, P = plan(S);
  const dessous = S.toile(), toileGl = S.toile(true), dessus = S.toile();
  const gl = toileGl.getContext('webgl', { premultipliedAlpha: true, preserveDrawingBuffer: true, antialias: false });
  const prog = gl.createProgram();
  for (const [type, src] of [[gl.VERTEX_SHADER, SOMMET], [gl.FRAGMENT_SHADER, FRAGMENT]]) {
    const sh = gl.createShader(type); gl.shaderSource(sh, src); gl.compileShader(sh);
    if (!gl.getShaderParameter(sh, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(sh));
    gl.attachShader(prog, sh);
  }
  gl.linkProgram(prog); gl.useProgram(prog);
  gl.bindBuffer(gl.ARRAY_BUFFER, gl.createBuffer()); gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]), gl.STATIC_DRAW);
  gl.enableVertexAttribArray(0); gl.bindAttribLocation(prog, 0, 'p'); gl.vertexAttribPointer(0, 2, gl.FLOAT, false, 0, 0);
  const un = Object.fromEntries(['uCentre', 'uRayon', 'uTemps', 'uVoix', 'uAlpha'].map(n => [n, gl.getUniformLocation(prog, n)]));
  gl.viewport(0, 0, W, H); gl.clearColor(0, 0, 0, 0);

  const depart = { x: cx, y: H * (S.portrait ? 0.44 : 0.47), r: 215 * u };
  // Les mots apparaissent à l'instant exact où la voix les dit.
  const instant = nom => VOIX.B.find(([n]) => n === nom)[1];
  const mots = [
    { texte: TEXTES.b_bonjour, t: instant('bonjour'), duree: 0.75, dx: 0, dy: 1.75, taille: 110 },
    { texte: TEXTES.b_mots[0], t: instant('ia'), duree: 0.6, dx: -1.45, dy: -1.45, taille: 150 },
    { texte: TEXTES.b_mots[1], t: instant('mobile'), duree: 0.65, dx: 0.7, dy: 1.8, taille: 130 },
    { texte: TEXTES.b_mots[2], t: instant('cyber'), duree: 0.85, dx: 0, dy: -1.8, taille: 130 }
  ];

  function forme(t, alpha) {
    gl.clear(gl.COLOR_BUFFER_BIT);
    if (alpha <= 0) return;
    const k = courbe.double(seg(t, TEMPS.revelation, 3.45));   // recul de la caméra : la forme rejoint le bouton
    gl.uniform2f(un.uCentre, mix(depart.x, P.lecture.x, k), H - mix(depart.y, P.lecture.y, k));
    gl.uniform1f(un.uRayon, mix(depart.r, P.lecture.r, k) * mix(0.72, 1, courbe.sortie(seg(t, 0, 0.6))));   // elle est là dès la première image, et gonfle
    gl.uniform1f(un.uTemps, t); gl.uniform1f(un.uVoix, S.voix(t) * (1 - 0.7 * k)); gl.uniform1f(un.uAlpha, alpha);
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
  }

  return function dessine(t) {
    dessus.setTransform(1, 0, 0, 1, 0, 0);
    if (t >= TEMPS.impact) { forme(t, 0); dessous.clearRect(0, 0, W, H); return dessineFin(dessus, S, P, t); }
    dessus.clearRect(0, 0, W, H);

    // Dessous : le noir, puis le fond vert qui monte à la révélation.
    dessous.fillStyle = '#000'; dessous.fillRect(0, 0, W, H);
    fond(dessous, S, courbe.double(seg(t, 2.6, 3.5)));
    // Milieu : la forme, visible dès la première image, qui s'efface quand la pastille du bouton la remplace.
    forme(t, 1 - seg(t, 3.5, 3.9));

    // Dessus : l'heure, les mots, puis le bouton et l'onde.
    const heure = courbe.sortie(seg(t, 0.05, 0.5)) * (1 - seg(t, 2.1, 2.3));   // l'heure s'efface avant le dernier mot, qui prend sa place
    if (heure > 0) {
      dessus.save(); dessus.globalAlpha = heure * 0.78; dessus.fillStyle = C.texte; dessus.textAlign = 'center'; dessus.textBaseline = 'middle';
      dessus.font = `500 ${72 * u}px Inter`; dessus.letterSpacing = `${8 * u}px`;
      dessus.fillText(TEXTES.b_heure, cx + 4 * u, H * (S.portrait ? 0.15 : 0.11)); dessus.restore();
    }
    for (const m of mots) {
      const a = courbe.sortie(seg(t, m.t, m.t + 0.16)) * (1 - courbe.entree(seg(t, m.t + m.duree, m.t + m.duree + 0.3)));
      if (a <= 0) continue;
      dessus.save(); dessus.globalAlpha = a; dessus.fillStyle = C.texte; dessus.textAlign = 'center'; dessus.textBaseline = 'middle';
      dessus.font = `italic ${m.taille * u}px "Instrument Serif"`;
      const l = dessus.measureText(m.texte).width, marge = 60 * u;
      const x = Math.min(W - marge - l / 2, Math.max(marge + l / 2, depart.x + m.dx * depart.r));
      const y = depart.y + m.dy * depart.r - (t - m.t) * 26 * u;
      dessus.fillText(m.texte, x, y); dessus.restore();
    }
    bouton(dessus, S, P, { alpha: courbe.sortie(seg(t, 3.0, 3.6)), pastille: seg(t, 3.45, 3.85) });
    onde(dessus, S, P, t, { alpha: courbe.sortie(seg(t, 3.25, 3.85)) });
  };
}

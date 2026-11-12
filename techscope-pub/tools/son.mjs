// Fabrique les trois bandes-son (audio/A.wav, B.wav, C.wav) et l'enveloppe de la voix (src/shared/env.js).
// Tout est synthétisé ici, sans échantillon extérieur ; seule la voix vient de audio/voix (moteur Pierre de TechScope).
// Usage : node tools/son.mjs
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { DUREE, IPS, VOIX, A, C } from '../src/shared/config.js';

const RACINE = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const SR = 48000, N = SR * DUREE, TAU = Math.PI * 2;

// Hasard reproductible : la même graine donne toujours le même bruit.
const hasard = graine => () => { graine |= 0; graine = graine + 0x6D2B79F5 | 0; let t = Math.imul(graine ^ graine >>> 15, 1 | graine); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; };

function piste() {
  const g = new Float32Array(N), d = new Float32Array(N);
  // Ajoute un son décrit par f(t local, i) entre t0 et t0+duree, avec un panoramique de -1 à 1.
  const ajoute = (t0, duree, f, gain = 1, pan = 0) => {
    const debut = Math.round(t0 * SR), n = Math.round(duree * SR), gg = gain * Math.cos((pan + 1) * Math.PI / 4), gd = gain * Math.sin((pan + 1) * Math.PI / 4);
    for (let i = 0; i < n; i++) { const k = debut + i; if (k < 0 || k >= N) continue; const v = f(i / SR, i); g[k] += v * gg * Math.SQRT2; d[k] += v * gd * Math.SQRT2; }
  };
  return { g, d, ajoute };
}

function lisVoix(nom) {
  const b = fs.readFileSync(path.join(RACINE, 'audio', 'voix', `${nom}.wav`));
  const sr = b.readUInt32LE(24), n = (b.length - 44) / 2, src = new Float32Array(n);
  for (let i = 0; i < n; i++) src[i] = b.readInt16LE(44 + i * 2) / 32768;
  const out = new Float32Array(Math.floor(n * SR / sr));   // rééchantillonnage linéaire vers 48 kHz
  for (let i = 0; i < out.length; i++) { const x = i * sr / SR, a = Math.floor(x), f = x - a; out[i] = src[a] * (1 - f) + (src[Math.min(n - 1, a + 1)] || 0) * f; }
  return out;
}

// Signature commune : l'accord TechScope (ré, la, fa dièse, mi) et la note de révélation.
const ACCORD = [146.83, 220, 369.99, 659.25];
function nappe(p, t0, gain = 0.05, attaque = 0.6) {
  ACCORD.forEach((f, i) => p.ajoute(t0, DUREE - t0, t => Math.min(1, t / attaque) * (Math.sin(TAU * f * t) + 0.5 * Math.sin(TAU * f * 1.003 * t + i)) * (0.8 + 0.2 * Math.sin(TAU * 0.3 * t + i)), gain / (1 + i * 0.35), i % 2 ? 0.4 : -0.4));
}
function note(p, t0, gain = 0.16) {
  p.ajoute(t0, 1.2, t => Math.exp(-t * 4.5) * (Math.sin(TAU * 1174.66 * t) + 0.35 * Math.sin(TAU * 2349.32 * t) * Math.exp(-t * 6)), gain);
}
// Coup sourd : une sinusoïde dont la hauteur chute très vite.
const coup = (p, t0, gain = 0.5, f0 = 60) => p.ajoute(t0, 0.35, t => Math.exp(-t * 14) * Math.sin(TAU * (f0 * t + 3 * (1 - Math.exp(-t * 30)))), gain);
function voix(p, version) {
  const seule = new Float32Array(N);
  for (const [nom, t0] of VOIX[version]) {
    const v = lisVoix(nom), debut = Math.round(t0 * SR);
    for (let i = 0; i < v.length && debut + i < N; i++) { seule[debut + i] += v[i]; p.g[debut + i] += v[i] * 0.9; p.d[debut + i] += v[i] * 0.9; }
  }
  return seule;
}

function versionA() {
  const p = piste(), r = hasard(11);
  // Rafale de clics secs qui s'accélère jusqu'à l'écrasement.
  for (let t = 0.02; t < A.ecrasementFin; t += 0.085 - 0.065 * Math.min(1, t / A.ecrasementFin)) {
    let avant = 0; const pan = r() * 1.6 - 0.8, ton = 0.5 + r();
    p.ajoute(t, 0.012, x => { const b = r() * 2 - 1, v = b - avant; avant = b; return v * Math.exp(-x * 500 * ton); }, 0.16, pan);
  }
  coup(p, A.claque, 0.55); coup(p, A.coupe, 0.5);
  // Montée en tension, coupée net.
  let etat = 0;
  p.ajoute(A.coupe, A.ecrasementFin - A.coupe, t => { const k = t / (A.ecrasementFin - A.coupe); etat += (r() * 2 - 1 - etat) * (0.02 + 0.5 * k * k); return k * k * (etat * 1.4 + 0.35 * Math.sin(TAU * (180 * t + 480 * t * t))); }, 0.3);
  note(p, A.note); coup(p, A.note, 0.35);
  nappe(p, 2.9);
  return { p, seule: voix(p, 'A') };
}

function versionB() {
  const p = piste(), r = hasard(22);
  // Souffle grave qui respire, puis laisse la place à l'accord.
  p.ajoute(0, 3.4, t => Math.min(1, t / 0.4) * Math.min(1, (3.4 - t) / 0.9) * (Math.sin(TAU * 55 * t) + 0.45 * Math.sin(TAU * 110.4 * t)) * (0.75 + 0.25 * Math.sin(TAU * 0.5 * t)), 0.12);
  let etat = 0;
  p.ajoute(0, 2.8, t => { etat += (r() * 2 - 1 - etat) * 0.015; return etat * Math.min(1, t / 0.5) * Math.min(1, (2.8 - t) / 0.6) * (0.6 + 0.4 * Math.sin(TAU * 0.5 * t)); }, 0.5);
  note(p, 2.5, 0.09);
  nappe(p, 2.5, 0.055, 0.9);
  return { p, seule: voix(p, 'B') };
}

function versionC() {
  const p = piste(), r = hasard(33);
  // Un « pop » par onglet, de plus en plus aigu.
  for (let i = C.depart; i < C.onglets; i++) { const f = 520 + i * 26; p.ajoute(C.apparition(i), 0.06, t => Math.exp(-t * 60) * Math.sin(TAU * (f * t + 2200 * t * t)), 0.2, (i / C.onglets) * 1.2 - 0.6); }
  // Tic-tac sur chaque saut du curseur.
  C.sauts.forEach(([t0], i) => p.ajoute(t0 + 0.14, 0.05, t => Math.exp(-t * 110) * Math.sin(TAU * (i % 2 ? 1500 : 1900) * t), 0.22, i % 2 ? 0.3 : -0.3));
  // Tension discrète sous le compteur.
  p.ajoute(1, 1.5, t => (t / 1.5) ** 2 * Math.sin(TAU * (220 + 60 * t) * t) * (0.5 + 0.5 * Math.sin(TAU * 8 * t)), 0.035);
  // Le clic.
  let avant = 0;
  p.ajoute(C.clic, 0.01, t => { const b = r() * 2 - 1, v = b - avant; avant = b; return v * Math.exp(-t * 600); }, 0.4);
  coup(p, C.clic, 0.4);
  note(p, C.clic + 0.12);
  nappe(p, C.clic + 0.12);
  return { p, seule: voix(p, 'C') };
}

function ecris(nom, { g, d }) {
  const b = Buffer.alloc(44 + N * 4), fondu = Math.round(0.06 * SR);
  b.write('RIFF', 0); b.writeUInt32LE(36 + N * 4, 4); b.write('WAVEfmt ', 8); b.writeUInt32LE(16, 16); b.writeUInt16LE(1, 20); b.writeUInt16LE(2, 22);
  b.writeUInt32LE(SR, 24); b.writeUInt32LE(SR * 4, 28); b.writeUInt16LE(4, 32); b.writeUInt16LE(16, 34); b.write('data', 36); b.writeUInt32LE(N * 4, 40);
  for (let i = 0; i < N; i++) {
    const f = Math.min(1, i / 240, (N - 1 - i) / fondu);   // pas de claquement au début ni à la fin
    b.writeInt16LE(Math.round(Math.tanh(g[i] * f) * 32000), 44 + i * 4);
    b.writeInt16LE(Math.round(Math.tanh(d[i] * f) * 32000), 46 + i * 4);
  }
  fs.writeFileSync(path.join(RACINE, 'audio', `${nom}.wav`), b);
}

// Enveloppe de la voix, une valeur par image : c'est elle qui anime l'onde à l'écran.
function enveloppe(seule) {
  const pas = SR / IPS, out = []; let lisse = 0;
  for (let i = 0; i < DUREE * IPS + 1; i++) {
    let s = 0; const a = Math.round(i * pas);
    for (let k = a; k < a + pas && k < N; k++) s += seule[k] * seule[k];
    const v = Math.sqrt(s / pas);
    lisse += (v - lisse) * (v > lisse ? 0.6 : 0.16);
    out.push(lisse);
  }
  const max = Math.max(...out) || 1;
  return out.map(v => Math.round(Math.min(1, v / max) ** 0.7 * 1000) / 1000);
}

const env = {};
for (const [nom, f] of [['A', versionA], ['B', versionB], ['C', versionC]]) {
  const { p, seule } = f();
  ecris(nom, p);
  env[nom] = enveloppe(seule);
  let cr = 0; for (let i = 0; i < N; i++) cr = Math.max(cr, Math.abs(p.g[i]), Math.abs(p.d[i]));
  console.log(`audio/${nom}.wav  crête ${cr.toFixed(2)}`);
}
fs.writeFileSync(path.join(RACINE, 'src', 'shared', 'env.js'),
  `// Fichier généré par tools/son.mjs : niveau de la voix, une valeur par image (${IPS} par seconde). Ne pas modifier à la main.\nexport const ENV = ${JSON.stringify(env)};\n`);

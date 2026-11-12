# TechScope — trois accroches publicitaires de 6 secondes

Trois débuts différents pour **une seule et même publicité** de [TechScope](https://github.com/Zakir310/TechScope), à tester en A/B/C.
Tout est fabriqué par code : images en Canvas 2D et WebGL, son synthétisé, voix « Pierre » de l'extension elle-même.

**Promesse commune** : *Toute l'actu tech. En une minute.*

| Version | Idée | Direction artistique | Technique |
|---|---|---|---|
| **A — Choc**, « Le mur » | Un mur de titres s'écrase en un seul trait, qui devient la voix. | Noir et blanc brutal, Anton en capitales, coupes sèches. | Typographie cinétique, Canvas 2D |
| **B — Curiosité**, « 07:00 » | Une forme lumineuse parle dans le noir ; c'était le bouton de lecture. | Très sombre, lumière verte, serif italique, mouvements lents. | Shader GLSL (WebGL) piloté par le niveau de la voix |
| **C — Problème / solution**, « Dix onglets » | Les onglets se multiplient, 47 non lus ; un clic replie tout dans un bouton. | Interface claire dessinée à plat, guidée par le curseur. | Dessin vectoriel d'interface, Canvas 2D |

## Structure, identique pour les trois

| Temps | Rôle | Contenu |
|---|---|---|
| 0,0 – 1,0 s | Captation | propre à chaque version |
| 1,0 – 2,5 s | Intrigue | propre à chaque version |
| 2,5 – 4,0 s | Révélation | l'onde de la voix et le bouton « Écouter mon briefing » apparaissent |
| 4,0 – 5,0 s | Impact | « Toute l'actu tech. En une minute. » |
| 5,0 – 6,0 s | Transition | logo TechScope, lente avancée de caméra vers la suite |

À partir de 4,0 s, les trois versions sont dessinées par le même code (`dessineFin` dans `src/shared/commun.js`) :
la suite de la publicité se raccorde donc de la même façon aux trois. Seule la hauteur des barres de l'onde diffère
en B, parce que la voix n'y parle pas aux mêmes instants.

## Dossier

```
exports/9x16|1x1|16x9/   les 18 vidéos : 3 versions × 3 formats, avec son et « _sans-son »
storyboards/             un storyboard par version + planches de contrôle (une image toutes les 0,5 s)
src/scene.html           la page qui joue une accroche (?v=A|B|C)
src/a-mur.js             version A
src/b-0700.js            version B
src/c-onglets.js         version C
src/shared/config.js     TEXTES, COULEURS, INSTANTS — le fichier à modifier en premier
src/shared/commun.js     fond, onde, bouton, promesse, logo : l'image finale commune
src/shared/core.js       courbes d'animation, hasard reproductible, démarrage
src/shared/env.js        niveau de la voix image par image (généré par tools/son.mjs)
audio/A.wav B.wav C.wav  les trois bandes-son ; audio/voix/ : les répliques de Pierre
tools/                   serveur.mjs (aperçu), son.mjs (bandes-son), rendu.mjs (vidéos), voix.cjs (répliques)
```

## Lancer

Il faut Node 20 ou plus récent, `ffmpeg`, et Playwright avec Chromium (`npm i -D playwright && npx playwright install chromium`).

```bash
npm run apercu                      # aperçu en direct sur http://localhost:5173/src/scene.html?v=A (clic = son)
npm run son                         # refabrique les trois bandes-son et l'enveloppe de la voix
npm run rendu                       # refait les 18 vidéos (environ 15 minutes)
node tools/rendu.mjs B 9x16         # une seule version, un seul format
node tools/rendu.mjs --planche      # seulement les planches de contrôle
```

Le rendu est déterministe : chaque image est calculée pour un instant exact (`window.image(t)`), jamais en temps réel,
et tout hasard vient d'une graine fixe. Deux rendus donnent les mêmes images.

## Modifier

- **Textes** : `TEXTES` dans `src/shared/config.js` (promesse, bouton, titres du mur, mots de la version B…).
- **Couleurs** : `COULEURS` dans le même fichier ; elles reprennent le thème vert de l'extension.
- **Instants** : `TEMPS` (structure commune), `A`, `C` et `VOIX` dans le même fichier. Après un changement de `VOIX`, `A` ou `C`, relancer `npm run son` : le son et l'image lisent les mêmes valeurs.
- **Animations** : chaque version tient dans un seul fichier, avec une fonction `dessine(t)` découpée selon la structure ci-dessus. `seg(t, début, fin)` donne l'avancement de 0 à 1 entre deux instants ; `courbe.*` donne l'accélération.
- **Ce que dit la voix** : `REPLIQUES` dans `tools/voix.cjs`, puis `node tools/voix.cjs <dossier extension de TechScope> <dossier contenant piper.onnx>` et `npm run son`. Le modèle `piper.onnx` (77 Mo) est celui que l'extension télécharge ; son adresse est dans `extension/piper.js`.
- **Formats** : `FORMATS` dans `tools/rendu.mjs`. Les scènes se recomposent seules selon la largeur et la hauteur.

## Son

Chaque version a sa signature (A : rafale de clics, montée, silence ; B : souffle grave ; C : « pops » d'onglets, tic-tac, clic),
et toutes finissent sur le même accord et la même note de révélation. Aucun échantillon extérieur : tout est synthétisé dans `tools/son.mjs`.
Les versions `_sans-son` sont les mêmes images sans piste audio ; chaque accroche se comprend par ses textes seuls.

## Licences et mentions

- Polices : Instrument Serif, Anton et Inter, licence SIL OFL 1.1 (textes dans `src/fonts/`).
- Voix **Pierre** : moteur Piper, corpus UPMC, licence **CC BY-SA 4.0** — à créditer à la diffusion (par exemple dans la description de la publicité : « Voix de synthèse : Piper, corpus UPMC, CC BY-SA 4.0 »).
- Les noms des médias apparaissent en texte seul, sans logo ; ils restent la propriété de leurs éditeurs. Les titres du mur (version A) sont inventés et ne sont attribués à aucun média.
- Icône et identité visuelle : TechScope.

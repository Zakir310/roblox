# Analyse de « +1 Plane Flight » (Satisfying Bubble Pop) — et transposition en jeu de fusées

> Jeu source : https://www.roblox.com/games/111780058106351/1-Plane-Flight
> Genre Roblox : « Incremental Simulator » de la famille **+1** (+1 Paper Plane, +1 Stone Skipping, +1 Blade, +1 Speed...).
> Le jeu est sorti fin octobre 2026, il n'a pas encore de wiki. Cette analyse repose sur la fiche du jeu
> et sur le modèle commun à tous les jeux « +1 », que ce studio reproduit quasiment à l'identique.
> Les points marqués **[À CONFIRMER]** seront ajustés avec tes captures d'écran.

---

## 1. La boucle de jeu (ce que le joueur fait en boucle)

```
   ┌──────────────────────────────────────────────────────────────┐
   │  1. S'ENTRAÎNER  →  gagne de la PUISSANCE (Power)             │
   │  2. LANCER l'avion →  vole une DISTANCE = f(Power × multis)   │
   │     • +1 VOL (Flights) à chaque lancer                        │
   │     • atterrit dans une ZONE  →  gagne des WINS               │
   │  3. DÉPENSER les Wins  →  œufs (pets), avions, boosts          │
   │  4. DÉBLOQUER des zones plus loin  →  plus de Wins            │
   │  5. REBIRTH  →  remet Power/Flights à zéro, multiplicateur ×  │
   │  → retour en 1 avec un multiplicateur plus gros               │
   └──────────────────────────────────────────────────────────────┘
```

C'est une boucle « idle/incrémental » : rien n'est difficile, tout est question de **nombres qui montent** et de
**feedback visuel satisfaisant** (le « +1 » qui pop, les chiffres énormes, les effets dorés).

### Les 3 monnaies / statistiques

| Stat | Comment on la gagne | À quoi elle sert |
|---|---|---|
| **Power (Puissance)** | En s'entraînant (clic maintenu ou clics répétés sur une zone d'entraînement) | Détermine la distance de vol. Remise à 0 au rebirth |
| **Flights (Vols)** | +1 par lancer (× multiplicateurs) | Score affiché, classement, condition de rebirth **[À CONFIRMER]** |
| **Wins (Victoires)** | En atterrissant dans une zone (plus la zone est loin, plus ça paye) | Monnaie principale : œufs, avions, zones, rebirth |

Il y a parfois une 4e monnaie premium (Gems / Diamants) achetée en Robux ou gagnée via les quêtes **[À CONFIRMER]**.

### Formule type de distance

```
distance = Power × multiAvion × multiPets × multiRebirth × multiGamepass × (bonus lancer parfait)
```

Les jeux « +1 » utilisent une **croissance exponentielle** des coûts (×1,5 à ×2 par palier) et une croissance
linéaire-ish des gains, ce qui crée le mur qui pousse à faire un rebirth ou à acheter.

---

## 2. La map (structure typique)

```
   [LOBBY / HUB]                      [PISTE DE LANCER — très longue, droite]
   ┌────────────────┐    ───────────────────────────────────────────────────────►
   │ spawn          │    │ Zone 1 │ Zone 2 │ Zone 3 │ Zone 4 │ ... │ Zone N │
   │ zone d'entraîn.│    │ 0-100  │100-500 │500-2k  │ 2k-10k │     │        │
   │ pad de lancer ─┼──► │ aéroport│ ville │ désert │ neige  │ ... │ espace │
   │ boutique (PNJ) │    repères de distance au sol tous les X studs
   │ œufs (PNJ)     │
   │ panneaux rebirth│
   │ leaderboards   │
   └────────────────┘
```

- **Hub compact** : tout est à 10 secondes de marche. Un pad « LANCER » bien visible, des pads « ENTRAÎNEMENT »
  (souvent plusieurs, chacun exigeant un niveau de Power minimum et donnant plus de Power/clic), des PNJ ou
  panneaux pour la boutique et les œufs.
- **La piste** : une ligne droite immense (10 000 à 100 000+ studs), découpée en **zones thématiques**
  (aéroport → ville → montagne → nuages → espace...). Chaque zone a un portail/panneau avec son nom et sa
  récompense en Wins. Des **repères de distance** (panneaux « 1 000 », « 5 000 ») sont posés au sol.
- **Zones verrouillées** : certaines zones demandent un achat en Wins ou un nombre de rebirths pour être
  « débloquées » (sinon l'avion s'arrête à la frontière) **[À CONFIRMER]**.
- **Leaderboards** : 2 à 4 panneaux géants dans le hub (Top Flights, Top Wins, Top Distance, Top Rebirths).
- **StreamingEnabled** activé : la piste est longue, Roblox ne charge que ce qui est proche.

---

## 3. Le lancer et la cinématique (le cœur du « feel »)

Séquence typique quand le joueur appuie sur LANCER :

1. **Préparation (0,3 s)** : le personnage joue une animation « bras en arrière », petit zoom caméra, son de « whoosh » chargé.
2. **Lancer** : l'avion est créé **côté client** (pour la fluidité) et part en avant. La caméra **décroche du
   personnage** et suit l'avion (CFrame interpolé, légèrement derrière et au-dessus, FOV qui s'élargit avec la vitesse).
3. **Vol** : particules de traînée, le compteur de distance monte en gros à l'écran, à chaque franchissement
   de zone un texte « ZONE : Désert ! +50 Wins » pop au milieu. Léger tremblement de caméra à grande vitesse.
4. **Atterrissage** : l'avion ralentit, touche le sol, petite explosion de particules, **gros panneau de résultat** :
   « 2 450 studs ! » + « +1 Vol » + « +120 Wins » avec des chiffres qui comptent vite (tween).
5. **Retour** : fondu noir 0,3 s, le personnage est téléporté au pad, la caméra revient. Total ~4 à 8 secondes.
6. **Validation serveur** : le serveur ne fait **pas confiance** au client : il recalcule la distance à partir du
   Power et des multiplicateurs connus, attribue les Wins et le +1 Flight, puis réplique aux autres joueurs un
   avion « fantôme » simplifié pour qu'ils voient le lancer.

Variante « Auto-Lancer » (gamepass) : la séquence est raccourcie et boucle toute seule.

---

## 4. Les systèmes secondaires

### Entraînement
- Pad au sol, le joueur clique (ou maintient) → `+X Power` flottant au-dessus de la tête, animation de
  musculation/haltère, son « ding ».
- Plusieurs pads : chacun a un prérequis (ex. 1 000 Power) et un gain plus élevé.
- Gamepass « Auto-Train » fréquent.

### Avions (équivalent des « armes/skins »)
- Liste de 10 à 30 avions, chacun avec un **multiplicateur de distance** et un coût en Wins (ou Robux pour les
  exclusifs). Papier → jouet → jet → doré → arc-en-ciel → galaxie...
- Un seul équipé à la fois. Débloqués dans un menu « Index/Avions » avec prévisualisation 3D (ViewportFrame).

### Pets (animaux)
- Œufs achetés en Wins dans chaque zone (plus la zone est loin, plus les pets sont forts).
- Rareté : Commun / Rare / Épique / Légendaire / Mythique, avec % d'obtention affiché.
- Chaque pet donne un multiplicateur (Power et/ou Wins). 3 à 4 équipés max (plus avec gamepass).
- **Fusion** : 3 pets identiques → version Gold, puis Rainbow (multi ×2/×3).
- Inventaire avec tri, équiper/déséquiper, supprimer, « équiper les meilleurs ».

### Rebirth
- Condition : atteindre N Flights ou N Wins. Reset Power (et parfois Flights), garde pets/avions/zones.
- Donne +X% multiplicateur permanent et débloque parfois des zones/pads.
- Coût croissant : rebirth 1 = 1 000, rebirth 2 = 2 500, etc.

### Quêtes / Objectifs journaliers **[À CONFIRMER]**
- « Lance 50 fois », « Atteins la zone 3 » → récompenses Wins/Gems. Souvent avec un timer.

### Codes
- Menu « Codes » : saisie texte → récompense (Wins, boost temporaire).

### Boosts / Potions
- Boost temporaire ×2 Wins pendant 15 min, acheté en Gems ou offert via une roue de la chance.

---

## 5. La boutique (monétisation, très standard chez ce studio)

| Type | Exemples | Prix typique |
|---|---|---|
| **Gamepasses** (permanents) | 2× Wins, 2× Power, Auto-Lancer, Auto-Train, +2 emplacements pets, Lucky (meilleure chance aux œufs), VIP | 99 à 799 Robux |
| **Developer Products** (consommables) | Packs de Wins (×5 paliers), Packs de Gems, « Rebirth instantané », Boost ×2 pendant 1 h | 49 à 2 499 Robux |
| **Avions exclusifs** | Avion doré ×5 distance | 199 à 499 Robux |
| **Pets exclusifs** | Pet Robux ×10 | 399 à 999 Robux |

La boutique est un **gros menu à onglets** (Gamepasses / Wins / Gems / Exclusifs), avec des cartes colorées,
un badge « MEILLEURE OFFRE », et une **offre de bienvenue avec compte à rebours** qui apparaît quelques minutes
après l'arrivée du joueur **[À CONFIRMER]**.

---

## 6. Le HUD (interface en jeu)

Disposition typique des jeux « +1 » (mobile-first, boutons gros et ronds) :

```
 ┌─────────────────────────────────────────────────────────────┐
 │ [✈ 1 240 Vols] [🏆 58,2k Wins] [💪 3,4M Power]   [⚙] [🎁 offre]│  ← barre du haut (monnaies)
 │                                                             │
 │ [🛒]                                                        │
 │ [🐾]  ← colonne gauche : Boutique, Pets, Avions,            │
 │ [✈ ]     Rebirth, Codes, Quêtes, Index, Paramètres          │
 │ [🔁]                                                        │
 │ [🎟]                        (vue 3D)                        │
 │ [📜]                                                        │
 │                                                             │
 │                 ┌─────────────────────────┐                 │
 │                 │  LANCER  ✈  (bouton XXL)│                 │  ← bas centre, mobile
 │                 └─────────────────────────┘                 │
 │      « +1 »  « +1 »  textes flottants qui montent           │
 └─────────────────────────────────────────────────────────────┘
```

- Nombres formatés avec abréviations (1,2k / 3,4M / 5B).
- Chaque bouton a un **tween « bounce »** au survol/clic, icônes épaisses avec contour noir (style Gotham Black).
- Les menus s'ouvrent avec un **scale 0 → 1,05 → 1** en 0,25 s et un fond assombri.
- Textes flottants « +1 » / « +50 Wins » qui montent et disparaissent (BillboardGui ou ScreenGui).
- Sur mobile, les boutons font ≥ 44 px.

---

## 7. Animations et effets

| Élément | Technique Roblox |
|---|---|
| Lancer / entraînement | `Animation` + `Animator:LoadAnimation()` sur le personnage, animations custom uploadées |
| Vol de l'avion | Côté client : `RunService.RenderStepped` ou `TweenService` sur un CFrame le long de la piste, courbe de vitesse |
| Caméra cinématique | `Camera.CameraType = Scriptable`, CFrame interpolé qui suit l'avion, FOV tweené, `Humanoid` masqué |
| Particules | `ParticleEmitter` (traînée, confettis à l'atterrissage), `Trail` sur l'avion |
| Effets UI | `TweenService` sur `Size`/`Position`/`Rotation`, `UIStroke`, `UIGradient` animé (brillance dorée) |
| Textes flottants | `BillboardGui` cloné, tweené vers le haut, détruit après 1 s |
| Sons | `SoundService` + sons courts (pop, ding, whoosh, cash) |
| Chiffres qui comptent | boucle qui interpole la valeur affichée vers la vraie valeur |
| Pets qui suivent | `AlignPosition`/`AlignOrientation` ou CFrame lerp vers un offset derrière le joueur, flottement sinusoïdal |

---

## 8. Architecture technique (comment c'est codé en coulisses)

```
ReplicatedStorage/
  Shared/
    Config/          ← tables de données : Zones, Planes, Pets, Eggs, Gamepasses, Rebirths
    Types.luau       ← types partagés (strict)
    Remotes/         ← RemoteEvents / RemoteFunctions nommés
    Util/            ← FormatNumber, Tween helpers, Signal
ServerScriptService/
  Server/
    DataService      ← DataStore + ProfileService-like (session lock, autosave, BindToClose)
    TrainService     ← valide les clics d'entraînement (rate limit)
    LaunchService    ← calcule la distance, attribue Flights/Wins, réplique le vol
    ShopService      ← MarketplaceService, ProcessReceipt, gamepasses
    PetService       ← œufs (RNG serveur), fusion, équipement
    RebirthService
    LeaderboardService ← OrderedDataStore, refresh toutes les 60 s
StarterPlayer/StarterPlayerScripts/
  Client/
    Controllers/     ← HudController, ShopController, PetsController, LaunchCinematic, TrainController
    UI/              ← composants d'interface
```

Règle d'or : **le client n'envoie que des intentions** (« je veux lancer », « je clique pour m'entraîner »),
le serveur calcule tout et renvoie l'état. Sinon le jeu est exploité en 24 h.

---

## 9. Transposition en jeu de FUSÉES — « +1 Rocket Launch »

| Dans +1 Plane Flight | Dans ton jeu de fusées |
|---|---|
| Lancer un avion | **Lancer une fusée** (décollage vertical puis trajectoire qui s'incline, ou vol vertical pur « altitude ») |
| Distance (studs) | **Altitude** (mètres / km) — la piste devient une **colonne verticale** de zones |
| Power | **Carburant / Poussée** (gagné en s'entraînant ou en « remplissant » la fusée) |
| Flights (+1 Vol) | **+1 Lancement** |
| Wins | **Étoiles** (ou « Orbits ») |
| Zones : aéroport, ville, désert... | **Couches** : pas de tir → nuages → stratosphère → orbite → Lune → Mars → ceinture d'astéroïdes → Soleil → trou noir |
| Avions (skins ×multi) | **Fusées** : pétard → fusée en carton → V2 → Saturn V → navette → Starship → fusée dorée → fusée galaxie |
| Pets | **Astronautes / aliens / satellites** compagnons qui orbitent autour du joueur |
| Rebirth | **« Nouvelle mission »** / Prestige, avec insigne de mission |
| Entraînement (haltères) | **Pompe à carburant** (clic = +X carburant) ou **banc d'essai moteur** |
| Lancer parfait | **Compte à rebours 3-2-1** avec timing parfait = bonus ×1,5 |

**Choix important à prendre : vol vertical ou vol horizontal ?**
- *Vertical* (la fusée monte, la caméra suit vers le haut, les zones sont empilées en altitude) : plus
  fidèle au thème, très spectaculaire, mais la map est une colonne (plus simple à construire, moins à explorer à pied).
- *Horizontal* (la fusée décolle puis s'incline et file le long d'une piste comme l'avion) : copie quasi 1:1 de
  +1 Plane Flight, on garde la map en ligne. Le plus simple pour commencer.
- **Recommandation** : **vertical** pour la cinématique (c'est ce qui fera la différence), mais avec le hub au sol
  et des **portails** vers chaque couche pour que les joueurs puissent visiter/s'entraîner dans les zones.

---

## 10. Plan de construction proposé (ordre de travail)

1. **Mise en place du projet** : Rojo, structure des dossiers, types strict, outils (Selene/StyLua), GitHub Actions.
2. **Données joueur** : DataStore sécurisé (session lock, autosave, migration de schéma).
3. **Config du jeu** : tables Zones, Fusées, Pets, Œufs, Rebirths, Gamepasses — tout l'équilibrage à un seul endroit.
4. **Entraînement** : pads, validation serveur, textes flottants, animation.
5. **Lancement** : calcul serveur, cinématique client (caméra, particules, panneau de résultat), réplication fantôme.
6. **HUD** : barre de monnaies, colonne de boutons, bouton LANCER, formatage des nombres, tweens.
7. **Zones** : détection de la zone d'atterrissage, panneaux, portails, verrouillage.
8. **Fusées** (skins) : index avec aperçu 3D, équipement, multiplicateurs.
9. **Pets** : œufs, RNG serveur, inventaire, équipement, fusion, suivi 3D.
10. **Rebirth** : conditions, reset, multiplicateurs.
11. **Boutique** : gamepasses, developer products, ProcessReceipt idempotent, offre de bienvenue.
12. **Leaderboards**, codes, quêtes, sons, polish.
13. **Map** dans Studio (guidée pas à pas) : hub, couches, décor.

Chaque étape produit quelque chose de testable dans Studio avant de passer à la suivante.

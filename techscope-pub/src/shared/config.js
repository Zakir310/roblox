// Réglages communs aux trois accroches. Ce fichier est lu par le navigateur (images) et par Node (son) :
// changer un texte, une couleur ou un instant ici le change partout.

export const DUREE = 6;   // secondes, immuable
export const IPS = 60;    // images par seconde

// Structure imposée, identique pour A, B et C.
export const TEMPS = { captation: 0, intrigue: 1, revelation: 2.5, impact: 4, transition: 5, fin: 6 };

export const TEXTES = {
  marque: 'TechScope',
  bouton: 'Écouter mon briefing',
  promesse: ['Toute l’actu tech.', 'En une minute.'],
  // Version A
  a_sources: '14 SOURCES.',
  a_articles: ['312 ARTICLES', 'CE MATIN.'],
  a_minute: '1 MINUTE.',
  a_titres: [
    'NOUVELLE PUCE IA', 'FAILLE CRITIQUE CORRIGÉE', 'LE PLIABLE ARRIVE', 'MISE À JOUR MAJEURE', 'RECORD DE VITESSE',
    'UN MODÈLE PLUS RAPIDE', 'FUITE DE DONNÉES', 'CARTE GRAPHIQUE DÉVOILÉE', 'LEVÉE DE FONDS', 'NOUVEAU NAVIGATEUR',
    'ROBOT HUMANOÏDE', 'BATTERIE DEUX JOURS', 'PROCESSEUR 2 NM', 'RANÇONGICIEL STOPPÉ', 'ÉCRAN ENROULABLE'
  ],
  // Version B
  b_heure: '07:00',
  b_bonjour: 'Bonjour.',
  b_mots: ['IA', 'Mobile', 'Cybersécurité'],
  // Version C
  c_non_lus: 'non lus'
};

export const SOURCES = ['The Verge', 'TechCrunch', 'Ars Technica', 'Tom’s Hardware', 'TechNode', 'SCMP Tech', 'Rest of World',
  'BleepingComputer', 'OpenAI', 'Google AI', 'NVIDIA', 'Numerama', 'Frandroid', '01net'];

// Couleurs reprises du thème vert de l'extension (theme-green.css).
export const COULEURS = {
  fond: ['#040e0a', '#06170f', '#0a2a1d', '#15503a'],
  lueurVerte: 'rgba(84,190,140,',   // + alpha
  lueurChaude: 'rgba(176,108,52,',
  texte: '#eef6f0',
  accent: '#9dffb9',
  ondeHaut: '#d4ffdc',
  ondeBas: '#38dd86',
  boutonHaut: 'rgba(185,247,123,.30)',
  boutonBas: 'rgba(120,200,110,.12)',
  boutonBord: 'rgba(215,255,228,.30)',
  boutonTexte: '#efffe0',
  clairFond: ['#f7fbf7', '#eaf5ee', '#cfe9da'],
  clairTexte: '#12241b',
  alerte: '#e5484d'
};

// Répliques de la voix Pierre : [fichier dans audio/voix, instant de départ en secondes].
export const VOIX = {
  A: [['complet', 3.55]],
  B: [['bonjour', 0.25], ['ia', 1.05], ['mobile', 1.62], ['cyber', 2.25], ['minute', 4.4]],
  C: [['complet', 3.55]]
};

// Version A : instants clés.
export const A = { claque: 0.12, coupe: 1.0, ecrasementDebut: 1.7, ecrasementFin: 2.45, note: 2.62 };

// Version C : les onglets. 3 au départ, 28 à la fin de la première seconde, de plus en plus vite.
export const C = {
  onglets: 28,
  depart: 3,
  apparition: i => i < 3 ? -1 : 0.05 + 0.92 * Math.pow((i - 2) / 25, 0.6),
  sauts: [[1.0, 5], [1.25, 19], [1.5, 11], [1.75, 24], [2.0, 8]],   // [instant, onglet visé]
  nonLus: [19, 47],
  clic: 2.5
};

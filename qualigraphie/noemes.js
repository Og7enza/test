// Noōgraphie — la qualigraphie du langage Noōs
// ------------------------------------------------------------------
// Chaque « noème » (unité de pensée) est un dessin au trait, tracé
// dans un champ carré de 120×120. Les glyphes sont composés à partir
// d'un petit alphabet de TRAITS PRIMITIFS (voir CONCEPT.md) afin que
// l'écriture reste cohérente et « manuscrite » : même graisse, mêmes
// terminaisons rondes, même respiration.
//
// Ce fichier est la SOURCE unique. `build.js` en dérive :
//   - les SVG individuels (glyphes/*.svg)
//   - la planche spécimen (planche.svg)
//   - la vitrine interactive (index.html)
//
// Un glyphe = un tableau d'« éléments » SVG bruts (path/circle/line…)
// SANS attributs de style : le style (couleur, graisse, bouts ronds)
// est ajouté par l'enrobage, ce qui garantit l'unité visuelle.

export const VIEWBOX = 120;

// Les 10 traits primitifs, nommés. Ils ne servent pas au rendu direct
// mais documentent la « clé de construction » de chaque noème.
export const TRAITS = [
  ["Le champ",   "▢", "le carré conceptuel qui accueille la pensée"],
  ["L'arc",      "⌒", "la perception : une courbe ouverte vers le haut"],
  ["La tige",    "│", "la genèse, la croissance verticale"],
  ["Le crochet", "✓", "le retour sur soi, la vérification"],
  ["La spirale", "@", "l'absorption vers l'intérieur, l'apprentissage"],
  ["La coupe",   "∪", "le contenant, la mémoire qui garde"],
  ["Le lien",    "—", "la relation entre deux nœuds"],
  ["La fourche", "Y", "la divergence, le partage vers l'extérieur"],
  ["La croix",   "✕", "la coupure, la négation, l'effacement"],
  ["Le point",   "•", "l'atome d'objet, la graine de sens"],
];

// --------------------------------------------------------------------
// VERBES — primitives cognitives. 1 trait dominant = 1 action.
// --------------------------------------------------------------------
export const VERBES = [
  {
    id: "observer", code: "O", nom: "Observer", trait: "L'arc",
    sens: "Percevoir le réel, ouvrir un regard sur ce qui est.",
    els: [
      'M 22 60 Q 60 24 98 60',   // paupière haute
      'M 22 60 Q 60 96 98 60',   // paupière basse
      '<circle cx="60" cy="60" r="9"/>', // pupille
    ],
  },
  {
    id: "comparer", code: "C", nom: "Comparer",
    trait: "Le lien + symétrie",
    sens: "Mettre deux choses en balance pour peser la différence.",
    els: [
      'M 60 26 V 44',            // pivot
      'M 26 44 H 94',            // fléau
      'M 30 44 Q 22 66 38 66',   // plateau gauche
      'M 90 44 Q 82 66 98 66',   // plateau droit (dissymétrie voulue)
      'M 34 66 H 34.01',
    ],
  },
  {
    id: "creer", code: "+", nom: "Créer", trait: "La tige",
    sens: "Faire naître ce qui n'existait pas ; une pousse qui monte.",
    els: [
      'M 60 100 V 42',
      'M 60 66 Q 38 60 40 38',   // feuille gauche
      'M 60 58 Q 82 52 80 30',   // feuille droite
    ],
  },
  {
    id: "verifier", code: "?", nom: "Vérifier", trait: "Le crochet",
    sens: "Éprouver la validité, revenir vérifier sa trace.",
    els: [
      'M 26 62 L 48 84 L 92 30',
      'M 92 30 Q 100 22 91 22',  // petit crochet de retour
    ],
  },
  {
    id: "apprendre", code: "!", nom: "Apprendre", trait: "La spirale",
    sens: "Absorber vers l'intérieur, enrouler le savoir sur soi.",
    els: [
      'M 90 56 C 90 26 46 22 38 54 C 32 78 66 86 74 62 C 79 47 60 42 56 56 C 54 63 63 66 65 60',
    ],
  },
  {
    id: "memoriser", code: "M", nom: "Mémoriser", trait: "La coupe",
    sens: "Déposer et garder ; un vase qui retient.",
    els: [
      'M 30 46 V 78 Q 30 92 44 92 H 76 Q 90 92 90 78 V 46',
      'M 24 46 H 96',            // couvercle
    ],
  },
  {
    id: "partager", code: "P", nom: "Partager", trait: "La fourche",
    sens: "Émettre vers l'extérieur ; un flux qui se divise.",
    els: [
      'M 60 98 V 62',
      'M 60 62 Q 44 46 34 30',   // branche gauche
      'M 34 30 L 42 34 M 34 30 L 34 40',
      'M 60 62 Q 76 46 86 30',   // branche droite
      'M 86 30 L 78 34 M 86 30 L 86 40',
    ],
  },
  {
    id: "relier", code: "=", nom: "Relier", trait: "Le lien",
    sens: "Nouer deux nœuds : établir une relation.",
    els: [
      '<circle cx="32" cy="60" r="11"/>',
      '<circle cx="88" cy="60" r="11"/>',
      'M 43 60 H 77',
    ],
  },
  {
    id: "fusionner", code: "&", nom: "Fusionner", trait: "La convergence",
    sens: "Deux gestes qui deviennent un seul.",
    els: [
      'M 28 28 Q 56 54 60 62',
      'M 92 28 Q 64 54 60 62',
      'M 60 62 V 98',
    ],
  },
  {
    id: "supprimer", code: "X", nom: "Supprimer", trait: "La croix",
    sens: "Trancher, effacer ; une croix rompue au centre.",
    els: [
      'M 28 28 L 50 50', 'M 70 70 L 92 92',
      'M 92 28 L 70 50', 'M 50 70 L 28 92',
    ],
  },
];

// --------------------------------------------------------------------
// OBJETS — les référents. Un socle de sens, placé dans le bas du champ
// quand il est composé à un verbe (voir la clé de composition).
// --------------------------------------------------------------------
export const OBJETS = [
  {
    id: "monde", code: "w", nom: "Monde", trait: "L'arc fermé",
    sens: "Le réel, le tout observable.",
    els: [
      '<circle cx="60" cy="60" r="34"/>',
      'M 26 60 H 94',
      'M 60 26 Q 44 60 60 94',
      'M 60 26 Q 76 60 60 94',
    ],
  },
  {
    id: "memoire", code: "m", nom: "Mémoire", trait: "Les couches",
    sens: "Le magasin des traces (objet), distinct du verbe Mémoriser.",
    els: [
      '<circle cx="60" cy="60" r="12"/>',
      '<circle cx="60" cy="60" r="23"/>',
      '<circle cx="60" cy="60" r="34"/>',
    ],
  },
  {
    id: "connaissance", code: "k", nom: "Connaissance", trait: "Le rayon",
    sens: "Le savoir : un foyer qui rayonne.",
    els: [
      '<circle cx="60" cy="60" r="8"/>',
      'M 60 24 V 40', 'M 60 96 V 80',
      'M 24 60 H 40', 'M 96 60 H 80',
      'M 35 35 L 46 46', 'M 85 85 L 74 74',
      'M 85 35 L 74 46', 'M 35 85 L 46 74',
    ],
  },
  {
    id: "probleme", code: "p", nom: "Problème", trait: "Le nœud",
    sens: "Ce qui résiste : un entrelacs.",
    els: [
      'M 34 74 C 30 40 88 40 74 66 C 64 84 40 62 60 46 C 72 36 84 48 82 62',
    ],
  },
  {
    id: "solution", code: "s", nom: "Solution", trait: "La clé",
    sens: "Ce qui ouvre : une clé.",
    els: [
      '<circle cx="44" cy="44" r="16"/>',
      'M 55 55 L 88 88',
      'M 88 88 L 96 80', 'M 76 76 L 84 68',
    ],
  },
  {
    id: "hypothese", code: "h", nom: "Hypothèse", trait: "Le pointillé",
    sens: "Le provisoire, le non encore éprouvé.",
    dash: true,
    els: [
      'M 60 24 L 96 60 L 60 96 L 24 60 Z',
    ],
  },
  {
    id: "utilisateur", code: "u", nom: "Utilisateur", trait: "La figure",
    sens: "L'humain avec qui l'on parle.",
    els: [
      '<circle cx="60" cy="40" r="15"/>',
      'M 30 92 Q 60 60 90 92',
    ],
  },
  {
    id: "blockchain", code: "b", nom: "Blockchain", trait: "La chaîne",
    sens: "Le registre inaltérable : des blocs chaînés.",
    els: [
      '<rect x="26" y="46" width="36" height="36" rx="9"/>',
      '<rect x="58" y="46" width="36" height="36" rx="9"/>',
      'M 62 64 H 58',
    ],
  },
];

// --------------------------------------------------------------------
// PENSÉES — noèmes composites (macros). Un dessin = un raisonnement.
// Ce sont les symboles Ω Φ Ψ Δ α réinterprétés dans la Noōgraphie.
// --------------------------------------------------------------------
export const PENSEES = [
  {
    id: "omega", code: "Ω", nom: "Le Cycle",
    formule: "O → C → + → ? → ! → M",
    sens: "Le raisonnement complet : observer, comparer, créer, vérifier, apprendre, mémoriser — bouclé.",
    els: [
      // anneau ouvert (le cycle qui se relance)
      'M 84 40 A 34 34 0 1 1 78 34',
      // flèche de flux
      'M 78 34 L 88 33 M 78 34 L 82 44',
      // six encoches = six étapes
      'M 60 26 V 34', 'M 92 45 L 85 49', 'M 92 78 L 85 74',
      'M 60 94 V 86', 'M 28 78 L 35 74', 'M 28 45 L 35 49',
    ],
  },
  {
    id: "phi", code: "Φ", nom: "La Découverte",
    formule: "Ow · C · +h · ? · !k",
    sens: "« Découvrir une nouvelle connaissance fiable. » Un œil dans l'axe du savoir, couronné de rayons.",
    els: [
      'M 60 18 V 102',                  // l'axe (la tige de Φ)
      '<circle cx="60" cy="60" r="26"/>',// la boucle
      // œil au centre (observation validée)
      'M 44 60 Q 60 48 76 60', 'M 44 60 Q 60 72 76 60',
      '<circle cx="60" cy="60" r="4.5"/>',
      // rayons de connaissance au sommet
      'M 60 18 L 52 10', 'M 60 18 L 68 10', 'M 60 18 L 60 8',
    ],
  },
  {
    id: "psi", code: "Ψ", nom: "La Résolution",
    formule: "Cm · Op · +s",
    sens: "« Résoudre un problème à partir de la mémoire existante. » Un trident dont le pied puise dans la coupe-mémoire et tend vers la clé.",
    els: [
      'M 60 100 V 54',                 // hampe
      'M 34 44 V 62',                  // dent gauche
      'M 86 44 V 62',                  // dent droite
      'M 34 62 Q 60 78 86 62',         // arc reliant les dents
      // coupe-mémoire à la base
      'M 46 100 Q 46 112 60 112 Q 74 112 74 100',
      // éclat de solution au sommet
      'M 60 54 L 52 40', 'M 60 54 L 68 40', 'M 60 44 L 60 34',
    ],
  },
  {
    id: "delta", code: "Δ", nom: "La Correction",
    formule: "?k · X · +k",
    sens: "« Corriger une connaissance après vérification. » Un delta portant un crochet de contrôle et une boucle de reprise.",
    els: [
      'M 60 26 L 96 96 L 24 96 Z',     // le delta
      'M 42 78 L 54 90 L 82 58',       // le crochet de vérification interne
      // petite boucle de correction (retour)
      'M 84 40 Q 98 44 94 58 Q 92 64 86 62',
      'M 86 62 L 90 66 M 86 62 L 84 55',
    ],
  },
  {
    id: "alpha", code: "α", nom: "La Macro apprise",
    formule: "OwCm+k?!kMb",
    sens: "Raccourci auto-généré : quand une séquence revient des millions de fois, l'IA en fait un seul geste continu.",
    els: [
      'M 44 82 C 20 58 34 28 58 32 C 82 36 84 70 66 82 C 57 88 48 84 51 72',
      'M 66 82 C 74 90 86 90 94 82',   // la queue de l'alpha
      '<circle cx="30" cy="34" r="3"/>',// la graine (marque d'auto-génération)
    ],
  },
];

export const ALL = { TRAITS, VERBES, OBJETS, PENSEES };

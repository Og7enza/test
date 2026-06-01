// =============================================================================
//  recipes.js — Détection de motifs (craft) à partir de la disposition du pad.
//
//  Modèle du pad : footprint 2x2 => 4 colonnes (index 0..3), chaque colonne a
//  une hauteur (nombre de nuages empilés). Capacité totale 8, hauteur/colonne
//  jusqu'à 4.
//
//  SIGNATURE d'une disposition = liste des hauteurs NON NULLES, triée par ordre
//  décroissant, jointe par des virgules. Ex : deux colonnes empilées à 2 + une
//  à 1 => "2,2,1". Cette signature distingue sans ambiguïté toutes les recettes.
//
//  Deux actions de craft :
//    • FORGE   (⚒️) : fabrique une ARME ou un VÉHICULE.
//    • INVOQUE (✨) : fabrique un COÉQUIPIER (empilement vertical pur).
//
//  Données pures => testables sans navigateur.
// =============================================================================

// Calcule la signature canonique d'un tableau de hauteurs de colonnes.
export function signatureOf(columnHeights) {
  const nonzero = columnHeights.filter((h) => h > 0).sort((a, b) => b - a);
  return nonzero.join(',');
}

export function totalClouds(columnHeights) {
  return columnHeights.reduce((s, h) => s + h, 0);
}

// Une disposition "verticale pure" = une seule colonne occupée.
export function isPureVertical(columnHeights) {
  return columnHeights.filter((h) => h > 0).length === 1;
}

// --- Recettes ARMES (action FORGE) ------------------------------------------
// signature -> id d'arme. Les 11 armes du jeu.
export const WEAPON_RECIPES = {
  '1':        'bow',            // 1 nuage
  '1,1':      'dagger',         // 2 côte à côte
  '2':        'lance',          // 2 empilés vertical
  '1,1,1':    'bolt',           // 3 en L
  '1,1,1,1':  'flames',         // 4 en carré (base pleine à plat)
  '2,1,1':    'heavyMG',        // 4 en T
  '2,2':      'longbow',        // 4 "en ligne" (mur 2x2)
  '2,2,1':    'divineThunder',  // 5
  '2,2,2':    'harpyLauncher',  // 6
  '2,2,2,1':  'electricBow',    // 7
  '2,2,2,2':  'wrathOfZeus',    // 8 — cube 2x2x2 = ultime
};

// --- Recettes VÉHICULES (action FORGE, 8 nuages, configurations "hautes") ----
// On teste les véhicules AVANT les armes : ces signatures à 8 nuages sont
// distinctes du cube "2,2,2,2".
export const VEHICLE_RECIPES = {
  '3,3,2':    'pegasus',        // 8
  '4,4':      'warChariot',     // 8 — deux tours de 4
  '4,2,2':    'giantTurtle',    // 8
  '3,3,1,1':  'royalEagle',     // 8
};

// --- Recettes COÉQUIPIERS (action INVOQUE, empilement vertical pur) ----------
export const TEAMMATE_RECIPES = {
  '2': 'archer',       // 2 nuages
  '3': 'spearman',     // 3 nuages
  '4': 'thunderling',  // 4 nuages
};

// Résout une action FORGE. Renvoie { kind:'vehicle'|'weapon', id } ou null.
export function resolveForge(columnHeights) {
  const sig = signatureOf(columnHeights);
  if (VEHICLE_RECIPES[sig]) return { kind: 'vehicle', id: VEHICLE_RECIPES[sig] };
  if (WEAPON_RECIPES[sig])  return { kind: 'weapon',  id: WEAPON_RECIPES[sig] };
  return null;
}

// Résout une action INVOQUE. Renvoie { kind:'teammate', id } ou null.
export function resolveSummon(columnHeights) {
  if (!isPureVertical(columnHeights)) return null;
  const sig = signatureOf(columnHeights);
  if (TEAMMATE_RECIPES[sig]) return { kind: 'teammate', id: TEAMMATE_RECIPES[sig] };
  return null;
}

// Liste lisible pour le "livre de recettes" affiché dans l'UI.
export function recipeBook() {
  const shape = {
    '1': '▪ (1)', '1,1': '▪▪ côte à côte', '2': '▪ empilé x2',
    '1,1,1': '▪ en L (x3)', '1,1,1,1': '▪ carré (x4)',
    '2,1,1': '▪ en T (x4)', '2,2': '▪ mur 2x2 (x4)',
    '2,2,1': '(x5)', '2,2,2': '(x6)', '2,2,2,1': '(x7)', '2,2,2,2': 'CUBE 2x2x2 (x8)',
    '3,3,2': '(x8)', '4,4': '2 tours x4', '4,2,2': '(x8)', '3,3,1,1': '(x8)',
  };
  return {
    weapons:   Object.entries(WEAPON_RECIPES).map(([sig, id]) => ({ sig, id, shape: shape[sig] })),
    vehicles:  Object.entries(VEHICLE_RECIPES).map(([sig, id]) => ({ sig, id, shape: shape[sig] })),
    teammates: Object.entries(TEAMMATE_RECIPES).map(([sig, id]) => ({ sig, id, shape: shape[sig] })),
  };
}

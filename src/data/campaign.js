// =============================================================================
//  campaign.js — 8 mondes mythologiques × 8 missions = 64 missions.
//  Génération procédurale à partir de modèles d'objectifs, difficulté
//  croissante. Données pures (testables sans navigateur).
// =============================================================================

// Thèmes des 8 mondes (couleur de sol, ambiance, brouillard).
export const WORLDS = [
  { id: 0, name: 'Plaines d\'Olympe',   ground: 0x6fbf73, accent: 0xffffff, sky: 0xbfe3ff, deco: 'columns' },
  { id: 1, name: 'Désert d\'Anubis',    ground: 0xe2c275, accent: 0xc99a3a, sky: 0xffe7b0, deco: 'pyramids' },
  { id: 2, name: 'Enfers d\'Hadès',     ground: 0x5a3a4a, accent: 0xff5a3c, sky: 0x40202c, deco: 'lava' },
  { id: 3, name: 'Mer Égée',            ground: 0x4aa3c7, accent: 0xffffff, sky: 0x9fd8ef, deco: 'isles' },
  { id: 4, name: 'Nil sacré',           ground: 0x7bb36a, accent: 0x2e7d6b, sky: 0xd9f0c0, deco: 'reeds' },
  { id: 5, name: 'Mont Tonnerre',       ground: 0x8d99ae, accent: 0xf2f4ff, sky: 0xb9c4d8, deco: 'rocks' },
  { id: 6, name: 'Cité de Memphis',     ground: 0xd9b97a, accent: 0xb07a2e, sky: 0xf3dfae, deco: 'obelisks' },
  { id: 7, name: 'Royaume des Dieux',   ground: 0xc9a8ff, accent: 0xffe66d, sky: 0xe9deff, deco: 'temples' },
];

// Modèles d'objectifs. type pilote la condition de victoire dans world.js.
//   eliminate    : éliminer toute l'équipe ennemie
//   destroy_base : détruire le temple ennemi
//   collect      : déposer N nuages sur son pad (cumulatif)
//   survive      : tenir T secondes
//   domination   : contrôler le point central pendant T secondes cumulées
//   escort       : amener un véhicule allié jusqu'à la zone ennemie
const OBJECTIVE_TEMPLATES = [
  { type: 'eliminate',    label: 'Éliminez l\'équipe rivale' },
  { type: 'destroy_base', label: 'Détruisez le temple ennemi' },
  { type: 'collect',      label: 'Récoltez et empilez {N} nuages' },
  { type: 'survive',      label: 'Survivez pendant {T} secondes' },
  { type: 'domination',   label: 'Dominez le sanctuaire central {T}s' },
  { type: 'destroy_base', label: 'Renversez le temple adverse' },
  { type: 'eliminate',    label: 'Anéantissez tous les rivaux' },
  { type: 'collect',      label: 'Offrande : empilez {N} nuages' },
];

// Renvoie la liste complète des 64 missions.
export function buildCampaign() {
  const missions = [];
  for (let w = 0; w < WORLDS.length; w++) {
    for (let m = 0; m < 8; m++) {
      const globalIndex = w * 8 + m;            // 0..63
      const tpl = OBJECTIVE_TEMPLATES[m];
      // Difficulté 1..8 dans un monde, + bonus de monde.
      const diff = m + 1 + w * 0.5;
      const enemyTeams = 1;
      const enemyBuddies = Math.min(4, 1 + Math.floor((m + w) / 2)); // 1..4
      const aiLevel = Math.min(1, 0.25 + diff * 0.09);               // 0.25..1
      const N = 6 + m * 2 + w;                                       // objectif collect
      const T = 30 + m * 8 + w * 5;                                  // objectif survive/domination
      const label = tpl.label.replace('{N}', N).replace('{T}', T);
      missions.push({
        index: globalIndex,
        world: w,
        worldName: WORLDS[w].name,
        missionInWorld: m + 1,
        title: `${w + 1}-${m + 1} · ${WORLDS[w].name}`,
        objective: { type: tpl.type, label, N, T },
        enemyTeams,
        enemyBuddies,
        aiLevel,
        // La dernière mission de chaque monde est un "boss" (équipe pleine).
        boss: m === 7,
      });
    }
  }
  return missions;
}

// Petit helper : nombre total de missions.
export const TOTAL_MISSIONS = WORLDS.length * 8;

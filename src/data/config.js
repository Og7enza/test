// =============================================================================
//  config.js — Constantes globales et paramètres de réglage (game-tuning).
//  Aucune dépendance : importable partout, y compris dans des tests Node.
// =============================================================================

export const CONFIG = {
  // ---- Rendu / perf ---------------------------------------------------------
  targetFPS: 30,                 // cap logique (le RAF tourne au rythme écran)
  maxPixelRatio: 2,              // limite le DPR sur mobile pour les perfs
  shadows: true,                 // ombres douces (désactivables si faible perf)
  fogColor: 0xbfe3ff,

  // ---- Caméra isométrique ---------------------------------------------------
  camera: {
    fov: 38,
    // Décalage de la caméra par rapport à la cible (vue iso ~ 3/4 plongée).
    offset: { x: 0, y: 34, z: 26 },
    lerp: 0.10,                  // douceur du suivi
    near: 1,
    far: 400,
  },

  // ---- Arène ----------------------------------------------------------------
  arena: {
    half: 30,                    // demi-largeur => terrain de 60x60
    groundY: 0,
  },

  // ---- Nuages (ressource unique) -------------------------------------------
  clouds: {
    waveInterval: 8.0,           // secondes entre deux vagues
    perWave: 3,                  // nuages par vague
    maxOnGround: 24,             // plafond pour éviter la surcharge
    fallSpeed: 9,
    spawnHeight: 22,
    size: 1.4,
    pickupRadius: 1.9,
  },

  // ---- Pad d'empilement (2x2, hauteur jusqu'à 4, capacité 8) ----------------
  pad: {
    cols: 4,                     // 2x2
    cell: 1.7,                   // espacement des colonnes
    layerHeight: 1.45,           // hauteur d'un nuage empilé
    maxColumnHeight: 4,          // pile verticale max (pour invoquer foudre/4)
    capacity: 8,                 // total de nuages simultanés
    useRadius: 3.2,              // distance pour interagir avec le pad
  },

  // ---- Buddies --------------------------------------------------------------
  buddy: {
    radius: 0.75,
    baseHP: 100,
    baseSpeed: 7.2,
    accel: 40,
    maxPerTeam: 4,
    respawnDelay: 6.0,           // anti soft-lock : un buddy de base réapparaît
    pickupReach: 1.9,
    aimAssistRange: 26,          // portée de l'acquisition de cible auto
  },

  // ---- Temple / base --------------------------------------------------------
  temple: {
    hp: 400,
    radius: 3.0,
  },

  // ---- Combat ---------------------------------------------------------------
  projectile: {
    maxAlive: 400,               // pool de projectiles
  },

  // ---- IA -------------------------------------------------------------------
  ai: {
    decisionInterval: 0.5,       // réflexion de l'IA "directeur" d'équipe
    reactionJitter: 0.25,
  },

  // ---- Couleurs d'équipe (jusqu'à 4) ---------------------------------------
  teamColors: [
    { name: 'Olympe',  primary: 0x3aa0ff, accent: 0xffd24a, emoji: '⚡' }, // bleu
    { name: 'Hadès',   primary: 0xc0392b, accent: 0xff8c42, emoji: '🔥' }, // rouge
    { name: 'Anubis',  primary: 0x2ecc71, accent: 0xf1c40f, emoji: '🐊' }, // vert
    { name: 'Râ',      primary: 0xf4d03f, accent: 0xe67e22, emoji: '☀️' }, // or
  ],

  // ---- Audio ----------------------------------------------------------------
  audio: {
    master: 0.7,
    music: 0.45,
    sfx: 0.8,
  },
};

// Positions des 4 colonnes du pad (footprint 2x2), centrées sur l'origine du pad.
//   index :  2 3
//            0 1
export function padColumnOffsets() {
  const c = CONFIG.pad.cell / 2;
  return [
    { x: -c, z: -c }, // 0
    { x:  c, z: -c }, // 1
    { x: -c, z:  c }, // 2
    { x:  c, z:  c }, // 3
  ];
}

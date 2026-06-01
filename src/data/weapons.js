// =============================================================================
//  weapons.js — Définition des 11 armes, 4 véhicules et 3 coéquipiers.
//  Données pures (stats + métadonnées d'affichage). Aucune dépendance.
// =============================================================================

// type de projectile : 'arrow' | 'bolt' | 'fire' | 'bullet' | 'lightning' | 'harpy'
// Les couleurs sont des entiers hex (Three.js).

export const WEAPONS = {
  fists: {
    id: 'fists', name: 'Poings', icon: '👊', tier: 0,
    damage: 8, fireRate: 1.6, range: 2.2, projSpeed: 0, projType: 'melee',
    projColor: 0xffffff, projSize: 0.2, spread: 0, count: 1, ammo: Infinity,
    desc: 'Arme par défaut au corps à corps.',
  },
  bow: {
    id: 'bow', name: 'Arc simple', icon: '🏹', tier: 1, clouds: 1,
    damage: 16, fireRate: 2.0, range: 18, projSpeed: 32, projType: 'arrow',
    projColor: 0xffe08a, projSize: 0.28, spread: 0.02, count: 1, ammo: 30,
    desc: '1 nuage. Tir rapide et précis.',
  },
  dagger: {
    id: 'dagger', name: 'Double dague', icon: '🗡️', tier: 1, clouds: 2,
    damage: 14, fireRate: 4.0, range: 3.2, projSpeed: 0, projType: 'melee',
    projColor: 0xcfd8ff, projSize: 0.3, spread: 0, count: 2, ammo: 60,
    desc: '2 nuages côte à côte. Frappes très rapides au corps à corps.',
  },
  lance: {
    id: 'lance', name: 'Lance', icon: '🔱', tier: 2, clouds: 2,
    damage: 30, fireRate: 1.2, range: 4.0, projSpeed: 0, projType: 'melee',
    projColor: 0xd0e7ff, projSize: 0.35, spread: 0, count: 1, ammo: 40,
    desc: '2 nuages empilés. Allonge et gros dégâts.',
  },
  bolt: {
    id: 'bolt', name: 'Éclair', icon: '⚡', tier: 3, clouds: 3,
    damage: 26, fireRate: 2.4, range: 20, projSpeed: 40, projType: 'bolt',
    projColor: 0x66e0ff, projSize: 0.3, spread: 0.03, count: 1, ammo: 28,
    desc: '3 nuages en L. Décharge électrique véloce.',
  },
  flames: {
    id: 'flames', name: 'Flammes infernales', icon: '🔥', tier: 4, clouds: 4,
    damage: 9, fireRate: 9.0, range: 9, projSpeed: 16, projType: 'fire',
    projColor: 0xff7a18, projSize: 0.5, spread: 0.18, count: 1, ammo: 120,
    desc: '4 nuages en carré. Jet de flammes courte portée.',
  },
  heavyMG: {
    id: 'heavyMG', name: 'Mitrailleuse lourde', icon: '🔫', tier: 4, clouds: 4,
    damage: 11, fireRate: 11.0, range: 22, projSpeed: 52, projType: 'bullet',
    projColor: 0xfff2a0, projSize: 0.18, spread: 0.06, count: 1, ammo: 150,
    desc: '4 nuages en T. Cadence de tir dévastatrice.',
  },
  longbow: {
    id: 'longbow', name: 'Arc long', icon: '🎯', tier: 4, clouds: 4,
    damage: 40, fireRate: 1.1, range: 34, projSpeed: 60, projType: 'arrow',
    projColor: 0xffd060, projSize: 0.34, spread: 0.0, count: 1, ammo: 24,
    desc: '4 nuages en ligne (2x2 colonnes). Très longue portée.',
  },
  divineThunder: {
    id: 'divineThunder', name: 'Foudre divine', icon: '🌩️', tier: 5, clouds: 5,
    damage: 34, fireRate: 2.0, range: 24, projSpeed: 46, projType: 'lightning',
    projColor: 0x9be7ff, projSize: 0.4, spread: 0.02, count: 1, ammo: 30, aoe: 2.2,
    desc: '5 nuages. Foudre à dégâts de zone.',
  },
  harpyLauncher: {
    id: 'harpyLauncher', name: 'Lance-harpies', icon: '🦅', tier: 6, clouds: 6,
    damage: 22, fireRate: 1.4, range: 26, projSpeed: 30, projType: 'harpy',
    projColor: 0xe8c8ff, projSize: 0.45, spread: 0.04, count: 1, ammo: 24, homing: 0.06,
    desc: '6 nuages. Projectiles harpies à tête chercheuse légère.',
  },
  electricBow: {
    id: 'electricBow', name: 'Arc électrique', icon: '🏹⚡', tier: 7, clouds: 7,
    damage: 30, fireRate: 3.2, range: 28, projSpeed: 64, projType: 'bolt',
    projColor: 0x7af0ff, projSize: 0.32, spread: 0.015, count: 1, ammo: 40, chain: 2,
    desc: '7 nuages. Flèches électriques qui ricochent sur les ennemis proches.',
  },
  wrathOfZeus: {
    id: 'wrathOfZeus', name: 'Colère de Zeus', icon: '👑⚡', tier: 8, clouds: 8,
    damage: 70, fireRate: 1.0, range: 30, projSpeed: 50, projType: 'lightning',
    projColor: 0xffffff, projSize: 0.6, spread: 0, count: 3, ammo: 16, aoe: 4.0,
    desc: '8 nuages (cube 2x2x2). ULTIME : triple foudre à large zone.',
  },
};

export const VEHICLES = {
  pegasus: {
    id: 'pegasus', name: 'Pégase', icon: '🦄', hp: 90, speed: 13, flying: true,
    seats: 1, weapon: 'bolt', clouds: 8,
    desc: 'Pégase ailé : très rapide, vole au-dessus des obstacles.',
  },
  warChariot: {
    id: 'warChariot', name: 'Char de guerre', icon: '🛞', hp: 220, speed: 8, flying: false,
    seats: 2, weapon: 'heavyMG', clouds: 8,
    desc: 'Char à 2 places, blindé, équipé d\'une mitrailleuse.',
  },
  giantTurtle: {
    id: 'giantTurtle', name: 'Tortue géante', icon: '🐢', hp: 360, speed: 4.5, flying: false,
    seats: 1, weapon: 'flames', clouds: 8,
    desc: 'Lente mais ultra-blindée. Crache des flammes.',
  },
  royalEagle: {
    id: 'royalEagle', name: 'Aigle royal', icon: '🦅', hp: 120, speed: 11, flying: true,
    seats: 1, weapon: 'heavyMG', clouds: 8,
    desc: 'Aigle volant armé d\'une mitrailleuse.',
  },
};

export const TEAMMATES = {
  archer:     { id: 'archer',     name: 'Guerrier Arc',   icon: '🧝', hp: 90,  speed: 7.4, weapon: 'bow',           clouds: 2 },
  spearman:   { id: 'spearman',   name: 'Guerrier Lance', icon: '💂', hp: 120, speed: 6.8, weapon: 'lance',         clouds: 3 },
  thunderling:{ id: 'thunderling',name: 'Guerrier Foudre',icon: '🧙', hp: 110, speed: 7.0, weapon: 'divineThunder', clouds: 4 },
};

export function getWeapon(id) { return WEAPONS[id] || WEAPONS.fists; }

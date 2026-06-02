// =============================================================================
//  assets.js — Génération procédurale de modèles 3D low-poly cartoon (cel-shadé).
//  Tout est construit à partir de primitives Three.js (aucun fichier externe).
//  Style : MeshToonMaterial + flatShading => rendu "Team Buddies-like".
// =============================================================================

import * as THREE from 'three';
import { CONFIG, padColumnOffsets } from '../data/config.js';

// --- Rampe de dégradé partagée pour le cel-shading (3 paliers) --------------
let _gradient = null;
function gradientMap() {
  if (_gradient) return _gradient;
  const data = new Uint8Array([90, 170, 255]);   // 3 paliers de luminosité
  const tex = new THREE.DataTexture(data, data.length, 1, THREE.RedFormat);
  tex.minFilter = THREE.NearestFilter;
  tex.magFilter = THREE.NearestFilter;
  tex.needsUpdate = true;
  _gradient = tex;
  return tex;
}

export function toonMat(color, { flat = true, emissive = 0x000000, emissiveIntensity = 0 } = {}) {
  const m = new THREE.MeshToonMaterial({ color, gradientMap: gradientMap() });
  m.flatShading = flat;
  if (emissive) { m.emissive = new THREE.Color(emissive); m.emissiveIntensity = emissiveIntensity; }
  return m;
}

// Chargeur de texture OPTIONNEL : applique l'image si elle existe, sinon ne fait
// rien (on garde le rendu procédural). Permet d'ajouter des assets plus tard
// sans jamais casser le build s'ils sont absents.
const _texLoader = new THREE.TextureLoader();
export function optionalTexture(url, onApply, { repeat = 1, srgb = true } = {}) {
  _texLoader.load(
    url,
    (t) => {
      t.wrapS = t.wrapT = THREE.RepeatWrapping;
      t.repeat.set(repeat, repeat);
      if (srgb && 'colorSpace' in t) t.colorSpace = THREE.SRGBColorSpace;
      t.anisotropy = 4;
      onApply(t);
    },
    undefined,
    () => { /* asset absent : on reste en procédural, aucune erreur bloquante */ },
  );
}

// Géométries réutilisées (perf : on partage autant que possible).
const G = {
  box: new THREE.BoxGeometry(1, 1, 1),
  sphere: new THREE.SphereGeometry(0.5, 10, 8),
  lowSphere: new THREE.IcosahedronGeometry(0.5, 0),
  cyl: new THREE.CylinderGeometry(0.5, 0.5, 1, 10),
  cone: new THREE.ConeGeometry(0.5, 1, 8),
};

function mesh(geo, mat, opts = {}) {
  const m = new THREE.Mesh(geo, mat);
  if (opts.pos) m.position.set(opts.pos[0], opts.pos[1], opts.pos[2]);
  if (opts.scale) m.scale.set(opts.scale[0], opts.scale[1], opts.scale[2]);
  if (opts.rot) m.rotation.set(opts.rot[0], opts.rot[1], opts.rot[2]);
  m.castShadow = opts.cast !== false;
  m.receiveShadow = !!opts.receive;
  return m;
}

// ---------------------------------------------------------------------------
//  BUDDY — petit personnage cartoon. Renvoie un Group avec parties nommées
//  (userData.legL/legR/armL/armR/hand) pour l'animation procédurale.
// ---------------------------------------------------------------------------
export function makeBuddy({ primary = 0x3aa0ff, accent = 0xffd24a } = {}) {
  const g = new THREE.Group();
  const skin = 0xf4c89a;
  const bodyMat = toonMat(primary);
  const accentMat = toonMat(accent);
  const skinMat = toonMat(skin);
  const darkMat = toonMat(0x222233);
  const whiteMat = toonMat(0xffffff);

  // Tronc (capsule trapue).
  const body = mesh(new THREE.CapsuleGeometry(0.42, 0.5, 4, 8), bodyMat, { pos: [0, 0.95, 0] });
  g.add(body);

  // Ceinture / tunique.
  g.add(mesh(G.cyl, accentMat, { pos: [0, 0.62, 0], scale: [0.92, 0.18, 0.92] }));

  // Tête.
  const head = mesh(new THREE.SphereGeometry(0.42, 12, 10), skinMat, { pos: [0, 1.62, 0] });
  g.add(head);

  // Casque / laurier coloré (demi-sphère).
  const helmet = mesh(new THREE.SphereGeometry(0.45, 12, 8, 0, Math.PI * 2, 0, Math.PI * 0.55), accentMat, { pos: [0, 1.66, 0] });
  g.add(helmet);
  // Cimier (petite crête).
  g.add(mesh(G.box, bodyMat, { pos: [0, 1.98, -0.05], scale: [0.12, 0.28, 0.5] }));

  // Yeux.
  g.add(mesh(G.sphere, whiteMat, { pos: [-0.16, 1.66, 0.34], scale: [0.18, 0.22, 0.12], cast: false }));
  g.add(mesh(G.sphere, whiteMat, { pos: [0.16, 1.66, 0.34], scale: [0.18, 0.22, 0.12], cast: false }));
  g.add(mesh(G.sphere, darkMat, { pos: [-0.16, 1.66, 0.4], scale: [0.08, 0.1, 0.08], cast: false }));
  g.add(mesh(G.sphere, darkMat, { pos: [0.16, 1.66, 0.4], scale: [0.08, 0.1, 0.08], cast: false }));

  // Bras (pivots aux épaules pour balancement).
  const armL = new THREE.Group(); armL.position.set(-0.5, 1.15, 0);
  armL.add(mesh(new THREE.CapsuleGeometry(0.13, 0.5, 3, 6), bodyMat, { pos: [0, -0.28, 0] }));
  const armR = new THREE.Group(); armR.position.set(0.5, 1.15, 0);
  armR.add(mesh(new THREE.CapsuleGeometry(0.13, 0.5, 3, 6), bodyMat, { pos: [0, -0.28, 0] }));
  g.add(armL); g.add(armR);

  // Point d'ancrage de l'arme dans la main droite.
  const hand = new THREE.Object3D(); hand.position.set(0, -0.55, 0.1); armR.add(hand);

  // Jambes (pivots aux hanches).
  const legL = new THREE.Group(); legL.position.set(-0.22, 0.55, 0);
  legL.add(mesh(new THREE.CapsuleGeometry(0.15, 0.4, 3, 6), darkMat, { pos: [0, -0.3, 0] }));
  const legR = new THREE.Group(); legR.position.set(0.22, 0.55, 0);
  legR.add(mesh(new THREE.CapsuleGeometry(0.15, 0.4, 3, 6), darkMat, { pos: [0, -0.3, 0] }));
  g.add(legL); g.add(legR);

  // Anneau d'équipe au sol (repère visuel en vue iso).
  const ring = new THREE.Mesh(new THREE.RingGeometry(0.6, 0.85, 20), new THREE.MeshBasicMaterial({ color: primary, transparent: true, opacity: 0.55, side: THREE.DoubleSide }));
  ring.rotation.x = -Math.PI / 2; ring.position.y = 0.03; g.add(ring);

  g.userData = { legL, legR, armL, armR, hand, head, ring, walkPhase: Math.random() * 6 };
  g.scale.setScalar(0.9);
  return g;
}

// Petit objet 3D d'arme tenu en main (visuel simple selon le type de projectile).
export function makeHeldWeapon(weapon) {
  const grp = new THREE.Group();
  const c = weapon.projColor || 0xffe08a;
  const t = weapon.projType;
  if (t === 'arrow') {
    grp.add(mesh(new THREE.TorusGeometry(0.3, 0.04, 6, 12, Math.PI), toonMat(0x8a5a2b), { rot: [0, 0, Math.PI / 2] }));
  } else if (t === 'melee') {
    grp.add(mesh(G.box, toonMat(0xcccccc), { pos: [0, 0.4, 0], scale: [0.08, 0.9, 0.08] }));
  } else if (t === 'fire') {
    grp.add(mesh(G.cyl, toonMat(0x555555), { scale: [0.12, 0.5, 0.12] }));
    grp.add(mesh(G.lowSphere, toonMat(c, { emissive: c, emissiveIntensity: 0.8 }), { pos: [0, 0.4, 0], scale: [0.3, 0.3, 0.3] }));
  } else {
    grp.add(mesh(G.box, toonMat(0x444455), { pos: [0, 0.2, 0.1], scale: [0.16, 0.16, 0.7] }));
    grp.add(mesh(G.lowSphere, toonMat(c, { emissive: c, emissiveIntensity: 0.7 }), { pos: [0, 0.2, 0.45], scale: [0.2, 0.2, 0.2] }));
  }
  return grp;
}

// ---------------------------------------------------------------------------
//  NUAGE — amas de sphères blanches.
// ---------------------------------------------------------------------------
export function makeCloud() {
  const g = new THREE.Group();
  const mat = toonMat(0xffffff, { emissive: 0xaaccff, emissiveIntensity: 0.25 });
  const puffs = [[0, 0, 0, 1], [0.45, 0.1, 0.1, 0.7], [-0.45, 0.05, -0.1, 0.7], [0.1, 0.25, 0.4, 0.6], [-0.1, 0.2, -0.4, 0.6]];
  for (const [x, y, z, s] of puffs) g.add(mesh(G.lowSphere, mat, { pos: [x, y, z], scale: [s, s * 0.85, s] }));
  g.scale.setScalar(CONFIG.clouds.size);
  return g;
}

// ---------------------------------------------------------------------------
//  TEMPLE (base) — plateforme + colonnes + fronton + cœur destructible.
//  userData.core = cristal cible (PV de la base).
// ---------------------------------------------------------------------------
export function makeTemple({ primary = 0x3aa0ff, accent = 0xffd24a } = {}) {
  const g = new THREE.Group();
  const stone = toonMat(0xe8e2d0);
  const stone2 = toonMat(0xd8d0bc);
  // Socle à étages.
  g.add(mesh(G.box, stone, { pos: [0, 0.3, 0], scale: [7, 0.6, 7], receive: true }));
  g.add(mesh(G.box, stone2, { pos: [0, 0.8, 0], scale: [6, 0.5, 6], receive: true }));
  // Colonnes aux 4 coins + 2 façades.
  const cols = [[-2.4, -2.4], [2.4, -2.4], [-2.4, 2.4], [2.4, 2.4], [0, -2.4], [0, 2.4]];
  for (const [x, z] of cols) {
    g.add(mesh(G.cyl, stone, { pos: [x, 2.1, z], scale: [0.5, 2.4, 0.5] }));
    g.add(mesh(G.cyl, stone2, { pos: [x, 3.35, z], scale: [0.62, 0.2, 0.62] }));
  }
  // Fronton (toit).
  g.add(mesh(G.box, toonMat(accent), { pos: [0, 3.6, 0], scale: [6.4, 0.4, 6.4] }));
  g.add(mesh(new THREE.ConeGeometry(0.5, 1, 4), toonMat(accent), { pos: [0, 4.2, 0], scale: [5.5, 1, 5.5] }));
  // Cœur cristallin (cible destructible).
  const core = mesh(new THREE.OctahedronGeometry(0.9, 0), toonMat(primary, { emissive: primary, emissiveIntensity: 0.9 }), { pos: [0, 2.4, 0] });
  g.add(core);
  g.userData = { core };
  return g;
}

// ---------------------------------------------------------------------------
//  PAD d'empilement 2x2. userData.columns = positions monde des 4 colonnes.
// ---------------------------------------------------------------------------
export function makePad(teamColor = 0x3aa0ff) {
  const g = new THREE.Group();
  const size = CONFIG.pad.cell + 1.4;
  g.add(mesh(G.box, toonMat(0xcfc6b0), { pos: [0, 0.15, 0], scale: [size, 0.3, size], receive: true }));
  // Marqueurs des 4 colonnes.
  const offs = padColumnOffsets();
  const marks = [];
  for (let i = 0; i < offs.length; i++) {
    const o = offs[i];
    const pad = new THREE.Mesh(new THREE.PlaneGeometry(CONFIG.pad.cell * 0.8, CONFIG.pad.cell * 0.8),
      new THREE.MeshBasicMaterial({ color: teamColor, transparent: true, opacity: 0.22 }));
    pad.rotation.x = -Math.PI / 2; pad.position.set(o.x, 0.32, o.z); g.add(pad); marks.push(pad);
  }
  // Poteaux d'angle.
  const cc = size / 2 - 0.15;
  for (const [sx, sz] of [[-1, -1], [1, -1], [-1, 1], [1, 1]])
    g.add(mesh(G.cyl, toonMat(teamColor), { pos: [sx * cc, 0.6, sz * cc], scale: [0.18, 1.0, 0.18] }));
  g.userData = { columns: offs, marks };
  return g;
}

// ---------------------------------------------------------------------------
//  VÉHICULES — formes low-poly distinctes.
// ---------------------------------------------------------------------------
export function makeVehicle(type, teamColor = 0x3aa0ff) {
  const g = new THREE.Group();
  const body = toonMat(teamColor);
  const dark = toonMat(0x333344);
  const gold = toonMat(0xffd24a);
  if (type === 'pegasus') {
    g.add(mesh(new THREE.CapsuleGeometry(0.5, 1.1, 4, 8), toonMat(0xffffff), { pos: [0, 1.2, 0], rot: [Math.PI / 2, 0, 0] }));
    g.add(mesh(G.cone, toonMat(0xffffff), { pos: [0, 1.5, 0.9], rot: [Math.PI / 2.5, 0, 0], scale: [0.4, 0.8, 0.4] })); // tête/cou
    for (const s of [-1, 1]) g.add(mesh(G.box, toonMat(0xf0f0ff), { pos: [s * 0.9, 1.6, -0.1], rot: [0, 0, s * 0.5], scale: [1.4, 0.1, 0.9] })); // ailes
  } else if (type === 'warChariot') {
    g.add(mesh(G.box, body, { pos: [0, 0.9, 0], scale: [1.8, 0.9, 2.4] }));
    g.add(mesh(G.box, gold, { pos: [0, 1.4, -0.8], scale: [1.8, 0.6, 0.2] }));
    for (const s of [-1, 1]) g.add(mesh(G.cyl, dark, { pos: [s * 1.0, 0.6, 0.7], rot: [0, 0, Math.PI / 2], scale: [1.0, 0.3, 1.0] })); // roues
  } else if (type === 'giantTurtle') {
    g.add(mesh(new THREE.SphereGeometry(1.4, 12, 8, 0, Math.PI * 2, 0, Math.PI / 2), toonMat(0x4a7a3a), { pos: [0, 0.9, 0] }));
    g.add(mesh(new THREE.SphereGeometry(1.5, 10, 6, 0, Math.PI * 2, 0, Math.PI / 2.2), toonMat(0x2e5a2a), { pos: [0, 0.85, 0], scale: [1.05, 0.5, 1.05] }));
    g.add(mesh(G.lowSphere, toonMat(0x7aa05a), { pos: [0, 0.7, 1.5], scale: [0.7, 0.7, 0.9] })); // tête
  } else { // royalEagle
    g.add(mesh(new THREE.CapsuleGeometry(0.45, 1.2, 4, 8), toonMat(0x8a5a2b), { pos: [0, 1.4, 0], rot: [Math.PI / 2, 0, 0] }));
    g.add(mesh(G.lowSphere, gold, { pos: [0, 1.7, 0.9], scale: [0.5, 0.5, 0.6] }));
    for (const s of [-1, 1]) g.add(mesh(G.box, toonMat(0x6a4a2b), { pos: [s * 1.2, 1.5, 0], rot: [0, 0, s * 0.3], scale: [2.0, 0.1, 1.0] }));
  }
  return g;
}

// ---------------------------------------------------------------------------
//  PROJECTILES — petit mesh par type (clonable pour le pool).
// ---------------------------------------------------------------------------
export function makeProjectile(type, color) {
  const emis = toonMat(color, { emissive: color, emissiveIntensity: 0.9 });
  let m;
  if (type === 'arrow') m = new THREE.Mesh(new THREE.ConeGeometry(0.1, 0.7, 6), emis);
  else if (type === 'bullet') m = new THREE.Mesh(new THREE.SphereGeometry(0.14, 6, 5), emis);
  else if (type === 'fire') m = new THREE.Mesh(G.lowSphere, emis);
  else if (type === 'lightning') m = new THREE.Mesh(new THREE.BoxGeometry(0.12, 0.12, 0.9), emis);
  else if (type === 'harpy') m = new THREE.Mesh(new THREE.ConeGeometry(0.2, 0.6, 5), emis);
  else m = new THREE.Mesh(new THREE.BoxGeometry(0.18, 0.18, 0.7), emis); // bolt
  m.castShadow = false;
  return m;
}

// ---------------------------------------------------------------------------
//  ARÈNE — sol thématique + murs + décors. Renvoie { group, obstacles }.
//  obstacles : [{x,z,r}] pour la navigation.
// ---------------------------------------------------------------------------
export function makeArena(world) {
  const g = new THREE.Group();
  const half = CONFIG.arena.half;
  const obstacles = [];

  // Sol.
  const ground = new THREE.Mesh(new THREE.PlaneGeometry(half * 2, half * 2, 1, 1), toonMat(world.ground, { flat: false }));
  ground.rotation.x = -Math.PI / 2; ground.receiveShadow = true; g.add(ground);
  // Texture de sol optionnelle (assets/textures/groundN.png), sinon couleur unie.
  optionalTexture(`assets/textures/ground${world.id}.png`, (t) => {
    t.magFilter = THREE.LinearFilter;
    ground.material.map = t; ground.material.color.set(0xffffff); ground.material.needsUpdate = true;
  }, { repeat: 5 });

  // Bordures (murs) — obstacles de périmètre.
  const wallMat = toonMat(world.accent);
  const t = 1.2, h = 2.2;
  const walls = [[0, -half, half * 2, t], [0, half, half * 2, t], [-half, 0, t, half * 2], [half, 0, t, half * 2]];
  for (const [x, z, w, d] of walls) g.add(mesh(G.box, wallMat, { pos: [x, h / 2, z], scale: [w, h, d], receive: true }));

  // Décors thématiques dispersés (certains servent d'obstacles).
  const rand = mulberry32(world.id * 7919 + 17);
  const decoCount = 12;
  for (let i = 0; i < decoCount; i++) {
    const x = (rand() * 2 - 1) * (half - 8);
    const z = (rand() * 2 - 1) * (half - 8);
    if (Math.hypot(x, z) < 6) continue;                  // garde le centre dégagé
    const obj = makeDeco(world.deco, world, rand);
    obj.position.set(x, 0, z);
    g.add(obj);
    obstacles.push({ x, z, r: obj.userData.radius || 1.6 });
  }
  return { group: g, obstacles };
}

function makeDeco(kind, world, rand) {
  const g = new THREE.Group();
  if (kind === 'pyramids' || kind === 'temples') {
    const s = 2 + rand() * 2.5;
    g.add(mesh(new THREE.ConeGeometry(1, 1, 4), toonMat(world.accent), { pos: [0, s / 2, 0], scale: [s, s, s], receive: true }));
    g.userData.radius = s * 0.6;
  } else if (kind === 'columns' || kind === 'obelisks') {
    const hh = 3 + rand() * 2;
    g.add(mesh(G.cyl, toonMat(0xe8e2d0), { pos: [0, hh / 2, 0], scale: [0.7, hh, 0.7] }));
    g.userData.radius = 0.9;
  } else if (kind === 'rocks' || kind === 'lava') {
    const s = 1.4 + rand() * 1.8;
    g.add(mesh(new THREE.DodecahedronGeometry(0.6, 0), toonMat(kind === 'lava' ? 0x6a2a2a : 0x8a8a96), { pos: [0, s * 0.4, 0], scale: [s, s, s] }));
    g.userData.radius = s * 0.6;
  } else { // isles / reeds : petits buissons
    const s = 1 + rand() * 1.2;
    g.add(mesh(G.lowSphere, toonMat(0x3a8a4a), { pos: [0, s * 0.4, 0], scale: [s, s * 0.8, s] }));
    g.userData.radius = s * 0.5;
  }
  return g;
}

// PRNG déterministe (pour des arènes reproductibles).
function mulberry32(a) {
  return function () {
    a |= 0; a = (a + 0x6D2B79F5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

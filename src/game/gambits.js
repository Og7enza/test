// =============================================================================
//  gambits.js — Système de "gambits" (façon Final Fantasy XII) pour l'IA des
//  alliés du joueur ET des bots. Un gambit = liste ORDONNÉE de règles
//  [Condition → Action]. À chaque tick, on évalue de haut en bas : la PREMIÈRE
//  condition vraie déclenche son action. Cela remplace les ordres "simples"
//  par un cerveau réactif et lisible.
//
//  Données pures (opèrent sur buddy + world via un objet `info` pré-calculé).
//  Aucune dépendance Three/DOM => testable sous Node.
// =============================================================================

import { CONFIG } from '../data/config.js';

// --- Utilitaires -----------------------------------------------------------
function approach(b, target, standoff) {
  const tp = target.pos || target.position;
  let dx = b.pos.x - tp.x, dz = b.pos.z - tp.z;
  const d = Math.hypot(dx, dz) || 1;
  return { x: tp.x + (dx / d) * standoff, z: tp.z + (dz / d) * standoff };
}

// --- ACTIONS : positionnent moveTarget / wantFire du buddy -----------------
export function actAttack(b, world, info) {
  const tgt = info.enemy || world.enemyTempleFor(b.team);
  if (tgt) b.moveTarget = approach(b, tgt, Math.max(2.5, b.weapon.range * 0.7));
  b.joy = null; b.wantFire = true;
}
export function actDefend(b, world, info) {
  const home = b.team.spawn;
  if (info.baseThreat && info.enemy) b.moveTarget = approach(b, info.enemy, b.weapon.range * 0.7);
  else if (Math.hypot(b.pos.x - home.x, b.pos.z - home.z) > 9) b.moveTarget = { x: home.x, z: home.z };
  else b.moveTarget = null;
  b.joy = null; b.wantFire = true;
}
export function actCollect(b, world, info) {
  if (!b.carried) {
    const c = info.cloud;
    if (c) {
      b.moveTarget = { x: c.pos.x, z: c.pos.z };
      if (Math.hypot(b.pos.x - c.pos.x, b.pos.z - c.pos.z) < CONFIG.buddy.pickupReach) world.tryPickup(b);
    } else b.moveTarget = { x: b.team.pad.x, z: b.team.pad.z };
  } else {
    const col = b.team.ai ? b.team.ai.depositColumnWorld(b) : { x: b.team.pad.x, z: b.team.pad.z };
    b.moveTarget = { x: col.x, z: col.z };
    if (Math.hypot(b.pos.x - b.team.pad.x, b.pos.z - b.team.pad.z) < CONFIG.pad.useRadius) {
      if (world.tryDeposit(b) && b.team.ai) b.team.ai.afterDeposit(b);
    }
  }
  b.joy = null; b.wantFire = info.enemyDist < 6;     // se défend si on l'approche
}
export function actRetreat(b, world, info) {
  const t = b.team;
  b.moveTarget = { x: t.spawn.x - t.toCenter.x * 1.5, z: t.spawn.z - t.toCenter.z * 1.5 };
  b.joy = null; b.wantFire = info.enemyDist < b.weapon.range;   // tire en reculant si possible
}
export function actFollow(b, world, info) {
  const leader = b.team.leader();
  if (leader && leader !== b) {
    const i = b.team.buddies.indexOf(b), ang = i * 1.7;
    const tx = leader.pos.x + Math.cos(ang) * 2.6, tz = leader.pos.z + Math.sin(ang) * 2.6;
    b.moveTarget = (Math.hypot(b.pos.x - tx, b.pos.z - tz) > 1.4) ? { x: tx, z: tz } : null;
  } else b.moveTarget = null;
  b.joy = null; b.wantFire = true;
}
export function actGuard(b, world, info) {
  const leader = b.team.leader();
  if (info.leaderThreat && info.enemy) b.moveTarget = approach(b, info.enemy, b.weapon.range * 0.6);
  else if (leader && leader !== b) {
    const d = Math.hypot(b.pos.x - leader.pos.x, b.pos.z - leader.pos.z);
    b.moveTarget = (d > 2.4) ? { x: leader.pos.x - b.team.toCenter.x * 2, z: leader.pos.z - b.team.toCenter.z * 2 } : null;
  } else b.moveTarget = null;
  b.joy = null; b.wantFire = true;
}
export function actHold(b, world, info) { b.moveTarget = null; b.joy = null; b.wantFire = info.enemyDist < b.weapon.range; }

// --- CONDITIONS : (buddy, world, info) => bool -----------------------------
const C = {
  selfLow: (p) => (b) => b.hp / b.maxHp < p,
  enemyInRange: (b, w, i) => i.enemyDist <= b.weapon.range,
  enemyVisible: (b, w, i) => i.enemyDist < CONFIG.buddy.aimAssistRange,
  enemyClose: (b, w, i) => i.enemyDist < 6,
  baseThreat: (b, w, i) => i.baseThreat,
  leaderThreat: (b, w, i) => i.leaderThreat,
  always: () => true,
};

// --- PRÉRÉGLAGES (chaque "ordre" du menu radial = un gambit) ---------------
// Évalués de haut en bas ; 1ʳᵉ condition vraie => action.
export const GAMBITS = {
  follow:  [[C.selfLow(0.20), actRetreat], [C.enemyInRange, actAttack], [C.always, actFollow]],
  guard:   [[C.leaderThreat, actAttack], [C.enemyClose, actAttack], [C.always, actGuard]],
  defend:  [[C.baseThreat, actAttack], [C.enemyInRange, actAttack], [C.always, actDefend]],
  attack:  [[C.selfLow(0.15), actRetreat], [C.always, actAttack]],
  collect: [[C.selfLow(0.22), actRetreat], [C.enemyClose, actAttack], [C.always, actCollect]],
  wait:    [[C.enemyInRange, actHold], [C.always, actHold]],
};

// Exécute le gambit identifié par `id` pour le buddy.
export function runGambit(id, b, world, info) {
  const rules = GAMBITS[id] || GAMBITS.follow;
  for (let k = 0; k < rules.length; k++) {
    if (rules[k][0](b, world, info)) { rules[k][1](b, world, info); return; }
  }
  actFollow(b, world, info);
}

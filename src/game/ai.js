// =============================================================================
//  ai.js — Intelligence des buddies.
//   1) updateBuddyBehavior() : fait jouer un buddy. S'il appartient à un
//      BATAILLON actif (et n'est pas le chef), il tient sa place en FORMATION
//      tant qu'aucune menace immédiate ; sinon il exécute son GAMBIT (cf.
//      gambits.js). Utilisé pour tous les buddies SAUF celui piloté à la main.
//   2) TeamAI : "directeur" d'une équipe gérée par l'ordinateur (rôles +
//      collecte + craft selon une recette objectif).
// =============================================================================

import { CONFIG } from '../data/config.js';
import { totalClouds } from '../data/recipes.js';
import { runGambit } from './gambits.js';

// Les "ordres" du menu radial sont désormais des PRÉRÉGLAGES de gambits.
export const ORDERS = [
  { id: 'follow',  label: 'Suivre',        icon: '🐾' },
  { id: 'guard',   label: 'Protéger chef', icon: '🛟' },
  { id: 'defend',  label: 'Défendre base', icon: '🛡️' },
  { id: 'attack',  label: 'Attaquer',      icon: '⚔️' },
  { id: 'collect', label: 'Collecter',     icon: '☁️' },
  { id: 'wait',    label: 'Attendre',      icon: '✋' },
];

// --- Formations de bataillon (décalages en repère "chef") -------------------
// x = latéral (droite +), z = profondeur (derrière +).
export const FORMATIONS = {
  wedge:  (i) => { const k = Math.floor(i / 2) + 1, side = (i % 2) ? -1 : 1; return { x: side * 1.7 * k, z: 1.3 * k }; },
  line:   (i, n) => ({ x: (i - (n - 1) / 2) * 1.9, z: 2.0 }),
  column: (i) => ({ x: 0, z: (i + 1) * 1.9 }),
  circle: (i, n) => { const a = (i / Math.max(1, n)) * Math.PI * 2; return { x: Math.cos(a) * 2.5, z: 2.4 + Math.sin(a) * 2.5 }; },
};

function formationSlot(b) {
  const team = b.team, leader = team.leader();
  if (!leader) return null;
  const members = team.aliveBuddies().filter((x) => x !== leader);
  const i = members.indexOf(b);
  if (i < 0) return null;
  const off = (FORMATIONS[team.formation] || FORMATIONS.wedge)(i, members.length);
  const f = leader.facing;
  // forward = (sin f, cos f) ; right = (cos f, -sin f) ; behind = -forward
  const rx = Math.cos(f), rz = -Math.sin(f), bx = -Math.sin(f), bz = -Math.cos(f);
  return { x: leader.pos.x + rx * off.x + bx * off.z, z: leader.pos.z + rz * off.x + bz * off.z };
}

// Pré-calcule le contexte utile aux gambits (perception du buddy).
function computeInfo(b, world) {
  const e = world.nearestEnemyBuddy(b);
  const enemyDist = e ? Math.hypot(e.pos.x - b.pos.x, e.pos.z - b.pos.z) : Infinity;
  const cloud = (!b.carried) ? world.nearestFreeCloud(b.pos) : null;
  let baseThreat = false, leaderThreat = false;
  const home = b.team.spawn, leader = b.team.leader();
  for (const o of world.buddies) {
    if (o.team === b.team || !o.alive) continue;
    if (Math.hypot(o.pos.x - home.x, o.pos.z - home.z) < 14) baseThreat = true;
    if (leader && Math.hypot(o.pos.x - leader.pos.x, o.pos.z - leader.pos.z) < 8) leaderThreat = true;
  }
  return { enemy: e, enemyDist, cloud, baseThreat, leaderThreat };
}

export function updateBuddyBehavior(b, world) {
  if (!b.alive) return;
  const info = computeInfo(b, world);

  // Bataillon : on tient la formation tant qu'aucun ennemi à portée.
  if (b.team.battalionActive && b !== b.team.leader()) {
    if (info.enemyDist > b.weapon.range * 0.95) {
      const slot = formationSlot(b);
      if (slot) { b.moveTarget = slot; b.joy = null; b.wantFire = info.enemyDist < b.weapon.range; return; }
    }
  }
  // Sinon : on joue le gambit (préréglage d'ordre).
  runGambit(b.order, b, world, info);
}

// --- Directeur d'équipe IA ---------------------------------------------------
export class TeamAI {
  constructor(team, world) {
    this.team = team;
    this.world = world;
    this.timer = Math.random() * 0.5;
    this.goal = null;            // { kind:'summon'|'forge', cols:[...] }
    this.builder = null;
    this.aggro = 0.35 + (team.aiLevel || 0.5) * 0.6;
  }

  update(dt) {
    this.timer -= dt;
    if (this.timer > 0) return;
    this.timer = CONFIG.ai.decisionInterval + Math.random() * CONFIG.ai.reactionJitter;
    this.think();
  }

  think() {
    const buddies = this.team.aliveBuddies();
    if (buddies.length === 0) return;

    if (!this.goal) this.goal = this.chooseGoal(buddies.length);
    if (!this.builder || !this.builder.alive) this.builder = buddies[0];

    buddies.forEach((b, i) => {
      if (b === this.builder) b.order = 'collect';
      else if (i % 2 === 0 && Math.random() < this.aggro) b.order = 'attack';
      else b.order = (Math.random() < this.aggro) ? 'attack' : 'defend';
    });
  }

  chooseGoal(teamSize) {
    const lvl = this.team.aiLevel || 0.5;
    const targetSize = Math.min(CONFIG.buddy.maxPerTeam, 2 + Math.round(lvl * 2));
    if (teamSize < targetSize) return { kind: 'summon', cols: [2, 0, 0, 0] };  // archer
    if (lvl > 0.85) return { kind: 'forge', cols: [2, 2, 2, 2] };   // Colère de Zeus
    if (lvl > 0.65) return { kind: 'forge', cols: [2, 2, 1, 0] };   // Foudre divine
    if (lvl > 0.45) return { kind: 'forge', cols: [2, 1, 1, 0] };   // Mitrailleuse
    return { kind: 'forge', cols: [1, 1, 1, 0] };                   // Éclair
  }

  depositColumnWorld(b) {
    const pad = this.team.pad, g = this.goal || { cols: [4, 0, 0, 0] };
    let col = -1;
    for (let i = 0; i < 4; i++) if (pad.heights[i] < (g.cols[i] || 0)) { col = i; break; }
    if (col < 0) for (let i = 0; i < 4; i++) if (pad.heights[i] < CONFIG.pad.maxColumnHeight) { col = i; break; }
    if (col < 0) col = 0;
    return { x: pad.x + pad.columns[col].x, z: pad.z + pad.columns[col].z };
  }

  afterDeposit() {
    const pad = this.team.pad;
    if (!this.goal) return;
    if (pad.total() < totalClouds(this.goal.cols)) return;
    const res = this.goal.kind === 'summon' ? pad.summon() : pad.forge();
    if (res) this.world.applyCraftResult(this.team, this.builder, res);
    else pad.clear();
    this.goal = null;
  }
}

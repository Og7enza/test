// =============================================================================
//  ai.js — Intelligence des buddies.
//   1) updateBuddyBehavior() : exécute l'ORDRE d'un buddy (Suivre / Défendre /
//      Attaquer / Collecter / Attendre). Utilisé pour tous les buddies SAUF
//      celui contrôlé manuellement par un humain.
//   2) TeamAI : "directeur" d'une équipe gérée par l'ordinateur. Répartit les
//      rôles, collecte les nuages, fabrique armes/coéquipiers selon sa recette
//      objectif.
// =============================================================================

import { CONFIG } from '../data/config.js';
import { totalClouds } from '../data/recipes.js';

// Les 5 ordres disponibles via le menu radial.
export const ORDERS = [
  { id: 'follow',  label: 'Suivre',        icon: '🐾' },
  { id: 'defend',  label: 'Défendre base', icon: '🛡️' },
  { id: 'attack',  label: 'Attaquer',      icon: '⚔️' },
  { id: 'collect', label: 'Collecter',     icon: '☁️' },
  { id: 'wait',    label: 'Attendre',      icon: '✋' },
];

function approachPoint(b, target, standoff) {
  // Point situé à `standoff` de la cible, dans la direction du buddy.
  const tp = target.pos || target.position;
  let dx = b.pos.x - tp.x, dz = b.pos.z - tp.z;
  const d = Math.hypot(dx, dz) || 1;
  return { x: tp.x + (dx / d) * standoff, z: tp.z + (dz / d) * standoff };
}

export function updateBuddyBehavior(b, world) {
  if (!b.alive) return;
  const { dist: enemyDist } = world.nearestEnemy(b);
  const threatened = enemyDist < 8;

  switch (b.order) {
    case 'wait':
      b.moveTarget = null; b.joy = null;
      b.wantFire = enemyDist < b.weapon.range;
      break;

    case 'follow': {
      const leader = b.team.leader();
      if (leader && leader !== b) {
        const i = b.team.buddies.indexOf(b);
        const ang = i * 1.7;
        const tx = leader.pos.x + Math.cos(ang) * 2.6, tz = leader.pos.z + Math.sin(ang) * 2.6;
        b.moveTarget = (Math.hypot(b.pos.x - tx, b.pos.z - tz) > 1.4) ? { x: tx, z: tz } : null;
      } else b.moveTarget = null;
      b.wantFire = true;            // tire si une cible passe à portée
      break;
    }

    case 'defend': {
      const home = b.team.spawn;
      const fromHome = Math.hypot(b.pos.x - home.x, b.pos.z - home.z);
      if (fromHome > 9) b.moveTarget = { x: home.x, z: home.z };
      else if (b.target) b.moveTarget = approachPoint(b, b.target, Math.min(8, b.weapon.range * 0.7));
      else b.moveTarget = null;
      b.wantFire = true;
      break;
    }

    case 'attack': {
      let tgt = world.nearestEnemyBuddy(b);
      if (!tgt) tgt = world.enemyTempleFor(b.team);
      if (tgt) b.moveTarget = approachPoint(b, tgt, Math.max(2.5, b.weapon.range * 0.7));
      b.wantFire = true;
      break;
    }

    case 'collect':
    default: {
      if (!b.carried) {
        const cloud = world.nearestFreeCloud(b.pos);
        if (cloud) {
          b.moveTarget = { x: cloud.pos.x, z: cloud.pos.z };
          if (Math.hypot(b.pos.x - cloud.pos.x, b.pos.z - cloud.pos.z) < CONFIG.buddy.pickupReach) world.tryPickup(b);
        } else {
          b.moveTarget = { x: b.team.pad.x, z: b.team.pad.z };
        }
      } else {
        // Apporte au pad. Une IA d'équipe vise une colonne précise (motif).
        const col = b.team.ai ? b.team.ai.depositColumnWorld(b) : { x: b.team.pad.x, z: b.team.pad.z };
        b.moveTarget = { x: col.x, z: col.z };
        if (Math.hypot(b.pos.x - b.team.pad.x, b.pos.z - b.team.pad.z) < CONFIG.pad.useRadius) {
          if (world.tryDeposit(b) && b.team.ai) b.team.ai.afterDeposit(b);
        }
      }
      b.wantFire = threatened;       // se défend si menacé
      break;
    }
  }
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
    // Sinon : une arme dont le palier dépend du niveau d'IA.
    if (lvl > 0.85) return { kind: 'forge', cols: [2, 2, 2, 2] };   // Colère de Zeus
    if (lvl > 0.65) return { kind: 'forge', cols: [2, 2, 1, 0] };   // Foudre divine
    if (lvl > 0.45) return { kind: 'forge', cols: [2, 1, 1, 0] };   // Mitrailleuse
    return { kind: 'forge', cols: [1, 1, 1, 0] };                   // Éclair
  }

  // Colonne où déposer pour se rapprocher du motif objectif.
  depositColumnWorld(b) {
    const pad = this.team.pad, g = this.goal || { cols: [4, 0, 0, 0] };
    let col = -1;
    for (let i = 0; i < 4; i++) if (pad.heights[i] < (g.cols[i] || 0)) { col = i; break; }
    if (col < 0) for (let i = 0; i < 4; i++) if (pad.heights[i] < CONFIG.pad.maxColumnHeight) { col = i; break; }
    if (col < 0) col = 0;
    return { x: pad.x + pad.columns[col].x, z: pad.z + pad.columns[col].z };
  }

  // Après un dépôt : si le motif objectif est atteint, on fabrique.
  afterDeposit() {
    const pad = this.team.pad;
    if (!this.goal) return;
    const need = totalClouds(this.goal.cols);
    if (pad.total() < need) return;

    const action = this.goal.kind;
    const res = action === 'summon' ? pad.summon() : pad.forge();
    if (res) {
      this.world.applyCraftResult(this.team, this.builder, res);
    } else {
      pad.clear();   // motif raté : on recycle
    }
    this.goal = null;
  }
}

// =============================================================================
//  world.js — Monde de jeu : équipes, temples, pads, nuages, projectiles,
//  combat, application des crafts, conditions de victoire/défaite et respawn
//  anti-blocage. C'est le chef d'orchestre de la simulation.
// =============================================================================

import * as THREE from 'three';
import { CONFIG } from '../data/config.js';
import { WEAPONS, VEHICLES, TEAMMATES } from '../data/weapons.js';
import { makeArena, makeTemple, makeProjectile } from '../core/assets.js';
import { Pad } from './pad.js';
import { Buddy } from './buddy.js';
import { updateBuddyBehavior, TeamAI } from './ai.js';

// --- Équipe -----------------------------------------------------------------
class Team {
  constructor(world, index, colorIndex, controller, opts = {}) {
    this.world = world;
    this.index = index;
    this.color = CONFIG.teamColors[colorIndex % CONFIG.teamColors.length];
    this.controller = controller;               // 'human' | 'ai'
    this.viewport = opts.viewport ?? null;       // index de viewport si humain
    this.aiLevel = opts.aiLevel ?? 0.6;
    this.spawn = opts.spawn;                      // {x,z}
    this.toCenter = opts.toCenter || { x: 0, z: 0 };
    this.buddies = [];
    this.activeBuddy = null;
    this.collected = 0;
    this.dominationTime = 0;
    this.score = 0;                               // kills (deathmatch)
    this.canRespawn = true;
    this.respawnTimer = 0;
    this.formation = 'off';                       // bataillon : off|wedge|line|column|circle

    // Temple.
    this.templeGroup = makeTemple(this.color);
    this.templeGroup.position.set(this.spawn.x, 0, this.spawn.z);
    // Oriente le temple vers le centre.
    this.templeGroup.rotation.y = Math.atan2(-this.spawn.x, -this.spawn.z);
    this.templeGroup.userData.teamRef = this;
    world.scene.add(this.templeGroup);
    this.core = this.templeGroup.userData.core;
    this.maxTempleHP = CONFIG.temple.hp;
    this.templeHP = this.maxTempleHP;
    this.templeDestroyed = false;

    // Pad : entre le temple et le centre.
    const px = this.spawn.x + this.toCenter.x * 6.5;
    const pz = this.spawn.z + this.toCenter.z * 6.5;
    this.pad = new Pad(world.scene, px, pz, this.color.primary);
    this.pad.team = this;

    this.ai = controller === 'ai' ? new TeamAI(this, world) : null;
  }

  aliveBuddies() { return this.buddies.filter((b) => b.alive); }
  leader() { return (this.activeBuddy && this.activeBuddy.alive) ? this.activeBuddy : this.aliveBuddies()[0] || null; }
  get battalionActive() { return this.formation !== 'off'; }

  damageTemple(d) {
    if (this.templeDestroyed) return;
    this.templeHP -= d;
    if (this.templeHP <= 0) {
      this.templeDestroyed = true;
      const p = this.templeGroup.position;
      this.world.particles.emit('explosion', p.x, 3, p.z, { big: true, count: 60 });
      this.world.audio.explosion(true);
      this.world.engine.addShake(0.9);
      if (this.core) this.core.visible = false;
    }
  }
}

// --- Monde ------------------------------------------------------------------
export class World {
  constructor(engine, particles, audio) {
    this.engine = engine;
    this.scene = engine.scene;
    this.particles = particles;
    this.audio = audio;

    this.teams = [];
    this.buddies = [];
    this.clouds = [];
    this.projectiles = [];
    this._projPool = {};
    this.obstacles = [];

    this.time = 0;
    this.waveTimer = CONFIG.clouds.waveInterval;
    this.over = false;
    this.result = null;
    this.objective = null;
    this.mode = 'skirmish';
    this.onEnd = null;            // callback(result)
    this._arenaGroup = null;
    this._tmpRay = new THREE.Raycaster();
  }

  // Construit l'arène + les équipes. teamConfigs : [{colorIndex,controller,viewport,aiLevel}]
  init({ worldTheme, teamConfigs, mode, objective }) {
    this.mode = mode;
    this.objective = objective;
    this.engine.setTheme(worldTheme);

    const arena = makeArena(worldTheme);
    this.scene.add(arena.group);
    this._arenaGroup = arena.group;
    this.obstacles = arena.obstacles.slice();

    // Disposition des points de spawn selon le nombre d'équipes.
    const spawns = this._spawnLayout(teamConfigs.length);

    teamConfigs.forEach((cfg, i) => {
      const spawn = spawns[i];
      const toCenter = this._dirToCenter(spawn);
      const team = new Team(this, i, cfg.colorIndex, cfg.controller, {
        viewport: cfg.viewport, aiLevel: cfg.aiLevel, spawn, toCenter,
      });
      team.canRespawn = cfg.canRespawn !== undefined ? cfg.canRespawn : true;
      this.teams.push(team);
      // Obstacles du temple et du pad.
      this.obstacles.push({ x: spawn.x, z: spawn.z, r: 4.0 });
      this.obstacles.push(team.pad.obstacle);
      // Buddies initiaux (1 par défaut ; les missions/IA peuvent en mettre plus).
      const n = Math.max(1, cfg.initialBuddies || 1);
      for (let k = 0; k < n; k++) {
        const ang = k * 1.3;
        const bx = team.pad.x - toCenter.x * 2 + Math.cos(ang) * k * 1.4;
        const bz = team.pad.z - toCenter.z * 2 + Math.sin(ang) * k * 1.4;
        const b = this.spawnBuddy(team, bx, bz, 'fists');
        if (b && team.controller === 'human' && !team.activeBuddy) team.activeBuddy = b;
        if (b && team.controller === 'ai') b.order = k === 0 ? 'collect' : 'defend';
      }
    });

    // Marqueur central (domination / escorte).
    const ring = new THREE.Mesh(new THREE.RingGeometry(4.4, 5, 28),
      new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.35, side: THREE.DoubleSide }));
    ring.rotation.x = -Math.PI / 2; ring.position.y = 0.06; this.scene.add(ring);
    this.centerRing = ring;

    // Réticule de cible (un par équipe humaine) : montre la cible verrouillée.
    for (const t of this.teams) {
      if (t.controller !== 'human') continue;
      const ret = new THREE.Group();
      const r1 = new THREE.Mesh(new THREE.RingGeometry(0.95, 1.2, 4),
        new THREE.MeshBasicMaterial({ color: t.color.accent, transparent: true, opacity: 0.95, side: THREE.DoubleSide, depthTest: false }));
      r1.rotation.x = -Math.PI / 2; r1.position.y = 0.14;
      ret.add(r1); ret.renderOrder = 998; ret.visible = false;
      this.scene.add(ret); t._reticle = ret;
    }
  }

  _spawnLayout(n) {
    const h = CONFIG.arena.half - 9;
    if (n <= 2) return [{ x: 0, z: -h }, { x: 0, z: h }];
    return [{ x: -h, z: -h }, { x: h, z: -h }, { x: -h, z: h }, { x: h, z: h }];
  }
  _dirToCenter(spawn) {
    const d = Math.hypot(spawn.x, spawn.z) || 1;
    return { x: -spawn.x / d, z: -spawn.z / d };
  }

  // --- Buddies --------------------------------------------------------------
  spawnBuddy(team, x, z, weaponId = 'fists') {
    if (team.buddies.filter((b) => b.alive).length >= CONFIG.buddy.maxPerTeam) return null;
    const b = new Buddy(this, team, x, z, weaponId);
    b.group.userData.buddyRef = b;
    team.buddies.push(b);
    this.buddies.push(b);
    this.audio.spawn();
    this.particles.emit('magic', x, 1, z, { count: 14 });
    return b;
  }

  removeBuddy(b) {
    if (b._lastAttacker) this.creditKill(b._lastAttacker);
    const i = this.buddies.indexOf(b); if (i >= 0) this.buddies.splice(i, 1);
    const j = b.team.buddies.indexOf(b); if (j >= 0) b.team.buddies.splice(j, 1);
    if (b.team.activeBuddy === b) b.team.activeBuddy = b.team.aliveBuddies()[0] || null;
    b.dispose();
  }

  creditKill(team) { team.score++; }

  // --- Nuages ---------------------------------------------------------------
  spawnCloud(x, z, y = CONFIG.clouds.spawnHeight) {
    if (this.clouds.length >= CONFIG.clouds.maxOnGround) {
      const old = this.clouds.find((c) => c.landed);
      if (old) this._removeCloud(old);
    }
    const Cloud = makeCloudEntity(this, x, z, y);
    this.clouds.push(Cloud);
    return Cloud;
  }
  _removeCloud(c) {
    const i = this.clouds.indexOf(c); if (i >= 0) this.clouds.splice(i, 1);
    this.scene.remove(c.group);
  }
  nearestFreeCloud(pos) {
    let best = null, bd = Infinity;
    for (const c of this.clouds) {
      if (!c.landed) continue;
      const d = (c.pos.x - pos.x) ** 2 + (c.pos.z - pos.z) ** 2;
      if (d < bd) { bd = d; best = c; }
    }
    return best;
  }
  tryPickup(b) {
    if (!b.canCarry()) return false;
    const c = this.nearestFreeCloud(b.pos);
    if (!c) return false;
    if (Math.hypot(c.pos.x - b.pos.x, c.pos.z - b.pos.z) > CONFIG.buddy.pickupReach) return false;
    this._removeCloud(c);
    b.pickupCloud();
    this.audio.pickup();
    this.particles.emit('puff', b.pos.x, 1.5, b.pos.z, { count: 6 });
    return true;
  }
  tryDeposit(b) {
    if (!b.carried) return false;
    const pad = b.team.pad;
    if (Math.hypot(b.pos.x - pad.x, b.pos.z - pad.z) > CONFIG.pad.useRadius) return false;
    if (!pad.deposit(b.pos.x, b.pos.z)) return false;
    b.releaseCloudMesh();
    b.team.collected++;
    this.audio.drop();
    return true;
  }
  // Lâche le nuage porté au sol (hors du pad).
  dropCarried(b) {
    if (!b.carried) return false;
    b.releaseCloudMesh();
    this.spawnCloud(b.pos.x + Math.sin(b.facing) * 1.2, b.pos.z + Math.cos(b.facing) * 1.2, 1.4);
    this.audio.drop();
    return true;
  }

  // --- Craft (joueur) -------------------------------------------------------
  playerForge(team) {
    const b = team.activeBuddy;
    if (!b || !b.alive) return null;
    if (Math.hypot(b.pos.x - team.pad.x, b.pos.z - team.pad.z) > CONFIG.pad.useRadius) return null;
    const res = team.pad.forge();
    if (res) this.applyCraftResult(team, b, res); else this.audio.craftFail();
    return res;
  }
  playerSummon(team) {
    const b = team.activeBuddy;
    if (!b || !b.alive) return null;
    if (Math.hypot(b.pos.x - team.pad.x, b.pos.z - team.pad.z) > CONFIG.pad.useRadius) return null;
    const res = team.pad.summon();
    if (res) this.applyCraftResult(team, b, res); else this.audio.craftFail();
    return res;
  }

  applyCraftResult(team, builder, res) {
    const p = builder ? builder.pos : { x: team.pad.x, z: team.pad.z };
    this.particles.emit('magic', p.x, 1, p.z, { count: 30 });
    this.audio.craft();
    if (res.kind === 'weapon') {
      if (builder) builder.setWeapon(res.id);
    } else if (res.kind === 'vehicle') {
      if (builder) builder.enterVehicle(VEHICLES[res.id]);
    } else if (res.kind === 'teammate') {
      const def = TEAMMATES[res.id];
      const nb = this.spawnBuddy(team, team.pad.x - team.toCenter.x * 2.5, team.pad.z - team.toCenter.z * 2.5, def.weapon);
      if (nb) { nb.maxHp = def.hp; nb.hp = def.hp; nb.speed = def.speed; nb.order = 'follow'; }
    }
  }

  // --- Projectiles ----------------------------------------------------------
  _getProjMesh(type, color) {
    const key = type + color;
    const pool = (this._projPool[key] ||= []);
    let m = pool.pop();
    if (!m) m = makeProjectile(type, color);
    m.visible = true; this.scene.add(m);
    return m;
  }
  _releaseProjMesh(p) {
    this.scene.remove(p.mesh);
    (this._projPool[p.weapon.projType + p.weapon.projColor] ||= []).push(p.mesh);
  }
  spawnProjectile({ x, y, z, dx, dz, weapon, team, owner }) {
    if (this.projectiles.length >= CONFIG.projectile.maxAlive) return;
    const mesh = this._getProjMesh(weapon.projType, weapon.projColor);
    mesh.position.set(x, y, z);
    const p = {
      mesh, x, y, z, vx: dx * weapon.projSpeed, vz: dz * weapon.projSpeed,
      weapon, team, owner, life: (weapon.range / weapon.projSpeed) + 0.1, dead: false,
    };
    mesh.rotation.y = Math.atan2(dx, dz);
    this.projectiles.push(p);
  }

  meleeAttack(buddy, w, dx, dz) {
    const reach = w.range;
    for (const b of this.buddies) {
      if (b.team === buddy.team || !b.alive) continue;
      const ox = b.pos.x - buddy.pos.x, oz = b.pos.z - buddy.pos.z;
      const d = Math.hypot(ox, oz);
      if (d > reach) continue;
      if ((ox / d) * dx + (oz / d) * dz < 0.3) continue;   // doit être devant
      b._lastAttacker = buddy.team;
      b.takeDamage(w.damage, buddy.team);
      const kb = b.vehicle ? 0.8 : 4.0;
      b.vel.x += dx * kb; b.vel.z += dz * kb;
      this.particles.emit('hit', b.pos.x, 1.2, b.pos.z, { color: w.projColor });
    }
    // Temples ennemis au corps à corps (toutes les équipes adverses).
    for (const t of this.teams) {
      if (t === buddy.team || t.templeDestroyed) continue;
      const tp = t.templeGroup.position;
      if (Math.hypot(tp.x - buddy.pos.x, tp.z - buddy.pos.z) < reach + CONFIG.temple.radius) t.damageTemple(w.damage);
    }
  }

  _updateProjectiles(dt) {
    for (let i = this.projectiles.length - 1; i >= 0; i--) {
      const p = this.projectiles[i];
      p.life -= dt;
      // Tête chercheuse (harpies).
      if (p.weapon.homing) {
        const t = this._nearestEnemyOfTeam(p.team, p.x, p.z);
        if (t) {
          const tx = t.pos.x - p.x, tz = t.pos.z - p.z, l = Math.hypot(tx, tz) || 1;
          p.vx += (tx / l * p.weapon.projSpeed - p.vx) * p.weapon.homing;
          p.vz += (tz / l * p.weapon.projSpeed - p.vz) * p.weapon.homing;
        }
      }
      p.x += p.vx * dt; p.z += p.vz * dt;
      p.mesh.position.set(p.x, p.y, p.z);
      if (p.weapon.projType === 'fire' || p.weapon.projType === 'harpy')
        this.particles.emit('trail', p.x, p.y, p.z, { color: p.weapon.projColor, size: 0.5 });

      let hit = false;
      // Collision buddies ennemis.
      for (const b of this.buddies) {
        if (b.team === p.team || !b.alive) continue;
        if (Math.hypot(b.pos.x - p.x, b.pos.z - p.z) < b.radius + p.weapon.projSize + 0.3) {
          this._applyProjectileHit(p, b);
          hit = true; break;
        }
      }
      // Collision temple ennemi (toutes les équipes adverses).
      if (!hit) {
        for (const t of this.teams) {
          if (t === p.team || t.templeDestroyed) continue;
          const tp = t.templeGroup.position;
          if (Math.hypot(tp.x - p.x, tp.z - p.z) < CONFIG.temple.radius) {
            t.damageTemple(p.weapon.damage);
            this.particles.emit('hit', p.x, p.y, p.z, { color: p.weapon.projColor });
            hit = true; break;
          }
        }
      }
      if (hit || p.life <= 0 || Math.abs(p.x) > CONFIG.arena.half || Math.abs(p.z) > CONFIG.arena.half) {
        this._releaseProjMesh(p);
        this.projectiles.splice(i, 1);
      }
    }
  }

  _applyProjectileHit(p, b) {
    const w = p.weapon;
    b._lastAttacker = p.team;
    b.takeDamage(w.damage, p.team);
    // Recul (impact) dans la direction du projectile.
    const kb = b.vehicle ? 1.0 : 5.0, l = Math.hypot(p.vx, p.vz) || 1;
    b.vel.x += (p.vx / l) * kb; b.vel.z += (p.vz / l) * kb;
    this.particles.emit('hit', p.x, p.y, p.z, { color: w.projColor });
    this.audio.hurt();
    // Dégâts de zone.
    if (w.aoe) {
      this.particles.emit('explosion', p.x, p.y, p.z, { count: 18 });
      this.engine.addShake(0.35);
      for (const o of this.buddies) {
        if (o === b || o.team === p.team || !o.alive) continue;
        if (Math.hypot(o.pos.x - p.x, o.pos.z - p.z) < w.aoe) { o._lastAttacker = p.team; o.takeDamage(w.damage * 0.6, p.team); }
      }
    }
    // Ricochet (arc électrique).
    if (w.chain) {
      let chained = 0;
      for (const o of this.buddies) {
        if (chained >= w.chain || o === b || o.team === p.team || !o.alive) continue;
        if (Math.hypot(o.pos.x - p.x, o.pos.z - p.z) < 5) {
          o._lastAttacker = p.team; o.takeDamage(w.damage * 0.5, p.team);
          this.particles.emit('hit', o.pos.x, 1.2, o.pos.z, { color: w.projColor });
          chained++;
        }
      }
    }
  }

  // --- Requêtes -------------------------------------------------------------
  enemyTempleFor(team) {
    for (const t of this.teams) if (t !== team && !t.templeDestroyed) return t.templeGroup;
    return null;
  }
  _nearestEnemyOfTeam(team, x, z) {
    let best = null, bd = Infinity;
    for (const b of this.buddies) {
      if (b.team === team || !b.alive) continue;
      const d = (b.pos.x - x) ** 2 + (b.pos.z - z) ** 2;
      if (d < bd) { bd = d; best = b; }
    }
    return best;
  }
  nearestEnemyBuddy(b) { return this._nearestEnemyOfTeam(b.team, b.pos.x, b.pos.z); }
  nearestEnemy(b) {
    const e = this.nearestEnemyBuddy(b);
    return { buddy: e, dist: e ? Math.hypot(e.pos.x - b.pos.x, e.pos.z - b.pos.z) : Infinity };
  }

  // --- Boucle ---------------------------------------------------------------
  update(dt) {
    if (this.over) return;
    this.time += dt;

    // Vagues de nuages.
    this.waveTimer -= dt;
    if (this.waveTimer <= 0) {
      this.waveTimer = CONFIG.clouds.waveInterval;
      for (let k = 0; k < CONFIG.clouds.perWave; k++) {
        const x = (Math.random() * 2 - 1) * (CONFIG.arena.half - 6);
        const z = (Math.random() * 2 - 1) * (CONFIG.arena.half - 6);
        this.spawnCloud(x, z);
      }
    }
    for (const c of this.clouds) c.update(dt);

    // IA d'équipe (directeurs).
    for (const t of this.teams) if (t.ai) t.ai.update(dt);
    // Comportement par ordre (tous sauf le buddy actif d'un humain).
    for (const b of this.buddies) {
      const human = b.team.controller === 'human' && b === b.team.activeBuddy;
      if (!human) updateBuddyBehavior(b, this);
    }
    // Mise à jour des buddies + projectiles + pads.
    for (const b of this.buddies) b.update(dt, this.time);
    this._updateProjectiles(dt);
    for (const t of this.teams) t.pad.update(this.time);

    // Réticules de cible (équipes humaines).
    for (const t of this.teams) {
      if (t.controller !== 'human' || !t._reticle) continue;
      const b = t.activeBuddy, tg = (b && b.alive) ? b.target : null;
      if (tg && tg.alive !== false) {
        const tp = tg.pos || tg.position;
        t._reticle.visible = true;
        t._reticle.position.set(tp.x, 0.14, tp.z);
        t._reticle.rotation.y += dt * 3;
      } else t._reticle.visible = false;
    }

    // Pulsation des cœurs de temple.
    for (const t of this.teams) if (t.core && !t.templeDestroyed) {
      t.core.rotation.y += dt * 1.2;
      t.core.position.y = 2.4 + Math.sin(this.time * 2) * 0.12;
    }

    // Respawn anti-blocage.
    for (const t of this.teams) this._handleRespawn(t, dt);

    // Domination (suivi du centre).
    this._updateDomination(dt);

    // Conditions de victoire/défaite.
    this._checkObjective(dt);
  }

  _handleRespawn(team, dt) {
    if (team.templeDestroyed || !team.canRespawn) return;
    if (team.aliveBuddies().length > 0) { team.respawnTimer = 0; return; }
    team.respawnTimer += dt;
    if (team.respawnTimer >= CONFIG.buddy.respawnDelay) {
      team.respawnTimer = 0;
      const b = this.spawnBuddy(team, team.spawn.x + team.toCenter.x * 3, team.spawn.z + team.toCenter.z * 3, 'fists');
      if (b && team.controller === 'human') team.activeBuddy = b;
    }
  }

  _updateDomination(dt) {
    if (!this.objective || this.objective.type !== 'domination') return;
    const counts = this.teams.map((t) => t.aliveBuddies().filter((b) =>
      Math.hypot(b.pos.x, b.pos.z) < 5).length);
    let lead = -1, leadN = 0, tie = false;
    counts.forEach((n, i) => { if (n > leadN) { leadN = n; lead = i; tie = false; } else if (n === leadN && n > 0) tie = true; });
    if (lead >= 0 && leadN > 0 && !tie) this.teams[lead].dominationTime += dt;
    this.centerRing.material.color.setHex(lead >= 0 && !tie ? this.teams[lead].color.primary : 0xffffff);
  }

  _humanTeam() { return this.teams.find((t) => t.controller === 'human') || this.teams[0]; }

  _checkObjective(dt) {
    const o = this.objective; if (!o) return;
    if (this.mode === 'versus') return this._checkVersus(o);

    const me = this._humanTeam();
    const enemies = this.teams.filter((t) => t !== me);

    // Défaite commune : temple du joueur détruit.
    if (me.templeDestroyed) return this._end('lose');

    switch (o.type) {
      case 'eliminate':
      case 'boss':
        if (enemies.every((t) => t.aliveBuddies().length === 0 && !t.canRespawn)) this._end('win');
        break;
      case 'destroy_base':
        if (enemies.every((t) => t.templeDestroyed)) this._end('win');
        break;
      case 'collect':
        if (me.collected >= (o.N || 10)) this._end('win');
        break;
      case 'survive':
        if (this.time >= (o.T || 60)) this._end('win');
        break;
      case 'domination':
        if (me.dominationTime >= (o.T || 60)) this._end('win');
        else if (enemies.some((t) => t.dominationTime >= (o.T || 60))) this._end('lose');
        break;
      case 'escort': {
        // Amener un véhicule allié près du temple ennemi.
        const et = this.enemyTempleFor(me);
        if (et) {
          const reached = me.aliveBuddies().some((b) => b.vehicle &&
            Math.hypot(b.pos.x - et.position.x, b.pos.z - et.position.z) < 7);
          if (reached) this._end('win');
        }
        break;
      }
      case 'deathmatch':
        if (me.score >= (o.score || 10)) this._end('win');
        else if (enemies.some((t) => t.score >= (o.score || 10))) this._end('lose');
        break;
    }
  }

  // Multijoueur : détermine un vainqueur parmi toutes les équipes.
  _checkVersus(o) {
    let winner = null;
    if (o.type === 'deathmatch') {
      winner = this.teams.find((t) => t.score >= (o.score || 15));
    } else if (o.type === 'domination') {
      winner = this.teams.find((t) => t.dominationTime >= (o.T || 45));
    } else if (o.type === 'destroy_base') {
      const standing = this.teams.filter((t) => !t.templeDestroyed);
      if (standing.length === 1 && this.teams.length > 1) winner = standing[0];
    }
    if (winner) { this.winnerTeam = winner; this._end('over'); }
  }

  _end(result) {
    if (this.over) return;
    this.over = true;
    this.result = result;
    if (result === 'lose') this.audio.defeat(); else this.audio.victory();
    if (this.onEnd) this.onEnd(result);
  }

  dispose() {
    for (const b of this.buddies.slice()) b.dispose();
    for (const c of this.clouds.slice()) this.scene.remove(c.group);
    for (const p of this.projectiles) this.scene.remove(p.mesh);
    for (const t of this.teams) { this.scene.remove(t.templeGroup); this.scene.remove(t.pad.group); if (t._reticle) this.scene.remove(t._reticle); }
    if (this._arenaGroup) this.scene.remove(this._arenaGroup);
    if (this.centerRing) this.scene.remove(this.centerRing);
    this.buddies = []; this.clouds = []; this.projectiles = []; this.teams = [];
  }
}

// --- Entité nuage (fonction usine pour éviter une classe exportée de plus) ---
import { makeCloud } from '../core/assets.js';
function makeCloudEntity(world, x, z, y) {
  const group = makeCloud();
  group.position.set(x, y, z);
  world.scene.add(group);
  return {
    group,
    pos: group.position,
    landed: y <= 0.9,
    update(dt) {
      if (!this.landed) {
        this.pos.y -= CONFIG.clouds.fallSpeed * dt;
        group.rotation.y += dt;
        if (this.pos.y <= 0.8) {
          this.pos.y = 0.8; this.landed = true;
          world.particles.emit('puff', x, 0.8, z, { count: 8 });
        }
      } else {
        this.pos.y = 0.8 + Math.sin(world.time * 2 + x) * 0.08;
        group.rotation.y += dt * 0.5;
      }
    },
  };
}

// =============================================================================
//  buddy.js — Entité "buddy" (personnage). Déplacement avec évitement
//  d'obstacles, combat à visée automatique assistée, transport de nuages,
//  équipement d'armes/véhicules et animation procédurale.
// =============================================================================

import * as THREE from 'three';
import { CONFIG } from '../data/config.js';
import { getWeapon } from '../data/weapons.js';
import { makeBuddy, makeHeldWeapon, makeVehicle, makeCloud } from '../core/assets.js';

const HALF = CONFIG.arena.half;
const _v = new THREE.Vector3();

let _idCounter = 0;

export class Buddy {
  constructor(world, team, x, z, weaponId = 'fists') {
    this.id = ++_idCounter;
    this.world = world;
    this.team = team;
    this.alive = true;
    this.radius = CONFIG.buddy.radius;

    this.group = makeBuddy({ primary: team.color.primary, accent: team.color.accent });
    this.group.position.set(x, 0, z);
    this._charChildren = this.group.children.filter((c) => c !== this.group.userData.ring);
    world.scene.add(this.group);

    this.vel = new THREE.Vector3();
    this.facing = 0;
    this.speed = CONFIG.buddy.baseSpeed;
    this.maxHp = CONFIG.buddy.baseHP;
    this.hp = this.maxHp;

    this.moveTarget = null;     // {x,z} (tap-to-move)
    this.joy = null;            // {x,z} direction normalisée (joystick)
    this.order = 'follow';      // ordre IA (ignoré si actif/joueur)
    this.isActive = false;      // contrôlé manuellement par un humain ?

    this.target = null;         // cible de tir (buddy ou temple)
    this.wantFire = false;
    this.fireCD = 0;

    this.carried = false;
    this._cloudMesh = null;

    this.vehicle = null;
    this._vehicleMesh = null;
    this._heldMesh = null;

    this._hitFlash = 0;
    this.setWeapon(weaponId);
    this._buildHpBar();
  }

  get pos() { return this.group.position; }

  // --- Équipement -----------------------------------------------------------
  setWeapon(id) {
    const w = getWeapon(id);
    this.weaponId = id;
    this.weapon = w;
    this.ammo = w.ammo;
    if (this._heldMesh) { this.group.userData.hand.remove(this._heldMesh); this._heldMesh = null; }
    if (id !== 'fists') {
      this._heldMesh = makeHeldWeapon(w);
      this.group.userData.hand.add(this._heldMesh);
    }
  }

  enterVehicle(def) {
    this.vehicle = def;
    this.maxHp = def.hp; this.hp = def.hp;
    this.speed = def.speed;
    this.flying = !!def.flying;
    this.setWeapon(def.weapon);
    for (const c of this._charChildren) c.visible = false;     // masque le perso
    if (this._heldMesh) this._heldMesh.visible = false;
    this._vehicleMesh = makeVehicle(def.id, this.team.color.primary);
    this.group.add(this._vehicleMesh);
  }

  // --- Nuages ---------------------------------------------------------------
  canCarry() { return !this.carried && !this.vehicle; }
  pickupCloud() {
    if (!this.canCarry()) return false;
    this.carried = true;
    this._cloudMesh = makeCloud();
    this._cloudMesh.scale.setScalar(CONFIG.clouds.size * 0.7);
    this._cloudMesh.position.set(0, 2.5, 0);
    this.group.add(this._cloudMesh);
    return true;
  }
  releaseCloudMesh() {
    if (this._cloudMesh) { this.group.remove(this._cloudMesh); this._cloudMesh = null; }
    this.carried = false;
  }

  // --- Dégâts / mort --------------------------------------------------------
  takeDamage(dmg, fromTeam) {
    if (!this.alive) return;
    this.hp -= dmg;
    this._hitFlash = 0.12;
    if (fromTeam && !this.target) this._lastAttacker = fromTeam;
    if (this.hp <= 0) this.die();
  }

  die() {
    if (!this.alive) return;
    this.alive = false;
    const p = this.pos;
    this.world.particles.emit('explosion', p.x, (this.vehicle ? 1.2 : 1.0), p.z, { big: !!this.vehicle });
    this.world.audio.explosion(!!this.vehicle);
    this.world.engine.addShake(this.vehicle ? 0.6 : 0.28);
    if (this.carried) this.world.spawnCloud(p.x, p.z, 1.2);   // relâche le nuage
    this.world.removeBuddy(this);
  }

  // --- Ciblage / tir --------------------------------------------------------
  acquireTarget() {
    const range = this.weapon.range > 6 ? CONFIG.buddy.aimAssistRange : this.weapon.range + 1;
    let best = null, bd = range * range;
    for (const b of this.world.buddies) {
      if (b.team === this.team || !b.alive) continue;
      const d = (b.pos.x - this.pos.x) ** 2 + (b.pos.z - this.pos.z) ** 2;
      if (d < bd) { bd = d; best = b; }
    }
    // À défaut, vise le temple ennemi si on est en mode attaque.
    if (!best && this.order === 'attack') {
      const et = this.world.enemyTempleFor(this.team);
      if (et) best = et;
    }
    this.target = best;
  }

  fire() {
    if (this.fireCD > 0 || !this.alive) return;
    const w = this.weapon;
    if (this.ammo <= 0) { this.setWeapon('fists'); return; }

    // Direction de visée (assistée) : vers la cible, sinon vers l'orientation.
    let dx = Math.sin(this.facing), dz = Math.cos(this.facing);
    if (this.target && this.target.alive !== false) {
      const tp = this.target.pos || this.target.position;
      dx = tp.x - this.pos.x; dz = tp.z - this.pos.z;
      const l = Math.hypot(dx, dz) || 1; dx /= l; dz /= l;
      this.facing = Math.atan2(dx, dz);
    }

    this.fireCD = 1 / w.fireRate;
    if (this.ammo !== Infinity) this.ammo--;

    if (w.projType === 'melee') {
      this.world.meleeAttack(this, w, dx, dz);
      this.world.audio.shoot('melee');
    } else {
      const muzzleY = this.vehicle ? 1.4 : 1.3;
      const mx = this.pos.x + dx * 1.0, mz = this.pos.z + dz * 1.0;
      this.world.particles.emit('muzzle', mx, muzzleY, mz, { color: w.projColor });
      for (let i = 0; i < (w.count || 1); i++) {
        const spread = (Math.random() - 0.5) * w.spread + (i - (w.count - 1) / 2) * w.spread;
        const a = Math.atan2(dx, dz) + spread;
        this.world.spawnProjectile({
          x: mx, y: muzzleY, z: mz,
          dx: Math.sin(a), dz: Math.cos(a),
          weapon: w, team: this.team, owner: this,
        });
      }
      this.world.audio.shoot(w.projType);
    }
  }

  // --- Boucle de mise à jour ------------------------------------------------
  update(dt, t) {
    if (!this.alive) return;
    if (this.fireCD > 0) this.fireCD -= dt;
    if (this._hitFlash > 0) this._hitFlash -= dt;

    // 1) Direction désirée (joystick prioritaire, sinon point cible).
    let dirx = 0, dirz = 0, moving = false;
    if (this.joy) { dirx = this.joy.x; dirz = this.joy.z; moving = (dirx || dirz) !== 0; }
    else if (this.moveTarget) {
      dirx = this.moveTarget.x - this.pos.x; dirz = this.moveTarget.z - this.pos.z;
      const d = Math.hypot(dirx, dirz);
      if (d < 0.45) { this.moveTarget = null; dirx = dirz = 0; }
      else { dirx /= d; dirz /= d; moving = true; }
    }

    // 2) Évitement d'obstacles + séparation des alliés (steering simple).
    if (moving && !this.flying) {
      for (const o of this.world.obstacles) {
        const ox = this.pos.x - o.x, oz = this.pos.z - o.z;
        const dist = Math.hypot(ox, oz);
        const safe = o.r + this.radius + 1.4;
        if (dist < safe && dist > 0.001) {
          const push = (safe - dist) / safe;
          dirx += (ox / dist) * push * 1.8;
          dirz += (oz / dist) * push * 1.8;
          // composante tangentielle pour contourner
          dirx += (-oz / dist) * push * 0.6;
          dirz += (ox / dist) * push * 0.6;
        }
      }
    }
    if (moving) {
      for (const b of this.world.buddies) {
        if (b === this || !b.alive) continue;
        const ox = this.pos.x - b.pos.x, oz = this.pos.z - b.pos.z;
        const dist = Math.hypot(ox, oz);
        if (dist < 1.5 && dist > 0.001) { dirx += (ox / dist) * 0.5; dirz += (oz / dist) * 0.5; }
      }
      const dl = Math.hypot(dirx, dirz) || 1; dirx /= dl; dirz /= dl;
    }

    // 3) Intégration de la vitesse.
    const desiredX = dirx * this.speed, desiredZ = dirz * this.speed;
    const accel = CONFIG.buddy.accel * dt;
    this.vel.x += (desiredX - this.vel.x) * Math.min(1, accel / this.speed * 2);
    this.vel.z += (desiredZ - this.vel.z) * Math.min(1, accel / this.speed * 2);
    if (!moving) { this.vel.x *= 0.8; this.vel.z *= 0.8; }
    this.pos.x += this.vel.x * dt;
    this.pos.z += this.vel.z * dt;

    // Bornes de l'arène.
    const lim = HALF - 1.4;
    this.pos.x = Math.max(-lim, Math.min(lim, this.pos.x));
    this.pos.z = Math.max(-lim, Math.min(lim, this.pos.z));

    // Altitude (véhicules volants).
    const targetY = this.flying ? 3.4 : 0;
    this.pos.y += (targetY - this.pos.y) * Math.min(1, dt * 4);

    // 4) Orientation.
    const sp = Math.hypot(this.vel.x, this.vel.z);
    if (sp > 0.3 && !this.target) this.facing = Math.atan2(this.vel.x, this.vel.z);
    this.group.rotation.y += (this.facing - this.group.rotation.y) * Math.min(1, dt * 12);

    // 5) Combat : acquisition de cible + tir auto-assisté.
    this.acquireTarget();
    if (this.wantFire) {
      const inRange = this._targetInRange();
      if (inRange || this.weapon.projType === 'melee') this.fire();
    }

    // 6) Animation procédurale.
    this._animate(dt, t, sp);
    this._updateHpBar();
  }

  _targetInRange() {
    if (!this.target) return this.weapon.range > 12;   // armes longue portée tirent quand même
    const tp = this.target.pos || this.target.position;
    const d = Math.hypot(tp.x - this.pos.x, tp.z - this.pos.z);
    return d <= this.weapon.range + 1;
  }

  _animate(dt, t, sp) {
    const u = this.group.userData;
    if (this.vehicle) {
      if (this._vehicleMesh && this.flying) this._vehicleMesh.position.y = Math.sin(t * 4) * 0.12;
      return;
    }
    u.walkPhase += dt * (4 + sp * 1.5);
    const swing = Math.min(1, sp / this.speed) * 0.8;
    const s = Math.sin(u.walkPhase) * swing;
    u.legL.rotation.x = s; u.legR.rotation.x = -s;
    if (this.carried) { u.armL.rotation.x = -2.2; u.armR.rotation.x = -2.2; }
    else { u.armL.rotation.x = -s * 0.7; u.armR.rotation.x = s * 0.7; }
    u.head.position.y = 1.62 + Math.abs(Math.sin(u.walkPhase)) * 0.04 * swing;
    // Punch de dégâts.
    const k = this._hitFlash > 0 ? 1.12 : 1.0;
    this.group.scale.setScalar(0.9 * k);
  }

  // --- Barre de vie (orientée vers la caméra iso, commune à toutes les vues) -
  _buildHpBar() {
    const g = new THREE.Group();
    const bg = new THREE.Mesh(new THREE.PlaneGeometry(1.2, 0.16),
      new THREE.MeshBasicMaterial({ color: 0x111111, transparent: true, opacity: 0.6, depthTest: false }));
    const fill = new THREE.Mesh(new THREE.PlaneGeometry(1.2, 0.16),
      new THREE.MeshBasicMaterial({ color: 0x4fe06a, depthTest: false }));
    fill.position.z = 0.001;
    g.add(bg); g.add(fill);
    g.position.y = 2.9;
    const off = CONFIG.camera.offset;
    g.rotation.x = -Math.atan2(off.z, off.y);   // face à la caméra iso
    g.renderOrder = 999;
    this.group.add(g);
    this._hpBar = g; this._hpFill = fill;
  }
  _updateHpBar() {
    const f = Math.max(0, this.hp / this.maxHp);
    this._hpFill.scale.x = f || 0.0001;
    this._hpFill.position.x = -(1 - f) * 0.6;
    this._hpFill.material.color.setHex(f > 0.5 ? 0x4fe06a : (f > 0.25 ? 0xf1c40f : 0xe04f4f));
    this._hpBar.visible = f < 1;     // caché à pleine vie
    if (this.vehicle) this._hpBar.position.y = 3.4;
  }

  dispose() {
    this.world.scene.remove(this.group);
  }
}

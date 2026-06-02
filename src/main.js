// =============================================================================
//  main.js — Point d'entrée. Assemble moteur, particules, audio, entrées,
//  monde, HUD et menus. Gère le routage tactile (raycast), le suivi caméra,
//  la boucle de jeu, la pause et le cycle de vie d'une partie.
// =============================================================================

import * as THREE from 'three';
import { CONFIG } from './data/config.js';
import { Engine } from './core/engine.js';
import { ParticleSystem } from './core/particles.js';
import { InputManager } from './core/input.js';
import { audio } from './core/audio.js';
import { World } from './game/world.js';
import { HUD } from './ui/hud.js';
import { Menus } from './ui/menus.js';
import { buildMatch } from './modes/modes.js';

class Game {
  constructor() {
    this.container = document.getElementById('game-root');
    this.uiRoot = document.getElementById('ui-layer');

    this.engine = new Engine(this.container);
    this.particles = new ParticleSystem(this.engine.scene);
    this.input = new InputManager(this.engine.renderer.domElement);
    this.input.setPlayerResolver((x, y) => this.engine.playerAt(x, y));

    this.world = null;
    this.hud = null;
    this.context = null;
    this.paused = false;
    this.running = false;
    this._lastIntent = null;

    this._ray = new THREE.Raycaster();
    this._ndc = new THREE.Vector2();
    this._plane = new THREE.Plane(new THREE.Vector3(0, 1, 0), 0);
    this._tmpV = new THREE.Vector3();

    this.handlers = {
      fireDown: (team) => { if (team.activeBuddy) team.activeBuddy.wantFire = true; },
      fireUp: (team) => { if (team.activeBuddy) team.activeBuddy.wantFire = false; },
      action: (team) => this.doAction(team),
      forge: (team) => { if (this.world) this._craftFeedback(team, this.world.playerForge(team), 'forge'); },
      summon: (team) => { if (this.world) this._craftFeedback(team, this.world.playerSummon(team), 'summon'); },
      depositColumn: (team, col) => {
        if (!this.world) return;
        const r = this.world.depositToColumn(team, col);
        if (this.hud && !r.ok) this.hud.toast(team, this._reasonMsg(r.reason, 'deposit'), false);
      },
      battalion: (team) => {
        const seq = ['off', 'wedge', 'line', 'column', 'circle'];
        team.formation = seq[(seq.indexOf(team.formation) + 1) % seq.length];
        audio.uiClick();
      },
      switchBuddy: (team, b) => { if (b.alive) { team.activeBuddy = b; audio.uiClick(); } },
      joystick: (team, dx, dy) => {
        const b = team.activeBuddy; if (!b) return;
        if (Math.hypot(dx, dy) > 0.2) { b.joy = { x: dx, z: dy }; b.moveTarget = null; }
        else b.joy = null;
      },
    };

    this._wireInput();
    this._buildPauseButton();

    this.menus = new Menus(document.getElementById('menu-layer'), {
      onStart: (intent) => this.startMatch(intent),
      onResume: () => this.resume(),
      onRestart: () => this.startMatch(this._lastIntent),
      onQuit: () => this.quit(),
    });

    window.addEventListener('resize', () => { if (this.hud) this.hud.layout(); });

    // Masque l'écran de chargement.
    const boot = document.getElementById('boot');
    if (boot) boot.style.display = 'none';

    this.engine.start((dt) => this.update(dt));
  }

  // --- Routage tactile monde ------------------------------------------------
  _wireInput() {
    this.input.on('tap', (e) => this.onTap(e));
    this.input.on('holdstart', (e) => this.onHoldStart(e));
    this.input.on('holdmove', (e) => { if (this.hud) this.hud.moveRadial(e.x, e.y); });
    this.input.on('holdend', () => { if (this.hud) { const r = this.hud.hideRadial(); if (r) audio.uiClick(); } });
  }

  _humanTeam(vp) { return this.world && this.world.teams.find((t) => t.controller === 'human' && t.viewport === vp); }

  raycast(player, x, y) {
    const vp = this.engine.viewports[player]; if (!vp) return {};
    const r = vp.rect, H = this.container.clientHeight, topY = H - (r.y + r.h);
    const nx = ((x - r.x) / r.w) * 2 - 1;
    const ny = -(((y - topY) / r.h) * 2 - 1);
    this._ndc.set(nx, ny);
    this._ray.setFromCamera(this._ndc, vp.camera);
    const groups = this.world.buddies.map((b) => b.group);
    const hits = this._ray.intersectObjects(groups, true);
    if (hits.length) {
      let o = hits[0].object;
      while (o && !o.userData.buddyRef) o = o.parent;
      if (o && o.userData.buddyRef) return { buddy: o.userData.buddyRef };
    }
    const pt = new THREE.Vector3();
    if (this._ray.ray.intersectPlane(this._plane, pt)) return { point: pt };
    return {};
  }

  onTap({ player, x, y }) {
    if (!this.world || this.paused || this.world.over) return;
    const team = this._humanTeam(player); if (!team) return;
    const hit = this.raycast(player, x, y);
    if (hit.buddy) {
      if (hit.buddy.team === team && hit.buddy.alive) { team.activeBuddy = hit.buddy; audio.uiClick(); }
      else if (hit.buddy.team !== team && team.activeBuddy) {
        team.activeBuddy.target = hit.buddy;
        team.activeBuddy.moveTarget = { x: hit.buddy.pos.x, z: hit.buddy.pos.z };
        team.activeBuddy.joy = null;
      }
    } else if (hit.point && team.activeBuddy) {
      team.activeBuddy.moveTarget = { x: hit.point.x, z: hit.point.z };
      team.activeBuddy.joy = null;
    }
  }

  onHoldStart({ player, x, y }) {
    if (!this.world || this.paused || this.world.over) return;
    const team = this._humanTeam(player); if (!team) return;
    const hit = this.raycast(player, x, y);
    if (hit.buddy && hit.buddy.team === team && hit.buddy !== team.activeBuddy && hit.buddy.alive)
      this.hud.showRadial(x, y, hit.buddy);
  }

  doAction(team) {
    const b = team.activeBuddy; if (!b || !b.alive) return;
    const nearPad = Math.hypot(b.pos.x - team.pad.x, b.pos.z - team.pad.z) < CONFIG.pad.useRadius;
    if (b.carried && nearPad) this.world.tryDeposit(b);
    else if (b.carried) this.world.dropCarried(b);
    else if (!this.world.tryPickup(b) && this.hud) this.hud.toast(team, 'Aucun nuage à portée — va en ramasser un', false);
  }

  // Retour visuel d'un craft (forge/invocation) : toast succès ou raison d'échec.
  _craftFeedback(team, r, kind) {
    if (!this.hud || !r) return;
    if (r.ok) this.hud.toast(team, (kind === 'summon' ? '✨ ' : '⚒️ ') + r.label + ' !', true);
    else this.hud.toast(team, this._reasonMsg(r.reason, kind), false);
  }
  _reasonMsg(reason, kind) {
    switch (reason) {
      case 'far': return 'Approche-toi du pad de ton équipe';
      case 'empty': return 'Empile d\'abord des nuages sur le pad';
      case 'no-buddy': return 'Aucun buddy actif';
      case 'no-cloud': return 'Ramasse un nuage d\'abord (bouton Action)';
      case 'col-full': return 'Colonne pleine (ou pad plein : 8 max)';
      case 'max': return 'Équipe pleine (4 buddies max)';
      case 'shape':
        return kind === 'summon'
          ? 'Invocation : empile 2, 3 ou 4 nuages dans UNE seule colonne'
          : 'Aucune recette pour ce motif (voir 📜 Recettes)';
      default: return '—';
    }
  }

  // --- Cycle de vie d'une partie --------------------------------------------
  startMatch(intent) {
    if (!intent) return;
    this._lastIntent = intent;
    this.cleanup();

    const m = buildMatch(intent);
    this.context = m.context;

    this.engine.setupViewports(m.playerCount);
    this.world = new World(this.engine, this.particles, audio);
    this.world.onEnd = (res) => this.onEnd(res);
    this.world.init({ worldTheme: m.worldTheme, teamConfigs: m.teamConfigs, mode: m.mode, objective: m.objective });

    this.hud = new HUD(this.uiRoot, this.engine, this.world, this.handlers);

    // Recentrage caméra immédiat sur chaque joueur.
    const off = CONFIG.camera.offset;
    for (const t of this.world.teams) {
      if (t.controller !== 'human') continue;
      const vp = this.engine.viewports[t.viewport]; if (!vp) continue;
      const p = (t.activeBuddy ? t.activeBuddy.pos : { x: t.spawn.x, y: 0, z: t.spawn.z });
      vp.target.set(p.x, 0, p.z);
      vp.camera.position.set(p.x + off.x, off.y, p.z + off.z);
      vp.camera.lookAt(p.x, 1, p.z);
    }

    this.menus.hide();
    this.paused = false;
    this.running = true;
    this.pauseBtn.style.display = 'flex';
    audio.init();
    audio.startMusic();
  }

  onEnd(result) {
    this.running = false;
    this.pauseBtn.style.display = 'none';
    if (this.world.mode === 'versus') {
      const w = this.world.winnerTeam;
      this.menus.showResults('win', { type: 'versus', versusWinner: w ? `${w.color.emoji} ${w.color.name}` : 'Égalité' });
    } else {
      this.menus.showResults(result, this.context || { type: 'skirmish' });
    }
  }

  pause() { if (!this.running || this.paused) return; this.paused = true; this.menus.showPause(this.context); }
  resume() { this.paused = false; }
  quit() { this.cleanup(); this.running = false; this.paused = false; this.pauseBtn.style.display = 'none'; }

  cleanup() {
    if (this.hud) { this.hud.dispose(); this.hud = null; }
    if (this.world) { this.world.dispose(); this.world = null; }
  }

  _buildPauseButton() {
    const b = document.createElement('button');
    b.className = 'pause-btn hud-interactive';
    b.textContent = '⏸';
    b.style.display = 'none';
    b.addEventListener('pointerdown', (e) => { e.preventDefault(); this.pause(); });
    this.uiRoot.appendChild(b);
    this.pauseBtn = b;
  }

  // --- Boucle ---------------------------------------------------------------
  update(dt) {
    if (!this.world || this.paused || this.world.over) return;
    this.world.update(dt);
    this.particles.update(dt);

    const off = CONFIG.camera.offset;
    for (const t of this.world.teams) {
      if (t.controller !== 'human') continue;
      const vp = this.engine.viewports[t.viewport]; if (!vp) continue;
      const tgt = (t.activeBuddy && t.activeBuddy.alive) ? t.activeBuddy.pos : t.templeGroup.position;
      this.engine.followTarget(vp, this._tmpV.set(tgt.x, tgt.y, tgt.z));
    }
    audio.setIntensity(Math.min(1, this.world.projectiles.length / 15 + 0.3));
    if (this.hud) this.hud.update();
  }
}

// Démarrage.
window.addEventListener('DOMContentLoaded', () => { window.__game = new Game(); });

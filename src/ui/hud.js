// =============================================================================
//  hud.js — Interface tactile par joueur (overlay DOM au-dessus du canvas).
//   • Joystick virtuel (gauche) + tap-to-move (géré côté main via raycast).
//   • Boutons : Tir (maintenu), Action (ramasser/déposer), Forge ⚒️, Invoque ✨.
//   • Bandeau objectif + PV temple + arme/munitions + icônes des buddies.
//   • Menu radial d'ordres (maintien sur un buddy).
//   • Mini-carte (mode 1 joueur).
//  Tous les éléments interactifs portent la classe .hud-interactive pour que
//  le gestionnaire tactile monde les ignore.
// =============================================================================

import { ORDERS } from '../game/ai.js';
import { getWeapon, VEHICLES, TEAMMATES } from '../data/weapons.js';
import { CONFIG } from '../data/config.js';

export class HUD {
  constructor(root, engine, world, handlers) {
    this.root = root;
    this.engine = engine;
    this.world = world;
    this.h = handlers;          // { fireDown, fireUp, action, forge, summon, switchBuddy, joystick }
    this.panels = [];           // un panneau par équipe humaine
    this._build();
    this._buildRadial();
    this._buildMinimap();
    this.layout();
  }

  _btn(label, cls) {
    const b = document.createElement('button');
    b.className = `hud-btn hud-interactive ${cls || ''}`;
    b.innerHTML = label;
    b.addEventListener('contextmenu', (e) => e.preventDefault());
    return b;
  }

  _build() {
    const humanTeams = this.world.teams.filter((t) => t.controller === 'human');
    for (const team of humanTeams) {
      const panel = document.createElement('div');
      panel.className = 'hud-panel';

      // Bandeau supérieur : objectif + ressources.
      const top = document.createElement('div'); top.className = 'hud-top';
      const obj = document.createElement('div'); obj.className = 'hud-obj';
      const stats = document.createElement('div'); stats.className = 'hud-stats';
      top.appendChild(obj); top.appendChild(stats);
      panel.appendChild(top);

      // Rangée d'icônes des buddies (changement de buddy actif).
      const buddyRow = document.createElement('div'); buddyRow.className = 'hud-buddies';
      panel.appendChild(buddyRow);

      // Joystick virtuel (gauche).
      const joyBase = document.createElement('div'); joyBase.className = 'hud-joy hud-interactive';
      const joyKnob = document.createElement('div'); joyKnob.className = 'hud-joy-knob';
      joyBase.appendChild(joyKnob); panel.appendChild(joyBase);
      this._wireJoystick(team, joyBase, joyKnob);

      // Boutons d'action (droite).
      const fire = this._btn('🔥<span>Tir</span>', 'hud-fire');
      const action = this._btn('✋<span>Action</span>', 'hud-action');
      const forge = this._btn('⚒️<span>Forge</span>', 'hud-forge');
      const summon = this._btn('✨<span>Invoque</span>', 'hud-summon');
      const batt = this._btn('🎖️<span>Bataillon</span>', 'hud-batt');
      const weap = document.createElement('div'); weap.className = 'hud-weapon';

      fire.addEventListener('pointerdown', (e) => { e.preventDefault(); this.h.fireDown(team); fire.classList.add('down'); });
      fire.addEventListener('pointerup', (e) => { e.preventDefault(); this.h.fireUp(team); fire.classList.remove('down'); });
      fire.addEventListener('pointercancel', () => { this.h.fireUp(team); fire.classList.remove('down'); });
      action.addEventListener('pointerdown', (e) => { e.preventDefault(); this.h.action(team); });
      forge.addEventListener('pointerdown', (e) => { e.preventDefault(); this.h.forge(team); });
      summon.addEventListener('pointerdown', (e) => { e.preventDefault(); this.h.summon(team); });
      batt.addEventListener('pointerdown', (e) => { e.preventDefault(); this.h.battalion(team); });

      const right = document.createElement('div'); right.className = 'hud-right';
      right.appendChild(weap); right.appendChild(batt); right.appendChild(summon); right.appendChild(forge);
      right.appendChild(action); right.appendChild(fire);
      panel.appendChild(right);

      // Toast : retour visuel (craft réussi / raison d'échec).
      const toast = document.createElement('div'); toast.className = 'hud-toast';
      panel.appendChild(toast);

      // Atelier : grille 2x2 du pad. On tape une colonne pour y empiler le nuage
      // porté (dépôt CIBLÉ) — indispensable pour faire une pile verticale (invoc.).
      const build = document.createElement('div'); build.className = 'hud-build';
      build.innerHTML = '<div class="build-title">⚒️ Atelier — tape une colonne</div>';
      const grid = document.createElement('div'); grid.className = 'build-grid';
      const buildCells = [];
      for (const col of [2, 3, 0, 1]) {           // ordre visuel : haut (2,3) puis bas (0,1)
        const cell = document.createElement('button');
        cell.className = 'build-cell hud-interactive';
        cell.addEventListener('pointerdown', (e) => { e.preventDefault(); this.h.depositColumn(team, col); });
        grid.appendChild(cell); buildCells[col] = cell;
      }
      build.appendChild(grid);
      const buildPreview = document.createElement('div'); buildPreview.className = 'build-preview';
      build.appendChild(buildPreview);
      panel.appendChild(build);

      this.root.appendChild(panel);
      this.panels.push({ team, panel, obj, stats, buddyRow, weap, joyBase, joyKnob, fire, action, forge, summon, batt, toast, build, buildCells, buildPreview });
    }
  }

  _wireJoystick(team, base, knob) {
    let active = false, id = null, cx = 0, cy = 0, R = 46;
    const reset = () => { knob.style.transform = 'translate(0px,0px)'; this.h.joystick(team, 0, 0); };
    base.addEventListener('pointerdown', (e) => {
      e.preventDefault(); active = true; id = e.pointerId;
      const r = base.getBoundingClientRect(); cx = r.left + r.width / 2; cy = r.top + r.height / 2; R = r.width / 2;
      base.setPointerCapture(id);
    });
    base.addEventListener('pointermove', (e) => {
      if (!active || e.pointerId !== id) return;
      e.preventDefault();
      let dx = e.clientX - cx, dy = e.clientY - cy;
      const d = Math.hypot(dx, dy) || 1; const cl = Math.min(d, R);
      dx = (dx / d) * cl; dy = (dy / d) * cl;
      knob.style.transform = `translate(${dx}px,${dy}px)`;
      this.h.joystick(team, dx / R, dy / R);    // -1..1
    });
    const end = (e) => { if (e.pointerId !== id) return; active = false; reset(); };
    base.addEventListener('pointerup', end);
    base.addEventListener('pointercancel', end);
  }

  // --- Menu radial d'ordres -------------------------------------------------
  _buildRadial() {
    const r = document.createElement('div'); r.className = 'hud-radial hidden';
    this.radialItems = [];
    ORDERS.forEach((o, i) => {
      const a = (-Math.PI / 2) + i * (Math.PI * 2 / ORDERS.length);
      const it = document.createElement('div'); it.className = 'radial-item';
      it.innerHTML = `<span class="ri-icon">${o.icon}</span><span class="ri-label">${o.label}</span>`;
      it.style.left = `${Math.cos(a) * 92}px`; it.style.top = `${Math.sin(a) * 92}px`;
      it.dataset.order = o.id;
      r.appendChild(it); this.radialItems.push(it);
    });
    const center = document.createElement('div'); center.className = 'radial-center'; r.appendChild(center);
    this.root.appendChild(r); this.radial = r;
    this._radialTarget = null;
  }
  showRadial(x, y, buddy) {
    this._radialTarget = buddy; this._radialChoice = null;
    this.radial.style.left = `${x}px`; this.radial.style.top = `${y}px`;
    this.radial.classList.remove('hidden');
    this.radialItems.forEach((it) => it.classList.toggle('sel', it.dataset.order === buddy.order));
  }
  moveRadial(x, y) {
    if (!this._radialTarget) return;
    const r = this.radial.getBoundingClientRect();
    const dx = x - (r.left + r.width / 2), dy = y - (r.top + r.height / 2);
    if (Math.hypot(dx, dy) < 28) { this._radialChoice = null; this.radialItems.forEach((it) => it.classList.remove('sel')); return; }
    const ang = Math.atan2(dy, dx);
    let best = 0, bd = Infinity;
    ORDERS.forEach((o, i) => {
      const a = (-Math.PI / 2) + i * (Math.PI * 2 / ORDERS.length);
      let d = Math.abs(((a - ang + Math.PI * 3) % (Math.PI * 2)) - Math.PI);
      if (d < bd) { bd = d; best = i; }
    });
    this._radialChoice = ORDERS[best].id;
    this.radialItems.forEach((it, i) => it.classList.toggle('sel', i === best));
  }
  hideRadial() {
    this.radial.classList.add('hidden');
    const choice = this._radialChoice, tgt = this._radialTarget;
    this._radialTarget = null; this._radialChoice = null;
    if (tgt && choice) { tgt.order = choice; return { buddy: tgt, order: choice }; }
    return null;
  }

  // --- Mini-carte (1 joueur) ------------------------------------------------
  _buildMinimap() {
    const c = document.createElement('canvas');
    c.className = 'hud-minimap'; c.width = 150; c.height = 150;
    this.root.appendChild(c); this.minimap = c; this.mmctx = c.getContext('2d');
    if (this.world.teams.filter((t) => t.controller === 'human').length > 1) c.style.display = 'none';
  }
  _drawMinimap() {
    if (this.minimap.style.display === 'none') return;
    const ctx = this.mmctx, S = 150, half = CONFIG.arena.half;
    const to = (v) => (v / (half * 2) + 0.5) * S;
    ctx.clearRect(0, 0, S, S);
    ctx.fillStyle = 'rgba(10,16,28,0.55)'; ctx.fillRect(0, 0, S, S);
    ctx.fillStyle = 'rgba(255,255,255,0.5)';
    for (const c of this.world.clouds) ctx.fillRect(to(c.pos.x) - 1, to(c.pos.z) - 1, 2, 2);
    for (const t of this.world.teams) {
      ctx.fillStyle = `#${t.color.primary.toString(16).padStart(6, '0')}`;
      const tp = t.templeGroup.position; ctx.fillRect(to(tp.x) - 3, to(tp.z) - 3, 6, 6);
      for (const b of t.aliveBuddies()) { ctx.beginPath(); ctx.arc(to(b.pos.x), to(b.pos.z), 2.5, 0, 7); ctx.fill(); }
    }
  }

  // --- Disposition selon les viewports --------------------------------------
  layout() {
    const H = this.engine.container.clientHeight;
    for (const p of this.panels) {
      const vp = this.engine.viewports[p.team.viewport] || this.engine.viewports[0];
      const r = vp.rect;
      const topY = H - (r.y + r.h);          // conversion bas-gauche -> haut-gauche
      Object.assign(p.panel.style, { left: `${r.x}px`, top: `${topY}px`, width: `${r.w}px`, height: `${r.h}px` });
    }
  }

  // --- Mise à jour par frame ------------------------------------------------
  update() {
    const o = this.world.objective;
    for (const p of this.panels) {
      const team = p.team, b = team.activeBuddy;
      // Objectif + état.
      let prog = '';
      if (o.type === 'collect') prog = ` (${team.collected}/${o.N})`;
      else if (o.type === 'survive') prog = ` (${Math.max(0, Math.ceil(o.T - this.world.time))}s)`;
      else if (o.type === 'domination') prog = ` (${Math.floor(team.dominationTime)}/${o.T}s)`;
      else if (o.type === 'deathmatch') prog = ` (${team.score}/${o.score})`;
      p.obj.textContent = `🎯 ${o.label}${prog}`;

      const enemyTemple = this.world.enemyTempleFor(team);
      const eTeam = enemyTemple ? enemyTemple.userData.teamRef : null;
      const eHP = eTeam ? Math.max(0, Math.ceil(eTeam.templeHP)) : 0;
      const eName = eTeam ? (eTeam.godName || 'ennemi') : '—';
      const clouds = this.world.clouds.filter((c) => c.landed).length;
      p.stats.innerHTML = `${team.color.emoji} 🗿<b>${Math.max(0, Math.ceil(team.templeHP))}</b> · ☁️${clouds} · 🎯 ${eName} <b>${eHP}</b>`;

      // Arme + munitions.
      if (b) {
        const w = b.vehicle ? { icon: b.vehicle.icon, name: b.vehicle.name } : getWeapon(b.weaponId);
        const ammo = (b.ammo === Infinity) ? '∞' : b.ammo;
        p.weap.innerHTML = `<span class="wi">${w.icon}</span><span class="wn">${w.name}</span><span class="wa">${ammo}</span>`;
      } else p.weap.innerHTML = '';

      // Contexte du bouton Action.
      if (b) {
        const nearPad = Math.hypot(b.pos.x - team.pad.x, b.pos.z - team.pad.z) < CONFIG.pad.useRadius;
        const free = this.world.nearestFreeCloud(b.pos);
        const nearCloud = free && Math.hypot(free.pos.x - b.pos.x, free.pos.z - b.pos.z) < CONFIG.buddy.pickupReach;
        let lbl = '✋<span>—</span>';
        if (b.carried && nearPad) lbl = '📥<span>Déposer</span>';
        else if (b.carried) lbl = '⬇️<span>Lâcher</span>';
        else if (nearCloud) lbl = '☁️<span>Ramasser</span>';
        p.action.innerHTML = lbl;
        const canCraft = nearPad && !team.pad.isEmpty();
        p.forge.classList.toggle('enabled', canCraft);
        p.summon.classList.toggle('enabled', canCraft);
      }

      // Bataillon (formation en cours).
      const fmt = { off: 'Bataillon', wedge: '🔺 Pointe', line: '▬ Ligne', column: '┃ File', circle: '⭕ Cercle' }[team.formation] || 'Bataillon';
      p.batt.innerHTML = `🎖️<span>${fmt}</span>`;
      p.batt.classList.toggle('active', team.battalionActive);

      // Atelier (visible près du pad) : état des colonnes + aperçu du résultat.
      this._updateBuildPanel(p, team, b);

      // Icônes des buddies.
      this._updateBuddyRow(p, team);
    }
    this._drawMinimap();
  }

  _updateBuddyRow(p, team) {
    const alive = team.aliveBuddies();
    // (Re)construit si le nombre a changé.
    if (p.buddyRow.childElementCount !== alive.length) {
      p.buddyRow.innerHTML = '';
      for (const b of alive) {
        const el = document.createElement('button');
        el.className = 'hud-buddy hud-interactive';
        el.addEventListener('pointerdown', (e) => { e.preventDefault(); this.h.switchBuddy(team, b); });
        p.buddyRow.appendChild(el); b._icon = el;
      }
    }
    for (const b of alive) {
      if (!b._icon) continue;
      const w = b.vehicle ? b.vehicle.icon : getWeapon(b.weaponId).icon;
      const hpPct = Math.max(0, Math.round((b.hp / b.maxHp) * 100));
      b._icon.innerHTML = `<span>${w}</span><i style="width:${hpPct}%"></i>`;
      b._icon.classList.toggle('active', b === team.activeBuddy);
      b._icon.style.setProperty('--tc', `#${team.color.primary.toString(16).padStart(6, '0')}`);
    }
  }

  // --- Atelier (dépôt ciblé + aperçu) ---------------------------------------
  _updateBuildPanel(p, team, b) {
    const nearPad = b && b.alive && !b.vehicle &&
      Math.hypot(b.pos.x - team.pad.x, b.pos.z - team.pad.z) < CONFIG.pad.useRadius;
    p.build.classList.toggle('show', !!nearPad);
    if (!nearPad) return;
    const pad = team.pad;
    for (let col = 0; col < 4; col++) {
      const h = pad.heights[col];
      const cell = p.buildCells[col];
      cell.innerHTML = h ? '<i>☁️</i>'.repeat(h) : '<small>+</small>';
      cell.classList.toggle('filled', h > 0);
    }
    const pv = pad.preview();
    p.buildPreview.innerHTML = `⚒️ ${this._resName(pv.forge) || '—'}　·　✨ ${this._resName(pv.summon) || '—'}`;
  }
  _resName(res) {
    if (!res) return null;
    if (res.kind === 'weapon') { const w = getWeapon(res.id); return `${w.icon} ${w.name}`; }
    if (res.kind === 'vehicle') { const v = VEHICLES[res.id]; return v ? `${v.icon} ${v.name}` : res.id; }
    if (res.kind === 'teammate') { const t = TEAMMATES[res.id]; return t ? `${t.icon} ${t.name}` : res.id; }
    return null;
  }

  // Message transitoire (succès craft / raison d'échec / astuce).
  toast(team, msg, ok = true) {
    const p = this.panels.find((pp) => pp.team === team);
    if (!p) return;
    p.toast.textContent = msg;
    p.toast.className = 'hud-toast show ' + (ok ? 'ok' : 'err');
    clearTimeout(p._toastT);
    p._toastT = setTimeout(() => { p.toast.className = 'hud-toast'; }, 2300);
  }

  dispose() {
    for (const p of this.panels) { clearTimeout(p._toastT); p.panel.remove(); }
    this.radial.remove(); this.minimap.remove();
  }
}

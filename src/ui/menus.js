// =============================================================================
//  menus.js — Écrans hors-jeu : menu principal, sélection campagne (8 mondes ×
//  8 missions), contre-IA, multijoueur local, livre de recettes, tutoriel,
//  pause et résultats. Émet des "intentions" de partie ; modes.js les traduit.
// =============================================================================

import { WORLDS, buildCampaign } from '../data/campaign.js';
import { recipeBook } from '../data/recipes.js';
import { WEAPONS, VEHICLES, TEAMMATES } from '../data/weapons.js';
import { audio } from '../core/audio.js';

const PROGRESS_KEY = 'divine_rivals_progress';
const nameOf = (id) => (WEAPONS[id] || VEHICLES[id] || TEAMMATES[id] || { name: id }).name;
const iconOf = (id) => (WEAPONS[id] || VEHICLES[id] || TEAMMATES[id] || { icon: '❓' }).icon;

export class Menus {
  constructor(root, handlers) {
    this.root = root;            // conteneur DOM des menus
    this.h = handlers;           // { onStart(intent), onResume, onRestart, onQuit }
    this.campaign = buildCampaign();
    this.unlocked = this._loadProgress();
    this.el = document.createElement('div');
    this.el.className = 'menu-layer';
    root.appendChild(this.el);
    this.showMain();
  }

  _loadProgress() {
    try { return Math.max(0, parseInt(localStorage.getItem(PROGRESS_KEY) || '0', 10)); } catch { return 0; }
  }
  _saveProgress(i) {
    this.unlocked = Math.max(this.unlocked, i);
    try { localStorage.setItem(PROGRESS_KEY, String(this.unlocked)); } catch {}
  }

  _clear() { this.el.innerHTML = ''; this.el.classList.remove('hidden'); this.root.classList.remove('hidden'); }
  hide() { this.el.classList.add('hidden'); this.root.classList.add('hidden'); }
  _h(tag, cls, html) { const e = document.createElement(tag); if (cls) e.className = cls; if (html != null) e.innerHTML = html; return e; }
  _btn(label, onClick, cls = '') {
    const b = this._h('button', `menu-btn ${cls}`, label);
    b.addEventListener('click', () => { audio.init(); audio.uiClick(); onClick(); });
    return b;
  }

  // --- Menu principal -------------------------------------------------------
  showMain() {
    this._clear();
    const wrap = this._h('div', 'menu-screen menu-main');
    const logo = document.createElement('img');
    logo.className = 'menu-logo'; logo.alt = 'Divine Rivals';
    logo.src = 'assets/ui/logo.png';
    logo.onerror = () => logo.remove();   // pas de logo fourni => on garde le titre texte
    wrap.appendChild(logo);
    wrap.appendChild(this._h('h1', 'menu-title', '⚡ DIVINE RIVALS'));
    wrap.appendChild(this._h('p', 'menu-sub', 'Empilez les nuages. Forgez. Dominez l\'Olympe.'));
    const col = this._h('div', 'menu-col');
    col.appendChild(this._btn('🗺️ Campagne', () => this.showCampaign(), 'big'));
    col.appendChild(this._btn('🤖 Contre l\'IA', () => this.showSkirmish()));
    col.appendChild(this._btn('👥 Multijoueur local', () => this.showVersus()));
    col.appendChild(this._btn('📜 Recettes', () => this.showRecipes()));
    col.appendChild(this._btn('❓ Tutoriel', () => this.showTutorial(() => this.showMain())));
    col.appendChild(this._btn('🔊 Son : ON', (function () { /* remplacé ci-dessous */ })));
    // bouton son dynamique
    const sound = col.lastChild;
    sound.onclick = () => { audio.init(); const on = audio.toggleMute(); sound.innerHTML = on ? '🔊 Son : ON' : '🔇 Son : OFF'; };
    wrap.appendChild(col);
    this.el.appendChild(wrap);
  }

  // --- Campagne -------------------------------------------------------------
  showCampaign() {
    this._clear();
    const wrap = this._h('div', 'menu-screen');
    wrap.appendChild(this._header('🗺️ Campagne — 64 missions', () => this.showMain()));
    const worlds = this._h('div', 'world-list');
    WORLDS.forEach((w) => {
      const firstIdx = w.id * 8;
      const locked = firstIdx > this.unlocked;
      const card = this._h('div', `world-card${locked ? ' locked' : ''}`);
      card.style.setProperty('--wc', `#${w.ground.toString(16).padStart(6, '0')}`);
      card.innerHTML = `<b>Monde ${w.id + 1}</b><span>${w.name}</span>`;
      const done = Math.min(8, Math.max(0, this.unlocked - firstIdx + 1));
      card.appendChild(this._h('i', 'world-prog', locked ? '🔒' : `${Math.min(done, 8)}/8`));
      if (!locked) card.addEventListener('click', () => { audio.uiClick(); this.showMissions(w.id); });
      worlds.appendChild(card);
    });
    wrap.appendChild(worlds);
    this.el.appendChild(wrap);
  }

  showMissions(worldId) {
    this._clear();
    const w = WORLDS[worldId];
    const wrap = this._h('div', 'menu-screen');
    wrap.appendChild(this._header(`Monde ${worldId + 1} — ${w.name}`, () => this.showCampaign()));
    const grid = this._h('div', 'mission-grid');
    for (let m = 0; m < 8; m++) {
      const idx = worldId * 8 + m;
      const mission = this.campaign[idx];
      const locked = idx > this.unlocked;
      const cell = this._h('button', `mission-cell${locked ? ' locked' : ''}${mission.boss ? ' boss' : ''}`);
      cell.innerHTML = `<b>${worldId + 1}-${m + 1}</b><span>${mission.objective.label}</span>${mission.boss ? '<i>👑 BOSS</i>' : ''}`;
      if (!locked) cell.addEventListener('click', () => { audio.uiClick(); this.h.onStart({ type: 'campaign', missionIndex: idx }); });
      grid.appendChild(cell);
    }
    wrap.appendChild(grid);
    this.el.appendChild(wrap);
  }

  // --- Contre IA ------------------------------------------------------------
  showSkirmish() {
    this._clear();
    const wrap = this._h('div', 'menu-screen');
    wrap.appendChild(this._header('🤖 Contre l\'IA', () => this.showMain()));
    let bots = 1, diff = 0.6, worldId = 0;
    const form = this._h('div', 'menu-form');
    form.appendChild(this._chooser('Adversaires', ['1', '2', '3'], 0, (i) => bots = i + 1));
    form.appendChild(this._chooser('Difficulté', ['Facile', 'Normal', 'Difficile'], 1, (i) => diff = [0.35, 0.6, 0.95][i]));
    form.appendChild(this._chooser('Arène', WORLDS.map((w) => w.name), 0, (i) => worldId = i));
    wrap.appendChild(form);
    wrap.appendChild(this._btn('▶️ Jouer', () => this.h.onStart({ type: 'skirmish', bots, difficulty: diff, worldId }), 'big'));
    this.el.appendChild(wrap);
  }

  // --- Multijoueur local ----------------------------------------------------
  showVersus() {
    this._clear();
    const wrap = this._h('div', 'menu-screen');
    wrap.appendChild(this._header('👥 Multijoueur local (écran partagé)', () => this.showMain()));
    let players = 2, modeId = 'deathmatch', fill = 0, worldId = 0;
    const modes = [
      ['deathmatch', 'Deathmatch'], ['domination', 'Domination'],
      ['football', 'Buddy Football'], ['destroy_base', 'Base Assault'],
    ];
    const form = this._h('div', 'menu-form');
    form.appendChild(this._chooser('Joueurs', ['2', '3', '4'], 0, (i) => players = i + 2));
    form.appendChild(this._chooser('Mode', modes.map((m) => m[1]), 0, (i) => modeId = modes[i][0]));
    form.appendChild(this._chooser('Bots de remplissage', ['0', '1', '2'], 0, (i) => fill = i));
    form.appendChild(this._chooser('Arène', WORLDS.map((w) => w.name), 0, (i) => worldId = i));
    wrap.appendChild(form);
    wrap.appendChild(this._h('p', 'menu-note', 'Astuce : tenez la tablette en paysage. Chaque joueur a son quadrant et ses propres commandes tactiles.'));
    wrap.appendChild(this._btn('▶️ Jouer', () => this.h.onStart({ type: 'versus', players, modeId, fill, worldId }), 'big'));
    this.el.appendChild(wrap);
  }

  // --- Livre de recettes ----------------------------------------------------
  showRecipes() {
    this._clear();
    const wrap = this._h('div', 'menu-screen');
    wrap.appendChild(this._header('📜 Recettes de craft', () => this.showMain()));
    const book = recipeBook();
    const cont = this._h('div', 'recipe-cols');
    const col = (title, list, action) => {
      const c = this._h('div', 'recipe-col');
      c.appendChild(this._h('h3', null, title));
      list.forEach((r) => c.appendChild(this._h('div', 'recipe-row',
        `<span class="ri">${iconOf(r.id)}</span><b>${nameOf(r.id)}</b><i>${r.shape}</i>`)));
      cont.appendChild(c);
    };
    col(`⚒️ Armes (Forge)`, book.weapons);
    col(`🚀 Véhicules (Forge, 8 nuages)`, book.vehicles);
    col(`✨ Coéquipiers (Invoque, pile verticale)`, book.teammates);
    wrap.appendChild(cont);
    this.el.appendChild(wrap);
  }

  // --- Tutoriel -------------------------------------------------------------
  showTutorial(done) {
    this._clear();
    const wrap = this._h('div', 'menu-screen menu-tuto');
    wrap.appendChild(this._h('h2', 'menu-title', 'Comment jouer'));
    wrap.appendChild(this._h('div', 'tuto-grid', `
      <div><b>🕹️ Se déplacer</b>Joystick (gauche) ou tapez le sol.</div>
      <div><b>👆 Changer de buddy</b>Tapez son icône ou tapez-le à l'écran.</div>
      <div><b>☁️ Nuages</b>Ils tombent du ciel. Ramassez-en un (Action).</div>
      <div><b>📥 Empiler</b>Placez-vous sur un côté du pad et Déposez : le nuage va dans cette colonne.</div>
      <div><b>⚒️ Forge</b>Selon la forme empilée : une arme ou un véhicule !</div>
      <div><b>✨ Invoque</b>Pile verticale (2/3/4) = nouveau coéquipier.</div>
      <div><b>🔥 Tir</b>Visée auto assistée. Maintenez Tir.</div>
      <div><b>🤚 Gambits (IA)</b>Maintenez le doigt sur un allié → menu radial. Chaque ordre est un « gambit » (règles si→alors) : fuit si faible, attaque à portée, protège le chef…</div>
      <div><b>🎖️ Bataillon</b>Bouton Bataillon : vos alliés marchent en formation (Pointe / Ligne / File / Cercle) derrière vous et combattent ensemble.</div>
    `));
    wrap.appendChild(this._btn('OK, j\'ai compris', () => done(), 'big'));
    this.el.appendChild(wrap);
  }

  // --- Résultats / Pause ----------------------------------------------------
  showResults(result, ctx) {
    this._clear();
    const win = result === 'win';
    if (win && ctx.missionIndex != null) this._saveProgress(ctx.missionIndex + 1);
    const wrap = this._h('div', 'menu-screen menu-result');
    const title = ctx.versusWinner ? `🏆 ${ctx.versusWinner} gagne !` : (win ? '🏆 VICTOIRE !' : '💀 DÉFAITE');
    wrap.appendChild(this._h('h1', `result-title ${win ? 'win' : 'lose'}`, title));
    const col = this._h('div', 'menu-col');
    if (ctx.type === 'campaign') {
      if (win && ctx.missionIndex + 1 < this.campaign.length)
        col.appendChild(this._btn('➡️ Mission suivante', () => this.h.onStart({ type: 'campaign', missionIndex: ctx.missionIndex + 1 }), 'big'));
      col.appendChild(this._btn('🔁 Rejouer', () => this.h.onStart({ type: 'campaign', missionIndex: ctx.missionIndex })));
    } else {
      col.appendChild(this._btn('🔁 Rejouer', () => this.h.onRestart()));
    }
    col.appendChild(this._btn('🏠 Menu principal', () => { this.h.onQuit(); this.showMain(); }));
    wrap.appendChild(col);
    this.el.appendChild(wrap);
  }

  showPause(ctx) {
    this._clear();
    const wrap = this._h('div', 'menu-screen menu-pause');
    wrap.appendChild(this._h('h1', 'menu-title', '⏸️ Pause'));
    const col = this._h('div', 'menu-col');
    col.appendChild(this._btn('▶️ Reprendre', () => { this.hide(); this.h.onResume(); }, 'big'));
    col.appendChild(this._btn('🔁 Recommencer', () => this.h.onRestart()));
    col.appendChild(this._btn('🏠 Quitter', () => { this.h.onQuit(); this.showMain(); }));
    wrap.appendChild(col);
    this.el.appendChild(wrap);
  }

  // --- Petits composants ----------------------------------------------------
  _header(title, back) {
    const h = this._h('div', 'menu-header');
    h.appendChild(this._btn('‹ Retour', back, 'back'));
    h.appendChild(this._h('h2', 'menu-title', title));
    return h;
  }
  _chooser(label, options, defIdx, onPick) {
    const row = this._h('div', 'chooser');
    row.appendChild(this._h('span', 'chooser-label', label));
    const opts = this._h('div', 'chooser-opts');
    let cur = defIdx;
    options.forEach((o, i) => {
      const b = this._h('button', `chooser-opt${i === defIdx ? ' sel' : ''}`, o);
      b.addEventListener('click', () => {
        audio.uiClick(); cur = i;
        [...opts.children].forEach((c, j) => c.classList.toggle('sel', j === i));
        onPick(i);
      });
      opts.appendChild(b);
    });
    row.appendChild(opts);
    return row;
  }
}

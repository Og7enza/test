// =============================================================================
//  input.js — Gestion tactile/souris multipoint.
//  Détecte les gestes génériques et les relaie ; le jeu décide du sens.
//    • tap        : appui court quasi immobile (déplacement / sélection)
//    • holdstart  : appui maintenu (> seuil) => menu radial d'ordres
//    • holdmove   : déplacement du doigt pendant un maintien (choix radial)
//    • holdend    : relâché après un maintien (valide l'ordre)
//    • dragstart/dragmove/dragend : glissé continu => joystick virtuel
//  Chaque pointeur est associé à un joueur via un "resolver" (x,y) -> index,
//  ce qui permet l'écran partagé multijoueur (jusqu'à 4).
// =============================================================================

const TAP_MAX_MS = 250;
const HOLD_MS = 320;
const MOVE_THRESH = 14;          // px avant de considérer un glissé

export class InputManager {
  constructor(el) {
    this.el = el;
    this.pointers = new Map();
    this.listeners = {};
    this.playerResolver = () => 0;       // par défaut : tout au joueur 0
    this.enabled = true;

    this._down = this._down.bind(this);
    this._move = this._move.bind(this);
    this._up = this._up.bind(this);

    el.addEventListener('pointerdown', this._down, { passive: false });
    el.addEventListener('pointermove', this._move, { passive: false });
    el.addEventListener('pointerup', this._up, { passive: false });
    el.addEventListener('pointercancel', this._up, { passive: false });
    el.addEventListener('contextmenu', (e) => e.preventDefault());
  }

  setPlayerResolver(fn) { this.playerResolver = fn; }
  on(evt, cb) { (this.listeners[evt] ||= []).push(cb); }
  _emit(evt, data) { (this.listeners[evt] || []).forEach((cb) => cb(data)); }

  // Ignore les pointeurs qui démarrent sur un élément interactif du HUD.
  _onHud(target) {
    return !!(target && target.closest && target.closest('.hud-interactive'));
  }

  _local(e) {
    const r = this.el.getBoundingClientRect();
    return { x: e.clientX - r.left, y: e.clientY - r.top };
  }

  _down(e) {
    if (!this.enabled) return;
    if (this._onHud(e.target)) return;       // le HUD gère ses propres appuis
    e.preventDefault();
    const { x, y } = this._local(e);
    const player = this.playerResolver(x, y);
    const p = {
      id: e.pointerId, x0: x, y0: y, x, y, t0: performance.now(),
      player, moved: false, held: false, dragging: false,
      holdTimer: setTimeout(() => this._promoteHold(e.pointerId), HOLD_MS),
    };
    this.pointers.set(e.pointerId, p);
    try { this.el.setPointerCapture(e.pointerId); } catch (_) {}
  }

  _promoteHold(id) {
    const p = this.pointers.get(id);
    if (!p || p.moved || p.dragging) return;
    p.held = true;
    this._emit('holdstart', { player: p.player, x: p.x, y: p.y });
  }

  _move(e) {
    const p = this.pointers.get(e.pointerId);
    if (!p) return;
    e.preventDefault();
    const { x, y } = this._local(e);
    p.x = x; p.y = y;
    const dist = Math.hypot(x - p.x0, y - p.y0);
    if (!p.moved && dist > MOVE_THRESH) {
      p.moved = true;
      clearTimeout(p.holdTimer);
      if (!p.held) { p.dragging = true; this._emit('dragstart', { player: p.player, x, y, x0: p.x0, y0: p.y0 }); }
    }
    if (p.held) this._emit('holdmove', { player: p.player, x, y });
    else if (p.dragging) this._emit('dragmove', { player: p.player, x, y, x0: p.x0, y0: p.y0, dx: x - p.x0, dy: y - p.y0 });
  }

  _up(e) {
    const p = this.pointers.get(e.pointerId);
    if (!p) return;
    e.preventDefault();
    clearTimeout(p.holdTimer);
    const { x, y } = this._local(e);
    const dt = performance.now() - p.t0;
    if (p.held) this._emit('holdend', { player: p.player, x, y });
    else if (p.dragging) this._emit('dragend', { player: p.player, x, y });
    else if (!p.moved && dt < TAP_MAX_MS) this._emit('tap', { player: p.player, x, y });
    this.pointers.delete(e.pointerId);
    try { this.el.releasePointerCapture(e.pointerId); } catch (_) {}
  }

  dispose() {
    this.el.removeEventListener('pointerdown', this._down);
    this.el.removeEventListener('pointermove', this._move);
    this.el.removeEventListener('pointerup', this._up);
    this.el.removeEventListener('pointercancel', this._up);
    this.pointers.forEach((p) => clearTimeout(p.holdTimer));
    this.pointers.clear();
  }
}

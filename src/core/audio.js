// =============================================================================
//  audio.js — Moteur audio 100% synthétisé (Web Audio API).
//  Aucun fichier son : tout est généré => livrable autonome.
//  - Bruitages cartoon : ramassage ("pouet"), craft (magie), tirs, explosions.
//  - Musique dynamique type drum'n'bass épique (séquenceur avec lookahead).
// =============================================================================

import { CONFIG } from '../data/config.js';

export class AudioEngine {
  constructor() {
    this.ctx = null;
    this.master = null;
    this.musicGain = null;
    this.sfxGain = null;
    this.enabled = true;
    this.musicOn = true;
    this._musicTimer = null;
    this._step = 0;
    this._nextNoteTime = 0;
    this._tempo = 168;                 // BPM drum'n'bass
    this._intensity = 0.6;             // 0..1 : monte pendant l'action
  }

  // Doit être appelé sur un geste utilisateur (politique navigateur).
  init() {
    if (this.ctx) { this.resume(); return; }
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) { this.enabled = false; return; }
    this.ctx = new AC();
    this.master = this.ctx.createGain();
    this.master.gain.value = CONFIG.audio.master;
    this.master.connect(this.ctx.destination);

    this.musicGain = this.ctx.createGain();
    this.musicGain.gain.value = CONFIG.audio.music;
    this.musicGain.connect(this.master);

    this.sfxGain = this.ctx.createGain();
    this.sfxGain.gain.value = CONFIG.audio.sfx;
    this.sfxGain.connect(this.master);
  }

  resume() { if (this.ctx && this.ctx.state === 'suspended') this.ctx.resume(); }
  get now() { return this.ctx ? this.ctx.currentTime : 0; }

  setMasterVolume(v) { if (this.master) this.master.gain.value = v; }
  toggleMute() {
    this.enabled = !this.enabled;
    if (this.master) this.master.gain.value = this.enabled ? CONFIG.audio.master : 0;
    return this.enabled;
  }
  // Intensité musicale (0..1) selon l'action en cours (combats, etc.).
  setIntensity(v) { this._intensity = Math.max(0, Math.min(1, v)); }

  // ---- Briques de synthèse --------------------------------------------------
  _env(node, t, a, d, peak = 1) {
    const g = node.gain;
    g.cancelScheduledValues(t);
    g.setValueAtTime(0.0001, t);
    g.exponentialRampToValueAtTime(peak, t + a);
    g.exponentialRampToValueAtTime(0.0001, t + a + d);
  }
  _tone({ type = 'sine', f0, f1, t, a = 0.005, d = 0.2, peak = 0.6, dest = null }) {
    if (!this.ctx || !this.enabled) return;
    const o = this.ctx.createOscillator();
    const g = this.ctx.createGain();
    o.type = type;
    o.frequency.setValueAtTime(f0, t);
    if (f1 != null) o.frequency.exponentialRampToValueAtTime(Math.max(1, f1), t + a + d);
    this._env(g, t, a, d, peak);
    o.connect(g); g.connect(dest || this.sfxGain);
    o.start(t); o.stop(t + a + d + 0.05);
  }
  _noise({ t, d = 0.2, peak = 0.5, type = 'highpass', freq = 1200, dest = null }) {
    if (!this.ctx || !this.enabled) return;
    const len = Math.floor(this.ctx.sampleRate * (d + 0.05));
    const buf = this.ctx.createBuffer(1, len, this.ctx.sampleRate);
    const data = buf.getChannelData(0);
    for (let i = 0; i < len; i++) data[i] = Math.random() * 2 - 1;
    const src = this.ctx.createBufferSource(); src.buffer = buf;
    const filt = this.ctx.createBiquadFilter(); filt.type = type; filt.frequency.value = freq;
    const g = this.ctx.createGain(); this._env(g, t, 0.005, d, peak);
    src.connect(filt); filt.connect(g); g.connect(dest || this.sfxGain);
    src.start(t); src.stop(t + d + 0.05);
  }

  // ---- Bruitages cartoon ----------------------------------------------------
  pickup() {                                   // "pouet" montant rigolo
    const t = this.now;
    this._tone({ type: 'square', f0: 320, f1: 720, t, a: 0.01, d: 0.14, peak: 0.4 });
  }
  drop() {
    const t = this.now;
    this._tone({ type: 'square', f0: 500, f1: 200, t, a: 0.01, d: 0.12, peak: 0.35 });
  }
  craft() {                                    // scintillement magique (arpège)
    const t = this.now;
    [523, 659, 784, 1046].forEach((f, i) =>
      this._tone({ type: 'triangle', f0: f, t: t + i * 0.06, a: 0.01, d: 0.22, peak: 0.4 }));
    this._noise({ t, d: 0.3, peak: 0.15, type: 'bandpass', freq: 3000 });
  }
  craftFail() {
    const t = this.now;
    this._tone({ type: 'sawtooth', f0: 200, f1: 90, t, a: 0.01, d: 0.25, peak: 0.3 });
  }
  shoot(kind = 'arrow') {
    const t = this.now;
    if (kind === 'bullet') this._tone({ type: 'square', f0: 900, f1: 500, t, a: 0.002, d: 0.05, peak: 0.22 });
    else if (kind === 'fire') this._noise({ t, d: 0.12, peak: 0.18, type: 'lowpass', freq: 1400 });
    else if (kind === 'lightning') { this._tone({ type: 'sawtooth', f0: 1200, f1: 200, t, a: 0.002, d: 0.18, peak: 0.3 }); this._noise({ t, d: 0.15, peak: 0.18, freq: 5000 }); }
    else if (kind === 'melee') this._tone({ type: 'square', f0: 220, f1: 140, t, a: 0.002, d: 0.08, peak: 0.25 });
    else this._tone({ type: 'triangle', f0: 700, f1: 1100, t, a: 0.002, d: 0.07, peak: 0.22 }); // arrow
  }
  explosion(big = false) {
    const t = this.now;
    this._noise({ t, d: big ? 0.6 : 0.35, peak: big ? 0.6 : 0.4, type: 'lowpass', freq: big ? 700 : 1100 });
    this._tone({ type: 'sine', f0: big ? 140 : 200, f1: 40, t, a: 0.005, d: big ? 0.5 : 0.3, peak: 0.5 });
  }
  hurt() { const t = this.now; this._tone({ type: 'square', f0: 300, f1: 120, t, a: 0.005, d: 0.12, peak: 0.3 }); }
  spawn() { const t = this.now; this._tone({ type: 'triangle', f0: 200, f1: 800, t, a: 0.02, d: 0.3, peak: 0.4 }); }
  uiClick() { const t = this.now; this._tone({ type: 'square', f0: 600, f1: 900, t, a: 0.002, d: 0.05, peak: 0.2 }); }
  victory() { const t = this.now; [523, 659, 784, 1046, 1318].forEach((f, i) => this._tone({ type: 'triangle', f0: f, t: t + i * 0.12, a: 0.01, d: 0.3, peak: 0.45 })); }
  defeat() { const t = this.now; [392, 330, 262, 196].forEach((f, i) => this._tone({ type: 'sawtooth', f0: f, t: t + i * 0.18, a: 0.01, d: 0.35, peak: 0.4 })); }

  // ---- Musique : séquenceur drum'n'bass --------------------------------------
  startMusic() {
    if (!this.ctx || !this.enabled || this._musicTimer) return;
    this._nextNoteTime = this.now + 0.1;
    this._step = 0;
    const scheduler = () => {
      if (!this.ctx) return;
      const secPerStep = (60 / this._tempo) / 4;        // double-croches
      while (this._nextNoteTime < this.now + 0.2) {
        this._scheduleStep(this._step, this._nextNoteTime);
        this._nextNoteTime += secPerStep;
        this._step = (this._step + 1) % 32;             // 2 mesures de 16 pas
      }
    };
    this._musicTimer = setInterval(scheduler, 40);
    this.musicOn = true;
  }
  stopMusic() { if (this._musicTimer) { clearInterval(this._musicTimer); this._musicTimer = null; } this.musicOn = false; }
  toggleMusic() { if (this.musicOn) this.stopMusic(); else this.startMusic(); return this.musicOn; }

  _scheduleStep(step, t) {
    const dest = this.musicGain;
    const inten = 0.4 + this._intensity * 0.6;
    // Kick : pattern syncopé drum'n'bass.
    const kickSteps = [0, 10, 16, 22];
    if (kickSteps.includes(step % 32)) {
      const o = this.ctx.createOscillator(); const g = this.ctx.createGain();
      o.type = 'sine'; o.frequency.setValueAtTime(150, t); o.frequency.exponentialRampToValueAtTime(45, t + 0.12);
      this._env(g, t, 0.004, 0.16, 0.9 * inten); o.connect(g); g.connect(dest); o.start(t); o.stop(t + 0.22);
    }
    // Snare sur les contretemps (pas 4 et 12 de chaque mesure).
    if (step % 8 === 4) this._noise({ t, d: 0.16, peak: 0.4 * inten, type: 'highpass', freq: 1800, dest });
    // Charley toutes les double-croches.
    if (step % 2 === 0) this._noise({ t, d: 0.04, peak: 0.12 * inten, type: 'highpass', freq: 7000, dest });
    // Basse reese (mi mineur) : notes longues.
    const bassRoot = [41.2, 41.2, 55, 36.7]; // E1, E1, A1, D1
    if (step % 8 === 0) {
      const f = bassRoot[(Math.floor(step / 8)) % bassRoot.length];
      const o = this.ctx.createOscillator(); const o2 = this.ctx.createOscillator(); const g = this.ctx.createGain();
      o.type = 'sawtooth'; o2.type = 'sawtooth'; o.frequency.value = f; o2.frequency.value = f * 1.01;
      const filt = this.ctx.createBiquadFilter(); filt.type = 'lowpass'; filt.frequency.value = 400 + inten * 600;
      this._env(g, t, 0.02, 0.9, 0.5 * inten); o.connect(filt); o2.connect(filt); filt.connect(g); g.connect(dest);
      o.start(t); o2.start(t); o.stop(t + 1.0); o2.stop(t + 1.0);
    }
    // Arpège lead épique (gamme mi mineur) quand l'intensité est haute.
    if (this._intensity > 0.5 && step % 2 === 0) {
      const scale = [659, 784, 988, 784, 1318, 988, 784, 659];
      const f = scale[(step / 2) % scale.length];
      this._tone({ type: 'triangle', f0: f, t, a: 0.005, d: 0.12, peak: 0.12 * inten, dest });
    }
  }
}

export const audio = new AudioEngine();

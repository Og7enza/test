// =============================================================================
//  pad.js — Pad d'empilement 2x2 d'une équipe. Gère les hauteurs de colonnes,
//  l'empilement visuel des nuages et la résolution des recettes (forge/invoque).
// =============================================================================

import * as THREE from 'three';
import { CONFIG } from '../data/config.js';
import { makePad, makeCloud } from '../core/assets.js';
import { resolveForge, resolveSummon, signatureOf } from '../data/recipes.js';

export class Pad {
  constructor(scene, x, z, teamColor) {
    this.scene = scene;
    this.x = x; this.z = z;
    this.group = makePad(teamColor);
    this.group.position.set(x, 0, z);
    scene.add(this.group);
    this.columns = this.group.userData.columns;   // [{x,z}] x4 (relatifs)
    this.heights = [0, 0, 0, 0];
    this.cloudMeshes = [[], [], [], []];
    this.obstacle = { x, z, r: 2.0 };
  }

  total() { return this.heights.reduce((s, h) => s + h, 0); }
  isFull() { return this.total() >= CONFIG.pad.capacity; }
  isEmpty() { return this.total() === 0; }

  // Colonne la plus proche d'un point monde (pour déposer en se positionnant).
  nearestColumn(wx, wz) {
    let best = 0, bd = Infinity;
    for (let i = 0; i < 4; i++) {
      const cx = this.x + this.columns[i].x, cz = this.z + this.columns[i].z;
      const d = (wx - cx) ** 2 + (wz - cz) ** 2;
      if (d < bd) { bd = d; best = i; }
    }
    return best;
  }

  // Dépose un nuage sur la colonne la plus proche du dépositaire.
  // Renvoie true si déposé.
  deposit(wx, wz) {
    if (this.isFull()) return false;
    const col = this.nearestColumn(wx, wz);
    if (this.heights[col] >= CONFIG.pad.maxColumnHeight) {
      // Colonne pleine : tente la plus basse disponible.
      let alt = -1, min = Infinity;
      for (let i = 0; i < 4; i++) if (this.heights[i] < min && this.heights[i] < CONFIG.pad.maxColumnHeight) { min = this.heights[i]; alt = i; }
      if (alt < 0) return false;
      return this._add(alt);
    }
    return this._add(col);
  }

  _add(col) {
    const layer = this.heights[col];
    const m = makeCloud();
    m.scale.setScalar(CONFIG.clouds.size * 0.62);
    const o = this.columns[col];
    m.position.set(this.x + o.x, 0.45 + layer * CONFIG.pad.layerHeight, this.z + o.z);
    this.scene.add(m);
    this.cloudMeshes[col].push(m);
    this.heights[col]++;
    return true;
  }

  signature() { return signatureOf(this.heights); }

  // Dépôt CIBLÉ sur une colonne précise (utilisé par l'Atelier tactile).
  // Renvoie true si déposé, false si pad/colonne pleine ou index invalide.
  addToColumn(col) {
    if (col < 0 || col > 3) return false;
    if (this.isFull()) return false;
    if (this.heights[col] >= CONFIG.pad.maxColumnHeight) return false;
    return this._add(col);
  }

  // Tente une forge (arme/véhicule). Vide le pad si réussi. Renvoie le résultat.
  forge() {
    const res = resolveForge(this.heights);
    if (res) this.clear();
    return res;
  }
  // Tente une invocation (coéquipier). Vide le pad si réussi.
  summon() {
    const res = resolveSummon(this.heights);
    if (res) this.clear();
    return res;
  }

  // Aperçu sans consommer (pour l'UI : qu'obtiendrait-on ?).
  preview() {
    return { forge: resolveForge(this.heights), summon: resolveSummon(this.heights), sig: this.signature(), total: this.total() };
  }

  clear() {
    for (let i = 0; i < 4; i++) {
      for (const m of this.cloudMeshes[i]) this.scene.remove(m);
      this.cloudMeshes[i].length = 0;
      this.heights[i] = 0;
    }
  }

  // Animation d'idle : léger flottement des nuages empilés.
  update(t) {
    for (let i = 0; i < 4; i++) {
      const arr = this.cloudMeshes[i];
      for (let k = 0; k < arr.length; k++) arr[k].rotation.y = t * 0.4 + k;
    }
  }
}

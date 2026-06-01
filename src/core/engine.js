// =============================================================================
//  engine.js — Renderer Three.js, éclairage, ombres douces, brouillard et
//  gestion du SPLIT-SCREEN (1/2/4 joueurs) avec caméras isométriques de suivi.
// =============================================================================

import * as THREE from 'three';
import { CONFIG } from '../data/config.js';

export class Engine {
  constructor(container) {
    this.container = container;
    this.renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, CONFIG.maxPixelRatio));
    this.renderer.shadowMap.enabled = CONFIG.shadows;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;     // ombres douces
    container.appendChild(this.renderer.domElement);
    this.renderer.domElement.style.touchAction = 'none';

    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(CONFIG.fogColor);
    this.scene.fog = new THREE.Fog(CONFIG.fogColor, 60, 180);

    this._setupLights();

    this.viewports = [];     // { camera, rect, target:Vector3, cam2:Vector3 }
    this.clock = new THREE.Clock();
    this._raf = null;
    this._onResize = this._resize.bind(this);
    window.addEventListener('resize', this._onResize);
    window.addEventListener('orientationchange', this._onResize);
    this._resize();
  }

  _setupLights() {
    const hemi = new THREE.HemisphereLight(0xffffff, 0x556070, 0.9);
    this.scene.add(hemi);
    const sun = new THREE.DirectionalLight(0xfff4e0, 1.15);
    sun.position.set(28, 46, 20);
    sun.castShadow = CONFIG.shadows;
    sun.shadow.mapSize.set(1024, 1024);
    const s = 42;
    sun.shadow.camera.left = -s; sun.shadow.camera.right = s;
    sun.shadow.camera.top = s; sun.shadow.camera.bottom = -s;
    sun.shadow.camera.near = 1; sun.shadow.camera.far = 140;
    sun.shadow.bias = -0.0008;
    this.scene.add(sun);
    this.scene.add(sun.target);
    this.sun = sun;
    this.hemi = hemi;
  }

  setTheme(world) {
    const sky = new THREE.Color(world.sky);
    this.scene.background = sky;
    this.scene.fog.color = sky;
  }

  // Crée `count` viewports (1, 2 ou 4) avec leur caméra.
  setupViewports(count) {
    this.viewports = [];
    for (let i = 0; i < count; i++) {
      const cam = new THREE.PerspectiveCamera(CONFIG.camera.fov, 1, CONFIG.camera.near, CONFIG.camera.far);
      const off = CONFIG.camera.offset;
      cam.position.set(off.x, off.y, off.z);
      cam.lookAt(0, 0, 0);
      this.viewports.push({ camera: cam, rect: { x: 0, y: 0, w: 1, h: 1 }, target: new THREE.Vector3(), pos: new THREE.Vector3(off.x, off.y, off.z) });
    }
    this._layout();
  }

  // Dispose les rectangles selon le nombre de joueurs (paysage).
  _layout() {
    const n = this.viewports.length;
    const W = this.container.clientWidth, H = this.container.clientHeight;
    let rects;
    if (n <= 1) rects = [{ x: 0, y: 0, w: W, h: H }];
    else if (n === 2) rects = [               // côte à côte (idéal en paysage)
      { x: 0, y: 0, w: W / 2, h: H },
      { x: W / 2, y: 0, w: W / 2, h: H },
    ];
    else rects = [                            // 4 quadrants
      { x: 0, y: H / 2, w: W / 2, h: H / 2 },
      { x: W / 2, y: H / 2, w: W / 2, h: H / 2 },
      { x: 0, y: 0, w: W / 2, h: H / 2 },
      { x: W / 2, y: 0, w: W / 2, h: H / 2 },
    ];
    this.viewports.forEach((v, i) => {
      v.rect = rects[i];
      v.camera.aspect = rects[i].w / rects[i].h;
      v.camera.updateProjectionMatrix();
    });
  }

  // Joueur correspondant à un point écran (pour le multitouch en split-screen).
  playerAt(x, y) {
    for (let i = 0; i < this.viewports.length; i++) {
      const r = this.viewports[i].rect;
      // r.y est en coordonnées "bas-gauche" (WebGL) ; on convertit en haut-gauche.
      const topY = this.container.clientHeight - (r.y + r.h);
      if (x >= r.x && x < r.x + r.w && y >= topY && y < topY + r.h) return i;
    }
    return 0;
  }

  // Met à jour la position d'une caméra pour suivre une cible (lerp doux).
  followTarget(vp, targetVec) {
    vp.target.lerp(targetVec, CONFIG.camera.lerp * 1.6);
    const off = CONFIG.camera.offset;
    const desired = this._tmp || (this._tmp = new THREE.Vector3());
    desired.set(vp.target.x + off.x, vp.target.y + off.y, vp.target.z + off.z);
    vp.camera.position.lerp(desired, CONFIG.camera.lerp);
    vp.camera.lookAt(vp.target.x, vp.target.y + 1, vp.target.z);
  }

  _resize() {
    const W = this.container.clientWidth, H = this.container.clientHeight;
    this.renderer.setSize(W, H, false);
    this._layout();
  }

  // Boucle principale : appelle update(dt) puis rend tous les viewports.
  start(update) {
    const loop = () => {
      this._raf = requestAnimationFrame(loop);
      let dt = this.clock.getDelta();
      if (dt > 0.05) dt = 0.05;                    // anti à-coups après pause
      update(dt);
      this.render();
    };
    this._raf = requestAnimationFrame(loop);
  }
  stop() { if (this._raf) cancelAnimationFrame(this._raf); this._raf = null; }

  render() {
    const r = this.renderer;
    const H = this.container.clientHeight;
    // Fond/bordures : on nettoie tout en sombre une fois.
    r.setScissorTest(false);
    r.setClearColor(0x05070d, 1);
    r.clear();
    r.setScissorTest(true);
    const gap = this.viewports.length > 1 ? 2 : 0;   // liseré entre vues
    for (const v of this.viewports) {
      const x = v.rect.x + gap, y = v.rect.y + gap, w = v.rect.w - gap * 2, h = v.rect.h - gap * 2;
      r.setViewport(x, y, w, h);
      r.setScissor(x, y, w, h);
      r.render(this.scene, v.camera);
    }
    r.setScissorTest(false);
  }

  dispose() {
    this.stop();
    window.removeEventListener('resize', this._onResize);
    window.removeEventListener('orientationchange', this._onResize);
    this.renderer.dispose();
    if (this.renderer.domElement.parentNode) this.renderer.domElement.parentNode.removeChild(this.renderer.domElement);
  }
}

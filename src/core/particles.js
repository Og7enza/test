// =============================================================================
//  particles.js — Système de particules GPU mutualisé (pool unique).
//  Un seul THREE.Points + ShaderMaterial (sprite circulaire doux via
//  gl_PointCoord, pas de texture). Allocation en anneau. Effets : bouffées de
//  nuage, explosions, flashs de tir, magie de craft, étincelles d'impact.
// =============================================================================

import * as THREE from 'three';

const VERT = `
  attribute float aSize;
  attribute float aAlpha;
  varying vec3 vColor;
  varying float vAlpha;
  void main() {
    vColor = color;
    vAlpha = aAlpha;
    vec4 mv = modelViewMatrix * vec4(position, 1.0);
    gl_PointSize = aSize * (260.0 / -mv.z);
    gl_Position = projectionMatrix * mv;
  }
`;
const FRAG = `
  uniform sampler2D uTex;
  uniform float uHasTex;
  varying vec3 vColor;
  varying float vAlpha;
  void main() {
    vec2 d = gl_PointCoord - vec2(0.5);
    float r = dot(d, d);
    if (r > 0.25) discard;                 // disque
    float soft = smoothstep(0.25, 0.02, r); // bord doux
    float a = vAlpha * soft;
    if (uHasTex > 0.5) {                    // sprite optionnel (assets/textures/particle.png)
      a = vAlpha * texture2D(uTex, gl_PointCoord).a;
    }
    gl_FragColor = vec4(vColor, a);
  }
`;

export class ParticleSystem {
  constructor(scene, max = 2400) {
    this.max = max;
    this.cursor = 0;
    this.positions = new Float32Array(max * 3);
    this.colors = new Float32Array(max * 3);
    this.sizes = new Float32Array(max);
    this.alphas = new Float32Array(max);
    this.vel = new Float32Array(max * 3);
    this.life = new Float32Array(max);       // restant (s)
    this.maxLife = new Float32Array(max);
    this.grav = new Float32Array(max);
    this.drag = new Float32Array(max);

    const geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.BufferAttribute(this.positions, 3));
    geo.setAttribute('color', new THREE.BufferAttribute(this.colors, 3));
    geo.setAttribute('aSize', new THREE.BufferAttribute(this.sizes, 1));
    geo.setAttribute('aAlpha', new THREE.BufferAttribute(this.alphas, 1));
    this.geo = geo;

    this.mat = new THREE.ShaderMaterial({
      vertexShader: VERT, fragmentShader: FRAG,
      uniforms: { uTex: { value: null }, uHasTex: { value: 0 } },
      transparent: true, depthWrite: false, vertexColors: true,
      blending: THREE.AdditiveBlending,
    });
    // Sprite de particule optionnel : glow doux si l'image existe, sinon disque analytique.
    new THREE.TextureLoader().load(
      'assets/textures/particle.png',
      (t) => { this.mat.uniforms.uTex.value = t; this.mat.uniforms.uHasTex.value = 1; },
      undefined,
      () => { /* asset absent : on garde le disque procédural */ },
    );
    this.points = new THREE.Points(geo, this.mat);
    this.points.frustumCulled = false;
    scene.add(this.points);
    this._c = new THREE.Color();
  }

  _spawn(x, y, z, vx, vy, vz, color, size, life, grav, drag) {
    const i = this.cursor;
    this.cursor = (this.cursor + 1) % this.max;
    this.positions[i * 3] = x; this.positions[i * 3 + 1] = y; this.positions[i * 3 + 2] = z;
    this.vel[i * 3] = vx; this.vel[i * 3 + 1] = vy; this.vel[i * 3 + 2] = vz;
    this._c.set(color);
    this.colors[i * 3] = this._c.r; this.colors[i * 3 + 1] = this._c.g; this.colors[i * 3 + 2] = this._c.b;
    this.sizes[i] = size; this.alphas[i] = 1; this.life[i] = life; this.maxLife[i] = life;
    this.grav[i] = grav; this.drag[i] = drag;
  }

  // Émetteurs de haut niveau.
  emit(type, x, y, z, opts = {}) {
    const n = opts.count || 0;
    switch (type) {
      case 'puff':
        for (let k = 0; k < (n || 10); k++) {
          const a = Math.random() * Math.PI * 2, s = Math.random() * 1.2;
          this._spawn(x, y, z, Math.cos(a) * s, 1 + Math.random() * 1.5, Math.sin(a) * s, 0xffffff, 1.6, 0.6, -1.5, 1.5);
        }
        break;
      case 'explosion': {
        const big = opts.big;
        for (let k = 0; k < (n || (big ? 40 : 22)); k++) {
          const a = Math.random() * Math.PI * 2, e = Math.random() * Math.PI - Math.PI / 2;
          const sp = (big ? 9 : 6) * (0.4 + Math.random());
          const col = Math.random() < 0.5 ? 0xff7a18 : (Math.random() < 0.6 ? 0xffd24a : 0x553322);
          this._spawn(x, y, z, Math.cos(a) * Math.cos(e) * sp, Math.sin(e) * sp + 2, Math.sin(a) * Math.cos(e) * sp, col, big ? 2.4 : 1.6, 0.5 + Math.random() * 0.3, 8, 2.5);
        }
        break;
      }
      case 'muzzle':
        for (let k = 0; k < (n || 6); k++) {
          const a = Math.random() * Math.PI * 2, s = Math.random() * 2;
          this._spawn(x, y, z, Math.cos(a) * s, Math.random() * 1, Math.sin(a) * s, opts.color || 0xffe08a, 1.0, 0.15, 0, 6);
        }
        break;
      case 'magic':
        for (let k = 0; k < (n || 30); k++) {
          const a = Math.random() * Math.PI * 2, s = 1 + Math.random() * 2;
          const col = [0x66e0ff, 0xffd24a, 0xff8cf0, 0x9bff9b][k % 4];
          this._spawn(x + (Math.random() - 0.5), y, z + (Math.random() - 0.5), Math.cos(a) * s, 2 + Math.random() * 3, Math.sin(a) * s, col, 1.3, 0.8 + Math.random() * 0.4, -2, 1.2);
        }
        break;
      case 'hit':
        for (let k = 0; k < (n || 8); k++) {
          const a = Math.random() * Math.PI * 2, e = Math.random() * Math.PI - Math.PI / 2, sp = 4 * Math.random();
          this._spawn(x, y, z, Math.cos(a) * sp, Math.sin(e) * sp, Math.sin(a) * sp, opts.color || 0xffffff, 0.9, 0.3, 5, 3);
        }
        break;
      case 'trail':
        this._spawn(x, y, z, 0, 0, 0, opts.color || 0xffffff, opts.size || 0.6, 0.25, 0, 1);
        break;
    }
  }

  update(dt) {
    const { positions, vel, life, maxLife, alphas, sizes, grav, drag, max } = this;
    for (let i = 0; i < max; i++) {
      if (life[i] <= 0) { if (alphas[i] !== 0) { alphas[i] = 0; sizes[i] = 0; } continue; }
      life[i] -= dt;
      const d = 1 - drag[i] * dt;
      vel[i * 3] *= d; vel[i * 3 + 1] = vel[i * 3 + 1] * d - grav[i] * dt; vel[i * 3 + 2] *= d;
      positions[i * 3] += vel[i * 3] * dt;
      positions[i * 3 + 1] += vel[i * 3 + 1] * dt;
      positions[i * 3 + 2] += vel[i * 3 + 2] * dt;
      const f = Math.max(0, life[i] / maxLife[i]);
      alphas[i] = f;
    }
    this.geo.attributes.position.needsUpdate = true;
    this.geo.attributes.aAlpha.needsUpdate = true;
    this.geo.attributes.aSize.needsUpdate = true;
    this.geo.attributes.color.needsUpdate = true;
  }
}

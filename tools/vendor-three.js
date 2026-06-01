// =============================================================================
//  tools/vendor-three.js — (Re)copie Three.js depuis node_modules vers
//  vendor/three/ pour rendre le jeu autonome/offline. Usage : `npm run vendor`
//  (nécessite `npm install` au préalable).
// =============================================================================

import { copyFile, mkdir } from 'node:fs/promises';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const SRC = join(ROOT, 'node_modules', 'three', 'build', 'three.module.js');
const DEST_DIR = join(ROOT, 'vendor', 'three');
const DEST = join(DEST_DIR, 'three.module.js');

try {
  await mkdir(DEST_DIR, { recursive: true });
  await copyFile(SRC, DEST);
  console.log('✔ Three.js copié vers vendor/three/three.module.js');
} catch (e) {
  console.error('✗ Échec : avez-vous lancé `npm install` ?\n', e.message);
  process.exit(1);
}

// =============================================================================
//  tools/build.js — Assemble le dossier `www/` (webDir de Capacitor) à partir
//  des fichiers du jeu. Usage : `npm run build`, puis `npx cap sync`.
// =============================================================================

import { cp, rm, mkdir } from 'node:fs/promises';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const WWW = join(ROOT, 'www');

// Éléments à embarquer dans l'app mobile.
const ITEMS = ['index.html', 'style.css', 'src', 'vendor', 'assets'];

await rm(WWW, { recursive: true, force: true });
await mkdir(WWW, { recursive: true });

for (const item of ITEMS) {
  try {
    await cp(join(ROOT, item), join(WWW, item), { recursive: true });
    console.log('  + ' + item);
  } catch (e) {
    if (item === 'assets') continue;   // optionnel
    console.warn('  ! ignoré : ' + item + ' (' + e.code + ')');
  }
}
console.log('\n✔ Build prêt dans www/. Lancez `npx cap sync` pour synchroniser Android/iOS.');

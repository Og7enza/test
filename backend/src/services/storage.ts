import fs from 'fs';
import path from 'path';

import { config } from '../config';

const dir = path.join(process.cwd(), 'uploads');

/**
 * Stocke l'image et renvoie une URL publique.
 * - `local` (défaut) : écrit dans `uploads/`, servi par Express.
 * - `s3` / `ipfs` : à implémenter (TODO) selon STORAGE + clés.
 */
export async function saveImage(buf: Buffer, filename: string): Promise<string> {
  // TODO: if (config.storage === 's3') { ... }  / if ('ipfs') { web3.storage }
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, filename), buf);
  return `${config.publicBaseUrl}/uploads/${filename}`;
}

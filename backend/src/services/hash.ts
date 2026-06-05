import crypto from 'crypto';

/** Empreinte SHA-256 (hex) des octets d'une image. */
export function sha256Hex(buf: Buffer): string {
  return crypto.createHash('sha256').update(buf).digest('hex');
}

const ALPHABET = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'; // Crockford base32

/**
 * Matricule public lisible et déterministe : `TC-XXXX-XXXX-XXXX`.
 * (Même logique que le client, mais le serveur fait foi.)
 */
export function deriveMatricule(sha256: string, capturedAt: Date): string {
  const seed = `${sha256}|${capturedAt.toISOString()}`;
  const digest = crypto.createHash('sha256').update(seed).digest();
  let s = '';
  for (let i = 0; i < 12; i++) {
    s += ALPHABET[digest[i] % ALPHABET.length];
    if (i === 3 || i === 7) s += '-';
  }
  return `TC-${s}`;
}

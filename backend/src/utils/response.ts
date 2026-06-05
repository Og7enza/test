import { Response } from 'express';

/** Enveloppe de succès attendue par l'app : { content, message? }. */
export function ok(res: Response, content: unknown, message?: string) {
  return res.status(200).json({ content, ...(message ? { message } : {}) });
}

export function fail(res: Response, status: number, message: string) {
  return res.status(status).json({ message });
}

export function rid(prefix = ''): string {
  return (
    prefix +
    Date.now().toString(36) +
    Math.random().toString(36).slice(2, 8)
  );
}

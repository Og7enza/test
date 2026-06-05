import { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';

import { config } from '../config';
import { store } from '../store';
import { User } from '../types';
import { fail } from '../utils/response';

export interface AuthedRequest extends Request {
  user?: User;
}

/**
 * Auth par jeton Bearer.
 * - Mode démo (JWT_SECRET absent) : tout jeton -> utilisateur de démo.
 * - Mode réel : vérifie un JWT signé avec JWT_SECRET (payload { uid }).
 *   (Pour faire marcher l'app d'ORIGINE telle quelle, brancher ici la
 *   vérification des jetons Firebase via firebase-admin.)
 */
export function auth(req: AuthedRequest, res: Response, next: NextFunction) {
  const header = (req.headers['authorization'] || '').toString();
  const token = header.replace(/^Bearer\s+/i, '').trim();

  if (!config.authEnabled) {
    req.user = store.getUserByUid('demo');
    return next();
  }
  if (!token) return fail(res, 401, 'Token manquant');
  try {
    const payload = jwt.verify(token, config.jwtSecret) as { uid: string };
    const user = store.getUserByUid(payload.uid);
    if (!user) return fail(res, 401, 'Utilisateur inconnu');
    req.user = user;
    return next();
  } catch {
    return fail(res, 401, 'Token invalide');
  }
}

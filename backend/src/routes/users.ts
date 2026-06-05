import { Router } from 'express';

import { auth, AuthedRequest } from '../middleware/auth';
import { store } from '../store';
import { ok } from '../utils/response';

const r = Router();

r.post('/createUser', auth, (req: AuthedRequest, res) => {
  const b = (req.body || {}) as { name?: string; email?: string; uid?: string };
  const uid = b.uid || req.user?.uid || 'demo';
  const user = store.upsertUser({
    id: uid,
    uid,
    name: b.name || 'Utilisateur',
    email: b.email || '',
  });
  return ok(res, user);
});

r.get('/getUser', auth, (req: AuthedRequest, res) => ok(res, req.user));

r.delete('/deleteUser', auth, (req: AuthedRequest, res) => {
  store.deleteUser(req.user!.uid);
  return ok(res, { deleted: true });
});

export default r;

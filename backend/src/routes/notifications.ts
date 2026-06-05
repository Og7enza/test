import { Router } from 'express';

import { auth, AuthedRequest } from '../middleware/auth';
import { store } from '../store';
import { ok } from '../utils/response';

const r = Router();

r.get('/', auth, (req: AuthedRequest, res) =>
  ok(res, store.listNotifications(req.user!.uid)),
);

r.patch('/archive', auth, (req: AuthedRequest, res) => {
  store.markNotificationsRead(req.user!.uid);
  return ok(res, { ok: true });
});

export default r;

import { Router } from 'express';

import { auth, AuthedRequest } from '../middleware/auth';
import { store } from '../store';
import { ok } from '../utils/response';

const r = Router();

r.get('/', auth, (req: AuthedRequest, res) =>
  ok(res, store.listTransactions(req.user!.uid)),
);

export default r;

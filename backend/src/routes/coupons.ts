import { Router } from 'express';

import { auth } from '../middleware/auth';
import { store } from '../store';
import { fail, ok } from '../utils/response';

const r = Router();

r.get('/getCoupons', auth, (_req, res) => ok(res, store.listCoupons()));

r.get('/verify', auth, (req, res) => {
  const code = String(req.query.coupon_code || '');
  const c = store.getCoupon(code);
  if (!c) return fail(res, 404, 'Coupon invalide');
  return ok(res, c);
});

export default r;

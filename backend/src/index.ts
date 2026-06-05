import cors from 'cors';
import express from 'express';
import path from 'path';

import { config, modeSummary } from './config';
import coupons from './routes/coupons';
import images from './routes/images';
import notifications from './routes/notifications';
import transactions from './routes/transactions';
import users from './routes/users';

const app = express();
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(process.cwd(), 'uploads')));

const p = config.apiPrefix;

app.get(`${p}/health`, (_req, res) =>
  res.json({ content: { status: 'ok', mode: modeSummary() } }),
);

app.use(`${p}/images`, images);
app.use(`${p}/users`, users);
app.use(`${p}/coupons`, coupons);
app.use(`${p}/notifications`, notifications);
app.use(`${p}/transactions`, transactions);

app.listen(config.port, () => {
  // eslint-disable-next-line no-console
  console.log(
    `TruthCatcher backend  ->  http://localhost:${config.port}${p}  [${modeSummary()}]`,
  );
});

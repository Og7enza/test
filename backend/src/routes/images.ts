import { Router } from 'express';
import multer from 'multer';

import { auth, AuthedRequest } from '../middleware/auth';
import { deriveMatricule, sha256Hex } from '../services/hash';
import { mintNft } from '../services/nft';
import { saveImage } from '../services/storage';
import { store } from '../store';
import { Certificate } from '../types';
import { fail, ok, rid } from '../utils/response';

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 20 * 1024 * 1024 },
});

const r = Router();

// Heure de confiance (le serveur fait foi).
r.get('/getTimeStamp', auth, (_req, res) => ok(res, new Date().toISOString()));

r.get('/all', auth, (req: AuthedRequest, res) =>
  ok(res, store.listCertificates(req.user!.uid, false)),
);

r.get('/archive', auth, (req: AuthedRequest, res) =>
  ok(res, store.listCertificates(req.user!.uid, true)),
);

r.get('/get_current_buyback', auth, (_req, res) =>
  ok(res, { amount: 1.5, currency: 'EUR' }),
);

// Vérification publique par matricule.
r.get('/searchImage/:matricule', auth, (req, res) => {
  const c = store.getByMatricule(req.params.matricule);
  if (!c || !c.isPublic) return fail(res, 404, 'Image Not Found');
  return ok(res, c);
});

// ⭐ Certifier : hash (serveur) -> matricule -> stockage -> mint NFT -> sauvegarde.
r.post('/upload', auth, upload.single('image'), async (req: AuthedRequest, res) => {
  if (!req.file) return fail(res, 400, 'image manquante');
  const body = (req.body || {}) as Record<string, string>;

  const sha = sha256Hex(req.file.buffer);
  const capturedAt = body.time ? new Date(body.time) : new Date();
  const matricule = deriveMatricule(sha, capturedAt);
  const imageUrl = await saveImage(req.file.buffer, `${matricule}.jpg`);
  const mint = await mintNft({ matricule, sha256: sha });

  const now = new Date().toISOString();
  const cert: Certificate = {
    _id: matricule,
    userId: req.user!.uid,
    matricule,
    name: body.name || 'Sans titre',
    image: imageUrl,
    sha256: sha,
    lat: body.lat ? Number(body.lat) : undefined,
    lng: body.lng ? Number(body.lng) : undefined,
    location: body.location || '',
    city: body.city,
    country: body.country,
    time: capturedAt.toISOString(),
    status: 'minted',
    tokenId: mint.tokenId,
    contractAddress: mint.contractAddress,
    nftTransferHash: mint.txHash,
    chain: mint.chain,
    isArchived: false,
    isPublic: body.isPublic ? body.isPublic !== 'false' : true,
    transactionId: body.stripeTransactionId,
    createdAt: now,
    __v: 0,
  };
  store.addCertificate(cert);
  store.addTransaction({
    _id: rid('t_'),
    userId: req.user!.uid,
    type: 'mint',
    amount: Number(body.amount || 0),
    currency: body.currency || 'EUR',
    matricule,
    status: 'Réussi',
    createdAt: now,
  });

  return ok(res, cert, 'Image Minted Successfully');
});

r.post('/archive/:matricule', auth, (req, res) => {
  const c = store.updateByMatricule(req.params.matricule, { isArchived: true });
  if (!c) return fail(res, 404, 'Image Not Found');
  return ok(res, c);
});

r.patch('/unArchive/:matricule', auth, (req, res) => {
  const c = store.updateByMatricule(req.params.matricule, { isArchived: false });
  if (!c) return fail(res, 404, 'Image Not Found');
  return ok(res, c);
});

r.post('/transferNft', auth, (req, res) => {
  const matricule = (req.body as { matricule?: string }).matricule;
  if (!matricule) return fail(res, 400, 'matricule manquant');
  const c = store.updateByMatricule(matricule, {
    nftTransferHash: '0x' + Date.now().toString(16),
  });
  if (!c) return fail(res, 404, 'Image Not Found');
  return ok(res, c, 'Purchase Successful');
});

export default r;

# TruthCatcher — Backend

Backend de certification de photos pour TruthCatcher. Implémente le **contrat
d'API reconstitué** dans [`../truthcatcher/docs/BACKEND_API.md`](../truthcatcher/docs/BACKEND_API.md),
de façon à pouvoir servir **l'app d'origine** (en changeant simplement son
`baseUrl`) **ou** le rework (via un `ApiCertificationRepository`).

## Philosophie : « tourne tout de suite, devient réel avec les clés »

Le backend **démarre sans aucune configuration** (mode démo) :
- store **en mémoire** (pas de base de données requise) + données de démo,
- **hash SHA‑256** et **matricule** réels,
- **horodatage** serveur réel,
- stockage des images sur **disque local** (`uploads/`),
- **mint NFT simulé**, **paiement simulé** (aucun secret nécessaire).

Chaque brique devient **réelle** dès que la variable d'environnement
correspondante est fournie (voir `.env.example`) :
- `MONGODB_URI` → persistance MongoDB au lieu de la mémoire,
- `JWT_SECRET` → vraie auth par jeton (sinon mode démo : utilisateur de test),
- `POLYGON_RPC_URL` + `MINTER_PRIVATE_KEY` + `NFT_CONTRACT_ADDRESS` → **vrai mint
  Polygon (gas‑free via le wallet sponsor)**,
- `STORAGE=s3|ipfs` (+ clés) → stockage objet/décentralisé,
- `STRIPE_SECRET_KEY` → vrais paiements.

## Démarrer (zéro config)

```bash
cd backend
npm install
npm run dev          # http://localhost:4000  (mode démo, tout simulé)
# Tester :
curl http://localhost:4000/api/v1/health
curl http://localhost:4000/api/v1/images/all -H "authorization: Bearer demo"
```

## Endpoints (cf. BACKEND_API.md)

| Méthode | Route | Rôle |
|---|---|---|
| GET | `/api/v1/health` | Santé du service |
| POST | `/api/v1/users/createUser` | Créer le profil |
| GET | `/api/v1/users/getUser` | Profil courant |
| DELETE | `/api/v1/users/deleteUser` | Supprimer le compte |
| GET | `/api/v1/images/getTimeStamp` | Heure de confiance |
| POST | `/api/v1/images/upload` | **Certifier** (hash + matricule + mint) |
| GET | `/api/v1/images/all` | Mes preuves |
| GET | `/api/v1/images/searchImage/:matricule` | **Vérifier** par matricule |
| POST | `/api/v1/images/archive/:matricule` | Archiver |
| GET | `/api/v1/images/archive` | Lister les archivées |
| PATCH | `/api/v1/images/unArchive/:matricule` | Désarchiver |
| POST | `/api/v1/images/transferNft` | Transférer le NFT |
| GET | `/api/v1/images/get_current_buyback` | Prix de rachat |
| GET | `/api/v1/coupons/getCoupons` | Coupons |
| GET | `/api/v1/coupons/verify` | Vérifier un coupon |
| GET | `/api/v1/notifications` | Notifications |
| PATCH | `/api/v1/notifications/archive` | Marquer lues |
| GET | `/api/v1/transactions` | Transactions |

Toutes les réponses suivent l'enveloppe `{ "content": <data>, "message"?: string }`.

## Architecture

```
src/
├── index.ts            # app Express + montage des routes + /uploads statique
├── config.ts           # lecture .env + détection du mode (démo vs réel)
├── types.ts            # types Certificate (MintedImage), User, etc.
├── store.ts            # accès données : mémoire (défaut) ou MongoDB (si URI)
├── middleware/auth.ts  # Bearer -> utilisateur (démo: jeton libre)
├── services/
│   ├── hash.ts         # SHA-256 + dérivation du matricule (réel)
│   ├── storage.ts      # disque local | S3 | IPFS (pluggable)
│   ├── nft.ts          # mint Polygon gas-free (mock | ethers réel)
│   └── payment.ts      # Stripe (mock | réel)
├── routes/*.ts         # users, images, coupons, notifications, transactions
└── utils/response.ts   # enveloppe { content, message }
```

## Mint NFT « gas‑free » (cible)

L'utilisateur ne paie **jamais** le gas : un **wallet sponsor** (le backend)
paie. Implémentation cible dans `services/nft.ts` :
- `ethers` + un **RPC Polygon** (Alchemy/Infura),
- un **smart contract ERC‑721** (déployé sur **Amoy testnet** d'abord, puis
  mainnet) avec une fonction `mintTo(address, tokenURI)`,
- le backend signe et envoie la tx avec `MINTER_PRIVATE_KEY` (il paie le gas),
- le `tokenURI` pointe vers les **métadonnées** (matricule, hash, geo, date,
  historique) stockées via `storage.ts` (IPFS recommandé).
- Option « vraiment sans clé privée en prod » : relayer / Account Abstraction
  (OpenZeppelin Defender, Biconomy, Gelato).

## Déploiement

`Dockerfile` fourni. Cibles simples (pas besoin de l'ancien AWS) :
**Render**, **Railway**, **Fly.io** (Docker). Ajouter les variables
d'environnement du `.env` dans le service, et un volume/persistance pour
`uploads/` (ou activer S3/IPFS).

## ⚠️ Ce dont j'ai besoin de toi pour passer en « réel » (par ordre de priorité)

1. **Hébergement** choisi (Render / Railway / Fly / autre) → je fournis la config.
2. **Base de données** : une **MongoDB** (gratuit : MongoDB Atlas) → `MONGODB_URI`.
3. **Blockchain (mint réel)** : un **RPC Polygon** (Alchemy/Infura, gratuit) +
   une **clé privée de wallet** dédié au mint (on commence sur **Amoy testnet**,
   gas gratuit via faucet) → `POLYGON_RPC_URL`, `MINTER_PRIVATE_KEY`. Je déploie
   le smart contract.
4. **Stockage** : décision **S3** (AWS/Backblaze) **ou IPFS** (web3.storage,
   gratuit) → clés correspondantes.
5. **Auth** : soit on garde **Firebase** (il faut un projet Firebase + clé de
   service Admin) pour que **l'app d'origine** marche sans modif ; soit on passe
   à une **auth JWT** maison (plus simple, mais il faut adapter l'app). → ton choix.
6. **Paiements** (optionnel) : un compte **Stripe** → `STRIPE_SECRET_KEY`.

> Tant que tu n'as rien fourni, le backend **tourne en mode démo** et reste
> entièrement testable.

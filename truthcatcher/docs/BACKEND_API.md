# TruthCatcher — Contrat d'API backend (reconstitué)

> **Pourquoi ce document existe**
> Le backend original (`https://backend.truthcatcher.com/api/v1`) était hébergé sur un
> compte AWS potentiellement perdu. Ce fichier **reconstitue l'API à partir du code
> client Flutter d'origine** (`truthcatchertheapp-master`). Il sert de **blueprint pour
> reconstruire le backend** à l'identique (ou mieux), que l'ancien soit retrouvé ou non.
>
> Source : rétro-ingénierie des `lib/controller/*.dart`. Les champs marqués _(supposé)_
> n'ont pas pu être confirmés à 100 % côté client et sont à valider.

## Conventions globales

- **Base URL** : `https://backend.truthcatcher.com/api/v1`
- **Auth** : toutes les routes (sauf mention contraire) exigent un header
  `Authorization: Bearer <FIREBASE_ID_TOKEN>` — jeton obtenu via
  `FirebaseAuth.instance.currentUser.getIdToken()`. Le backend vérifie ce jeton
  avec le **Firebase Admin SDK** et en déduit l'utilisateur (`userId` = Firebase UID).
- **Content-Type** : `application/json` (sauf `/images/upload` qui est `multipart/form-data`).
- **Enveloppe de réponse** : succès `200` avec un corps `{ "content": <payload>, "message"?: string }`.
  Erreurs : code HTTP ≠ 200 avec `{ "message": string }`.

---

## 1. Certification d'image & NFT (`/images`)

### `GET /images/getTimeStamp` — Horodatage de confiance
Renvoie l'heure **serveur** (source de vérité anti-triche). Le client compare en continu
l'horloge du téléphone à cette heure ; dérive > ±1 min ⇒ certification bloquée.
- **Réponse** : `{ "content": "2025-02-09T12:34:56.000Z" }` (ISO‑8601)
- _Source_ : `nft_controller.dart:325-356`

### `POST /images/upload` — Certifier une photo + minter le NFT  ⭐ cœur métier
Reçoit la photo + métadonnées, **hash l'image, génère le matricule, mint le NFT sur
Polygon, stocke l'image**, et renvoie l'objet `MintedImage` certifié.
- **Body** : `multipart/form-data`
  | champ | type | obligatoire | note |
  |---|---|---|---|
  | `image` | file (jpg) | ✅ | la photo capturée |
  | `name` | string | ✅ | titre/légende |
  | `location` | string | ✅ | adresse lisible (reverse‑geocode) |
  | `time` | string | optionnel | `DateTime.toLocal().toString()` côté client |
  | `amount` | string(number) | ✅ | montant payé |
  | `currency` | string | ✅ | ex. `usd` |
  | `stripeTransactionId` | string | ✅ | id paiement Stripe |
  | `coupon`, `couponId` | string | optionnel | si coupon appliqué |
- **Réponse** : `{ "content": MintedImage }`
- _Source_ : `nft_controller.dart:175-267`
- ⚠️ Les coordonnées GPS brutes (lat/lng) ne semblent **pas** transmises séparément —
  seule la chaîne `location` l'est. À améliorer dans le rebuild (envoyer lat/lng + précision).

### `GET /images/all` — Mes images certifiées
- **Query** _(supposé, commenté côté client)_ : `?perPage=<n>&skip=<n>`
- **Réponse** : `{ "content": [MintedImage, ...] }`
- _Source_ : `nft_controller.dart:131-173`

### `GET /images/searchImage/{matricule}` — Vérifier par matricule  ⭐
Recherche publique d'une preuve par son matricule (aussi utilisé par les deeplinks
`/nftDetails/{matricule}`).
- **Réponse** : `200 { "content": MintedImage }` · `404 { "message": "Image Not Found" }`
- _Source_ : `nft_controller.dart:450-496`

### `POST /images/archive/{matricule}` — Archiver
- **Réponse** : `{ "content": MintedImage }` · _Source_ : `nft_controller.dart:358-402`

### `GET /images/archive` — Lister les archivées
- **Query** _(supposé)_ : `?perPage&skip` · **Réponse** : `{ "content": [MintedImage] }`
- _Source_ : `nft_controller.dart:404-448`

### `PATCH /images/unArchive/{matricule}` — Désarchiver
- _Source_ : `nft_controller.dart:498-529`

### `POST /images/transferNft` — Transférer / vendre le NFT
- **Body** (json) : `receiverAddress`, `matricule`, `amount`, `stripeTransferId`,
  `applePaymentTransactionId`, `currency`, `coupon?`, `couponId?`
- _Source_ : `nft_controller.dart:531-606`

### `GET /images/get_current_buyback` — Prix de rachat courant
- _Source_ : `stripe_controller.dart:143-144`

---

## 2. Utilisateurs (`/users`)

| Méthode | Route | Rôle | Source |
|---|---|---|---|
| `POST` | `/users/createUser` | Crée le profil (après signup Firebase). Body _(supposé)_ : `{ name, email, ... }` | `auth_controller.dart:210` |
| `GET`  | `/users/getUser` | Profil de l'utilisateur courant | `user_controller.dart:28` |
| `DELETE` | `/users/deleteUser` | Suppression de compte (RGPD) | `user_controller.dart:67` |

## 3. Coupons (`/coupons`)

| Méthode | Route | Rôle | Source |
|---|---|---|---|
| `GET` | `/coupons/getCoupons` | Liste des coupons | `coupon_controller.dart:37` |
| `GET` | `/coupons/verify?coupon_code=<code>` | Valide un code | `coupon_controller.dart:67` |

## 4. Notifications (`/notifications`)

| Méthode | Route | Rôle | Source |
|---|---|---|---|
| `GET` | `/notifications` | Liste (pagination `?perPage&skip` _supposé_) | `notification_controller.dart:102` |
| `PATCH` | `/notifications/archive` | Marque comme lues/archivées | `notification_controller.dart:152` |

## 5. Transactions (`/transactions`)

| Méthode | Route | Rôle | Source |
|---|---|---|---|
| `GET` | `/transactions` | Historique d'achats (pagination _supposé_) | `transaction_controller.dart:60` |

---

## 6. Services externes (appelés directement par le client — à revoir)

- **Stripe** : `POST https://api.stripe.com/v1/payment_intents` — ⚠️ appelé **depuis le
  client** (`stripe_controller.dart:42`). Cela implique une clé secrète Stripe embarquée
  dans l'app = **risque de sécurité**. Dans le rebuild, les PaymentIntents doivent être
  créés **côté backend**.
- **Etherscan** : lookup d'adresse (`nft_controller.dart:610`) avec une clé API en clair —
  même remarque, à déplacer côté serveur.

---

## 7. Modèle `MintedImage` (schéma de données certifiées)

Déduit de `models/minted_image.dart`. C'est le document central (probablement MongoDB,
champs `_id` / `__v`).

| champ | type | description |
|---|---|---|
| `_id` | string | id document |
| `userId` | string | Firebase UID du propriétaire |
| `matricule` | string | **identifiant public infalsifiable** de la preuve |
| `name` | string | titre/légende |
| `image` | string (URL) | URL de la photo stockée (S3/IPFS) |
| `time` | string | horodatage de capture |
| `location` | string | adresse lisible |
| `transactionId` | string | id de la transaction de paiement |
| `status` | string | état (ex. minted / pending) |
| `tokenId` | string? | id du token NFT sur la chaîne |
| `contractAddress` | string? | adresse du smart contract (Polygon) |
| `nftTransferHash` | string? | hash de la tx de transfert |
| `transferedAt` | date | date de transfert |
| `isArchived` | bool | archivé ou non |
| `createdAt` | date | création |
| `__v` | int | version Mongo |

> ❗️ **Ce qui manque pour une preuve vraiment infalsifiable** (à ajouter au rebuild) :
> `sha256` de l'image, `lat`/`lng` + précision GPS, `capturedAt` serveur signé,
> `chainId`, `mintTxHash`, et idéalement une **signature** (le backend signe
> `sha256 + matricule + timestamp + geo` avec une clé privée → vérifiable hors‑ligne).

---

## 8. Pile backend probable (à confirmer / reconstruire)

D'après les usages côté client : **Node.js/Express** + **MongoDB** (`_id`, `__v`),
**Firebase Admin** (vérif. tokens + messaging), **Stripe** (paiements), **stockage objet**
(S3 ou IPFS pour `image`), et un **service de mint Polygon** (ethers.js/web3 + un wallet
relayer qui paie le gas → mint « gas‑free » pour l'utilisateur).

Voir `ARCHITECTURE.md` pour la cible de reconstruction.

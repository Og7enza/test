# TruthCatcher — Handoff / reprise de session

> Point de reprise rapide. Voir aussi `PROJET_TRUTHCATCHER.md` (descriptif/deck)
> et `BACKEND_API.md` (contrat d'API). Dernière mise à jour : juin 2026.

## Le projet en 1 phrase
App mobile de **photos infalsifiables** : capture en direct → **hash SHA‑256 +
matricule incrusté + horodatage + GPS** → certification + **NFT gas‑free
(Polygon)** → vérification publique par matricule.

## Repo / emplacements
- Repo : **`Og7enza/test`** · branche de travail : **`claude/epic-bell-E1FQl`**
- App (rework Flutter) : **`truthcatcher/`**
- Backend (Node/TS) : **`backend/`**
- Docs : `truthcatcher/docs/` (`PROJET_TRUTHCATCHER.md`, `BACKEND_API.md`, ce fichier)
- CI : `.github/workflows/truthcatcher-apk.yml` (APK), `web.yml` (web → gh-pages)

## État (✅ fait / ⏳ en attente)
| Brique | État | Détail |
|---|---|---|
| App Android (APK) | ✅ vert | Artefact `truthcatcher-debug-apk` (onglet Actions). Tout simulé (pas de backend). |
| UX d'origine portée | ✅ | Galerie **masonry** + barre **à encoche** + **Hero**. Reste : parcours capture multi‑étapes + détail enrichi. |
| Web (iPhone/Safari) | ⏳ | Build publié sur branche `gh-pages`. **Action user** : Settings→Pages→Source→*Deploy from a branch*→`gh-pages`. URL : https://og7enza.github.io/test/ |
| Backend | ✅ runnable (démo) | `cd backend && npm install && npm run dev`. Hash/matricule/horodatage réels ; NFT/stockage/paiement/auth simulés → réels via `.env`. |
| Charte graphique | ✅ | Couleurs `#1F73B9`/`#294083`/`#F2F2F2`, logo TC, Montserrat. Zéro noir. |

## Comment lancer
- **APK** : onglet Actions → run vert « TruthCatcher APK » → Artifacts → installer sur Android.
- **Web** : régler Pages (ci‑dessus) → ouvrir l'URL dans Safari.
- **App en local** : `cd truthcatcher && flutter create . && flutter pub get && flutter run`.
- **Backend** : `cd backend && npm install && npm run dev` → http://localhost:4000/api/v1/health.

## Décisions clés
- Backend d'origine perdu (AWS) → app **reconstruite en mock** (tourne sans backend).
- **Clone de l'app d'origine abandonné** (vieux plugins incompatibles Android moderne) → on **porte l'UI d'origine dans le rework**.
- Backend **reconstruit** depuis le blueprint `BACKEND_API.md`.

## En attente du user (pour passer en réel)
1. Régler **GitHub Pages** (web iPhone).
2. Pour le backend réel : **hébergeur** (Render/Railway/Fly), **MongoDB Atlas**,
   **RPC Polygon + clé wallet** (testnet Amoy), **IPFS/S3**, choix **auth
   (Firebase vs JWT)**, **Stripe** (optionnel).

## Prochaines étapes possibles
- (a) Déployer le backend · (b) brancher le backend sur le rework
  (`ApiCertificationRepository`) · (c) smart contract Polygon testnet ·
  (d) parcours de capture multi‑étapes façon original · (e) deck / questionnaires.

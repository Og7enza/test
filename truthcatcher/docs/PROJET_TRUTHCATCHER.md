# TruthCatcher — Descriptif produit, fonctionnalités & état du projet

> **À quoi sert ce document**
> Point de référence complet de l'app **TruthCatcher** : la vision, le produit,
> les fonctionnalités, l'identité de marque, l'état technique et l'historique des
> décisions. Pensé pour être réutilisé dans une autre conversation (faire un
> **deck/pitch**, **retravailler des questionnaires**, ou **reprendre le
> développement**). Dernière mise à jour : juin 2026.

---

## 1. En une phrase (elevator pitch)

**TruthCatcher est une application mobile qui transforme une photo prise sur le
vif en preuve infalsifiable** : chaque cliché est horodaté, géolocalisé, haché
(SHA‑256) et scellé par un **matricule unique** incrusté sur l'image, puis
certifié (et minté en NFT gas‑free sur Polygon) pour une valeur probante et une
traçabilité durables.

**Variantes courtes :**
- *« La preuve photo, infalsifiable et vérifiable par tous. »*
- *« Capturez la vérité : une photo, un matricule, une preuve à vie. »*

---

## 2. Le problème & la valeur (pour le deck)

**Problème.** Une photo seule ne prouve plus rien : on peut la retoucher,
rejouer sa date, mentir sur le lieu. Pour un constat, un litige, un état des
lieux, une livraison, une expertise… il manque une **preuve opposable** :
*qui*, *quoi*, *quand*, *où*, **non modifiable**.

**Solution.** Une capture **en direct dans l'app** (jamais un import), figée
par 4 garanties combinées :
1. **Empreinte** SHA‑256 de l'image (toute modification change l'empreinte).
2. **Horodatage** de confiance (anti‑triche d'horloge).
3. **Géolocalisation** (GPS + adresse).
4. **Matricule** public unique, **incrusté sur la photo** et enregistré, qui
   permet à **n'importe qui** de retrouver et vérifier la preuve.
+ **NFT** (Polygon, gas‑free) pour ancrer la preuve et son historique.

**Cas d'usage.** Constats d'assurance, états des lieux (locatif), litiges,
preuves de livraison, chantiers/BTP, expertise, journalisme, particuliers.

**Pourquoi ça marche.** La valeur = **confiance + simplicité**. L'utilisateur
prend une photo ; l'app fait le reste ; la preuve est vérifiable publiquement
via le matricule.

---

## 3. Le produit en détail — parcours utilisateur

1. **Onboarding** (3 écrans) → **Connexion / Inscription** (email, Google,
   Apple — simulés en démo).
2. **Accueil (dashboard)** : salutation, **icône de marque**, cloche
   notifications, et surtout le **dashboard de quota** (photos utilisées / total
   + barre + restantes), badge **FREE / PREMIUM**, accès Premium, et liste des
   **preuves récentes**.
3. **Capture** (bouton caméra central) : prise **en direct uniquement**
   (l'import galerie est volontairement **interdit** — essentiel au concept).
   → calcul du **hash**, dérivation du **matricule** (`TC‑XXXX‑XXXX‑XXXX`),
   **incrustation du matricule** sur la photo (filigrane), **horodatage** +
   **GPS**.
4. **Confirmation** : aperçu de la photo tamponnée, **titre/légende**, récap
   (empreinte, heure, localisation). Pour les comptes **Premium** : réglages de
   **confidentialité** (voir §4).
5. **Paiement simulé** (+ **coupons** `DEMO10` / `TRUTH50`) → **certification +
   mint NFT simulé** (gas‑free).
6. **Détail de preuve** : grande image (transition **Hero**), **matricule** mis
   en avant (copie), empreinte SHA‑256, dates (capture / certification),
   localisation **selon la précision choisie**, infos **NFT** (chaîne, token id,
   contrat, transaction), badges de **confidentialité** (public/privé + infos
   partagées), **partage**.
7. **Galerie** : grille **masonry** (tuiles de hauteurs variées, overlay
   matricule), Hero vers le détail.
8. **Recherche / Vérification** : saisir un **matricule** → retrouver la preuve.
   Fonctionne aussi via **deeplink** `/nftDetails/{matricule}`.
9. **Profil** : compte, wallet, **Abonnement Premium**, Aide, Confidentialité,
   CGU, **Archives**, **Mes transactions**, déconnexion, suppression de compte.
10. **Notifications**, **Transactions** (historique), **Archives**
    (archiver / désarchiver une preuve).

---

## 4. Modèle Premium (différenciation & monétisation)

| | **Free** | **Premium** |
|---|---|---|
| Pool de photos | **5** | **100** |
| Sous‑comptes | — | **jusqu'à 5** (partagent le pool) |
| Confidentialité de localisation | Adresse complète (public) | **Granularité** : Adresse complète / **Ville + Pays** / **Pays uniquement** / **Masquée** |
| Coordonnées GPS exactes | partagées | **on/off** |
| Horodatage précis | partagé | **on/off** |
| Visibilité de la preuve | Publique | **Privé / Public** |

- **Quota** : consommé à chaque certification ; **capture bloquée** si épuisé →
  CTA « Passer Premium ».
- **Sous‑comptes** : un compte Premium peut **lier jusqu'à 5 sous‑comptes** qui
  **puisent dans le même pool** de photos.
- **Confidentialité granulaire** : choisie **à la prise** (écran de
  confirmation), reflétée dans le détail de la preuve.
- Pistes de prix (à valider) : Premium ~**9,99 €/mois** (affiché en démo).

---

## 5. Identité de marque (charte graphique officielle)

- **Logo** : « Truth » + « Catcher », le **C** stylisé en **obturateur / œil** ;
  + un **symbole TC** (monogramme) utilisé comme **icône d'application**.
- **Couleurs** :
  - `#1F73B9` — bleu (primaire)
  - `#294083` — bleu marine (foncé, dégradés, texte)
  - `#F2F2F2` — gris clair (fond)
  - **Aucun noir** (consigne : les textes sombres sont en **marine**).
- **Typographies** : **Century Gothic Bold** (titres — non libre, substitut
  type *Jost* possible) + **Montserrat** (texte, intégré).
- Assets produits : `assets/branding/tc_wordmark.png` (logo blanc transparent),
  `assets/branding/tc_icon.png` (icône TC). Icône du launcher générée depuis
  l'icône TC.

---

## 6. État technique actuel

**Stack (rework moderne, fiable) :** Flutter ; **Riverpod** (state) ;
**go_router** ; architecture *feature‑first* (`core / features / shared`) ;
**SHA‑256** on‑device (`crypto`) ; caméra (`camera`) ; GPS
(`geolocator/geocoding`) ; incrustation image (`image`) ; galerie masonry
(`flutter_staggered_grid_view`) ; partage (`share_plus`).

**Important — tout est SIMULÉ (démo) :** il **n'y a pas de backend**.
L'authentification, le paiement, le mint NFT et le stockage sont **mockés en
local** ; la galerie est **pré‑remplie** (3 preuves de démo). Raison : le
**backend d'origine** (`backend.truthcatcher.com`, hébergé sur un **compte AWS
perdu**) n'est plus disponible.

**Le code client = blueprint du backend perdu :** voir
[`docs/BACKEND_API.md`](BACKEND_API.md) — tous les endpoints + payloads ont été
reconstitués (users, images/upload, getTimeStamp, searchImage, archive,
transferNft, coupons, notifications, transactions…). Sert à **reconstruire** le
backend.

**Distribution / builds (CI GitHub Actions) :**
- **Android (APK)** : workflow `.github/workflows/truthcatcher-apk.yml` →
  artefact `truthcatcher-debug-apk` (téléchargeable depuis l'onglet **Actions**,
  installable sur un téléphone Android). ✅ vert.
- **Web (iPhone/Safari)** : workflow `.github/workflows/web.yml` → publie le
  build Flutter web dans la branche **`gh-pages`** → servi par GitHub Pages à
  **https://og7enza.github.io/test/**. Sur web, on **navigue toute l'app** ; la
  **capture caméra** est désactivée (message « app mobile requise »).
- **iOS natif** : nécessite un **Mac (Xcode)** ou un **compte Apple Developer +
  TestFlight** (pas faisable « juste avec un iPhone » — d'où la version web).

**Dépôt & branche :** repo `Og7enza/test`, app dans le dossier **`truthcatcher/`**,
branche de travail **`claude/epic-bell-E1FQl`**. *(À terme : extraire vers un
repo dédié `truthcatcher`.)*

---

## 7. Historique & décisions clés (pour reprendre sans contexte)

- **App d'origine** : Flutter + **GetX/Provider**, **Firebase** (auth/messaging),
  **Stripe** + achats in‑app, **Hive**, **backend** Node sur AWS (perdu). Le
  client était **soudé** à ces services → **ne compile/tourne pas** sans eux.
- **Décision 1 — Rework propre** : reconstruction d'une base **moderne qui
  tourne sans backend** (tout mocké), + **charte graphique**, + features
  **Premium / quota / confidentialité**, + **capture en direct only**.
- **Décision 2 — Tentative de clone de l'original** : abandonnée. L'ancien stack
  (vieux plugins : `flutter_windowmanager` jcenter, `secure_application` vs
  `camerawesome` sur `rxdart`, etc.) est **incompatible avec les outils Android
  modernes** ↔ un Flutter récent est requis pour résoudre les conflits Dart =
  **étau** insoluble sans tout réécrire.
- **Décision 3 — Porter l'UI d'origine dans le rework** (en cours) : on ramène le
  *look & feel* et le *parcours d'image* de l'original **sur la base moderne qui
  compile**. Déjà fait : **galerie masonry**, **barre du bas à encoche + FAB
  caméra centré**, **transition Hero**.

---

## 8. Roadmap / chantiers ouverts

- **Parcours de capture multi‑étapes** façon original (caméra avec cadre →
  aperçu → étape « infos » → confirmation) — *à porter*.
- **Détail de preuve enrichi** (actions archiver/transférer façon original).
- **Backend** : reconstruire depuis `docs/BACKEND_API.md` (Node + Polygon
  gas‑free via relayer + stockage IPFS/S3 + **signature serveur** de la preuve).
- **Granularité +** : choisir **quels sous‑comptes** précis accèdent à une
  preuve privée.
- **Auth réelle** (Firebase ou autre) + **paiement réel** (Stripe/IAP) quand le
  backend revient.
- **iOS** (TestFlight) si compte Apple ; **icône/splash** ; **i18n**.
- **Migration** vers un **repo dédié**.

---

## 9. Pour les prochaines conversations

- **Faire un deck / pitch** : piocher dans §1 (pitch), §2 (problème/valeur),
  §3 (produit/parcours), §4 (Premium/monétisation), §5 (marque). Cibles :
  assurance, immobilier (état des lieux), logistique, BTP, particuliers.
- **Retravailler des questionnaires** : me fournir les questionnaires existants
  (onboarding, qualification, etc.) → je les reformule/structure en m'appuyant
  sur ce descriptif.
- **Reprendre le développement** : repartir de la branche
  `claude/epic-bell-E1FQl`, dossier `truthcatcher/`, CI APK + Web déjà en place ;
  prochaine étape recommandée = parcours de capture multi‑étapes (§8).

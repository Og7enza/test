# TruthCatcher — Architecture du rework

## 1. Vision produit

Application mobile de **photos infalsifiables**. Chaque cliché est :

1. **Capturé** dans l'app (pas d'import depuis la galerie pour la preuve forte).
2. **Horodaté** (heure de confiance, vérifiée contre dérive d'horloge).
3. **Géolocalisé** (GPS + adresse lisible, détection d'incohérences/VPN à terme).
4. **Haché** (SHA‑256 de l'image — empreinte unique, calcul **on‑device**).
5. **Certifié** → reçoit un **matricule** unique, public, infalsifiable, lié à la photo
   **et** à son auteur. Le matricule permet de **retrouver et vérifier** la preuve à tout
   moment (`/verify/{matricule}` + deeplinks).
6. **Minté en NFT** sur **Polygon** (gas‑free pour l'utilisateur), embarquant matricule +
   hash + métadonnées + historique → traçabilité et valeur probante renforcée.

## 2. Décisions de modernisation (vs app d'origine)

| Sujet | Origine | Rework | Raison |
|---|---|---|---|
| State management | GetX + Provider (mélangés) | **Riverpod** (sans codegen) | Testable, découplé, un seul paradigme |
| Navigation | `onGenerateRoute` GetX | **go_router** | Deeplinks/matricule propres, typé |
| Modèles | classes manuelles + Hive generator | classes immuables simples (codegen optionnel plus tard) | Compile sans `build_runner` |
| Réseau | `http` + logique dans les controllers | **Repository** + DTO + couche `data` | Backend remplaçable/mockable |
| Backend | requis (`backend.truthcatcher.com`) | **abstrait derrière une interface** + impl **mock locale** | L'app tourne **sans** backend pendant le rebuild |
| Hash | côté serveur | **on‑device (SHA‑256)** avant upload | Preuve calculable et vérifiable côté client |
| Sécurité clés (Stripe/Etherscan) | clés dans le client ⚠️ | **déplacées côté backend** | Ne jamais embarquer de secret |

## 3. Architecture en couches (feature‑first)

```
lib/src/
├── core/                      # transverse, sans dépendance métier
│   ├── config/    AppConfig (env, base URL, chaîne, tolérance horloge)
│   ├── theme/     couleurs, typo, ThemeData (Material 3)
│   ├── router/    go_router + routes (deeplink matricule)
│   ├── services/  HashService (SHA‑256), LocationService (GPS+geocode),
│   │              TrustedTimeService (heure de confiance + contrôle de dérive)
│   └── utils/     Result<T>, helpers
├── features/
│   ├── capture/           # prise de vue → brouillon de preuve
│   │   ├── domain/        CaptureDraft (path, bytes, hash, geo, time)
│   │   └── presentation/  CaptureScreen, PreviewConfirmScreen
│   ├── certificate/       # la preuve certifiée (ex‑MintedImage)
│   │   ├── domain/        Certificate, CertificationRepository (interface)
│   │   ├── data/          MockCertificationRepository (local), [ApiCertificationRepository à venir]
│   │   ├── application/   providers Riverpod (liste, certification)
│   │   └── presentation/  GalleryScreen, CertificateDetailScreen
│   └── verify/            # vérification par matricule
│       └── presentation/  VerifyScreen
└── shared/widgets/        # widgets réutilisables (boutons, etc.)
```

**Flux de dépendances** : `presentation` → `application` → `domain` ← `data`.
Le `domain` ne dépend de rien (ni Flutter réseau, ni backend). On échange l'implémentation
du `CertificationRepository` (mock ↔ API réelle) **sans toucher à l'UI**.

## 4. Le « contrat de preuve » (ce que garantit un matricule)

Un `Certificate` lie de façon vérifiable :

```
matricule ⟶ { sha256(image), lat, lng, capturedAt(confiance), author, [tokenId, txHash] }
```

Cible : le backend **signe** ce tuple avec une clé privée → toute personne peut vérifier
hors‑ligne (signature) **et** on‑chain (NFT). Tant que le backend n'est pas reconstruit,
le **mock** génère un matricule déterministe à partir du hash (démo locale, non probante).

## 5. Stratégie « sans backend » (phase actuelle)

- `MockCertificationRepository` : calcule le SHA‑256, génère un matricule, simule un
  tokenId/contrat, stocke en mémoire (+ fichiers locaux). ⇒ **toute l'UX est démontrable
  immédiatement**, sans réseau.
- Quand le backend (re)existe : on ajoute `ApiCertificationRepository` qui implémente la
  même interface en tapant les routes décrites dans `BACKEND_API.md`, et on bascule le
  provider. Aucune autre ligne d'UI à changer.

## 6. Reconstruction du backend (quand tu le décides)

Pile cible recommandée : **Node.js (NestJS/Express) + PostgreSQL/Mongo + stockage IPFS
(web3.storage) + ethers.js + relayer Polygon (mint gas‑free via meta‑tx / Account
Abstraction)**. Endpoints à réimplémenter : voir `BACKEND_API.md`. Ajouts recommandés :
hash + geo + signature serveur stockés dans le NFT/metadata.

## 7. Roadmap incrémentale

- [x] **M0** — Fondation : structure, thème, router, services (hash/geo/time), modèle
      `Certificate`, repository + mock, UI vertical slice (capture → certifier → détail →
      vérifier). *(en cours dans ce commit)*
- [ ] **M1** — Caméra réelle branchée + sauvegarde locale des photos + persistance (Hive/Isar).
- [ ] **M2** — `ApiCertificationRepository` + auth (Firebase ou autre) quand le backend revient.
- [ ] **M3** — Mint Polygon gas‑free (relayer) + signature de preuve + vérif on‑chain.
- [ ] **M4** — Durcissement (anti‑screenshot, détection VPN/spoof GPS), partage, notifications.
- [ ] **M5** — Backend reconstruit + bascule prod.

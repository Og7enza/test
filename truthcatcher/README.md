# TruthCatcher 📸🔒

Application mobile de **photos infalsifiables** : chaque cliché est **horodaté,
géolocalisé, haché (SHA‑256)** puis **certifié** avec un **matricule unique** qui permet
de le retrouver et de le vérifier à tout moment. Les preuves certifiées peuvent être
**mintées en NFT (gas‑free) sur Polygon** pour une traçabilité et une valeur probante
renforcées.

> Rework propre de l'application Flutter d'origine (`truthcatchertheapp`). Voir
> [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) pour les choix techniques et
> [`docs/BACKEND_API.md`](docs/BACKEND_API.md) pour le contrat d'API backend reconstitué.

## État actuel — M0 (fondation)

L'app tourne **sans backend** : un *repository mock* calcule le hash, génère le matricule
et simule le mint NFT en local, afin que toute l'expérience (capture → certifier →
détail → vérifier) soit démontrable immédiatement. Le backend pourra être branché plus
tard sans toucher à l'UI (voir l'interface `CertificationRepository`).

## Démarrer

Ce dépôt contient le code applicatif (`lib/`) et la configuration. Les dossiers de
plateforme (`android/`, `ios/`, …) se génèrent avec Flutter :

```bash
cd truthcatcher
flutter create .            # génère android/ ios/ web/ etc. autour du lib/ existant
flutter pub get
flutter run
```

Prérequis : Flutter ≥ 3.4. Permissions requises à l'exécution : **caméra** et
**localisation** (gérées par les services correspondants).

## Architecture (résumé)

```
lib/src/
├── core/        config · theme · router · services (hash, geo, time) · utils
├── features/    capture · certificate · verify
└── shared/      widgets réutilisables
```

`presentation → application → domain ← data`. Le `domain` ne dépend de rien ; on échange
le `CertificationRepository` (mock ↔ API réelle) sans modifier l'UI.

## Licence

Privé — tous droits réservés (à ajuster).

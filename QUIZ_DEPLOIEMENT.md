# 🚀 Quiz « Vrai ou IA ? » — Déploiement Firebase (projet testtruthcatcher)

- ✅ **Aucune donnée personnelle collectée** : pas d'e-mail, pas de nom — juste
  le score et le détail des réponses, anonymes. Les règles Firestore
  l'interdisent même techniquement (`hasOnly`). Le seul appel à l'action est
  volontaire : QR + lien Linktree sur l'écran final.
- ✅ **Page de résultats publique** : `resultats.html` montre en direct les
  statistiques de tous les participants (score moyen, répartition, taux de
  bonnes réponses image par image, « la plus trompeuse »).
- ✅ Tout tient dans la formule gratuite de Firebase.

```
public/
├── index.html          ← racine du site (redirige vers /quiz/)
└── quiz/
    ├── index.html      ← le quiz (intro, 13 questions, feedback, score, CTA)
    ├── resultats.html  ← résultats de tous les participants (temps réel)
    └── q1…q13.jpg, logo.png, qr.png
firebase.json           ← config Hosting (dossier public/) + règles Firestore
.firebaserc             ← projet par défaut : testtruthcatcher
firestore.rules         ← règles (voir ci-dessous)
.github/workflows/deploy-quiz.yml ← déploiement en 1 clic depuis GitHub
```

## ✅ Config Firebase : automatique

Rien à coller dans les pages : servies par Firebase Hosting, elles chargent la
config du projet via l'URL réservée `/__/firebase/init.json`. Les placeholders
restants (`VOTRE_API_KEY`, `VOTRE_APP_ID`) ne servent que de secours pour un
test en local.

> Seule condition : le projet doit avoir **au moins une application Web**
> enregistrée (Console → Paramètres du projet → Vos applications → icône `</>`).

## 📋 Étape 1 — Firestore (une seule fois, dans la Console)

1. [console.firebase.google.com](https://console.firebase.google.com) →
   projet **testtruthcatcher** → menu **Firestore Database**.
2. **Créer une base de données** (si pas déjà fait) → emplacement Europe
   (ex. `eur3`) → mode **production** → Créer.
3. Onglet **Règles** → collez ceci → **Publier** :

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /quiz_reponses/{doc} {
      allow read: if true;
      allow create: if request.resource.data.keys().hasOnly(['score', 'total', 'answers', 'createdAt'])
                    && request.resource.data.score is int
                    && request.resource.data.total is int
                    && request.resource.data.score >= 0
                    && request.resource.data.score <= request.resource.data.total
                    && request.resource.data.answers is list
                    && request.resource.data.answers.size() <= 50;
      allow update, delete: if false;
    }
  }
}
```

Ce que ça garantit : n'importe quel joueur peut **ajouter** sa participation,
tout le monde peut **lire** les statistiques (c'est anonyme), personne ne peut
**modifier/supprimer**, et il est **impossible** d'écrire un champ personnel
(e-mail, nom…) dans la collection.

## 📋 Étape 2 — Déployer

**Option A — CLI sur votre machine** (`npm i -g firebase-tools`, `firebase login`) :

```bash
firebase deploy --only hosting
```

**Option B — GitHub Actions** (aucune installation locale) :
1. Console Google Cloud → IAM → Comptes de service → clé JSON d'un compte de
   service du projet (rôle *Firebase Hosting Admin*).
2. GitHub → Settings → Secrets and variables → Actions → secret
   `FIREBASE_SERVICE_ACCOUNT` = contenu du JSON.
3. Onglet **Actions** → « Déployer le quiz (Firebase) » → **Run workflow**
   (laissez « Déployer firestore.rules » décoché — voir avertissement).

→ Quiz : **https://testtruthcatcher.web.app/** (la racine redirige vers `/quiz/`)
→ Résultats : **https://testtruthcatcher.web.app/quiz/resultats.html**

## ⚠️ Règles Firestore via CLI : prudence

`firebase deploy --only firestore:rules` **remplace l'intégralité des règles
Firestore du projet** par le fichier `firestore.rules` de ce repo. Ne l'utilisez
(ou ne cochez l'option du workflow) que si ce fichier est votre unique source
de règles. Sinon, passez par la Console (étape 1).

## 🧪 Test de validation

1. Jouez une partie complète sur l'URL déployée → écran final :
   « Vos réponses anonymes sont enregistrées » **sans ⚠️**.
2. Console → Firestore → collection **quiz_reponses** : un document avec
   `score`, `total`, `answers` (détail par question), `createdAt` — et rien
   d'autre.
3. Ouvrez **resultats.html** : votre participation apparaît dans les stats
   (mise à jour en direct).

Si ⚠️ apparaît : Firestore pas créé, règles pas publiées, ou aucune app Web
enregistrée dans le projet (voir plus haut).

## 🔧 Modifier le quiz plus tard

- **Changer une image** : remplacez `public/quiz/qN.jpg` (gardez le nom).
- **Ordre / bonnes réponses** : tableau `QUIZ` dans `public/quiz/index.html`
  **et** dans `public/quiz/resultats.html` (les deux doivent rester identiques).
- **Textes** : en clair dans le HTML.

Hébergement gratuit (palier gratuit Firebase largement suffisant pour une
étude / démo).

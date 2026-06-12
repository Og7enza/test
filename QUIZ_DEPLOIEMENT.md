# 🚀 Quiz « Vrai ou IA ? » — Déploiement Firebase (truthcatcher-sequence)

Le quiz est intégré dans ce repo, prêt à déployer :

```
public/
├── index.html          ← page racine provisoire (redirige vers /quiz/)
└── quiz/               ← le quiz complet (index.html + q1…q13.jpg + logo + QR)
firebase.json           ← config Hosting (dossier public/) + règles Firestore
.firebaserc             ← projet par défaut : truthcatcher-sequence
firestore.rules         ← règle « create seulement » sur quiz_reponses
.github/workflows/deploy-quiz.yml ← déploiement en 1 clic depuis GitHub (optionnel)
```

## ✅ Config Firebase : automatique

Plus besoin de coller `apiKey` & co dans `index.html` : une fois servi par
Firebase Hosting, le quiz charge la config du projet via l'URL réservée
`/__/firebase/init.json`. Les placeholders (`VOTRE_API_KEY`…) ne servent que de
secours hors Hosting (test local) — vous pouvez les remplacer si vous voulez
tester en local avec Firestore, sinon ignorez-les.

> Seule condition : le projet doit avoir **au moins une application Web**
> enregistrée (Console → Paramètres du projet → Vos applications → icône `</>`).

## 📋 Il reste 2 étapes (5 min)

### 1. Activer Firestore (une seule fois, dans la Console)

Console Firebase → **Firestore Database** → **Créer une base de données** →
mode **production**. Les règles sont dans `firestore.rules` ; elles seront
poussées au déploiement (ou collez-les dans l'onglet *Règles*) :

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /quiz_reponses/{doc} {
      allow create: if true;
      allow read, update, delete: if false;
    }
  }
}
```

N'importe quel joueur peut envoyer ses réponses, personne ne peut les lire ni
les modifier depuis le web. Vous les consultez dans la Console.

### 2. Déployer

**Option A — CLI sur votre machine** (repo cloné, `npm i -g firebase-tools`,
`firebase login`) :

```bash
firebase deploy --only hosting,firestore:rules
```

**Option B — GitHub Actions** (aucune installation locale) :
1. Console Google Cloud → IAM → Comptes de service → créez une clé JSON d'un
   compte de service du projet (rôles *Firebase Hosting Admin* + *Firebase
   Rules Admin*).
2. GitHub → Settings → Secrets and variables → Actions → nouveau secret
   `FIREBASE_SERVICE_ACCOUNT` = contenu du JSON.
3. Onglet **Actions** → « Déployer le quiz (Firebase) » → **Run workflow**.

→ Le quiz sera sur **https://truthcatcher-sequence.web.app/quiz/**

## ⚠️ Important si votre site actuel a du contenu

Un déploiement Hosting **remplace tout le contenu du site** par le dossier
`public/` de ce repo. Si `truthcatcher-sequence.web.app` héberge déjà une page
d'accueil à conserver, copiez-la dans `public/` (à la place du `index.html`
de redirection) **avant** de déployer.

## 🧪 Test de validation

Jouez une partie complète sur l'URL déployée. Sur l'écran final :
- « Vos réponses sont enregistrées » sans ⚠️ → tout est bon ;
- vérifiez Console → Firestore → collection **quiz_reponses** : un document
  avec `score`, `total`, `email`, `answers` (détail par question), `createdAt`.

Si ⚠️ apparaît : Firestore pas encore créé, règles pas en place, ou aucune
app Web enregistrée dans le projet (voir plus haut).

## 🔧 Modifier le quiz plus tard

- **Changer une image** : remplacez `public/quiz/qN.jpg` (gardez le nom).
- **Ordre / bonnes réponses** : tableau `QUIZ` dans `public/quiz/index.html`.
- **Textes** : en clair dans le HTML.

Hébergement gratuit (palier gratuit Firebase largement suffisant pour une
étude / démo).

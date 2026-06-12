# 🚀 Quiz « Vrai ou IA ? » — Déploiement en parallèle (site dédié)

Le quiz est déployé sur un **site Firebase Hosting dédié** (`truthcatcher-quiz`)
dans le même projet `truthcatcher-sequence` :

- ✅ **`truthcatcher-sequence.web.app` n'est JAMAIS touché** — ce repo ne peut
  déployer que le site quiz (`"site": "truthcatcher-quiz"` dans `firebase.json`).
- ✅ Les réponses vont quand même dans le Firestore du projet (collection
  `quiz_reponses`), comme prévu.
- ✅ Compris dans la formule actuelle : le multi-sites fait partie du palier
  gratuit de Firebase (jusqu'à 36 sites par projet, sans surcoût).

```
public/
├── index.html          ← racine du site quiz (redirige vers /quiz/)
└── quiz/               ← le quiz complet (index.html + q1…q13.jpg + logo + QR)
firebase.json           ← Hosting ciblé sur le site "truthcatcher-quiz"
.firebaserc             ← projet par défaut : truthcatcher-sequence
firestore.rules         ← règle « create seulement » sur quiz_reponses (référence)
.github/workflows/deploy-quiz.yml ← déploiement en 1 clic depuis GitHub
```

## ✅ Config Firebase : automatique

Rien à coller dans `index.html` : servi par Firebase Hosting, le quiz charge la
config du projet via l'URL réservée `/__/firebase/init.json` (disponible sur
tous les sites du projet, y compris le site dédié). Les placeholders
(`VOTRE_API_KEY`…) ne servent que de secours pour un test en local.

> Seule condition : le projet doit avoir **au moins une application Web**
> enregistrée (Console → Paramètres du projet → Vos applications → icône `</>`).

## 📋 Les étapes restantes

### 1. Firestore (une seule fois, dans la Console — sans rien casser)

- **Si Firestore n'existe pas encore** : Console → Firestore Database →
  Créer une base de données → mode production, puis collez le contenu de
  `firestore.rules` dans l'onglet *Règles*.
- **Si Firestore existe déjà** : ne remplacez PAS vos règles. Ajoutez juste ce
  bloc **à l'intérieur** de votre `match /databases/{database}/documents` :

```
match /quiz_reponses/{doc} {
  allow create: if true;
  allow read, update, delete: if false;
}
```

N'importe quel joueur peut envoyer ses réponses, personne ne peut les lire ni
les modifier depuis le web. Vous les consultez dans la Console.

### 2. Déployer (ne touche que le site quiz)

**Option A — CLI sur votre machine** (`npm i -g firebase-tools`, `firebase login`) :

```bash
firebase hosting:sites:create truthcatcher-quiz   # une seule fois
firebase deploy --only hosting                    # déploie UNIQUEMENT le site quiz
```

**Option B — GitHub Actions** (aucune installation locale) :
1. Console Google Cloud → IAM → Comptes de service → clé JSON d'un compte de
   service du projet (rôle *Firebase Hosting Admin*).
2. GitHub → Settings → Secrets and variables → Actions → secret
   `FIREBASE_SERVICE_ACCOUNT` = contenu du JSON.
3. Onglet **Actions** → « Déployer le quiz (Firebase) » → **Run workflow**
   (le site dédié est créé automatiquement au premier lancement ; laissez
   « Déployer firestore.rules » décoché — voir avertissement ci-dessous).

→ Le quiz sera sur **https://truthcatcher-quiz.web.app/** (la racine redirige
vers `/quiz/`).

> Si l'ID `truthcatcher-quiz` est déjà pris au niveau mondial, choisissez-en un
> autre (ex. `truthcatcher-quiz-vrai-ou-ia`) aux deux endroits : `firebase.json`
> (`"site"`) et la commande/le workflow de création de site.

## ⚠️ Règles Firestore via CLI : prudence

`firebase deploy --only firestore:rules` **remplace l'intégralité des règles
Firestore du projet** par le fichier `firestore.rules` de ce repo. Ne l'utilisez
(ou ne cochez l'option du workflow) que si Firestore vient d'être créé et que ce
fichier est votre unique source de règles. Sinon, passez par la Console
(ajout additif, étape 1).

## 🧪 Test de validation

Jouez une partie complète sur l'URL déployée. Sur l'écran final :
- « Vos réponses sont enregistrées » sans ⚠️ → tout est bon ;
- vérifiez Console → Firestore → collection **quiz_reponses** : un document
  avec `score`, `total`, `email`, `answers` (détail par question), `createdAt`.

Si ⚠️ apparaît : Firestore pas créé, règle `quiz_reponses` absente, ou aucune
app Web enregistrée dans le projet (voir plus haut).

## 🔧 Modifier le quiz plus tard

- **Changer une image** : remplacez `public/quiz/qN.jpg` (gardez le nom).
- **Ordre / bonnes réponses** : tableau `QUIZ` dans `public/quiz/index.html`.
- **Textes** : en clair dans le HTML.

Hébergement gratuit (palier gratuit Firebase largement suffisant pour une
étude / démo).

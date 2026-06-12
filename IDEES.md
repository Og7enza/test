# Idées / pistes pour plus tard

## Mode « Soirée » (jeu à boire) — idée du 12/06/2026

- Sélecteur de modes sur l'écran d'accueil : **Original** / **Soirée** / **Survival**
- **Soirée** : à chaque mauvaise réponse, « À boire ! » pendant 5 s au début
  de la question suivante (timer porté à 15 s), compteur de shots, écran
  final « vous avez bu X shots ». Bandeau « à consommer avec modération ».
- **Survival** : les images s'enchaînent jusqu'à la première erreur.
  Prérequis : élargir le stock d'images (30-50+, sourcées/créditées comme
  les actuelles).
- À héberger sur une page séparée (ex. `/quiz/soiree.html`) pour préserver
  la vitrine pro de TruthCatcher.
- Technique : ajouter un champ `mode` aux documents enregistrés pour
  séparer les stats → mettre à jour le `hasOnly([...])` dans
  `firestore.rules` (sinon l'écriture sera refusée).
- `TIME_PER_Q` est la constante du chrono dans `public/quiz/index.html`.

## Monétisation (réflexion du 12/06/2026)

1. **Quiz web actuel = acquisition, pas revenu** : funnel vers la
   wishlist/bêta TruthCatcher ; stats publiables (« baromètre Vrai ou IA »).
2. **Premier revenu réaliste** : atelier de sensibilisation deepfakes en
   entreprise (quiz personnalisé aux couleurs/images du client, stats
   privées, débrief) — 500 à 2 000 € la session, produit déjà prêt à 90 %.
3. **App party game (marque séparée)** : freemium — Original + Survival
   gratuits, mode Soirée premium ~2,99 € (RevenueCat), pub rewarded en
   option. Marché saturé : pari fun, pas un plan de revenus principal.
4. Licences photos CC BY-SA : usage commercial OK avec attribution (déjà
   affichée dans le quiz).
5. Jamais de mélange de marque TruthCatcher ↔ alcool ; 18+, loi Évin.

Le prompt complet « application mobile commerciale » est dans la
conversation Claude du 12/06/2026 (session quiz) — points clés : Capacitor,
dossier quizapp/, appId com.partyproof.app, RevenueCat avec mode démo,
privacy policy + fiches store FR/EN, APK/AAB via GitHub Actions.

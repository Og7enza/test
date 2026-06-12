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

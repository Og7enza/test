# Deck de présentation — Portfolio IA & gain de token

> Version texte du deck. La version présentable (plein écran, navigation clavier,
> hors-ligne) est dans [`presentation/index.html`](index.html).
> Structure : **Présentation → Étude de gain de token → Pitch**.

---

## PARTIE 1 — PRÉSENTATION

### Slide 1 — Titre
**Trois produits, une méthode.**
Divine Rivals · TruthCatcher · Quiz « Vrai ou IA ? »
Construits de bout en bout avec un agent IA — et une facture de tokens divisée par ~3.

### Slide 2 — Le constat
- Développer un jeu ou une app assistés par IA coûte surtout en **tokens** : contexte
  relu, code généré, itérations ratées, génération d'assets.
- La plupart du coût est **invisible** : il vient de la structure du projet, pas des
  fonctionnalités.
- Question posée : peut-on livrer autant en dépensant beaucoup moins de tokens ?

### Slide 3 — Le portfolio en un coup d'œil
| Produit | Nature | Plateforme | État |
| --- | --- | --- | --- |
| **Divine Rivals** | Jeu action/stratégie temps réel 3D | Web (Three.js) + Unity | Jouable, hors-ligne |
| **TruthCatcher** | Photos infalsifiables (hash SHA-256, horodatage, NFT Polygon) | Flutter mobile | M0, démo mock complète |
| **Quiz « Vrai ou IA ? »** | Sensibilisation deepfakes + acquisition | Web / Firebase | Déployable |

### Slide 4 — Divine Rivals
- « Build & battle » réimaginé sur un thème mythologie grecque & égyptienne.
- **100 % original et hors-ligne** : modèles 3D procéduraux (primitives Three.js),
  audio synthétisé (Web Audio API), zéro asset externe.
- 64 missions de campagne, IA d'alliés à *gambits*, multijoueur écran partagé,
  système de craft par empilement de nuages (11 armes, véhicules, coéquipiers).
- Portage **Unity** avec mécanique « Chaudron / Tier / nuages colorés ».

### Slide 5 — TruthCatcher
- Chaque photo est **horodatée, géolocalisée, hachée (SHA-256)** puis **certifiée**
  avec un matricule unique vérifiable à tout moment.
- Preuves *mintables* en **NFT gas-free sur Polygon**.
- Architecture propre `presentation → application → domain ← data` : on branche le
  backend réel sans toucher à l'UI.
- Zéro donnée personnelle sur le funnel public associé.

### Slide 6 — Quiz « Vrai ou IA ? »
- Outil d'acquisition et **atelier B2B de sensibilisation aux deepfakes**
  (500 à 2 000 € la session, produit prêt à ~90 %).
- Bilingue FR/EN, chronomètre, résultats publics en temps réel.
- **Aucune donnée personnelle** collectée (garanti par les règles Firestore),
  hébergement gratuit Firebase.

### Slide 7 — La méthode commune
Six choix, appliqués partout :
1. **Génération procédurale** (visuels + audio dans le code).
2. **Logique pure et testable** (modules déterministes, validables en une ligne).
3. **Architecture modulaire** (fichiers courts, responsabilité unique).
4. **Réutilisation cross-plateforme** (même design JS → Unity → Flutter).
5. **Autonomie hors-ligne** (dépendances *vendorisées*, runs reproductibles).
6. **Docs durables** (README/ARCHITECTURE compacts = ré-onboarding bon marché).

---

## PARTIE 2 — ÉTUDE DE GAIN DE TOKEN

### Slide 8 — Pourquoi mesurer les tokens
- Le vrai coût du dev IA n'est pas le code final, mais le **contexte relu** et les
  **itérations**.
- Livrable mesuré ici : **8 131 lignes de code** (JS 3 773 · C# 1 709 · Dart 1 580 ·
  HTML/CSS 1 069), ~1 000 lignes de docs, **0 asset généré** pour le jeu.

### Slide 9 — Méthode & hypothèses
- On décompose la consommation en 4 postes : **écriture du code**, **itérations**,
  **assets**, **ré-onboarding**.
- Hypothèses unitaires explicites et ajustables (12 tk/ligne ; contexte relu ×18 naïf
  vs ×6 adopté ; itération manuelle 4 500 tk vs test pur 1 200 tk ; asset génératif
  3 000 tk + 1 génération média).
- Estimation transparente, **pas** une télémétrie. Voir
  [`ETUDE_GAIN_TOKEN.md`](ETUDE_GAIN_TOKEN.md).

### Slide 10 — Le bilan chiffré
| Poste | Naïf | Méthode | Gain |
| --- | ---: | ---: | ---: |
| Écriture du code | 1 854 k | 683 k | 1 171 k |
| Itérations / debug | 585 k | 183 k | 402 k |
| Assets | 144 k | 15 k | 129 k (+48 générations) |
| Ré-onboarding | 455 k | 141 k | 314 k |
| **Total** | **≈ 3,04 M** | **≈ 1,02 M** | **≈ 2,02 M (~66 %)** |

### Slide 11 — Résultat
> **≈ 2,0 millions de tokens économisés (~66 %)** et **48 générations d'images/audio
> évitées**, pour un livrable équivalent.
Contribution des leviers : modularité **58 %**, logique pure/offline **20 %**,
ré-onboarding/réutilisation **16 %**, procédural **6 % + médias évités**.

### Slide 12 — Sensibilité & limites
- Fourchette : ~48 % (conservateur) → ~66 % (central) → ~72 % (agressif).
- Même au plus prudent, le gain reste **≳ 45 %** et les 48 générations média restent évitées.
- Limite : coûts unitaires supposés, à confirmer par la télémétrie réelle.

---

## PARTIE 3 — PITCH (conclusion)

### Slide 13 — Le pitch
**Nous livrons des produits complets — jeux et apps multi-plateformes — en dépensant
~3× moins de tokens d'IA, sans sacrifier la qualité ni l'originalité.**
La méthode (procédural, logique pure, modularité, docs réutilisées) est le produit :
elle transforme la structure de coût du développement assisté par IA.

### Slide 14 — Ce que ça débloque
- **Plus de produits** à budget de tokens constant.
- **Zéro dépendance** aux banques d'assets et aux crédits de génération média.
- **Portabilité** : un design, trois plateformes.
- **Reproductibilité** : hors-ligne, testable, auditable.

### Slide 15 — L'ask
- Valider l'étude avec **télémétrie réelle** sur le prochain cycle.
- Choisir le **produit tête d'affiche** à pousser en premier (Divine Rivals grand
  public, ou TruthCatcher B2B/preuve légale, ou atelier deepfakes B2B).
- Objectif : industrialiser la méthode comme **avantage de coût durable**.

> **Contact / prochaine étape :** jouer la démo, ouvrir le deck, et décider ensemble
> du premier produit à lancer.

# Étude de gain de token — portfolio Divine Rivals / TruthCatcher

> **Objet.** Quantifier les tokens d'IA (contexte lu + texte généré + itérations)
> économisés par les choix de méthode adoptés sur ce dépôt, comparés à un
> développement assisté par IA « naïf » produisant les mêmes livrables.
>
> **Statut.** Estimation transparente et paramétrable — **pas** une télémétrie
> mesurée. Toutes les hypothèses unitaires sont explicites et ajustables ci-dessous ;
> le lecteur peut recalculer avec ses propres coûts.

---

## 1. Ce qui a réellement été livré (mesuré sur le dépôt)

| Livrable | Volume mesuré |
| --- | --- |
| Code JavaScript (Divine Rivals web, Three.js) | **3 773 lignes** |
| Code C# (portage Unity « Chaudron ») | **1 709 lignes** |
| Code Dart (app Flutter TruthCatcher) | **1 580 lignes** |
| HTML / CSS (site + quiz Firebase) | **1 069 lignes** |
| **Total code** | **8 131 lignes** |
| Documentation (README, ARCHITECTURE, guides) | **~1 005 lignes** |
| Assets binaires livrés (surtout images du quiz + textures) | **32 fichiers** |
| Assets visuels/audio **générés par IA** pour le jeu | **0** (rendu 100 % procédural) |

Trois produits, trois plateformes (Web/JS, Unity/C#, Flutter/Dart), un design
partagé (recettes, Tiers, campagne, thème mytho gréco-égyptien).

---

## 2. Méthode : décomposer la consommation de tokens

La consommation réelle d'un agent IA n'est pas le poids du code final : elle est
dominée par le **contexte relu** à chaque édition et par les **itérations ratées**.
On la décompose en quatre postes indépendants :

- **A. Écriture du code** — contexte relu + texte généré pour produire l'artéfact.
  Piloté par la **modularité** (taille du contexte à charger par édition).
- **B. Itérations de correction** — reprises, debug. Piloté par la **testabilité**
  et le **déterminisme hors-ligne**.
- **C. Production des assets** — visuels / audio. Piloté par le choix
  **procédural vs génératif**.
- **D. Ré-onboarding inter-sessions** — recharger le contexte projet à chaque
  nouvelle session/plateforme. Piloté par les **docs durables** et la
  **réutilisation cross-plateforme** du design.

### Hypothèses unitaires (ajustables)

| Paramètre | Valeur retenue |
| --- | --- |
| Coût de production d'une ligne de code (sortie) | 12 tokens |
| Multiplicateur de contexte relu — approche **naïve** (fichiers monolithiques) | ×18 |
| Multiplicateur de contexte relu — méthode **adoptée** (fichiers courts, responsabilité unique) | ×6 |
| Itération de debug manuel/navigateur (reproduire l'état + décrire + corriger) | 4 500 tokens |
| Validation par **test pur** en une ligne (`node -e …`) | 1 200 tokens |
| Asset visuel/audio via IA générative (dialogue prompt + itérations + câblage) | 3 000 tokens **+ 1 génération média** |
| Ré-onboarding d'une session — sans doc durable | 15 000 tokens |
| Ré-onboarding d'une session — via README/ARCHITECTURE compacts | 5 000 tokens |

---

## 3. Calcul des deux scénarios

### A. Écriture du code
`tokens = LOC × 12 × (1 + multiplicateur de contexte)`

- Naïf : `8 131 × 12 × (1 + 18)` ≈ **1,854 M**
- Adopté : `8 131 × 12 × (1 + 6)` ≈ **0,683 M**

### B. Itérations de correction
- Naïf : 130 itérations navigateur × 4 500 ≈ **0,585 M**
- Adopté : 30 debug manuels × 4 500 + 40 tests purs × 1 200 ≈ 135 k + 48 k ≈ **0,183 M**
  *(la logique de jeu vit dans des modules purs — `recipes.js`, `campaign.js` — validables en une ligne sans navigateur)*

### C. Production des assets
- Naïf : ~48 assets du jeu (8 sols, 18 icônes, logo, splash, UI, 8 ciels, 8 SFX/musiques) × 3 000 ≈ **0,144 M** + **48 générations média**
- Adopté : rendu procédural (`assets.js` 391 l., `audio.js` 179 l., `particles.js` 155 l., déjà comptés en A) + câblage/réglage ≈ **0,015 M** + **0 génération média**

### D. Ré-onboarding inter-sessions & réutilisation cross-plateforme
- Naïf : 25 sessions × 15 000 + re-dérivation du design sur 2 plateformes × 40 000 ≈ 375 k + 80 k ≈ **0,455 M**
- Adopté : 25 sessions × 5 000 + réutilisation du design × 2 × 8 000 ≈ 125 k + 16 k ≈ **0,141 M**

### Bilan

| Poste | Naïf | Méthode adoptée | Gain |
| --- | ---: | ---: | ---: |
| A. Écriture du code | 1 854 k | 683 k | **1 171 k** |
| B. Itérations / debug | 585 k | 183 k | **402 k** |
| C. Assets | 144 k | 15 k | **129 k** (+48 générations média) |
| D. Ré-onboarding / réutilisation | 455 k | 141 k | **314 k** |
| **Total** | **≈ 3,04 M** | **≈ 1,02 M** | **≈ 2,02 M (~66 %)** |

> **Résultat principal : ≈ 2,0 millions de tokens économisés (~66 %),
> et 48 générations d'images/audio évitées** pour un livrable strictement équivalent.

---

## 4. Les leviers, par contribution au gain

1. **Architecture modulaire** — *58 % du gain (≈ 1,17 M).*
   Fichiers courts à responsabilité unique → l'agent charge un contexte réduit par
   édition au lieu d'un fichier monolithique.
2. **Logique pure et testable + déterminisme hors-ligne** — *20 % (≈ 0,40 M).*
   `recipes.js`, `campaign.js` sont purs et validables en une ligne ; Three.js est
   *vendorisé* (pas de fetch), donc runs reproductibles → moins d'itérations ratées.
3. **Ré-onboarding via docs durables + réutilisation cross-plateforme** — *16 % (≈ 0,31 M).*
   README/ARCHITECTURE compacts rechargent le contexte projet à coût réduit ; le même
   design (recettes, Tiers, campagne) est réemployé JS → Unity → Flutter.
4. **Génération procédurale des assets** — *6 % (≈ 0,13 M) + 48 générations média évitées.*
   Modèles 3D (primitives Three.js) et audio (Web Audio API) produits par le code :
   zéro asset binaire à générer, décrire et itérer.

---

## 5. Sensibilité

Le classement des leviers est robuste ; l'ampleur dépend surtout des multiplicateurs
de contexte (poste A). Fourchette selon les hypothèses :

| Scénario | Multiplicateur naïf/adopté | Gain total estimé |
| --- | --- | --- |
| Conservateur | ×10 / ×6 | ~48 % |
| Central (retenu) | ×18 / ×6 | **~66 %** |
| Agressif | ×25 / ×5 | ~72 % |

Même dans l'hypothèse conservatrice, le gain reste **≳ 45 %**, et les 48 générations
média restent évitées quel que soit le scénario.

---

## 6. Limites

- Estimation à partir de volumes réels mais de **coûts unitaires supposés** ; à
  remplacer par la télémétrie d'usage réelle dès qu'elle est disponible.
- Le scénario « naïf » est un point de comparaison plausible, pas une mesure d'un
  projet concurrent réel.
- Les crédits de génération d'images/audio (poste C) sont comptés en « générations
  évitées », pas convertis en tokens : leur coût monétaire s'ajoute au gain ci-dessus.

---

## 7. À retenir

> Sur un livrable équivalent — trois produits, trois plateformes — les choix de
> méthode (**modularité, logique pure testable, docs durables réutilisées, rendu
> procédural**) divisent la facture de tokens **par ~3** et **suppriment toute
> dépense de génération média**. Ce n'est pas une optimisation cosmétique : c'est
> la structure de coût du développement assisté par IA.

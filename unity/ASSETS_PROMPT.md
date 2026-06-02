# Prompts Claude Designer — assets cartoon légers (Unity)

Objectif : look **cartoon plat, léger, fluide sur mobile**. On reste sur des
**images 2D** (Claude Designer ne fait pas de modèles 3D). Ces images se posent
sur les formes low‑poly existantes (sol, ciel) ou dans le HUD.

## 📁 Où déposer les fichiers
Crée le dossier **`unity/Assets/Resources/art/`** et mets les PNG dedans avec **exactement**
les noms indiqués. Comme ils sont dans `Resources/`, je les chargerai **automatiquement
par code** (`Resources.Load`) — tu n'as rien à câbler dans l'éditeur.

## 🎨 STYLE COMMUN (à coller en tête de chaque prompt)
```
Style : illustration de jeu mobile, cartoon PLAT et léger, aplats de couleurs
vives, contours nets et épais, très peu de détails (optimisé mobile), ambiance
mythologie grecque & égyptienne. Pas de texte. Création 100% originale.
```

---

## 1) Sol d'arène — ⭐ gros impact, très léger  →  `art/ground.png`
```
[STYLE] + Texture de SOL vue strictement de dessus (top-down), PARFAITEMENT
CARRELABLE (seamless, bords raccordables), sans perspective ni ombre : herbe
verte cartoon avec quelques dalles de marbre crème et de minuscules fleurs.
Carré, export 1024×1024 PNG.
```

## 2) Ciel — ⭐ gros impact  →  `art/sky.png`
```
[STYLE] + Ciel cartoon : dégradé doux bleu profond en haut vers doré chaud à
l'horizon, quelques nuages blancs simples et ronds. Carré, export 1024×1024 PNG.
```

## 3) Sprite de particule (lueur) — pour les explosions/impacts  →  `art/particle.png`
```
[STYLE] + Petit disque de LUEUR douce : blanc, dégradé radial (opaque au centre →
transparent au bord). FOND TRANSPARENT. Carré, 128×128 PNG.
```

## 4) Nuages colorés du chaudron (×4, transparents)  →  `art/cloud_white.png`, `art/cloud_gray.png`, `art/cloud_gold.png`, `art/cloud_black.png`
```
[STYLE] + Icône de NUAGE cartoon tout simple, [COULEUR] (blanc / gris / or
brillant / noir-violacé), contour épais, aplat. FOND TRANSPARENT. 256×256 PNG.
```
*(Refais le prompt 4× en changeant juste la couleur et le nom de fichier.)*

## 5) Icônes de boutons HUD (transparentes)
```
[STYLE] + Icône d'interface cartoon, objet centré, contour épais, FOND TRANSPARENT, 256×256 PNG : [SUJET]
```
| Fichier | [SUJET] |
| --- | --- |
| `art/icon_fire.png` | une flamme stylisée orange/jaune (bouton Tir) |
| `art/icon_action.png` | une main de dessin animé qui attrape (bouton Action) |
| `art/icon_switch.png` | deux flèches circulaires (changer de personnage) |
| `art/icon_cauldron.png` | une marmite/chaudron qui bouillonne |
| `art/flame.png` | une flamme dorée (jauge de Tier) |

---

## ▶️ Quand tu as les PNG
Dépose‑les dans `unity/Assets/Resources/art/`, pousse sur Git (ou envoie‑les moi),
et je **branche tout par code** : sol texturé, ciel, lueur de particules, et icônes
du HUD à la place du texte. Commence par **`ground` + `sky`** : c'est ce qui change
le plus l'allure, pour quasiment zéro coût de perf.

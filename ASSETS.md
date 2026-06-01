# 🎨 Liste des assets à créer — Divine Rivals

Ce document liste **tous les assets graphiques** à faire produire (par Claude Designer
ou autre), pour remplacer/compléter le rendu procédural actuel.

**Style directeur** : low-poly *cartoon* cel-shadé, couleurs vives et saturées, contours
nets, ambiance mythologie grecque & égyptienne. Cohérence entre tous les éléments.

> 🔧 **Fonctionnement** : tout est **optionnel**. Le jeu marche déjà sans aucun de ces
> fichiers (rendu procédural). Dès qu'un fichier est déposé au bon chemin, il est utilisé.
> Deux catégories ci-dessous : **[AUTO]** = pris en compte automatiquement, **[À CÂBLER]** =
> envoie-le moi et je l'intègre (rapide).

---

## 1. Sols d'arène — [AUTO] ⭐ priorité haute

Textures **carrelables** (seamless), vue de dessus, déposées ici :

| Fichier | Monde | Ambiance souhaitée |
| --- | --- | --- |
| `assets/textures/ground0.png` | Plaines d'Olympe | herbe verte stylisée, fleurs, dalles de marbre éparses |
| `assets/textures/ground1.png` | Désert d'Anubis | sable doré, dunes, hiéroglyphes discrets |
| `assets/textures/ground2.png` | Enfers d'Hadès | roche sombre, fissures de lave incandescente |
| `assets/textures/ground3.png` | Mer Égée | eau turquoise + bancs de sable clairs |
| `assets/textures/ground4.png` | Nil sacré | herbe luxuriante, roseaux, eau du Nil |
| `assets/textures/ground5.png` | Mont Tonnerre | pierre grise, neige, éclats |
| `assets/textures/ground6.png` | Cité de Memphis | dalles de grès, sable, motifs égyptiens |
| `assets/textures/ground7.png` | Royaume des Dieux | marbre violet/or, nuages, lueur divine |

- **Format** : PNG (ou WebP), **1024×1024**, **carrelable** (tileable sans couture), sRGB.
- La couleur de base actuelle reste en secours si le fichier manque.

## 2. Logo du menu — [AUTO] ⭐ priorité haute
- `assets/ui/logo.png` — logo **« DIVINE RIVALS »**, PNG **transparent**, ~**1200×500**,
  style relief or/marbre, éclair stylisé. (Affiché au-dessus du titre du menu principal.)

---

## 3. Icônes d'armes / véhicules / coéquipiers — [À CÂBLER] ⭐ priorité haute
PNG **transparents**, **128×128** (ou 256×256), icône cartoon centrée, fond vide.
Remplaceront les emojis du HUD et du livre de recettes.

- Armes → `assets/icons/weapons/<id>.png` :
  `bow, dagger, lance, bolt, flames, heavyMG, longbow, divineThunder, harpyLauncher, electricBow, wrathOfZeus`
- Véhicules → `assets/icons/vehicles/<id>.png` :
  `pegasus, warChariot, giantTurtle, royalEagle`
- Coéquipiers → `assets/icons/teammates/<id>.png` :
  `archer, spearman, thunderling`

*(Total : 18 icônes. Les `id` correspondent exactement aux clés du code.)*

---

## 4. Habillage UI tactile — [À CÂBLER]
- `assets/ui/joystick_base.png` (256×256, transparent) — base du joystick.
- `assets/ui/joystick_knob.png` (160×160, transparent) — pommeau.
- `assets/ui/btn_fire.png`, `btn_action.png`, `btn_forge.png`, `btn_summon.png`,
  `btn_battalion.png` (192×192, transparent) — fonds de boutons ronds.
- `assets/ui/frame.png` (9-slice, 256×256) — cadre des panneaux HUD/menus *(optionnel)*.

## 5. Ciels / arrière-plans — [À CÂBLER]
- `assets/textures/sky<0-7>.png` — **soit** panorama équirectangulaire **2048×1024**,
  **soit** dégradé vertical **1024×1024**. Un par monde (mêmes thèmes qu'au §1).
  *(Sinon, couleur de ciel unie actuelle.)*

## 6. Textures de modèles 3D — [À CÂBLER] (optionnel, pour aller plus loin)
Atlas/teintes pour habiller les primitives low-poly :
- `assets/textures/buddy_atlas.png` (512×512) — visage, tunique, détails.
- `assets/textures/temple.png` (512×512) — marbre/colonnes.
- `assets/textures/cloud.png` (256×256, transparent) — nuage doux.
- `assets/textures/particle.png` (128×128, transparent, dégradé radial blanc) — sprite de particules.

---

## 7. App mobile (Capacitor) — [À CÂBLER] ⭐ pour un rendu « store »
- `assets/app/icon.png` — **1024×1024**, plein cadre (icône de l'app).
- `assets/app/splash.png` — **2732×2732**, logo centré sur fond `#05070d` (écran de lancement).
- Android adaptatif *(optionnel)* : `icon-foreground.png` + `icon-background.png` (432×432,
  sujet dans la zone de sécurité centrale).

> Ces fichiers servent à générer les icônes/splash natifs (ex. via `@capacitor/assets`).

## 8. Audio — [À CÂBLER] (optionnel)
La musique et les bruitages sont **synthétisés** (aucun fichier requis). Pour du son « réel » :
- `assets/audio/music_battle.mp3` (boucle drum'n'bass épique, ~60–90 s).
- `assets/audio/music_menu.mp3` (boucle calme).
- SFX `assets/audio/sfx/<nom>.wav` : `pickup, drop, craft, shoot, explosion, hurt, victory, defeat`.

---

## 📦 Récapitulatif des priorités
1. **Sols** (`ground0..7`) + **logo** → impact visuel immédiat, **automatique**.
2. **Icônes** d'armes/véhicules/coéquipiers (18) → HUD beaucoup plus pro.
3. **Icône + splash** d'app → rendu « vraie application ».
4. Ciels, habillage UI, textures 3D, audio → finitions.

Envoie-moi les fichiers (ou dépose-les dans `assets/` et pousse), je les **intègre et on
recompile l'APK via GitHub Actions**. 🎮

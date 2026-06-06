# 🎨 Direction Artistique & Plan graphique — Divine Rivals (route « 3D sublimée »)

But : atteindre **et dépasser** le rendu de l'original (low‑poly iso cartoon), en
**gardant tout le moteur/gameplay actuel** (chaudron, Tiers, IA, siège, écran partagé).
Contraintes : **mobile 30 FPS**, **aucun raccourci** qui casse une feature/la qualité,
chaque phase **testée en Play ET build device** avant la suivante.

---

## 1. Piliers de DA (le « style »)
- **Low‑poly cartoon cel‑shadé** : aplats francs, **2–3 paliers** d'ombre, **contour sombre** (outline) sur perso/objets clés.
- **Couleurs vives et saturées**, lisibilité **vue de dessus** (silhouettes nettes, sommets contrastés).
- **Lumière** : soleil chaud + ambiant froid (déjà en place) + **ombres douces** + **bloom léger** (URP).
- **Échelle/lecture** : persos trapus et expressifs ; le **buste du dieu** domine la base (point de mire du siège).
- **Palette par équipe/dieu** (déjà dans `Config`) : Olympe/Zeus bleu+or · Hadès rouge+orange · Anubis vert+or sombre · Râ or+ambre.

## 2. Assets CC0 à récupérer (usage commercial, sans crédit sauf mention)
À mettre dans `unity/Assets/Art/…` (je câblerai les chemins) :
| Besoin | Source (CC0) | Dossier cible |
| --- | --- | --- |
| **Personnages low‑poly animés** | **KayKit – Adventurers** (kaylousberg) | `Art/Models/Characters/` |
| Variété ennemis | **KayKit – Skeletons** | `Art/Models/Characters/` |
| **Animations** (idle/marche/attaque) | **KayKit – Character Animations** + **Quaternius – Universal Animation Library** | `Art/Animations/` |
| Décors / props (colonnes, rochers, arbres) | **Kenney**, **Quaternius** | `Art/Models/Props/` |
| Textures sol & ciel (HDRI) | **Poly Haven**, **ambientCG** | `Art/Textures/` |
| Icônes manquantes | **game-icons.net** *(CC‑BY → crédit requis)* | `Art/UI/` |
> Licences : tout **CC0** sauf game‑icons.net (**CC‑BY**). On notera les auteurs CC‑BY dans `CREDITS.md`.

## 3. Plan par phases (avec critère « Terminé quand… »)
- **P0 — URP** : installer Universal RP, asset pipeline, convertir, **0 matériau rose**. *(Nos `P.Mat` demandent déjà URP Lit → quasi auto.)* **Terminé quand** : le jeu tourne identique en URP, sans rose, 30 FPS device.
- **P1 — Cel‑shading + post‑process** : shader **toon** (ou Shader Graph) branché dans `P.Mat`, **outline**, **Volume global** (Bloom léger, Vignette, Color Adjustments), `renderPostProcessing=true` sur les caméras. **Terminé quand** : look cartoon net, perf OK.
- **P2 — Modèles animés** : remplacer les **sprites/primitives** des buddies par **modèles KayKit** + **Animator** (idle/run/attack via retarget). Repli sprite si modèle absent. **Terminé quand** : persos 3D animés, 4 équipes teintées, perf OK.
- **P3 — Dieux & arène** : buste du dieu en **statue** (modèle CC0 / prop) qui émerge ; props de décor (colonnes/rochers) ; skybox texturée. **Terminé quand** : arène habillée, dieux imposants.
- **P4 — VFX/juice** : particules URP (impacts, magie de craft), trails de projectiles, secousse caméra (déjà là), feedback de dépôt/craft. 
- **P5 — UI** : icônes (on les a) sur les boutons + recettes, cadre, police.
- **P6 — Audio** : musique + SFX (CC0).
- **P7 — Perf** : LOD, **GPU/SRP batching**, atlas, profilage sur le Pixel → **30 FPS stable**.

## 4. Mapping perso → modèle + teinte d'équipe
- **Minions** : archer → *ranger/rogue* · lancier → *knight* · foudre → *mage* · base → *barbarian/knight* (KayKit). **Teinte par équipe** via la couleur du matériau (1 modèle → 4 variantes).
- **Coéquipiers/véhicules** : mapper sur les modèles dispo ; à défaut, garder le sprite en repli.
- **Dieux (bustes)** : statue agrandie (prop CC0) ou notre buste procédural amélioré (toon + or) — **à trancher en P3**.

## 5. À COLLER au Claude local — P0 (URP) puis P1 (toon)
```
Objectif P0 : migrer le rendu en URP sans rien casser, puis P1 cel-shading + bloom.
Étapes P0 :
1) Package Manager -> installe "Universal RP".
2) Assets -> Create -> Rendering -> URP Asset (with Universal Renderer).
3) Project Settings -> Graphics + Quality : pointer l'URP Asset.
4) Window -> Rendering -> Render Pipeline Converter -> Built-in to URP -> convertir.
5) Vérifier qu'il n'y a AUCUN matériau rose (sinon remplacer le shader par URP).
6) Caméras (créées par code dans Game.MakeCameras) : ajouter
   cam.GetUniversalAdditionalCameraData().renderPostProcessing = true; (using UnityEngine.Rendering.Universal;)
7) Créer un Volume global (Bloom léger + Vignette + Color Adjustments).
Étapes P1 :
8) Ajouter un shader toon URP (Shader Graph ou shader CC0) + outline ; brancher dans P.Mat
   (garder le fallback si le shader est absent).
Règles : aucune régression ; tester en Play ET build sur device ; viser 30 FPS ;
me signaler tout compromis. Ne pas modifier la logique de gameplay (chaudron/Tiers/IA).
```

## 6. Qui fait quoi
- **Toi** : télécharger les packs CC0 du §2 (commence par **KayKit Adventurers + Animations** et **Quaternius Universal Animation Library**) ; lancer le Claude local sur la **P0** (brief §5).
- **Le Claude local** : exécute P0→P1 dans Unity (il voit la Console), teste, commit.
- **Moi (ici)** : specs, recherches d'assets, fiches par phase, relecture. Donne‑moi un retour après P0 et je détaille la **P1 (shader toon précis)** + la **P2 (intégration des modèles KayKit)**.

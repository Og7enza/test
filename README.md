# ⚡ Divine Rivals

**Divine Rivals** est un jeu d'action/stratégie temps réel en 3D isométrique, jouable
au doigt sur mobile (Android / iOS) et dans le navigateur. Il s'inspire des **mécaniques
de jeu** du genre « build & battle » popularisé par *Team Buddies* (collecte de ressources,
empilement, craft par motifs, escouades commandées), entièrement **réimaginé** sur un thème
de **mythologie grecque & égyptienne**.

> 100 % original : tout le code, les modèles 3D (générés proceduralement via primitives
> Three.js) et l'audio (synthétisé via la Web Audio API) sont produits par ce projet.
> Aucune ressource externe n'est requise — le jeu est **autonome et jouable hors-ligne**.

---

## 🎮 Jouer tout de suite (navigateur)

```bash
npm install      # installe Three.js + Capacitor, et vendorise Three dans vendor/
npm start        # lance un serveur local sur http://localhost:8080
```

Ouvrez **http://localhost:8080** dans Chrome/Safari (idéalement en **paysage**, ou via
les outils mobiles des DevTools). Sur ordinateur, la souris simule le tactile.

> Si `vendor/three/three.module.js` est absent après un clone, lancez `npm run vendor`
> (nécessite `npm install`). Ce fichier est versionné pour permettre un fonctionnement
> hors-ligne immédiat.

---

## 🕹️ Prise en main

| Action | Commande tactile |
| --- | --- |
| **Se déplacer** | Joystick virtuel (bas-gauche) **ou** tapez le sol où aller |
| **Changer de buddy** | Tapez son icône (haut-gauche) ou tapez-le à l'écran |
| **Ramasser / Déposer un nuage** | Bouton **Action** (contextuel) |
| **Empiler dans une colonne précise** | Placez-vous **du côté** voulu du pad puis *Déposer* |
| **Forger une arme / un véhicule** | Bouton **⚒️ Forge** (près du pad) |
| **Invoquer un coéquipier** | Bouton **✨ Invoque** (pile verticale) |
| **Tirer** | Bouton **🔥 Tir** (visée automatique assistée) |
| **Donner un ordre à un allié (IA)** | **Maintenez** le doigt sur un allié → menu radial |
| **Pause** | Bouton ⏸ en haut au centre |

### Gambits (IA des alliés, façon FFXII)
Maintenez le doigt sur un allié → menu radial. Chaque ordre est en réalité un **gambit** :
une liste ordonnée de règles *condition → action* évaluées de haut en bas. Exemple du
préréglage « Attaquer » : *si PV < 15% → repli, sinon → attaque la cible la plus proche*.

🐾 Suivre · 🛟 Protéger le chef · 🛡️ Défendre base · ⚔️ Attaquer · ☁️ Collecter · ✋ Attendre

### Bataillons (formations)
Bouton **🎖️ Bataillon** : il fait basculer vos alliés en **formation** derrière vous et
cycle entre **Pointe (V) → Ligne → File → Cercle → Off**. En formation, ils avancent
groupés et rompent les rangs pour combattre quand un ennemi entre à portée, puis se
reforment.

> 🎨 Assets manquants (sols, icônes, logo, splash…) : voir **[ASSETS.md](ASSETS.md)**.
> Tout est optionnel et « drop-in » — le jeu tourne déjà sans, en rendu procédural.

---

## ☁️ Le craft (cœur du jeu)

La ressource unique est le **nuage**. Il en tombe **3 toutes les 8 s**. Un buddy ne porte
**qu'un nuage à la fois** et le dépose sur le **pad 2×2** de son équipe. La **forme empilée**
détermine ce qu'on obtient — la signature est la liste des hauteurs de colonnes triées.

### ⚒️ Armes (action Forge) — 11 au total
| Forme | Arme |
| --- | --- |
| 1 nuage | Arc simple |
| 2 côte à côte | Double dague |
| 2 empilés | Lance |
| 3 en L | Éclair |
| 4 en carré | Flammes infernales |
| 4 en T (`2,1,1`) | Mitrailleuse lourde |
| mur 2×2 (`2,2`) | Arc long |
| `2,2,1` (5) | Foudre divine |
| `2,2,2` (6) | Lance-harpies |
| `2,2,2,1` (7) | Arc électrique |
| **cube 2×2×2** (`2,2,2,2`, 8) | **Colère de Zeus** (ultime) |

### 🚀 Véhicules (action Forge, 8 nuages en configuration « haute »)
`3,3,2` → **Pégase** · `4,4` → **Char de guerre** · `4,2,2` → **Tortue géante** · `3,3,1,1` → **Aigle royal**

### ✨ Coéquipiers (action Invoque, pile verticale pure)
2 → **Guerrier Arc** · 3 → **Guerrier Lance** · 4 → **Guerrier Foudre** (max 4 buddies / équipe)

> 💡 La même pile (ex. 2 empilés) donne une **Lance** avec *Forge* ou un **Guerrier Arc**
> avec *Invoque* : l'action choisie lève l'ambiguïté. Voir aussi le menu **📜 Recettes**.

---

## 🗺️ Modes de jeu

- **Campagne** — 8 mondes mythologiques × 8 missions = **64 missions** (élimination,
  destruction de base, collecte, survie, domination, boss). Progression sauvegardée
  (localStorage). Difficulté et taille des escouades ennemies croissantes.
- **Contre l'IA** — 1 à 3 bots, difficulté réglable, arène au choix.
- **Multijoueur local (écran partagé)** — **2 à 4 joueurs** sur le même appareil, chacun
  avec son **quadrant** et ses propres commandes : Deathmatch, Domination, Buddy Football,
  Base Assault. Bots de remplissage optionnels.

---

## 📱 Convertir en application mobile (Capacitor)

Le projet est prêt pour [Capacitor](https://capacitorjs.com/). Les fichiers web sont
assemblés dans `www/` (le `webDir` défini dans `capacitor.config.json`).

```bash
# 1) Dépendances
npm install

# 2) Assembler le dossier web (www/)
npm run build

# 3) Initialiser Capacitor (une seule fois)
npx cap init "Divine Rivals" com.divinerivals.game --web-dir=www   # déjà pré-configuré

# 4) Ajouter les plateformes (nécessite Android Studio / Xcode)
npm run cap:android      # = cap add android + sync + open
# ou
npm run cap:ios          # = cap add ios + sync + open

# 5) À chaque modif du jeu :
npm run build && npx cap sync
```

Puis lancez le build natif depuis **Android Studio** (APK/AAB) ou **Xcode** (IPA).
Le jeu force le **mode paysage** côté UI ; pensez à verrouiller l'orientation dans la
config native (`AndroidManifest.xml` / `Info.plist`) pour une expérience optimale.

---

## ⚙️ Performances & compatibilité

- Cible **30 FPS** sur mobile : `devicePixelRatio` plafonné, une seule lumière à ombres
  douces (PCFSoft, shadow map 1024), particules GPU mutualisées (pool unique), géométries
  partagées, projectiles *poolés*.
- Caméra **isométrique** de suivi ; en multi, **un viewport par joueur** (scissor test).
- Gère le redimensionnement et l'orientation. Aucune fuite mémoire : `dispose()` sur les
  mondes/HUD entre les parties.

---

## 🗂️ Structure du projet

```
index.html            Page + import map (three -> vendor)
style.css             UI tactile, menus, HUD, joystick, radial
vendor/three/         Three.js embarqué (offline)
src/
  main.js             Orchestrateur : boucle, entrées (raycast), caméra, cycle de partie
  core/
    engine.js         Renderer, lumières, ombres, brouillard, split-screen
    input.js          Tactile multipoint (tap / hold / drag) + résolution par joueur
    audio.js          Bruitages + musique drum'n'bass (100% synthétisés)
    particles.js      Système de particules GPU (ShaderMaterial, pool)
    assets.js         Modèles low-poly cel-shadés (buddies, temples, pad, véhicules…)
  game/
    world.js          Équipes, nuages, projectiles, combat, victoire/défaite, respawn
    buddy.js          Déplacement/évitement, combat auto-visé, transport, animation
    pad.js            Pad 2×2, empilement, résolution des recettes
    ai.js             Ordres (radial) + directeur d'équipe IA (collecte/craft/combat)
  ui/
    hud.js            HUD par joueur, joystick, menu radial, mini-carte
    menus.js          Menus, campagne, recettes, tutoriel, pause, résultats
  data/
    config.js         Réglages globaux
    weapons.js        Armes / véhicules / coéquipiers
    recipes.js        Détection de motifs (pur, testable)
    campaign.js       8 mondes + générateur de 64 missions (pur, testable)
  modes/modes.js      Intentions de menu -> config de partie
tools/
  serve.js            Serveur statique de dev (sans dépendance)
  build.js            Assemble www/ pour Capacitor
  vendor-three.js     (Re)copie Three.js dans vendor/
```

---

## 🧪 Tests rapides de la logique pure (sans navigateur)

```bash
node --input-type=module -e "import {resolveForge} from './src/data/recipes.js'; \
  console.log(resolveForge([2,2,2,2]))"   # => { kind: 'weapon', id: 'wrathOfZeus' }
```

---

## 📝 Choix de conception & simplifications assumées

- **Navigation** : steering avec évitement d'obstacles + séparation (navmesh « simplifié »),
  plutôt qu'un A* complet — léger et adapté au mobile.
- **Véhicules** : traités comme une amélioration du buddy (PV/vitesse/arme/vol). Le multi-place
  est cosmétique pour l'instant.
- **Buddy Football** : ruleset de **contrôle de zone** (le « ballon » est le centre). Une
  version avec ballon transportable et buts est un prochain ajout naturel.
- **Anti-blocage** : un buddy de base réapparaît au temple si une équipe tombe à zéro
  (sauf modes « élimination » où l'ennemi ne réapparaît pas).
- Les **64 missions** sont générées depuis des modèles d'objectifs (difficulté croissante,
  thèmes par monde) : toutes sont jouables et distinctes.

---

## 📄 Licence

MIT — œuvre originale. *Divine Rivals* est un hommage **mécanique** au genre ; il ne
contient aucun actif, nom, code ou contenu protégé d'un autre jeu.

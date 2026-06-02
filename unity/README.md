# Divine Rivals — version Unity (rework « Chaudron »)

Portage **Unity (C#)** du jeu, avec le nouveau système de **chaudron / Tier / nuages
colorés**. Tout est généré **au runtime** (aucun prefab ni scène à câbler) : le jeu
démarre seul via `[RuntimeInitializeOnLoadMethod]`. Une scène vide suffit.

> ⚠️ **Code non compilé ici.** Ce projet a été écrit hors éditeur Unity. Il est
> conçu pour compiler tel quel, mais **attends-toi à 1–2 corrections** à la
> première ouverture (colle-moi les erreurs de la Console, je corrige).

---

## 🎮 Nouvelles mécaniques

- **Chaudron** (remplace le pad) : chaque équipe a un chaudron avec **3 postes**.
- **Tier = nombre de buddies assignés** au chaudron (0→3). On **assigne** un buddy
  (bouton *Assigner*) : il devient immobile et « touille » (ne combat plus), mais
  fait monter le Tier → débloque de meilleures recettes. *Retirer* le rend jouable.
- **On démarre avec 2 buddies** (max 4). Choix tactique dès le début : garder ses 2
  combattants, ou en sacrifier un au chaudron pour monter en puissance.
- **Nuages colorés** : blanc (fréquent), gris (rare), or (très rare), noir (extrême).
  On les ramasse (ACTION) et on les verse dans le chaudron (capacité 8).
- **Recettes filtrées par Tier** (≈19, noms mythologiques). Le coût est en **nuages
  colorés**. Ex. : *Arc d'Apollon* (T0, 2 blancs) … *Colère de Zeus* (T3, 3 or + 2 noirs).
  Tier 0 = armes faibles + nouveau buddy ; T1 intermédiaires + Pégase ; T2 puissantes
  + Char/Aigle ; T3 ultimes + tous véhicules.
- **But** : **détruire le buste du dieu ennemi** (Zeus / Hadès / Anubis / Râ) — il
  émerge du sol, a beaucoup de PV et **riposte** (foudre). Les minions réapparaissent.
- **Modes** : 1 Joueur (vs IA) et **2 Joueurs en écran partagé** (chaudron/Tier
  indépendants). Une seule map. (Campagne supprimée.)

## 🕹️ Contrôles (tactile)
- **Joystick** (bas-gauche) ou **tap sur le sol** : se déplacer.
- **TIR** (maintenu) : tirer (visée auto). **ACTION** : ramasser / verser un nuage.
- **CHGT** : changer de buddy actif. **CHAUDRON** : ouvrir l'atelier (Assigner/Retirer
  + recettes du Tier courant).

---

## 🔧 Compiler l'APK dans Unity (pas à pas)

1. **Installe Unity Hub** puis un **Unity LTS** : `2021.3`, `2022.3` ou `Unity 6`.
   Lors de l'install, coche le module **Android Build Support** (avec **OpenJDK** +
   **Android SDK & NDK Tools**).
2. **Ouvre le projet** : Unity Hub → *Add* → sélectionne le dossier **`unity/`** de ce
   dépôt → ouvre-le (accepte l'upgrade si la version diffère).
   - Conseil : ce projet vise le **Built-in Render Pipeline** (template *3D Core*).
     Si tout apparaît rose, dis-le moi (adaptation URP simple).
3. **Crée une scène vide** : *File ▸ New Scene* → *Basic (Built-in)* ou *Empty* →
   *File ▸ Save As* → `Assets/Scenes/Main.unity`. (La scène peut rester vide : le jeu
   se construit tout seul au lancement.)
4. *File ▸ Build Settings* → **Add Open Scenes** (ajoute `Main`).
   → **Android** → **Switch Platform**.
5. *Player Settings* (bouton dans Build Settings) :
   - **Resolution and Presentation ▸ Default Orientation = Landscape Left** (ou Auto Landscape).
   - **Other Settings ▸ Minimum API Level = Android 7.0 (API 24)** (ou +).
   - (Optionnel) Company/Product name, *Package name* (ex. `com.divinerivals.game`).
6. Branche ton téléphone (USB, *débogage USB* activé) → **Build And Run**.
   Ou **Build** pour générer un **`.apk`** (ou `.aab`) à installer manuellement.

> Pour tester vite sur PC avant le téléphone : appuie sur **Play** dans l'éditeur
> (souris = tactile, le jeu démarre directement sur le menu).

---

## 📁 Structure
```
unity/
  Assets/Scripts/
    Core.cs       Config + helpers (matériaux/primitives) + audio + BOOTSTRAP
    Recipes.cs    Armes/véhicules/coéquipiers + ~19 recettes (couleur + Tier)
    Buddy.cs      Personnage (déplacement, combat, transport, "au travail")
    Cauldron.cs   Chaudron : 3 postes, Tier, stock de nuages, craft
    Team.cs       Équipe + GodBust (buste du dieu : émergence, riposte, PV)
    World.cs      Arène, vagues de nuages, projectiles, combat, victoire
    AI.cs         IA ennemie (collecte, montée en Tier, craft, combat)
    Game.cs       Orchestrateur : menu, caméras split-screen, entrées, boucle
    HUD.cs        Interface tactile (joystick, boutons, panneau chaudron)
  Packages/manifest.json
  ProjectSettings/ProjectVersion.txt
```

## 📝 Choix assumés (vs cahier des charges)
- **Recettes par COULEUR + TIER** (et non par position 2×2×2) : plus lisible/mobile,
  tout aussi riche. On pourra réintroduire des motifs positionnels plus tard.
- **Visuels procéduraux** (primitives) en attendant tes assets libres de droit
  (modèles `.glb`, textures) — facile à brancher ensuite.
- Campagne retirée ; une seule map ; modes 1J vs IA et 2J écran partagé.

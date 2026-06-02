// =============================================================================
//  Game.cs — Orchestrateur (MonoBehaviour unique). Menu, mise en place de la
//  partie, caméras isométriques (écran partagé), entrées tactiles (déplacement
//  par tap + callbacks HUD), boucle de jeu, résultats.
// =============================================================================
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;

namespace DivineRivals {

public class Game : MonoBehaviour {
    Transform worldRoot;
    World world;
    Sfx sfx;
    HUD hud;
    GameObject menu;
    bool running, resultsShown; float shake;
    readonly List<Camera> cams = new List<Camera>();
    readonly List<Team> camTeam = new List<Team>();
    readonly Vector3 camOffset = new Vector3(0, 34, 26);

    void Awake() {
        Application.targetFrameRate = Config.TargetFPS;
        Input.multiTouchEnabled = true;
        try { Screen.orientation = ScreenOrientation.LandscapeLeft; } catch { }
        gameObject.AddComponent<AudioListener>();
        sfx = new Sfx(gameObject);
        SetupLight();
        SetupEventSystem();
        ShowMenu(null);
    }

    void SetupLight() {
        var g = new GameObject("Sun");
        var l = g.AddComponent<Light>();
        l.type = LightType.Directional; l.color = new Color(1f, 0.96f, 0.88f); l.intensity = 1.15f;
        l.shadows = LightShadows.Soft;
        g.transform.rotation = Quaternion.Euler(50f, -30f, 0f);
        var fill = new GameObject("Fill").AddComponent<Light>();
        fill.type = LightType.Directional; fill.color = new Color(0.6f, 0.72f, 0.95f); fill.intensity = 0.45f; fill.shadows = LightShadows.None;
        fill.transform.rotation = Quaternion.Euler(-28f, 140f, 0f);
        RenderSettings.ambientLight = new Color(0.56f, 0.6f, 0.68f);
    }

    void SetupEventSystem() {
        if (FindObjectOfType<EventSystem>() == null) {
            var es = new GameObject("EventSystem");
            es.AddComponent<EventSystem>();
            es.AddComponent<StandaloneInputModule>();
        }
    }

    // --- Menu / résultats -----------------------------------------------------
    void ShowMenu(string banner) {
        Teardown();
        running = false;
        menu = UI.Canvas("Menu", 10);
        UI.Text(menu.transform, banner ?? "DIVINE RIVALS — Chaudron", 54, new Vector2(0, 180), new Vector2(900, 120), new Color(1f, 0.84f, 0.3f));
        UI.Text(menu.transform, "Détruis le buste du dieu ennemi !", 26, new Vector2(0, 110), new Vector2(900, 60), Color.white);
        UI.Button(menu.transform, "1 Joueur (vs IA)", new Vector2(0, 10), new Vector2(420, 80), () => StartMatch(1));
        UI.Button(menu.transform, "2 Joueurs (écran partagé)", new Vector2(0, -90), new Vector2(420, 80), () => StartMatch(2));
    }

    void ShowResults() {
        string b = world.result == "win" ? "VICTOIRE !" : (world.result == "lose" ? "DEFAITE" :
                   (world.winner != null ? world.winner.teamName + " gagne !" : "Egalite"));
        ShowMenu(b);
    }

    // --- Cycle de partie ------------------------------------------------------
    void StartMatch(int humans) {
        Teardown();
        worldRoot = new GameObject("World").transform;
        worldRoot.SetParent(transform, false);
        world = new World(worldRoot, sfx);

        var cfgs = new List<TeamCfg>();
        if (humans <= 1) {
            cfgs.Add(new TeamCfg { colorIndex = 0, ctrl = Ctrl.Human, viewport = 0, aiLevel = 0.6f });
            cfgs.Add(new TeamCfg { colorIndex = 1, ctrl = Ctrl.AI, viewport = -1, aiLevel = 0.6f, templeHP = Config.BustHP });
        } else {
            cfgs.Add(new TeamCfg { colorIndex = 0, ctrl = Ctrl.Human, viewport = 0, aiLevel = 0.6f });
            cfgs.Add(new TeamCfg { colorIndex = 1, ctrl = Ctrl.Human, viewport = 1, aiLevel = 0.6f });
        }
        world.Init(cfgs);
        world.onShake = a => shake = Mathf.Min(1.4f, Mathf.Max(shake, a));
        MakeCameras(humans);
        hud = new HUD(this, world);
        resultsShown = false; running = true;
    }

    void Teardown() {
        if (menu) { Destroy(menu); menu = null; }
        if (hud != null) { hud.Destroy(); hud = null; }
        foreach (var c in cams) if (c) Destroy(c.gameObject);
        cams.Clear(); camTeam.Clear();
        if (worldRoot) { Destroy(worldRoot.gameObject); worldRoot = null; }
        world = null;
    }

    void MakeCameras(int humans) {
        var humanTeams = world.teams.FindAll(t => t.controller == Ctrl.Human);
        Rect[] rects = humans <= 1
            ? new[] { new Rect(0, 0, 1, 1) }
            : new[] { new Rect(0, 0, 0.5f, 1), new Rect(0.5f, 0, 0.5f, 1) };
        for (int i = 0; i < humanTeams.Count; i++) {
            var go = new GameObject("Cam" + i);
            var cam = go.AddComponent<Camera>();
            cam.fieldOfView = 38; cam.farClipPlane = 400; cam.nearClipPlane = 0.5f;
            cam.backgroundColor = new Color(0.5f, 0.66f, 0.86f);
            cam.rect = rects[Mathf.Min(i, rects.Length - 1)];
            var t = humanTeams[i];
            go.transform.position = t.spawn + camOffset;
            cams.Add(cam); camTeam.Add(t);
        }
    }

    void Update() {
        if (!running || world == null) return;
        float dt = Mathf.Min(Time.deltaTime, 0.05f);
        if (!world.over) {
            HandleTaps();
            world.Tick(dt);
            FollowCams(dt);
            if (shake > 0f) shake = Mathf.Max(0f, shake - dt * 4.5f);
            if (hud != null) hud.Refresh();
        }
        if (world.over && !resultsShown) { resultsShown = true; sfx.Boom(); ShowResults(); }
    }

    void FollowCams(float dt) {
        for (int i = 0; i < cams.Count; i++) {
            var t = camTeam[i];
            Vector3 tgt = (t.active != null && t.active.alive) ? t.active.Pos : new Vector3(t.spawn.x, 1f, t.spawn.z);
            var cam = cams[i].transform;
            cam.position = Vector3.Lerp(cam.position, tgt + camOffset, 1f - Mathf.Exp(-6f * dt));
            if (shake > 0.001f) cam.position += new Vector3(Random.value - 0.5f, (Random.value - 0.5f) * 0.6f, Random.value - 0.5f) * shake;
            cam.LookAt(tgt + Vector3.up);
        }
    }

    // --- Entrées : tap-pour-déplacer (le reste passe par les boutons HUD) -----
    void HandleTaps() {
        if (Input.touchCount > 0) {
            for (int i = 0; i < Input.touchCount; i++) {
                var tc = Input.GetTouch(i);
                if (tc.phase != TouchPhase.Began) continue;
                if (EventSystem.current != null && EventSystem.current.IsPointerOverGameObject(tc.fingerId)) continue;
                TapAt(tc.position);
            }
        } else if (Input.GetMouseButtonDown(0)) {
            if (EventSystem.current != null && EventSystem.current.IsPointerOverGameObject()) return;
            TapAt(Input.mousePosition);
        }
    }

    void TapAt(Vector2 screen) {
        float vx = screen.x / Screen.width, vy = screen.y / Screen.height;
        for (int i = 0; i < cams.Count; i++) {
            var r = cams[i].rect;
            if (vx < r.x || vx > r.x + r.width || vy < r.y || vy > r.y + r.height) continue;
            var t = camTeam[i];
            if (t.active == null || !t.active.alive) return;
            Ray ray = cams[i].ScreenPointToRay(screen);
            if (Mathf.Abs(ray.direction.y) < 1e-4f) return;
            float dist = -ray.origin.y / ray.direction.y;
            if (dist <= 0) return;
            Vector3 p = ray.origin + ray.direction * dist;
            t.active.SetMove(p);
            return;
        }
    }

    // --- Callbacks appelés par le HUD ----------------------------------------
    public void OnJoystick(Team t, Vector2 v) { if (t.active != null && t.active.alive) { t.active.joy = v; if (v.sqrMagnitude > 0.04f) t.active.hasMove = false; } }
    public void OnFire(Team t, bool down) { if (t.active != null && t.active.alive) t.active.wantFire = down; }
    public void OnSwitch(Team t) {
        var f = t.Free(); if (f.Count == 0) return;
        int idx = t.active != null ? f.IndexOf(t.active) : -1;
        t.active = f[(idx + 1) % f.Count];
        sfx.Pickup();
    }
    public void OnAction(Team t) {
        var b = t.active; if (b == null || !b.alive) return;
        if (b.carryColor >= 0) { if (!world.TryDeposit(b)) hud.Toast(t, "Approche le chaudron pour verser"); }
        else if (!world.TryPickup(b)) hud.Toast(t, "Aucun nuage à portée");
    }
    public void OnAssign(Team t) {
        var b = t.active; if (b == null || !b.alive) return;
        if ((b.Pos - t.cauldron.pos).sqrMagnitude > Config.UseRadius * Config.UseRadius * 1.4f) { hud.Toast(t, "Approche le chaudron"); return; }
        int post = t.cauldron.FirstFreePost();
        if (post < 0) { hud.Toast(t, "Tous les postes sont occupés"); return; }
        if (t.cauldron.Assign(b, post)) hud.Toast(t, "Buddy assigné — Tier " + t.Tier);
    }
    public void OnRemove(Team t) {
        for (int i = Config.Posts - 1; i >= 0; i--) if (t.cauldron.postBuddy[i] != null) { t.cauldron.RemovePost(i); hud.Toast(t, "Buddy retiré — Tier " + t.Tier); return; }
        hud.Toast(t, "Aucun buddy au chaudron");
    }
    public void OnCraft(Team t, Recipe r) {
        var res = t.cauldron.Craft(r);
        hud.Toast(t, res.ok ? ("✨ " + res.msg + " !") : res.msg);
    }
}

}

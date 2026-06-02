// =============================================================================
//  HUD.cs — Interface tactile (uGUI, construite en code). Un panneau par joueur
//  humain (gère l'écran partagé). Joystick + Tir + Action + Changer de buddy,
//  et le panneau CHAUDRON : postes/Tier, stock de nuages colorés, Assigner /
//  Retirer, et les recettes filtrées par Tier.
// =============================================================================
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

namespace DivineRivals {

// --- Helpers de création uGUI ----------------------------------------------
public static class UI {
    static Font _font;
    public static Font F() {
        if (_font == null) { _font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf"); if (_font == null) _font = Resources.GetBuiltinResource<Font>("Arial.ttf"); }
        return _font;
    }
    public static GameObject Canvas(string name, int order) {
        var go = new GameObject(name);
        var c = go.AddComponent<Canvas>(); c.renderMode = RenderMode.ScreenSpaceOverlay; c.sortingOrder = order;
        var sc = go.AddComponent<CanvasScaler>(); sc.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        sc.referenceResolution = new Vector2(1280, 720); sc.matchWidthOrHeight = 0.5f;
        go.AddComponent<GraphicRaycaster>();
        return go;
    }
    public static RectTransform Node(Transform parent, Vector2 aMin, Vector2 aMax, Vector2 pivot, Vector2 pos, Vector2 size) {
        var go = new GameObject("ui"); go.transform.SetParent(parent, false);
        var rt = go.AddComponent<RectTransform>();
        rt.anchorMin = aMin; rt.anchorMax = aMax; rt.pivot = pivot; rt.anchoredPosition = pos; rt.sizeDelta = size;
        return rt;
    }
    // Région stretchée (= viewport d'un joueur), enfants ancrés à ses coins.
    public static RectTransform Region(Transform parent, Rect r) {
        var rt = Node(parent, new Vector2(r.x, r.y), new Vector2(r.x + r.width, r.y + r.height), new Vector2(0.5f, 0.5f), Vector2.zero, Vector2.zero);
        return rt;
    }
    public static Text Text(Transform parent, string s, int size, Vector2 pos, Vector2 dim, Color col, TextAnchor anchor = TextAnchor.MiddleCenter) {
        var rt = Node(parent, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), pos, dim);
        var t = rt.gameObject.AddComponent<Text>(); t.font = F(); t.fontSize = size; t.color = col; t.alignment = anchor; t.text = s;
        t.horizontalOverflow = HorizontalWrapMode.Wrap; t.verticalOverflow = VerticalWrapMode.Overflow;
        return t;
    }
    public static Image Box(RectTransform rt, Color col) { var im = rt.gameObject.AddComponent<Image>(); im.color = col; return im; }
    public static Button Button(Transform parent, string label, Vector2 pos, Vector2 size, System.Action onClick) {
        var rt = Node(parent, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), pos, size);
        Box(rt, new Color(0.12f, 0.18f, 0.32f, 0.95f));
        var b = rt.gameObject.AddComponent<Button>(); b.targetGraphic = rt.GetComponent<Image>();
        if (onClick != null) b.onClick.AddListener(() => onClick());
        var t = Text(rt, label, 22, Vector2.zero, size, new Color(1f, 0.95f, 0.85f)); t.alignment = TextAnchor.MiddleCenter;
        var trt = t.GetComponent<RectTransform>(); trt.anchorMin = Vector2.zero; trt.anchorMax = Vector2.one; trt.sizeDelta = Vector2.zero; trt.anchoredPosition = Vector2.zero;
        return b;
    }
}

// Bouton "maintenir" (tir) : appui / relâche.
public class PressButton : MonoBehaviour, IPointerDownHandler, IPointerUpHandler {
    public System.Action onDown, onUp;
    public void OnPointerDown(PointerEventData e) { onDown?.Invoke(); }
    public void OnPointerUp(PointerEventData e) { onUp?.Invoke(); }
}

// Joystick virtuel (uGUI, multitouch-safe).
public class Joystick : MonoBehaviour, IPointerDownHandler, IDragHandler, IPointerUpHandler {
    public RectTransform bg, knob; public System.Action<Vector2> onChange; float radius = 70f;
    void Start() { if (bg) radius = bg.sizeDelta.x * 0.5f; }
    public void OnPointerDown(PointerEventData e) { OnDrag(e); }
    public void OnDrag(PointerEventData e) {
        Vector2 lp;
        RectTransformUtility.ScreenPointToLocalPointInRectangle(bg, e.position, e.pressEventCamera, out lp);
        Vector2 v = Vector2.ClampMagnitude(lp, radius);
        if (knob) knob.anchoredPosition = v;
        onChange?.Invoke(v / Mathf.Max(1f, radius));
    }
    public void OnPointerUp(PointerEventData e) { if (knob) knob.anchoredPosition = Vector2.zero; onChange?.Invoke(Vector2.zero); }
}

// --- HUD --------------------------------------------------------------------
public class HUD {
    Game game; World world; GameObject canvas;
    static readonly string[] CL = { "B", "G", "O", "N" };

    class Panel {
        public Team team;
        public Text stats, posts, stock, toast;
        public float toastT;
        public GameObject craft;
        public List<(Button btn, Text txt, Recipe r)> recipes = new List<(Button, Text, Recipe)>();
    }
    List<Panel> panels = new List<Panel>();

    public HUD(Game g, World w) { game = g; world = w; canvas = UI.Canvas("HUD", 5); Build(); }

    void Build() {
        var humans = world.teams.FindAll(t => t.controller == Ctrl.Human);
        Rect[] rects = humans.Count <= 1
            ? new[] { new Rect(0, 0, 1, 1) }
            : new[] { new Rect(0, 0, 0.5f, 1), new Rect(0.5f, 0, 0.5f, 1) };

        for (int i = 0; i < humans.Count; i++) {
            var team = humans[i];
            var region = UI.Region(canvas.transform, rects[Mathf.Min(i, rects.Length - 1)]);
            var p = new Panel { team = team };

            // Bandeau haut.
            var top = UI.Node(region, new Vector2(0, 1), new Vector2(1, 1), new Vector2(0.5f, 1), new Vector2(0, -6), new Vector2(-20, 40));
            UI.Box(top, new Color(0, 0, 0, 0.45f));
            p.stats = UI.Text(top, "", 20, Vector2.zero, Vector2.zero, Color.white);
            var srt = p.stats.GetComponent<RectTransform>(); srt.anchorMin = Vector2.zero; srt.anchorMax = Vector2.one; srt.sizeDelta = new Vector2(-16, 0); srt.anchoredPosition = Vector2.zero; p.stats.alignment = TextAnchor.MiddleLeft;

            // Joystick (bas-gauche).
            var jbg = UI.Node(region, new Vector2(0, 0), new Vector2(0, 0), new Vector2(0, 0), new Vector2(24, 24), new Vector2(150, 150));
            UI.Box(jbg, new Color(1, 1, 1, 0.10f));
            var knob = UI.Node(jbg, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(64, 64));
            UI.Box(knob, new Color(1f, 0.84f, 0.3f, 0.9f));
            var joy = jbg.gameObject.AddComponent<Joystick>(); joy.bg = jbg; joy.knob = knob;
            var capt = team; joy.onChange = v => game.OnJoystick(capt, v);

            // Bouton TIR (maintenu) : Image + PressButton (pas de Button onClick).
            var fireRT = UI.Node(region, new Vector2(1, 0), new Vector2(1, 0), new Vector2(1, 0), new Vector2(-90, 70), new Vector2(116, 116));
            UI.Box(fireRT, new Color(0.78f, 0.27f, 0.18f, 0.95f));
            var ft = UI.Text(fireRT, "TIR", 26, Vector2.zero, Vector2.zero, Color.white);
            var ftr = ft.GetComponent<RectTransform>(); ftr.anchorMin = Vector2.zero; ftr.anchorMax = Vector2.one; ftr.sizeDelta = Vector2.zero; ftr.anchoredPosition = Vector2.zero;
            var pb = fireRT.gameObject.AddComponent<PressButton>(); pb.onDown = () => game.OnFire(capt, true); pb.onUp = () => game.OnFire(capt, false);

            var act = UI.Button(region, "ACTION", new Vector2(0, 0), new Vector2(96, 88), () => game.OnAction(capt)); Anchor(act, new Vector2(1, 0), new Vector2(-210, 64));
            var sw = UI.Button(region, "CHGT", new Vector2(0, 0), new Vector2(84, 76), () => game.OnSwitch(capt)); Anchor(sw, new Vector2(1, 0), new Vector2(-92, 200));
            var cauldronBtn = UI.Button(region, "CHAUDRON", new Vector2(0, 0), new Vector2(180, 64), () => ToggleCraft(p)); Anchor(cauldronBtn, new Vector2(0.5f, 0), new Vector2(0, 40));

            BuildCraftPanel(p, region);

            // Toast.
            p.toast = UI.Text(region, "", 22, new Vector2(0, 0), new Vector2(560, 40), new Color(1f, 0.9f, 0.6f));
            Anchor(p.toast.GetComponent<RectTransform>(), new Vector2(0.5f, 1), new Vector2(0, -54));
            p.toast.color = new Color(1, 1, 1, 0);

            panels.Add(p);
        }
    }

    void Anchor(Component c, Vector2 anchor, Vector2 pos) {
        var rt = c.GetComponent<RectTransform>();
        rt.anchorMin = anchor; rt.anchorMax = anchor; rt.pivot = anchor; rt.anchoredPosition = pos;
    }
    void BuildCraftPanel(Panel p, RectTransform region) {
        var panel = UI.Node(region, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(560, 460));
        UI.Box(panel, new Color(0.05f, 0.07f, 0.13f, 0.96f));
        p.craft = panel.gameObject; p.craft.SetActive(false);

        p.posts = UI.Text(panel, "", 22, new Vector2(0, 200), new Vector2(540, 36), new Color(1f, 0.84f, 0.3f));
        p.stock = UI.Text(panel, "", 20, new Vector2(0, 168), new Vector2(540, 30), Color.white);
        UI.Button(panel, "➕ Assigner (Tier+)", new Vector2(-135, 130), new Vector2(250, 48), () => game.OnAssign(p.team));
        UI.Button(panel, "➖ Retirer (Tier-)", new Vector2(135, 130), new Vector2(250, 48), () => game.OnRemove(p.team));
        UI.Button(panel, "✕ Fermer", new Vector2(230, 200), new Vector2(90, 40), () => p.craft.SetActive(false));

        // Recettes en grille 2 colonnes (triées par tier).
        var list = new List<Recipe>(Data.Recipes);
        list.Sort((a, b) => a.tier - b.tier);
        for (int i = 0; i < list.Count; i++) {
            var r = list[i];
            int col = i % 2, row = i / 2;
            float x = col == 0 ? -135 : 135, y = 92 - row * 44;
            var btn = UI.Button(panel, "", new Vector2(x, y), new Vector2(258, 40), () => game.OnCraft(p.team, r));
            var txt = btn.GetComponentInChildren<Text>(); txt.fontSize = 15;
            p.recipes.Add((btn, txt, r));
        }
    }

    void ToggleCraft(Panel p) { p.craft.SetActive(!p.craft.activeSelf); }

    static string Cost(Recipe r) { string s = ""; for (int i = 0; i < 4; i++) if (r.cost[i] > 0) s += r.cost[i] + CL[i] + " "; return s.Trim(); }

    public void Toast(Team t, string msg) {
        var p = panels.Find(x => x.team == t); if (p == null) return;
        p.toast.text = msg; p.toast.color = new Color(1f, 0.92f, 0.7f, 1f); p.toastT = 2.3f;
    }

    public void Refresh() {
        foreach (var p in panels) {
            var t = p.team; var b = t.active;
            var enemy = world.EnemyBustFor(t);
            string eName = enemy != null ? enemy.team.godName : "—";
            int eHP = enemy != null ? Mathf.Max(0, Mathf.CeilToInt(enemy.hp)) : 0;
            string carry = (b != null && b.carryColor >= 0) ? Config.CloudName[b.carryColor] : "-";
            p.stats.text = $"{t.teamName}   Base {Mathf.CeilToInt(t.bust.hp)}   Tier {t.Tier}   Nuage:{carry}    Cible: {eName} {eHP}";

            if (p.craft.activeSelf) {
                string ps = "Postes: ";
                for (int i = 0; i < Config.Posts; i++) ps += t.cauldron.postBuddy[i] != null ? "[■]" : "[_]";
                p.posts.text = ps + "   TIER " + t.Tier;
                var st = t.cauldron.stock;
                p.stock.text = $"Nuages  B:{st[0]} G:{st[1]} O:{st[2]} N:{st[3]}   ({t.cauldron.Total}/{Config.CauldronCap})";
                foreach (var rb in p.recipes) {
                    bool unlocked = t.Tier >= rb.r.tier;
                    rb.btn.gameObject.SetActive(unlocked);
                    if (!unlocked) continue;
                    bool afford = Data.CanAfford(rb.r, t.cauldron.stock);
                    rb.btn.interactable = afford;
                    rb.txt.text = rb.r.name + "  " + Cost(rb.r);
                    rb.txt.color = afford ? new Color(0.85f, 1f, 0.85f) : new Color(0.7f, 0.7f, 0.75f);
                }
            }

            if (p.toastT > 0f) {
                p.toastT -= Time.deltaTime;
                var c = p.toast.color; c.a = Mathf.Clamp01(p.toastT); p.toast.color = c;
            }
        }
    }

    public void Destroy() { if (canvas) Object.Destroy(canvas); }
}

}
